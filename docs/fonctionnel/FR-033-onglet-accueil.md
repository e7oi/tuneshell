# FR-033 — Onglet Accueil : pistes et albums à redécouvrir

**Statut :** Brouillon (cadrage validé le 2026-11-13 ; maquette revue et décisions du 2026-11-14 ; passe à `Active` sur validation du propriétaire) · **Créée le :** 2026-11-13 · **Ticket :** MPL-079 · **Lié :** UC-014, UC-004, FR-007, FR-009, FR-010, FR-011, FR-016, FR-017, FR-020, BR-007, BR-014, BR-016, ADR-010, ADR-022, ADR-024 · **Source :** demande du propriétaire du 2026-11-13 ; maquette Claude Design, canevas « TuneShell — Onglet Accueil » (écrans 9a à 9h), sources à rapatrier dans `docs/design/screens/source/` à la validation

## Besoin

Arriver sur une vue vivante : de la musique à redécouvrir, à un geste.

## Exigences

1. **Onglet.** « Accueil » devient le premier onglet et l'onglet de départ : Accueil, Pistes, Albums, Artistes, Réglages (cinq destinations, barre du bas sous 600 dp, rail au-delà). Il n'existe que lorsque la bibliothèque est affichée ; l'écran de bienvenue, l'explication d'accès et le choix des dossiers du premier lancement sont inchangés (FR-014, FR-009). Le Retour système depuis Pistes, Albums, Artistes ou Réglages ramène sur Accueil ; depuis Accueil, il quitte l'application. L'onglet courant n'est pas conservé d'un lancement à l'autre.
2. **Chargement (9g).** Tant que la bibliothèque n'est pas lue, Accueil montre le titre et un bandeau de progression (`ProgressBanner`, comme Pistes) ; il n'allonge pas l'ouverture.
3. **En-tête.** Titre « Accueil » et, à droite, un bouton « Autres suggestions » (48 dp, icône d'actualisation et libellé) qui refait les deux tirages (BR-016 règle 6). Pas de tirer-pour-actualiser : il garde le sens « relire les disques » des listes.
4. **Pistes à redécouvrir (9a à 9d).** Titre de section puis jusqu'à trois lignes de 64 dp : pochette de 48 dp (tuile neutre sans pochette, FR-007), titre, « artiste · album » (« Artiste inconnu » en texte simple), durée. Toucher une ligne lit la piste ; la file est les pistes affichées à partir de celle-ci, d'origine « Accueil · Pistes à redécouvrir » (voir À valider). Sélection : BR-016.
5. **Albums à redécouvrir.** Titre de section puis jusqu'à deux cartes d'album sur une ligne de deux colonnes (pochette carrée de rayon 16, titre, « artiste · année », comme FR-020). Toucher une carte ouvre le détail de l'album dans l'onglet Albums (ADR-022 ; Retour ramène à la grille des albums).
6. **Dernier joué.** Pas de carte propre : le mini-lecteur (FR-016) porte la piste courante, restaurée en pause (BR-012). Il est absent tant que rien n'a été joué (9e).
7. **Indisponible.** Une piste ou un album dont le disque est absent n'est jamais affiché (BR-016 règle 2) ; l'accueil n'a donc ni ligne grisée ni bandeau de disque absent.
8. **États vides.** Aucune piste ni album à proposer : composant d'état vide (BR-007), « Rien à afficher pour l'instant », « Lance une piste, elle reviendra ici. » (9f). Une seule des deux sections vide : elle est absente, sans message. Moins d'éléments que le maximum (9d) : la liste ou la grille est simplement plus courte.
9. **Paysage et écran large (9h).** Rail de navigation à gauche ; les pistes dans une colonne de 340 dp, les albums à droite. Le panneau lecteur permanent reste dans MPL-052.
10. **Accessibilité et mise en page.** Zones tactiles d'au moins 48 dp ; ligne de piste lue « titre, artiste · album, durée » ; carte d'album lue « Album {titre}, de {artiste} » ; contenu défilant sous l'en-tête, texte à 200 % sans couper une zone tactile ; thèmes clair et sombre. Textes dans les fichiers ARB, en français et en anglais.
11. **Réseau et permissions.** Aucun (D15, D26).

## Hors périmètre

Voir UC-014 : playlists (MPL-080), suggestions par moment (MPL-066), liste « Récemment écoutés », carte « dernier joué » ou liens album et artiste sur l'accueil (ils restent dans le lecteur, FR-032), statistiques, voiture, panneau lecteur permanent (MPL-052).

## À valider (PO)

- **Écart à FR-009 (`Active`)** : exigence 1 (quatre onglets, départ sur Pistes, « pas d'onglet Playlists ou Favoris » : seul le premier point change), exigence 7 (Retour vers Accueil au lieu de Pistes), exigence 10. **Écart à UC-004 (`Active`)** : scénario nominal. Aucune n'est modifiée avant validation.
- **Pistes n'est plus l'onglet de départ.** Autre choix : Accueil en deuxième onglet, départ sur Pistes.
- **Toucher une piste** : la file est les trois pistes affichées, à partir de celle touchée. Autre choix : la piste seule, ou son album en file.
- **Retour depuis un détail ouvert de l'accueil** : grille Albums, pas Accueil (même choix que FR-032). Autre choix : l'onglet Accueil a son propre navigateur (ADR-024).
- **Textes** (titres de section « Pistes à redécouvrir » et « Albums à redécouvrir », état vide) : proposés dans la maquette, sans test d'usage. L'intitulé de la section d'albums n'est pas dans la maquette actuelle (à ajouter).
- **Écart de la maquette** : elle montre les deux sections ; les titres des sections seront ceux de l'exigence 4 et 5.

## As-built

À écrire à la livraison.
