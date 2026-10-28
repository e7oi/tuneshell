# BR-012 — Reprise de la lecture : ce qui est enregistré, quand, et comment c'est restauré

**Statut :** Active (validée le 2026-10-28) · **Créée le :** 2026-10-28 · **Ticket :** MPL-053 · **Lié :** UC-011, FR-001, FR-005, FR-028, BR-001, BR-003, BR-004, BR-009, ADR-019

## Règle

La **session de lecture** est ce qu'il faut pour retrouver la musique : la file dans son ordre, la piste courante, la position, l'aléatoire et la répétition. Elle est enregistrée sur l'appareil (aucun réseau, D15, D26) et restaurée au lancement suivant.

1. **Contenu.** La file (chaque entrée est une piste identifiée par disque et chemin relatif, BR-004 règle 1 ; une piste peut y figurer plusieurs fois), l'index de la piste courante, la position dans cette piste, l'état de l'aléatoire, la répétition (désactivée, toutes, une piste) et, si l'aléatoire est actif, l'ordre d'origine de la file (BR-009 règle 2). Ni la provenance de la file (« Album · … »), ni l'intention de lire, ni la durée : voir À valider.
2. **Quand elle est enregistrée.** À chaque changement de la file (nouvelle file, retrait, déplacement, ajout, « lire ensuite », vider la suite, aléatoire) et de la piste courante ; à la mise en pause, à l'arrêt, quand l'application passe en arrière-plan et quand elle est retirée des applications récentes ; et, pendant la lecture, toutes les 10 secondes au plus pour la position. Les écritures sont regroupées : jamais une écriture de toute la file à chaque tic de position.
3. **Perte acceptée.** Si le processus meurt en pleine lecture sans prévenir, la position retrouvée peut retarder de 10 secondes au plus. La file et la piste, elles, sont à jour.
4. **File vide.** Quand la file devient vide, la session enregistrée est effacée.
5. **Quand elle est restaurée.** Une seule fois par lancement, après que le contrôleur est démarré et que la bibliothèque est lue depuis la base. La restauration ne bloque pas le premier écran. Elle n'a lieu que si l'utilisateur n'a pas déjà mis une file en place : dès qu'une file existe, la session enregistrée est ignorée, puis remplacée par la nouvelle.
6. **État restauré : en pause, rien de chargé.** Le contrôleur est dans l'état « arrêté » (FR-001) avec la file, la piste courante, la position et les modes ; l'intention de lire est fausse. Le moteur n'ouvre aucun fichier, le service au premier plan n'est pas démarré et aucune notification n'est montrée (FR-005 : tant qu'il n'y a pas de « Lecture »). Aucune lecture ne démarre toute seule.
7. **Premier « Lecture ».** La piste courante est chargée par le chemin habituel (BR-001, BR-003) puis placée à la position enregistrée ; si la position dépasse la durée de la piste ou si le moteur refuse de s'y placer, la piste repart du début, sans message. Les commandes « suivant », « précédent » et « aller à une piste » avant ce premier « Lecture » partent du début de la piste visée.
8. **Pistes disparues (BR-004).** À la restauration, chaque entrée est cherchée dans la bibliothèque par (disque, chemin relatif). Une entrée absente de la bibliothèque est retirée de la file, y compris de l'ordre d'origine. Une piste déplacée ou renommée est une autre piste (BR-004 règle 3) : l'ancienne entrée disparaît, la nouvelle n'est pas devinée.
9. **Piste courante disparue.** La piste courante devient la première entrée restante qui la suivait, à la position zéro. S'il n'en reste aucune après elle, la dernière entrée restante avant elle ; s'il ne reste rien, rien n'est restauré et la session est effacée.
10. **Disque absent.** Une entrée dont le disque est dans la bibliothèque mais absent (BR-001, BR-008) est gardée : elle revient grisée, et la lecture la saute avec le signalement habituel. Un disque retiré de la bibliothèque n'a plus de pistes : règle 8.
11. **Données abîmées ou d'une version inconnue.** Une session illisible ou incohérente (index hors de la file, répétition inconnue) est ignorée et effacée, sans message ni plantage ; au pire, l'application démarre comme avant.
12. **Réglage désactivé.** Aucune session n'est enregistrée ni restaurée, et celle qui existe est effacée au moment où le réglage est désactivé. Réactivé, l'enregistrement reprend avec la file du moment.
13. **Confidentialité.** La session contient des chemins de fichiers : elle reste dans la base de l'appareil, n'est jamais journalisée en clair, et n'entre ni dans le dépôt ni dans les journaux d'essai (D27).

## Cas limites

