# FR-025 — Réglages de la bibliothèque et de la lecture

**Statut :** Brouillon · **Créée le :** 2026-10-25 · **Ticket :** MPL-051 · **Décisions :** D23, D25 · **Lié :** UC-003, UC-009, FR-003, FR-006, FR-011, FR-014, FR-015, FR-023, BR-005, BR-008, ADR-017 · **Source :** `docs/design/HANDOFF.md` §5 (8e), décisions du propriétaire du 2026-10-24

## Besoin

Retrouver dans Réglages la configuration de la bibliothèque (dossiers, disques), garder une actualisation à portée de main sans pastille permanente, et régler deux comportements : le démarrage et le débranchement du casque.

## Exigences

1. **« Dossiers de musique »** (navigation). Ouvre le choix des dossiers du téléphone (FR-003.4, FR-015) dans l'onglet Réglages, avec une flèche de retour ; « Valider » ou le retour ramène à Réglages ; valider lance l'indexation, que montre l'onglet Pistes. Sous-titre : « N dossiers · {noms} » (tronqué), ou « Aucun dossier ». Sans accès aux fichiers audio du téléphone, la ligne ramène à l'explication d'accès (FR-014.5).
2. **« Disques amovibles »** (navigation). Ouvre l'écran des disques existant (UC-003) dans l'onglet. Sous-titre : le nom du disque et son état (« T7 Shield · non connecté »), « N disques », ou « Aucun disque ». Un disque absent ou à accès perdu ajoute un badge ambre « N absent » sur la ligne (BR-007, règle 3 : texte, pas la couleur seule).
3. **Pistes sans pastilles.** Les pastilles « Actualiser », « Dossiers » et « Disques » (FR-011.2) quittent l'onglet Pistes : son en-tête ne garde que le titre et la loupe grisée. Le bandeau de source absente et son bouton « Voir » restent dans Pistes (BR-008, règle 2) et ouvrent l'écran des disques.
4. **Tirer pour actualiser.** Tirer la liste des Pistes, des Albums ou des Artistes vers le bas, au sommet de la liste, lance la même actualisation que l'ancienne pastille (FR-003.7 : téléphone et disques, nouvelles étiquettes, étiquettes en échec relues). Le cercle de progression dure jusqu'à la fin de l'indexation des fichiers, pas de la lecture des étiquettes (qui garde son bandeau). Pendant une indexation en cours, le geste ne relance rien. Une liste vide ou en chargement n'a pas de geste : « Actualiser maintenant » la remplace.
5. **« Actualiser maintenant »** (action, section Bibliothèque), sous-titre « Cherche les nouveaux fichiers ». Même effet que l'exigence 4 ; grisée pendant une indexation.
6. **« Actualiser au démarrage »** (interrupteur, activé par défaut), sous-titre « Cherche les nouveaux fichiers à chaque ouverture ». Désactivé : le lancement montre la bibliothèque enregistrée sans réindexer le téléphone ni les disques ; la disponibilité des disques est tout de même lue (BR-008, règle 1). La toute première indexation après le choix des dossiers a toujours lieu.
7. **« Pause si le casque est débranché »** (interrupteur, activé par défaut), sous-titre « Recommandé ». Désactivé : débrancher un casque filaire ou déconnecter un appareil Bluetooth ne met plus la lecture en pause (BR-005, règle 5). Le focus audio (appels, autres applications) est inchangé.
8. Textes dans les fichiers ARB, en français mot pour mot des maquettes quand elles en ont (« Dossiers de musique », « Disques amovibles », « Actualiser au démarrage », « Cherche les nouveaux fichiers à chaque ouverture », « Pause si le casque est débranché », « Recommandé »), avec la version anglaise.

## Hors périmètre

Choisir ou modifier le repère d'un disque, désactiver un disque et ses dossiers (MPL-056), refonte de l'écran des disques (MPL-046), « Reprendre là où j'en étais » (MPL-053), « Ignorer les fichiers courts » (MPL-054), actualisation périodique en arrière-plan.

## À valider (PO)

Cette fiche s'écarte de trois fiches `Active` : elles ne sont pas modifiées, leur écart est ici.
- FR-011, exigence 2 : les pastilles quittent Pistes (décision du propriétaire du 2026-10-24).
- FR-003, exigence 7 : l'indexation « à chaque démarrage » devient un réglage, activé par défaut (exigence 6).
- BR-005, règle 5 : le débranchement du casque met en pause « toujours » ; elle devient un réglage, activé par défaut (exigence 7).
- Exigence 4 : le cercle s'arrête à la fin de l'indexation des fichiers, pas à celle des étiquettes (qui peut durer des minutes sur un disque).
- Exigence 5 : le libellé « Actualiser maintenant » et son sous-titre sont de moi.
- Exigence 6 : désactivé, un disque branché pendant la session n'est pas indexé avant une actualisation (la détection du branchement en direct vient avec MPL-046).

## As-built

À écrire à la livraison.
