# ADR-019 — Session de lecture enregistrée dans la base (schéma v5), restauration sans lecture

**Statut :** Active (validée le 2026-10-28) · **Date :** 2026-10-28 · **Ticket :** MPL-053 · **Décisions :** D15, D26, D30 · **Fiches :** UC-011, BR-012, FR-028 · **Complète :** ADR-004, ADR-015, ADR-017

## Contexte

La file, la piste courante, la position et les modes ne vivent que dans `PlayerController` (mémoire). Android arrête l'application en pause ou la retire des récentes (FR-005.8) ; tout est alors perdu. Il faut les enregistrer et les rétablir sans que le contrôleur dépende d'un stockage, sans démarrer de lecture et sans alourdir le démarrage avec une file de 7 500 pistes.

## Décision

- **Stockage : la base Drift, schéma v5** (ADR-004, ADR-017). Deux tables : `playback_session` (une ligne : index courant, position en millisecondes, aléatoire, répétition, version du format) et `playback_queue` (`position` entier, `disk_id`, `relative_path`, `origin_position` entier nul hors aléatoire ; clé primaire `position`). Pas de clé étrangère vers `tracks` : une entrée est une identité (BR-004), pas un identifiant interne. Migration v4 vers v5 testée à partir du dump de la v4 ; dump v5 versionné ; code Drift régénéré.
- **Domaine** (`domain/playback/`, Dart pur) : `PlaybackSession` (modèle immuable), port `PlaybackSessionStore` (`read`, `write`, `clear`) ; adaptateur Drift sous `data/db/`. Tests d'abord avec un faux magasin.
- **Contrôleur : une seule méthode de plus, `restore(PlaybackSession)`.** Elle pose file, courante, position, modes et ordre d'origine, état « arrêté », intention fausse, sans rien charger ; elle est refusée si une file existe déjà (BR-012 règle 5). La position est gardée pour le premier chargement : `_loadFrom` place le moteur à la position après l'ouverture, une seule fois (BR-012 règle 7). Le contrôleur n'importe aucun stockage.
- **Enregistrement : `SessionKeeper`** (`domain/playback/services/`, Dart pur, horloge et minuteries injectables) écoute `controller.states`, compare file et courante (`entryIds`, index) pour décider si la **file** a changé, et regroupe les écritures (délai court après un changement de file ; position au plus toutes les 10 s pendant la lecture ; écriture immédiate à la pause et à l'arrêt). Une écriture de position ne réécrit pas la file. Un `flush()` est appelé quand l'application passe en arrière-plan et quand elle est retirée des récentes (avant la fin du processus de FR-005.8).
- **Restauration : `SessionRestorer`** dans `app/` (câblage), après `controller.start()` et la première lecture de la bibliothèque depuis la base (pas après l'indexation) : retire les entrées inconnues, calcule la nouvelle courante (BR-012 règles 8 et 9), appelle `restore`. Elle ne bloque pas `runApp` : le mini-lecteur apparaît quand elle a fini.
- **Réglage** : une clé `resume_playback` dans `AppSettings` (ADR-017), lue par le gardien et par le restaurateur ; désactivé, le gardien efface la session et n'écrit plus.
- **Écritures de la file** : remplacement complet dans une transaction (suppression puis insertion par lots). 7 500 lignes de deux textes courts : de l'ordre de la dizaine de millisecondes, hors du fil de l'interface si Drift le permet ; à mesurer sur le Pixel. Une file ne change qu'à une action de l'utilisateur, pas à chaque piste.
- **Aucune dépendance, aucune permission, aucun réseau.**

## Conséquences

- Schéma v5 : migration, dump, régénération (`*.g.dart` versionnés, CI de régénération).
- Un nouvel état à garder cohérent : file, ordre d'origine et courante enregistrés ensemble, dans une transaction.
- `PlayerController` change de façon limitée (une méthode, une position de départ différée) : les tests existants doivent rester verts sans modification.
- Le placement à la position dépend du moteur : à vérifier sur le Pixel avec `media_kit` (placement avant ou après la durée connue, contrat de `AudioEngine`), voir risques.
- Les chemins enregistrés sont de la donnée privée : jamais dans les journaux (BR-012 règle 13, D27).

## Alternatives examinées

- **Un seul texte JSON dans `app_settings`.** Simple, mais une file de 7 500 pistes dans un champ de réglage mélange deux natures de données, réécrit tout à chaque changement de position si on n'y prend garde, et se migre mal. Écartée.
- **Enregistrer seulement la piste courante et la position, pas la file.** Plus léger ; mais « reprendre » perd le reste de l'album ou de la liste, ce qui est le cœur du besoin. Écartée.
- **Identifiants internes des pistes (clé étrangère).** Plus compact ; mais la réindexation les garde seulement tant que le fichier existe (BR-004 règle 2), et une piste d'un disque retiré les ferait échouer à l'écriture. L'identité (disque, chemin) est stable et suffit. Écartée.
- **Reprendre la lecture si elle jouait à la fermeture.** Écartée : le son ne part jamais tout seul (BR-005, FR-005).
- **Démarrer le service au premier plan et la session média à la restauration** (pour qu'une touche média ou la notification relance la musique). Écartée : FR-005 (aucune notification sans « Lecture ») ; peut être un ticket à part.
- **`shared_preferences` ou fichier.** Même raison qu'ADR-017. Écartée.

## Risques à vérifier sur le Pixel

- Placement du moteur à la position enregistrée juste après `open`, avant que la durée soit connue (contrat `AudioEngine`) ; sinon le faire à l'arrivée de la durée.
- Coût de l'écriture et de la lecture de 7 500 entrées ; temps jusqu'à l'apparition du mini-lecteur après le premier cadre.
- Enregistrement fiable quand Android retire l'application des récentes en pause (le `flush` a-t-il le temps de finir avant la fin du processus ?).

## À valider (PO)

- Le schéma v5 et les deux tables (ci-dessus).
- La perte maximale de 10 s de position après une mort brutale du processus (BR-012 règle 3).
- Le stockage de l'ordre d'origine de l'aléatoire (colonne `origin_position`) plutôt que de le perdre à la fermeture (la désactivation de l'aléatoire garderait alors l'ordre mélangé, écart à BR-009 règle 2).

## As-built

MPL-053, 2026-10-28, test appareil non fait (D14). Réalisé comme décidé, avec ces précisions : le port a quatre méthodes (`read`, `writeQueue`, `writeProgress`, `clear`) et l'adaptateur Drift (`lib/data/db/drift_playback_session_store.dart`) écrit la file par lots de 500 dans une transaction ; les tables sont `playback_session` (classe `PlaybackSessions`) et `playback_queue` (classe `PlaybackQueueEntries`), la colonne `origin_position` donnant la place de l'entrée dans l'ordre d'origine ; la migration v4 vers v5 est testée avec des données (`migration_test.dart`) ; `SessionKeeper` reçoit un réglage `enabled` et une méthode `adopt` ; la restauration est dans `lib/app/session_restore.dart` et le câblage dans `lib/app/session_keeping.dart`. Une lecture illisible (dommage, incohérence) rend null dans l'adaptateur, ce qui efface la session. Mesures de performance sur 7 500 pistes : non faites (tests sur 7 600 entrées en mémoire seulement).
