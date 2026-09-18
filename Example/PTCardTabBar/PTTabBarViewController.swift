//
//  PTTabBarViewController.swift
//  PTCardTabBar_Example
//
//  Created by Selwan IOS on 9/11/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import PTCardTabBar

class PTTabBarViewController: PTCardTabBarController {

    override func viewDidLoad() {
        let vc1 = LabelViewController(title: "Home")
        let vc2 =  LabelViewController(title: "Calendar")
        let vc3 = LabelViewController(title: "More")
        
        vc1.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "home"), tag: 1)
        vc2.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "calendar"), tag: 2)
        vc3.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "more"), tag: 3)
        
        self.viewControllers = [vc1, vc2, vc3]
        
        // Le userInfo doit porter les DEUX clés : sans "value", PTCardTabBarController.setBadge
        // sort sans rien faire et le badge de démo ne s'affiche jamais.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            NotificationCenter.default.post(name: .PTCardTabBarBadgeNotification,
                                            object: nil,
                                            userInfo: ["index": 0, "value": 3])
        }
        
        
        super.viewDidLoad()
    }
}
