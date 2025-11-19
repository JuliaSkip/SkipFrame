//
//  DrawingView.swift
//  testFrame
//
//  Created by Скіп Юлія Ярославівна on 14.11.2025.
//

import UIKit

/// `DrawingView` is a custom UIView that provides a drawing canvas.
/// It supports multiple brush types, undo/redo functionality, fading effects,
/// and arrow drawing.
///
/// Example usage:
/// ```swift
/// let drawingView = DrawingView()
/// drawingView.translatesAutoresizingMaskIntoConstraints = false
/// drawingView.backgroundColor = frameColor
/// self.addSubview(drawingView)
///
/// NSLayoutConstraint.activate([
///     drawingView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
///     drawingView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
///     drawingView.topAnchor.constraint(equalTo: self.topAnchor),
///     drawingView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
/// ])
/// ```
public final class DrawingView: UIView {
    
    // MARK: - Brush settings
    
    /// Type of brush used for drawing.
    enum BrushType { case round, square, dotted, eraser, arrow }
    var brushType: BrushType = .round
    
    /// Drawing mode for fade effects.
    enum DrawMode { case normal, fading }
    var drawMode: DrawMode = .normal
    private var fadingDisplayLink: CADisplayLink?
    
    /// The main image view storing permanent drawing content.
    let mainImageView = UIImageView()
    /// Temporary image view for in-progress strokes or fading.
    private let tempImageView = UIImageView()
    /// Undo stack storing previous states of the canvas.
    private var undoStack: [UIImage] = []
    /// Redo stack storing undone states for redo functionality.
    private var redoStack: [UIImage] = []
    /// The last tracked point for arrow
    private var lastPoint = CGPoint.zero
    /// Start point of arrow
    private var arrowStartPoint = CGPoint.zero
    /// property to track swipes
    private var swiped = false
    
    // MARK: - Brush color and properties
    
    /// Red component of the brush color (0–1).
    var red: CGFloat = 0
    /// Green component of the brush color (0–1).
    var green: CGFloat = 0
    /// Blue component of the brush color (0–1).
    var blue: CGFloat = 0
    /// Width of the brush stroke.
    var brushWidth: CGFloat = 10
    /// Opacity of the brush stroke.
    var opacity: CGFloat = 1
    
    // MARK: - Initialization
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    /// Shared initialization logic.
    private func commonInit() {
        setupImages()
        setupGestures()
        isMultipleTouchEnabled = false
    }
    
    // MARK: - Public methods
    
    /// Clears the entire canvas, removing all drawings.
    public func resetCanvas() {
        mainImageView.image = nil
        tempImageView.image = nil
    }
    
    /// Undoes the last drawing action.
    public func undo() {
        guard let lastImage = undoStack.popLast() else { return }
        if let current = mainImageView.image {
            redoStack.append(current)
        }
        mainImageView.image = lastImage
    }
    
    /// Redoes the last undone drawing action.
    public func redo() {
        guard let nextImage = redoStack.popLast() else { return }
        if let current = mainImageView.image {
            undoStack.append(current)
        }
        mainImageView.image = nextImage
    }
    
    // MARK: - Private setup methods
    
    /// Sets up the main and temporary image views with autoresizing.
    private func setupImages() {
        mainImageView.frame = bounds
        tempImageView.frame = bounds
        
        mainImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tempImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mainImageView.contentMode = .scaleToFill
        tempImageView.contentMode = .scaleToFill
        
        addSubview(mainImageView)
        addSubview(tempImageView)
    }
    
