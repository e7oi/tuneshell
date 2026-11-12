# ADR-023 — Recherche et dossiers par lettre dans l'arbre média de la voiture

**Statut :** Brouillon · **Date :** 2026-11-12 · **Ticket :** MPL-075 · **Fiches :** BR-015, BR-013, BR-011, FR-029 · **Complète :** ADR-020

## Contexte

Le découpage par lettres existe encore dans `LibraryMediaTree` (`maxChildren`, `_cut`), mais `media_browsing.dart` le neutralise depuis MPL-064 (`_wholeLists`) ; MPL-074 y a ajouté la pagination du gestionnaire. La voiture n'a aucune recherche : `PlayerAudioHandler` ne déclare pas la recherche à Android Auto et ne redéfinit pas `search`. Le domaine ne connaît ni Flutter ni les fournisseurs de `features/` (règle 1 de CLAUDE.md), donc il ne peut pas réutiliser l'index de recherche de l'interface (ADR-018).

## Décision

- **Lettres** : rendre à `maxChildren` sa valeur de seuil (100) pour les trois listes, sans toucher à `_cut` ; la pagination du gestionnaire reste le filet pour un niveau de plus de 400 lignes.
- **Recherche** : le port `MediaTree` reçoit `search(String query)` qui rend des `MediaNode` jouables. `LibraryMediaTree` la fait en mémoire avec le même `fold` que ses clés de tri : un texte de recherche par piste (titre affiché, artiste, artiste de l'album, album) fait une fois à la première requête, puis tous les mots de la requête doivent s'y trouver (BR-011, règles 3 et 4). Le texte de BR-011 reste la référence ; un test commun vérifie que l'interface et l'arbre rendent les mêmes pistes pour les mêmes requêtes sur un jeu de pistes fictives.
- **Déclaration** : `androidBrowsableRootExtras` de la configuration de `audio_service` reçoit `android.media.browse.SEARCH_SUPPORTED: true` ; `PlayerAudioHandler.search` appelle l'arbre. Les résultats portent l'identifiant `t|search|…` : l'action de lecture met en file la liste des résultats (BR-015, règle 6).
- Aucune dépendance nouvelle, aucun réseau.

## Conséquences

- Une requête relit la bibliothèque jouable en mémoire : O(pistes) mesuré à 10 000 pistes sous 100 ms ; au-delà de 50 000, revoir (comme ADR-018).
- Deux implémentations de la correspondance (interface et arbre) à garder alignées, d'où le test commun.
- Le gestionnaire doit tolérer une requête vide (liste vide) et une requête très longue (coupée).

## Alternatives examinées

- Réutiliser l'index de `features/` depuis le gestionnaire : franchit la règle de dépendance du domaine et lie la voiture à un état d'interface ; écartée.
- FTS5 dans Drift : disproportionné pour quelques milliers de pistes (ADR-018) ; écartée.
- Garder toutes les listes entières et paginées : c'est l'état actuel, jugé trop long à faire défiler et sans accès par lettre par le propriétaire ; écartée.

## À valider (PO)

- Le seuil de 100 entrées et la pagination à 400 comme filet.
- Une seule recherche pour la voiture, rendant des pistes seulement.
