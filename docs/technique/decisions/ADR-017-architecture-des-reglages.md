# ADR-017 — Architecture des réglages : table dans la base, lecture avant le premier écran, `dynamic_color`, choix des dossiers en page

**Statut :** Brouillon · **Date :** 2026-10-25 · **Ticket :** MPL-051 · **Décisions :** D15, D30 · **Fiches :** UC-009, FR-023, FR-024, FR-025, FR-026 · **Complète :** ADR-004, ADR-010, ADR-016

## Contexte

L'application n'a aucun réglage retenu : le thème suit le système, l'index est à droite, le casque met toujours en pause, l'indexation a lieu à chaque démarrage. L'écran Réglages (maquette 8e) les rend choisissables, ce qui demande un stockage, la lecture des valeurs avant le premier écran (sinon le thème clignote), une façon d'obtenir les couleurs d'Android, et un accès au choix des dossiers depuis Réglages alors qu'il est aujourd'hui un état de la vue Pistes (`LibraryFolderChoice`, FR-003.4).

## Décision

- **Stockage : une table de la base Drift existante**, `app_settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)`, schéma **v4**, avec migration testée à partir du dump de la v3 (ADR-004). Pas de nouvelle dépendance, un seul stockage, des migrations déjà outillées. Les valeurs sont des textes (`system`, `true`…) ; une valeur absente ou inconnue donne la valeur par défaut.
- **Domaine** (`domain/settings/`, Dart pur) : `AppSettings` (immuable : thème, couleurs dynamiques, index à gauche, pause au débranchement, actualisation au démarrage), `ThemeChoice`, et un port `SettingsStore` (`readAll`, `write`). La lecture indulgente et l'écriture des clés sont du domaine, testées d'abord. L'adaptateur Drift est sous `data/db/`.
- **Lecture avant le premier écran** : `main()` lit les réglages (la base s'ouvre) avant `runApp`, et les fournit au conteneur ; les écrans lisent `appSettingsProvider` sans état de chargement. Une lecture qui échoue donne les valeurs par défaut. Un changement met à jour l'état d'abord, puis écrit ; une écriture qui échoue est journalisée et ne défait pas l'affichage.
- **Thème** : `MaterialApp.themeMode` vient du réglage. Les couleurs d'Android viennent de **`dynamic_color`** (`DynamicColorBuilder`) : les schémas ne sont passés à `TsTheme.light/dark(dynamicScheme:)` que si le réglage est actif et qu'Android en fournit ; `TsColors` reste fixe (conception, `HANDOFF.md` §2.1). Flutter n'expose pas ces couleurs sans paquet.
- **Pause au débranchement** : `InterruptionPolicy` reçoit une fonction `pauseOnUnplug` qu'elle lit à l'événement (le domaine ne connaît pas Riverpod). **Actualisation au démarrage** : `LibraryController` lit le réglage au démarrage. Les deux, tests d'abord.
- **Index à gauche** : un fournisseur du réglage donne `alignStart` des trois index (Pistes, Albums, Artistes) ; la table des rectangles d'exclusion (ADR-016) n'a rien à changer.
- **Choix des dossiers en page poussée** : ouvert depuis Réglages, le choix est une page (`FolderChoicePage`) du navigateur de l'onglet, qui montre `FolderChoiceView` et lit les dossiers par l'indexeur ; « Valider » ferme la page et appelle `confirmFolders`. L'état `LibraryFolderChoice` du contrôleur ne sert plus qu'au premier lancement et à la liste vide ; la branche « annulable » du contrôleur (`_beforeChoice`, `cancelFolderChoice`) disparaît. Cela règle aussi la limite connue de FR-009 (le Retour ferme le choix d'un autre onglet).
- **Tirer pour actualiser** : `RefreshIndicator` autour des trois listes, qui appelle `LibraryController.refresh()` ; le cercle dure jusqu'à la fin de l'indexation des fichiers.
- **Onglet Réglages** : même navigateur d'onglet que Albums et Artistes (ADR-016) ; le Retour du système y entre d'abord.
- **Version** : une constante `appVersion` (`lib/app/app_info.dart`) et un test qui la compare à la ligne `version:` de `pubspec.yaml`. Pas de `package_info_plus`, pas de code natif.
- **Licences** : `showLicensePage` de Flutter ; la licence de l'application (GPL-3.0-or-later) et celles des polices (OFL) y sont ajoutées par `LicenseRegistry`. Pas d'ouverture de page web : l'adresse du code est du texte.
- **Dépendance** : `dynamic_color` **2.1.0** (et `material_color_utilities` 0.13.0), épinglées (D30). Vérifiée compatible avec le Flutter épinglé par un essai d'ajout sans écriture. Licences et poids de l'APK à vérifier à l'implémentation ; aucune permission ajoutée (D15).

## Conséquences

- Schéma v4 : migration, dump de schéma, code Drift régénéré (`*.g.dart` versionnés, CI de régénération).
- `main()` attend la base avant le premier cadre : quelques dizaines de millisecondes, derrière l'écran de démarrage natif.
- Le contrôleur de la bibliothèque perd une branche ; ses tests et ceux de la page changent (FR-003.4 passe par la page).
- Trois fiches `Active` s'écartent (FR-011.2, FR-003.7, BR-005 règle 5) : écarts dans FR-025, aucune n'est modifiée.

## Alternatives examinées

- `shared_preferences` : une dépendance native de plus pour quelques clés, alors que la base existe. Écartée.
- Un fichier JSON : réinvente la migration et l'atomicité. Écartée.
- Une seconde base pour les réglages : deux ouvertures, rien de gagné. Écartée.
- Lire les réglages après le premier cadre : le thème clignote. Écartée.
- Le Retour d'Android, ou « Dossiers » qui ramène sur Pistes pour ouvrir le choix : zéro refonte, mais l'utilisateur quitte Réglages et le Retour ne revient pas où il était. Écartée.
- `url_launcher` pour le code source : dépendance et intention natives pour une ligne. Écartée pour ce ticket.

## À valider (PO)

- La dépendance `dynamic_color` 2.1.0 (D30).
- Le schéma v4 et la lecture des réglages avant le premier écran.
- La suppression de la branche « annulable » du contrôleur au profit d'une page (refonte d'un écran livré par MPL-044 ; testée par les tests de widgets, à revoir sur le Pixel).

## As-built

À écrire à la livraison.
