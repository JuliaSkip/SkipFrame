//
//  ButtonsManager.swift
//  testFrame
//
//  Created by Скіп Юлія Ярославівна on 14.11.2025.
//
import UIKit

/// `ButtonsManager` is a singleton class responsible for managing all UI buttons
/// for drawing controls, including brush selection, color picking, undo/redo, sliders,
/// save, and timer mode. Supports dynamic icon changes, reordering of buttons, and
/// moving the buttons stack between top and bottom positions.
///
/// Example usage:
/// ```swift
/// let manager = ButtonsManager.shared
/// manager.setupLayoutFor(view: view, drawingView: drawingView, backgroundImageView: backgroundImageView, parentViewController: self)
/// manager.reorderButtons([.color, .brushes, .sliders, .reset, .timer, .save])
/// ```
@MainActor
public final class ButtonsManager {
    
    // MARK: - Public Enums
    
    /// Types of actions associated with buttons.
    public enum ActionType {
        case save, color, reset, undo, redo, brushes
        case roundBrush, squareBrush, dottedBrush, arrowBrush, eraserBrush
        case timeMode, brushSlider, opacitySlider
    }
    
    /// Types of buttons that can be reordered in the UI stack.
    public enum ButtonType {
        case color, brushes, sliders, reset, timer, save
    }
    
    /// Position of the buttons stack in the parent view.
    public enum StackPosition {
        case top, bottom
    }
        
    // MARK: - Singleton
    
    /// Shared singleton instance.
    public static let shared = ButtonsManager()

    // MARK: - Private properties

    private weak var drawingView: DrawingView?
    private var backgroundImageView: UIImageView?
    private var parentViewController: UIViewController?
    
    private var sliderStackView: UIStackView?
    private let stackView = UIStackView()
    
    private let buttonSave = UIButton(type: .system)
    private let buttonActions = UIButton(type: .system)
    private let buttonColor = UIButton(type: .system)
    private let buttonBrush = UIButton(type: .system)
    private let buttonModeToggle = UIButton(type: .system)
    private let buttonToggleSliders = UIButton(type: .system)
    private let brushSlider = UISlider()
    private let opacitySlider = UISlider()
    private var brushIconView: UIImageView?
    private var opacityIconView: UIImageView?
    
    // MARK: - Public methods
    
    /// Sets up the buttons and sliders stack layout on a parent view.
    ///
    /// - Parameters:
    ///   - view: Parent view where the buttons stack will be added.
    ///   - drawingView: The DrawingView instance to control.
    ///   - backgroundImageView: UIImageView for background rendering.
    ///   - parentViewController: Parent view controller for presenting alerts.
    public func setupLayoutFor(view: UIView, drawingView: DrawingView, backgroundImageView: UIImageView, parentViewController: UIViewController) {
        self.drawingView = drawingView
        self.backgroundImageView = backgroundImageView
        self.parentViewController = parentViewController
        setupButtonsStack(view: view)
        setupSlidersStack(view: view, drawingView: drawingView)
    }
    
    /// Changes the icon for a specific button or menu item.
    ///
    /// - Parameters:
    ///   - target: The action type to update.
    ///   - systemName: SF Symbol name to set as icon.
    ///   - tintColor: Tint color for the icon.
    public func changeButtonIcon(for target: ActionType, to systemName: String, colored tintColor: UIColor) {
        guard let image = UIImage(systemName: systemName)?.withTintColor(tintColor, renderingMode: .alwaysOriginal) else {
            print("Invalid SF Symbol: \(systemName)")
            return
        }
        
        switch target {
        case .save:
            buttonSave.setImage(image, for: .normal)
            buttonSave.tintColor = tintColor
            
        case .color:
            buttonColor.setImage(image, for: .normal)
            buttonColor.tintColor = tintColor
            
        case .brushes:
            buttonBrush.setImage(image, for: .normal)
            buttonBrush.tintColor = tintColor
            
        case .timeMode:
            buttonModeToggle.setImage(image, for: .normal)
            buttonModeToggle.tintColor = tintColor
            
        case .reset, .undo, .redo:
            updateMainActionMenuIcons(for: target, image: image)
            
        case .roundBrush, .squareBrush, .dottedBrush, .arrowBrush, .eraserBrush:
            updateBrushMenuIcon(for: target, image: image)
            
        case .brushSlider:
            brushIconView?.image = image
            
        case .opacitySlider:
            opacityIconView?.image = image
        }
    }
    
