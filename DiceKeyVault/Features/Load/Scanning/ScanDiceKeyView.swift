//
//  ScanDiceKeyView.swift
//  DiceKeyVault
//

import AVFoundation
import SwiftUI

/// The camera preview with the read-faces overlay and floating controls. What it reads is
/// acted on by whoever holds `scanner`.
struct ScanDiceKeyView: View {
    @Bindable var scanner: ScannerState
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            switch scanner.cameraAuthorized {
            case .some(true):
                layout {
                    camera.layoutPriority(isCompactHeight ? 1 : 0)
                    status
                }
            case .some(false):
                ContentUnavailableView(
                    "Camera Access Needed",
                    systemImage: "camera",
                    description: Text("Permission to access the camera is required to scan your DiceKey")
                )
            case .none:
                ProgressView()
            }
        }
        .task {
            scanner.cameraAuthorized = await ActiveCameras.requestAccessIfNeeded()
            scanner.cameras = ActiveCameras.get()
        }
        // The first camera, until one is chosen, and again if the chosen one goes away.
        .onChange(of: scanner.cameras) { _, cameras in
            if !cameras.contains(where: { $0.uniqueID == scanner.selectedCameraID }) {
                scanner.selectedCameraID = cameras.first?.uniqueID
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVCaptureDevice.wasConnectedNotification)) { _ in
            scanner.cameras = ActiveCameras.get()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVCaptureDevice.wasDisconnectedNotification)) { _ in
            scanner.cameras = ActiveCameras.get()
        }
        .errorAlert($scanner.cameraError)
    }

    private var isCompactHeight: Bool { verticalSizeClass == .compact }

    /// The status sits beside the camera in a compact-height window, such as a phone in landscape,
    /// where the camera is sized first so it fills the height, and under it otherwise. One layout
    /// either way, so the camera keeps running through a turn.
    private var layout: AnyLayout {
        isCompactHeight ? AnyLayout(HStackLayout(spacing: .space4)) : AnyLayout(VStackLayout(spacing: .space3))
    }

    private var status: some View {
        VStack(spacing: 0) {
            Text("\(scanner.model.facesRead) of \(DiceKey.faceCount) dice read")
                .font(.headline)
                .monospacedDigit()
                .fixedSize()
            Text(
                scanner.model.hasRepeatedLetters
                    ? "Two dice share a letter, so these aren't one DiceKey. Check for a die from another set."
                    : "Hold the box flat, lid off, or show a list card or recovery sheet"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var camera: some View {
        GeometryReader { reader in
            let size = CGSize(width: reader.size.width, height: reader.size.width)
            ZStack(alignment: .bottom) {
                CameraPreviewView(preview: scanner.preview, camera: scanner.selectedCamera)
                FacesReadOverlay(
                    renderedSize: size,
                    dice: scanner.model.dice,
                    imageFrameSize: scanner.model.imageFrameSize
                )
                ScanControls(
                    cameras: scanner.cameras, selectedCameraID: $scanner.selectedCameraID,
                    torchOn: $scanner.torchOn)
            }
            .frame(width: size.width, height: size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color.camera)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMd))
        .padding(.vertical, .space1)
    }
}

#Preview {
    ScanDiceKeyView(scanner: ScannerState())
}
