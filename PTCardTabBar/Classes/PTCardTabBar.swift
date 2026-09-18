//
//  CardTabBar.swift
//  PTR
//
//  Created by Hussein AlRyalat on 8/30/19.
//  Copyright © 2019 SketchMe. All rights reserved.
//

import UIKit

/// Contraint aux classes (`AnyObject`) pour que `PTCardTabBar.delegate` puisse être `weak` :
/// sans ça, la barre retenait fortement son delegate. Un `PTCardTabBarController` se déclarant
/// lui-même delegate de sa propre barre ne pouvait alors jamais être désalloué.
public protocol CardTabBarDelegate: AnyObject {
    func cardTabBar(_ sender: PTCardTabBar, didSelectItemAt index: Int, button: PTBarButton)
}

public class PTClearCardTabBar: PTCardTabBar {
    override var glassMode: Int {
        get { 1 }
        set { super.glassMode = 1 }
    }
}

public class PTCardTabBar: UIView {
    
    public weak var delegate: CardTabBarDelegate?
    
    var effectView: UIVisualEffectView? = nil
    
    var glassMode: Int = 0 {
        didSet {
            if #available(iOS 26.0, *) {
                self.effectView?.effect = UIGlassEffect(style: UIGlassEffect.Style(rawValue: self.glassMode) ?? .regular)
            }
        }
    }
    
    var mainColor: UIColor = .tertiarySystemBackground {
        didSet {
            if #available(iOS 26.0, *) {} else {
                self.backgroundColor = self.mainColor
            }
        }
    }
    
    var border: (UIColor, Int) = (.clear, 0) {
        didSet {
            self.layer.borderColor = self.border.0.cgColor
            self.layer.borderWidth = CGFloat(self.border.1)
        }
    }
    
    open var items: [UITabBarItem] = [] {
        didSet {
            reloadViews()
        }
    }
    
    override open func tintColorDidChange() {
        super.tintColorDidChange()
        reloadApperance()
    }
    
    func reloadApperance() {
        
        buttons().forEach { button in
            button.selectedColor = tintColor
        }
        
        indicatorView.tintColor = tintColor
    }
    
    open func setBadge(value: Int, at: Int) {
        if let button = buttons()[safe: at] {
            button.setBadge(value: value)
        }
    }
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        
        return stackView
    }()
    
    
    lazy var indicatorView: PTIndicatorView = {
        let view = PTIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.constraint(width: 5)
        view.backgroundColor = tintColor
        view.makeWidthEqualHeight()
        
        return view
    }()
    
    public var indicatorIsHidden = false {
        didSet {
            indicatorView.isHidden = indicatorIsHidden
            reloadViews()
        }
    }
    
    
    private var indicatorViewYConstraint: NSLayoutConstraint!
    private var indicatorViewXConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public init(glassMode: Int) {
        super.init(frame: .zero)
        self.glassMode = glassMode
        setup()
    }
    
    deinit {
        stackView.arrangedSubviews.forEach {
            if let button = $0 as? UIControl {
                button.removeTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            }
        }
    }
    
    private func setup(){
        translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 26.0, *) {
            self.backgroundColor = .clear
            let effectView = UIVisualEffectView(effect: UIGlassEffect(style: UIGlassEffect.Style(rawValue: self.glassMode) ?? .regular))
            effectView.frame = bounds
            effectView.layer.cornerRadius = bounds.size.width / 2
            addSubview(effectView)
            self.effectView = effectView
            
        } else {
            self.backgroundColor = self.mainColor
        }
        
        addSubview(stackView)
        addSubview(indicatorView)
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 3, height: 3)
        self.layer.shadowRadius = 6
        self.layer.shadowOpacity = 0.15
        
        tintColorDidChange()
    }
    
    func add(item: UITabBarItem){
        self.items.append(item)
        self.addButton(with: item.image!, tag: item.tag)
    }
    
    func remove(item: UITabBarItem){
        if let index = self.items.firstIndex(of: item) {
            self.items.remove(at: index)
            let view = self.stackView.arrangedSubviews[index]
            self.stackView.removeArrangedSubview(view)
        }
    }
    
    private func addButton(with image: UIImage, tag: Int = 0){
        let button = PTBarButton(image: image)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = tag
        button.selectedColor = tintColor
        if indicatorIsHidden {
            button.unselectedColor = tintColor
        }
        button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
        self.stackView.addArrangedSubview(button)
    }
    
    open func select(at index: Int, notifyDelegate: Bool = true){
        var btn: PTBarButton!
        for (bIndex, view) in stackView.arrangedSubviews.enumerated() {
            if let button = view as? PTBarButton {
                button.tintColor = bIndex == index ? tintColor : UIColor(rgb: 0x9b9b9b)
                if bIndex == index {
                    btn = button
                }
            }
        }
        
        if notifyDelegate {
            self.delegate?.cardTabBar(self, didSelectItemAt: index, button: btn)
        }
    }
    
    
    open func reloadViews(){
        indicatorViewYConstraint?.isActive = false
        indicatorViewYConstraint = indicatorView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: -10.5)
        indicatorViewYConstraint.isActive = true
        
        for button in (stackView.arrangedSubviews.compactMap { $0 as? PTBarButton }) {
            stackView.removeArrangedSubview(button)
            button.removeFromSuperview()
            button.removeTarget(self, action: nil, for: .touchUpInside)
        }
        
        for item in items {
            if let image = item.image {
                addButton(with: image, tag: item.tag)
            } else {
                addButton(with: UIImage(), tag: item.tag)
            }
        }
        if !indicatorIsHidden {
            select(at: 0)
        }
    }
    
    
    
    private func buttons() -> [PTBarButton] {
        return stackView.arrangedSubviews.compactMap { $0 as? PTBarButton }
    }
    
    open func button(at index: Int) -> PTBarButton? {
        buttons()[safe: index]
    }
    
    open func select(at index: Int){
        /* move the indicator view */
        if indicatorViewXConstraint != nil {
            indicatorViewXConstraint.isActive = false
            indicatorViewXConstraint = nil
        }
        
        var btn: PTBarButton!
        for (bIndex, button) in buttons().enumerated() {
            button.selectedColor = tintColor
            button.isSelected = bIndex == index
            
            if bIndex == index {
                btn = button
                indicatorViewXConstraint = indicatorView.centerXAnchor.constraint(equalTo: button.centerXAnchor)
                indicatorViewXConstraint.isActive = true
            }
        }
        
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
        
        // Aucun bouton à cet index — barre encore vide, ou index hors bornes. Notifier ferait
        // passer un PTBarButton! nul à un paramètre non optionnel, donc trap à l'appel.
        guard let btn = btn else { return }
        self.delegate?.cardTabBar(self, didSelectItemAt: index, button: btn)
    }
    
    
    @objc func buttonTapped(sender: PTBarButton){
        if let index = stackView.arrangedSubviews.firstIndex(of: sender){
            select(at: index)
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let position = touches.first?.location(in: self) else {
            super.touchesEnded(touches, with: event)
            return
        }
        
        // Les boutons vivent dans la stack view : on ramène leurs cadres dans le repère de la
        // barre avant toute comparaison avec `position`.
        let frames = self.stackView.arrangedSubviews
            .compactMap { $0 as? PTBarButton }
            .filter { !$0.isHidden }
            .map { (button: $0, frame: self.convert($0.bounds, from: $0)) }
        
        // Un bouton désactivé ne consomme pas le touch, qui remonte donc jusqu'ici. Un tap qui
        // tombe SUR lui ne doit rien déclencher — surtout pas l'action du voisin le plus proche.
        if let touched = frames.first(where: { $0.frame.contains(position) }), !touched.button.isEnabled {
            super.touchesEnded(touches, with: event)
            return
        }
        
        // Ailleurs dans la barre — marges, interstices — on active le bouton actif le plus proche,
        // ce qui élargit la zone tactile à toute la capsule.
        let closest = frames.filter { $0.button.isEnabled }.min {
            CGPoint(x: $0.frame.midX, y: $0.frame.midY).distance(to: position) <
            CGPoint(x: $1.frame.midX, y: $1.frame.midY).distance(to: position)
        }
        
        if let closest = closest {
            buttonTapped(sender: closest.button)
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: indicatorIsHidden ? 0 : 8, right: 0))
        effectView?.frame = bounds
        layer.cornerRadius = bounds.height / 2
        effectView?.layer.cornerRadius = layer.cornerRadius
    }
}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

