# FR-031 — Favoris, pastilles de la liste de pistes et réglage de l'historique

**Statut :** Brouillon · **Créée le :** 2026-11-03 · **Ticket :** MPL-065 · **Décisions :** D15 · **Lié :** UC-013, UC-005, FR-009, FR-010, FR-011, FR-013, FR-017, FR-019, FR-023, FR-025, FR-027, BR-007, BR-014, ADR-021 · **Source :** décision du propriétaire du 2026-11-03 (filtres en haut de Pistes) ; pas de maquette : à dessiner avec le design (MPL-016) avant l'implémentation

## Besoin

Marquer des favoris, les retrouver, retrouver ce qu'on a écouté récemment, et garder la main sur l'historique.

## Exigences

1. **Pastilles.** Sous le champ de recherche de l'onglet Pistes (FR-027), trois pastilles à choix unique : « Toutes » (par défaut), « Favoris », « Récentes ». Zone tactile d'au moins 48 dp, état annoncé par TalkBack, libellés dans les fichiers ARB. Le choix est retenu pendant la session, pas d'un lancement à l'autre.
2. **Listes filtrées.** BR-014 règle 8. La lecture d'une piste de la liste filtrée met en file la liste filtrée, comme pour la liste habituelle (FR-011). Le saut de lecture, la piste grisée et le message d'un disque absent restent ceux de FR-011.
3. **Cœur du lecteur.** Le cœur du lecteur plein écran (FR-017 exigence 5) marque ou retire la piste en cours : plein quand elle est favorite, avec un retour haptique léger, libellé TalkBack « Ajouter aux favoris » / « Retirer des favoris ».
4. **Appui long.** Le menu d'appui long d'une ligne (FR-019) reçoit « Ajouter aux favoris » / « Retirer des favoris ».
5. **États vides.** « Favoris » sans favori et « Récentes » sans écoute montrent un message du composant d'état vide (BR-007), avec le geste à faire. Une recherche sans résultat garde le message de FR-027.
6. **Réglages.** Dans la section « Lecture » de Réglages (FR-023) : un interrupteur « Enregistrer l'historique d'écoute » (BR-014 règle 7) et une ligne « Effacer l'historique » avec confirmation. Zones de 48 dp, texte et état annoncés par TalkBack.
7. **Enregistrement.** Une écoute est enregistrée selon BR-014 règle 4, sans ralentir la lecture ni l'interface ; un échec d'écriture est consigné (sans identité, D27) et n'interrompt rien.
8. **Textes.** Fichiers ARB, français et anglais (BR-007).

## Hors périmètre

Voir UC-013 (playlists, favoris d'albums ou d'artistes, statistiques affichées, suggestions, Android Auto, export).

## À valider (PO)

- Exigences 1, 4 et 6 : placement et textes sans maquette ; un lot de design court est à prévoir avant le code.
- Exigence 1 : le choix de la pastille n'est pas retenu d'un lancement à l'autre.
