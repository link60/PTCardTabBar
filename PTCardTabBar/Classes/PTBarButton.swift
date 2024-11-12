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
            reloadApperance()
        }
    }
    
    var unselectedColor: UIColor! = UIColor(rgb: 0x9b9b9b) {
        didSet {
            reloadApperance()
        }
    }
    
    init(forItem item: UITabBarItem) {
        super.init(frame: .zero)
        setImage(item.image, for: .normal)
        if #available(iOS 14.0, *) {
            showsMenuAsPrimaryAction = true
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
            reloadApperance()
        }
    }
    
    func reloadApperance(){
        self.tintColor = isSelected ? selectedColor : unselectedColor
    }
    
    func setBadge(value: Int) {
        badge.setCount(value)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        badgeLayout(self)
    }
}
