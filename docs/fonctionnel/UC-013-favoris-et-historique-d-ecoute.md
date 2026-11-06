# UC-013 — Garder ses favoris et retrouver ce qu'on a écouté

**Statut :** Active (validée le 2026-11-05) · **Créée le :** 2026-11-03 · **Ticket :** MPL-065 · **Lié :** UC-005, UC-007, UC-010, FR-011, FR-017, FR-019, FR-023, FR-027, FR-031, BR-004, BR-011, BR-014, ADR-021

## Acteur et but

L'utilisateur veut marquer les pistes qu'il aime et retrouver vite celles qu'il a écoutées récemment, sans refaire une recherche, dans une bibliothèque de plusieurs milliers de pistes.

## Préconditions

- Une bibliothèque indexée (UC-001, UC-003).
- L'historique est enregistré par défaut ; l'utilisateur peut le désactiver et l'effacer (FR-031).

## Scénario nominal

1. L'utilisateur écoute une piste. Dans le lecteur plein écran (FR-017), il touche le cœur : la piste devient favorite, le cœur est plein.
2. Dans l'onglet Pistes (UC-005), trois pastilles sous le champ de recherche : « Toutes », « Favoris », « Récentes ». Il touche « Favoris » : la liste ne montre que ses favoris, triés par titre comme la liste habituelle.
3. Il touche « Récentes » : les pistes qu'il a écoutées, la plus récente en premier, chacune une seule fois.
4. Il touche une piste de la liste filtrée : la lecture suit les règles habituelles (la liste affichée devient la file, FR-011).
5. Il peut retirer un favori du même cœur, ou d'un appui long sur une ligne (FR-019).

## Variantes

- 2a. Aucun favori : un message vide explique comment en ajouter (le cœur du lecteur).
- 3a. Rien d'écouté encore, ou historique désactivé et effacé : message vide.
- 2b. Un favori est sur un disque absent : il reste dans « Favoris », grisé, sauté à la lecture avec le message habituel (BR-001, BR-008).
- 2c. Le fichier d'un favori a disparu de la bibliothèque : il n'est plus affiché ; il revient si le fichier revient (BR-014).
- 6a. Il désactive l'historique dans Réglages : plus rien n'est enregistré ; « Effacer l'historique » vide la liste « Récentes » sans toucher aux favoris.
- 4a. Une recherche est active (UC-010) : elle s'applique à la liste filtrée.

## Hors périmètre

Playlists, plusieurs listes de favoris, favoris d'albums ou d'artistes, statistiques d'écoute affichées (nombre de lectures, graphiques), suggestions « Mix du soir », « Pour vous maintenant » et « Redécouvrir » (MPL-066), dossiers « Favoris » et « Récentes » dans Android Auto, export de l'historique, synchronisation entre appareils.
