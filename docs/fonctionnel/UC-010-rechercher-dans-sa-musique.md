# UC-010 — Retrouver une piste, un album ou un artiste en le cherchant

**Statut :** Brouillon · **Créée le :** 2026-10-28 · **Ticket :** MPL-055 · **Lié :** UC-004, UC-005, UC-008, FR-011, FR-020, FR-021, FR-027, BR-011, ADR-018 · **Source :** demande du propriétaire du 2026-10-24 (la conception ne montre qu'un emplacement, `docs/design/HANDOFF.md` §4 et §8)

## Acteur et but

L'utilisateur connaît un bout du titre, de l'artiste ou de l'album qu'il veut et ne veut pas faire défiler une bibliothèque de plusieurs milliers de pistes.

## Préconditions

- La bibliothèque contient des pistes (UC-001, UC-003).

## Scénario nominal

1. Dans l'onglet **Pistes**, **Albums** ou **Artistes**, l'utilisateur touche la loupe de l'en-tête : le titre laisse la place à un champ de texte, le clavier s'ouvre (FR-027).
2. Il tape quelques lettres : la liste se réduit à chaque frappe aux lignes qui correspondent, sans tenir compte de la casse ni des accents (BR-011).
3. Il touche une piste : elle se lance, avec les résultats pour file (FR-027) ; ou un album ou un artiste : le détail s'ouvre (UC-008).
4. Il revient, la recherche est toujours là ; un second Retour la ferme et la liste complète revient.

## Variantes

- 2a. Aucune ligne ne correspond : un message le dit et propose d'effacer la recherche.
- 2b. Plusieurs mots : chacun doit se trouver dans la ligne, dans n'importe quel ordre (BR-011).
- 3a. Une piste trouvée est sur un disque absent : elle est grisée, comme dans la liste, et toucher explique ce qu'il faut brancher (BR-008).
- 4a. L'utilisateur change d'onglet : la recherche de chaque onglet est gardée telle quelle (FR-027).

## Hors périmètre

Recherche à résultats mélangés (pistes, albums et artistes sur un seul écran), recherche par genre, année, dossier ou chemin, historique et suggestions, recherche vocale, filtres et autres tris, recherche dans la file ou dans un détail d'album.
