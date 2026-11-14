# UC-014 — Arriver sur l'accueil : reprendre ce qu'on écoutait et redécouvrir sa musique

**Statut :** Active (validée le 2026-11-13, révisée le 2026-11-14) · **Créée le :** 2026-11-13 · **Ticket :** MPL-079 · **Lié :** UC-004, UC-007, UC-008, UC-011, UC-013, FR-009, FR-032, FR-033, BR-010, BR-012, BR-014, BR-016, ADR-024 · **Source :** demande du propriétaire du 2026-11-13

> Vocabulaire : dans `FR-014`, « l'accueil » désigne l'écran de bienvenue du premier lancement. Les fiches de MPL-079 appellent « accueil » l'onglet de la bibliothèque et gardent « écran de bienvenue » pour le premier lancement.

## Acteur et but

L'utilisateur ouvre l'application et veut, sans chercher, tomber sur de la musique qu'il n'a pas écoutée depuis longtemps. Ce qu'il écoutait en dernier est déjà dans le mini-lecteur.

## Préconditions

- Une bibliothèque indexée et lue (UC-001, UC-003) ; l'accès accordé (FR-004).

## Scénario nominal

1. L'application s'ouvre sur l'onglet **Accueil** (premier onglet, onglet de départ). S'il y a une piste courante (restaurée, UC-011), le mini-lecteur est déjà là, en pause : c'est le « dernier joué » ; l'accueil ne le répète pas.
2. « Pistes oubliées » : trois pistes que l'utilisateur n'a pas écoutées depuis longtemps, avec pochette, titre, « artiste · album » et durée. Il en touche une : elle est lue, et la file est toute la bibliothèque, par artiste, album et numéro de piste, à partir d'elle.
3. « Albums oubliés » : deux cartes d'album. Il touche un album : le détail s'ouvre dans l'onglet Albums (UC-008).
4. Il passe sur Pistes, puis revient sur Accueil : la sélection est la même. Il touche « Autres suggestions » en haut de l'écran : de nouvelles pistes et de nouveaux albums s'affichent.
5. Au démarrage suivant, un nouveau tirage est fait.

## Variantes

- 2a. Rien n'a été joué : pas de mini-lecteur ; les redécouvertes sont là.
- 2b. Une piste ou un album est indisponible (disque absent, BR-001) : il n'est pas tiré et n'apparaît pas. S'il le devient en cours de session, il disparaît sans remplaçant.
- 3a. Bibliothèque petite : moins de trois pistes ou de deux albums éligibles ; une section sans élément est absente.
- 3b. Ni piste ni album à proposer, et rien de joué : un état vide indique quoi faire.
- 3c. Un album tiré disparaît de la bibliothèque (réindexation) : sa carte est retirée, sans nouveau tirage.

## Hors périmètre

Playlists manuelles ou automatiques (mood, période, activité : idée MPL-080), « Mix du soir » et « Pour vous maintenant » (MPL-066), liste « Récemment écoutés » ou carte « dernier joué » sur l'accueil (la pastille « Récentes » de Pistes existe, FR-031), statistiques, Android Auto (BR-013 règle 2 : « Reprendre » y existe déjà), réseau (D15, D26).
