//
//  TabBarControllerViewController.swift
//  SketchNUR
//
//  Created by Hussein Al-Ryalat on 11/12/18.
//  Copyright © 2018 SketchMe. All rights reserved.
//

import UIKit

open class PTCardTabBarController: UITabBarController {
    
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
    
    open lazy var customTabBar: PTCardTabBar = {
        return PTCardTabBar(glassMode: self.glassMode)
    }()
    
    open func hideTabBar() {
        UIView.animate(withDuration: 0.3, animations: {
            self.customTabBar.alpha = 0
        }, completion:  { _ in
            self.customTabBar.isHidden = true
        })
    }
    
    @objc open func showTabBar() {
        self.customTabBar.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.customTabBar.alpha = 1
        }, completion: nil)
    }
    
    fileprivate(set) lazy var smallBottomView: UIView = {
        let anotherSmallView = UIView()
        anotherSmallView.backgroundColor = .clear
        anotherSmallView.translatesAutoresizingMaskIntoConstraints = false
        
        return anotherSmallView
    }()
    
    override open var selectedIndex: Int {
        didSet {
            customTabBar.select(at: selectedIndex, notifyDelegate: false)
        }
    }
    
    override open var selectedViewController: UIViewController? {
        didSet {
            customTabBar.select(at: selectedIndex, notifyDelegate: false)
        }
    }
    
    @IBInspectable public var bottomSpacing: CGFloat = 20
    @IBInspectable public var tabBarHeight: CGFloat = 70
    @IBInspectable public var leftSpacing: CGFloat = 20
    @IBInspectable public var rightSpacing: CGFloat = 20
    @IBInspectable public var glassMode: Int = 0
    
    fileprivate var leadingConstraint: NSLayoutConstraint!
    fileprivate var trailingConstraint: NSLayoutConstraint!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: tabBarHeight + bottomSpacing, right: 0)
        }
        
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            traitOverrides.horizontalSizeClass = .compact
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(setBadge), name: .PTCardTabBarBadgeNotification, object: nil)
        
        self.tabBar.isHidden = true
        
        addAnotherSmallView()
        setupTabBar()
        
        customTabBar.items = tabBar.items!
        customTabBar.select(at: selectedIndex)
    }
    
    public override func setTabBarHidden(_ isHidden: Bool, animated: Bool){
        let block = {
            self.customTabBar.alpha = isHidden ? 0 : 1
            self.additionalSafeAreaInsets = isHidden ? .zero : UIEdgeInsets(top: 0, left: 0, bottom: self.tabBarHeight + self.bottomSpacing, right: 0)
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: block)
        } else {
            block()
        }
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
    
    fileprivate func setupTabBar() {
        customTabBar.delegate = self
        self.view.addSubview(customTabBar)
        
        customTabBar.bottomAnchor.constraint(equalTo: smallBottomView.topAnchor, constant: 0).isActive = true
        customTabBar.heightAnchor.constraint(equalToConstant: tabBarHeight).isActive = true
        
        leadingConstraint = customTabBar.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: leftSpacing)
        leadingConstraint.isActive = true
        
        trailingConstraint = customTabBar.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -rightSpacing)
        trailingConstraint.isActive = true
        
        self.view.bringSubviewToFront(customTabBar)
        self.view.bringSubviewToFront(smallBottomView)
        
        customTabBar.glassMode = glassMode
        customTabBar.tintColor = tintColor
    }
    
    @objc open func redrawCustomTabBar(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.leadingConstraint.constant = self.leftSpacing
                self.trailingConstraint.constant = -self.rightSpacing
                self.customTabBar.updateConstraints()
                self.customTabBar.updateConstraintsIfNeeded()
                self.view.layoutIfNeeded()
            }
        } else {
            self.leadingConstraint.constant = self.leftSpacing
            self.trailingConstraint.constant = -self.rightSpacing
            self.customTabBar.updateConstraints()
            self.customTabBar.updateConstraintsIfNeeded()
            self.view.layoutIfNeeded()
        }
    }
    
    @objc fileprivate func setBadge(_ notification: Notification) {
        if  let index = notification.userInfo?["index"] as? Int,
            let value = notification.userInfo?["value"] as? Int {
            customTabBar.setBadge(value: value, at: index)
        }
    }
}

extension PTCardTabBarController: CardTabBarDelegate {
    public func cardTabBar(_ sender: PTCardTabBar, didSelectItemAt index: Int, button: PTBarButton) {
        if self.selectedIndex == index {
            if selectedViewController != nil && selectedViewController!.isKind(of: UINavigationController.self) {
                (selectedViewController as! UINavigationController).popToRootViewController(animated: true)
            }
        }
        self.selectedIndex = index
    }
}

public extension Notification.Name {
    static let PTCardTabBarBadgeNotification = Notification.Name("PTCardTabBarBadgeNotification")
}
