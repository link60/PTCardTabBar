//
//  SceneDelegate.swift
//  PTCardTabBar_Example
//
//  Ajouté le 2026-09-18 : depuis iOS 26/27, UIKit ne tolère plus une app qui n'a pas adopté le
//  cycle de vie UIScene. Sans le manifeste `UIApplicationSceneManifest` et ce délégué, l'exemple
//  était tué au lancement par `_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`
//  (EXC_BREAKPOINT) — le pod n'avait donc plus de banc de validation.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}
