# FR-026 — À propos et Confidentialité

**Statut :** Brouillon · **Créée le :** 2026-10-25 · **Ticket :** MPL-051 · **Décisions :** D1, D15, D26 · **Lié :** UC-009, FR-023, BR-007, ADR-011, ADR-017 · **Source :** `docs/design/HANDOFF.md` §5 (8e), §9

## Besoin

Dire ce qu'est l'application : sa version, sa licence libre, d'où vient son code, et ce qu'elle fait ou ne fait pas des données de l'utilisateur.

## Exigences

1. **Ligne « TuneShell {version} »** (navigation), sous-titre « Libre · GPL-3.0-or-later · code source ». La version est celle de `pubspec.yaml` (0.1.0 aujourd'hui) ; la licence est GPL-3.0-or-later (D1), à la place du « [LICENCE À PRÉCISER] » de la maquette.
2. **Page À propos.** Nom, version, « © 2026 Eloi BERTIN », licence GPL-3.0-or-later avec la phrase de garantie courte de la licence, l'adresse du dépôt de code source en texte que l'on peut sélectionner (aucun lien : l'application n'ouvre pas de page web, D15), et une ligne « Licences » qui ouvre la page des licences de Flutter : licences des paquets, des polices (OFL) et celle de l'application.
3. **Ligne « Confidentialité »** (navigation), sous-titre « Aucune donnée collectée, aucun compte, aucun réseau ».
4. **Page Confidentialité.** Courte, en phrases simples : aucune donnée n'est envoyée nulle part ; il n'y a ni compte, ni publicité, ni statistiques, ni connexion au réseau (la version courante n'a pas la permission Internet, D15, D26) ; ce qui reste sur le téléphone (la liste des pistes lues dans les fichiers, les pochettes réduites, les réglages) et disparaît avec les données de l'application ; ce que l'application demande à Android et pourquoi (lire les fichiers audio, afficher la notification de lecture, accéder au dossier d'un disque que l'on a choisi).
5. **Version juste.** La version affichée ne peut pas différer de celle du `pubspec.yaml` : un test les compare.
6. **Accessibilité et règles d'interface.** Pages en texte défilant, lisibles à tout niveau de texte ; jetons ; clair et sombre (BR-007).
7. **Textes** dans les fichiers ARB, en français et en anglais ; les licences de tiers restent dans leur langue.

## Hors périmètre

Lien web ouvrable, « noter l'application », journal des modifications dans l'application, mentions légales de publication (D5, D6), licence des ressources de marque (ADR-011).

## À valider (PO)

- Exigence 2 : l'adresse du code source n'est pas un lien (pas de dépendance ni de code natif pour ouvrir un navigateur) ; une ouverture par `url_launcher` ou une intention native reste possible plus tard.
- Exigence 4 : le texte de la page Confidentialité est de moi ; la conception ne donne que le sous-titre.
- Exigence 1 : « Libre · GPL-3.0-or-later · code source » est le sous-titre de la maquette avec la licence qu'elle laissait à préciser.
- `HANDOFF.md` §9 : la licence des ressources de marque (logo, icônes) reste à trancher avant publication ; elle n'est pas dite dans cette page.

## As-built

À écrire à la livraison.