- Fin de file atteinte avant la fermeture : la file est conservée (FR-001 règle 5), la piste courante est la dernière, position zéro.
- Même piste présente deux fois : chaque entrée garde sa place.
- Bibliothèque pas encore lue (premier lancement après une mise à jour, base vide) : rien n'est restauré et la session enregistrée est gardée telle quelle.
- Une indexation au démarrage retire plus tard une piste de la file restaurée : même comportement qu'aujourd'hui, la piste échoue à l'ouverture et la lecture passe à la suivante (BR-003).
- Répétition « une piste » et aléatoire restent actifs après la restauration.
- La restauration avec une file de 7 500 pistes ne doit pas retarder le premier écran (mesure sur le Pixel, ADR-019).

## À valider (PO)

- **Écart à BR-009 (`Active`)** : « les modes ne sont pas conservés entre deux lancements ». Cette fiche les conserve (règle 1). BR-009 n'est pas modifiée ; la phrase sera mise à jour à la livraison si le propriétaire valide.
- **Écart à FR-001 (`Active`)** : « persistance de la file après redémarrage » était hors périmètre, et **à FR-005** : « reprise de la file après un redémarrage de l'application » aussi. Cette fiche les lève ; as-built ajouté à la livraison, règles inchangées.
- Règle 1 : la provenance de la file (« Album · … ») n'est pas conservée ; après restauration le lecteur n'affiche pas de provenance. Autre choix : l'enregistrer.
- Règle 1 : l'intention de lire n'est pas conservée, même si la musique jouait au moment de la fermeture : l'application n'envoie jamais de son toute seule. Autre choix : reprendre en lecture quand l'application s'est arrêtée en jouant (refusé par défaut : surprise au casque, au volant).
- Règle 2 : 10 s de position perdue au pire (choix de moi).
- Règle 9 : la piste courante disparue est remplacée par la suivante restante au début.
- Règle 7 : position hors durée ou placement refusé par le moteur : début de piste, sans message.

## As-built

MPL-053, 2026-10-28, test appareil non fait (D14). Modèle `PlaybackSession` (`lib/domain/playback/model/playback_session.dart` : `isValid`, `keeping`), port `PlaybackSessionStore`, `SessionKeeper` (`lib/domain/playback/services/session_keeper.dart`), `PlayerController.session` et `restore`, `restorePlaybackSession` (`lib/app/session_restore.dart`), câblage `startSessionKeeping` (`lib/app/session_keeping.dart`, appelé par `main` après `startSystemPlayback`), adaptateur `DriftPlaybackSessionStore`. Tests : `playback_session_test`, `player_controller_restore_test`, `session_keeper_test`, `drift_playback_session_store_test`, `session_restore_test`, `session_keeping_test`.

- Écriture (règle 2) : la file et l'avancement sont écrits 1 s après le dernier changement ; la position seule, 10 s au plus pendant la lecture ; tout de suite à la pause, à l'arrêt d'une piste chargée et quand l'application passe en arrière-plan (`AppLifecycleListener.onPause`). Pas d'écriture supplémentaire au retrait des récentes : la position a déjà été écrite à la pause et l'arrêt ne la change pas.
- Une session restaurée sans entrée retirée n'est pas réécrite (`SessionKeeper.adopt`) ; si des entrées ont été retirées, la file nettoyée est écrite.
- Position (règle 7) : `PlayerController` la garde dans `_resumeAt` jusqu'au premier « Lecture » (ou jusqu'à toute autre commande ou nouvelle file) ; elle est donnée au moteur par un `seek` juste après l'`open`. Si la durée arrive plus petite que la position, la piste revient au début. Un `seek` refusé par le moteur laisse la piste au début, sans message.
- L'ordre d'origine de l'aléatoire est enregistré (colonne `origin_position`) ; la désactivation de l'aléatoire après un redémarrage rend l'ordre d'origine.
- Une session sans aucune piste connue de la bibliothèque est effacée ; une bibliothèque vide à la lecture laisse la session enregistrée.
- Le mini-lecteur et le lecteur affichent la durée de la bibliothèque tant que le moteur n'en a pas donné (`shownDurationProvider`), pour que la progression soit visible avant le premier « Lecture » ; le curseur du lecteur reste inactif tant que le moteur ne connaît pas la durée.
- Écarts levés, validés par le propriétaire le 2026-10-28 : BR-009 (modes entre deux lancements), FR-001 et FR-005 (persistance de la file hors périmètre) ; leurs règles ne changent pas.
- À vérifier sur le Pixel (HOWTO §21) : `seek` juste après `open` avec `media_kit`, temps d'écriture et de lecture de 7 500 pistes, enregistrement au retrait des récentes en pause.
