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

*(vide)* — `PTCARDTABBAR_CORRECTIFS.md` en est sorti le 2026-09-18 : il est passé **en cours** →
[`../in-progress/PTCARDTABBAR_CORRECTIFS.md`](../in-progress/PTCARDTABBAR_CORRECTIFS.md).

## `medium/` — quand la place se libère

*(vide)*

## `low/` — quand tout le reste est fait

*(vide)*

## `to-define/` — cadrage requis avant toute estimation

*(vide)*
