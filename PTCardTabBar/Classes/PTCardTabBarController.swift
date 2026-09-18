//
//  TabBarControllerViewController.swift
//  SketchNUR
//
//  Created by Hussein Al-Ryalat on 11/12/18.
//  Copyright © 2018 SketchMe. All rights reserved.
//

import UIKit

open class PTCardTabBarController: UITabBarController, CardTabBarDelegate {
    
    @IBInspectable public var tintColor: UIColor? {
        didSet {
            customTabBar.tintColor = tintColor
            customTabBar.reloadAppearance()
        }
    }
    
    open lazy var customTabBar: PTCardTabBar = {
        return PTCardTabBar(glassMode: self.glassMode)
    }()
    
    open func hideTabBar() {
        UIView.animate(withDuration: 0.3, animations: {
            self.customTabBar.alpha = 0
        }, completion: { finished in
            // Un showTabBar() arrivé pendant les 0,3 s interrompt cette animation, et sa completion
            // est alors appelée avec finished == false. Sans ce test, elle masquait une barre qu'on
            // venait de réafficher : alpha à 1 mais isHidden, donc invisible et non interactive.
            guard finished else { return }
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
    @IBInspectable public var glassMode: Int = 0 {
        didSet {
            customTabBar.glassMode = glassMode
        }
    }
    @IBInspectable public var mainColor: UIColor = .tertiarySystemBackground  {
        didSet {
            customTabBar.mainColor = mainColor
        }
    }
    
    public var border: (UIColor, Int) = (.clear, 0) {
        didSet {
            customTabBar.border = border
        }
    }
    
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
        
        // UITabBarController charge sa vue dès l'init, donc ce viewDidLoad s'exécute avant que
        // l'appelant ait pu poser `viewControllers` : `tabBar.items` est alors nil, et le forçage
        // faisait planter tout PTCardTabBarController() construit par code.
        customTabBar.items = tabBar.items ?? []
        // notifyDelegate: false — le contrôleur connaît déjà son index. Notifier ici relançait
        // cardTabBar(_:didSelectItemAt:), donc un popToRootViewController animé en plein viewDidLoad.
        customTabBar.select(at: selectedIndex, notifyDelegate: false)
    }
    
    /// Masque ou réaffiche la barre en ajustant aussi `additionalSafeAreaInsets`, donc en
    /// redimensionnant les vues enfants — contrairement à `hideTabBar()` / `showTabBar()`, qui ne
    /// jouent que sur l'opacité.
    ///
    /// Anciennement `setTabBarHidden(_:animated:)`, ce qui **surchargeait** la méthode UIKit du
    /// même nom (`UITabBarController`, iOS 18+) sans appeler `super` : régler `isTabBarHidden`
    /// passait par ici et ne masquait donc pas la barre native.
    open func setCardTabBarHidden(_ isHidden: Bool, animated: Bool) {
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
        
        // On ancre sur la barre, pas sur SON safeAreaLayoutGuide : celui-ci se déduit de la
        // position de la barre, qui dépend de cette contrainte — une dépendance circulaire que le
        // moteur ne résout qu'en multipliant les passes de layout. La barre ne touchant aucun bord
        // d'écran, ses insets sont nuls et le résultat géométrique est identique.
        leadingConstraint = customTabBar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: leftSpacing)
        leadingConstraint.isActive = true
        
        trailingConstraint = customTabBar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -rightSpacing)
        trailingConstraint.isActive = true
        
        self.view.bringSubviewToFront(customTabBar)
        self.view.bringSubviewToFront(smallBottomView)
        
        customTabBar.glassMode = glassMode
        customTabBar.tintColor = tintColor
    }
    
    @objc open func redrawCustomTabBar(animated: Bool) {
        // Les contraintes sont posées par setupTabBar(), donc depuis viewDidLoad : appelé avant
        // chargement de la vue, ce qui suit déréférencerait deux optionnels nuls.
        guard isViewLoaded, leadingConstraint != nil, trailingConstraint != nil else { return }
        
        // On solde le layout en attente HORS du bloc : sinon l'animation embarque tout ce qui
        // traînait d'invalidé dans la hiérarchie, contrôleurs enfants compris, au lieu du seul
        // déplacement de la barre. Le layoutIfNeeded du bloc doit rester sur self.view : c'est
        // l'ancêtre commun sur lequel les deux contraintes sont installées.
        view.layoutIfNeeded()
        
        leadingConstraint.constant = leftSpacing
        trailingConstraint.constant = -rightSpacing
        
        guard animated else {
            view.layoutIfNeeded()
            return
        }
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc fileprivate func setBadge(_ notification: Notification) {
        if  let index = notification.userInfo?["index"] as? Int,
            let value = notification.userInfo?["value"] as? Int {
            customTabBar.setBadge(value: value, at: index)
        }
    }
    
    /// Déclarée dans le corps de la classe, et non dans une extension : une conformité portée par
    /// une extension ne peut pas être surchargée, ce qui privait les sous-classes de tout point
    /// d'entrée pour intercepter la sélection — cas classique d'un onglet central qui doit
    /// présenter une modale au lieu de changer d'onglet.
    open func cardTabBar(_ sender: PTCardTabBar, didSelectItemAt index: Int, button: PTBarButton) {
        if selectedIndex == index,
           let navigation = selectedViewController as? UINavigationController {
            navigation.popToRootViewController(animated: true)
        }
        selectedIndex = index
    }
}

public extension Notification.Name {
    static let PTCardTabBarBadgeNotification = Notification.Name("PTCardTabBarBadgeNotification")
}
