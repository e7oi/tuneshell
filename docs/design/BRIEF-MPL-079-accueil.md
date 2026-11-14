# Brief Claude Design — Onglet Accueil (MPL-079)

> À coller dans Claude Design avec le dossier de conception v0.4 (`HANDOFF.md`, `screens/source/*.dc.html`, jetons). Rédigé le 2026-11-13 ; fiches : `UC-014`, `BR-016`, `FR-033`. Les exigences de comportement font foi dans `FR-033` et `BR-016` ; ce brief dit seulement ce que la maquette doit montrer.

## Demande

Compléter la conception v0.4 avec un **nouvel onglet « Accueil »**, premier des cinq onglets (Accueil · Pistes · Albums · Artistes · Réglages), qui sert d'écran de départ. Il reprend le langage visuel existant (« Carapace sonore », Material 3, jetons de `tuneshell_tokens.dart`) sans rien inventer de nouveau côté couleur, rayon ou police. Les données d'exemple restent fictives.

Attention au vocabulaire : l'« Accueil » de l'écran 1 (`Onboarding.dc.html`) est l'écran de bienvenue du premier lancement et ne change pas. Appelle le nouvel écran **9 · Accueil (onglet)**, états 9a à 9h.

## Ce que l'écran contient

1. **Carte « Reprendre »** : la dernière piste jouée. Pochette (`ArtworkTile`), titre, « artiste · album » où l'artiste et l'album sont deux liens soulignés de 48 dp (comme dans le lecteur plein écran, 5a), bouton « Lecture » qui devient « Pause » quand la piste joue. Rien ne démarre tout seul. Proposer la taille de la pochette et la hiérarchie (carte large, pochette 96 ou 152 ?) en cohérence avec le détail d'album (8b).
2. **Section « Redécouvertes »** : grille de **six cartes d'album au plus**, mêmes cartes que la grille Albums (8a) : pochette carrée rayon 16, titre, « Artiste · année » ; deux colonnes en portrait. Sous la grille (ou dans l'en-tête de section, à toi de proposer), un bouton **« Autres suggestions »** de 48 dp, icône + libellé, qui refait le tirage. Pas de tirer-pour-actualiser.
3. **Mini-lecteur et barre de navigation** : inchangés, avec cinq destinations ; proposer l'icône et le libellé « Accueil » dans la barre du bas et dans le rail.

## États à dessiner (clair et sombre, portrait ; plus le paysage)

| Réf. | État |
|---|---|
| 9a | Normal : carte « Reprendre » en pause (session restaurée) et six redécouvertes |
| 9b | Normal avec la piste en lecture : bouton « Pause », ligne en `primary` pour ce qui joue, mini-lecteur visible |
| 9c | Piste sans pochette (tuile neutre) et album ou artiste inconnu (texte simple, sans lien) |
| 9d | Disque absent : carte « Reprendre » grisée (opacité 35 %, icône + texte, jamais la couleur seule) et une carte d'album grisée dans la grille |
| 9e | Petite bibliothèque : moins de six redécouvertes (1 à 3 cartes, pas de trous) ; et variante sans aucune redécouverte (section absente) |
| 9f | Aucune carte « Reprendre » (rien joué, rien d'enregistré) mais des redécouvertes |
| 9g | État vide complet : ni carte ni redécouvertes, composant d'état vide existant (6a–6d) avec le geste à faire, texte proposé « Lance une piste, elle reviendra ici » |
| 9h | Chargement de la bibliothèque (même état que Pistes, 3a) |
| 9i | Paysage / écran étendu (rail à gauche, panneau lecteur de 6e) : grille à trois ou quatre colonnes, carte « Reprendre » adaptée |

## Contraintes (rappel du HANDOFF)

- Principes 1 à 5 de §1 : rien ne recouvre la liste ; menthe (`primary`) pour ce qui joue et l'action principale, écaille (`tertiary`) pour ce qui demande une action (pas ici) ; pas de dégradé ni de lueur dans l'interface.
- Marge écran 16, zone tactile 48 minimum, texte lisible à 200 %, TalkBack : la carte « Reprendre » est lue comme un élément (« Reprendre : titre, artiste, album ») avec ses liens et son bouton séparés.
- Aucun bandeau de disque absent sur cet écran : l'état est porté par les cartes grisées.
- Composants existants à réutiliser (§6) : `ArtworkTile`, `TrackTile` (pour s'en inspirer), `StatusBanner` non utilisé, `MiniPlayer`. Tout nouveau composant (carte « Reprendre », bouton « Autres suggestions ») est décrit dans `Composants.dc.html` avec ses états.
- Réalisable en Flutter avec Material 3 et sans nouvelle dépendance.

## Points où je veux une proposition (deux variantes si utile)

1. **Album et artiste** : carte « Reprendre » avec liens (recommandé) ou trois tuiles séparées (piste, album avec pochette, artiste avec avatar à initiale, 8c). Montrer les deux sur 9a si le choix n'est pas évident.
2. **Placement de « Autres suggestions »** : sous la grille ou à droite du titre de section.
3. **Titres de section et textes** (français, mot pour mot repris en ARB) : « Reprendre », « Redécouvertes », « Autres suggestions ».
4. **Icône de l'onglet** dans le jeu d'icônes de §2.3.

## À rendre

- `Accueil.dc.html` (propriétés `theme`, `state` = normal · lecture · sanspochette · absent · petite · sanscarte · vide · chargement · paysage), planches `Lot7-Accueil-clair` et `-sombre` ;
- mise à jour de `Composants.dc.html`, de la navigation (§3.1, cinq onglets, rail inclus) et de `Jetons.dc.html` si un jeton manque ;
- les captures des états ci-dessus ; un court texte pour `HANDOFF.md` (§3.1, nouvel écran 9, critères d'acceptation).
