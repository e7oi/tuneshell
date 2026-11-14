# FR-033 — Onglet Accueil : reprendre et redécouvrir

**Statut :** Brouillon (cadrage validé le 2026-11-13, en attente de la maquette Claude Design : `docs/design/BRIEF-MPL-079-accueil.md`) · **Créée le :** 2026-11-13 · **Ticket :** MPL-079 · **Lié :** UC-014, UC-004, FR-007, FR-009, FR-010, FR-016, FR-017, FR-020, FR-032, BR-007, BR-012, BR-014, BR-016, ADR-010, ADR-022, ADR-024 · **Source :** demande du propriétaire du 2026-11-13 ; maquette demandée à Claude Design le 2026-11-13 (décision du propriétaire) ; en attendant, composants et jetons existants

## Besoin

Arriver sur une vue vivante : ce qu'on écoutait, et des albums à redécouvrir.

## Exigences

1. **Onglet.** « Accueil » devient le premier onglet et l'onglet de départ : Accueil, Pistes, Albums, Artistes, Réglages (cinq destinations, barre du bas sous 600 dp, rail au-delà). Il n'existe que lorsque la bibliothèque est affichée ; l'écran de bienvenue, l'explication d'accès et le choix des dossiers du premier lancement sont inchangés (FR-014, FR-009). Le Retour système depuis Pistes, Albums, Artistes ou Réglages ramène sur Accueil ; depuis Accueil, il quitte l'application. L'onglet courant n'est pas conservé d'un lancement à l'autre.
2. **Chargement.** Tant que la bibliothèque n'est pas lue, Accueil montre le même état de chargement que Pistes ; il n'allonge pas l'ouverture.
3. **Carte « Reprendre ».** Pochette (FR-007), titre, « artiste · album » avec les deux liens de FR-032 (ils ouvrent le détail dans l'onglet Albums ou Artistes, ADR-022). Source et cas : BR-016 règles 1 à 4. Un bouton « Lecture » : si la piste est la piste courante du contrôleur, il lance ou reprend la file telle quelle, à sa position (BR-012 règles 6 et 7) et devient « Pause » pendant la lecture ; sinon il met l'album de la piste en file, à partir d'elle (la piste seule si elle n'a pas d'album). Le corps de la carte ouvre le lecteur plein écran (FR-017) quand la piste est la piste courante.
4. **Redécouvertes.** Titre de section, puis une grille de cartes d'album (pochette, titre, artiste, comme FR-020) : deux colonnes en portrait téléphone, davantage en largeur. Toucher une carte ouvre le détail de l'album dans l'onglet Albums (ADR-022 ; Retour ramène à la grille des albums). Une carte d'album d'un disque absent est grisée et s'ouvre quand même (FR-020 exigence 5). Sélection : BR-016 règles 5 à 9.
5. **Autres suggestions.** Un bouton de 48 dp sous la grille (ou dans l'en-tête de la section) refait le tirage (BR-016 règle 8). Pas de tirer-pour-actualiser sur Accueil : il garde le sens « relire les disques » des listes.
6. **États vides.** Aucune carte « Reprendre » et aucune redécouverte : composant d'état vide (BR-007) avec le geste à faire (« Lance une piste, elle reviendra ici »). Seule la grille vide : la section est absente, pas de message.
7. **Pas de bandeau propre.** L'accueil n'affiche pas les bandeaux de disque absent des listes (BR-008) ; l'état est porté par les cartes grisées (voir À valider).
8. **Accessibilité et mise en page.** Zones tactiles d'au moins 48 dp ; carte lue comme un seul élément (« Reprendre : {titre}, {artiste}, {album} ») avec ses liens et son bouton séparés ; cartes d'album lues « Album {titre}, de {artiste} » ; contenu défilant, paysage et texte à 200 % sans couper une zone tactile ; thèmes clair et sombre. Textes dans les fichiers ARB, en français et en anglais.
9. **Réseau et permissions.** Aucun (D15, D26).

## Hors périmètre

Voir UC-014 : playlists (MPL-080), suggestions par moment (MPL-066), liste « Récemment écoutés », cartes séparées « dernier album » et « dernier artiste » (couvertes par les liens de la carte, voir À valider), statistiques, voiture, panneau lecteur permanent (MPL-052).

## À valider (PO)

- **Écart à FR-009 (`Active`)** : exigence 1 (quatre onglets, départ sur Pistes, « pas d'onglet Playlists ou Favoris » : seul le premier point change), exigence 7 (Retour vers Accueil au lieu de Pistes), exigence 10. **Écart à UC-004 (`Active`)** : scénario nominal. Aucune n'est modifiée avant validation.
- **Pistes n'est plus l'onglet de départ.** Autre choix : Accueil en deuxième onglet, départ sur Pistes (l'accueil devient un détour).
- **Album et artiste en liens de la carte, pas en cartes séparées.** La demande d'origine liste « titre / album / artiste ». La carte les montre et les ouvre déjà ; des tuiles dédiées dupliqueraient les liens. Autre choix : trois tuiles (piste, album avec pochette, artiste).
- **Retour depuis un détail ouvert de l'accueil** : grille Albums ou Artistes, pas Accueil (même choix que FR-032). Autre choix : l'onglet Accueil a son propre navigateur et le Retour revient à l'accueil (plus de code, ADR-024).
- **Pas de bandeau de disque absent** sur l'accueil (exigence 7).
- **Texte de l'état vide**, titres des sections et du bouton : sans maquette.

## As-built

À écrire à la livraison.
