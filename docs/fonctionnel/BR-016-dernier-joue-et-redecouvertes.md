# BR-016 — Dernier joué et redécouvertes de l'accueil

**Statut :** Active (validée le 2026-11-13) · **Créée le :** 2026-11-13 · **Ticket :** MPL-079 · **Décisions :** D15, D23, D27 · **Lié :** UC-014, FR-033, BR-001, BR-004, BR-008, BR-010, BR-012, BR-014, ADR-024

## Règle

L'accueil montre **la dernière piste jouée** et **des albums à redécouvrir**. Tout se calcule sur l'appareil, à partir de la bibliothèque et de l'historique existants (BR-014) ; rien n'est envoyé (D15, D26) et rien de nouveau n'est enregistré, hors le tirage gardé en mémoire (règle 8).

### Dernier joué

1. **Source.** La piste courante du contrôleur, vivante ou restaurée (BR-012) ; à défaut, la dernière écoute de l'historique (BR-014 règle 6) dont la piste est dans la bibliothèque (les écoutes de fichiers disparus sont sautées, BR-014 règle 2). Sans l'une ni l'autre, pas de carte.
2. **Album et artiste.** Ceux de la piste, retrouvés comme pour les liens du lecteur (BR-010 règle 1, FR-032 : l'artiste est celui de l'album). Album ou artiste inconnu : pas de lien, jamais.
3. **Historique désactivé.** La règle 1 reste valable : la piste courante prime ; l'historique déjà enregistré est encore lu (BR-014 règle 7), l'effacer retire la source de repli.
4. **Disque absent.** La carte est grisée, la lecture donne le message habituel (BR-001, BR-008).

### Redécouvertes

5. **Unité : l'album** (groupe de BR-010). Une piste sans album n'est jamais tirée.
6. **Éligible.** L'album a au moins une piste jouable (disque disponible, BR-001), aucune de ses pistes n'a été écoutée depuis 30 jours (« jamais écouté » compte), et ce n'est pas l'album de la piste du « Reprendre ».
7. **Priorité et tirage.** Niveau 1 : les albums éligibles dont une piste a une écoute plus ancienne que 30 jours ou est en favori. Niveau 2 : les autres éligibles. Six albums au plus : tirés au hasard (loi uniforme) dans le niveau 1, complétés au hasard dans le niveau 2 s'il en manque. Un album n'apparaît qu'une fois. Moins de six éligibles : tous ; zéro : section absente. (Le niveau 2 évite une section vide : l'historique n'existe que depuis la livraison de MPL-065 et beaucoup d'albums n'ont jamais été écoutés.)
8. **Quand le tirage change.** Le tirage est fait au premier affichage de l'accueil après le démarrage de l'application, puis gardé en mémoire : changer d'onglet, tourner l'écran, revenir du lecteur, finir une piste ou réindexer ne le changent pas. Il ne change que sur action de l'utilisateur (« Autres suggestions »), qui évite si possible les albums déjà affichés. Il n'est pas enregistré : aucune garantie d'albums différents d'un démarrage à l'autre.
9. **Pendant la session.** Un album qui quitte la bibliothèque est retiré de la grille sans remplaçant ; un album dont le disque devient absent reste, grisé, son détail s'ouvre (FR-020 exigence 5).
10. **Pas d'aléa non testable.** Le hasard et l'horloge sont injectés dans le calcul (test d'abord, sélection reproductible).
11. **Données privées.** Aucun titre, nom ni identité dans les journaux ni le dépôt (D27, BR-014 règle 9).
12. **Hors voiture.** Android Auto ne montre pas l'accueil (BR-013 règle 2 reste).

## Cas limites

- Bibliothèque vide : ni carte ni grille, état vide (FR-033).
- Un seul album dans la bibliothèque, et c'est celui de la piste courante : pas de redécouverte.
- Piste courante restaurée sur un disque absent : carte grisée (règle 4) ; ses albums ne sont pas tirés (règle 6).
- Heure de l'appareil changée en arrière : une écoute « dans le futur » compte comme récente ; pas de correction.

## À valider (PO)

- **Redécouvertes = albums**, six au plus. Autre choix : des pistes (plus fines, mais sans pochette ni détail à ouvrir).
- **Seuils** : 30 jours sans écoute (règle 6), six albums (règle 7), favoris comme signal de niveau 1.
- **Niveau 2 = albums jamais écoutés** : c'est une découverte plus qu'une redécouverte ; accepté pour ne pas laisser la section vide les premières semaines. Autre choix : la section reste vide (ou absente) tant qu'aucune écoute n'a 30 jours.
- **Règle 8 : « à chaque affichage de l'accueil »** (demande d'origine) est reformulé en « à chaque démarrage, plus action explicite ». Un tirage à chaque retour sur l'onglet changerait la grille sous les doigts de l'utilisateur (il revient de l'album qu'il vient d'ouvrir et ne la retrouve pas). Autre choix : nouveau tirage à chaque retour sur l'onglet après N minutes ; à décider.
- **Écart à BR-012 : aucun.** La carte « Reprendre » n'allume jamais le son seule.
