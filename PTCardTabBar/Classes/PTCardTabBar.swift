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
    
    /// Ce que la barre représente. C'est ce réglage — et non `indicatorIsHidden` — qui dit s'il
    /// existe une notion de sélection.
    public enum SelectionStyle {
        /// Barre d'onglets : un bouton à la fois est sélectionné, les autres sont grisés.
        case tabs
        /// Barre d'actions : aucun bouton n'est jamais sélectionné et tous gardent leur teinte
        /// pleine. Un tap notifie le delegate sans rien sélectionner ni déplacer l'indicateur.
        case actions
    }
    
    /// `.tabs` par défaut. Une barre qui ne sert qu'à déclencher des actions — fermer, scanner,
    /// enregistrer — doit passer en `.actions`, sinon ses boutons non tapés se grisent.
    public var selectionStyle: SelectionStyle = .tabs {
        didSet {
            guard selectionStyle != oldValue else { return }
            buttons().forEach { $0.unselectedColor = unselectedTint }
            if selectionStyle == .actions {
                buttons().forEach { $0.isSelected = false }
            } else if !items.isEmpty {
                // Retour en barre d'onglets : plus rien n'était sélectionné, on rétablit.
                select(at: min(selectedButtonIndex, items.count - 1), notifyDelegate: false)
            }
            updateIndicatorVisibility()
        }
    }
    
    /// Teinte des boutons non sélectionnés. En barre d'actions, c'est la teinte normale : rien
    /// n'étant sélectionné, griser reviendrait à tout griser.
    private var unselectedTint: UIColor? {
        selectionStyle == .actions ? tintColor : UIColor(rgb: 0x9b9b9b)
    }
    
    /// Affiche ou masque le point sous l'onglet courant. Réglage d'**affichage** uniquement : il ne
    /// dit plus rien de la sémantique de sélection, qui vit dans `selectionStyle`. Il ne reconstruit
    /// donc plus les boutons.
    public var indicatorIsHidden = false {
        didSet {
            updateIndicatorVisibility()
        }
    }
    
    /// En `.actions`, l'indicateur n'a pas de cible : `select` ne pose jamais sa contrainte
    /// d'abscisse. On le masque d'office pour qu'il ne puisse pas rester affiche n'importe ou.
    private func updateIndicatorVisibility() {
        indicatorView.isHidden = indicatorIsHidden || selectionStyle == .actions
    }
    
    
    private var indicatorViewYConstraint: NSLayoutConstraint!
    private var indicatorViewXConstraint: NSLayoutConstraint!
    
    /// Onglet actuellement sélectionné, mémorisé par la barre elle-même. Sert à retrouver la
    /// sélection après une reconstruction des boutons : sans lui, toute mutation d'`items`
    /// ramènerait le surlignage sur l'onglet 0 alors que le contrôleur, lui, ne bougerait pas.
    private var selectedButtonIndex = 0
    
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
        button.unselectedColor = unselectedTint
        button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
        self.stackView.addArrangedSubview(button)
    }
    
    
    open func reloadViews(){
        indicatorViewYConstraint?.isActive = false
        indicatorViewYConstraint = indicatorView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: -10.5)
        indicatorViewYConstraint.isActive = true
        
        // La contrainte d'abscisse vise un bouton qu'on s'apprête à retirer : la laisser en place
        // reviendrait à retenir une vue morte jusqu'à la prochaine sélection.
        indicatorViewXConstraint?.isActive = false
        indicatorViewXConstraint = nil
        
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
        // On restaure la sélection courante plutôt que de la forcer à 0 : une mutation d'`items`
        // — permuter deux onglets, par exemple — ne doit pas déplacer le surlignage sous
        // l'utilisateur. Et sans `notifyDelegate: false`, reconstruire les boutons déclencherait
        // l'action de l'onglet visé : à l'ouverture d'une fiche produit, c'était « fermer ».
        if selectionStyle == .tabs, !items.isEmpty {
            select(at: min(selectedButtonIndex, items.count - 1), notifyDelegate: false)
        }
    }
    
    
    
    private func buttons() -> [PTBarButton] {
        return stackView.arrangedSubviews.compactMap { $0 as? PTBarButton }
    }
    
    open func button(at index: Int) -> PTBarButton? {
        buttons()[safe: index]
    }
    
    /// Sélectionne l'onglet `index` : pose `isSelected`, déplace l'indicateur, et notifie le
    /// delegate si demandé.
    ///
    /// Il existait deux `select(at:)` aux sémantiques opposées — l'une posait `isSelected` et
    /// notifiait toujours, l'autre écrivait `tintColor` en direct sans toucher à `isSelected`. La
    /// résolution de surcharge envoyait toute sélection **programmatique** vers la seconde, si
    /// bien que `isSelected` restait périmé et que le premier `reloadApperance()` venu repeignait
    /// le surlignage sur le mauvais onglet. Une seule méthode désormais.
    ///
    /// En `.actions`, rien n'est sélectionné : seul le delegate est notifié.
    open func select(at index: Int, notifyDelegate: Bool = true) {
        let boutons = buttons()
        let cible = boutons[safe: index]
        
        if selectionStyle == .tabs {
            indicatorViewXConstraint?.isActive = false
            indicatorViewXConstraint = nil
            
            for (bIndex, button) in boutons.enumerated() {
                button.selectedColor = tintColor
                button.unselectedColor = unselectedTint
                button.isSelected = (bIndex == index)
            }
            
            if let cible = cible {
                selectedButtonIndex = index
                indicatorViewXConstraint = indicatorView.centerXAnchor.constraint(equalTo: cible.centerXAnchor)
                indicatorViewXConstraint?.isActive = true
            }
            
            UIView.animate(withDuration: 0.25) {
                self.layoutIfNeeded()
            }
        }
        
        // Aucun bouton à cet index — barre encore vide, ou index hors bornes. Notifier ferait
        // passer un PTBarButton! nul à un paramètre non optionnel, donc trap à l'appel.
        guard notifyDelegate, let cible = cible else { return }
        delegate?.cardTabBar(self, didSelectItemAt: index, button: cible)
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

