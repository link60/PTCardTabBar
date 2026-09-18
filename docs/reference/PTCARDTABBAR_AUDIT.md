# Audit global du pod — fork `link60`, branche `badge`

> **Document de référence — hors flux Kanban.** Diagnostic figé au **2026-09-18** sur
> `HEAD = de21149`, conservé tel quel : il décrit l'état du code **avant tout correctif**. Ne pas le
> réécrire au fil des corrections — c'est la carte de chantier qui porte l'avancement.
>
> **Chantier associé :** [`PTCARDTABBAR_CORRECTIFS.md`](../in-progress/PTCARDTABBAR_CORRECTIFS.md)
> (`in-progress`) — c'est là que se suit le dev, lot par lot. Chaque lot y renvoie aux constats
> `E*` / `M*` / `F*` numérotés ci-dessous, qui servent d'identifiants stables.
>
> **Périmètre :** [`PTCardTabBar/Classes/**`](../../PTCardTabBar/Classes).
> **Consommateur :** DateLimite (`/Users/loicsence/Developer/iOS/datelimite`), via
> `pod 'PTCardTabBar', git: …, branch: 'badge'`.

> **Hors sujet volontaire.** Le défaut de réagencement iOS 26/27 documenté dans
> `docs/in-progress/REFLOW_LAYOUT_IOS26.md` côté DateLimite n'est **pas** traité ici : il a été
> écarté par la mesure (`inheritedAnimationDuration = 0`) et la cause était un `reloadData()`
> côté app. Aucun constat ci-dessous ne prétend l'expliquer.

## Méthode

Trois niveaux de preuve, distingués partout dans le rapport :

| Marqueur | Signification |
|---|---|
| **Mesuré** | Observé au runtime sur simulateur iPhone 17 / iOS 27 (`CB5E2618…`), log à l'appui |
| **Prouvé par le compilateur / le SDK** | Diagnostic Swift ou en-tête UIKit du SDK iOS 27 installé |
| **Prouvé par lecture** | Sémantique du langage ou de UIKit sans ambiguïté, mais non exécuté |
| **Supposé** | Hypothèse de lecture, reste à confirmer |

Banc de mesure : app d'exemple du pod, instrumentée temporairement (arbre de travail **restauré**,
`git status` propre). Deux obstacles ont dû être levés pour la faire tourner — ils constituent
eux-mêmes un constat, cf. **F13**.

---

## Gravité élevée

### E5 — `PTCardTabBarController()` par code plante — *ajouté le 2026-09-18 (Lot 1)*

**Où :** [PTCardTabBarController.swift:108](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L108)
— `customTabBar.items = tabBar.items!`.

Ce forçage était signalé dans l'audit initial comme un **risque** au conditionnel. Il est en fait
**atteint dès l'init** : `UITabBarController.init(nibName:bundle:)` charge sa vue immédiatement,
donc `viewDidLoad` s'exécute **avant** que l'appelant ait pu poser `viewControllers`. `tabBar.items`
est alors `nil` et le forçage trappe.

**Mesuré**, découvert en recettant le Lot 1 — un simple `PTCardTabBarController()` suffit :

```
EXC_BREAKPOINT (SIGTRAP)
  libswiftCore  _assertionFailure(_:_:file:line:flags:)
  PTCardTabBar  PTCardTabBarController.viewDidLoad()
  UIKitCore     -[UITabBarController initWithNibName:bundle:]
```

Seules les sous-classes qui posent `viewControllers` **avant** d'appeler `super.viewDidLoad()` y
échappent — c'est exactement ce que fait `PTTabBarViewController` dans l'exemple, ce qui masquait le
défaut. DateLimite y échappe aussi : il instancie depuis un storyboard, où les segues de relation
peuplent `viewControllers` au décodage.

**Corrigé au Lot 1** : `tabBar.items ?? []`, plus une garde dans `select(at:)` qui ne notifie pas le
delegate quand aucun bouton ne correspond — sans quoi la correction déplaçait simplement le trap.

### E1 — `delegate` fort + protocole non class-bound : cycle de rétention

