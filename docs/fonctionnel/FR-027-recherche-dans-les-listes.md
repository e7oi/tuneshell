# FR-027 — Recherche dans les listes Pistes, Albums et Artistes

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-055 · **Décisions :** D3 · **Lié :** UC-010, UC-005, UC-008, FR-009, FR-010, FR-011, FR-013, FR-018, FR-020, FR-021, FR-022, BR-007, BR-008, BR-011, ADR-010, ADR-016, ADR-018 · **Source :** demande du propriétaire du 2026-10-24 ; **la conception ne montre pas d'écran de recherche** (`docs/design/HANDOFF.md` §4 : emplacement discret ; §8 : hors périmètre)

## Besoin

Retrouver vite une piste, un album ou un artiste en tapant quelques lettres, dans la vue où l'on se trouve.

## Exigences

1. **Ouverture.** Les trois vues ont une loupe à droite de leur titre. Dans Pistes elle remplace le bouton désactivé « Rechercher (bientôt) » (FR-011.1). Toucher la loupe remplace le titre par un champ de texte plein largeur : flèche de retour à gauche, bouton « Effacer » à droite quand le champ n'est pas vide, clavier ouvert, focus dans le champ. Indications : « Rechercher une piste », « Rechercher un album », « Rechercher un artiste » (textes proposés).
2. **Résultats en direct.** À chaque frappe la liste est remplacée par les lignes qui correspondent (BR-011) ; l'ordre est celui de la vue. La ligne de compte devient « {n} résultats » (« 1 résultat »).
3. **Une recherche par vue.** Chaque vue garde sa requête quand on change d'onglet et qu'on revient, et quand un détail s'ouvre puis se ferme. Elle n'est pas gardée entre deux lancements. La fermer (Retour, flèche) la vide.
4. **Pendant la recherche.** L'index alphabétique est masqué (la liste filtrée est courte et ses lettres changent à chaque frappe). Les bandeaux (sources, progression) restent : la recherche n'enlève aucune information d'état. Tirer pour actualiser (FR-011) reste possible.
5. **Toucher un résultat.** Piste : elle se lance, la file est **tous les résultats affichés**, dans leur ordre (comme FR-011.8 pour la liste affichée) ; la provenance de la file est « Recherche · {requête} » (FR-018, ADR-016). Album ou artiste : le détail s'ouvre dans l'onglet (FR-020, FR-021) ; au retour la recherche est intacte. Une ligne d'un disque absent reste touchable et explique (BR-008, règle 5).
6. **Aucun résultat.** Le message « Aucun résultat pour « {requête} » » et un bouton « Effacer la recherche » à la place de la liste.
7. **Bibliothèque vide.** La loupe est désactivée, comme aujourd'hui.
8. **Clavier.** L'action « Rechercher » du clavier le ferme et garde les résultats ; faire défiler la liste ferme aussi le clavier ; changer d'onglet le ferme sans vider la requête.
9. **Retour (geste, touche).** Ferme d'abord la recherche ouverte de la vue (la liste complète revient), après le clavier que le système ferme lui-même ; un détail ouvert par un résultat se ferme avant la recherche, puis le Retour ordinaire reprend (FR-009, ADR-016).
10. **TalkBack.** Le champ se lit « Rechercher une piste » ; le nombre de résultats est annoncé 0,5 s après la dernière frappe ; « Effacer » et la flèche ont un libellé (BR-007).
11. **Composant.** Un `SearchField` dans `lib/ui/widgets/` qui reçoit sa valeur et ses rappels, sans Riverpod ni domaine (ADR-010) ; jetons de `tuneshell_tokens.dart`, aucun littéral. Thèmes clair et sombre, portrait et paysage, échelle de texte jusqu'à 200 %.
12. **Performance.** Taper dans le champ reste à 60 images par seconde sur 7 500 pistes (profile, Pixel) ; la liste filtrée suit le plafond de deux reconstructions par seconde pendant la lecture des tags (FR-011.11).
13. Textes dans les fichiers ARB, français et anglais ; ceux de cette fiche sont proposés (la conception n'en fournit pas).

## Hors périmètre

Voir UC-010. Surlignage des lettres trouvées, classement par pertinence, tri ou filtre complémentaire.

## À valider (PO)

- **Pas de maquette.** La conception met la recherche hors périmètre (HANDOFF §8) : l'interface ci-dessus est ma proposition, sur le modèle habituel de Material (champ à la place du titre). Option : demander un écran à Claude Design avant l'implémentation.
- Exigence 5 : la file d'un résultat touché est **les résultats affichés** (recommandé, cohérent avec FR-011.8) plutôt que toute la bibliothèque.
- Exigence 3 : une recherche par vue, gardée entre les onglets, pas entre les lancements.
- Exigence 4 : index masqué pendant la recherche.
- Exigence 7 : loupe désactivée sans bibliothèque.
- Fiches `Active` touchées, non modifiées : FR-011 (exigence 1 et hors périmètre), FR-013 (index), FR-020 et FR-021 (en-têtes), FR-018 et ADR-016 (`QueueOrigin`), FR-009 (Retour) ; leur as-built est complété à la livraison.
