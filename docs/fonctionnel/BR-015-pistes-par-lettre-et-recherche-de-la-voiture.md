# BR-015 — Listes par lettre et recherche dans la voiture

**Statut :** Brouillon · **Créée le :** 2026-11-12 · **Ticket :** MPL-075 · **Lié :** UC-012, FR-029, BR-010, BR-011, BR-013, ADR-020, ADR-023 · **Source :** demande du propriétaire du 2026-11-12, après l'essai en voiture de MPL-074

## Règles

1. **Dossiers par lettre.** Les listes Pistes, Albums et Artistes de l'arbre média (BR-013) sont de nouveau découpées en dossiers par lettre : au-delà de 100 entrées (seuil à mesurer en voiture), un niveau montre une ligne par lettre suivante, et ainsi de suite jusqu'à ce que chaque niveau tienne ; une lettre qui n'a qu'une suite possible se fond dans la précédente. Le dossier s'intitule par ses lettres en capitales (« A », « BE »). L'ordre est celui des listes du téléphone (BR-013, règle 3 ; BR-010, règle 7 ; FR-011.7).
2. **Accès complet.** Chaque lettre existante a son dossier, du premier niveau : l'accès à une lettre ne dépend pas de la page chargée.
3. **Pagination conservée.** Un niveau qui dépasse quand même 400 lignes (plus de lettre à couper) reste servi par pages ou par « Suite… » comme BR-013, règle 4.
4. **Recherche globale.** La racine déclare la recherche à Android Auto, qui montre alors le bouton de recherche (clavier ou voix). La requête porte sur toute la bibliothèque jouable, quel que soit le dossier ouvert. Elle rend des **pistes**, jouables, avec les règles de correspondance de BR-011 (titre affiché, artiste, artiste de l'album, album ; casse, accents et espaces sans effet ; tous les mots, n'importe où et dans n'importe quel ordre ; une lettre suffit). Les textes « Artiste inconnu » et « Album inconnu » ne sont pas cherchés.
5. **Résultats.** Rangés par titre A→Z comme la liste Pistes ; au plus 100 par page, la suite par la pagination de la règle 3. Aucun résultat : une liste vide, sans ligne inventée. Les pistes d'un disque absent ne sont pas proposées (BR-013, règle 6).
6. **File d'un résultat.** Choisir un résultat met en file la liste des résultats, à partir de ce résultat, comme la recherche du téléphone (FR-027). L'aléatoire et la répétition gardent leur état (BR-009). La règle 5 de BR-013 (liste Pistes entière) ne change pas pour les pistes choisies sous une lettre.
7. **Identifiants stables.** Un dossier de lettre et un résultat ont un identifiant qui ne dépend que de ses lettres ou de la piste (disque, chemin relatif), valable après réindexation (BR-013, règle 7) ; la requête n'est jamais journalisée (D27).
8. **Lecture seule, sans réseau.** Comme BR-013, règles 10 et 11 ; la recherche se fait en mémoire sur l'arbre déjà construit (ADR-023).

## À valider (PO)

- Règle 1 : portée aux trois listes (Pistes, Albums, Artistes), comme avant MPL-064 ; autre choix : seulement Pistes. Seuil de 100 entrées par niveau, à mesurer en voiture. **Remplace BR-013, règle 4** (listes entières servies par pages), qui reste `Active` jusqu'à ta validation.
- Règle 4 : la recherche rend des pistes seulement ; autre choix : des sections Albums et Artistes aussi.
- Règle 6 : la file d'un résultat est la liste des résultats ; autre choix : toute la bibliothèque (règle 5 de BR-013), de sorte que l'aléatoire mélange tout.
- Hors périmètre : commande vocale « joue X » de l'assistant (`playFromSearch`), qui demande un choix de résultat sans écran ; à cadrer à part si voulu.
