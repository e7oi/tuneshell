# BR-013 — Arbre média proposé à Android Auto

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-060 · **Décisions :** D6, D12, D27 · **Lié :** UC-012, FR-029, BR-001, BR-004, BR-009, BR-010, BR-012, ADR-020

## Règles

1. **Racine fixe.** Trois dossiers : « Albums », « Artistes », « Pistes », précédés de la piste courante quand une file existe (règle 2). Pas de « Dossiers » : choisir des dossiers est une action du téléphone.
2. **Reprendre.** Un seul élément jouable : la piste courante de la file que le contrôleur tient (la session enregistrée, restaurée au lancement, BR-012). Le jouer reprend cette file telle quelle, à sa position. Sans file, l'entrée est absente.
3. **Mêmes listes que l'application.** Albums et artistes sont ceux de BR-010, dans le même ordre de tri ; les pistes sont triées par titre comme dans l'onglet Pistes. Les pistes d'un album sont dans l'ordre disque puis numéro.
4. **Listes longues.** Une liste qui dépasse la taille tolérée par Android Auto est découpée en groupes alphabétiques (A à Z et « # ») comme l'index de l'application, un niveau de plus. La taille limite et la profondeur maximale sont celles retenues par ADR-020 ; aucune liste n'est tronquée sans que l'on puisse atteindre le reste.
5. **File au choix d'une piste.** Choisir une piste d'un album, d'un artiste ou d'un groupe de la liste Pistes met en file toutes les pistes de ce groupe jouables, à partir de la piste choisie (même règle que FR-022). L'aléatoire et la répétition gardent leur état (BR-009).
6. **Sources absentes.** Les pistes d'un disque absent (BR-001) ne sont pas proposées ; un album ou un artiste dont toutes les pistes sont absentes non plus. Aucune piste grisée : on ne manipule pas l'écran en conduisant.
7. **Identifiants stables.** Chaque élément a un identifiant qui ne change pas d'un lancement à l'autre et qui reste valable si la bibliothèque est réindexée ; une piste y est identifiée par (disque, chemin relatif) (BR-004). Ces identifiants ne sont jamais affichés ni journalisés avec leur contenu (D27).
8. **Bibliothèque vide.** La racine propose un seul élément non jouable : « Ouvre TuneShell sur le téléphone pour choisir ta musique ».
9. **Titres.** Titre, artiste et album des étiquettes ; à défaut le nom de fichier sans extension, comme sur le téléphone (FR-005, exigence 2). Textes fixes de l'arbre dans les fichiers ARB.
10. **Lecture seule.** Android Auto ne modifie rien : pas de suppression, d'indexation ni de réglage. Aucun réseau (D15).
11. **Même moteur, mêmes règles.** Une lecture lancée depuis Android Auto passe par le même `PlayerController` : ouverture des disques amovibles, éjection, interruptions (BR-002, BR-005).

## À valider (PO)

- Règle 6 : pistes absentes masquées. Autre choix : affichées non jouables.
- Règle 4 : découpage alphabétique des longues listes (le seuil exact se mesure sur la voiture).
- Règle 2 : pas de « Récents » séparé de « Reprendre » (pas d'historique, MPL-058).
