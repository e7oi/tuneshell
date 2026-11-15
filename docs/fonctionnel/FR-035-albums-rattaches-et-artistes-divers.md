# FR-035 — Albums rattachés et artiste « Artistes divers » dans les vues

**Statut :** Active (validée le 2026-11-14) · **Créée le :** 2026-11-14 · **Ticket :** MPL-082 · **Lié :** BR-017, BR-010, FR-020, FR-021, FR-032, FR-033, FR-029, BR-013, BR-016, UC-008, ADR-026 · **Source :** demande du propriétaire du 2026-11-14 ; pas de maquette (aucun composant nouveau : un texte à la place du nom de l'artiste)

## Besoin

Voir chaque album **une seule fois**, avec toutes ses chansons, même quand chaque chanson a son interprète (bandes originales, compilations), sans changer les fichiers.

## Exigences

1. **Onglet Albums (FR-020).** Un album rattaché (BR-017) est une seule carte avec le nombre total de ses pistes ; le sous-titre est « Artistes divers » (en anglais « Various artists »).
2. **Détail de l'album (FR-020.8).** Les pistes sont dans l'ordre de BR-010 règle 6. Chaque ligne montre l'**artiste de la piste** (comme FR-011) quand l'album est « Artistes divers », pour reconnaître les interprètes.
3. **Onglet Artistes (FR-021).** Une entrée « Artistes divers » regroupe ces albums (BR-017, règle 5), triée comme un nom ordinaire. Le détail de l'artiste, « Lire » et « Aléatoire » (FR-022) suivent les règles de FR-021.
4. **Lecture (FR-022).** Lire, ajouter à la file ou mettre « ensuite » un album rattaché utilise toutes ses pistes, dans l'ordre de BR-010 règle 6.
5. **Lecteur plein écran (FR-032).** Le lien **album** ouvre l'album rattaché. Le lien **artiste** n'existe pas pour une piste d'un album « Artistes divers » (BR-010, règle 5 : un interprète de piste sans album propre n'a pas d'entrée) ; le nom reste en texte simple.
6. **Voiture (BR-013, FR-029).** L'arbre montre l'album rattaché une seule fois, avec son artiste « Artistes divers », et l'entrée « Artistes divers » dans la liste des artistes. « Artiste en cours » est absent pour une piste d'un album « Artistes divers » (comme FR-032.7 quand le groupe n'existe pas). Les identifiants de dossiers changent une fois à la mise à jour de l'application (voir ADR-026).
7. **Accueil (FR-033, BR-016).** Un album rattaché est une seule carte « à redécouvrir », éligible et indisponible comme tout album (BR-016) ; son sous-titre est « Artistes divers ».
8. **Recherche (FR-027, BR-011).** La recherche d'albums trouve par titre, par artiste de l'album et par **titre ou artiste de n'importe quelle piste** de l'album (BR-011, règle 1 complétée) ; le mot « Artistes divers » n'est pas cherché. L'index et les lettres ne changent pas.
9. **Textes** dans les fichiers ARB, en français et en anglais ; le libellé TalkBack de la carte reprend le sous-titre.

## Hors périmètre

Réglage manuel de fusion ou de séparation ; modification des étiquettes (MPL-067) ; lecture du drapeau « compilation » des fichiers ; rapprochement de titres qui diffèrent visiblement (« vol.1 » et « volume 1 ») ; fusion entre disques par le dossier ; nettoyage des doublons de pistes (MPL-040) ; changement de la recherche ou des lettres.

## Validé par le propriétaire (2026-11-14)

Les points ci-dessous sont validés avec la recommandation : garde-fou du dossier (a), artiste « Artistes divers », pas de lien artiste dans le lecteur pour un tel album, changement unique des identifiants de dossiers de la voiture, réglage manuel de fusion écarté pour l'instant. Le reste est repris tel quel.

- **Pas de lien artiste dans le lecteur** pour un album « Artistes divers » (exigence 5). Autre choix : lien vers l'entrée « Artistes divers », trompeur puisque le lecteur affiche l'interprète de la piste.
- **Interprète sur chaque ligne du détail** (exigence 2) : déjà vrai si FR-011 le montre toujours ; sinon c'est la seule retouche de présentation.
- **Complète FR-020, FR-021, FR-029, FR-032 et FR-033 (`Active`)** : report à la validation.

## As-built

MPL-082, 2026-11-14, test appareil : non testé (D14). `AlbumGroup.variousArtists`, `ArtistGroup.various` (`library_groups.dart`) ; texte « Artistes divers » (`artistVarious`, ARB) par `artistName` (`artists_view.dart`) et `albumArtistName` (`albums_view.dart`) ; interprète par ligne dans `album_detail_page.dart` ; voiture : `MediaArtist.various`, nom traduit dans `media_browsing.dart`, « Artiste en cours » absent. Tests : `browse_views_test.dart` (détail et onglet Artistes), `library_groups_test.dart`, `library_media_tree_test.dart` (FR-035.6).

- Exigence 8 : la recherche d'albums cherche le titre de l'album, son artiste et **le titre et l'artiste de chaque piste** (`albumTexts`, `library_search.dart`) ; « Artistes divers » lui-même n'est pas un texte cherché (comme l'artiste inconnu, BR-011 règle 2). Demande du propriétaire du 2026-11-14, validée.
- Lien d'artiste du lecteur : absent pour un album « Artistes divers » (`artistOf` rend null), le lien d'album reste.
- Accueil : aucune retouche, la carte reprend `albumArtistName`.
