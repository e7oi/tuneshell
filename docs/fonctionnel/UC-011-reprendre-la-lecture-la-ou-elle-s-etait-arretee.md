# UC-011 — Reprendre la lecture là où elle s'était arrêtée

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-053 · **Lié :** UC-002, UC-007, FR-001, FR-005, FR-016, FR-017, FR-018, FR-023, FR-028, BR-001, BR-004, BR-009, BR-012, ADR-019 · **Source :** idée de la conception (`docs/design/HANDOFF.md` §5, écran 8e), découpée de MPL-048 le 2026-10-23

## Acteur et but

L'utilisateur écoutait un album, un artiste ou une longue liste, puis l'application s'est arrêtée (retrait des applications récentes en pause, Android qui la ferme, redémarrage du téléphone). Il la rouvre et veut retrouver sa musique où il l'avait laissée, sans rechercher la piste ni refaire la file.

## Préconditions

- Une file avait été constituée (UC-001, UC-003, UC-007, UC-010).
- Le réglage « Reprendre là où j'en étais » est activé (FR-028) ; il l'est par défaut.

## Scénario nominal

1. Au lancement, l'application ouvre sur l'onglet Pistes, comme aujourd'hui (FR-009).
2. Quelques instants après, le mini-lecteur apparaît avec la piste qui jouait, **en pause**, et sa barre de progression à la position où elle s'était arrêtée (FR-016).
3. L'utilisateur touche lecture : la piste repart de cette position, puis la file continue (FR-001), avec les mêmes modes aléatoire et répétition qu'avant.
4. Il peut aussi ouvrir le lecteur plein écran et la file (FR-017, FR-018) : ils sont ceux de la veille.

## Variantes

- 2a. Rien n'avait été mis en file, ou la file avait été vidée : le mini-lecteur n'apparaît pas.
- 2b. Des pistes de la file ont disparu de la bibliothèque (fichier supprimé, déplacé, dossier retiré) : elles ne reviennent pas ; la file reprend avec les autres (BR-012).
- 2c. La piste qui jouait a disparu : la file reprend à la piste suivante restante, au début de celle-ci (BR-012).
- 2d. La piste ou une partie de la file est sur un disque absent : elles reviennent grisées ; au lancement de la lecture, les pistes de ce disque sont sautées avec le message habituel (BR-001).
- 3a. L'utilisateur choisit d'autres pistes avant la fin de la restauration : son choix l'emporte, rien n'est restauré par-dessus (BR-012).
- 1a. Le réglage est désactivé : rien n'est restauré, rien n'est enregistré, et la file enregistrée est effacée (BR-012, FR-028).

## Hors périmètre

Lancer la lecture tout seul à l'ouverture, afficher la notification ou démarrer le service avant un « Lecture » (FR-005), reprise par une touche média quand le processus est mort, restauration de l'onglet, du défilement, du détail ouvert ou d'une recherche, historique des files, plusieurs files enregistrées, synchronisation entre appareils.
