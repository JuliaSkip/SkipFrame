# SkipFrame

`SkipFrame` is a lightweight Swift framework for adding an interactive drawing overlay on top of any `UIViewController`. It allows drawing with different brush types, colors, opacity control, undo/redo, and saving artwork to Photos. The framework is fully open-source and supports both **Swift Package Manager (SPM)** and **CocoaPods** integration.

---

## Features

- Add a customizable drawing overlay to any view controller.
- Supports multiple brush types:
  - Round
  - Square
  - Dotted
  - Arrow
  - Eraser
- Brush width and opacity sliders.
- Undo/redo functionality.
- Reset canvas feature.
- Change brush and action button icons dynamically.
- Color picker integration for brush color selection.
- Save drawing along with the background snapshot to Photos.
- Positionable toolbar (top or bottom).
- Fully documented with SwiftDoc comments.
- SwiftLint integrated for consistent code style.

---

## Installation

### Swift Package Manager (SPM)

1. In Xcode, go to `File` → `Add Packages…`.
2. Enter the repository URL:

https://github.com/JuliaSkip/SkipFrame.git

3. Choose the desired version and click **Add Package**.

### CocoaPods

1. Add this to your `Podfile`:
```ruby
pod 'SkipFrame', :git => 'https://github.com/JuliaSkip/SkipFrame.git'
```
2. Run
```
pod install
```

## Usage

1. Import the framework
``` swift
import SkipFrame
```
2. Setup SkipFrame in your view controller
``` swift
class ViewController: UIViewController {

    private let skipFrame = SkipFrame()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add SkipFrame overlay
        skipFrame.frame = view.bounds
        view.addSubview(skipFrame)

        // Setup for the current view controller
        skipFrame.setupFrame(for: self)
    }
}
```
3. Customize the frame if you want to. Framework gives you default setup.
``` swift
// Change background color of the drawing area
skipFrame.setBackgroundColorForFrame(to: .yellow)

// Change button icons
skipFrame.changeButtonIcon(for: .save, to: "square.and.arrow.down", colored: .red)

// Reorder buttons
skipFrame.reorderButtons([.color, .brushes, .sliders, .reset, .timer, .save])

// Remove unnecessary buttons by not adding them to a new stack
skipFrame.reorderButtons([.color, .brushes, .save])

// Move buttons stack to bottom
skipFrame.changeButtonsStackPosition(to: .bottom)
```

4. To enable saving images to the user’s photo library on iOS, the application must declare the appropriate usage-description key in Info.plist. Without this key, iOS will block write access to the photo library.

Add the following entry:
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app requires permission to save images to your photo library.</string>
```

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
