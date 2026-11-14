# FR-034 — Identité de la build : version, commit et état de l'arbre

**Statut :** Brouillon · **Créée le :** 2026-11-14 · **Ticket :** MPL-081 · **Décisions :** D14, D15, D26, D27 · **Lié :** FR-026, FR-023, UC-009, ADR-017, ADR-025 · **Source :** demande du propriétaire du 2026-11-14 (« la version affichée n'est pas assez précise pour savoir exactement la version utilisée/testée »)

## Besoin

Savoir, depuis l'écran du téléphone, quelle build exacte est installée : deux builds faites à des moments différents affichent aujourd'hui « 0.1.0 », donc un test sur le Pixel (D14) ne dit pas ce qu'il a testé.

## Exigences

1. **Identité affichée.** La page À propos et la ligne « TuneShell {version} » de Réglages (FR-026.1) montrent la version du `pubspec.yaml`, le **commit court** de la build (7 caractères) et, si l'arbre avait des modifications non commitées à la compilation, la mention « modifié ». Exemple : « 0.1.0 · a1b2c3d » ou « 0.1.0 · a1b2c3d · modifié ». La date de compilation (UTC, jour) suit : « 2026-11-14 ».
2. **Une build sans identité le dit.** Compilée sans les valeurs (par exemple `flutter run` ou `flutter test`), la build affiche « 0.1.0 · build locale » : jamais un faux commit, jamais une valeur vide.
3. **Source unique, pas de saisie à la main.** Le commit, la mention « modifié » et la date sont calculés au moment de la compilation par un script du dépôt (voir ADR-025) ; personne ne les écrit dans un fichier suivi. Le test de `pubspec.yaml` (FR-026.5) reste : la version affichée est celle du `pubspec.yaml`.
4. **Copiable.** L'identité complète est sélectionnable (comme l'adresse du code, FR-026.2) pour la coller dans un rapport de test.
5. **Aucune donnée privée, aucun réseau.** Le commit est public (dépôt public) ; rien n'est envoyé (D15, D26). Pas de nom de machine, de chemin ni d'utilisateur dans l'identité (D27).
6. **Accessibilité et règles d'interface.** Jetons, clair et sombre, texte lisible à 200 % (BR-007). Textes dans les fichiers ARB, en français et en anglais.

## Hors périmètre

Mise à jour automatique, vérification d'une version plus récente, journal des modifications dans l'application, numéro de build autoincrémenté (voir ADR-025, « Alternatives »), signature de production (D5).

## À valider (PO)

- **Écart à FR-026 (`Active`)** : l'exigence 1 dit « la version est celle de `pubspec.yaml` » et l'exigence 5 « un test les compare » ; elles restent vraies, l'identité s'y ajoute. Aucune n'est modifiée avant validation.
- **Écart à ADR-017 (`Active`)** : « pas de `package_info_plus`, pas de code natif » reste respecté ; la ligne « Version » est complétée, pas remplacée.
- **Numéro de build** (`+1` du `pubspec.yaml`) : non affiché, car il ne change pas d'une build à l'autre ; le commit joue ce rôle. Autre choix : augmenter le `+N` à la main à chaque test.
- **Date de compilation** : proposée, retirable sans conséquence si le commit suffit.

## As-built

À écrire à la livraison.
