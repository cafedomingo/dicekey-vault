//
//  DiceKeyVaultApp.swift
//  DiceKeyVault
//

import SwiftData
import SwiftUI
import UIKit

@main
struct DiceKeyVaultApp: App {
    @State private var unlocked = UnlockedDiceKeys()
    @State private var saved = SavedDiceKeys()
    private let catalog: ModelContainer
    /// Why the synced store didn't open, when the app fell back to this device's copy so
    /// Settings stays reachable to turn sync off.
    private let syncFailure: String?
    // Not `@State`: it is never read from `body`, and reading a `@State` value from an
    // initializer is outside what SwiftUI supports.
    private let privacyCover = PrivacyCoverWindowController()

    init() {
        do {
            catalog = try Catalog.container()
            syncFailure = nil
        } catch let error where Catalog.syncsThisLaunch {
            do {
                catalog = try Catalog.container(syncing: false)
            } catch {
                fatalError("The catalog store can't be opened: \(error)")
            }
            syncFailure = error.localizedDescription
        } catch {
            fatalError("The catalog store can't be opened: \(error)")
        }
        privacyCover.startObserving()
        Self.configureScenes()
    }

    /// Every scene is elevated, as a sheet is, so that in dark the system draws list rows a step
    /// lighter than `bg` and keeps its own tap and selection highlights. On the Mac, the window
    /// hides its title, because the sidebar already shows the app's name as its title.
    /// `queue: nil` delivers on the posting thread, and UIKit connects scenes on the main thread.
    private static func configureScenes() {
        _ = NotificationCenter.default.addObserver(
            forName: UIScene.willConnectNotification, object: nil, queue: nil
        ) { note in
            guard let scene = note.object as? UIWindowScene else { return }
            MainActor.assumeIsolated {
                scene.traitOverrides.userInterfaceLevel = .elevated
                #if targetEnvironment(macCatalyst)
                    scene.titlebar?.titleVisibility = .hidden
                #endif
            }
        }
    }

    /// The Mac's first window, in the iPad points that the Mac app scales down: home's sidebar at
    /// the 416 points that the Mac gives it, beside content at `contentWidth` with the system's
    /// 20-point list margins, since a wider window only widens the margins. It is taller than wide,
    /// for the keys, and macOS shrinks it to fit a smaller screen.
    private static let macWindowSize = CGSize(width: 416 + .contentWidth + 2 * 20, height: 1000)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(unlocked)
                .environment(saved)
                .modelContainer(catalog)
                .environment(\.catalogSyncFailure, syncFailure)
        }
        #if targetEnvironment(macCatalyst)
            .defaultSize(Self.macWindowSize)
        #endif
    }
}

extension EnvironmentValues {
    @Entry var catalogSyncFailure: String?
}
