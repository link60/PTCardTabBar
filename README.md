# PTCardTabBar

[![CI Status](https://img.shields.io/travis/hussc/PTCardTabBar.svg?style=flat)](https://travis-ci.org/hussc/PTCardTabBar)
[![Version](https://img.shields.io/cocoapods/v/PTCardTabBar.svg?style=flat)](https://cocoapods.org/pods/PTCardTabBar)
[![License](https://img.shields.io/cocoapods/l/PTCardTabBar.svg?style=flat)](https://cocoapods.org/pods/PTCardTabBar)
[![Platform](https://img.shields.io/cocoapods/p/PTCardTabBar.svg?style=flat)](https://cocoapods.org/pods/PTCardTabBar)


## Screenshots

1             |  2
:-------------------------:|:-------------------------:
![](Screenshots/PTCardTabBar-1.png)  |  ![](Screenshots/PTCardTabBar-2.png)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Badges

A badge is set either directly, or through a notification — useful when the code that knows the
count has no reference to the tab bar controller.

```swift
// Direct
cardTabBarController.customTabBar.setBadge(value: 3, at: 0)

// Par notification : les DEUX clés sont obligatoires, un userInfo incomplet est ignoré
// silencieusement. `index` est la position de l'onglet, `value` le compte affiché (0 efface).
NotificationCenter.default.post(
    name: .PTCardTabBarBadgeNotification,
    object: nil,
    userInfo: ["index": 0, "value": 3]
)
```

Les deux valeurs doivent être des `Int`. L'observateur est posé par
`PTCardTabBarController.viewDidLoad`, donc la notification n'a d'effet qu'une fois la vue du
contrôleur chargée.

## Requirements

## Installation

PTCardTabBar is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'PTCardTabBar'
```

## Author

hussc, hus.sc@aol.com

## License

PTCardTabBar is available under the MIT license. See the LICENSE file for more info.
