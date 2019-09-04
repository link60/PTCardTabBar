//
//  TabBarControllerViewController.swift
//  SketchNUR
//
//  Created by Hussein Al-Ryalat on 11/12/18.
//  Copyright © 2018 SketchMe. All rights reserved.
//

import UIKit

public class PTTabBarController: UITabBarController {
    
    
    @IBInspectable public var tintColor: UIColor? {
        didSet {
            customTabBar.tintColor = tintColor
            customTabBar.reloadApperance()
        }
    }
    
    @IBInspectable public var tabBarBackgroundColor: UIColor? {
        didSet {
            customTabBar.backgroundColor = tabBarBackgroundColor
            customTabBar.reloadApperance()
        }
    }
    
    lazy var customTabBar: PTCardTabBar = {
        return PTCardTabBar()
    }()
    
    fileprivate lazy var smallBottomView: UIView = {
        let anotherSmallView = UIView()
        anotherSmallView.backgroundColor = .clear
        anotherSmallView.translatesAutoresizingMaskIntoConstraints = false

        return anotherSmallView
    }()
    
    override public var selectedIndex: Int {
        didSet {
            customTabBar.select(at: selectedIndex, notifyDelegate: false)
        }
    }

    override public var selectedViewController: UIViewController? {
        didSet {
            customTabBar.select(at: selectedIndex, notifyDelegate: false)
        }
    }
    
    fileprivate var bottomSpacing: CGFloat = 20
    fileprivate var tabBarHeight: CGFloat = 70
    fileprivate var horizontleSpacing: CGFloat = 20
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: tabBarHeight + bottomSpacing, right: 0)
        }
        
        
        self.tabBar.isHidden = true

        addAnotherSmallView()
        setupTabBar()
        
        customTabBar.items = tabBar.items!
        customTabBar.select(at: selectedIndex)
    }
    
    fileprivate func addAnotherSmallView(){
        self.view.addSubview(smallBottomView)
        
        smallBottomView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        
        let cr: NSLayoutConstraint
        
        if #available(iOS 11.0, *) {
            cr = smallBottomView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: tabBarHeight)
        } else {
            cr = smallBottomView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: tabBarHeight)
        }
        
        cr.priority = .defaultHigh
        cr.isActive = true
        
        smallBottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        smallBottomView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    fileprivate func setupTabBar(){
        customTabBar.delegate = self
        self.view.addSubview(customTabBar)
        
        customTabBar.bottomAnchor.constraint(equalTo: smallBottomView.topAnchor, constant: 0).isActive = true
        customTabBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        customTabBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: horizontleSpacing).isActive = true
        customTabBar.heightAnchor.constraint(equalToConstant: tabBarHeight).isActive = true
        
        self.view.bringSubview(toFront: customTabBar)
        self.view.bringSubview(toFront: smallBottomView)
        
        customTabBar.tintColor = tintColor
    }
}

extension PTTabBarController: CardTabBarDelegate {
    func cardTabBar(_ sender: PTCardTabBar, didSelectItemAt index: Int) {
        self.selectedIndex = index
    }
}
