# ADR-024 — Accueil : sélection des redécouvertes et lecture de l'historique

**Statut :** Brouillon · **Date :** 2026-11-13 · **Ticket :** MPL-079 · **Décisions :** D3, D15, D27 · **Fiches :** UC-014, BR-016, FR-033, BR-014, FR-032 · **Complète :** ADR-016, ADR-021, ADR-022

## Contexte

L'accueil a besoin de deux choses que l'application sait presque faire : la dernière piste jouée (piste courante du contrôleur, ou dernière écoute de l'historique) et un tirage d'albums peu écoutés. L'historique existe (`play_events`, ADR-021) mais `ListeningStore.recent()` rend les pistes sans leur date, alors que la règle « pas écoutée depuis 30 jours » (BR-016 règle 6) en a besoin. Le tirage doit rester stable pendant la session.

## Décision

- **Pas de changement de schéma.** `play_events` a déjà `played_at` et un index sur (`disk_id`, `relative_path`). Le port `ListeningStore` (`domain/library/ports/`) gagne `lastPlayedAt()` : dernière écoute de chaque identité (`GROUP BY` côté Drift, un seul passage), faux magasin mis à jour. `recent()` ne change pas.
- **Calcul dans le domaine.** Un service pur `Rediscovery` (`domain/library/services/`) reçoit les groupes d'albums (BR-010), les dernières écoutes, les favoris, l'horloge et un `Random` injectés ; il rend la sélection. Tests d'abord (niveaux, seuil de 30 jours, disque absent, petite bibliothèque, album de la piste courante exclu, tirage reproductible avec un `Random` à graine).
- **Tirage gardé pour le processus.** Un notifier Riverpod dans `app/providers/` tient le tirage, créé au premier affichage de l'accueil et jamais invalidé par un changement d'onglet, une rotation ou une réindexation (il filtre seulement les albums disparus à la lecture). `reshuffle()` refait le tirage en écartant, si possible, les albums déjà affichés. Rien n'est écrit sur disque.
- **« Reprendre ».** Dérivé du `playerStateProvider` (piste courante) puis de l'historique : aucun état propre. Album et artiste via `LibraryGroups.albumOf` et `artistOf` (ADR-022). Les liens et l'ouverture d'un album passent par `browseRequestProvider`.
- **Coquille.** `HomeShell` passe à cinq destinations ; l'index de l'onglet est déduit de l'énumération des onglets, plus de nombres écrits (`_select(1/2)` aujourd'hui, à remplacer). L'onglet Accueil n'a pas de navigateur propre : le détail s'ouvre dans Albums ou Artistes (voir alternatives).
- **Découpage de présentation.** Écran sous `features/home/`, cartes réutilisées de `ui/` ; tout nouveau composant (carte « Reprendre ») va dans `ui/widgets/` sans logique (ADR-010). Aucune dépendance, aucune permission, aucun réseau.

## Conséquences

- Un port élargi (une méthode), une requête de plus, aucune migration.
- MPL-077 (« Précédent » suit l'historique réel) a besoin d'une trace de lecture en ordre, par session, qui n'est pas `play_events` (seuil de 30 s, une entrée par piste dans « Récentes »). Les deux sont indépendants : MPL-079 ne lit que `play_events` et la piste courante, et ne dépend pas de MPL-077.
- Coût : dernière écoute de 20 000 lignes groupées, et calcul sur quelques centaines d'albums, une fois par démarrage et à chaque « Autres suggestions » ; à mesurer sur le Pixel (7 500 pistes).

## Alternatives examinées

- **Nouveau tirage à chaque affichage de l'onglet.** Instable sous les doigts de l'utilisateur ; écartée au profit du démarrage plus l'action explicite (BR-016 règle 8).
- **Tirage enregistré dans la base.** Donnerait la non-répétition d'un démarrage à l'autre, au prix d'une table ou d'un réglage de plus ; reportée.
- **Tirage au hasard dans SQL.** Le groupe d'album est calculé en mémoire (BR-010) ; une requête serait de toute façon refaite en mémoire. Écartée.
- **Redécouvertes de pistes.** Pas de pochette ni de détail à ouvrir ; il faudrait mettre une file en place à chaque toucher. Écartée (À valider de BR-016).
- **Navigateur propre à l'onglet Accueil** (Retour vers l'accueil depuis un détail) : possible avec `detailBuilder` comme Albums et Artistes, mais le détail existerait dans deux navigateurs ; reporté tant que le propriétaire ne l'a pas demandé.

## Risques à vérifier sur le Pixel

- Premier affichage de l'accueil avec 7 500 pistes et 20 000 écoutes : pas de saccade.
- Rotation et retour du lecteur : la grille ne change pas.
- Indices d'onglet : les liens du lecteur ouvrent toujours Albums et Artistes (cinq destinations).

## À valider (PO)

- Le port élargi (`lastPlayedAt`), sans schéma nouveau.
- Le tirage gardé en mémoire seulement (pas de non-répétition entre deux lancements).
