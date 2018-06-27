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
