//
//  InterfaceOrientationTests.swift
//  DiceKeyVaultTests
//

import Foundation
import Testing

@Suite("Interface orientation")
struct InterfaceOrientationTests {
    /// Read from the file, since on an iPad the bundle answers this key with the `~ipad` list.
    @Test("a phone turns the interface to portrait and both landscapes, as the camera turns its picture")
    func phoneTurnsWithTheCamera() throws {
        let url = try #require(Bundle.main.url(forResource: "Info", withExtension: "plist"))
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let orientations = try #require((plist as? [String: Any])?["UISupportedInterfaceOrientations"] as? [String])
        #expect(
            Set(orientations) == [
                "UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft",
                "UIInterfaceOrientationLandscapeRight"
            ])
    }
}
