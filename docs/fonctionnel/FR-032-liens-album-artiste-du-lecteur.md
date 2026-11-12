# FR-032 — Liens vers l'album et l'artiste depuis le lecteur plein écran

**Statut :** Active (validée le 2026-11-12) · **Créée le :** 2026-11-12 · **Tickets :** MPL-076 (liens), MPL-078 (voiture, exigence 7) · **Lié :** UC-007, UC-008, UC-012, FR-017, FR-020, FR-021, FR-029, BR-007, BR-010, BR-013, ADR-016, ADR-022 · **Source :** demande du propriétaire du 2026-11-10 ; pas de maquette (réalisé sans Claude Design si le propriétaire l'accepte)

## Besoin

Depuis la piste en cours, passer en un geste à son album ou à son artiste, pour enchaîner les titres sans retourner chercher dans les onglets.

## Exigences

1. **Liens.** Dans le lecteur plein écran, le nom de l'artiste et le nom de l'album de la ligne « artiste · album » (FR-017.4) sont deux zones tactiles distinctes. Un lien n'existe que si le groupe correspondant existe dans la bibliothèque (BR-010) ; sinon le texte reste simple. « Artiste inconnu » et l'album absent n'ont jamais de lien.
2. **Effet.** Toucher un lien réduit le lecteur (comme « Réduire », FR-017.1), bascule sur l'onglet Albums ou Artistes et ouvre le détail du groupe (FR-020.8, FR-021). Le détail se comporte alors comme s'il avait été ouvert depuis la grille : Retour ramène à la grille, sans retour au lecteur (voir À valider).
3. **Piste en cours visible.** Le détail ouvert met la piste en cours en surbrillance (FR-020.10) ; il n'interrompt pas la lecture.
4. **Disque absent.** Le lien reste actif pour un groupe grisé : le détail s'ouvre (FR-020.5).
5. **Accessibilité.** Zone tactile d'au moins 48 dp en hauteur ; libellés TalkBack « Ouvrir l'album {titre} » et « Ouvrir l'artiste {nom} » ; les liens se distinguent autrement que par la couleur (soulignement). Textes dans les fichiers ARB, en français et en anglais.
6. **Paysage et grand texte.** Les liens suivent la mise en page de FR-017.11 ; à 200 % le texte passe à la ligne sans couper une zone tactile.
7. **Voiture (partie B, à valider).** Android Auto dessine lui-même son lecteur : aucun lien n'y est possible. L'équivalent est à la racine de l'arbre média (BR-013.1) : deux dossiers « Album en cours » et « Artiste en cours », après « Reprendre », qui ouvrent le détail du groupe de la piste en cours ; absents sans piste courante ou sans groupe. Ils suivent la règle 3 à 6 de BR-013 (mêmes listes, absentes masquées, pagination) et ne sont pas jouables eux-mêmes.

## Hors périmètre

Liens depuis le mini-lecteur, la file d'attente ou les lignes de piste ; lien sur le genre ou l'année ; ouverture d'un artiste « invité » absent des groupes ; historique de navigation.

## À valider (PO)

- **Artiste cliqué (décidé : artiste de l’album ; aucun lien si l’artiste de la piste est inconnu).** Les groupes d'artistes suivent l'artiste de l'album (BR-010), alors que la ligne du lecteur affiche l'artiste de la piste. Les deux diffèrent pour un invité (« Artiste A feat. B »). Proposition : le lien ouvre le groupe de l'artiste de l'album de la piste ; si le texte affiché diffère, il n'y a quand même qu'un lien (pas de découpage des invités). Autre choix : pas de lien quand les deux diffèrent.
- **Retour.** Après le lien, Retour mène à la grille de l'onglet, pas au lecteur. Autre choix : rouvrir le lecteur au Retour (plus lourd, un état à garder).
- **Partie B (voiture).** Elle modifie BR-013 règle 1 et FR-029 (`Active`) : racine à cinq entrées au lieu de trois ou quatre. Peut devenir un ticket à part ou être abandonnée.
- **Fiches `Active` touchées.** FR-017.4, UC-007, UC-012, BR-013 règle 1 et FR-029 complétées le 2026-11-12 après la validation de cette fiche.
- **Signe visuel.** Le soulignement comme seul signe visuel est mon choix, sans maquette.

## As-built

MPL-076, 2026-11-12, test appareil en attente (D14). Réalisé comme décidé (ADR-022), avec ces précisions :

- `LibraryGroups.albumOf` et `artistOf` (`library_groups.dart`) retrouvent le groupe d'une piste par son identité interne, par une table faite à la première question ; pas de lien pour un album ou un artiste inconnu, ni pour une piste hors bibliothèque. L'artiste est celui de l'album (BR-010, règle 1).
- `TextLink` (`lib/ui/widgets/text_link.dart`) : texte souligné, zone tactile de 48 dp, libellé TalkBack, sémantique de lien. La ligne du lecteur est un `Wrap` : artiste, « · », album.
- `browseRequestProvider` (`app/providers/browse_request_providers.dart`) ; le lecteur écrit la demande puis se réduit (`maybePop`). `HomeShell` reçoit `request`, `onRequestHandled` et `detailBuilder` (câblés dans `app/app.dart`), change d'onglet, vide le navigateur de l'onglet jusqu'à sa grille et pousse le détail.
- Voiture : `LibraryMediaTree` ajoute `current|album` et `current|artist` après « Reprendre » (libellés `carCurrentAlbum` et `carCurrentArtist`, sous-titre = titre ou nom du groupe). Leurs enfants sont ceux du groupe réel : les pistes gardent l'identifiant du groupe et se jouent en file d'album (BR-013, règle 5). Même icône d'onglet et même image de repli que Albums et Artistes dans `PlayerAudioHandler`.
- Écart : la ligne « artiste · album » n'est plus un seul texte pour les tests (`find.text('Mists')` et `find.text('Shore')`).
- Tests : `library_groups_test.dart` (groupes d'une piste), `home_shell_test.dart` (demande), `player_flow_test.dart` (liens), `library_media_tree_test.dart` et `player_audio_handler_test.dart` (voiture).
