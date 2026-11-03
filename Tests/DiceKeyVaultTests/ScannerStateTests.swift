//
//  ScannerStateTests.swift
//  DiceKeyVaultTests
//

import Testing

@testable import DiceKeyVault

@MainActor
@Suite("Holding the scanner")
struct ScannerStateTests {
    @Test("a closed scanner is released, and what it read with it")
    func released() {
        weak var released: ScannerState?
        weak var releasedPreview: CameraPreview?
        do {
            let scanner = ScannerState()
            releasedPreview = scanner.preview
            scanner.close()
            released = scanner
        }
        #expect(released == nil)
        #expect(releasedPreview == nil)
    }
}
