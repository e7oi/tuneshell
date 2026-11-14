# ADR-024 — Accueil : sélection des redécouvertes et lecture de l'historique

**Statut :** Active (validée le 2026-11-13, révisée le 2026-11-14) · **Date :** 2026-11-13 · **Ticket :** MPL-079 · **Décisions :** D3, D15, D27 · **Fiches :** UC-014, BR-016, FR-033, BR-014, FR-032 · **Complète :** ADR-016, ADR-021, ADR-022

## Contexte

L'accueil propose trois pistes et deux albums à redécouvrir (BR-016). L'historique existe (`play_events`, ADR-021) mais `ListeningStore.recent()` rend les pistes sans leur date, alors que la règle « pas écoutée depuis 30 jours » en a besoin. Le tirage doit rester stable pendant la session, et ne jamais contenir d'élément indisponible. La carte « dernier joué » a été retirée (révision du 2026-11-14) : le mini-lecteur la remplace.

## Décision

- **Pas de changement de schéma.** `play_events` a déjà `played_at` et un index sur (`disk_id`, `relative_path`). Le port `ListeningStore` (`domain/library/ports/`) gagne `lastPlayedAt()` : dernière écoute de chaque identité (`GROUP BY` côté Drift, un seul passage), faux magasin mis à jour. `recent()` ne change pas.
- **Calcul dans le domaine.** Un service pur `Rediscovery` (pistes et albums, disponibilité incluse) (`domain/library/services/`) reçoit les groupes d'albums (BR-010), les dernières écoutes, les favoris, l'horloge et un `Random` injectés ; il rend la sélection. Tests d'abord (niveaux, seuil de 30 jours, disque absent, petite bibliothèque, album de la piste courante exclu, tirage reproductible avec un `Random` à graine).
- **Tirage gardé pour le processus.** Un notifier Riverpod dans `app/providers/` tient le tirage, créé au premier affichage de l'accueil et jamais invalidé par un changement d'onglet, une rotation ou une réindexation (il filtre seulement les albums disparus à la lecture). `reshuffle()` refait le tirage en écartant, si possible, les albums déjà affichés. Rien n'est écrit sur disque.
- **Affichage.** Le tirage est filtré à la lecture par la disponibilité des disques (un élément indisponible disparaît, revient avec son disque, BR-016 règle 7). L'ouverture d'un album passe par `browseRequestProvider` ; lire une piste met en file les pistes affichées (`PlayerController`, origine propre). Pas de carte « dernier joué » : le mini-lecteur existant la porte.
- **Coquille.** `HomeShell` passe à cinq destinations ; l'index de l'onglet est déduit de l'énumération des onglets, plus de nombres écrits (`_select(1/2)` aujourd'hui, à remplacer). L'onglet Accueil n'a pas de navigateur propre : le détail s'ouvre dans Albums ou Artistes (voir alternatives).
- **Découpage de présentation.** Écran sous `features/home/`, cartes réutilisées de `ui/` ; tout nouveau composant (ligne de piste de l'accueil) va dans `ui/widgets/` sans logique (ADR-010). Aucune dépendance, aucune permission, aucun réseau.

## Conséquences

- Un port élargi (une méthode), une requête de plus, aucune migration.
- MPL-077 (« Précédent » suit l'historique réel) a besoin d'une trace de lecture en ordre, par session, qui n'est pas `play_events` (seuil de 30 s, une entrée par piste dans « Récentes »). Les deux sont indépendants : MPL-079 ne lit que `play_events` et la piste courante, et ne dépend pas de MPL-077.
- Coût : dernière écoute de 20 000 lignes groupées, et calcul sur quelques centaines d'albums, une fois par démarrage et à chaque « Autres suggestions » ; à mesurer sur le Pixel (7 500 pistes).

## Alternatives examinées

- **Nouveau tirage à chaque affichage de l'onglet.** Instable sous les doigts de l'utilisateur ; écartée au profit du démarrage plus l'action explicite (BR-016 règle 8).
- **Tirage enregistré dans la base.** Donnerait la non-répétition d'un démarrage à l'autre, au prix d'une table ou d'un réglage de plus ; reportée.
- **Tirage au hasard dans SQL.** Le groupe d'album est calculé en mémoire (BR-010) ; une requête serait de toute façon refaite en mémoire. Écartée.
- **Albums seulement** (cadrage du 2026-11-13) : écarté à la maquette ; trois pistes s'ajoutent aux deux albums (décision du 2026-11-14).
- **Navigateur propre à l'onglet Accueil** (Retour vers l'accueil depuis un détail) : possible avec `detailBuilder` comme Albums et Artistes, mais le détail existerait dans deux navigateurs ; reporté tant que le propriétaire ne l'a pas demandé.

## Risques à vérifier sur le Pixel

- Premier affichage de l'accueil avec 7 500 pistes et 20 000 écoutes : pas de saccade.
- Rotation et retour du lecteur : la grille ne change pas.
- Indices d'onglet : les liens du lecteur ouvrent toujours Albums et Artistes (cinq destinations).

## À valider (PO)

- Le port élargi (`lastPlayedAt`), sans schéma nouveau.
- Le tirage gardé en mémoire seulement (pas de non-répétition entre deux lancements).
