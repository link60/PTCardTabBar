# Docs — board Kanban des chantiers

Cartes de chantier et documents de référence du fork `PTCardTabBar`, rangés par statut façon Kanban.

> **Le dossier d'une carte EST son statut.** On déplace le fichier de colonne en colonne quand le
> statut change (`git mv`), et on recale les liens relatifs — ils cassent dès que la profondeur
> change.
>
> Les **en-têtes internes** des cartes peuvent être périmés (rédigés au démarrage du chantier).
> La colonne dans laquelle vit le fichier fait foi.

## Colonnes

| Dossier | Statut | Index |
|---|---|---|
| [`backlog/`](backlog) | à démarrer, ventilé par urgence | [index par urgence](backlog/README.md) |
| [`in-progress/`](in-progress) | en cours | — |
| [`done/`](done) | livré | — |
| [`reference/`](reference) | socle documentaire, **hors flux Kanban** | — |

Dans `backlog/`, l'urgence est portée par le **sous-dossier** — `high/`, `medium/`, `low/`,
`to-define/` — jamais par le contenu de la carte. Changer d'urgence = déplacer le fichier entre
sous-dossiers, à profondeur égale, donc sans aucun lien à recaler.

**Audit ≠ carte.** Un audit décrit l'état du code **à une date**, et ne bouge plus : il vit dans
`reference/`. Le chantier qui en découle est une carte de `backlog/`, qui référence l'audit et porte
seule l'avancement. On ne réécrit pas l'audit au fil des correctifs — sinon on perd le point de
départ.

## État du board

### `backlog/` — à démarrer

- [`PTCARDTABBAR_CORRECTIFS.md`](backlog/high/PTCARDTABBAR_CORRECTIFS.md) — `high` / `L`,
  **ouverte le 2026-09-18**, chantier **lotti en 7 lots**, rien de démarré. Remise en état du pod à
  partir de l'audit du même jour : quatre défauts mesurés sur simulateur iOS 27 (cycle de rétention,
  bouton désactivé actionnable, surlignage d'onglet désynchronisé, course `hide`/`show`), puis
  nettoyage d'API et accessibilité. Le **Lot 0** remet en route le banc de validation, sans lequel
  tout se testerait dans DateLimite.

### `in-progress/` — en cours

*(vide)*

### `done/` — livré

*(vide)*

### `reference/` — transverse, pas une colonne de statut

- [`PTCARDTABBAR_AUDIT.md`](reference/PTCARDTABBAR_AUDIT.md) — **audit global du 2026-09-18** sur
  `HEAD = de21149`, vérifié sur pièces (simulateur iPhone 17 / iOS 27, sonde `@available` au
  compilateur, en-têtes du SDK). Quatre constats en gravité élevée **mesurés**, sept moyens, quinze
  d'hygiène, chacun avec fichier, ligne, niveau de preuve et correctif proposé. Notables : le
  `delegate` fort qui empêche toute désallocation (prouvé en A/B), les **deux surcharges
  `select(at:)`** aux sémantiques opposées dont la résolution a été établie au compilateur, et
  l'override non signalé de l'API UIKit `setTabBarHidden(_:animated:)` d'iOS 18. Un seul point reste
  **supposé** : le forçage de la classe de taille compacte sur iPad. Document **figé** — l'avancement
  se suit sur la carte de chantier.

## Déploiement — à ne pas oublier

`Pods/` est gitignoré côté DateLimite : un correctif ne prend effet qu'une fois **poussé sur la
branche `badge`** de ce fork, puis récupéré par `pod update PTCardTabBar`. Le `Podfile.lock` de
l'app épingle un SHA, et comme `s.version` du podspec ne bouge jamais, c'est bien ce SHA qui fait
foi — pas le numéro de version.
