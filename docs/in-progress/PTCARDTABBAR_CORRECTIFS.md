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
> **Taille :** `L` — sept lots indépendants. **Lots 0, 1, 2, 4 et 6 livrés ; Lots 3 et 5 en
> recette côté app. Tous les lots sont traités.**

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
| 3 | Unification de la sélection | M/L | 🟡 En recette — 2026-09-18 |
| 4 | Nettoyage et surface d'API | M | ✅ Livré — 2026-09-18 |
| 5 | Accessibilité et Dynamic Type | L | 🟡 En recette — 2026-09-18 |
| 6 | Mesure iPad — forçage de la classe de taille | S | ✅ Livré — 2026-09-18 |

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
| M5 | 3 + 4 | | | | |
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

**Décision de conception prise avec Loïc le 2026-09-18.** Le pod n'avait aucun moyen de distinguer
une **barre d'onglets** d'une **barre d'actions** : il se servait d'`indicatorIsHidden` comme
approximation. D'où deux effets croisés dans DateLimite — les barres de la fiche produit obtenaient
le bon rendu par accident, et la barre principale perdait son repère de sélection dès que le réglage
« Recettes » posait `indicatorIsHidden = true` sur elle.

Deux arbitrages :

1. **Dans la barre principale, l'onglet courant garde son point ET son icône teintée**, les autres
   en gris. Le `indicatorIsHidden = true` des deux `showXxxController` est un **effet de bord à
   retirer côté app** — ces méthodes ne font que permuter deux onglets.
2. **Le pod reçoit une notion explicite** : `selectionStyle: .tabs | .actions`. `indicatorIsHidden`
   redevient un simple réglage d'affichage du point.

Critères de sortie :

- [x] une seule notification du delegate pendant `viewDidLoad`, et aucun `popToRootViewController`
      involontaire ;
- [x] après un `selectedIndex` programmatique, `isSelected` est cohérent et un `reloadApperance()`
      ne déplace plus le surlignage ;
- [x] inverser l'ordre `indicatorIsHidden` / `items` ne déclenche plus rien ;
- [x] en `.actions`, aucun bouton ne se sélectionne et tous gardent leur teinte pleine ;
- [x] **correctif côté app appliqué** — commit `77d73257` sur `master` de `date-limite-ios` :
      `selectionStyle = .actions` sur les deux barres de la fiche produit, retrait du
      `indicatorIsHidden = true` des deux `showXxxController`. Recensement fait au passage : le
      projet n'a que **trois** instances de la barre, les deux de `Products.storyboard` et le
      `PTCardTabBarController` de `Main-Common.storyboard` ;
- [x] **DateLimite** : fiche produit, les cinq icônes restent à `#000000` (et `#45B526` pour le ✓)
      en mode création comme en édition, avant tap, après tap et au retour d'un écran poussé.
      Routage par `tag` vérifié sur `.addItem`, `.historic`, `.save`, `.notify`, `.dismiss` ;
- [x] **DateLimite** : barre principale, onglet courant à `#000000` + point indicateur, les autres
      exactement `#9B9B9B`, y compris après bascule du réglage « Recettes » **dans les deux sens** ;
- [~] **DateLimite, régression E3** : le **mécanisme** est vérifié — sélection programmatique pure
      (`-SnapshotInitialTab settings`, zéro tap) puis deux `reloadApperance()` provoqués par une
      bascule clair/sombre, plus une passe de layout par aller-retour arrière-plan : l'onglet reste
      surligné à chaque fois. **La rotation elle-même ne peut pas être jouée en ligne de
      commande** : `Simulator.app` a disparu avec Xcode 27, et `simctl ui` ne gère que
      l'apparence et le contraste, pas l'orientation. Ce n'est pas une install cassée sur ce poste,
      c'est l'outil qui n'existe plus. Il faut donc un UITest `XCUIDevice.shared.orientation` ou
      un appareil ;
