# ADR-022 — Ouvrir un album ou un artiste depuis le lecteur plein écran

**Statut :** Brouillon · **Date :** 2026-11-12 · **Ticket :** MPL-076 · **Fiches :** FR-032, FR-017, FR-020, FR-021, BR-010 · **Complète :** ADR-016

## Contexte

Le lecteur est une route poussée sur le navigateur racine (FR-017). Les détails d'album et d'artiste sont des routes des navigateurs imbriqués des onglets (ADR-016) : le lecteur ne peut pas les pousser lui-même. `features/` ne connaît que `domain/`, `ui/` et `app/providers/` ; `ui/` ne connaît ni Riverpod ni le domaine.

## Décision

- Une **demande de navigation** : un fournisseur `browseRequestProvider` dans `app/providers/` porte une valeur `(onglet, clé du groupe)` ou rien. Le lecteur l'écrit puis se réduit ; `HomeShell` l'écoute, change d'onglet, pousse le détail sur le navigateur de l'onglet (en vidant d'abord ce navigateur jusqu'à sa grille) et efface la demande. Les clés sont celles de BR-010 ; la demande ne porte ni titre ni chemin.
- Le **composant de lien** est un widget de `ui/` qui reçoit un texte, un libellé et un rappel (ADR-010) ; le lecteur calcule dans `features/` si le groupe existe.
- Aucune dépendance nouvelle, aucun routeur de paquet.

## Conséquences

- Le détail s'ouvre toujours sur une pile propre de l'onglet : pas d'empilement de détails en chaîne.
- Pour la partie B (voiture), l'arbre média reçoit la piste courante et en déduit les deux groupes avec les mêmes clés ; rien ne passe par la demande de navigation.

## Alternatives examinées

- Pousser le détail sur le navigateur racine par-dessus le lecteur : cache la navigation et le mini-lecteur, incohérent avec ADR-016 ; écartée.
- Rouvrir le lecteur au retour : demande de garder l'état de provenance ; reportée (À valider de FR-032).

## À valider (PO)

- Vider la pile de l'onglet avant d'ouvrir le détail (le détail ouvert depuis une autre grille ne garde pas son ancienne position).
