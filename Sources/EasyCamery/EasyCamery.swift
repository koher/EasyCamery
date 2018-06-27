import EasyImagy
import AVFoundation

public protocol CameraPixel {
    static var cameraPixelDefaultValue: Self { get }
    static var cameraPixelFormatType: OSType { get }
    static func cameraPixelCopy(buffer: CVPixelBuffer, to image: inout Image<Self>)
}

extension RGBA : CameraPixel where Channel == UInt8 {
    public static var cameraPixelDefaultValue : RGBA<UInt8> {
        return .black
    }
    
    public static var cameraPixelFormatType: OSType {
        return kCVPixelFormatType_32BGRA
    }
    
    public static func cameraPixelCopy(buffer: CVPixelBuffer, to image: inout Image<RGBA<UInt8>>) {
        precondition(!CVPixelBufferIsPlanar(buffer))
        
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)!
        let pointer = UnsafeRawBufferPointer(start: baseAddress, count: image.count)
        image.withUnsafeMutableBytes {
            $0.copyMemory(from: pointer)
        }
    }
}
extension UInt8 : CameraPixel {
    public static var cameraPixelDefaultValue : UInt8 {
        return .min
    }
    
    public static var cameraPixelFormatType: OSType {
        return kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    }
    
    public static func cameraPixelCopy(buffer: CVPixelBuffer, to image: inout Image<UInt8>) {
        precondition(CVPixelBufferIsPlanar(buffer))
        
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(buffer, 0)!
        let pointer = UnsafeRawBufferPointer(start: baseAddress, count: image.count)
        image.withUnsafeMutableBytes {
            $0.copyMemory(from: pointer)
        }
    }
}

public class Camera<Pixel : CameraPixel> {
    private let delegate: Delegate<Pixel>
    private var session: AVCaptureSession
    private var frame: Image<Pixel>?
    
    private var isActive: Bool = false
    
    public init(
        sessionPreset: AVCaptureSession.Preset = .vga640x480,
        focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
    ) throws {
        self.delegate = Delegate()
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw CameraError(message: "No camera device found.")
        }
        do {
            try! device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            device.focusMode = focusMode
        }
        
        guard device.supportsSessionPreset(sessionPreset) else {
            throw CameraError(message: "\(sessionPreset) is not supported.")
        }
        
        let input = try! AVCaptureDeviceInput(device: device)
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Pixel.cameraPixelFormatType
        ]
        let queue = DispatchQueue.init(label: "org.koherent.EasyCamery.Camera", qos: .userInteractive)
        output.setSampleBufferDelegate(delegate, queue: queue)
        
        let session = AVCaptureSession()
        do {
            session.beginConfiguration()
            defer { session.commitConfiguration() }
            
            session.addInput(input)
            session.addOutput(output)
            session.sessionPreset = sessionPreset
        }
        self.session = session
        
        delegate.camera = self
    }
    
    public func start(_ handler: (Image<Pixel>) -> Void) {
        guard !isActive else { return }
        isActive = !isActive
        session.startRunning()
    }
    
    public func stop() {
        guard isActive else { return }
        isActive = !isActive
        session.stopRunning()
    }
}

extension Camera {
    private class Delegate<Pixel : CameraPixel> : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        weak var camera: Camera<Pixel>?
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let camera = self.camera else { return }
            
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            
            var frame = camera.frame ?? Image<Pixel>(width: width, height: height, pixel: Pixel.cameraPixelDefaultValue)
            do {
                camera.frame = nil
                defer { camera.frame = frame }
                
                do {
                    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
                    defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
                    
                    Pixel.cameraPixelCopy(buffer: imageBuffer, to: &frame)
                }
            }
        }
    }
}

public struct CameraError : Error {
    public let message: String
    public init(message: String) {
        self.message = message
    }
}