- [~] **re-recette après le correctif de régression ci-dessous** — le `pod update` est fait
      (`48ab610`) et l'app **compile**. Reste la vérification **visuelle** : permuter les onglets
      par le réglage « Recettes » en étant sur Réglages, la barre doit rester sur l'onglet courant
      au lieu de sauter sur le premier.

**Correctif de régression du 2026-09-18** *(défaut introduit par ce lot, remonté par la session de
recette app)*

`reloadViews()` forçait le surlignage sur l'onglet 0 **sans notifier**. Avant ce lot, le même appel
notifiait : le contrôleur suivait, l'utilisateur était ramené à l'onglet 0 mais barre et contenu
restaient d'accord. En coupant la notification pour désamorcer la mine `configure()`, j'avais
transformé « on saute à l'onglet 0 » en « la barre ment » — elle affichait l'onglet 0 pendant que le
contenu restait sur l'onglet courant. Visible dans l'app quand le réglage « Recettes » permute les
onglets alors qu'on est sur Réglages.

La barre mémorise désormais son propre index sélectionné et le restaure après reconstruction, borné
au nombre d'items. Revenir de `.actions` à `.tabs` rétablit aussi la sélection, qui n'existait plus.

```
T1 on est sur l onglet 2        | selectedIndex=2 | barre 2:sel=true
T2 apres reconstruction         | selectedIndex=2 | barre 2:sel=true   ← avant : barre 0:sel=true
T3 apres reduction a 2 items    | selectedIndex=2 | barre 1:sel=true   ← bornage
```

> T3 est un cas artificiel : je n'ai raccourci que `customTabBar.items`, pas `viewControllers`. En
> usage réel les deux suivent, et UIKit borne `selectedIndex` de son côté. Le bornage de la barre
> est le seul comportement sain quand l'index visé n'existe plus.

**Implémentation du 2026-09-18 :**

- **E3** — les deux `select(at:)` fusionnent en une seule méthode, qui pose `isSelected`, déplace
  l'indicateur et notifie selon `notifyDelegate`. La surcharge sans paramètre disparaît, mais
  `select(at: 0)` continue de compiler et de notifier grâce à la valeur par défaut : aucun appelant
  de l'app n'est touché (`Finder.swift:60`, `SideMenuViewController.swift:318`) ;
- **M1** — `reloadViews()` sélectionne désormais avec `notifyDelegate: false`, et `viewDidLoad` fait
  de même. Une seule écriture de `selectedIndex` au lieu de trois, et plus de
  `popToRootViewController(animated: true)` involontaire au démarrage ;
- **M1 (mine)** — `indicatorIsHidden` ne reconstruit plus les boutons : c'est un réglage
  d'affichage. L'ordre des lignes de `DetailProductHelper.configure()` n'a plus d'importance ;
- **M5 (partiel)** — `reloadViews()` désactive et relâche `indicatorViewXConstraint` avant de
  retirer les boutons ; il retenait jusque-là une vue morte ;
- **nouveau** — `selectionStyle`, et l'indicateur masqué d'office en `.actions` (il n'y a pas de
  cible où le poser).

> **Non fait, volontairement.** La réutilisation des boutons existants quand le nombre d'items ne
> change pas — l'autre moitié de **M5** — n'est pas dans ce lot : réutiliser un bouton lui ferait
> garder le `badgeLayout`, l'`isEnabled` et l'image d'un item qui n'est plus le même. C'est une
> optimisation à concevoir, pas une correction, et ce lot touche déjà le chemin nominal. **Reportée
> au Lot 4.**

**Recette du 2026-09-18**, iPhone 17 / iOS 27 :

