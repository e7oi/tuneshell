# BR-017 — Rattachement des albums sans artiste d'album et clé d'album normalisée

**Statut :** Active (validée le 2026-11-14) · **Créée le :** 2026-11-14 · **Ticket :** MPL-082 · **Lié :** BR-010, FR-035, FR-032, BR-013, BR-016, ADR-026, UC-008 · **Source :** demande du propriétaire du 2026-11-14 (« ne pas avoir plusieurs fois le même album, chacun avec 1 ou n chansons »)

> **Écart avec une fiche `Active`.** Cette règle complète BR-010 (règles 1, 2, 3 et 5) sans la modifier. À la validation, BR-010 renvoie ici pour les cas décrits ci-dessous (voir « À valider »).

## Diagnostic (code lu le 2026-11-14, aucune donnée réelle)

La clé d'un album est `artiste de l'album replié` + NUL + `titre replié` (`LibraryGroups.build`, `lib/features/browse/library_groups.dart`). L'artiste de l'album est `albumArtist`, à défaut `artist` de la **piste**. Les causes possibles d'un album en plusieurs morceaux, de la plus probable à la moins probable :

1. **Pas d'étiquette « artiste de l'album » et un artiste de piste différent par chanson** (cas typique d'une bande originale : chaque chanson a son interprète). Chaque interprète fait un album d'une piste. C'est la « limite connue » que BR-010 a laissée à valider.
2. **Étiquette « artiste de l'album » présente sur une partie des pistes seulement** (les unes « Divers », les autres vides) : deux clés pour le même album.
3. **Écritures différentes qui paraissent identiques**, que le repli actuel (`foldText`) ne ramène pas à la même clé : lettres accentuées en deux codes (é en un caractère ou « e » + accent combinant), apostrophe droite et apostrophe courbe, points de suspension « … » et trois points, tirets de formes différentes, espaces insécables étroites ou de largeur nulle, ligatures et lettres hors table (œ, ß, ø, ł).
4. **Deux sources qui étiquettent différemment** : le stockage interne est lu par MediaStore, le disque amovible par le lecteur d'étiquettes du fichier (BR-004, FR-007) ; les séparateurs de valeurs multiples et l'artiste de l'album absent peuvent différer.

L'année, le numéro de disque et la durée n'entrent pas dans la clé : ils ne scindent pas un album. Des titres réellement différents (« vol.1 », « volume 2 », avec ou sans sous-titre) ne sont pas une différence invisible : ils restent des albums distincts (hors périmètre, MPL-067).

## Règles

1. **Clé normalisée.** Pour la clé d'album (artiste et titre), en plus de la règle 3 de BR-010 : les accents combinants sont ignorés ; les apostrophes, guillemets, tirets et points de suspension de formes différentes sont ramenés à une forme ; les espaces de toute sorte, insécables et de largeur nulle comprises, valent un espace simple ; les caractères invisibles de mise en forme sont ignorés ; œ, æ, ß, ø, ł et leurs pareils se replient comme les lettres accentuées. L'affichage garde toujours l'écriture la plus fréquente (BR-010, règle 3). La normalisation de la **recherche** (BR-011) et des **lettres de l'index** (FR-013) ne change pas.
2. **Artiste « divers ».** Une étiquette d'artiste de l'album qui, une fois normalisée, vaut « various artists », « various », « va », « artistes divers » ou « divers » désigne l'**artiste « Artistes divers »** (règle 4).
3. **Rattachement.** Quand plusieurs albums de la règle 2 de BR-010 portent le **même titre normalisé**, sont **sur le même disque et dans le même dossier**, et que leur artiste d'album **vient de l'artiste de piste** (étiquette « artiste de l'album » absente) ou est l'artiste « divers » de la règle 2, ils forment **un seul album**. Un album dont l'étiquette « artiste de l'album » est renseignée et n'est pas « divers » n'est jamais rattaché : l'étiquette du propriétaire fait foi. Un seul album concerné : rien ne change.
4. **Artiste de l'album rattaché.** Un album rattaché à partir de **deux artistes de piste distincts ou plus**, ou dont une piste porte « divers », a pour artiste de l'album **« Artistes divers »**, un artiste unique de la bibliothèque (texte dans les fichiers ARB, fr et en). Si les pistes rattachées n'ont qu'un artiste, l'album reste à cet artiste.
5. **Artiste « Artistes divers ».** Il regroupe tous les albums de la règle 4 et les albums étiquetés « divers » (même d'un autre dossier) ; il est trié dans l'onglet Artistes comme un nom ordinaire, par son texte affiché. Son entrée n'apparaît que s'il a au moins un album.
6. **Contenu inchangé.** Rattacher ne déplace, ne renomme et ne supprime aucun fichier ni étiquette : seul le regroupement affiché change, et il se recalcule à chaque émission de la liste (BR-010, règle 10). Les favoris et l'historique, qui suivent la piste (BR-004), ne sont pas touchés.
7. **Ordre et métadonnées de l'album rattaché.** Comme BR-010 règles 6 à 8 : ordre des pistes par disque, numéro de piste puis titre ; année la plus ancienne ; pochette de la première piste qui en a une.
8. **Ce qui n'est pas rattaché.** Deux dossiers différents, deux disques différents, deux titres qui ne diffèrent pas seulement par la normalisation de la règle 1 : albums distincts.
9. **Coût.** Le regroupement de 7 500 pistes reste sous deux secondes (BR-010, as-built) ; le rattachement n'ajoute qu'un passage sur les albums.

## Cas limites

- « Greatest Hits » de deux artistes, deux dossiers : deux albums (règle 3, dossier différent).
- « Greatest Hits » de deux artistes **étiquetés** « artiste de l'album » : deux albums (l'étiquette fait foi).
- Un album en deux dossiers (« CD1 », « CD2 ») sans artiste d'album : **non rattaché** par la règle 3 ; c'est une limite connue (voir « À valider »).
- Un album réparti sur le téléphone et sur le disque (BR-010, règle 4) : la clé d'artiste doit être la même ; le rattachement par dossier ne joue pas entre disques.
- Plusieurs dossiers parents portant le même nom sur un même disque : le dossier est comparé par son **chemin relatif complet**, non par son nom.
- Piste sans titre d'album : jamais rattachée (« Album inconnu » reste un par artiste).
- Piste sans artiste du tout, dans un dossier où un album de même titre existe : elle rejoint l'album ; l'artiste inconnu ne compte pas comme un « artiste distinct » et ne suffit pas à faire un album « Artistes divers ».

## Scénarios de test synthétiques (aucune donnée réelle, D27)

Noms génériques uniquement : « Album A », « Artiste 1 », « Artiste 2 », dossier « dossier-1 ».

- Quatre pistes d'« Album A », artistes 1 à 4, sans artiste d'album, même dossier → un album de quatre pistes, « Artistes divers ».
- Idem avec une piste étiquetée « Various Artists » → un album, « Artistes divers ».
- Deux pistes d'« Album A » d'un même artiste, une autre d'un autre artiste, même dossier → un album, « Artistes divers ».
- « Album A » dans deux dossiers, artistes différents, sans artiste d'album → deux albums.
- « Album A » étiqueté « Artiste 1 » et « Album A » étiqueté « Artiste 2 » (artiste d'album renseigné), même dossier → deux albums.
- « Album A » et « ALBUM  Á » (casse, deux espaces, accent) → un album (BR-010, règle 3, déjà acquis).
- « é » en un caractère et « e » + accent combinant ; apostrophe droite et courbe ; « … » et « ... » ; espace insécable ; espace de largeur nulle → même clé.
- Titres « Album A vol.1 » et « Album A volume 1 » → deux albums (différence visible).

## Validé par le propriétaire (2026-11-14)

Les points ci-dessous sont validés avec la recommandation : garde-fou du dossier (a), artiste « Artistes divers », pas de lien artiste dans le lecteur pour un tel album, changement unique des identifiants de dossiers de la voiture, réglage manuel de fusion écarté pour l'instant. Le reste est repris tel quel.

- **Garde-fou du dossier : (a) recommandé et confirmé par le diagnostic du 2026-11-14 sur le stockage interne** (voir MPL-082, un dossier par album, aucune étiquette « artiste de l'album » sur ces albums, 17 rattachements, aucun faux rapprochement). Disque amovible non diagnostiqué.
- **Garde-fou du dossier (recommandé).** Sans lui, le rattachement par titre seul fusionnerait deux « Greatest Hits » d'artistes sans étiquette d'album. Avec lui, un album dont les chansons sont rangées dans **un dossier par artiste** n'est pas rattaché. Le diagnostic sur l'appareil (ticket MPL-082) dit laquelle des deux organisations est la vôtre ; choix : (a) dossier obligatoire (recommandé), (b) titre seul pour les pistes sans étiquette d'artiste de l'album, plus de rattachements et plus de risques de faux rapprochements.
- **Album en plusieurs dossiers (CD1, CD2).** Hors du garde-fou (a) ; aucun cas sur le stockage interne : option « dossier parent commun » non retenue, à rouvrir si le disque amovible en montre.
- **Seuil « deux artistes ou plus ».** Rattacher dès qu'il y a deux albums de même titre dans le dossier (retenu) ; pas de nombre minimal de pistes.
- **Artiste « divers » à la place de l'artiste le plus fréquent.** Autre choix : garder l'artiste le plus fréquent comme artiste de l'album (la bande originale apparaît alors sous un interprète au hasard). Non retenu : trompeur.
- **Texte « Artistes divers ».** Mêmes mots dans l'interface ; la liste des synonymes de la règle 2 est à compléter selon vos étiquettes.
- **Modifie BR-010** (règles 1, 2, 3 et 5) et complète UC-008 (`Active`) : à reporter dans ces fiches à la validation.
- **Réglage manuel de fusion** (forcer, ou défaire, un regroupement album par album) : non retenu dans ce ticket (voir ADR-026) ; à rouvrir si le diagnostic montre des albums restants.

## As-built

MPL-082, 2026-11-14, test appareil : non testé (D14). `albumKeyText` (`lib/features/browse/album_key_text.dart`) sert la clé d'album et d'artiste ; `LibraryGroups.build` fait le rattachement (`_mergedKeys`, `_isVarious`, clé réservée `\u0001` de l'artiste « divers »). Tests : `test/features/browse/album_key_text_test.dart` (règle 1), `test/features/browse/library_groups_test.dart` (groupe `BR-017`, règles 2 à 8).

- Règle 3 : un seau par (disque, chemin relatif du dossier, titre normalisé). Il est fusionné si deux artistes de piste distincts non vides, ou une étiquette « divers », s'y trouvent ; les pistes sans artiste du seau le rejoignent. Une piste dont l'étiquette d'artiste d'album est renseignée (et n'est pas « divers ») est hors seau.
- Règle 8 : chaque dossier rattaché est un album à lui (identité = disque, dossier, titre), même si un autre dossier porte le même titre ; seules les pistes étiquetées « divers » font l'album unique de leur titre, quel que soit le dossier, et un dossier qui en contient une les rejoint (règle 5). Relevé par la revue QA.
- Cas limite « piste sans artiste » : elle rejoint l'album seulement si le dossier est rattaché ; une piste sans artiste avec un seul autre artiste ne rattache rien.
- L'ancien test « une compilation sans artiste d'album se découpe par artiste de piste » (BR-010, limite connue) est remplacé : elle ne se découpe plus que d'un dossier à l'autre.
- Le repli de la recherche (`foldText`) et des lettres (`sortKey`) est inchangé ; `albumKeyText` s'appuie sur `sortKey` après ses remplacements.