    /// Reorders the buttons stack based on the given order.
    ///
    /// - Parameter order: Array of ButtonType specifying the new order.
    public func reorderButtons(_ order: [ButtonType]) {
        let mapping: [ButtonType: UIButton] = [
            .color: buttonColor,
            .brushes: buttonBrush,
            .sliders: buttonToggleSliders,
            .reset: buttonActions,
            .timer: buttonModeToggle,
            .save: buttonSave
        ]
        
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for type in order {
            if let button = mapping[type] {
                stackView.addArrangedSubview(button)
            }
        }
        
        stackView.setNeedsLayout()
        stackView.layoutIfNeeded()
    }
    
    /// Changes the position of the buttons stack and slider stack to top or bottom of the parent view.
    ///
    /// - Parameter position: StackPosition value (`.top` or `.bottom`).
    public func changeButtonsStackPosition(to position: StackPosition) {
        guard let superview = stackView.superview, let sliderStack = sliderStackView else { return }
        
        let oldConstraints = superview.constraints.filter {
            ($0.firstItem as? UIView === stackView) || ($0.secondItem as? UIView === stackView)
        }
        NSLayoutConstraint.deactivate(oldConstraints)
        
        let oldSliderConstraints = superview.constraints.filter {
            ($0.firstItem as? UIView === sliderStack) || ($0.secondItem as? UIView === sliderStack)
        }
        NSLayoutConstraint.deactivate(oldSliderConstraints)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        sliderStack.translatesAutoresizingMaskIntoConstraints = false
        
        switch position {
        case .top:
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: 16),
                stackView.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -16)
            ])
            
            NSLayoutConstraint.activate([
                sliderStack.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8),
                sliderStack.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 16),
                sliderStack.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -16)
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                stackView.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                stackView.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -16)
            ])
            
            NSLayoutConstraint.activate([
                sliderStack.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -8),
                sliderStack.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 16),
                sliderStack.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -16)
            ])
        }
    }
    
    // MARK: - Private setup methods

    /// Sets up the main buttons stack layout.
    private func setupButtonsStack(view: UIView){
        setupButtons()
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.backgroundColor = view.backgroundColor
        
        [buttonColor, buttonBrush, buttonToggleSliders, buttonActions, buttonModeToggle, buttonSave].forEach {
            stackView.addArrangedSubview($0)
        }
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    /// Configures button icons, menus, and actions.
    private func setupButtons() {
        buttonSave.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        buttonColor.setImage(UIImage(systemName: "paintpalette"), for: .normal)
        buttonBrush.setImage(UIImage(systemName: "paintbrush"), for: .normal)
        buttonActions.setImage(UIImage(systemName: "arrow.uturn.left"), for: .normal)
        buttonToggleSliders.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        buttonModeToggle.setImage(UIImage(systemName: "hourglass"), for: .normal)
        
        [buttonSave, buttonColor, buttonBrush, buttonToggleSliders, buttonActions, buttonModeToggle,].forEach {
            $0.tintColor = .systemBlue
        }
        
        setupBrushMenu()
        setupMainActionMenu()
        
        buttonSave.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        buttonColor.addTarget(self, action: #selector(colorTapped), for: .touchUpInside)
        buttonToggleSliders.addTarget(self, action: #selector(toggleSliders), for: .touchUpInside)
        buttonModeToggle.addTarget(self, action: #selector(toggleDrawMode), for: .touchUpInside)
    }
    
    /// Sets up brush selection menu for the brush button.
    private func setupBrushMenu() {
        guard let drawingView = drawingView else { return }
        
        let round = UIAction(title: "Round", image: UIImage(systemName: "circle.fill"), state: drawingView.brushType == .round ? .on : .off) { _ in
            drawingView.brushType = .round
        }
        
        let square = UIAction(title: "Square", image: UIImage(systemName: "square.fill"), state: drawingView.brushType == .square ? .on : .off) { _ in
            drawingView.brushType = .square
        }
        
        let dotted = UIAction(title: "Dotted", image: UIImage(systemName: "circle.dashed"), state: drawingView.brushType == .dotted ? .on : .off) { _ in
            drawingView.brushType = .dotted
        }
        
        let arrow = UIAction(title: "Arrow", image: UIImage(systemName: "arrow.up.right"), state: drawingView.brushType == .arrow ? .on : .off) { _ in
            drawingView.brushType = .arrow
        }
        
        let eraser = UIAction(title: "Eraser", image: UIImage(systemName: "eraser"), state: drawingView.brushType == .eraser ? .on : .off) { _ in
            drawingView.brushType = .eraser
        }
        
        buttonBrush.menu = UIMenu(title: "Brushes", options: .singleSelection, children: [round, square, dotted, arrow, eraser])
        buttonBrush.showsMenuAsPrimaryAction = true
    }
    
    /// Updates brush menu icon dynamically.
    private func updateBrushMenuIcon(for target: ActionType, image: UIImage) {
        guard let menu = buttonBrush.menu else { return }
        
        let newChildren: [UIMenuElement] = menu.children.map { element in
            guard let action = element as? UIAction else { return element }
            let state = action.state
            
            switch target {
            case .roundBrush where action.title == "Round":
                return UIAction(title: action.title, image: image, state: state) { _ in
                    self.drawingView?.brushType = .round
                }
            case .squareBrush where action.title == "Square":
                return UIAction(title: action.title, image: image, state: state) { _ in
                    self.drawingView?.brushType = .square
                }
            case .dottedBrush where action.title == "Dotted":
                return UIAction(title: action.title, image: image, state: state) { _ in
                    self.drawingView?.brushType = .dotted
                }
            case .arrowBrush where action.title == "Arrow":
                return UIAction(title: action.title, image: image, state: state) { _ in
                    self.drawingView?.brushType = .arrow
                }
            case .eraserBrush where action.title == "Eraser":
                return UIAction(title: action.title, image: image, state: state) { _ in
                    self.drawingView?.brushType = .eraser
                }
            default:
                return action
            }
        }
        
        buttonBrush.menu = UIMenu(title: menu.title, options: menu.options, children: newChildren)
    }
    
    /// Sets up reset/undo/redo main action menu.
    private func setupMainActionMenu() {
        let resetAction = UIAction(title: "Reset", image: UIImage(systemName: "trash")) { _ in
            self.drawingView?.resetCanvas()
        }
        
        let undoAction = UIAction(title: "Undo", image: UIImage(systemName: "arrow.uturn.left")) { _ in
            self.drawingView?.undo()
        }
        
        let redoAction = UIAction(title: "Redo", image: UIImage(systemName: "arrow.uturn.right")) { _ in
            self.drawingView?.redo()
        }
        
        let menu = UIMenu(title: "Actions", children: [resetAction, undoAction, redoAction])
        buttonActions.menu = menu
        buttonActions.showsMenuAsPrimaryAction = true
    }
    
    /// Updates main action menu icons dynamically.
    private func updateMainActionMenuIcons(for target: ActionType, image: UIImage) {
        guard let menu = buttonActions.menu else { return }
        
        let newChildren: [UIMenuElement] = menu.children.map { element in
            guard let action = element as? UIAction else { return element }
            
            switch target {
            case .reset where action.title == "Reset":
                return UIAction(title: action.title, image: image) { _ in
                    self.drawingView?.resetCanvas()
                }
            case .undo where action.title == "Undo":
                return UIAction(title: action.title, image: image) { _ in
                    self.drawingView?.undo()
                }
            case .redo where action.title == "Redo":
                return UIAction(title: action.title, image: image) { _ in
                    self.drawingView?.redo()
                }
            default:
                return action
            }
        }
        
        buttonActions.menu = UIMenu(title: menu.title, options: menu.options, children: newChildren)
    }
    
    /// Sets up sliders stack for brush width and opacity.
    private func setupSlidersStack(view: UIView, drawingView: DrawingView){
        brushSlider.minimumValue = 1
        brushSlider.maximumValue = 50
        brushSlider.value = Float(drawingView.brushWidth)
        brushSlider.addTarget(self, action: #selector(brushSliderChanged(_:)), for: .valueChanged)
        
        let brushIcon = UIImageView(image: UIImage(systemName: "paintbrush"))
        brushIcon.tintColor = .systemBlue
        brushIconView = brushIcon
        let brushStack = UIStackView(arrangedSubviews: [brushIcon, brushSlider])
        brushStack.axis = .horizontal
        brushStack.spacing = 8
        brushStack.alignment = .center
        
        opacitySlider.minimumValue = 0.1
        opacitySlider.maximumValue = 1.0
        opacitySlider.value = Float(drawingView.opacity)
        opacitySlider.addTarget(self, action: #selector(opacitySliderChanged(_:)), for: .valueChanged)
        
        let opacityIcon = UIImageView(image: UIImage(systemName: "drop.fill"))
        opacityIcon.tintColor = .systemBlue
        opacityIconView = opacityIcon
        let opacityStack = UIStackView(arrangedSubviews: [opacityIcon, opacitySlider])
        opacityStack.axis = .horizontal
        opacityStack.spacing = 8
        opacityStack.alignment = .center
        
        let sliderStack = UIStackView(arrangedSubviews: [brushStack, opacityStack])
        sliderStack.axis = .vertical
        sliderStack.spacing = 12
        sliderStack.distribution = .fillEqually
        sliderStack.isHidden = true
        
        sliderStackView = sliderStack
        view.addSubview(sliderStack)
        sliderStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sliderStack.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 80),
            sliderStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sliderStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    /// Updates sliders stack icons
    private func updateSliderIcon(for target: UISlider, image: UIImage) {
        if target == brushSlider {
            brushIconView?.image = image
        } else if target == opacitySlider {
            opacityIconView?.image = image
        }
    }
    
    // MARK: - Button actions

    @objc private func toggleDrawMode() {
        guard let drawingView = drawingView else { return }
        
        drawingView.drawMode = (drawingView.drawMode == .normal) ? .fading : .normal
        
        UIView.animate(withDuration: 0.2) {
            self.buttonModeToggle.backgroundColor = (drawingView.drawMode == .fading) ? UIColor.systemBlue.withAlphaComponent(0.2) : .clear
            self.buttonModeToggle.layer.cornerRadius = 8
        }
    }
    
    @objc private func toggleSliders() {
        guard let sliderStack = sliderStackView else { return }
        UIView.animate(withDuration: 0.3) {
            self.buttonToggleSliders.backgroundColor = (sliderStack.isHidden) ? UIColor.systemBlue.withAlphaComponent(0.2) : .clear
            self.buttonToggleSliders.layer.cornerRadius = 8
            sliderStack.isHidden.toggle()
        }
    }
    
    @objc private func saveTapped() {
        guard let drawingView = drawingView else { return }
        
        let size = drawingView.bounds.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        let finalImage = renderer.image { _ in
            backgroundImageView?.layer.render(in: UIGraphicsGetCurrentContext()!)
            
            drawingView.layer.render(in: UIGraphicsGetCurrentContext()!)
        }
        
        UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
        
        let alert = UIAlertController(
            title: "Saved",
            message: "Your artwork has been saved to Photos.",
            preferredStyle: .alert
        )
        
        parentViewController?.present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            alert.dismiss(animated: true)
        }
    }
    
    @objc private func colorTapped() {
        NotificationCenter.default.post(name: NSNotification.Name("openColorPicker"), object: nil)
    }
    
    @objc private func brushSliderChanged(_ sender: UISlider) { drawingView?.brushWidth = CGFloat(sender.value) }
    
    @objc private func opacitySliderChanged(_ sender: UISlider) { drawingView?.opacity = CGFloat(sender.value) }
    
}