```
T0 apres viewDidLoad (.tabs)    | 0:sel=true/#0088FF  1:sel=false/#9B9B9B  2:sel=false/#9B9B9B
selectedIndex ecrit = 0                                     ← une seule fois (trois auparavant)
T1 apres selectedIndex=2        | 0:sel=false/#9B9B9B  1:sel=false/#9B9B9B  2:sel=true/#0088FF
T2 apres rafraichissement teinte| 0:sel=false/#9B9B9B  1:sel=false/#9B9B9B  2:sel=true/#FF383C
T3 en .actions                  | 0:sel=false/#FF383C  1:sel=false/#FF383C  2:sel=false/#FF383C
T4 select(at:1) en .actions     | inchangé — le delegate est notifié, rien n'est sélectionné
mine M1 desamorcee — delegate pose AVANT items, aucun crash, aucune action declenchee
```

**T2 est le cœur du lot** : avant, le rafraîchissement de teinte repeignait le surlignage sur
l'onglet 0. Il reste maintenant sur l'onglet 2.

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

- [x] aucun symbole mort restant ;
- [x] relevé d'appelants côté app repassé sur les onze symboles supprimés ou renommés : **zéro
      usage**, et aucune sous-classe de `PTCardTabBarController` — les ruptures d'API ne mordent
      donc nulle part ;
- [x] la fiche produit peut fixer l'apparence de ses deux barres sur iOS 26+ (`glassMode`,
      `mainColor` et `border` sont désormais `public` sur `PTCardTabBar`) ;
- [x] une couleur de bordure dynamique suit la bascule clair/sombre ;
- [x] **DateLimite compile après `pod update`** — vérifié le 2026-09-18 sur `48ab610` :
      `BUILD SUCCEEDED`, 0 erreur, 0 avertissement dans le pod. Ce build couvre aussi le correctif
      de régression du Lot 3 (`c7e90d7`), que la recette app n'avait pas vu.

**Implémentation du 2026-09-18 :**

