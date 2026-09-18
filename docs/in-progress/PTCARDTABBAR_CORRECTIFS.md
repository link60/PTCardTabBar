# Correctifs du pod `PTCardTabBar` — chantier lotti

> **Carte ouverte le 2026-09-18 — `in-progress`, démarrée le 2026-09-18** (ex-`backlog/high`).
> Remise en état du fork `link60` à partir du diagnostic de l'audit du même jour. L'urgence `high`
> tenait à quatre constats (**E1** à **E4**) : des défauts fonctionnels **reproduits sur
> simulateur**, dont deux atteignent DateLimite en production.
>
> **Diagnostic :** [`PTCARDTABBAR_AUDIT.md`](../reference/PTCARDTABBAR_AUDIT.md) — document de
> référence **figé**, décrivant l'état du code avant tout correctif. Les identifiants `E*` / `M*` /
> `F*` utilisés ici y renvoient et sont stables. Ne pas réécrire l'audit au fil des corrections :
> c'est **cette carte** qui porte l'avancement.
>
> **Taille :** `L` — sept lots indépendants. **Lots 0, 1 et 2 livrés ; Lot 3 à démarrer.**

---

## 1. Objectif

Remettre le pod en état d'être maintenu : supprimer les quatre défauts fonctionnels mesurés, rendre
la surface d'API cohérente, et rattraper la dette d'accessibilité — sans régression visible dans
DateLimite, seul consommateur.

Le chantier **n'est pas une réécriture**. La barre « carte », son rendu verre iOS 26+ et son API
publique côté app restent ce qu'ils sont ; on corrige ce qui est faux et on nettoie ce qui est mort.

## 2. Déclencheurs

- **E1** aggravé par le multi-fenêtres : DateLimite déclare `UIApplicationSupportsMultipleScenes = true`
  et instancie un `PTCardTabBarController` **par scène** ; chaque fenêtre iPad fermée fuit l'arbre
  complet.
- **E2** est un défaut visible par l'utilisateur : la cloche de notification grisée ouvre quand même
  le flux.
- **F13** — l'exemple du pod ne démarre plus sous iOS 27, donc plus aucun banc de validation : tout
  correctif devrait aujourd'hui se tester dans DateLimite, ce qui est lent et risqué. C'est le vrai
  bloquant du chantier, d'où un **Lot 0**.

## 3. Périmètre

**Ce qui bouge :** [`PTCardTabBar/Classes/**`](../../PTCardTabBar/Classes),
[`PTCardTabBar.podspec`](../../PTCardTabBar.podspec), et le projet d'exemple
(`Example/`) pour le seul Lot 0.

**Ce qui ne bouge pas :**

| Sujet | Décision |
|---|---|
| Rendu verre iOS 26+ (`UIGlassEffect`) | **Conservé.** Vérifié sur iOS 27 : capsule, rayon d'angle et effet corrects. |
| `F10` — mélange `stackView.frame` posé à la main / Auto Layout sur `indicatorView` | **Hors périmètre.** Fonctionne ; le corriger demanderait de refondre le layout interne de la barre. Dette **assumée**, pas planifiée. |
| Nom du pod, dépendance `BadgeHub` | Inchangés. `BadgeHub` reste non maintenu, mais le remplacer est un chantier distinct. |

## 4. Contrainte de livraison

Le chantier vit sur la branche **`correctifs-audit`**, partie de `badge` au commit `de21149`.
DateLimite pointe dessus le temps du chantier :

```ruby
pod 'PTCardTabBar', git: 'https://github.com/link60/PTCardTabBar.git', branch: 'correctifs-audit'
```

`Pods/` est gitignoré côté app : un lot n'existe pour DateLimite qu'une fois **poussé** puis
récupéré par `pod update PTCardTabBar`. Le `Podfile.lock` épingle un SHA et `s.version` du podspec
ne bouge jamais — **c'est le SHA qui fait foi**, pas le numéro de version.

En fin de chantier, `correctifs-audit` a vocation à remplacer `badge` (merge ou bascule du Podfile).

Conséquence pratique : chaque lot se termine par un `pod update` côté app et une vérification que
DateLimite **compile et se comporte** comme avant. Un lot n'est pas livré tant que ce dernier point
n'est pas fait.

## 5. Banc de validation

Le banc est l'app d'exemple du pod, remise en route au Lot 0.

