import Foundation
import AVFoundation
import UIKit
import SwiftUI

class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var error: CameraError?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var photoCompletion: ((UIImage?) -> Void)?
    
    /// Factory method to create the appropriate camera service
    static func create() -> CameraService {
        #if targetEnvironment(simulator)
        print("📱 Running in simulator - using MockCameraService")
        return MockCameraService()
        #else
        print("📱 Running on device - using CameraService")
        return CameraService()
        #endif
    }

    override init() {
        super.init()
        checkAuthorization()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            defer {
                // Always commit configuration, even if setup fails
                self.session.commitConfiguration()
            }
            
            self.session.sessionPreset = .photo

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input) else {
                DispatchQueue.main.async {
                    self.error = .cameraUnavailable
                }
                return
            }

            self.session.addInput(input)

            guard self.session.canAddOutput(self.photoOutput) else {
                DispatchQueue.main.async {
                    self.error = .outputUnavailable
                }
                return
            }

            self.session.addOutput(self.photoOutput)
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCompletion = completion

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            guard self.session.isRunning, !self.session.inputs.isEmpty else {
                DispatchQueue.main.async {
                    self.photoCompletion?(nil)
                }
                return
            }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async { [weak self] in
                self?.photoCompletion?(nil)
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.photoCompletion?(image)
        }
    }
}

enum CameraError: LocalizedError {
    case cameraUnavailable
    case outputUnavailable
    case captureError
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable: return "Camera is not available"
        case .outputUnavailable: return "Could not set up photo output"
        case .captureError: return "Failed to capture photo"
        case .unauthorized: return "Camera access not authorized"
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {

    }
}

