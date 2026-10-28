# UC-009 — Régler l'application

**Statut :** Active (validée le 2026-10-25) · **Créée le :** 2026-10-25 · **Ticket :** MPL-051 · **Lié :** UC-003, UC-004, UC-006, FR-023, FR-024, FR-025, FR-026, ADR-017 · **Source :** `docs/design/HANDOFF.md` §5 (écran 8, état 8e)

## Acteur et but

L'utilisateur veut choisir l'apparence de l'application, régler ce qui se passe au démarrage et quand le casque se débranche, retrouver ses dossiers de musique et ses disques, et savoir ce qu'est l'application (version, licence, données).

## Préconditions

- L'application est lancée ; l'accès aux fichiers audio est réglé (UC-006).

## Scénario nominal

1. L'utilisateur touche l'onglet **Réglages** : quatre sections, « Bibliothèque », « Apparence », « Lecture », « À propos » (FR-023).
2. Il choisit le thème **Sombre** : l'application change aussitôt ; au lancement suivant elle est restée sombre (FR-024).
3. Il active « Index alphabétique à gauche » : la poignée de l'index passe à gauche dans Pistes, Albums et Artistes (FR-024).
4. Il touche « Dossiers de musique » : le choix des dossiers s'ouvre dans l'onglet, avec un retour vers Réglages (FR-025).
5. Il touche « Disques amovibles » : l'écran des disques s'ouvre ; un disque absent est annoncé déjà sur la ligne (FR-025).
6. Il tire la liste des pistes vers le bas : la bibliothèque se réindexe (FR-025).
7. Il touche « TuneShell 0.1.0 » : la version, la licence GPL-3.0-or-later, les licences des composants et l'adresse du code source (FR-026) ; puis « Confidentialité » : ce que l'application garde sur le téléphone et ce qu'elle ne fait pas (FR-026).

## Variantes

- 2a. Le téléphone n'a pas les couleurs dynamiques (Android 11) : la ligne « Couleurs du fond d'écran » est grisée et dit pourquoi (FR-024).
- 4a. Sans accès aux fichiers audio du téléphone : toucher « Dossiers de musique » ramène à l'explication d'accès (FR-014).
- 6a. Une indexation tourne déjà : le geste ne la relance pas.
- 7a. Une valeur réglée illisible au démarrage (base abîmée) : la valeur par défaut s'applique, sans message (FR-023).

## Hors périmètre

« Reprendre là où j'en étais » (MPL-053), « Ignorer les fichiers courts » (MPL-054), recherche (MPL-055), désactiver un disque (MPL-056), langue (suit le système), réglages de l'égaliseur, de la minuterie ou du volume (non prévus), sauvegarde et export des réglages.

## As-built

MPL-051, 2026-10-25, test appareil non fait (D14) : le Pixel était verrouillé ; seuls l'installation de la build release par-dessus la précédente et son démarrage sans plantage ont été constatés. `lib/features/settings/` (écran, À propos, Confidentialité), `lib/features/library/folder_choice_page.dart`, `lib/app/providers/settings_providers.dart`, `lib/domain/settings/`. Tests : `test/features/settings/`, `test/domain/settings/`, `test/app/`, `test/features/library/`, `test/features/browse/`, `test/features/shell/`.
