# UC-012 — Écouter sa musique dans la voiture avec Android Auto

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-060 · **Épique :** MPL-005 · **Décisions :** D6, D12, D15 · **Lié :** UC-002, UC-011, FR-005, FR-029, BR-001, BR-002, BR-013, ADR-020 · **Source :** PRD phase 3, demande du propriétaire du 2026-10-28

## Acteur et but

L'utilisateur branche son Pixel à la voiture. Il veut choisir et lancer sa musique TuneShell depuis l'écran de la voiture ou aux commandes du volant, sans toucher au téléphone, et l'entendre sans coupure quand l'écran du téléphone est éteint.

## Préconditions

- La musique est déjà indexée (UC-001, UC-003) ; TuneShell n'indexe pas depuis la voiture.
- Android Auto est installé et la voiture (ou l'émulateur) connectée. TuneShell n'étant pas distribuée par le Play Store, l'option « Sources inconnues » des réglages développeur d'Android Auto est activée (D6).

## Scénario nominal

1. Le téléphone se connecte à la voiture ; TuneShell apparaît dans les applications multimédia d'Android Auto.
2. L'écran de la voiture propose de reprendre la dernière lecture (UC-011) et de parcourir Albums, Artistes et Pistes (FR-029).
3. L'utilisateur choisit un album, un artiste ou une piste ; la lecture démarre et la file est celle du groupe choisi (BR-013).
4. Les commandes de la voiture (lecture, pause, précédent, suivant, position) pilotent la même lecture que la notification du téléphone (FR-005).

## Variantes et erreurs

- **Application jamais ouverte depuis le démarrage du téléphone** : la navigation fonctionne quand même (ADR-020).
- **Bibliothèque vide** : un élément explique d'ouvrir TuneShell sur le téléphone (BR-013).
- **Disque amovible absent ou éjecté** : ses pistes n'apparaissent pas ; l'éjection pendant la lecture suit BR-002.
- **Piste illisible** : saut ou message comme sur le téléphone (BR-003).
- **Appel téléphonique, navigation vocale** : interruptions de BR-005, inchangées.

## Hors périmètre

Recherche et commandes vocales (« Joue … »), Android Automotive OS, Apple CarPlay, écrans de lecture personnalisés (Android Auto impose ses gabarits), indexation ou réglages depuis la voiture, publication sur le Play Store.
