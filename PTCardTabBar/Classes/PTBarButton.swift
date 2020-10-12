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
    
    lazy var badge: BadgeHub = {
        return BadgeHub(view: self)
    }()
    
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
    }
    
    init(image: UIImage){
        super.init(frame: .zero)
        setImage(image, for: .normal)
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
        badge.setCircleAtFrame(CGRect(x: (self.bounds.width/2)+8, y: -25, width: 30, height: 30))
        badge.scaleCircleSize(by: 0.9)
        badge.setCountLabelFont(UIFont.boldSystemFont(ofSize: 15))
    }
}