| Support | Rôle |
|---|---|
| iPhone 17 / iOS 27 — `CB5E2618-2AA4-4A50-BDF7-56B64E04ED60` | banc principal, c'est là qu'ont été mesurés E1 à E4 |
| iPad Air 13" / iOS 27 — `3A1905DA-0621-441C-9852-4E7E92E0C6F1` | vérification iPad, notamment le Lot 6 |
| iPad Air 13" / iOS 26.5 — `0D6B9095-F6D0-4FA3-9D65-5987F28CDCAA` | témoin sain pour comparaison |

Les mesures se font par instrumentation temporaire de l'exemple (`NSLog` + `log stream` filtré),
jamais par modification du pod pour les besoins du test.

---

## 6. Découpage et suivi

### Convention de suivi

- `⬜ À faire` : lot non démarré ;
- `🚧 En cours` : implémentation commencée ;
- `🟡 En recette` : implémentation terminée, mais un ou plusieurs critères restent à vérifier ;
- `✅ Livré` : lot terminé, vérifié et répondant à tous ses critères de sortie.

Lorsqu'un lot est livré, remplacer son statut dans le tableau ci-dessous, cocher ses critères de
sortie et ajouter un bloc **Implémentation du \<date\>** sous le lot. Un lot n'est pas livré sur la
seule base du commit : la vérification sur le banc **et** le `pod update` côté DateLimite doivent
être faits.

| Lot | Objet | Taille | Statut |
|---:|---|:---:|:---:|
| 0 | Remise en route du banc de validation | S | ✅ Livré — 2026-09-18 |
| 1 | Correctifs sûrs, sans rupture d'API | M | ✅ Livré — 2026-09-18 |
| 2 | Cycle de rétention du `delegate` | S | ✅ Livré — 2026-09-18 |
| 3 | Unification de la sélection | M/L | ⬜ À faire |
| 4 | Nettoyage et surface d'API | M | ⬜ À faire |
| 5 | Accessibilité et Dynamic Type | L | ⬜ À faire |
| 6 | Mesure iPad — forçage de la classe de taille | S | ⬜ À faire |

### Couverture des constats de l'audit

Aucun constat ne doit disparaître en silence.

| Constat | Lot | Constat | Lot | Constat | Lot |
|---|:---:|---|:---:|---|:---:|
| E1 | 2 | M3 | 6 | F5 | 0 + 4 |
| **E5** | **1** | | | | |
| E2 | 1 | M4 | 1 | F6 | 4 |
| E3 | 3 | M5 | 3 | F7 | 5 |
| E4 | 1 | M6 | 1 | F8 | 5 |
| M1 | 3 | M7 | 4 | F9 | 4 |
| M2 | 4 | F1 à F4 | 4 | F10 | *hors périmètre* |
| | | F11, F12 | 4 | F13 | 0 |
| | | F14 | 0 + 4 | F15 | 4 |

---

### Lot 0 — Remise en route du banc de validation

**Constats : F13, F14 (partie exemple), F5 (badge de démo).**

Sans banc, tout le reste se teste dans DateLimite. C'est le premier lot, même s'il ne touche pas une
ligne du pod.

- ajouter un `post_install` à `Example/Podfile` qui supprime `IPHONEOS_DEPLOYMENT_TARGET` des cibles
  Pods — c'est ce que fait déjà DateLimite (`Podfile:72`) et c'est ce qui débloque `BadgeHub`,
  figé à iOS 10 et refusé par Xcode 27 ;
- adopter le cycle de vie `UIScene` dans l'exemple : manifeste `UIApplicationSceneManifest` dans
  `Example/PTCardTabBar/Info.plist` + un `SceneDelegate` ; sans quoi iOS 27 tue l'app au lancement
  (`_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`, `EXC_BREAKPOINT`) ;
- nettoyer `UIRequiredDeviceCapabilities = armv7` du même plist ;
- corriger la démo de badge : `PTTabBarViewController` poste `["index": 0]` **sans la clé `"value"`**,
  que `setBadge` exige — le badge de démo ne s'est donc jamais affiché.

Critères de sortie :

- [x] `xcodebuild -workspace Example/PTCardTabBar.xcworkspace -scheme PTCardTabBar-Example` passe
      **sans override** de `IPHONEOS_DEPLOYMENT_TARGET` en ligne de commande ;
- [x] l'exemple démarre sur iPhone 17 / iOS 27 et les trois onglets répondent ;
- [x] le badge de démo s'affiche après les 5 s de la temporisation ;
- [x] le contrat du `userInfo` de `PTCardTabBarBadgeNotification` (`index`, `value`) est écrit dans
      le README du pod.

