# FR-030 — Identité visuelle : icône d'application, icône de notification et écran de démarrage

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-049 · **Décisions :** D4, D26 · **Lié :** FR-005, FR-014, BR-007, ADR-011, `docs/design/HANDOFF.md` §5 (écran 7) et §9, `docs/design/brand/README.md`

## Besoin

TuneShell porte partout sa marque finale (demi-carapace et demi-haut-parleur, note au centre, menthe vers cyan sur fond nuit) au lieu de l'icône Flutter par défaut : sur le lanceur, dans la notification de lecture, au démarrage et dans l'écran d'accueil.

## Exigences

1. **Icône d'application adaptative.** Avant-plan, fond `#0D1528` (`brandNight`) et couche monochrome (icônes à thème d'Android 13 et plus) ; lisible dans les masques rond, carré arrondi et goutte. Le motif tient dans la zone sûre de 66 dp.
2. **Petites tailles.** La variante simplifiée (`app_icon_small_48dp`) sert aux tailles où les ondes fines disparaissent (liste d'applications, applications récentes) si le rendu de l'icône complète y est illisible.
3. **Icône de notification.** Silhouette blanche unie de 24 dp (`ic_notification`), référencée par la session média (FR-005) et par la future notification de parcours ; elle remplace l'icône actuelle sans toucher à `res/raw/keep.xml`.
4. **Écran de démarrage.** Fond de la marque et logo, sans animation obligatoire, qui reprend le thème clair ou sombre du système sans flash blanc ; il ne s'attarde pas : il disparaît dès que le premier écran est prêt (pas de durée minimale).
5. **Logo dans l'application.** Le logo dessiné en code (écran d'accueil, MPL-044) et l'icône ont le même dessin ; si les tracés finaux diffèrent de ceux du code, le code reprend les tracés finaux.
6. **Aucune dépendance ajoutée** si les ressources se font sans (voir À valider).
7. **Nom.** Libellé du lanceur : « TuneShell » (ADR-007), inchangé.

## Hors périmètre

Accessibilité et profilage (MPL-059), animation du logo, publication, licence des ressources de marque (ADR-011, avant publication), icônes de widgets, icône Android Auto autre que celle de l'application (MPL-060).

## À valider (PO)

- **Tracés finaux (réponse du 2026-10-28 : le propriétaire fournira de nouveaux fichiers ; MPL-049 attend ces fichiers, les SVG actuels ne sont pas utilisés).** Les fichiers de `docs/design/brand/` sont des maquettes « à finaliser » ; c'est toi qui valides le dessin final (je ne redessine pas la marque sans ton accord). Question : les SVG actuels servent-ils de base, ou fournis-tu de nouveaux fichiers ?
- **Format des sources (réponse du 2026-10-28 : le propriétaire n'aime pas le rendu vectoriel).** Les sources peuvent être des PNG de haute définition au rendu des images validées (dégradés, relief, lueur), pas seulement des SVG. Android accepte des PNG pour les trois couches de l'icône adaptative (avant-plan et monochrome en 432 × 432 px, transparents) ; seule l'icône de notification doit être une silhouette à un seul ton (canal alpha). Ressources écrites à la main, sans `flutter_launcher_icons` ni dépendance ; `minSdk` 30 rend inutiles les anciennes icônes PNG par défaut, qui seraient supprimées.
- **Écran de démarrage.** Proposé : API native d'Android 12 (`windowSplashScreenBackground`, icône sans animation), avec repli de `launch_background` sur Android 11 (`minSdk` 30) ; pas de paquet.

## As-built

MPL-049, 2026-10-28, test appareil partiel (D14). Sources : trois PNG de l'IA, choisis par le propriétaire (`docs/design/brand/`, voir son README). Icône adaptative : `mipmap-anydpi` (et `-v33` avec la couche monochrome), fond `@color/brand_night`, avant-plan et monochrome de 432 px dans `drawable-nodpi`, emblème de 264 px (66 dp) ; les icônes PNG par défaut sont supprimées. Notification : `ic_notification.png` en cinq densités, référencée par `androidNotificationIcon` et gardée par `res/raw/keep.xml`. Démarrage : `values-v31` et `values-night-v31` (fond nuit et emblème dans les deux thèmes), `launch_background.xml` avant Android 12. Logo de l'application : `assets/brand/emblem.png` affiché par `TuneShellLogo` (le dessin en code est supprimé). Test : `test/ui/widgets/tuneshell_logo_test.dart`. Protocole : `HOWTO.md` §22.

- Vu sur le Pixel 10 Pro (release) : icône du lanceur, petite icône de la carte multimédia du volet de notifications (silhouette de l'emblème). Non testé : icônes à thème, applications récentes, écran de démarrage (trop bref pour une capture sans arrêter la lecture en cours du propriétaire), écran d'accueil, écran verrouillé.
- Exigence 2 (variante petites tailles) : non faite ; Android n'a pas de variante par taille pour l'icône adaptative, l'image n°4 de l'IA (damier dessiné dans l'image) est écartée.
- Exigence 4 : le fond de l'écran de démarrage est le bleu nuit dans les deux thèmes (la marque), pas le thème du système ; l'application, elle, s'ouvre dans le thème choisi.
- L'emblème de l'application ne suit plus la couleur dynamique (Material You), contrairement à l'ancien dessin en code.
