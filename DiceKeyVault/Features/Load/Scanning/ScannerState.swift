//
//  ScannerState.swift
//  DiceKeyVault
//

import AVFoundation
import Observation

/// The scanner's camera, still running, and what it has read. Held, and its reads acted on, above
/// the scanner's screen: a resize or a large phone's turn can move the scanner and start a new
/// screen, which carries on with these, and two screens can be up for a moment.
@MainActor @Observable
final class ScannerState {
    let model = DiceKeyScanModel()
    var cameraAuthorized: Bool?
    /// Discovered once and again when a camera connects or disconnects, not per render:
    /// the scanner's body re-evaluates on every scanned frame.
    var cameras: [AVCaptureDevice] = []
    var selectedCameraID: String?
    var torchOn = false
    var cameraError: PresentableError?
    /// Made when first shown, since a `@State` default is made again each time its view is.
    @ObservationIgnored private(set) lazy var preview = CameraPreview(
        onFrame: { [model] frame in model.apply(frame) },
        onFailure: { [weak self] error in
            self?.cameraError = PresentableError(title: "Camera Unavailable", error: error)
        })

    var selectedCamera: AVCaptureDevice? {
        cameras.first { $0.uniqueID == selectedCameraID }
    }

    /// Stops the camera now, rather than whenever the state is released.
    func close() {
        preview.tearDown()
    }
}
