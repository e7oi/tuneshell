# BR-014 — Favoris et historique d'écoute

**Statut :** Active (validée le 2026-11-05) · **Créée le :** 2026-11-03 · **Ticket :** MPL-065 · **Décisions :** D15, D23, D27 · **Lié :** UC-013, FR-031, BR-001, BR-004, BR-008, BR-012, ADR-021

## Règle

Un **favori** est une piste que l'utilisateur a marquée. L'**historique** est la suite des écoutes comptées. Tout est enregistré sur l'appareil, rien n'est envoyé (D15, D26).

1. **Identité.** Un favori et une écoute sont rattachés à l'identité de la piste, (disque, chemin relatif) (BR-004 règle 1), et non à un identifiant interne.
2. **Favori : durée de vie.** Un favori survit à la réindexation (BR-004 règle 2) et à l'absence d'un disque (il reste, grisé, BR-001 et BR-008). Si le fichier disparaît de la bibliothèque, le favori n'est plus affiché mais reste enregistré, et il réapparaît si le fichier revient. Un favori n'est jamais supprimé automatiquement.
3. **Marquer et retirer.** Par le cœur du lecteur plein écran (la piste en cours) et par l'appui long d'une ligne de la liste (FR-019). Marquer deux fois une piste ne crée pas de doublon.
4. **Écoute comptée.** Une écoute est comptée quand la piste a été jouée 30 secondes, ou la moitié de sa durée si elle est plus courte que 60 secondes. Un saut avant ce seuil, une restauration de la session (BR-012) sans lecture et une pause qui ne dépasse pas le seuil ne comptent pas. Avec la répétition d'une piste, chaque tour atteignant le seuil compte.
5. **Contenu d'une écoute.** L'identité de la piste et l'instant de l'écoute (date et heure locales). Rien d'autre : ni titre, ni artiste, ni position. (L'heure permettra des suggestions selon le moment, MPL-066.)
6. **Historique borné.** Les 20 000 écoutes les plus récentes sont gardées ; au-delà, les plus anciennes sont supprimées. Une piste n'apparaît qu'une fois dans « Récentes », à sa dernière écoute.
7. **Réglage et effacement.** « Enregistrer l'historique d'écoute » est activé par défaut. Désactivé, plus aucune écoute n'est enregistrée et l'historique existant est gardé jusqu'à « Effacer l'historique » (avec confirmation). Effacer l'historique ne touche pas aux favoris.
8. **Listes.** « Favoris » : les favoris affichés, dans l'ordre de la liste Pistes (titre, FR-011 exigence 7). « Récentes » : les pistes de l'historique affichées, de la dernière écoute à la plus ancienne. Les deux se combinent avec la recherche (BR-011) et l'index alphabétique n'est montré que pour « Favoris » (« Récentes » n'est pas triée par titre).
9. **Données privées.** Les identités ne vont jamais dans les journaux, les exports ni le dépôt (D27, BR-012 règle 13).
10. **Hors voiture.** Android Auto ne montre ni favoris ni historique dans ce ticket (BR-013 règle 2 reste).

## À valider (PO)

Validé le 2026-11-05 par le propriétaire (« pour le reste c'est ok »), sans changement.

- Règle 4 : le seuil (30 secondes, ou la moitié d'une piste de moins de 60 secondes).
- Règle 6 : la borne de 20 000 écoutes.
- Règle 7 : historique enregistré par défaut (autre choix : désactivé, l'utilisateur l'active).
- Règle 3 : l'appui long d'une ligne comme second moyen de marquer.
- Règle 8 : pas d'index alphabétique sur « Récentes ».
- **Écart à FR-017 (`Active`), exigence 5** : le cœur « Favoris (bientôt) » devient un vrai bouton. **Écart à FR-009, FR-011 et FR-023 (`Active`)** : pastilles sous le champ de recherche de Pistes, lignes de réglage de l'historique. Aucune des fiches `Active` n'est modifiée avant validation.
- Réassociation d'un disque (MPL-038) : les favoris et écoutes suivent la nouvelle identité à ce moment-là (à trancher avec MPL-038).
