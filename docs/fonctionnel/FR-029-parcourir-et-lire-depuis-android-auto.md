# FR-029 — Parcourir et lire depuis Android Auto

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-060 · **Décisions :** D6, D12, D15 · **Lié :** UC-012, BR-013, FR-005, FR-022, ADR-020

## Besoin

TuneShell apparaît dans Android Auto, se parcourt à l'écran de la voiture et se commande au volant. L'interface est fournie par Android Auto ; TuneShell ne fournit que l'arbre et la lecture.

## Exigences

1. **Déclaration.** L'application se déclare application multimédia d'Android Auto ; aucune permission ajoutée, pas d'`INTERNET` (D15). Elle est visible dans le lanceur d'Android Auto.
2. **Navigation.** La racine et les niveaux suivent BR-013. Chaque élément montre titre, sous-titre (artiste pour un album ou une piste) et pochette quand elle existe ; sans pochette, une icône neutre de la marque.
3. **Lecture.** Choisir une piste, un album ou un artiste lance la lecture (BR-013, règle 5). « Reprendre » rejoue la session enregistrée (BR-013, règle 2).
4. **Commandes.** Lecture, pause, précédent, suivant et déplacement dans la piste agissent sur la lecture en cours, comme dans la notification (FR-005). L'écran de la voiture montre la piste, l'artiste, l'album, la pochette et la position.
5. **Téléphone non ouvert.** Tout fonctionne sans que l'écran du téléphone soit allumé et sans que l'application ait été ouverte depuis le démarrage du téléphone (ADR-020).
6. **Réactivité.** La racine s'affiche sans attente perceptible ; une liste longue s'affiche en un temps que la voiture accepte (seuil mesuré, voir À valider).
7. **Erreurs.** Une piste illisible ou un disque éjecté se signalent par l'état de lecture d'Android Auto, avec les messages de BR-003 et BR-008, pas par un écran du téléphone.
8. **Pas de saisie.** Aucun champ de texte ni recherche (règle de conduite d'Android Auto ; recherche vocale hors périmètre).
9. **Textes.** Libellés fixes (« Reprendre », « Albums », « Artistes », « Pistes », message de bibliothèque vide) dans les fichiers ARB, français et anglais.

## Hors périmètre

Recherche vocale, commandes vocales, Android Automotive OS, CarPlay, publication Play Store, mise en page personnalisée.

## À valider (PO)

- Exigence 6 : seuil de temps d'affichage à fixer après la mesure en voiture.
- Les actions personnalisées « Aléatoire » et « Répéter » ne sont pas proposées dans la voiture (comme dans la notification, ADR-015).

## As-built

À renseigner à la livraison.
