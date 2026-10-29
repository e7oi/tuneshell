# ADR-020 — Android Auto : service média existant, arbre servi par le gestionnaire

**Statut :** Active (validée le 2026-10-28) · **Date :** 2026-10-28 · **Ticket :** MPL-060 · **Décisions :** D6, D12, D15, D27 · **Fiches :** UC-012, FR-029, BR-013 · **Complète :** ADR-006, ADR-015

## Contexte

`audio_service` déclare déjà `AudioService`, un `MediaBrowserService` (ADR-006). Android Auto s'y connecte comme un navigateur média : il demande la racine, puis les enfants d'un identifiant, puis lance la lecture d'un identifiant. Le gestionnaire actuel (`PlayerAudioHandler`, `platform/media_session/`) ne répond pas aux requêtes de navigation.

## Décision (proposée)

- **Pas de service natif en plus.** On réutilise `AudioService` ; le gestionnaire répond à `getChildren`, `getMediaItem` et `playFromMediaId`, la racine étant celle d'`audio_service` (et sa racine « récent » pour BR-013, règle 2).
- **Déclaration** : métadonnée `com.google.android.gms.car.application` du manifeste vers `res/xml/automotive_app_desc.xml` (`<uses name="media"/>`). Aucune permission.
- **Frontière** : un port de lecture de l'arbre dans `domain/playback/ports/` (nom à choisir à l'implémentation), implémenté dans `app/` à partir des fournisseurs de bibliothèque ; le gestionnaire (`platform/`) ne connaît ni Drift ni Riverpod, comme `TrackDescriber` aujourd'hui. Un faux dans `test/` compte comme seconde implémentation.
- **Logique pure et testée d'abord** : construction de l'arbre (racine, groupes alphabétiques, albums, artistes), identifiants stables encodant (disque, chemin relatif), résolution d'un identifiant en liste de pistes à lire. Tout en `domain/` ; le gestionnaire ne fait que traduire en `MediaItem`.
- **Lecture** : `playFromMediaId` appelle le même `PlayerController` (BR-013, règle 11) ; aucune seconde voie de lecture.

## À vérifier avant d'écrire du code (risques)

1. **Démarrage sans interface.** Quand la voiture se connecte et que l'application n'est pas lancée, Android démarre le service ; `audio_service` doit créer un moteur Flutter et exécuter `main()`. Vérifier que `main()` câble le gestionnaire, la bibliothèque et la restauration (ADR-019) sans écran et assez vite pour Android Auto (délai de réponse de la racine). Mesure sur le Pixel.
2. **Pochettes.** Android Auto lit-il un `file://` de l'application ? Sinon, un `ContentProvider` ou la copie des pochettes en `content://` est nécessaire (nouveau code natif Kotlin, protocole écrit dans `HOWTO.md`). À trancher par un essai.
3. **Taille des listes.** Limite pratique d'éléments par niveau, pagination (`MediaBrowserCompat.EXTRA_PAGE`) et profondeur maximale : à mesurer ; fixe le seuil du découpage alphabétique (BR-013, règle 4).
4. **Sources inconnues.** Hors Play Store, Android Auto n'affiche l'application que si l'option développeur est active (D6, ouverte pour Google Play) ; à confirmer en voiture.
5. **Disques amovibles.** Ouverture par descripteur (`fd://`) depuis le service quand l'interface n'existe pas : même chemin que la notification, à confirmer.

## Résultats de la mise en œuvre (2026-10-28)

1. **Démarrage sans interface** : déjà couvert. `TuneShellApplication` crée le moteur de `audio_service` et câble les canaux natifs avant toute activité ; le service lance `main()`. Reste à mesurer en voiture le délai de la première racine : `main()` charge les réglages avant d'appeler `startSystemPlayback`.
2. **Pochettes** : `file://` comme la notification. Vérifié en voiture le 2026-10-28 : affichées sur l'écran de lecture et le tableau de bord, pas dans les listes (suite possible : `content://`).
3. **Taille des listes** : seuil de 100 entrées par niveau, découpage par lettres successives jusqu'à ce que chaque niveau tienne (le niveau le plus profond peut dépasser s'il n'y a plus de lettre à couper). À mesurer.
4. **Sources inconnues** : non vérifié.
5. **Disques amovibles** : même chemin que la notification ; non vérifié depuis la voiture.
6. **Flux gardé vivant** : Riverpod met en pause un flux que personne n'écoute. `keepMediaTreeReadable` écoute les groupes et la liste triée pour toute la vie du processus ; un arbre est construit à chaque demande de la voiture à partir de leurs valeurs.
7. **Provenance de la file** : choisir une piste dans la voiture efface la provenance affichée par le lecteur (`onQueueChosen`), pour ne pas dire « Album · X » d'une file qui n'en vient plus.

## Conséquences

- Le côté natif ne change presque pas (manifeste, un fichier XML, éventuellement un fournisseur de pochettes) ; l'effort est dans l'arbre et les tests.
- Pas de nouvelle dépendance Dart ; pas de réseau ; aucune donnée privée dans le dépôt.
- Le test final est réel : voiture, Pixel en release (D14), après un essai de l'arbre sur le téléphone seul si possible.

## Alternatives écartées

- **Service `MediaBrowserService` natif Kotlin séparé** : deux sessions média, deux files ; contraire à D2 et à BR-013, règle 11.
- **Recherche vocale d'abord** : demande de la reconnaissance de commandes hors du besoin immédiat.