**Implémentation du 2026-09-18 :**

- `Example/Podfile` — `post_install` qui supprime `IPHONEOS_DEPLOYMENT_TARGET` des cibles Pods, puis
  `pod install` ; `BadgeHub` hérite désormais du `platform :ios, '15.0'` du Podfile ;
- `Example/PTCardTabBar/SceneDelegate.swift` — nouveau fichier, ajouté au projet Xcode (les quatre
  entrées `PBXBuildFile` / `PBXFileReference` / enfant de groupe / phase `Sources`, `plutil -lint`
  OK) ; `Info.plist` reçoit le manifeste `UIApplicationSceneManifest` ;
- `AppDelegate` — la fenêtre et les callbacks actif/arrière-plan partent dans le `SceneDelegate`.
  Sous le cycle de vie UIScene, `AppDelegate.window` n'est plus utilisée et
  `applicationDidBecomeActive` & consorts ne sont plus appelés : les laisser aurait induit en erreur
  quiconque copie l'exemple ;
- `Info.plist` — `UIRequiredDeviceCapabilities = armv7` supprimé (reliquat 32 bits) ;
- `PTTabBarViewController` — la démo de badge postait `["index": 0]` sans la clé `"value"` exigée
  par `setBadge` : **elle n'avait jamais rien affiché**. Corrigée en `["index": 0, "value": 3]` ;
- `README.md` — section **Badges** ajoutée : les deux clés obligatoires, le fait qu'un `userInfo`
  incomplet est ignoré en silence, et le moment où l'observateur est posé.

**Recette du 2026-09-18**, iPhone 17 / iOS 27 (`CB5E2618…`), build sans aucun override :

- `** BUILD SUCCEEDED **`, zéro erreur, zéro avertissement de deployment target ;
- l'app démarre — plus de `EXC_BREAKPOINT` au lancement ;
- chemin **« From Code »** : les trois onglets répondent, l'indicateur suit, et le badge `3`
  apparaît sur le premier onglet après la temporisation — **une première** ;
- chemin **« From Storyboard »** : la barre se construit, la teinte rose de l'`@IBInspectable` est
  appliquée, les onglets répondent. C'est le chemin qu'emprunte DateLimite.

---

### Lot 1 — Correctifs sûrs, sans rupture d'API

**Constats : E4, E2, M4, M6.** Aucune signature publique ne change ; c'est le lot à faible risque et
fort rendement.

- **E4 — course `hideTabBar` / `showTabBar`.** La completion ignore le flag `finished` et masque une
  barre qu'on vient de réafficher (mesuré : `isHidden = true` avec `alpha = 1.00`). Correctif d'une
  ligne, **déjà validé par la mesure** pendant l'audit :
  ```swift
  }, completion: { finished in
      if finished { self.customTabBar.isHidden = true }
  })
  ```
- **E2 — bouton désactivé actionnable.** `touchesEnded` filtre `isHidden` mais pas `isEnabled` :
  ajouter `&& $0.isEnabled` au filtre, et faire connaître l'état désactivé à
  `PTBarButton.reloadApperance()`, qui ne regarde aujourd'hui que `isSelected`.
- **M6 — `redrawCustomTabBar`.** Supprimer les **quatre** lignes `updateConstraints()` /
  `updateConstraintsIfNeeded()` (sans effet : `PTCardTabBar` ne surcharge pas `updateConstraints`) ;
  solder le layout en attente **avant** d'ouvrir le bloc d'animation ; ajouter une garde sur les
  contraintes IUO, nulles tant que la vue n'est pas chargée.
- **M4 — dépendance circulaire de contrainte.** Ancrer sur `customTabBar.leadingAnchor` /
  `.trailingAnchor` plutôt que sur le `safeAreaLayoutGuide` **de la barre elle-même**. Résultat
  géométrique identique, sans la boucle de layout.

Critères de sortie :

- [x] sur le banc : `hideTabBar()` puis `showTabBar()` à 100 ms laisse `isHidden = false` ;
- [x] sur le banc : un tap sur un bouton `isEnabled = false` ne change pas d'onglet et ne notifie pas
      le delegate ;
- [x] `redrawCustomTabBar` ne plante pas s'il est appelé avant chargement de la vue ;
- [x] **DateLimite après `pod update`** : barre de `ProductsController` correcte en rotation et au
      retour de recherche ; cloche grisée de la fiche produit **non actionnable**. *Validé par Loïc
      le 2026-09-18.*

