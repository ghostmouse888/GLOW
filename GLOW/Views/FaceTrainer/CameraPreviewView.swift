import SwiftUI
import AVFoundation

/// Full screen live camera preview — the user sees their own face
/// the entire time, just like the Nintendo DS Face Trainer.
struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

// MARK: — UIView subclass with AVCaptureVideoPreviewLayer

final class PreviewUIView: UIView {

    var session: AVCaptureSession? {
        didSet {
            guard let session else { return }
            previewLayer.session       = session
            previewLayer.videoGravity  = .resizeAspectFill
            previewLayer.connection?.videoOrientation = .portrait
        }
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
