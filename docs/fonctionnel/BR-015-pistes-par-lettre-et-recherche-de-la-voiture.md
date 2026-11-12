# BR-015 — Listes par lettre et recherche dans la voiture

**Statut :** Active (validée le 2026-11-12) · **Créée le :** 2026-11-12 · **Ticket :** MPL-075 · **Lié :** UC-012, FR-029, BR-010, BR-011, BR-013, ADR-020, ADR-023 · **Source :** demande du propriétaire du 2026-11-12, après l'essai en voiture de MPL-074

## Règles

1. **Pistes par lettre.** La liste Pistes de l'arbre média (BR-013) est de nouveau découpée en dossiers par lettre : au-delà de 100 entrées, un niveau montre une ligne par lettre suivante, et ainsi de suite jusqu'à ce que chaque niveau tienne ; une lettre qui n'a qu'une suite possible se fond dans la précédente. Le dossier s'intitule par ses lettres en capitales (« A », « BE »). L'ordre est celui de la liste du téléphone (FR-011.7). **Albums et Artistes ne sont pas découpés** : ils restent des listes entières, avec leurs pochettes (BR-013, règle 4), servies par pages. Choix du propriétaire, 2026-11-12 : voir toutes les pochettes en liste aide à reconnaître un album.
2. **Accès complet.** Chaque lettre existante a son dossier, du premier niveau : l'accès à une lettre ne dépend pas de la page chargée.
3. **Pagination conservée.** Un niveau qui dépasse quand même 400 lignes (Albums, Artistes, ou une lettre sans suite possible) reste servi par pages ou par « Suite… » comme BR-013, règle 4.
4. **Recherche globale.** La racine déclare la recherche à Android Auto, qui montre alors le bouton de recherche (clavier ou voix). La requête porte sur toute la bibliothèque jouable, quel que soit le dossier ouvert. Les résultats sont rangés dans cet ordre, sans titre de section (Android Auto reçoit une liste plate) : albums, artistes, pistes ; chaque groupe n'apparaît que s'il a un résultat. Les albums et artistes sont des dossiers (ils s'ouvrent comme dans les listes) ; les pistes sont jouables. Correspondance de BR-011 (titre affiché, artiste, artiste de l'album, album pour une piste ; titre et artiste pour un album ; nom pour un artiste ; casse, accents et espaces sans effet ; tous les mots, n'importe où et dans n'importe quel ordre ; une lettre suffit). « Artiste inconnu » et « Album inconnu » ne sont pas cherchés.
   *Écart à la demande :* le propriétaire voulait les résultats de la section ouverte, ou tout si aucune section n'est active. Android Auto ne dit pas à l'application dans quel dossier se trouve l'utilisateur quand il lance une recherche : la requête arrive seule. La recherche est donc toujours globale, en trois sections.
5. **Taille des résultats.** Au plus 100 résultats par section. Aucun résultat : une liste vide, sans ligne inventée. Les pistes, albums et artistes d'un disque absent ne sont pas proposés (BR-013, règle 6), à la différence de la recherche du téléphone qui les grise (BR-011, règle 6) : écart voulu, on ne manipule pas l'écran en conduisant. Une requête de plus de 100 caractères est coupée. Rangement dans chaque section : l'ordre des listes (BR-013, règle 3).
6. **File d'une piste trouvée.** Choisir une piste trouvée met en file la liste des pistes trouvées, à partir d'elle (provisoire : le propriétaire la redéfinira, 2026-11-12). L'aléatoire et la répétition gardent leur état (BR-009). La règle 5 de BR-013 ne change pas pour les pistes choisies sous une lettre.
7. **Identifiants stables.** Un dossier de lettre et une piste trouvée ont un identifiant qui ne dépend que de ses lettres ou de la piste (disque, chemin relatif), valable après réindexation (BR-013, règle 7) ; la requête n'est jamais journalisée (D27).
8. **Lecture seule, sans réseau.** Comme BR-013, règles 10 et 11 ; la recherche se fait en mémoire sur l'arbre déjà construit (ADR-023).

## À valider (PO)

- Règle 1 : remplace BR-013, règle 4 pour la liste Pistes seulement ; le seuil de 100 entrées est à mesurer en voiture.
- Règle 6 : file d'une piste trouvée à redéfinir.
- Hors périmètre, gardé pour plus tard : commande vocale « joue X » (`playFromSearch`).

## As-built

MPL-075, 2026-11-12, test appareil en attente (D14). `LibraryMediaTree` (`maxTracks` pour la seule liste Pistes, `search`), `MediaTree.search` (port), `PlayerAudioHandler.search`, `currentMediaTree` (`maxChildren` illimité, `maxTracks` 100) et la configuration d'`audio_service` (`android.media.browse.SEARCH_SUPPORTED`).

- Le découpage est l'algorithme de MPL-060 (`_cut`) : une lettre qui n'a qu'une suite possible se fond dans la précédente, un dossier est intitulé par les lettres communes (« TRACK 1 »).
- Une recherche est faite en mémoire : un texte par piste (titre affiché, artiste, artiste d'album, album) et par album, fait à la première requête ; au plus 100 résultats par section.
- Les pistes trouvées ont le parent `search|<requête>` : l'identifiant d'une piste trouvée ne change pas, et la lecture met en file les pistes trouvées. La requête n'est pas journalisée.
- Écart : deux implémentations de la correspondance (interface, ADR-018 ; arbre) ; l'alignement par un test commun prévu par ADR-023 est dû (dette).
- Tests : `library_media_tree_test.dart` (lettres, recherche), `player_audio_handler_test.dart` (gestionnaire), `media_browsing_test.dart` (liste réelle).