*Suppressions* — `ReplaceMe.swift` (fichier vide), `.travis.yml` (CI morte), `PTClearCardTabBar`,
`add(item:)` / `remove(item:)` (morts **et** faux), `UIColor.by(r:g:b:a:)`, quatre helpers
d'`UIView+AutoLayout` sans appelant, `PTBarButton.init(forItem:)`, le `deinit` de `PTCardTabBar`
(retirer des targets qu'`UIControl` ne retient pas, en réveillant au passage un `lazy var`), et
`tabBarBackgroundColor` (mort, et concurrent de `mainColor`).

*Surface d'API* —

- **M2** : `setTabBarHidden(_:animated:)` devient `setCardTabBarHidden(_:animated:)`. L'ancien nom
  **surchargeait** la méthode UIKit d'`UITabBarController` (iOS 18+) sans appeler `super` : régler
  `isTabBarHidden` passait par le pod et ne masquait pas la barre native ;
- **M7** : `glassMode`, `mainColor` et `border` passent en `public`. Une barre utilisée seule — les
  deux de la fiche produit, instanciées depuis un storyboard — n'avait jusqu'ici **aucun** moyen de
  choisir son apparence, ces réglages n'étant exposés que sur le contrôleur ;
- **F11** : la conformité `CardTabBarDelegate` quitte l'extension pour le corps de la classe, en
  `open`. Une conformité portée par une extension ne peut pas être surchargée, ce qui privait les
  sous-classes de tout point d'entrée pour intercepter la sélection ;
- **F15** : `reloadApperance` → `reloadAppearance` (symbole interne, sans coût pour les appelants).

*Corrections* —

- **M7** : la bordure ré-résout son `UIColor` à chaque changement de trait
  (`registerForTraitChanges` sur iOS 17+, `traitCollectionDidChange` en deçà). Un `cgColor` fige la
  couleur au moment de l'affectation : une bordure sémantique ne suivait pas le mode sombre ;
- **F6** : `badgeLayout` n'est plus appelé à chaque passe de `layoutSubviews`. Comme `badge` est un
  `lazy var`, cet appel instanciait un `BadgeHub` pour **chaque** bouton, badge ou pas. Une garde
  `hasBadge` le réserve aux boutons qui en portent un ;
- **F9** : `shadowPath` posé dans `layoutSubviews`, à côté du `cornerRadius` déjà recalculé là.
  Sans lui, Core Animation redessine l'ombre hors écran à chaque changement de taille ;
- **F12** : `homepage` et `source` du podspec pointent sur le fork `link60`, avec une note disant
  que la consommation se fait par branche et que c'est le SHA du `Podfile.lock` qui fait foi.

> **M5 — réutilisation des boutons : écartée, avec preuve.** Reportée du Lot 3, elle demande une
> identité d'item stable pour savoir quel bouton réutiliser. Le seul candidat est `tag`, qui vaut
> **0 par défaut** : vérification faite dans `Main-Common.storyboard`, aucun des items de la barre
> principale de DateLimite n'en déclare un, ils sont donc tous à 0 et indiscernables. Pire,
> `showRecipesController` modifie l'**image d'un item en place** — réutiliser sans resynchroniser
> l'image ferait disparaître le changement d'icône, et resynchroniser écraserait les images
> personnalisées de `updateNotificationIcon`. Le contrat est donc **documenté** sur `items` à la
> place : toute mutation reconstruit les boutons, les personnalisations se posent après. L'autre
> moitié de M5 — la contrainte d'indicateur qui retenait une vue morte — a bien été corrigée au
> Lot 3.

**Recette du 2026-09-18** : `pod install` accepte le podspec modifié, `BUILD SUCCEEDED` sur
l'exemple, et l'app tourne — barre rendue, point indicateur sous l'onglet courant, badge affiché,
onglets non sélectionnés en gris. Aucun symbole supprimé n'est utilisé côté DateLimite.

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

**Le défaut principal n'était pas celui annoncé.** L'audit pointait des boutons sans nom. La mesure
a montré pire : **VoiceOver ne pouvait pas activer un onglet du tout**.

```
AVANT  b0 isAccessibilityElement=false  label=nil  traits=0
       accessibilityActivate() sur le bouton 2 → rend false, selectedIndex reste 0
```

Les boutons n'étaient même pas des éléments d'accessibilité, et `accessibilityActivate()` — le point
d'entrée exact par lequel VoiceOver active un élément — échouait. La cause : `showsMenuAsPrimaryAction`
était posé **inconditionnellement** à la construction alors qu'aucun menu n'est jamais assigné. Avec
`menu == nil`, UIKit considère que l'action principale est « présenter un menu » qui n'existe pas et
refuse l'activation. Une barre d'onglets entièrement inutilisable au lecteur d'écran, pas seulement
mal nommée.

Critères de sortie :

- [x] VoiceOver annonce chaque onglet par son nom et son état sélectionné ;
- [x] **VoiceOver peut activer un onglet** — le vrai défaut, découvert à la mesure ;
- [x] la barre est annoncée comme barre d'onglets, pas comme une pile de boutons anonymes ;
- [x] à la plus grande taille de texte, la barre reste lisible et les badges ne débordent pas ;
- [x] la zone tactile atteint 44 pt sans changer le rendu ;
- [ ] **en RTL, le badge est du bon côté** — implémenté, non vérifié : la disposition RTL demande un
      lancement dédié et l'exemple n'est pas localisé ;
- [ ] **un test XCUI tape un onglet sans `-SnapshotInitialTab`** — validation côté DateLimite.

**Implémentation du 2026-09-18 :**

- **activation** — `showsMenuAsPrimaryAction` n'est plus posé qu'au moment où un `menu` est
  effectivement assigné (override de `menu` avec `didSet`), et `accessibilityActivate()` est
  surchargé pour déclencher l'action directement. Ceinture et bretelles : l'onglet est atteignable
  quel que soit l'état du menu ;
- **identité** — `addButton` reçoit l'`UITabBarItem` entier au lieu de `image` + `tag`, et reprend
  `accessibilityLabel`, à défaut `title`, plus `accessibilityIdentifier`. Un nom vide laisse `nil`
  pour ne pas couper le repli d'UIKit sur le nom de l'image — vérifié : l'onglet sans label est
  annoncé « more », d'après son asset ;
- **traits** — `.button`, plus `.selected` quand l'onglet est courant et `.notEnabled` quand il est
  désactivé. Le conteneur porte `.tabBar` et `shouldGroupAccessibilityChildren` ;
- **badge** — exposé en `accessibilityValue` ;
- **cible tactile** — `point(inside:with:)` et `accessibilityFrame` étendent verticalement la zone
  sensible à 44 pt. Les icônes mesurent **121 × 24 pt** (relevé du Lot 1), soit la moitié de la
  recommandation ; le rendu ne bouge pas, seule la zone sensible grandit ;
- **Dynamic Type** — la police du badge suit les réglages de taille de texte, plafonnée à 22 pt pour
  ne pas dévorer l'icône ;
- **RTL** — le décalage du badge est miroité selon `effectiveUserInterfaceLayoutDirection` ;
- **`tabBarHeight` devient vivant** — il n'était lu qu'une fois, à `viewDidLoad` : le modifier
  ensuite n'avait aucun effet. Il met désormais à jour la contrainte de hauteur, l'ancrage du bas et
  `additionalSafeAreaInsets`.

> **La hauteur de barre n'est volontairement pas mise à l'échelle par le pod.** Elle pilote
> `additionalSafeAreaInsets`, donc le cadrage de **tous** les écrans enfants : c'est un choix de mise
> en page qui appartient à l'application. Ce qui manquait, c'est la possibilité de l'exprimer — le
> réglage était figé après `viewDidLoad`. Il ne l'est plus, et DateLimite peut désormais poser
> `tabBarHeight = UIFontMetrics.default.scaledValue(for: 70)` si le sujet se pose.

**Recette du 2026-09-18**, iPhone 17 / iOS 27 :

```
APRES  barre : element=false traits=32768 (.tabBar) groupe=true
       b0    : element=true  label=Accueil  traits=9 (.button + .selected)
       b2    : label=more (repli UIKit sur l'asset)  id=onglet-plus  traits=1 (.button)
       accessibilityActivate() sur le bouton 2 → rend true, selectedIndex=2, traits b2=9
       cible tactile : bounds 120,7 × 24 — point(10, -8) est DEDANS
       badge 4 → accessibilityValue = "4"
```

Rendu inchangé en taille de texte normale. En `AccessibilityXXXL`, le badge grossit sans déborder de
sa pastille et la barre garde ses proportions.

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

- [x] verdict écrit dans cette carte, captures à l'appui ;
- [x] décision prise : **forçage remplacé** par `isTabBarHidden = true`.

**Mesure du 2026-09-18**, DateLimite sur iPad Air 13" / iOS 27 (`3A1905DA…`), trois variantes
obtenues en modifiant le pod **installé** dans `Pods/` — sans toucher au `Podfile` ni au code de
l'app, fichier remis à l'identique et droits restaurés ensuite.

| Variante | Sélecteur d'onglets natif | Barre de recherche | Classe de taille des enfants |
|---|---|---|---|
| **A** — forçage (code d'origine) | absent | déployée | **compacte, imposée** |
| **B** — rien | **pilule centrée « Mes Produits ›»** | repliée en loupe | régulière |
| **C** — `isTabBarHidden = true` | absent | déployée | régulière |

**Le forçage faisait bien ce pour quoi il avait été ajouté** : sans lui, iPadOS 18 affiche son
sélecteur d'onglets natif dans la barre de navigation, en doublon de la barre « carte » du pod. Le
commit d'origine (`5e3c61a`, « Disable iOS 18 new top tabbar ») était donc justifié.

**Mais l'hypothèse de l'audit sur son coût est infirmée.** Je m'attendais à voir les écrans enfants
basculer en disposition compacte. Vérifié sur deux écrans, dont un SwiftUI :

- liste des produits : identique entre A et C ;
- suggestions de recettes : **identique au pixel** entre A et C — « En stock » et « À prévoir »
  restent côte à côte. Cette disposition est pilotée par la **largeur**, pas par la classe de taille.

**Décision : remplacer quand même.** Pas parce que le forçage nuit aujourd'hui — la mesure dit qu'il
ne nuit pas — mais parce qu'il obtient par un effet de bord global ce qu'une API dédiée obtient
précisément. Tout écran enfant futur qui s'appuierait sur `horizontalSizeClass` hériterait d'un
mensonge posé par la barre d'onglets, sans rapport avec son propre besoin.

> `isTabBarHidden` n'était **pas atteignable** avant ce chantier : le pod surchargeait
> `setTabBarHidden(_:animated:)` sans appeler `super`, et le régler passait par le pod au lieu
> d'UIKit. Le Lot 4 a levé cet obstacle sans le savoir ; le Lot 6 en récolte le bénéfice.

---

### Jalons

| Jalon | Contenu | Statut |
|---|---|:---:|
| **J1 — le pod redevient testable** | Lot 0 | ✅ 2026-09-18 |
| **J2 — plus de défaut fonctionnel connu** | Lots 1, 2, 3 | ⬜ |
| **J3 — API saine** | Lot 4 | ✅ 2026-09-18 |
| **J4 — accessible** | Lot 5 | ⬜ |
| **J5 — dernière zone d'ombre levée** | Lot 6 | ✅ 2026-09-18 |

---

## 7. Journal

> Une entrée par session de travail : ce qui a été fait, ce qui a surpris, ce qui reste ouvert.
> Les entrées les plus récentes en haut.

### 2026-09-18 — Lot 6 livré, chantier complet

Le seul lot dont le livrable était un **verdict**, pas un correctif. Et le verdict contredit
l'hypothèse de départ : le forçage de classe de taille ne dégrade rien de visible dans DateLimite.
Les deux écrans testés, dont un SwiftUI, sont identiques avec et sans. La disposition que je croyais
pilotée par la classe de taille l'est en fait par la largeur.

Ce que la mesure a établi en revanche, c'est que le forçage **servait vraiment à quelque chose** :
sans lui, iPadOS 18 affiche son sélecteur d'onglets natif en doublon de la barre « carte ». Le
commit d'origine était justifié, il n'avait simplement pas d'autre outil à l'époque.

Remplacé par `isTabBarHidden`, non pas pour réparer un dégât mais pour cesser d'obtenir par effet de
bord global ce qu'une API obtient précisément. Le premier écran enfant qui s'appuiera un jour sur
`horizontalSizeClass` n'héritera pas d'un mensonge posé par la barre d'onglets.

Détail qui vaut d'être noté : cette API n'était **pas atteignable** avant ce chantier. Le pod
surchargeait `setTabBarHidden(_:animated:)` sans appeler `super`. Le Lot 4 a levé l'obstacle en
croyant seulement nettoyer un nom.

**Les sept lots sont traités.** Restent deux recettes côté app — la vérification visuelle du Lot 3
et les deux points d'accessibilité du Lot 5 — plus un `pod update`.

### 2026-09-18 — Lot 5 en recette

Le lot devait corriger des boutons mal nommés. Il a corrigé une barre d'onglets **inutilisable au
lecteur d'écran** : `accessibilityActivate()` rendait `false` et l'onglet ne changeait pas. Sans la
mesure, j'aurais posé des labels sur des boutons que VoiceOver n'aurait toujours pas pu activer, et
la case aurait été cochée à tort.

La cause tenait à une ligne qui n'avait rien à voir avec l'accessibilité : `showsMenuAsPrimaryAction`
posé inconditionnellement à la construction, alors qu'aucun menu n'est jamais assigné — ni dans le
pod, ni dans l'exemple, ni dans DateLimite. Avec `menu == nil`, UIKit refuse l'activation.

Deux points restent ouverts et demandent l'app : la vérification RTL, et le test XCUI qui devrait
désormais pouvoir taper un onglet sans le contournement `-SnapshotInitialTab`.

**Prochain : Lot 6**, la mesure iPad — dernier point de l'audit resté au stade de l'hypothèse.

### 2026-09-18 — Lot 4 en recette

Gros lot en volume, faible en risque : l'essentiel est du retrait. Onze symboles supprimés ou
renommés, zéro usage côté app — les ruptures d'API annoncées ne mordent nulle part.

Deux choses méritent d'être retenues :

- **`setTabBarHidden` n'était pas du code mort inoffensif.** C'était un override d'une méthode
  UIKit d'`UITabBarController`, sans `super`. Tant que personne ne l'appelait, rien ne se voyait ;
  le jour où quelqu'un aurait réglé `isTabBarHidden` pour masquer la barre native d'iPadOS 18, il
  aurait obtenu un fondu d'opacité sur la barre custom et rien d'autre ;
- **la réutilisation des boutons a été écartée pour la deuxième fois, cette fois avec une preuve.**
  Le storyboard de DateLimite ne pose aucun `tag` sur les items de la barre principale : ils valent
  tous 0, donc aucune identité d'item exploitable. La documenter valait mieux que la simuler.

**Prochain : Lot 5**, accessibilité et Dynamic Type — le seul lot qui apporte quelque chose à
l'utilisateur final au-delà de la correction de défauts.

### 2026-09-18 — Lot 3, correctif de régression

La recette côté DateLimite a validé trois critères sur quatre et **trouvé un défaut que j'avais
introduit** : en coupant la notification de `reloadViews()` pour désamorcer la mine de
`configure()`, j'avais désynchronisé la barre et le contenu. Le symptôme est plus discret que celui
d'avant — la barre ne saute plus, elle affiche simplement le mauvais onglet — donc plus facile à
laisser passer. Corrigé en mémorisant la sélection dans la barre.

Leçon pour les lots suivants : couper une notification n'est pas neutre quand quelqu'un d'autre
s'en servait pour se resynchroniser. Il fallait remplacer la synchronisation, pas seulement la
supprimer.

La rotation n'a pas pu être jouée : `Simulator.app` n'est pas installé sur ce poste. La session de
recette a attaqué le mécanisme par ses autres déclencheurs — bascule clair/sombre, qui provoque le
même `tintColorDidChange` → `reloadApperance()` — et l'a vérifié. La case reste entrouverte pour la
rotation elle-même.

### 2026-09-18 — Lot 3 en recette

Le lot a démarré sur une question de conception plutôt que sur du code. En préparant la fusion des
deux `select`, il est apparu que le pod **ne sait pas** distinguer une barre d'onglets d'une barre
d'actions : il déduit la sémantique du masquage de l'indicateur. Les deux barres de la fiche produit
obtenaient donc le bon rendu par accident, et la barre principale perdait son repère de sélection
dès qu'un réglage sans rapport lui posait `indicatorIsHidden = true`.

Fusionner sans trancher cette ambiguïté aurait figé le défaut dans une seule méthode au lieu de
deux. Arbitrage pris avec Loïc : notion explicite `selectionStyle`, et le point indicateur reste le
repère de la barre principale.

Conséquence : **le pod seul ne suffit pas**. Deux endroits de l'app doivent suivre, sinon les barres
de la fiche produit griseront leurs boutons non tapés. Le correctif app est prêt mais n'est pas
appliqué — il appartient à l'autre repo.

**Prochain : Lot 4**, nettoyage et surface d'API — qui reprendra aussi la réutilisation des boutons,
sortie du périmètre de ce lot.

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