**Où :** [PTCardTabBar.swift:11](../../PTCardTabBar/Classes/PTCardTabBar.swift#L11) (`public protocol CardTabBarDelegate {`),
[:24](../../PTCardTabBar/Classes/PTCardTabBar.swift#L24) (`public var delegate: CardTabBarDelegate?`),
[PTCardTabBarController.swift:27](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L27) (`open lazy var customTabBar`),
[:146](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L146) (`customTabBar.delegate = self`).

Le contrôleur retient fortement la barre ; la barre retient fortement son delegate ; le delegate
est le contrôleur. `PTCardTabBarController` ne peut jamais être désalloué.

**Mesuré (A/B).** Exemple présenté puis `dismiss` :

```
sans correctif : aucun `deinit`
avec `protocol CardTabBarDelegate: AnyObject` + `public weak var delegate` :
  09:35:07.511  AUDIT >>> deinit PTTabBarViewController
```

**Impact réel sur DateLimite.** `UIApplicationSupportsMultipleScenes = true`
(`DateLimite/DateLimite-Info.plist`) et **un contrôleur instancié par scène**
(`Date_LimiteSceneDelegate.swift:492` pour iPad, `:516` pour iPhone). Chaque fenêtre principale
fermée sur iPad fuit l'arbre complet : 3 `UINavigationController`, leurs contrôleurs, collections
et données. En mono-fenêtre l'impact se réduit à un objet permanent, donc négligeable — c'est le
multi-fenêtres iPad qui fait la gravité.

À noter : côté app, `ProductTabBarManager` **contourne déjà** le problème (`private weak var host`,
`DetailProductHelper.swift:79`) et le commentaire l.63 documente explicitement la contrainte subie.
Le correctif supprime ce besoin de contournement sans rien casser pour lui.

**Correctif :**
```swift
public protocol CardTabBarDelegate: AnyObject { … }
public weak var delegate: CardTabBarDelegate?
```
Rupture d'API théorique (un delegate `struct` deviendrait impossible) — aucun conformeur de ce type
n'existe dans l'app.

---

### E2 — Un bouton `isEnabled = false` reste pleinement actionnable

**Où :** [PTCardTabBar.swift:266-280](../../PTCardTabBar/Classes/PTCardTabBar.swift#L266), en particulier
la l.272 : `.filter { !$0.isHidden }`.

`touchesEnded` récupère le touch qui n'a pas été consommé par un bouton (ce qui est exactement le
cas quand le bouton est désactivé) et déclenche l'action du bouton **le plus proche**, sans jamais
regarder `isEnabled`.

**Mesuré.** Bouton d'index 1 désactivé, tap directement dessus :

```
09:33:30.899  AUDIT >>> bouton index 1 isEnabled=false
09:33:40.592  AUDIT >>> selectedIndex ecrit = 1
```

La capture confirme le basculement d'onglet, et l'icône prend même la **teinte « sélectionné »** :
aucun rendu désactivé nulle part.

**Impact réel sur DateLimite.** `DetailProductHelper.swift:175` coupe la cloche de notification
(`isEnabled = false`) quand les alertes sont désactivées, et
`DetailProductController.swift:344 didTapNotificationButton()` n'a **aucune garde**. Le geste passe
donc quand même : la cloche grisée ouvre le flux de notification.

**Correctif :**
```swift
let buttons = stackView.arrangedSubviews
    .compactMap { $0 as? PTBarButton }
    .filter { !$0.isHidden && $0.isEnabled }
```
et traiter l'état désactivé dans `PTBarButton.reloadApperance()`
([PTBarButton.swift:63](../../PTCardTabBar/Classes/PTBarButton.swift#L63)), qui ne connaît aujourd'hui
que `isSelected`.

---

### E3 — Deux surcharges `select(at:)` aux sémantiques opposées → surlignage désynchronisé

**Où :** [PTCardTabBar.swift:183](../../PTCardTabBar/Classes/PTCardTabBar.swift#L183)
(`select(at:notifyDelegate:)`) et [:233](../../PTCardTabBar/Classes/PTCardTabBar.swift#L233)
(`select(at:)`). La première pose `button.tintColor` **directement** et ne touche ni `isSelected`
ni l'indicateur ; la seconde pose `isSelected`, déplace l'indicateur et notifie **toujours**.

**Prouvé par le compilateur.** Sonde `@available(*, deprecated)` sur chaque surcharge :

| Site d'appel | Surcharge résolue |
|---|---|
| `PTCardTabBar.swift:220` (`reloadViews`) | `select(at:)` — notifie toujours |
| `PTCardTabBar.swift:264` (`buttonTapped`) | `select(at:)` |
| `PTCardTabBarController.swift:109` (`viewDidLoad`) | `select(at:)` |
| `PTCardTabBarController.swift:56` / `:62` (didSet) | `select(at:notifyDelegate:)` |

Autrement dit : **toute sélection programmatique passe par la surcharge qui ne met pas `isSelected`
à jour.**

**Mesuré.** Après `selectedIndex = 2`, puis un simple rafraîchissement de teinte :

```
T2 juste apres selectedIndex=2        | 0:sel=true/tint=#9B9B9B  1:sel=false/tint=#9B9B9B  2:sel=false/tint=#0088FF
T2 apres rafraichissement de teinte   | 0:sel=true/tint=#FF383C  1:sel=false/tint=#9B9B9B  2:sel=false/tint=#9B9B9B
```

Le surlignage **saute sur le mauvais onglet** : `isSelected` est resté sur 0, et
`reloadApperance()` repeint à partir de `isSelected`.

**Impact réel sur DateLimite.** Chemin de production, pas seulement de test :
- `Date_LimiteSceneDelegate.openRecipeDeeplink` (`:665`) fait `cardTabBarController.selectedIndex = idx`
  à l'ouverture d'un push recette ;
- `ProductsController.setupBottom` (`:498`) fait `tabBar.tintColor = skin.text()` — donc
  `reloadApperance()` — à chaque rafraîchissement de la barre (rotation, transition de taille,
  changement d'écran) ;
- `indicatorIsHidden = true` dans cette app (`Date_LimiteSceneDelegate:533`, `:542`,
  `DetailProductHelper:99-100`) : **la teinte est le seul repère de sélection.**

**Correctif :** fusionner en une seule méthode qui pose `isSelected`, déplace l'indicateur et
notifie selon le paramètre ; supprimer la surcharge sans paramètre (ou en faire un simple
`select(at: i, notifyDelegate: true)`). Les appels internes doivent passer `notifyDelegate`
explicitement.

---

### E4 — Course `hideTabBar()` / `showTabBar()` : barre opaque mais masquée

**Où :** [PTCardTabBarController.swift:31-37](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L31)
et [:39-44](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L39). La completion de `hideTabBar`
ignore le flag `finished` et pose `isHidden = true` inconditionnellement.

**Mesuré.** `hideTabBar()` puis `showTabBar()` 100 ms plus tard :

```
09:38:21.123  AUDIT >>> T1 RESULTAT 700 ms apres showTabBar | barre isHidden=true alpha=1.00
```

Barre à alpha 1 mais `isHidden` — **invisible et non interactive** jusqu'au prochain `showTabBar()`.
C'est bien la course pressentie.

**Impact réel sur DateLimite.** Les deux appels sont fréquents et rapprochés :
`ProductsController.willPresentSearchController:557` masque / `willDismissSearchController:563`
réaffiche (annulation rapide d'une recherche) ; `setupBottom:504/506` appelle l'un ou l'autre à
chaque rafraîchissement ; `:1477` masque au push du détail.

**Correctif validé par la mesure** (une ligne) :
```swift
open func hideTabBar() {
    UIView.animate(withDuration: 0.3, animations: {
        self.customTabBar.alpha = 0
    }, completion: { finished in
        if finished { self.customTabBar.isHidden = true }
    })
}
```
Vérifié sur le même scénario : `isHidden=false alpha=1.00`. `showTabBar()` interrompt l'animation
d'alpha en cours, la completion est donc appelée avec `finished == false` et ne masque plus rien.

---

## Gravité moyenne

### M1 — `viewDidLoad` notifie le delegate deux fois et force l'index 0

**Où :** [PTCardTabBarController.swift:108-109](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L108).
`items = tabBar.items!` déclenche `reloadViews()` → `select(at: 0)` → delegate ; puis la l.109
refait un `select(at:)` → delegate.

**Mesuré.** Deux écritures de `selectedIndex` à l'intérieur de `super.viewDidLoad()` :
```
AUDIT >>> avant super.viewDidLoad()
AUDIT >>> selectedIndex ecrit = 0
AUDIT >>> selectedIndex ecrit = 0
AUDIT >>> apres super.viewDidLoad(), selectedIndex=0
```

Conséquences : un `selectedIndex` préréglé (storyboard, restauration d'état) est écrasé par 0, et
le delegate exécute `popToRootViewController(animated: true)`
([:194-196](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L194)) pendant `viewDidLoad`.

**Mine à retardement associée (prouvé par lecture).** `reloadViews()` appelle `select(at: 0)` dès
que `items` bouge et que `indicatorIsHidden == false`. Dans cette surcharge,
`var btn: PTBarButton!` ([:240](../../PTCardTabBar/Classes/PTCardTabBar.swift#L240)) reste `nil` si
aucun bouton ne correspond, et est passé à un paramètre **non optionnel** → trap Swift.
Dans `DetailProductHelper.configure()`, la seule chose qui l'empêche est l'ordre des lignes :
`delegate = self` (`:95-96`) puis `indicatorIsHidden = true` (`:99-100`) **avant** `items`
(`setupTabBar()`). Inverser ces deux lignes suffirait à faire, au mieux, crasher l'ouverture d'une
fiche produit — au pire, à déclencher l'action de tag 0 de la barre gauche, c'est-à-dire
`host.dismiss()` : la fiche se fermerait toute seule à l'ouverture.

**Correctif :** `reloadViews()` ne doit pas notifier (`select(at: 0, notifyDelegate: false)`), et
la signature du delegate doit accepter un bouton optionnel — ou la méthode doit sortir tôt quand
aucun bouton ne correspond.

---

### M2 — `setTabBarHidden(_:animated:)` détourne une API UIKit iOS 18

**Où :** [PTCardTabBarController.swift:112](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L112).

**Prouvé par le SDK** (iOS 27.0 installé, `UITabBarController.h:140`) :
```objc
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated API_AVAILABLE(ios(18.0), …);
```
Ce n'est donc pas une méthode maison : c'est un **override** d'une méthode UIKit, sans appel à
`super`. Il n'a aucun appelant dans le pod, l'exemple ou l'app (vérifié) — donc oui, code mort
côté app, mais pas inoffensif : `isTabBarHidden = true` (le moyen documenté de masquer la barre
native iPadOS 18) passe par ce setter et se retrouve détourné vers le réglage d'alpha du pod.

Ironie utile : c'est précisément l'API qui pourrait remplacer le hack
`traitOverrides.horizontalSizeClass = .compact` de la l.97-99.

**Correctif :** renommer en `setCardTabBarHidden(_:animated:)` (ou supprimer, puisque `hideTabBar`/
`showTabBar` couvrent le besoin), et évaluer `isTabBarHidden = true` à la place du forçage de
classe de taille.

---

### M3 — Forçage de la classe de taille compacte sur iPad (supposé, à mesurer)

**Où :** [PTCardTabBarController.swift:97-99](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L97).

`traitOverrides.horizontalSizeClass = .compact` s'applique à **toute la hiérarchie enfant** :
chaque contrôleur d'onglet croit tourner sur iPhone. Effets attendus : popovers rendus en sheets,
`UISplitViewController` imbriqués qui se collapsent, layouts adaptatifs qui basculent. L'app place
ce contrôleur dans le `secondary` d'un `PrimarySplitViewController`
(`Date_LimiteSceneDelegate:508`), donc en plein dans ce périmètre.

**Supposé** — non mesuré. À vérifier sur l'iPad Air 13" iOS 27 (`3A1905DA…`), avec le témoin 26.5
(`0D6B9095…`), en comparant les écrans enfants avec et sans la ligne.

---

### M4 — Contraintes ancrées sur le `safeAreaLayoutGuide` de la barre elle-même

**Où :** [PTCardTabBarController.swift:152](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L152)
et [:155](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L155) :
`customTabBar.safeAreaLayoutGuide.leadingAnchor` contraint à `view.safeAreaLayoutGuide.leadingAnchor`.

Le safe area d'une vue se déduit de sa position, qui dépend ici de la contrainte elle-même :
dépendance circulaire que le moteur résout par des passes de layout supplémentaires.
Géométriquement le résultat est identique — la barre ne touche aucun bord d'écran, ses insets sont
nuls — donc on paie la boucle pour rien.

**Prouvé par lecture**, coût réel non quantifié.
**Correctif :** ancrer sur `customTabBar.leadingAnchor` / `.trailingAnchor`.

---

### M5 — `reloadViews()` détruit et recrée tous les boutons à chaque mutation d'`items`

**Où :** [PTCardTabBar.swift:200-221](../../PTCardTabBar/Classes/PTCardTabBar.swift#L200), déclenché par
le `didSet` de `items` ([:51](../../PTCardTabBar/Classes/PTCardTabBar.swift#L51)) — donc aussi par
`append`, `insert` et `remove`.

Côté app, `DetailProductHelper.setupTabBar()` fait une affectation puis jusqu'à deux `insert` :
jusqu'à **trois reconstructions complètes** par ouverture de fiche. Toute personnalisation posée
sur un bouton (`badgeLayout` l.147, `setImage`/`isEnabled` dans `updateNotificationIcon`, badges
posés par notification) est perdue si `items` rebouge après coup. Le code app est correct
aujourd'hui **uniquement** parce qu'il personnalise après la dernière mutation — c'est une
propriété fragile, non documentée.

Accessoirement, `indicatorViewXConstraint`
([:106](../../PTCardTabBar/Classes/PTCardTabBar.swift#L106)) n'est pas remis à `nil` dans `reloadViews()` :
il continue de retenir un bouton retiré de la hiérarchie.

**Correctif :** réutiliser les boutons existants quand le nombre d'items ne change pas (ou exposer
un `reload` explicite plutôt qu'un `didSet`), et remettre `indicatorViewXConstraint` à `nil`.

---

### M6 — `redrawCustomTabBar(animated:)` : les deux points signalés, confirmés

**Où :** [PTCardTabBarController.swift:165-181](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L165).

**(a) `self.view.layoutIfNeeded()` dans le bloc d'animation.** `self.view` est bien la racine du
tab bar controller, contrôleurs enfants compris — disproportionné pour déplacer deux constantes.
**Mais** : ta mesure (`inheritedAnimationDuration = 0` dans le `layoutSubviews` des cellules)
montre que, dans le cas observé, les enfants ne sont **pas** animés. `layoutIfNeeded` n'anime que
ce qui est effectivement invalidé au moment de l'appel ; l'exposition est donc réelle mais
conditionnelle. Je ne peux pas affirmer que ça anime la hiérarchie enfant en pratique.

Le motif propre est de solder le layout en attente **avant** d'ouvrir le bloc. À noter qu'on ne
peut pas réduire le `layoutIfNeeded` à la seule barre : les deux contraintes sont installées sur
`self.view`, qui est l'ancêtre commun.

```swift
@objc open func redrawCustomTabBar(animated: Bool) {
    guard leadingConstraint != nil else { return }   // cf. (c)
    view.layoutIfNeeded()                            // on solde le retard hors animation
    leadingConstraint.constant = leftSpacing
    trailingConstraint.constant = -rightSpacing
    guard animated else { view.layoutIfNeeded(); return }
    UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
}
```

**(b) `customTabBar.updateConstraints()` appelé à la main** (l.170 et l.177). Confirmé : c'est un
point d'extension qu'UIKit appelle lui-même ; on demande `setNeedsUpdateConstraints()`.
Ici l'appel est de surcroît **sans effet** — `PTCardTabBar` ne surcharge pas `updateConstraints`,
donc seule l'implémentation `UIView` s'exécute et aucune contrainte n'y est créée. Idem pour
`updateConstraintsIfNeeded()` (l.171, l.178). **Les quatre lignes sont à supprimer.**

**(c) `leadingConstraint` / `trailingConstraint` sont des IUO**
([:87-88](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L87)) posés dans `setupTabBar()`, donc
depuis `viewDidLoad`. Appeler `redrawCustomTabBar` avant chargement de la vue plante
(prouvé par lecture : déréférencement d'IUO `nil`). Les trois appelants de l'app
(`ProductsController:501`, `RecipeSuggestionController:203`, `ConsumptionStatsHostingController:101`)
passent tous par des contrôleurs enfants, donc après — mais l'API publique ne se protège pas.

---

### M7 — Trois APIs de fond concurrentes, dont deux mortes, et un fond écrasé sur iOS 26+

**Où :** `tabBarBackgroundColor` ([Controller:20-25](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L20)),
`mainColor` ([:75-79](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L75)),
`border` ([:81-85](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L81)).

- `tabBarBackgroundColor` et `border` n'ont **aucun appelant** (pod, exemple, app — vérifié).
- `border` fige un `UIColor` en `cgColor`
  ([PTCardTabBar.swift:46](../../PTCardTabBar/Classes/PTCardTabBar.swift#L46)) : une couleur dynamique ne
  suivra pas la bascule clair/sombre.
- Sur iOS 26+, `setup()` force `backgroundColor = .clear` + effet verre
  ([:135-142](../../PTCardTabBar/Classes/PTCardTabBar.swift#L135)) : **tout fond posé ailleurs est écrasé
  silencieusement**, y compris celui défini dans un storyboard.

Ce dernier point touche directement DateLimite : `leftCardTabBar` / `rightCardTabBar`
(`DetailProductController.swift:38-39`) sont des `PTCardTabBar` instanciés **depuis un storyboard**,
donc via `init?(coder:)` → `setup()`. Sur iOS 26+ ils passent en verre `glassMode = 0` quoi qu'en
dise le storyboard. Et comme `glassMode`, `mainColor` et `border` sont **internes** au module, une
barre utilisée seule (le cas de l'écran détail) n'a **aucun moyen** de choisir son apparence : seul
le `PTCardTabBarController` expose ces réglages.

**Rendu vérifié** sur iOS 27 : la capsule et son rayon d'angle s'affichent correctement, l'effet de
verre est bien appliqué. Pas de régression visuelle constatée — le problème est l'impossibilité de
configurer, pas le rendu.

**Correctif :** supprimer `tabBarBackgroundColor`, promouvoir `glassMode`/`mainColor`/`border` en
`public` sur `PTCardTabBar`, et ré-résoudre les `cgColor` sur changement de trait.

---

## Gravité faible / hygiène

| # | Constat | Où | Preuve |
|---|---|---|---|
| **F1** | `ReplaceMe.swift` : fichier vide (0 octet), résidu du template CocoaPods → supprimer | [`PTCardTabBar/Classes/ReplaceMe.swift`](../../PTCardTabBar/Classes/ReplaceMe.swift) | Mesuré |
| **F2** | `add(item:)` et `remove(item:)` : code mort **et faux**. `add` force `item.image!` et crée un bouton en double (le `didSet` d'`items` a déjà tout reconstruit) ; `remove` fait `removeArrangedSubview` sans `removeFromSuperview` — le bouton reste visible — puis indexe `arrangedSubviews[index]` après reconstruction | [PTCardTabBar.swift:158](../../PTCardTabBar/Classes/PTCardTabBar.swift#L158), [:163](../../PTCardTabBar/Classes/PTCardTabBar.swift#L163) | Lecture |
| **F3** | Code mort confirmé, zéro appelant dans pod + exemple + app : `PTClearCardTabBar`, `UIColor.by(r:g:b:a:)`, `pinToSafeArea`, `pinToSuperView`, `centerInSuperView`, `constraint(height:)`, `PTBarButton.init(forItem:)` | Extensions + `PTCardTabBar.swift:15`, `PTBarButton.swift:36` | Mesuré (grep exhaustif) |
| **F4** | `deinit` de `PTCardTabBar` retire des targets : inutile (`UIControl` ne retient pas ses targets, et l'objet meurt), et touche le `lazy stackView` — qu'il instancie s'il ne l'était pas | [PTCardTabBar.swift:124-130](../../PTCardTabBar/Classes/PTCardTabBar.swift#L124) | Lecture |
| **F5** | Observateur `NotificationCenter` jamais retiré → **pas une fuite** (auto-retrait depuis iOS 9), mais posé sans garde de double-enregistrement. Le contrat du `userInfo` (`index`, `value`) n'est documenté nulle part, et **l'exemple lui-même le viole** : il poste `["index": 0]` sans `"value"`, donc le badge de démo ne s'affiche jamais | [Controller:101](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L101), [:183](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L183) ; `Example/PTCardTabBar/PTTabBarViewController.swift:26` | Lecture |
| **F6** | `PTBarButton.layoutSubviews` appelle `badgeLayout(self)` à **chaque** passe : instancie un `BadgeHub` pour chaque bouton même sans badge, et réapplique frame / échelle / police en boucle | [PTBarButton.swift:71-74](../../PTCardTabBar/Classes/PTBarButton.swift#L71) | Lecture |
| **F7** | **Accessibilité** — cf. détail ci-dessous | [PTCardTabBar.swift:171-181](../../PTCardTabBar/Classes/PTCardTabBar.swift#L171) | Lecture + corroboration app |
| **F8** | Dynamic Type / RTL : `tabBarHeight = 70` et `boldSystemFont(ofSize: 15)` ne suivent pas les tailles de texte ; le badge est calé sur un décalage en dur à droite du centre, donc non miroité en RTL. Le reste (leading/trailing, `UIStackView`) est correct en RTL | [Controller:67](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L67), [PTBarButton.swift:19-21](../../PTCardTabBar/Classes/PTBarButton.swift#L19) | Lecture |
| **F9** | Ombre sans `shadowPath` → rendu hors écran à chaque changement de taille. Le `cornerRadius` est déjà recalculé dans `layoutSubviews`, le `shadowPath` pourrait y être posé | [PTCardTabBar.swift:150-153](../../PTCardTabBar/Classes/PTCardTabBar.swift#L150), [:286](../../PTCardTabBar/Classes/PTCardTabBar.swift#L286) | Lecture |
| **F10** | `layoutSubviews` pose `stackView.frame` à la main alors qu'`indicatorView` est contraint en Auto Layout **sur** `stackView` et sur les boutons. Ça fonctionne, mais chaque affectation de frame réinvalide le layout du sous-arbre | [PTCardTabBar.swift:282-288](../../PTCardTabBar/Classes/PTCardTabBar.swift#L282), [:202](../../PTCardTabBar/Classes/PTCardTabBar.swift#L202), [:247](../../PTCardTabBar/Classes/PTCardTabBar.swift#L247) | Lecture |
| **F11** | La conformité `CardTabBarDelegate` est déclarée **en extension** : une sous-classe ne peut pas surcharger `cardTabBar(_:didSelectItemAt:button:)`. Aucun point d'extension pour intercepter une sélection (cas classique : un onglet central qui présente une modale au lieu de changer d'onglet) | [Controller:191-200](../../PTCardTabBar/Classes/PTCardTabBarController.swift#L191) | **Prouvé par le compilateur** : `overriding non-open instance method outside of its defining module` / `declared in extension … cannot be overridden` |
| **F12** | Podspec : `homepage` et `source` pointent toujours sur `hussc/PTCardTabBar` alors que la consommation se fait sur le fork `link60` ; `version` figée à `1.0.3` depuis une vingtaine de commits. Sans effet tant que le `Podfile` impose `git:` + `branch:`, mais toute résolution par tag serait fausse | [`PTCardTabBar.podspec`](../../PTCardTabBar.podspec) | Lecture |
| **F13** | **L'exemple ne tourne plus** : (a) `BadgeHub` déclare `IPHONEOS_DEPLOYMENT_TARGET = 10.0`, refusé par Xcode 27 — l'app s'en sort via son `post_install` qui supprime la clé (`Podfile:72`), pas l'exemple ; (b) sans manifeste `UIScene`, iOS 27 tue l'app au lancement (`_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`, `EXC_BREAKPOINT`). Il n'y a donc plus de banc de validation manuelle pour le fork | `Example/` | **Mesuré** (build + rapport de crash) |
| **F14** | Résidus : `.travis.yml` (CI morte), `UIRequiredDeviceCapabilities = armv7` dans l'Info.plist de l'exemple | racine, `Example/PTCardTabBar/Info.plist` | Mesuré |
| **F15** | Faute propagée dans le code : `reloadApperance()` → `reloadAppearance()`. Symbole **interne** au module, renommage sans coût pour les consommateurs | `PTCardTabBar.swift:62`, `PTBarButton.swift:63` | Lecture |

### F7 — Accessibilité, en détail

`addButton(with:tag:)` ne retient de l'`UITabBarItem` que **`image` et `tag`**. Sont jetés :
`title`, `accessibilityLabel`, `accessibilityIdentifier`, `badgeValue`. Les `PTBarButton` créés
n'ont donc ni nom, ni trait `.tab`, ni reflet de l'état sélectionné ; le conteneur n'est pas exposé
comme `.tabBar`. VoiceOver annonce « bouton » sans identité, et la sélection n'est pas annoncée.

S'ajoute le fait que la sélection est pilotée par `touchesEnded` sur le conteneur (E2) plutôt que
par l'action des boutons : même un bouton correctement nommé ne serait pas activable par les
technologies d'assistance selon le chemin normal.

**Corroboration dans ton propre repo :** les tests UI de DateLimite notent que la barre
« n'est pas tappable de manière fiable depuis XCUI » (`DateLimiteUITests.swift:274-276`) et
contournent par un launch argument `-SnapshotInitialTab` traité côté `SceneDelegate`. C'est
exactement le symptôme de boutons sans identité d'accessibilité — XCUI et VoiceOver lisent le même
arbre.

**Correctif :** reprendre `item.title` / `item.accessibilityLabel` / `item.accessibilityIdentifier`
sur le bouton, poser `accessibilityTraits = [.button, .tab]` (et `.tabBar` sur le conteneur),
refléter la sélection via le trait `.selected`, et faire porter l'activation par les boutons
eux-mêmes.

---

## Réponses aux six points signalés

| # | Point | Verdict |
|---|---|---|
| 1 | `UIView.animate` + `self.view.layoutIfNeeded()` dans `redrawCustomTabBar` | **Confirmé** comme motif disproportionné, **mais** ta mesure montre que les enfants ne sont pas animés en pratique. Correctif = solder le layout avant le bloc. On ne peut pas restreindre le `layoutIfNeeded` à la barre : les contraintes vivent sur `self.view`. Cf. **M6(a)** |
| 2 | `customTabBar.updateConstraints()` appelé à la main | **Confirmé, et pire qu'inutile en apparence** : sans override d'`updateConstraints` dans `PTCardTabBar`, les deux lignes (`updateConstraints` + `updateConstraintsIfNeeded`) sont strictement sans effet. À supprimer. Cf. **M6(b)** |
| 3 | Course `hideTabBar` / `showTabBar` | **Confirmée par la mesure** : `isHidden=true` avec `alpha=1.00`. Correctif d'une ligne (`if finished`), **validé par la mesure**. Cf. **E4** |
| 4 | `setTabBarHidden(_:animated:)` sans appelant | **Confirmé sans appelant**, mais ce n'est pas du code mort neutre : c'est un **override d'une API UIKit iOS 18** (vérifié dans le SDK), sans `super`. Cf. **M2** |
| 5 | `delegate` fort et non class-bound | **Confirmé, et c'est le constat le plus grave** : cycle de rétention prouvé par A/B au runtime, aggravé par le multi-fenêtres iPad. Cf. **E1** |
| 6 | `ReplaceMe.swift` | **Confirmé**, fichier vide à supprimer. Cf. **F1** |

---

## Ordre de livraison

Le découpage en lots, les critères de sortie et l'avancement vivent dans la carte de chantier :
[`PTCARDTABBAR_CORRECTIFS.md`](../in-progress/PTCARDTABBAR_CORRECTIFS.md).

## Rappel de déploiement

`Pods/` est gitignoré côté DateLimite : un correctif ne prend effet qu'une fois **poussé sur la
branche `badge` du fork**, puis récupéré par `pod update PTCardTabBar` (le `Podfile.lock` épingle
aujourd'hui `de21149d51c240b799452a889f5a309811fb9bf0`). Comme `s.version` ne bouge jamais,
c'est bien le SHA de la branche qui fait foi.
