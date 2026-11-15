# ADR-026 — Clé d'album normalisée et rattachement des albums sans artiste d'album

**Statut :** Active (validée le 2026-11-14) · **Date :** 2026-11-14 · **Ticket :** MPL-082 · **Décisions :** D23, D27 · **Fiches :** BR-017, FR-035, BR-010, BR-013, FR-032, ADR-022 · **Complète :** ADR-016, ADR-020, ADR-022

## Contexte

`LibraryGroups.build` (`lib/features/browse/library_groups.dart`) construit la clé d'un album avec l'artiste de l'album (étiquette, sinon artiste de la piste) et le titre, repliés par `sortKey` (casse, table d'accents latins, espaces). Un album dont chaque chanson a un interprète différent et pas d'étiquette « artiste de l'album » se découpe donc en albums d'une piste (limite déjà notée dans BR-010). Le repli ne traite pas non plus les accents combinants, les apostrophes et tirets de formes différentes, ni les espaces de largeur nulle. La clé est consommée par la grille et le détail, la demande de navigation du lecteur (ADR-022), l'arbre de la voiture (ADR-020, identifiants stables) et l'Accueil (ADR-024). Les favoris et l'historique suivent la piste (BR-004), pas l'album.

## Décision

1. **Normalisation dédiée à l'album.** Une fonction pure `albumKeyText` de `features/browse/` (pas de nouveau paquet : pas de bibliothèque Unicode ; on retire les accents combinants U+0300–U+036F et les caractères de mise en forme, on ramène les formes de ponctuation et on étend la table de repli) sert `_fold` d'album. `foldText` et `sortKey` restent tels quels : la recherche (BR-011) et les lettres (FR-013) ne bougent pas.
2. **Rattachement en second passage dans `LibraryGroups.build`.** Le premier passage reste celui d'aujourd'hui. Un second passage regroupe, par (disque, chemin relatif complet du dossier, titre normalisé), les albums dont l'artiste vient de la piste ou est « divers », s'il y en a au moins deux ; il les fusionne. Les pistes gardent leur ordre (BR-010, règle 6) ; la fusion se fait avant le calcul des artistes.
3. **Artiste « Artistes divers ».** `AlbumGroup` gagne un indicateur `variousArtists` (et `artist` reste vide, comme pour l'artiste inconnu) ; l'interface le traduit. `ArtistGroup` « divers » a une clé fixe, réservée (jamais le repli d'un nom réel). Le texte affiché vient de l'ARB ; `build` reçoit le libellé replié pour trier l'entrée parmi les artistes.
4. **Domaine intact.** Pas de schéma de base, pas de changement du scanner ni des étiquettes lues : tout est calculé à partir des champs déjà stockés (`albumArtist`, `artist`, `album`, chemin relatif, disque). Aucune migration, aucun nouvel accès natif.
5. **Identifiants de la voiture.** Les clés d'album changent une fois (normalisation, albums fusionnés) ; les identifiants de dossiers de l'arbre (BR-013, règle 7) changent à la mise à jour. Effet : une application voiture qui avait mémorisé un dossier d'album revient à la racine ; sans perte de données. À noter dans HOWTO et signaler au propriétaire.
6. **Diagnostic avant code.** Les règles de BR-017 dépendent de la façon dont les fichiers du propriétaire sont étiquetés et rangés. La procédure du ticket MPL-082 (export hors dépôt, D27) donne les chiffres ; le garde-fou du dossier est décidé d'après eux.

## Conséquences

- Les albums d'un dossier ressemblent à ce que le propriétaire attend, sans toucher aux fichiers. Faux rapprochement possible seulement entre deux albums de même titre, sans étiquette d'artiste de l'album, dans le même dossier : le garde-fou le limite.
- Un album en deux dossiers (CD1, CD2) sans étiquette reste scindé tant que l'option « dossier parent commun » n'est pas retenue.
- Le coût du regroupement reste un passage de plus sur les albums (test de 7 500 pistes à conserver).
- Les fiches `Active` BR-010, FR-020, FR-021, FR-029, FR-032, FR-033 sont complétées à la validation.

## Alternatives examinées

- **Regrouper par titre d'album seul, partout** : simple, mais fusionne les « Greatest Hits », « Live » ou « Best of » de tous les artistes. Écarté.
- **Regrouper par titre seul pour les pistes sans étiquette d'artiste de l'album** (sans garde-fou de dossier) : plus de rattachements, risque de faux rapprochements ; proposé comme choix (b) dans BR-017.
- **Artiste de l'album = artiste le plus fréquent du groupe** : une bande originale apparaîtrait sous un interprète quelconque ; trompeur. Écarté.
- **Lire le drapeau « compilation » des étiquettes** (`METADATA_KEY_COMPILATION` côté fichier ; côté MediaStore à vérifier) : exigerait une colonne (schéma 7) et un nouveau rescan ; reporté, utile si les étiquettes du propriétaire le portent.
- **Réglage manuel de fusion** (forcer ou défaire un regroupement) : demande une table de dérogations (schéma 7), un écran et des clés stables qui survivent à la renormalisation ; trop lourd pour un défaut qui se règle par le code. Reporté après le diagnostic ; la correction à la source reste MPL-067 (éditeur d'étiquettes).
- **Utiliser une bibliothèque de normalisation Unicode (NFKD)** : nouvelle dépendance épinglée (D30) pour un besoin couvert par une table et la suppression des accents combinants. Écartée.

## Validé par le propriétaire (2026-11-14)

Les points ci-dessous sont validés avec la recommandation : garde-fou du dossier (a), artiste « Artistes divers », pas de lien artiste dans le lecteur pour un tel album, changement unique des identifiants de dossiers de la voiture, réglage manuel de fusion écarté pour l'instant. Le reste est repris tel quel.

- Le choix (a) ou (b) du garde-fou et l'option « dossier parent commun » (BR-017).
- Le changement unique des identifiants de dossiers de la voiture (décision 5).

## Écarts constatés à l'implémentation (À valider, PO)

- **Tri de l'entrée « Artistes divers ».** La décision 3 prévoyait de passer le libellé à `LibraryGroups.build` pour la trier par ordre alphabétique. Le groupe est calculé sans accès à la langue ; l'entrée est donc placée **en tête, juste après « Artiste inconnu »**, dans le groupe « # » de l'onglet Artistes. Autre choix : passer le libellé (provider lié à la langue).
- **Recherche.** « Artistes divers » n'est pas un texte cherché (même règle que l'artiste inconnu, BR-011 règle 2), pour la même raison. FR-035.8 en dit plus : à confirmer ou à compléter.
