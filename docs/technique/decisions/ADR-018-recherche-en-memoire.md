# ADR-018 — Recherche en mémoire dans `features/`, sans FTS5 ni schéma

**Statut :** Active (validée le 2026-10-28) · **Date :** 2026-10-28 · **Ticket :** MPL-055 · **Décisions :** D3 · **Fiches :** UC-010, FR-027, BR-011 · **Complète :** ADR-010, ADR-013, ADR-016

## Contexte

La recherche porte sur les titres, artistes et albums de plus de 7 500 pistes, à chaque frappe, sans tenir compte de la casse ni des accents. D3 note que le plein texte FTS5 de Drift est possible. Les listes sont déjà chargées en mémoire (`listedTracksProvider`, deux émissions par seconde au plus) et les groupes d'albums et d'artistes sont déjà calculés à partir d'elles (ADR-016).

## Décision

- **Filtre en mémoire**, sans FTS5, sans table, sans migration (le schéma reste v4). Un modèle pur dans `features/library/` (comme `LibraryListModel`) construit, à chaque émission de la liste, un texte replié par ligne (titre, artiste, artiste de l'album, album) ; la requête repliée est coupée en mots, chaque mot doit se trouver dans ce texte (BR-011).
- **Repli partagé** : la fonction de repli de `sortKey` (`lib/ui/widgets/alphabet_index.dart`) est exposée (`foldText`) et utilisée aussi par le modèle de recherche ; `features/` peut importer `ui/` (règle 3), et `domain/` n'est pas concerné.
- **État de la requête** : un `Notifier` par vue (Pistes, Albums, Artistes), tenu par la coquille tant que l'application tourne, vidé à la fermeture de la recherche (FR-027.3).
- **Provenance de la file** : une valeur de plus dans `QueueOrigin` (« Recherche · {requête} »), sans nouvelle opération du contrôleur (ADR-016).
- **Composant** `SearchField` dans `ui/widgets/` (ADR-010).

## Conséquences

- Aucun code natif, aucun schéma, pas de latence de requête : le résultat est calculé dans l'image de la frappe (BR-011, règle 8 : 16 ms pour 10 000 pistes, à mesurer en profile sur le Pixel).
- Mémoire : un texte replié d'une centaine de caractères par piste (environ 1,5 Mo pour 7 500 pistes).
- Limite : au-delà de 50 000 pistes le filtre ne tient plus dans une image ; il faudrait FTS5 (tokenizer `unicode61 remove_diacritics`), un schéma v5 et une nouvelle ADR.

## Options écartées

- **FTS5 de Drift** : migration et dumps de schéma, index à tenir à jour pendant la lecture des tags, requêtes asynchrones (latence, résultats qui arrivent après la frappe suivante), repli des accents à régler ; sans gain mesurable pour la taille visée.
- **Recherche par MediaStore** : ne voit pas les disques lus par SAF (D25).
- **Recherche globale à résultats mélangés** : une autre fonction, un autre écran ; non demandée.
