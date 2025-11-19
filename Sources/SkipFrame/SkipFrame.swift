//
//  SkipFrame.swift
//  frame
//
//  Created by Скіп Юлія Ярославівна on 14.11.2025.
//

import UIKit

/// `SkipFrame` is a custom frame for drawing over an existing `UIViewController`.
/// It allows overlaying a colored layer on a snapshot of the current screen,
/// interacting with buttons, and opening a color picker.
///
/// Example usage:
/// ```swift
/// let skipFrame = SkipFrame()
/// skipFrame.frame = view.bounds
/// view.addSubview(skipFrame)
/// skipFrame.setupFrame(for: self)
/// skipFrame.setBackgroundColorForFrame(to: .red)
/// skipFrame.changeButtonsStackPosition(to: .top)
/// ```

public final class SkipFrame: UIView {
    
    // MARK: - Private properties
    
    private weak var parentViewController: UIViewController?
    private var colorPickerDelegate: ColorPickerDelegate?
    private let drawingView = DrawingView()
    private var frameColor: UIColor = .clear
    private let backgroundImageView = UIImageView()
    
    // MARK: - Public methods

    /// Sets up the frame for the specified `UIViewController`.
    /// Adds a drawing layer, buttons, and a snapshot of the screen.
    /// - Parameter parentViewController: The view controller where the frame will be displayed.
    public func setupFrame(for parentViewController: UIViewController) {
        self.parentViewController = parentViewController
        
        makeSnapshot(for: parentViewController)
        setupDrawingview()

        ButtonsManager.shared.setupLayoutFor(
            view: self,
            drawingView: drawingView,
            backgroundImageView: backgroundImageView,
            parentViewController: parentViewController
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openColorPicker),
            name: NSNotification.Name("openColorPicker"),
            object: nil
        )
    }
    
    /// Sets the background color for the drawing layer.
    /// - Parameter color: The color to apply to the frame.
    public func setBackgroundColorForFrame(to color: UIColor){
        self.frameColor = color
        drawingView.backgroundColor = color
    }
    
    /// Changes the icon of a button to a new SF Symbol.
    /// - Parameters:
    ///   - target: The action type of the button (`ButtonsManager.ActionType`).
    ///   - systemName: The SF Symbol name.
    ///   - tintColor: The color of the icon.
    public func changeButtonIcon(for target: ButtonsManager.ActionType, to systemName: String, colored tintColor: UIColor) {
        ButtonsManager.shared.changeButtonIcon(for: target, to: systemName, colored: tintColor)
    }
    
    /// Reorders buttons in the stack.
    /// - Parameter order: An array of button types (`ButtonsManager.ButtonType`) in the desired order.
    public func reorderButtons(_ order: [ButtonsManager.ButtonType]) {
        ButtonsManager.shared.reorderButtons(order)
    }
    
    /// Changes the position of the button stack on the screen.
    /// - Parameter position: The new stack position (`ButtonsManager.StackPosition`).
    public func changeButtonsStackPosition(to position: ButtonsManager.StackPosition) {
        ButtonsManager.shared.changeButtonsStackPosition(to: position)
    }
    
    /// Returns current drawing
    public func getDrawing() -> UIImage? {
        return ButtonsManager.shared.getDrawing()
    }
    
    // MARK: - Private methods

    /// Sets up the drawing layer over the frame.
    private func setupDrawingview(){
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.backgroundColor = frameColor
        self.addSubview(drawingView)
        
        NSLayoutConstraint.activate([
            drawingView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            drawingView.topAnchor.constraint(equalTo: self.topAnchor),
            drawingView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    /// Creates a snapshot of the parent view controller and adds it as a background.
    /// - Parameter parentViewController: The view controller to snapshot.
    private func makeSnapshot(for parentViewController: UIViewController){
        if let snapshot = parentViewController.view.snapshot() {
            backgroundImageView.image = snapshot
            backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(backgroundImageView)
            
            NSLayoutConstraint.activate([
                backgroundImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                backgroundImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                backgroundImageView.topAnchor.constraint(equalTo: self.topAnchor),
                backgroundImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
    }
    
    /// Opens the system color picker to select a color for the frame.
    @objc private func openColorPicker() {
        guard let parent = parentViewController else { return }
        let picker = UIColorPickerViewController()
        let delegate = ColorPickerDelegate(parent: self)
        picker.delegate = delegate
        self.colorPickerDelegate = delegate
        parent.present(picker, animated: true)
    }
    
    /// Applies the selected color to the drawing layer.
    /// - Parameter color: The color chosen by the user.
    private func applyColor(_ color: UIColor) {
        color.getRed(&drawingView.red, green: &drawingView.green, blue: &drawingView.blue, alpha: nil)
    }
    
    // MARK: - ColorPickerDelegate
        
    /// Delegate for the system color picker.
    private class ColorPickerDelegate: NSObject, UIColorPickerViewControllerDelegate {
        private weak var parent: SkipFrame?
        
        init(parent: SkipFrame) { self.parent = parent }
        
        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            parent?.applyColor(viewController.selectedColor)
        }
        
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            parent?.applyColor(viewController.selectedColor)
        }
    }
}

// MARK: - UIView extension

extension UIView {
    
    /// Takes a snapshot of the view and returns it as a UIImage.
    /// - Returns: The snapshot image, or `nil` if it fails.
    func snapshot() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            layer.render(in: UIGraphicsGetCurrentContext()!)
        }
    }
}

