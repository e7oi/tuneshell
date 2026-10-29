# FR-029 — Parcourir et lire depuis Android Auto

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-060 · **Décisions :** D6, D12, D15 · **Lié :** UC-012, BR-013, FR-005, FR-022, ADR-020

## Besoin

TuneShell apparaît dans Android Auto, se parcourt à l'écran de la voiture et se commande au volant. L'interface est fournie par Android Auto ; TuneShell ne fournit que l'arbre et la lecture.

## Exigences

1. **Déclaration.** L'application se déclare application multimédia d'Android Auto ; aucune permission ajoutée, pas d'`INTERNET` (D15). Elle est visible dans le lanceur d'Android Auto.
2. **Navigation.** La racine et les niveaux suivent BR-013. Chaque élément montre titre, sous-titre (artiste pour un album ou une piste) et pochette quand elle existe ; sans pochette, une icône neutre de la marque.
3. **Lecture.** Albums et artistes s'ouvrent comme des dossiers : un artiste donne ses albums, un album donne ses pistes. Choisir une piste lance la lecture avec la file de sa liste (BR-013, règle 5). La première entrée de la racine, quand une file existe, est la piste courante : la choisir reprend cette file telle quelle (BR-013, règle 2).
4. **Commandes.** Lecture, pause, précédent, suivant et déplacement dans la piste agissent sur la lecture en cours, comme dans la notification (FR-005). L'écran de la voiture montre la piste, l'artiste, l'album, la pochette et la position.
5. **Téléphone non ouvert.** Tout fonctionne sans que l'écran du téléphone soit allumé et sans que l'application ait été ouverte depuis le démarrage du téléphone (ADR-020).
6. **Réactivité.** La racine s'affiche sans attente perceptible ; une liste longue s'affiche en un temps que la voiture accepte (seuil mesuré, voir À valider).
7. **Erreurs.** Une piste illisible ou un disque éjecté se signalent par l'état de lecture d'Android Auto, avec les messages de BR-003 et BR-008, pas par un écran du téléphone.
8. **Pas de saisie.** Aucun champ de texte ni recherche (règle de conduite d'Android Auto ; recherche vocale hors périmètre).
9. **Textes.** Libellés fixes (« Reprendre », « Albums », « Artistes », « Pistes », message de bibliothèque vide) dans les fichiers ARB, français et anglais.

## Hors périmètre

Recherche vocale, commandes vocales, Android Automotive OS, CarPlay, publication Play Store, mise en page personnalisée.

## À valider (PO)

- Exigence 6 : seuil de temps d'affichage à fixer après la mesure en voiture.
- Les actions personnalisées « Aléatoire » et « Répéter » ne sont pas proposées dans la voiture (comme dans la notification, ADR-015).

## As-built

MPL-060, 2026-10-28, test appareil non fait (D14 : il exige la voiture). Arbre : `LibraryMediaTree` (`lib/domain/playback/services/library_media_tree.dart`, Dart pur, port `MediaTree`, modèle `MediaNode` et actions `ResumeAction` et `PlayTracks`), construit à la demande par `currentMediaTree` (`lib/app/media_browsing.dart`) à partir des vues Albums, Artistes et Pistes. `PlayerAudioHandler` répond à `getChildren`, `getMediaItem` et `playFromMediaId` ; choisir une piste efface la provenance de la file du lecteur (`onQueueChosen`). Déclaration : métadonnée `com.google.android.gms.car.application` et `res/xml/automotive_app_desc.xml`, aucune permission ajoutée. Texte de la bibliothèque vide : clé ARB `carEmptyLibrary`. Tests : `library_media_tree_test`, `player_audio_handler_test` (groupe FR-029), `media_browsing_test`. Protocole : `HOWTO.md` §23.

- Seuil de découpage des longues listes : 100 entrées (`maxChildren`), à mesurer en voiture (exigence 6).
- `keepMediaTreeReadable` garde les groupes d'albums et d'artistes calculés pendant toute la vie du processus (sinon Riverpod met le flux en pause) : coût processeur à surveiller pendant une indexation.
- Les pochettes sont données en `file://` (comme la notification) ; si Android Auto ne les affiche pas, passer par un `content://` (ADR-020, risque 2).
