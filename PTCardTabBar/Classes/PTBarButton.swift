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
    
    open lazy var badge: BadgeHub = {
        return BadgeHub(view: self)
    }()
    
    open var badgeLayout: (PTBarButton) -> Void = { button in
        button.badge.setCircleAtFrame(CGRect(x: (button.bounds.width/2)+8, y: -25, width: 30, height: 30))
        button.badge.scaleCircleSize(by: 0.9)
        button.badge.setCountLabelFont(UIFont.boldSystemFont(ofSize: 15))
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
        }
    }
    
    init(image: UIImage){
        super.init(frame: .zero)
        setImage(image, for: .normal)
        if #available(iOS 14.0, *) {
            showsMenuAsPrimaryAction = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override public var isSelected: Bool {
        didSet {
            reloadAppearance()
        }
    }
    
    func reloadAppearance(){
        guard isEnabled else {
            self.tintColor = disabledColor
            return
        }
        self.tintColor = isSelected ? selectedColor : unselectedColor
    }
    
    /// Vrai dès qu'un badge a été posé. `badge` est un `lazy var` : appeler `badgeLayout` sans
    /// cette garde instanciait un `BadgeHub` pour **chaque** bouton, badge ou pas, et réappliquait
    /// cadre, échelle et police à chaque passe de layout.
    private var hasBadge = false
    
    func setBadge(value: Int) {
        hasBadge = true
        badge.setCount(value)
        badgeLayout(self)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        guard hasBadge else { return }
        badgeLayout(self)
    }
}
