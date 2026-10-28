# FR-023 — Écran Réglages et stockage des réglages

**Statut :** Active (validée le 2026-10-25) · **Créée le :** 2026-10-25 · **Ticket :** MPL-051 · **Décisions :** D15, D30 · **Lié :** UC-009, FR-009, FR-010, FR-024, FR-025, FR-026, BR-007, ADR-016, ADR-017 · **Source :** `docs/design/HANDOFF.md` §5 (écran 8, 8e), `Reglages.dc.html`

## Besoin

Un écran qui réunit les réglages de l'application, retenus d'un lancement à l'autre.

## Exigences

1. **Structure.** L'onglet Réglages (FR-009) montre le titre « Réglages » et quatre sections, chacune avec un intitulé : « Bibliothèque », « Apparence », « Lecture », « À propos ». Les lignes sont de trois sortes : navigation (flèche ›, ouvre une page), interrupteur, bouton segmenté (le thème). Chaque ligne a un libellé et un sous-titre explicatif, zone tactile d'au moins 48 dp.
2. **Seuls les réglages qui fonctionnent.** Une ligne n'est montrée que si son effet est livré. « Reprendre là où j'en étais » (MPL-053) et « Ignorer les fichiers courts » (MPL-054) de la maquette sont absents tant qu'ils ne sont pas faits.
3. **Dans l'onglet.** Les pages ouvertes depuis Réglages (dossiers, disques, À propos, Confidentialité, licences) s'ouvrent dans l'onglet par son navigateur (ADR-016) : la navigation et le mini-lecteur restent ; le Retour du système ramène à Réglages avant de ramener sur Pistes.
4. **Valeurs par défaut.** Thème Système ; couleurs du fond d'écran désactivées ; index à droite ; pause au débranchement du casque activée ; actualisation au démarrage activée.
5. **Mémoire.** Un réglage change aussitôt et est conservé d'un lancement à l'autre, y compris après l'arrêt de l'application par Android (ADR-017).
6. **Pas de clignotement.** Les réglages sont lus avant le premier écran : un thème sombre choisi ne montre pas un instant le thème clair.
7. **Valeur illisible.** Une valeur absente, inconnue ou abîmée donne la valeur par défaut, sans message ni plantage.
8. **Galerie de composants.** Dans les builds debug et profile, une ligne ouvre la galerie, comme aujourd'hui (FR-010.7) ; la release ne l'a pas.
9. **Paysage et grands écrans.** La liste garde une largeur de lecture confortable (au plus 600 dp, centrée) ; la navigation est celle de FR-009.
10. **Accessibilité.** Chaque interrupteur annonce son libellé, son sous-titre et son état ; le bouton segmenté annonce son choix ; les lignes de navigation se lisent comme des boutons.
11. **Règles d'interface et textes.** Jetons seulement, clair et sombre, animations réduites respectées (BR-007) ; textes dans les fichiers ARB, en français mot pour mot des maquettes, avec la version anglaise.

## Hors périmètre

Réglages cachés, profils, import et export, réinitialisation générale, langue de l'interface.

## À valider (PO)

- Exigence 9 : largeur maximale de 600 dp, de moi.
- Exigence 2 : les deux réglages de la maquette qui n'ont pas d'effet encore sont retirés de l'écran, au lieu d'être affichés inactifs.
- FR-009, exigence 2 (`Active`) dit que Réglages affiche « bientôt » jusqu'à MPL-048 : ce ticket le remplace.

## As-built

MPL-051, 2026-10-25, test appareil non fait (D14) : le Pixel était verrouillé ; seuls l'installation de la build release par-dessus la précédente et son démarrage sans plantage ont été constatés. `SettingsPage` (`lib/features/settings/settings_page.dart`), tuiles dans `lib/ui/widgets/settings_tiles.dart` (`SettingsSectionHeader`, `SettingsNavTile`, `SettingsSwitchTile`, `SettingsSegmentedTile`), `AppSettings` et `SettingsStore` (`lib/domain/settings/`), `AppSettingsNotifier` (`lib/app/providers/settings_providers.dart`), table `app_settings` (schéma v4) et `DriftSettingsStore`.

- L'onglet a son navigateur (`_TabNavigator` de `HomeShell`) ; le Retour du système y entre avant de ramener sur Pistes.
- Les réglages sont lus par `main()` avant `runApp` ; une lecture qui échoue donne les défauts ; une écriture qui échoue est journalisée et ne défait pas l'affichage.
- Largeur maximale 600 dp, centrée (test). La galerie est montrée par `kDebugMode || kProfileMode`.

MPL-053, 2026-10-28 : la ligne « Reprendre là où j'en étais » (FR-028) rejoint la section « Lecture ». L'exigence 2 ne vise plus que « Ignorer les fichiers courts » (MPL-054).
