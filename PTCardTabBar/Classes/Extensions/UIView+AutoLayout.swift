//
//  UIView+AutoLayout.swift
//  Prayer Times Reminder
//
//  Created by Hussein Al-Ryalat on 8/6/18.
//  Copyright © 2018 SketchMe. All rights reserved.
//

import UIKit

extension UIView {
    func constraint(width: CGFloat){
        prepareForAutoLayout()
        self.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func makeWidthEqualHeight(){
        prepareForAutoLayout()
        self.widthAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    func prepareForAutoLayout(){
        translatesAutoresizingMaskIntoConstraints = false
    }
}
