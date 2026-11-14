# UC-014 — Arriver sur l'accueil : reprendre ce qu'on écoutait et redécouvrir sa musique

**Statut :** Active (validée le 2026-11-13) · **Créée le :** 2026-11-13 · **Ticket :** MPL-079 · **Lié :** UC-004, UC-007, UC-008, UC-011, UC-013, FR-009, FR-032, FR-033, BR-010, BR-012, BR-014, BR-016, ADR-024 · **Source :** demande du propriétaire du 2026-11-13

> Vocabulaire : dans `FR-014`, « l'accueil » désigne l'écran de bienvenue du premier lancement. Les fiches de MPL-079 appellent « accueil » l'onglet de la bibliothèque et gardent « écran de bienvenue » pour le premier lancement.

## Acteur et but

L'utilisateur ouvre l'application et veut, sans chercher, reprendre ce qu'il écoutait (dernier titre, son album, son artiste) ou tomber sur de la musique qu'il n'a pas écoutée depuis longtemps.

## Préconditions

- Une bibliothèque indexée et lue (UC-001, UC-003) ; l'accès accordé (FR-004).
- Pour « Reprendre » : une piste courante (session restaurée, UC-011) ou au moins une écoute enregistrée (UC-013).

## Scénario nominal

1. L'application s'ouvre sur l'onglet **Accueil** (premier onglet, onglet de départ).
2. Une carte « Reprendre » montre la dernière piste jouée : pochette, titre, « artiste · album ». Le nom de l'artiste et celui de l'album sont des liens (FR-032) ; un bouton lance la lecture (BR-012 : rien ne démarre tout seul).
3. Dessous, « Redécouvertes » : une grille d'albums que l'utilisateur n'a pas écoutés depuis longtemps. Il touche un album : le détail s'ouvre dans l'onglet Albums (UC-008).
4. Il passe sur Pistes, puis revient sur Accueil : la sélection est la même. Il touche « Autres suggestions » : un nouveau tirage s'affiche.
5. Au démarrage suivant, un nouveau tirage est fait.

## Variantes

- 2a. Aucune piste courante mais un historique : la carte montre la dernière écoute enregistrée.
- 2b. Ni piste courante ni écoute : la carte est absente ; si « Redécouvertes » est aussi vide, un état vide explique quoi faire.
- 2c. Historique désactivé dans Réglages (UC-013) : la carte suit la piste courante ; l'historique déjà enregistré reste lu tant qu'il n'est pas effacé.
- 2d. La piste est sur un disque absent : la carte est grisée ; « Lecture » donne le message habituel (BR-001, BR-008).
- 3a. Bibliothèque petite : moins de six albums éligibles, la grille est plus courte ; aucun éligible, la section est absente.
- 3b. Un album tiré disparaît de la bibliothèque pendant la session (réindexation) : sa carte est retirée, sans nouveau tirage.

## Hors périmètre

Playlists manuelles ou automatiques (mood, période, activité : idée MPL-080), « Mix du soir » et « Pour vous maintenant » (MPL-066), liste « Récemment écoutés » sur l'accueil (la pastille « Récentes » de Pistes existe, FR-031), statistiques, Android Auto (BR-013 règle 2 : « Reprendre » y existe déjà), réseau (D15, D26).
