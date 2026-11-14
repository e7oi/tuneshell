# FR-033 — Onglet Accueil : pistes et albums oubliés

**Statut :** Active (validée le 2026-11-14, maquette validée par le propriétaire) · **Créée le :** 2026-11-13 · **Ticket :** MPL-079 · **Lié :** UC-014, UC-004, FR-007, FR-009, FR-010, FR-011, FR-016, FR-017, FR-020, BR-007, BR-014, BR-016, ADR-010, ADR-022, ADR-024 · **Source :** demande du propriétaire du 2026-11-13 ; maquette Claude Design, canevas « TuneShell — Onglet Accueil » (écrans 9a à 9h), sources dans `docs/design/screens/source/` (`Accueil.dc.html`, `Lot7-Accueil-clair.dc.html`, `Lot7-Accueil-sombre.dc.html`)

## Besoin

Arriver sur une vue vivante : de la musique à redécouvrir, à un geste.

## Exigences

1. **Onglet.** « Accueil » devient le premier onglet et l'onglet de départ : Accueil, Pistes, Albums, Artistes, Réglages (cinq destinations, barre du bas sous 600 dp, rail au-delà). Il n'existe que lorsque la bibliothèque est affichée ; l'écran de bienvenue, l'explication d'accès et le choix des dossiers du premier lancement sont inchangés (FR-014, FR-009). Le Retour système depuis Pistes, Albums, Artistes ou Réglages ramène sur Accueil ; depuis Accueil, il quitte l'application. L'onglet courant n'est pas conservé d'un lancement à l'autre.
2. **Chargement (9g).** Tant que la bibliothèque n'est pas lue, Accueil montre le titre et un bandeau de progression (`ProgressBanner`, comme Pistes) ; il n'allonge pas l'ouverture.
3. **En-tête.** Titre « Accueil » et, à droite, un bouton « Autres suggestions » (48 dp, icône d'actualisation et libellé) qui refait les deux tirages (BR-016 règle 6). Pas de tirer-pour-actualiser : il garde le sens « relire les disques » des listes.
4. **Pistes oubliées (9a à 9d).** Titre de section « Pistes oubliées », puis jusqu'à trois lignes de 64 dp : pochette de 48 dp (tuile neutre sans pochette, FR-007), titre, « artiste · album » (« Artiste inconnu » en texte simple), durée. Toucher une ligne lit la piste, et **la file est la liste complète de la bibliothèque** ordonnée par artiste, puis album, puis numéro de piste, placée sur la piste touchée (origine « Accueil »). Ordre : artiste de l'album (BR-010 règle 1 ; à défaut l'artiste de la piste, « Artiste inconnu » en dernier), puis titre de l'album, disque, numéro de piste et titre ; les pistes sans album viennent après les albums de leur artiste. Les pistes indisponibles restent dans la file et sont sautées avec le message habituel (BR-001, BR-008). Sélection : BR-016.
5. **Albums oubliés.** Titre de section « Albums oubliés », puis jusqu'à deux cartes d'album sur une ligne de deux colonnes (pochette carrée de rayon 16, titre, « artiste · année », comme FR-020). Toucher une carte ouvre le détail de l'album dans l'onglet Albums (ADR-022 ; Retour ramène à la grille des albums).
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
- **Tri de la file** (exigence 4) : le détail des égalités (artiste sans album, disques multiples) est proposé ; la file complète de plusieurs milliers de pistes se construit comme celle de Pistes (FR-011).
- **Retour depuis un détail ouvert de l'accueil** : grille Albums, pas Accueil (même choix que FR-032). Autre choix : l'onglet Accueil a son propre navigateur (ADR-024).
- **Textes** : « Pistes oubliées » et « Albums oubliés » (choix du propriétaire, 2026-11-14 ; variante possible avec « ? » ou « À retrouver » : un changement de fichier ARB), état vide et bouton proposés dans la maquette.

## As-built

Livré par MPL-079 (2026-11-14, à tester sur le Pixel).

- `lib/features/home/home_page.dart` : écran (en-tête et bouton, bandeau de chargement, état vide, colonne étroite, deux colonnes à partir de `TsSize.compactMax` avec 340 dp de pistes) ; lignes `TrackTile`, cartes `AlbumGridCard`.
- `lib/features/home/home_providers.dart` : `HomeDraw` (tirage gardé en mémoire, `reshuffle()`), `homeContentProvider` (tirage filtré par disponibilité à la lecture).
- `lib/domain/library/services/rediscovery.dart` : sélection (BR-016) ; `ListeningStore.lastPlayedAt()` et sa requête Drift.
- `LibraryGroups.tracksByArtist` : file de l'exigence 4. Origine `HomeOrigin`, libellé « Accueil » dans le lecteur.
- `HomeShell` : cinq destinations, l'accueil d'abord ; Pistes a son propre navigateur pour que le Retour ferme encore la recherche (FR-027), les autres onglets reviennent sur Accueil.
- Tests : `test/features/home/`, `test/domain/library/rediscovery_test.dart`, `test/features/shell/home_shell_test.dart`.
- Non testé sur appareil : voir HOWTO §27.
