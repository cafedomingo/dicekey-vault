//
//  CameraPreviewView.swift
//  DiceKeyVault
//

import AVFoundation
import SwiftUI

/// Shows `preview`, which keeps running when a resize starts a new scanner screen and moves to it.
struct CameraPreviewView {
    let preview: CameraPreview
    let camera: AVCaptureDevice?
}

extension CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreview.Host {
        CameraPreview.Host(preview: preview)
    }

    func updateUIView(_ host: CameraPreview.Host, context: Context) {
        preview.update(camera: camera)
    }
}

/// The camera's session and its picture, which outlast any one scanner screen. The picture's
/// view moves to the newest host in a window, since a rebuilt screen's host can enter a window
/// before or after the old one leaves, or never. Runs until `tearDown` or until released, as
/// when a window closes while scanning.
@MainActor
final class CameraPreview {
    final class Host: UIView {
        let preview: CameraPreview

        init(preview: CameraPreview) {
            self.preview = preview
            super.init(frame: .zero)
            preview.hosts.append(WeakHost(host: self))
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            preview.place()
        }
    }

    private struct WeakHost {
        weak var host: Host?
    }

    /// Keeps the preview layer the size of the view.
    private final class LayerFillingView: UIView {
        override func layoutSublayers(of layer: CALayer) {
            super.layoutSublayers(of: layer)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for sublayer in layer.sublayers ?? [] { sublayer.frame = layer.bounds }
            CATransaction.commit()
        }
    }

    private let view = LayerFillingView()
    private var hosts: [WeakHost] = []
    private let session: CameraSession
    private var currentCameraID: String?
    private var startTask: Task<Void, Never>?
    /// Called when the session cannot start, so the screen can say so rather than
    /// showing a black rectangle with no explanation.
    private let onFailure: @MainActor (any Error) -> Void

    init(
        onFrame: @escaping @MainActor @Sendable (ScannedFrame) -> Void,
        onFailure: @escaping @MainActor (any Error) -> Void
    ) {
        session = CameraSession(onFrame: onFrame)
        self.onFailure = onFailure
        view.backgroundColor = UIColor.camera
        view.clipsToBounds = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    isolated deinit {
        tearDown()
    }

    private func place() {
        hosts.removeAll { $0.host == nil }
        guard let host = hosts.last(where: { $0.host?.window != nil })?.host, view.superview !== host else { return }
        view.frame = host.bounds
        host.addSubview(view)
    }

    /// Starts `camera` when it changes, or stops for none. A camera that failed to start is
    /// tried again on the next update.
    func update(camera: AVCaptureDevice?) {
        guard camera?.uniqueID != currentCameraID else { return }
        currentCameraID = camera?.uniqueID
        startTask?.cancel()
        startTask = Task { [session, view] in
            guard let camera else {
                await session.stop()
                return
            }
            do {
                try await session.start(camera: camera)
            } catch {
                self.currentCameraID = nil
                self.onFailure(error)
                return
            }
            guard !Task.isCancelled, let previewLayer = session.previewLayer else { return }
            view.layer.insertSublayer(previewLayer, at: 0)
            view.layer.setNeedsLayout()
        }
    }

    func tearDown() {
        startTask?.cancel()
        let session = session
        Task { await session.stop() }
    }
}
