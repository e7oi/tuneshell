# ADR-025 — Identité de la build : valeurs de compilation, script de build, pas de plugin

**Statut :** Brouillon · **Date :** 2026-11-14 · **Ticket :** MPL-081 · **Décisions :** D14, D15, D27, D30 · **Fiches :** FR-034, FR-026, UC-009 · **Complète :** ADR-017

## Contexte

`appVersion` est une constante écrite à la main (`0.1.0`), seulement comparée par un test à la ligne `version:` de `pubspec.yaml` (`0.1.0+1`). Le `+1` ne change jamais : deux APK compilées à des commits différents sont indiscernables dans l'application. D14 exige le test réel d'une build release précise ; le propriétaire ne peut pas aujourd'hui le vérifier. ADR-017 a exclu `package_info_plus` et le code natif.

## Décision

- **Valeurs de compilation, sans dépendance.** Le commit court, l'état de l'arbre et la date arrivent par `--dart-define` (`BUILD_COMMIT`, `BUILD_DIRTY`, `BUILD_DATE`), lus par `String.fromEnvironment` dans une classe de domaine `BuildInfo` (Dart pur : le domaine n'importe pas Flutter). Valeurs absentes : « build locale » (FR-034.2).
- **Un script, pas des commandes à retenir.** `tool/build-release.sh` calcule les trois valeurs (`git rev-parse --short=7 HEAD`, `git status --porcelain`, `date -u`), vérifie que `flutter` voit bien le même arbre, puis lance `flutter build apk --release --dart-define=…` ; `HOWTO.md` §7 l'indique à la place de la commande nue. Le test réel (D14) se fait avec ce script ; une build sans lui s'annonce « build locale ».
- **Version.** Reste la constante `appVersion` testée contre `pubspec.yaml` (FR-026.5). Le numéro de build `+N` n'est pas affiché.
- **Affichage.** `BuildInfo.label` produit le texte (« 0.1.0 · a1b2c3d · modifié ») ; la page À propos et la ligne de Réglages l'utilisent ; test d'abord pour le formatage (domaine), un test de widget pour l'affichage.
- **Pas de CI.** Rien dans `code-ci.yml` : la CI ne compile pas d'APK. Si elle en compile un plus tard (MPL-026), elle appellera le même script.

## Conséquences

- Aucune dépendance, aucune permission, aucun code natif, aucun schéma.
- L'identité n'est exacte que si la build passe par le script ; c'est visible (« build locale ») plutôt que faux.
- Le commit affiché peut ne pas exister sur `origin` (commit local) ; « modifié » signale un arbre sale.

## Alternatives examinées

- **`package_info_plus`** : lit `versionName` et `versionCode` de l'APK installée, donc la même information que `pubspec.yaml`, sans le commit ; ajoute un plugin natif, contre ADR-017. Écartée.
- **Fichier généré et suivi (`build_info.dart` écrit par un hook Git)** : met un commit dans le code qui le contient (le commit change le commit) et salit l'arbre. Écartée.
- **Incrémenter `+N` à la main** : oublié tôt ou tard, pas de lien avec le code. Reportée si le propriétaire la préfère.
- **`git describe` dans Gradle (`versionName`)** : lisible par `package_info_plus` seulement, et couple la build Android à Git. Écartée.

## Risques à vérifier sur le Pixel

- La build faite par le script affiche bien le commit de la PR testée, et « modifié » après une modification locale.
- `flutter run` et les tests n'affichent aucun faux commit.

## À valider (PO)

- Le script comme chemin normal de compilation pour les tests sur le Pixel.
- L'absence de numéro de build affiché (voir FR-034, « À valider »).
