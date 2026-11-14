# BR-016 — Redécouvertes de l'accueil

**Statut :** Active (validée le 2026-11-13, révisée le 2026-11-14 sur décision du propriétaire : voir « Révision ») · **Créée le :** 2026-11-13 · **Ticket :** MPL-079 · **Décisions :** D15, D23, D27 · **Lié :** UC-014, FR-033, BR-001, BR-004, BR-008, BR-010, BR-012, BR-014, ADR-024

## Règle

L'accueil propose **trois pistes** et **deux albums à redécouvrir**. Tout se calcule sur l'appareil, à partir de la bibliothèque et de l'historique existants (BR-014) ; rien n'est envoyé (D15, D26) et rien de nouveau n'est enregistré, hors le tirage gardé en mémoire (règle 6).

1. **Pas de carte « dernier joué ».** La dernière piste jouée est celle du mini-lecteur (FR-016), restaurée au lancement (BR-012) ; l'accueil ne la répète pas. Sans piste courante, pas de mini-lecteur et l'accueil ne montre que les redécouvertes.
2. **Disponible.** Une piste est disponible quand son disque l'est (BR-001, BR-008). Un album est disponible quand **au moins une** de ses pistes l'est (décision du 2026-11-14) ; son détail grise les autres (FR-020 exigence 5). Un élément indisponible n'est **jamais tiré** et n'apparaît pas sur l'accueil : pas de ligne ni de carte grisée.
3. **Éligible.** Disponible, aucune écoute depuis 30 jours (« jamais écouté » compte ; pour un album, aucune de ses pistes), et ni la piste courante ni son album. Une piste sans album peut être tirée ; une piste n'est pas tirée si son album est l'un des deux albums tirés.
4. **Priorité.** Niveau 1 : les éligibles qui ont une écoute plus ancienne que 30 jours ou un favori (pour un album : l'une de ses pistes). Niveau 2 : les autres. Tirage au hasard (loi uniforme) dans le niveau 1, complété dans le niveau 2 s'il en manque. Aucun doublon. Le niveau 2 évite des sections vides : l'historique n'existe que depuis MPL-065 et beaucoup de musique n'a jamais été écoutée.
5. **Moins d'éléments que prévu.** Autant que d'éligibles, de zéro à trois pistes et de zéro à deux albums ; une section vide est absente. Aucun des deux, et l'accueil n'a pas non plus de piste courante : état vide (FR-033).
6. **Quand le tirage change.** Au premier affichage de l'accueil après le démarrage de l'application, puis il est gardé en mémoire : changer d'onglet, tourner l'écran, revenir du lecteur, finir une piste ou réindexer ne le changent pas. Il ne change que sur « Autres suggestions », qui refait les deux tirages en évitant si possible les éléments déjà affichés. Il n'est pas enregistré : aucune garantie d'éléments différents d'un démarrage à l'autre.
7. **Pendant la session.** Un élément qui quitte la bibliothèque ou devient indisponible (disque retiré ou éjecté) disparaît de l'accueil sans remplaçant ; il revient avec son disque si le tirage n'a pas été refait.
8. **Testable.** Le hasard et l'horloge sont injectés dans le calcul (test d'abord, sélection reproductible).
9. **Données privées.** Aucun titre, nom ni identité dans les journaux ni le dépôt (D27, BR-014 règle 9).
10. **Hors voiture.** Android Auto ne montre pas l'accueil (BR-013 règle 2 reste).

## Cas limites

- Bibliothèque vide : état vide.
- Un seul album, et c'est celui de la piste courante : pas d'album ; les pistes des autres albums restent possibles.
- Historique désactivé (BR-014 règle 7) : l'historique déjà enregistré reste lu pour la règle des 30 jours ; l'effacer ne laisse que les favoris et le niveau 2.
- Heure de l'appareil changée en arrière : une écoute « dans le futur » compte comme récente ; pas de correction.

## Révision du 2026-11-14

Décisions du propriétaire après la maquette : la carte « Reprendre » est retirée (doublon du mini-lecteur) et remplacée par trois pistes ; deux albums seulement (quatre serraient la page) ; un élément indisponible n'est pas affiché. Remplace l'ancienne règle « dernier joué » (anciennes règles 1 à 4) et l'ancienne règle 9 (album grisé).

## À valider (PO)

- Niveau 2 = jamais écoutés (règle 4) : c'est une découverte plus qu'une redécouverte. Autre choix : sections vides tant qu'aucune écoute n'a 30 jours.
- Seuil de 30 jours, trois pistes et deux albums (décidés pour 3 et 2), favoris comme signal de niveau 1.
- Tirage au démarrage et sur « Autres suggestions » plutôt qu'« à chaque affichage » (règle 6) : un tirage à chaque retour sur l'onglet changerait l'écran sous les doigts de l'utilisateur.
