# EasyCamery

```swift
import UIKit
import AVFoundation
import EasyCamery
import EasyImagy

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    private let camera: Camera<RGBA<UInt8>> = try! Camera(sessionPreset: .vga640x480, focusMode: .continuousAutoFocus)
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        camera.start { [weak self] image in
            // Makes `image` negative
            image.update { pixel in
                pixel.red = 255 - pixel.red
                pixel.green = 255 - pixel.green
                pixel.blue = 255 - pixel.blue
            }
            
            self?.imageView.image = image.uiImage
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        camera.stop()
        
        super.viewWillDisappear(animated)
    }
}
```

## Installation

### Swift Package Manager

**Package.swift**

```swift
// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  ...
  dependencies: [
    .package(url: "https://github.com/koher/EasyCamery.git", .branch("master")),
  ],
  targets: [
    .target(
      ...
      dependencies: [
        "EasyCamery",
      ]),
    ]
)
```

### [Carthage](https://github.com/Carthage/Carthage)

**Cartfile** 

```
github "koher/EasyCamery" "master"
```

## License

MIT