    /// Adds gesture recognizers (currently double tap for fill).
    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    /// Handles double-tap gesture to fill the canvas with the current brush color.
    @objc private func handleDoubleTap() {
        UIGraphicsBeginImageContext(bounds.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let rect = CGRect(origin: .zero, size: bounds.size)
        
        mainImageView.image?.draw(in: rect)
        
        context.setFillColor(red: red, green: green, blue: blue, alpha: opacity)
        context.fill(rect)
        
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let currentImage = mainImageView.image {
            undoStack.append(currentImage)
        }
    }
    
    /// Draws a line from one point to another using the current brush type and color.
    private func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        UIGraphicsBeginImageContext(bounds.size)
        let rect = CGRect(origin: .zero, size: bounds.size)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        tempImageView.image?.draw(in: rect)
        
        switch brushType {
        case .round:
            context.setLineCap(.round)
            context.setLineDash(phase: 0, lengths: [])
            context.setStrokeColor(red: red, green: green, blue: blue, alpha: 1)
        case .square:
            context.setLineCap(.square)
            context.setLineDash(phase: 0, lengths: [])
            context.setStrokeColor(red: red, green: green, blue: blue, alpha: 1)
        case .dotted:
            context.setLineCap(.round)
            context.setLineDash(phase: 0, lengths: [1, 30])
            context.setStrokeColor(red: red, green: green, blue: blue, alpha: 1)
        case .eraser:
            context.setLineCap(.round)
            context.setLineDash(phase: 0, lengths: [])
            context.setStrokeColor(UIColor.systemBackground.cgColor)
        case .arrow:
            context.setLineCap(.round)
            context.setLineDash(phase: 0, lengths: [])
            context.setStrokeColor(red: red, green: green, blue: blue, alpha: 1)
        }
        
        context.setLineWidth(brushWidth)
        context.setBlendMode(.normal)
        
        context.move(to: fromPoint)
        context.addLine(to: toPoint)
        context.strokePath()
        
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = opacity
        
        UIGraphicsEndImageContext()
    }
    
    /// Draws an arrowhead from start to end points.
    private func drawArrowHead(context: CGContext, start: CGPoint, end: CGPoint) {
        let arrowLength: CGFloat = 15 + brushWidth
        let arrowAngle: CGFloat = .pi / 6
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx)
        
        
        let tail1 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        let tail2 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        
        
        context.setLineWidth(brushWidth)
        context.setStrokeColor(red: red, green: green, blue: blue, alpha: opacity)
        context.setLineCap(.round)
        
        context.move(to: end)
        context.addLine(to: tail1)
        
        context.move(to: end)
        context.addLine(to: tail2)
        
        context.strokePath()
        
    }
    
    /// Starts the fading animation for the temp image view.
    private func startFading() {
        fadingDisplayLink?.invalidate()
        fadingDisplayLink = CADisplayLink(target: self, selector: #selector(updateFading))
        fadingDisplayLink?.add(to: .main, forMode: .common)
    }
    
    /// Updates the fading effect by gradually decreasing alpha.
    @objc private func updateFading() {
        guard tempImageView.image != nil else {
            fadingDisplayLink?.invalidate()
            fadingDisplayLink = nil
            return
        }
        
        tempImageView.alpha -= 0.02
        if tempImageView.alpha <= 0 {
            tempImageView.image = nil
            tempImageView.alpha = 1
            fadingDisplayLink?.invalidate()
            fadingDisplayLink = nil
        }
    }
    
    // MARK: - Touch handling
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: self)
            if brushType == .arrow {
                arrowStartPoint = lastPoint
            }
            
            if let currentImage = mainImageView.image {
                undoStack.append(currentImage)
            }
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: self)
            drawLine(from: lastPoint, to: currentPoint)
            lastPoint = currentPoint
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        if !swiped { drawLine(from: lastPoint, to: lastPoint) }
        
        let endPoint = touch.location(in: self)
        
        if brushType == .arrow && drawMode == .fading {
            UIGraphicsBeginImageContext(bounds.size)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            let rect = CGRect(origin: .zero, size: bounds.size)
            
            tempImageView.image?.draw(in: rect)
            
            drawArrowHead(context: context, start: arrowStartPoint, end: endPoint)
            tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            tempImageView.alpha = 1
            UIGraphicsEndImageContext()
            
        } else if brushType == .arrow{
            UIGraphicsBeginImageContext(bounds.size)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            let rect = CGRect(origin: .zero, size: bounds.size)
            
            mainImageView.image?.draw(in: rect)
            tempImageView.image?.draw(in: rect, blendMode: .normal, alpha: opacity)
            
            drawArrowHead(context: context, start: arrowStartPoint, end: endPoint)
            mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            tempImageView.image = nil
        }
        
        if drawMode == .fading {
            startFading()
        } else if brushType != .arrow {
            
            UIGraphicsBeginImageContext(bounds.size)
            let rect = CGRect(origin: .zero, size: bounds.size)
            
            mainImageView.image?.draw(in: rect)
            tempImageView.image?.draw(in: rect, blendMode: .normal, alpha: opacity)
            
            mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            tempImageView.image = nil
        }
    }
}
