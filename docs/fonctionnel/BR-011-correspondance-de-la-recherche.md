# BR-011 — Correspondance de la recherche

**Statut :** Brouillon · **Créée le :** 2026-10-28 · **Ticket :** MPL-055 · **Décisions :** D3 · **Lié :** UC-010, FR-011, FR-027, BR-010, ADR-018 · **Source :** demande du propriétaire du 2026-10-24

## Règles

1. **Portée selon la vue.** Pistes : le titre affiché (le nom de fichier s'il manque, FR-003.5), l'artiste, l'artiste de l'album et l'album. Albums : le titre de l'album et son artiste (BR-010, règle 1). Artistes : le nom de l'artiste (BR-010, règle 5). Un champ absent ne correspond à rien.
2. **Texte de remplacement non cherché.** « Artiste inconnu » et « Album inconnu » sont des textes d'affichage : taper « inconnu » ne ramène pas toutes les pistes sans étiquette.
3. **Repli.** La requête et les champs sont comparés sans tenir compte de la casse ni des accents, avec le même repli que le tri (FR-011.7) et que BR-010 (règle 3) : « ecris » trouve « Écris-moi ». Les espaces en trop sont ignorés ; la ponctuation est gardée telle quelle.
4. **Mots.** La requête est coupée aux espaces. Chaque mot doit se trouver **quelque part dans** le texte de la ligne (sous-chaîne, pas seulement début de mot), dans n'importe quel ordre ; les mots peuvent tomber dans des champs différents (« hahn bach » trouve une piste dont l'artiste est Hahn et l'album Bach). Une requête vide ou faite d'espaces ne filtre rien.
5. **Ordre des résultats.** Celui de la vue (titre A→Z, FR-011.7 ; titre d'album, FR-020 ; nom d'artiste, FR-021). Pas de classement par pertinence.
6. **Sources absentes.** Les pistes, albums et artistes d'un disque absent ou à accès perdu sont trouvés comme dans la liste, grisés (BR-008).
7. **Pas de minimum de lettres.** Une lettre suffit ; le résultat suit chaque frappe.
8. **Coût.** Le filtre se fait en mémoire sur la bibliothèque affichée (ADR-018) : il ne dépasse pas une image (16 ms) pour 10 000 pistes. Au-delà de 50 000 pistes, revoir la décision (FTS5, nouvelle ADR).

## À valider (PO)

- Règle 2 : « Artiste inconnu » et « Album inconnu » ne sont pas cherchés.
- Règle 4 : tous les mots, n'importe où, plutôt que début de mot ou phrase exacte.
- Règle 5 : pas de classement par pertinence.
