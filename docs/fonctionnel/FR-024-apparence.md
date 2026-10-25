# FR-024 — Apparence : thème, couleurs du fond d'écran, index à gauche

**Statut :** Active (validée le 2026-10-25) · **Créée le :** 2026-10-25 · **Ticket :** MPL-051 · **Décisions :** D15, D30 · **Lié :** UC-009, FR-008, FR-010, FR-013, FR-023, ADR-010, ADR-017 · **Source :** `docs/design/HANDOFF.md` §2.1, §6.1 (point 8), §5 (8e)

## Besoin

Choisir clair, sombre ou le thème du système, emprunter les couleurs du fond d'écran d'Android, et mettre l'index alphabétique du côté de la main qui tient le téléphone.

## Exigences

1. **Thème.** Un bouton segmenté « Système », « Clair », « Sombre ». « Système » suit le thème d'Android en direct (FR-008.2) ; les deux autres l'imposent. Le choix s'applique à toute l'application, lecteur et feuilles comprises, sans la redémarrer.
2. **Couleurs du fond d'écran** (Material You). Un interrupteur « Couleurs du fond d'écran », sous-titre « Remplace le menthe par les couleurs d'Android ». Actif : les `ColorScheme` clair et sombre viennent d'Android (`dynamic_color`, ADR-017) à la place de ceux de Design ; `TsColors` (repères de source, indisponible, ligne en cours, marque) reste fixe, comme le prescrit la conception. Désactivé par défaut.
3. **Pas de couleurs dynamiques.** Quand Android ne les fournit pas (version avant 12, `minSdk` 30), la ligne est grisée, son sous-titre dit « Android 12 ou plus », et l'application garde ses couleurs.
4. **Index à gauche.** Un interrupteur « Index alphabétique à gauche », sous-titre « Pour une utilisation de la main gauche ». Actif : la poignée, la colonne et la bulle de la lettre sont du côté gauche dans Pistes, Albums et Artistes (FR-013.1, FR-020.6, FR-021.4), le rectangle de la poignée gauche est exclu du geste Retour d'Android (FR-013.2) et celui du côté droit est retiré. La grille « Aller à la lettre » ne change pas. Désactivé par défaut.
5. **Contrastes.** Les paires de couleurs des jetons restent celles de FR-008.7 ; avec les couleurs dynamiques, celles qu'Android fournit s'appliquent telles quelles.
6. **Dépendance.** `dynamic_color` (version épinglée, justifiée dans ADR-017, D30) est la seule dépendance nouvelle du ticket.

## Hors périmètre

Choix d'une couleur d'accent, thème noir pur, taille du texte propre à l'application (elle suit celle d'Android), images de fond.

## À valider (PO)

- Exigence 6 : nouvelle dépendance `dynamic_color` (D30, validation du propriétaire exigée).
- Exigence 4 : le côté « gauche » est le côté physique gauche (l'application n'a que des langues de gauche à droite).
- Exigence 3 : texte « Android 12 ou plus », de moi.

## As-built

MPL-051, 2026-10-25, test appareil non fait (D14) : le Pixel était verrouillé ; seuls l'installation de la build release par-dessus la précédente et son démarrage sans plantage ont été constatés. `TuneShellApp` (`lib/app/app.dart`) lit le thème et les couleurs dynamiques du réglage ; `DynamicColorBuilder` de `dynamic_color` 1.9.0 (et non 2.1.0, voir ADR-017) donne les schémas ; `TsColors` reste fixe. `dynamicColorsSupportedProvider` dit si Android a des couleurs dynamiques : sinon la ligne est grisée et dit « Android 12 ou plus », et le thème garde ses couleurs même si le réglage est vrai en base. L'index lit `appSettingsProvider.indexOnLeft` (`alignStart` des trois `AlphabetScroller`). Tests : `test/app/app_test.dart`, `test/features/browse/browse_views_test.dart`, `test/features/library/library_page_test.dart`.
