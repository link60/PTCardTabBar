# Backlog — index par urgence

> Kanban par dossiers : **le dossier d'une carte EST son statut**.
> `backlog/<urgence>/` (planifié) → [`../in-progress/`](../in-progress) (en cours) →
> [`../done/`](../done) (livré).
> Au démarrage / à la clôture d'un chantier, la carte **change de dossier** (`git mv` + recalage des
> liens relatifs, qui cassent avec la profondeur).
>
> L'urgence est portée par le sous-dossier — `high/`, `medium/`, `low/`, `to-define/` — pas par le
> contenu de la carte. Changer d'urgence = déplacer le fichier entre sous-dossiers (même profondeur,
> donc aucun lien à recaler). Un sous-dossier vide veut dire « rien à ce niveau », pas « oublié ».
>
> Les **audits** ne sont pas des cartes : ils vivent dans [`../reference/`](../reference) et sont
> **figés** à leur date. Une carte de chantier les référence et porte seule l'avancement.

---

## `high/` — à dépiler en premier

- [`PTCARDTABBAR_CORRECTIFS.md`](high/PTCARDTABBAR_CORRECTIFS.md) — `L` / élevée,
  **ouverte le 2026-09-18**, chantier **lotti en 7 lots**, rien de démarré. Remise en état du fork à
  partir de l'audit [`PTCARDTABBAR_AUDIT.md`](../reference/PTCARDTABBAR_AUDIT.md) du même jour.
  Quatre défauts **mesurés sur simulateur iOS 27**, dont deux atteignent DateLimite en production :
  cycle de rétention du `delegate` (**E1** — le contrôleur n'est jamais désalloué ; aggravé par le
  multi-fenêtres iPad, chaque fenêtre fermée fuit l'arbre complet), bouton `isEnabled = false` qui
  reste actionnable (**E2** — la cloche grisée de la fiche produit ouvre quand même le flux),
  surlignage d'onglet qui saute après une sélection programmatique (**E3** — visible après un push
  recette), et course `hideTabBar` / `showTabBar` laissant la barre opaque mais masquée (**E4**).
  - **Lot 0 d'abord** — l'exemple du pod ne démarre plus sous iOS 27 (`BadgeHub` figé à iOS 10,
    et cycle de vie `UIScene` non adopté) : sans banc, tout se testerait dans DateLimite. C'est le
    vrai bloquant.
  - **Deux correctifs déjà éprouvés** pendant l'audit puis défaits avec la restauration de l'arbre :
    la remise en route du banc et le `if finished` d'**E4**. À réécrire, validité établie.
  - **Lot 3 le plus délicat** — il touche le chemin nominal de sélection, et désamorce au passage
    une mine côté app : ce qui empêche aujourd'hui `DetailProductHelper.configure()` de fermer la
    fiche produit à son ouverture est **uniquement l'ordre de deux lignes**.
  - **Lot 5** (accessibilité) permettrait de retirer le contournement `-SnapshotInitialTab` des
    tests UI de DateLimite.
  - `F10` (mélange frame / Auto Layout dans le layout interne) est **hors périmètre** : dette
    assumée, pas planifiée.

## `medium/` — quand la place se libère

*(vide)*

## `low/` — quand tout le reste est fait

*(vide)*

## `to-define/` — cadrage requis avant toute estimation

*(vide)*
