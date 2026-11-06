# ADR-021 — Favoris et historique d'écoute dans la base (schéma v6)

**Statut :** Active (validée le 2026-11-05) · **Date :** 2026-11-03 · **Ticket :** MPL-065 · **Décisions :** D3, D15, D23, D27, D30 · **Fiches :** UC-013, BR-014, FR-031 · **Complète :** ADR-004, ADR-017, ADR-019

## Contexte

Il faut enregistrer des favoris et des écoutes qui survivent à la réindexation, à l'absence d'un disque et au retrait d'un fichier, sans les rattacher à un identifiant interne de piste, et sans alourdir la lecture. L'historique alimentera plus tard des suggestions (MPL-066), qui ont besoin de l'heure de chaque écoute.

## Décision

- **Stockage : la base Drift, schéma v6** (comme ADR-019). Deux tables : `favorites` (`disk_id`, `relative_path`, `added_at`, clé primaire (`disk_id`, `relative_path`)) et `play_events` (`id` auto-incrémenté, `disk_id`, `relative_path`, `played_at` en millisecondes, index sur `played_at` et sur (`disk_id`, `relative_path`)). Pas de clé étrangère vers `tracks` : une identité (BR-004) survit au retrait d'une piste. Migration v5 vers v6 testée à partir du dump de la v5 ; dump v6 versionné ; `*.g.dart` régénérés.
- **Domaine** (`domain/library/`, Dart pur) : modèle `TrackKey` (identité), port `ListeningStore` (`favorites`, `setFavorite`, `recordPlay`, `recentKeys(limit)`, `clearHistory`, `trimHistory(keep)`), adaptateur Drift sous `data/db/`, faux magasin en test. Tests d'abord.
- **Comptage des écoutes : `PlayCounter`** (`domain/playback/services/`, Dart pur, horloge injectable) : écoute `controller.states`, applique le seuil de BR-014 règle 4 (temps joué cumulé de la piste en cours, remis à zéro à chaque changement de piste ou de tour), écrit par le port, regroupe les écritures et rogne l'historique à 20 000 lignes (règle 6). Il suit le réglage `record_history` (clé de plus dans `AppSettings`, ADR-017). Un échec d'écriture est rapporté à un rappel et n'atteint jamais la lecture.
- **Présentation** : fournisseurs Riverpod `favoriteKeysProvider` (ensemble d'identités) et `recentOrderProvider` (identité vers dernière écoute), lus par la liste de pistes (`features/library/`) pour filtrer sans nouvelle requête de pistes : le filtre « Favoris » et « Récentes » s'applique à la liste triée déjà en mémoire (ADR-013, ADR-018).
- **Aucune dépendance, aucune permission, aucun réseau.**

## Conséquences

- Schéma v6 : migration, dump, régénération (CI de régénération).
- Le contrôleur ne change pas : le compteur n'écoute que ses états.
- Le filtre « Récentes » trie par dernière écoute, pas par titre : l'index alphabétique est masqué (BR-014 règle 8).
- Les identités enregistrées sont de la donnée privée : jamais dans les journaux (BR-014 règle 9).

## Alternatives examinées

- **Colonnes `favorite` et `play_count` dans `tracks`.** Simple, mais une piste retirée puis revenue, ou un disque réassocié, perdrait tout ; et un compteur seul perd l'heure d'écoute. Écartée.
- **Un texte JSON dans `app_settings`.** Mêmes raisons qu'ADR-019 (mélange de natures, réécriture entière). Écartée.
- **Compteur seul, sans journal d'écoutes.** Plus petit, mais interdit « Mix du soir » et « Pour vous maintenant » (MPL-066) et « Récentes » par date. Écartée.
- **Écouter plutôt les événements de fin de piste (`completed`).** Rate les pistes écoutées longtemps puis sautées, et ne compte pas les écoutes interrompues. Écartée au profit du seuil de temps joué.

## Risques à vérifier sur le Pixel

- Coût du filtre « Récentes » sur 7 500 pistes et 20 000 écoutes (dernière écoute par identité en mémoire).
- Écriture d'une écoute pendant la lecture : aucune saccade, aucun blocage du fil de l'interface.
- Migration v5 vers v6 sur la base réelle.

## À valider (PO)

- Le schéma v6 et ses deux tables.
- Les écoutes avec l'heure, pas un simple compteur.
- Le seuil et la borne de BR-014 (règles 4 et 6).
