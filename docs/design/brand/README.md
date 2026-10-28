# Marque TuneShell

Les images finales viennent d'une IA (réponse du propriétaire du 2026-10-28), choisies et validées par lui : demi-carapace à gauche, demi-haut-parleur à droite, note de musique au centre. Aucun fichier vectoriel : le propriétaire n'aime pas ce rendu (FR-030).

| Fichier | Usage | Statut |
|---|---|---|
| `logo-principal.jpeg` | Logo avec le texte « TuneShell », fond nuit | Référence validée |
| `icon_color.png` | Emblème en couleur, fond transparent : source de l'avant-plan de l'icône adaptative, de l'écran de démarrage et du logo de l'application (`assets/brand/emblem.png`) | Finale |
| `icon_monochrome.png` | Emblème blanc uni, fond transparent : couche monochrome (icônes à thème, Android 13 et plus) | Finale |
| `icon_notification.png` | Emblème blanc uni et simplifié, fond transparent : petite icône de notification (24 dp) | Finale |
| `logo-reference.jpg`, `note-centre-reference.png` | Références fournies par l'auteur | Référence, pas pour l'app |

## Couleurs

- Fond de l'icône : `#0D1528` (`TsColors.brandNight`, `@color/brand_night`)
- Menthe `#74FDD3` vers cyan `#3DD6D9` (`brandMint`, `brandCyan`)

## Intégration Android (MPL-049)

Les ressources sont écrites à la main, sans `flutter_launcher_icons` :

- Icône adaptative : `res/mipmap-anydpi/ic_launcher.xml` (et `-v33` avec la couche monochrome), fond `@color/brand_night`, avant-plan et monochrome en PNG de 432 px dans `res/drawable-nodpi/` ; l'emblème mesure 66 dp sur 108 (zone sûre).
- Notification : `res/drawable-*/ic_notification.png` (24, 36, 48, 72 et 96 px), référencée par `AudioServiceConfig.androidNotificationIcon` et gardée par `res/raw/keep.xml`.
- Écran de démarrage : `res/values-v31/` et `res/values-night-v31/` (Android 12 et plus), `res/drawable/launch_background.xml` avant.
- Logo de l'application : `assets/brand/emblem.png`, affiché par `TuneShellLogo`.

Les PNG de `res/` sont dérivés des fichiers de ce dossier : emblème recadré, canal alpha nettoyé, mis à l'échelle. Pour les refaire, repartir de ces sources.
