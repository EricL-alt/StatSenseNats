import Foundation
import UIKit
import SwiftUI

#if targetEnvironment(simulator)
class MockCameraService: CameraService {
    override init() {
        super.init()
        // Skip actual camera setup in simulator
        DispatchQueue.main.async {
            self.isAuthorized = true
        }
    }
    
    override func checkAuthorization() {
        // Skip real authorization check in simulator
        isAuthorized = true
    }
    
    override func startSession() {
        // Don't actually start the AVCaptureSession in simulator
        DispatchQueue.main.async {
            self.isSessionRunning = true
        }
    }
    
    override func stopSession() {
        // Don't actually stop the AVCaptureSession in simulator
        DispatchQueue.main.async {
            self.isSessionRunning = false
        }
    }
    
    override func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        // Generate a mock image for testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // Create a simple test image
            let image = self?.createMockImage()
            self?.capturedImage = image
            completion(image)
        }
    }
    
    private func createMockImage() -> UIImage? {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Draw a gradient background
            let colors = [UIColor.systemBlue, UIColor.systemPurple]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map { $0.cgColor } as CFArray,
                locations: [0, 1]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Add text
            let text = "Mock Camera Image"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 60),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return image
    }
}
#endif
