import AVFoundation
import Vision
import Combine
import UIKit

final class FaceDetectionService: NSObject, ObservableObject {

    // MARK: — Published face readings
    @Published var reading = FaceReading()
    @Published var permissionGranted = false
    @Published var permissionDenied  = false

    // MARK: — Camera
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "glow.face.detection", qos: .userInitiated)

    // MARK: — Vision
    private let faceRequest = VNDetectFaceLandmarksRequest()

    // MARK: — Baseline calibration
    private var calibrationReadings: [FaceReading] = []
    private var isCalibrating = true
    private var calibrationSeconds = 2.0
    private var calibrationStart: Date?
    private var baseline = FaceReading()

    // MARK: — Init

    override init() {
        super.init()
        checkPermission()
    }

    // MARK: — Permission

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.permissionGranted = true
                        self?.setupSession()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        default:
            DispatchQueue.main.async { self.permissionDenied = true }
        }
    }

    // MARK: — Session setup

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .medium

        // Front camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { session.commitConfiguration(); return }

        session.addInput(input)

        // Video output
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration(); return
        }
        session.addOutput(videoOutput)

        // Mirror front camera
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation     = .portrait
            connection.isVideoMirrored      = true
        }

        session.commitConfiguration()
    }

    // MARK: — Start / Stop

    func start() {
        guard permissionGranted else { return }
        isCalibrating   = true
        calibrationStart = Date()
        calibrationReadings.removeAll()
        processingQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stop() {
        processingQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

// MARK: — Sample buffer delegate (Vision processing)

extension FaceDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .leftMirrored,
                                            options: [:])
        try? handler.perform([faceRequest])

        guard let observation = faceRequest.results?.first as? VNFaceObservation,
              let landmarks   = observation.landmarks
        else {
            DispatchQueue.main.async { self.reading.faceDetected = false }
            return
        }

        let newReading = extractReading(from: landmarks, observation: observation)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.reading = newReading

            // Calibration — collect baseline for 2 seconds
            if self.isCalibrating {
                self.calibrationReadings.append(newReading)
                if let start = self.calibrationStart,
                   Date().timeIntervalSince(start) >= self.calibrationSeconds {
                    self.finishCalibration()
                }
            }
        }
    }

    // MARK: — Landmark extraction

    private func extractReading(from landmarks: VNFaceLandmarks2D,
                                 observation: VNFaceObservation) -> FaceReading {
        var r = FaceReading()
        r.faceDetected = true

        // Jaw openness — distance between top and bottom lip normalised by face height
        if let outerLips = landmarks.outerLips {
            let pts    = outerLips.normalizedPoints
            let topY   = pts.map(\.y).max() ?? 0
            let bottomY = pts.map(\.y).min() ?? 0
            let faceH  = observation.boundingBox.height
            r.jawOpenness = faceH > 0 ? Float((topY - bottomY) / faceH) * 3.5 : 0
            r.jawOpenness = min(1.0, max(0.0, r.jawOpenness))
        }

        // Eye openness — average of left and right
        var eyeValues: [Float] = []
        if let leftEye = landmarks.leftEye {
            eyeValues.append(eyeOpenness(from: leftEye.normalizedPoints))
        }
        if let rightEye = landmarks.rightEye {
            eyeValues.append(eyeOpenness(from: rightEye.normalizedPoints))
        }
        r.eyeOpen = eyeValues.isEmpty ? 0 : eyeValues.reduce(0, +) / Float(eyeValues.count)

        // Smile amount — horizontal stretch of outer lips
        if let outerLips = landmarks.outerLips {
            let pts    = outerLips.normalizedPoints
            let leftX  = pts.map(\.x).min() ?? 0
            let rightX = pts.map(\.x).max() ?? 0
            let faceW  = observation.boundingBox.width
            let stretch = faceW > 0 ? Float((rightX - leftX) / faceW) : 0
            // Normalise: resting ~0.45, max smile ~0.65
            r.smileAmount = min(1.0, max(0.0, (stretch - 0.35) / 0.3))
        }

        // Brow raise — vertical position of medial brow relative to eye
        if let leftBrow = landmarks.leftEyebrow, let leftEye = landmarks.leftEye {
            let browY  = leftBrow.normalizedPoints.map(\.y).max() ?? 0
            let eyeY   = leftEye.normalizedPoints.map(\.y).max() ?? 0
            let faceH  = observation.boundingBox.height
            let gap    = faceH > 0 ? Float((browY - eyeY) / faceH) : 0
            // Normalise: resting ~0.06, raised ~0.12
            r.browRaise = min(1.0, max(0.0, (gap - 0.04) / 0.08))
        }

        // Mouth openness (same as jaw but separate signal)
        r.mouthOpenness = r.jawOpenness

        return r
    }

    private func eyeOpenness(from points: [CGPoint]) -> Float {
        guard points.count >= 6 else { return 0.5 }
        let topY    = points.map(\.y).max() ?? 0
        let bottomY = points.map(\.y).min() ?? 0
        let leftX   = points.map(\.x).min() ?? 0
        let rightX  = points.map(\.x).max() ?? 0
        let width   = rightX - leftX
        guard width > 0 else { return 0.5 }
        let ratio = Float((topY - bottomY) / width)
        // Normalise: closed ~0.05, open ~0.35
        return min(1.0, max(0.0, (ratio - 0.05) / 0.30))
    }

    // MARK: — Calibration

    private func finishCalibration() {
        guard !calibrationReadings.isEmpty else { return }
        let count = Float(calibrationReadings.count)
        baseline.jawOpenness   = calibrationReadings.map(\.jawOpenness).reduce(0, +) / count
        baseline.eyeOpen       = calibrationReadings.map(\.eyeOpen).reduce(0, +) / count
        baseline.smileAmount   = calibrationReadings.map(\.smileAmount).reduce(0, +) / count
        baseline.browRaise     = calibrationReadings.map(\.browRaise).reduce(0, +) / count
        isCalibrating          = false
    }
}
