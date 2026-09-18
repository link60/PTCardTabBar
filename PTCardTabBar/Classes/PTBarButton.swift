//
//  PTTabBarButtonItem.swift
//  PTR
//
//  Created by Hussein AlRyalat on 4/7/19.
//  Copyright © 2019 SketchMe. All rights reserved.
//

import UIKit
import BadgeHub

public class PTBarButton: UIButton {

    /// Cible tactile minimale recommandée. Les icônes d'une barre « carte » font une vingtaine de
    /// points de haut : sans extension, la zone sensible du bouton est deux fois trop petite.
    private static let minimumTouchTarget: CGFloat = 44

    open lazy var badge: BadgeHub = {
        return BadgeHub(view: self)
    }()

    open var badgeLayout: (PTBarButton) -> Void = { button in
        // Miroité en RTL : sans ça le badge se retrouve du côté intérieur de l'icône.
        let rtl = button.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let dx = (button.bounds.width / 2) + 8
        button.badge.setCircleAtFrame(CGRect(x: rtl ? -dx : dx, y: -25, width: 30, height: 30))
        button.badge.scaleCircleSize(by: 0.9)
        // Suit les réglages de taille de texte, plafonné pour que le badge ne dévore pas l'icône.
        let metrics = UIFontMetrics(forTextStyle: .caption1)
        button.badge.setCountLabelFont(metrics.scaledFont(for: .boldSystemFont(ofSize: 15),
                                                          maximumPointSize: 22))
    }

    var selectedColor: UIColor! = .black {
        didSet {
            reloadAppearance()
        }
    }

    var unselectedColor: UIColor! = UIColor(rgb: 0x9b9b9b) {
        didSet {
            reloadAppearance()
        }
    }

    /// Teinte d'un bouton désactivé. Sans elle, un bouton `isEnabled = false` gardait l'apparence
    /// d'un bouton actif — voire celle d'un bouton sélectionné.
    var disabledColor: UIColor! = UIColor(rgb: 0xc7c7c7) {
        didSet {
            reloadAppearance()
        }
    }

    override public var isEnabled: Bool {
        didSet {
            reloadAppearance()
            updateAccessibilityTraits()
        }
    }

    init(image: UIImage){
        super.init(frame: .zero)
        setImage(image, for: .normal)
        isAccessibilityElement = true
        updateAccessibilityTraits()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isAccessibilityElement = true
        updateAccessibilityTraits()
    }


    override public var isSelected: Bool {
        didSet {
            reloadAppearance()
            updateAccessibilityTraits()
        }
    }

    /// `showsMenuAsPrimaryAction` n'est posé que **si un menu existe**.
    ///
    /// Il l'était inconditionnellement à la construction. Avec `menu == nil`, UIKit considère alors
    /// que l'action principale est « présenter un menu » qui n'existe pas :
    /// `accessibilityActivate()` rend `false` et **VoiceOver ne peut pas activer l'onglet**.
    @available(iOS 14.0, *)
    override public var menu: UIMenu? {
        didSet {
            showsMenuAsPrimaryAction = (menu != nil)
        }
    }

    func reloadAppearance(){
        guard isEnabled else {
            self.tintColor = disabledColor
            return
        }
        self.tintColor = isSelected ? selectedColor : unselectedColor
    }

    /// Reprend le nom, l'identifiant et le badge de l'`UITabBarItem` d'origine. Sans ça les boutons
    /// n'ont aucune identité : ni VoiceOver ni XCUITest ne peuvent les désigner.
    func applyAccessibility(from item: UITabBarItem) {
        let nom = item.accessibilityLabel ?? item.title
        accessibilityLabel = (nom?.isEmpty == false) ? nom : nil
        accessibilityIdentifier = item.accessibilityIdentifier
        updateAccessibilityTraits()
    }

    private func updateAccessibilityTraits() {
        var traits: UIAccessibilityTraits = .button
        if isSelected { traits.insert(.selected) }
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }

    /// VoiceOver active un élément par ce point d'entrée. L'implémentation d'`UIControl` échouait
    /// ici (cf. `menu`) ; on déclenche l'action nous-mêmes pour que l'onglet soit atteignable.
    override public func accessibilityActivate() -> Bool {
        guard isEnabled else { return false }
        sendActions(for: .touchUpInside)
        return true
    }

    /// Étend verticalement la zone sensible jusqu'à 44 pt sans toucher au rendu : l'icône reste à
    /// sa taille, seul le bouton devient atteignable au doigt.
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let manque = max(0, Self.minimumTouchTarget - bounds.height)
        return bounds.insetBy(dx: 0, dy: -manque / 2).contains(point)
    }

    /// Même extension pour l'exploration au doigt sous VoiceOver, qui vise le cadre d'accessibilité
    /// — exprimé en coordonnées écran — et non les limites de la vue.
    override public var accessibilityFrame: CGRect {
        get {
            let manque = max(0, Self.minimumTouchTarget - bounds.height)
            let etendu = bounds.insetBy(dx: 0, dy: -manque / 2)
            return UIAccessibility.convertToScreenCoordinates(etendu, in: self)
        }
        set { super.accessibilityFrame = newValue }
    }

    /// Vrai dès qu'un badge a été posé. `badge` est un `lazy var` : appeler `badgeLayout` sans
    /// cette garde instanciait un `BadgeHub` pour **chaque** bouton, badge ou pas, et réappliquait
    /// cadre, échelle et police à chaque passe de layout.
    private var hasBadge = false

    func setBadge(value: Int) {
        hasBadge = true
        badge.setCount(value)
        badgeLayout(self)
        accessibilityValue = value > 0 ? "\(value)" : nil
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard hasBadge else { return }
        badgeLayout(self)
    }
}
