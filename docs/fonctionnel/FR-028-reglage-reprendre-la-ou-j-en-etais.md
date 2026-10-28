# FR-028 — Réglage « Reprendre là où j'en étais » et affichage de la lecture restaurée

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-053 · **Décisions :** D15, D30 · **Lié :** UC-011, UC-009, FR-005, FR-016, FR-017, FR-018, FR-023, FR-025, BR-007, BR-012, ADR-017, ADR-019 · **Source :** `docs/design/HANDOFF.md` §5 (écran 8, 8e), `Reglages.dc.html`

## Besoin

Choisir si la musique est retrouvée au lancement, et voir clairement que ce qui est affiché est une lecture en pause, restaurée.

## Exigences

1. **Une ligne dans « Lecture ».** La section « Lecture » de Réglages (FR-023.1) reçoit un interrupteur « Reprendre là où j'en étais » avec le sous-titre de la maquette. Zone tactile d'au moins 48 dp, libellé, sous-titre et état annoncés par TalkBack (FR-023.10). La ligne n'était pas montrée tant que son effet n'était pas livré (FR-023.2) : elle l'est avec ce ticket.
2. **Par défaut : activé** (choix proposé, voir À valider). La valeur est conservée d'un lancement à l'autre (FR-023.5) sous une clé de réglage de plus ; une valeur illisible donne l'activé (FR-023.7).
3. **Désactiver** efface la session enregistrée aussitôt et arrête d'en enregistrer ; la file en cours continue de jouer sans changement. **Activer** reprend l'enregistrement avec la file du moment (BR-012 règle 12).
4. **Après la restauration.** Le mini-lecteur (FR-016) montre la piste courante, sa pochette et sa progression à la position enregistrée, avec le bouton « Lecture » et non « Pause » ; le lecteur plein écran (FR-017) et la file (FR-018) montrent la file restaurée, la piste courante en tête et les modes aléatoire et répétition tels qu'avant. Aucune provenance de file n'est affichée (BR-012 règle 1).
5. **Pas de signalement.** Une restauration réussie ne montre ni message ni bandeau. Les pistes d'un disque absent sont grisées et signalées au moment de la lecture, comme toujours (BR-001, BR-008). Une session illisible est ignorée sans message (BR-012 règle 11).
6. **Pas de notification avant « Lecture ».** La session média n'est pas créée par la restauration (FR-005).
7. **Pas de clignotement.** Le mini-lecteur n'apparaît qu'une fois la file restaurée, en une seule fois ; il ne montre pas un instant une file partielle.
8. **Textes.** Libellé et sous-titre de la maquette dans les fichiers ARB, avec la version anglaise (BR-007).

## Hors périmètre

Un réglage séparé pour les modes, la position ou la reprise automatique de la lecture, un historique de files, la restauration de l'écran affiché.

## À valider (PO)

- **Écart à FR-023 (`Active`)** : exigence 2 (« les deux réglages de la maquette qui n'ont pas d'effet encore sont retirés ») et structure de la section « Lecture » ; la ligne s'ajoute avec ce ticket sans changer les règles de FR-023.
- Exigence 2 : activé par défaut. Autre choix : désactivé, l'utilisateur l'active (la maquette ne dit pas la valeur par défaut).
- Exigence 4 : pas de provenance après restauration.

## As-built

MPL-053, 2026-10-28, test appareil non fait (D14). Interrupteur dans la section « Lecture » (`lib/features/settings/settings_page.dart`), clé `resume_playback` (`SettingKey.resumePlayback`, `AppSettings.resumePlayback`, activé par défaut), `AppSettingsNotifier.setResumePlayback`. `startSessionKeeping` suit le réglage : désactivé, la session enregistrée est effacée et plus rien n'est écrit ; activé, la file du moment est écrite. Textes de la maquette (« Reprendre là où j'en étais », « Restaure la file d'attente au démarrage ») dans les ARB. Tests : `settings_page_test`, `app_settings_test`, `settings_providers_test`, `session_keeping_test`, `player_flow_test` (groupe « a restored session »).

- Exigence 7 (pas de clignotement) : la restauration lit la base derrière le premier écran ; le mini-lecteur apparaît d'un coup à la fin. Délai à mesurer sur le Pixel avec 7 500 pistes.
- Écart levé, validé le 2026-10-28 : la ligne s'ajoute à FR-023 (exigence 2) sans changer ses règles.