**Implémentation du 2026-09-18 :**

- **E4** — `hideTabBar` teste `finished` avant de masquer. Un `showTabBar()` arrivé pendant les
  0,3 s interrompt l'animation d'alpha, sa completion reçoit alors `finished == false` et ne masque
  plus rien ;
- **E2** — repris plus largement que prévu. Le simple filtre `isEnabled` **ne suffisait pas** : il
  excluait bien le bouton désactivé, mais reportait alors le geste sur le **voisin le plus proche**,
  donc déclenchait une action fausse — pire que le défaut d'origine. `touchesEnded` distingue
  maintenant deux cas : un tap qui tombe **sur** un bouton désactivé ne fait rien, un tap ailleurs
  dans la capsule active le bouton **actif** le plus proche. Au passage, les cadres sont ramenés
  dans le repère de la barre par `convert(_:from:)` : l'ancien calcul comparait des `center` exprimés
  dans la stack view à une position exprimée dans la barre, et ne marchait que parce que l'origine
  de la stack view est (0, 0) ;
- **E2 (rendu)** — `PTBarButton` gagne `disabledColor` et observe `isEnabled` ; un bouton désactivé
  gardait jusqu'ici l'apparence d'un bouton actif, voire sélectionné ;
- **E5** *(nouveau, cf. addendum de l'audit)* — `tabBar.items ?? []` au lieu du forçage, plus une
  garde dans `select(at:)` qui ne notifie pas le delegate quand aucun bouton ne correspond ;
- **M6** — les quatre lignes `updateConstraints()` / `updateConstraintsIfNeeded()` supprimées ; le
  layout en attente est soldé **hors** du bloc d'animation ; garde `isViewLoaded` + contraintes non
  nulles en tête de méthode ;
- **M4** — contraintes ancrées sur `customTabBar.leadingAnchor` / `.trailingAnchor` au lieu du
  `safeAreaLayoutGuide` de la barre elle-même.

**Recette du 2026-09-18**, iPhone 17 / iOS 27, instrumentation temporaire du banc :

```
AUDIT >>> hideTabBar()
AUDIT >>> showTabBar() a +100 ms
AUDIT >>> E4 : isHidden=false alpha=1.00        ← avant correctif : isHidden=true alpha=1.00
AUDIT >>> M6 : redraw avant viewDidLoad survecu
```

- tap **sur** le bouton désactivé (`position={181, 31}`, dans son cadre `{{120.7, 18.7}, {120.7, 25}}`)
  → **aucune** écriture de `selectedIndex`, l'onglet ne bouge pas ;
- tap dans la marge basse de la capsule (`position={180, 56}`, sous les icônes) → le bouton actif le
  plus proche est activé, comportement voulu.

> **Relevé à verser au Lot 5.** Le diagnostic a mesuré la taille réelle des boutons : environ
> **121 × 24 pt**, soit une hauteur bien en deçà des 44 pt recommandés. C'est la règle du « bouton le
> plus proche » qui rend la barre utilisable ; une fois l'activation portée par les boutons
> eux-mêmes, il faudra leur donner une zone tactile conforme.

---

### Lot 2 — Cycle de rétention du `delegate`

**Constat : E1.** Le plus grave, et le plus simple à corriger.

```swift
public protocol CardTabBarDelegate: AnyObject { … }
public weak var delegate: CardTabBarDelegate?
```

Rupture d'API **théorique** : un delegate `struct` deviendrait impossible. Les deux conformeurs
connus sont des classes — `PTCardTabBarController` lui-même, et `ProductTabBarManager` côté app, qui
**contourne déjà** le problème avec un `private weak var host` et documente la contrainte subie dans
son en-tête. Le correctif rend ce contournement inutile, sans l'obliger à changer.

Critères de sortie :

- [x] sur le banc : `deinit` du contrôleur observé après `dismiss` ;
- [x] **DateLimite compile après `pod update`**, sans adaptation de `ProductTabBarManager` —
      vérifié le 2026-09-18 : `Podfile.lock` épinglé sur `103cf163…`, `** BUILD SUCCEEDED **`,
      0 erreur, 0 avertissement dans le pod, et aucun avertissement dans `DetailProductHelper.swift`
      où vit le conformeur. Les 239 avertissements de l'app sont préexistants et hors périmètre ;
- [x] **sur iPad**, un second `PTCardTabBarController` relâché ne survit pas — mesuré en A/B dans
      DateLimite, cf. ci-dessous. *Critère reformulé : le scénario « seconde fenêtre » s'est révélé
      impraticable en simulateur, le graphe de rétention exercé est le même.*

**Recette du 2026-09-18**, DateLimite sur iPad Air 13" / iOS 27 (`3A1905DA…`), sonde temporaire dans
`Date_LimiteSceneDelegate` (retirée depuis) : on instancie un second `PTCardTabBarController` depuis
le storyboard de l'app — exactement ce que fait `iPadScene` —, on force le chargement de sa vue pour
que `setupTabBar` câble le delegate, puis on le relâche et on suit une référence faible pendant 24 s.

| Pod | Après relâchement |
|---|---|
| `delegate` **fort** (avant correctif) | `suivis=2 vivants=2` — stable sur 24 s, **il ne meurt jamais** |
| `delegate` **faible** (après correctif) | `suivis=2 vivants=1` — mort en **moins de 3 s** |

L'A/B a été fait en modifiant temporairement le pod **installé** dans `Pods/`, sans toucher au
`Podfile` : le fichier a été remis à l'identique et ses droits restaurés à la fin.

> **Pourquoi pas le scénario « seconde fenêtre ».** Ouvrir une scène principale par
> `requestSceneSessionActivation` fait tomber le serveur de rendu sur iPadOS 27 en simulateur —
> l'app meurt deux secondes après l'ouverture, sans rapport de crash, avec des
> `Failed to commit transaction … invalid destination port`. C'est un défaut d'environnement, pas du
> pod ; le graphe de rétention exercé par le test retenu est strictement le même, et il a l'avantage
> de fournir un A/B. **Reste utile à faire à la main un jour**, App Exposé à l'appui, pour couvrir le
> cycle de vie de scène complet.

**Implémentation du 2026-09-18 :**

```swift
public protocol CardTabBarDelegate: AnyObject { … }
public weak var delegate: CardTabBarDelegate?
```

**Vérification préalable du côté app**, avant d'appliquer : passer le `delegate` en `weak` déplace
la charge de rétention sur l'appelant, donc il fallait s'assurer que les deux conformeurs sont
retenus ailleurs.

- `PTCardTabBarController` est delegate de sa propre barre : il est retenu par sa hiérarchie de
  vues et par son parent, donc rien à faire ;
- `ProductTabBarManager` est retenu par `DetailProductController` via
  `lazy var tabBarManager = ProductTabBarManager(host: self)`
  (`DetailProductController.swift:56`), indépendamment du delegate. Aucune adaptation nécessaire —
  et son contournement `private weak var host` devient superflu, sans qu'il soit urgent de le
  retirer.

Aucun autre conformeur de `CardTabBarDelegate` dans le pod, l'exemple ou l'app.

**Recette du 2026-09-18**, iPhone 17 / iOS 27 :

```
AUDIT >>> presente, delegate de la barre = Optional(<PTTabBarViewController: 0x101d6cc00>)
AUDIT >>> deinit PTTabBarViewController              ← jamais observé avant ce correctif
```

Le delegate reste bien branché pendant la présentation — changement d'onglet, déplacement de
l'indicateur et badge inchangés — et le contrôleur se désalloue au `dismiss`.

---

### Lot 3 — Unification de la sélection

**Constats : E3, M1, M5.** Le lot le plus délicat : il touche le chemin nominal de sélection d'onglet.

Aujourd'hui `PTCardTabBar` expose **deux** `select(at:)` aux sémantiques opposées — l'une pose
`isSelected` et notifie toujours, l'autre pose `tintColor` directement et ne touche pas à
`isSelected`. La résolution de surcharge a été établie au compilateur : **toute sélection
programmatique passe par celle qui ne met pas `isSelected` à jour**, d'où le surlignage qui saute
sur le mauvais onglet au premier rafraîchissement de teinte.

- fusionner en une seule méthode qui pose `isSelected`, déplace l'indicateur et notifie selon le
  paramètre ; les appels internes passent `notifyDelegate` explicitement ;
- **M1** — `reloadViews()` ne doit plus notifier le delegate. Aujourd'hui il le fait, ce qui provoque
  deux notifications dans `viewDidLoad` (mesuré : deux écritures de `selectedIndex`), écrase un
  `selectedIndex` préréglé et déclenche un `popToRootViewController(animated: true)` involontaire ;
- rendre le bouton **optionnel** dans la signature du delegate, ou sortir tôt si aucun bouton ne
  correspond : aujourd'hui un `PTBarButton!` nul est passé à un paramètre non optionnel, donc trap ;
- **M5** — remettre `indicatorViewXConstraint` à `nil` dans `reloadViews()` (il retient un bouton
  retiré de la hiérarchie), et réutiliser les boutons existants quand le nombre d'items ne change pas.

> ⚠️ **Mine à désamorcer au passage.** Côté DateLimite, ce qui empêche aujourd'hui
> `DetailProductHelper.configure()` de crasher — ou pire, de déclencher le tag `0` de la barre
> gauche, c'est-à-dire `dismiss()`, à l'ouverture d'une fiche — est **uniquement l'ordre des
> lignes** : `indicatorIsHidden = true` (`:99-100`) avant l'affectation d'`items`. Après ce lot,
> l'ordre ne doit plus rien changer. C'est un critère de sortie.

Critères de sortie :

- [ ] une seule notification du delegate pendant `viewDidLoad`, et aucun `popToRootViewController`
      involontaire ;
- [ ] après un `selectedIndex` programmatique, `isSelected` est cohérent et un
      `reloadApperance()` ne déplace plus le surlignage ;
- [ ] inverser l'ordre `indicatorIsHidden` / `items` dans `DetailProductHelper.configure()` reste
      sans effet (test à faire en local, **à ne pas commiter côté app**) ;
- [ ] DateLimite : ouverture d'un push recette puis rotation → le bon onglet reste surligné ;
- [ ] DateLimite : fiche produit, barres gauche et droite, tous les boutons routent vers la bonne
      action.

---

### Lot 4 — Nettoyage et surface d'API

**Constats : M2, M7, F1 à F6, F9, F11, F12, F14 (`.travis.yml`), F15.** Rupture d'API **assumée** :
à faire passer côté DateLimite dans la foulée.

- **Code mort** (zéro appelant, vérifié sur pod + exemple + app) : `ReplaceMe.swift` (fichier vide),
  `add(item:)` et `remove(item:)` — morts **et faux**, `PTClearCardTabBar`, `UIColor.by(r:g:b:a:)`,
  `pinToSafeArea` / `pinToSuperView` / `centerInSuperView` / `constraint(height:)`,
  `PTBarButton.init(forItem:)`, le `deinit` de `PTCardTabBar` ;
- **M2** — renommer `setTabBarHidden(_:animated:)` en `setCardTabBarHidden(_:animated:)`, ou le
  supprimer : c'est un **override de l'API UIKit iOS 18** (vérifié dans l'en-tête du SDK 27), sans
  appel à `super`, qui détourne `isTabBarHidden` ;
- **M7** — supprimer `tabBarBackgroundColor` (mort et concurrent de `mainColor`) ; promouvoir
  `glassMode`, `mainColor` et `border` en `public` sur `PTCardTabBar`, qu'une barre utilisée seule —
  le cas de la fiche produit — puisse enfin être configurée ; ré-résoudre les `cgColor` au changement
  de trait, sans quoi une couleur de bordure dynamique ne suit pas le mode sombre ;
- **F11** — rendre la conformité `CardTabBarDelegate` surchargeable : déclarée en extension, elle
  interdit aujourd'hui toute interception de la sélection par une sous-classe ;
- **F6** — sortir `badgeLayout(self)` de `layoutSubviews` : il instancie un `BadgeHub` par bouton même
  sans badge, et réapplique frame, échelle et police à chaque passe ;
- **F9** — poser `shadowPath` dans `layoutSubviews`, où le `cornerRadius` est déjà recalculé ;
- **F12** — podspec : pointer `homepage` et `source` sur le fork `link60` ;
- **F15** — `reloadApperance` → `reloadAppearance` (symbole interne, renommage sans coût) ;
- **F14** — supprimer `.travis.yml` (CI morte).

Critères de sortie :

- [ ] aucun symbole mort restant (re-passer le relevé d'appelants de l'audit) ;
- [ ] DateLimite compile après `pod update`, renommages répercutés ;
- [ ] la fiche produit peut fixer l'apparence de ses deux barres sur iOS 26+ ;
- [ ] une couleur de bordure dynamique suit la bascule clair/sombre.

---

### Lot 5 — Accessibilité et Dynamic Type

**Constats : F7, F8.** Le plus gros lot fonctionnel, et le seul qui apporte quelque chose à
l'utilisateur final au-delà de la correction de défauts.

`addButton(with:tag:)` ne retient de l'`UITabBarItem` que **`image` et `tag`** : `title`,
`accessibilityLabel`, `accessibilityIdentifier` et `badgeValue` sont jetés. Les boutons n'ont donc ni
nom, ni trait `.tab`, ni reflet de l'état sélectionné, et la barre n'est pas exposée comme `.tabBar`.
S'y ajoute le fait que la sélection est pilotée par `touchesEnded` sur le conteneur plutôt que par
l'action des boutons.

- reprendre `title` / `accessibilityLabel` / `accessibilityIdentifier` de l'item sur le bouton ;
- poser `accessibilityTraits = [.button, .tab]`, `.tabBar` sur le conteneur, et refléter la sélection
  via le trait `.selected` ;
- faire porter l'activation par les boutons eux-mêmes, `touchesEnded` ne restant qu'un élargissement
  de la zone tactile ;
- **F8** — faire suivre `tabBarHeight` et la police du badge aux tailles de texte ; miroiter le
  décalage du badge en RTL (aujourd'hui en dur à droite du centre).

> **Gain collatéral côté app :** les tests UI de DateLimite notent que la barre « n'est pas tappable
> de manière fiable depuis XCUI » et contournent par un launch argument `-SnapshotInitialTab`. Ce lot
> devrait permettre de le retirer — XCUI et VoiceOver lisent le même arbre.

Critères de sortie :

- [ ] VoiceOver annonce chaque onglet par son nom et son état sélectionné ;
- [ ] la barre est annoncée comme barre d'onglets, pas comme une pile de boutons anonymes ;
- [ ] à la plus grande taille de texte, la barre reste lisible et les badges ne débordent pas ;
- [ ] en RTL, le badge est du bon côté ;
- [ ] un test XCUI tape un onglet **sans** `-SnapshotInitialTab` (validation faite côté DateLimite).

---

### Lot 6 — Mesure iPad : forçage de la classe de taille

**Constat : M3 — le seul point de l'audit resté au stade de l'hypothèse.**

`traitOverrides.horizontalSizeClass = .compact` s'applique à **toute la hiérarchie enfant** sur iPad :
chaque contrôleur d'onglet croit tourner sur iPhone. Effets attendus — popovers rendus en sheets,
`UISplitViewController` imbriqués qui se collapsent, layouts adaptatifs qui basculent. DateLimite
place ce contrôleur dans le `secondary` d'un `PrimarySplitViewController`, donc en plein dedans.

Ce lot est une **mesure, pas un correctif** : comparer les écrans enfants avec et sans la ligne, sur
`3A1905DA…` (iOS 27) avec `0D6B9095…` (26.5) en témoin, puis arbitrer entre garder le forçage et
passer par `isTabBarHidden` — disponible depuis iOS 18 et aujourd'hui masqué par l'override traité
au Lot 4.

Critères de sortie :

- [ ] verdict écrit dans cette carte, captures à l'appui ;
- [ ] décision prise : forçage conservé, remplacé, ou nouveau lot ouvert.

---

### Jalons

| Jalon | Contenu | Statut |
|---|---|:---:|
| **J1 — le pod redevient testable** | Lot 0 | ✅ 2026-09-18 |
| **J2 — plus de défaut fonctionnel connu** | Lots 1, 2, 3 | ⬜ |
| **J3 — API saine** | Lot 4 | ⬜ |
| **J4 — accessible** | Lot 5 | ⬜ |
| **J5 — dernière zone d'ombre levée** | Lot 6 | ⬜ |

---

## 7. Journal

> Une entrée par session de travail : ce qui a été fait, ce qui a surpris, ce qui reste ouvert.
> Les entrées les plus récentes en haut.

### 2026-09-18 — Lot 2 livré

La fuite est confirmée **dans DateLimite**, et sa disparition aussi : un contrôleur relâché survivait
indéfiniment avant le correctif, il meurt en moins de trois secondes après. C'est le même graphe que
celui d'une fenêtre iPad fermée.

Le scénario initial — ouvrir puis fermer une seconde fenêtre par programme — a été **abandonné** :
iPadOS 27 en simulateur tue l'app dès l'ouverture de la seconde scène. Deux tentatives, même issue,
aucun rapport de crash, seulement des `Failed to commit transaction` du serveur de rendu. Plutôt que
d'insister sur un obstacle d'outillage, le test a été ramené au graphe de rétention lui-même, ce qui
a permis en prime un A/B propre en repassant le pod installé en `strong`.

Compilation de l'app vérifiée au passage : `BUILD SUCCEEDED`, 0 erreur, 0 avertissement dans le pod.

**Prochain : Lot 3**, l'unification de la sélection.

### 2026-09-18 — Lot 2 en recette

Deux lignes de correctif, mais une vérification en amont qui valait le détour : rendre un `delegate`
faible déplace la charge de rétention sur l'appelant, et si personne ne retient le delegate il meurt
aussitôt. Les deux conformeurs sont couverts — le contrôleur par sa hiérarchie de vues, le manager
de la fiche produit par le `lazy var` de son contrôleur. Rien à adapter côté app.

Le `deinit` part désormais au `dismiss`, ce qu'aucun run n'avait jamais montré. Reste la
confirmation côté DateLimite, et surtout le cas qui motivait le lot : **sur iPad, ouvrir puis fermer
une seconde fenêtre principale**. C'est là que la fuite se voyait, une scène étant un
`PTCardTabBarController` complet.

**Prochain : Lot 3**, l'unification de la sélection — le lot délicat, dont la recette est
entièrement côté app.

### 2026-09-18 — Lot 1 en recette

Cinq correctifs posés, tous vérifiés sur le banc ; reste la passe DateLimite, qui demande un
`pod update` et une main sur l'app.

Deux choses ne se sont pas passées comme prévu, et toutes deux ont amélioré le correctif :

- **le filtre `isEnabled` seul était un mauvais correctif.** Il rendait le bouton désactivé inerte,
  mais reportait le geste sur son voisin : l'utilisateur tapait la cloche grisée et déclenchait
  « ajouter à la liste de courses ». Il fallait distinguer le tap *sur* un bouton désactivé du tap
  dans la marge ;
- **un défaut non répertorié est tombé pendant la recette** : `UITabBarController` charge sa vue dès
  l'init, donc `viewDidLoad` s'exécute avant que l'appelant ait pu poser `viewControllers`, et le
  `tabBar.items!` de la ligne 108 trappe. Tout `PTCardTabBarController()` construit par code
  plantait. Consigné en **E5** dans l'audit — en addendum daté, le corps du document restant figé —
  et corrigé ici, puisque c'est un crash et que le correctif est de deux lignes.

L'audit avait classé ce forçage en simple risque au conditionnel. Il était atteignable dès l'init :
seul l'ordre des lignes de l'exemple, et l'instanciation par storyboard côté DateLimite, le
masquaient.

**Prochain : Lot 2**, le cycle de rétention.

### 2026-09-18 — Lot 0 livré

Le banc est de nouveau opérationnel : l'exemple compile sans bricolage de ligne de commande et
tourne sous iOS 27. Les lots suivants peuvent se valider ici plutôt que dans DateLimite.

Deux surprises en chemin, aucune bloquante :

- la démo de badge de l'exemple **n'avait jamais fonctionné** — `userInfo` incomplet depuis
  l'origine. Ce n'était pas dans le périmètre annoncé du lot, mais un banc dont une démo ment est
  pire qu'un banc absent ;
- `AppDelegate` gardait sa `window` et les callbacks de cycle de vie du template 2019, morts sous
  UIScene. Nettoyés, sinon l'exemple enseigne le contraire de ce qu'il montre.

Le `SceneDelegate` a demandé une édition à la main du `project.pbxproj` (projet de 2019, pas de
groupe synchronisé sur le système de fichiers). Quatre entrées ajoutées, fichier relu par
`plutil -lint` et validé par le build.

**Prochain : Lot 1**, correctifs sûrs sans rupture d'API.

### 2026-09-18 — ouverture de la carte

Audit global du pod mené sur `HEAD = de21149`, avec vérification sur pièces (simulateur iPhone 17 /
iOS 27, sonde `@available` au compilateur, en-têtes du SDK iOS 27). Quatre défauts mesurés, sept
points moyens, quinze points d'hygiène — cf. [`PTCARDTABBAR_AUDIT.md`](../reference/PTCARDTABBAR_AUDIT.md).

Deux correctifs ont été **écrits et éprouvés pendant l'audit puis défaits** avec la restauration de
l'arbre de travail : la remise en route du banc (Lot 0) et le `if finished` de **E4** (Lot 1). Ils
sont à réécrire, mais leur validité est établie.

Branche **`correctifs-audit`** créée depuis `badge` (`de21149`) et poussée avec ces docs
(`625acb5`). `badge` reste intacte. Au passage, l'identité git locale du repo a été corrigée :
elle héritait du global `lsence@fidme.com` alors que ce fork est perso — 6 des 34 commits du fork
portaient déjà la mauvaise adresse.
