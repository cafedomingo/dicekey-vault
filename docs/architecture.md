# The app, and how to work on it

Companion documents:

- `derivation.md`: how keys are made
- `security.md`: what is stored and why it is safe
- `catalog-format.md`: the catalog's file, link and code formats
- `design.md`: the look
- `scanning.md`: how the scanner reads a DiceKey

The repository's issues list what is left.

## The app in one paragraph

DiceKey Vault regenerates a few rarely used keys (SSH, WireGuard, age, passphrases, BIP39
wallet phrases) from a DiceKey. It stores no secret. It is one SwiftUI target, for iOS 26
and later and for Mac Catalyst on the Mac. The target uses Observation, async/await and
Swift 6 strict concurrency, and it has no external dependencies. The user scans a DiceKey
with the camera or types it by hand. Two local Swift packages supply the rest. `Derivation`
has two targets: `Derivation`, for recipes and derived values, and `KeyFormats`, for key
encodings and BIP39. `ReadDiceKey` holds the generated face specification, with the font
that the dice are printed in, and the DiceKey scanner. The app and its packages contain no
Objective-C or C++. The one C++ file is the driver of `scripts/compare-upstream/`.

## Goals, in priority order

1. **Always be able to read a DiceKey and re-derive the same secrets.** The derivation and
   the scanner are Swift code. You build them from sources in this repository. The project
   checks each against something independent of it (`derivation.md`, `scanning.md`). Any
   change that alters derived output is a bug.
2. Build with the current Xcode against the current SDKs. Use Swift 6 language mode, strict
   concurrency and no deprecated APIs. GitHub Actions macOS runners compile the app, so the
   SDK floor follows what they ship. The runners have no iOS 27 SDK, so the deployment
   target is 26.
3. Use Liquid Glass throughout (`design.md`), with system chrome where possible. Make sure
   nothing in the interface conflicts with the system look.

## Shape of the app

`ContentView` is a two-column `NavigationSplitView` driven by selection. The sidebar
(`DiceKeyList`, home) lists every DiceKey with its keys. In the sidebar, you pick a DiceKey,
a key or New key. The detail column is a `NavigationStack` that shows the selection. When
you open a key or New key from a `DiceKeyScreen`, the stack pushes it over that screen.
Where the detail column is beside home, the stack pushes the scanner over whatever the
column shows. A phone shows the same columns as a stack. It selects the scanner in place of
home. A large phone in landscape shows the columns side by side. It hides home while the
scanner is open, because the camera and the keypad need the whole width there.

- **`UnlockedDiceKeys`** (`@Observable`) is the only holder of DiceKeys in memory. The
  DiceKey in use, the last one opened or unlocked, stays unlocked while the app is open,
  including while the app shows home. Any other DiceKey locks after the lock delay
  (`security.md`) once it stops being in use. All DiceKeys lock that long after the app goes
  to the background.
- **The keychain service** (`SavedDiceKeys`) can keep a DiceKey on this device, protected by
  user presence (Face ID, Touch ID or the passcode). It is never synced or restored
  elsewhere.
- **The catalog** (SwiftData, `Model/Catalog.swift`: `DiceKeyRecord`, `KeyEntry`) holds only
  non-secret metadata. This is enough to derive each key again. `security.md` says what the
  catalog holds. `catalog-format.md` defines its fields, and defines how it travels as a
  file, a link and a code.
- **`Derivation`**: `KeyRecipe` turns a kind and a name into canonical recipe JSON. It reads
  the JSON back only in that form. `DerivedKey` derives the keys of a recipe, one key for
  each of the kind's algorithms (`KeyKind.algorithms`). It also encodes each key.
  `scripts/derive-kinds.py`, an independent implementation, writes `Fixtures/kinds.json`.
- **`ReadDiceKey`** is the scanner. `scripts/compare-upstream/compare-upstream.sh` also
  reads the photo corpus of `ReadDiceKey` with DiceKeys' own scanner, for the comparison in
  `scanning.md`.

## Where things live

```
DiceKeyVault/
  App/        entry point, ContentView, UnlockedDiceKeys
  Model/      DiceKey and its faces, the SwiftData catalog, CatalogFile, PaperPayload, RecoveryCode,
              ScannedCode
  Services/   what talks to the OS: Camera, Keychain, Clipboard, DeviceOwner
  Features/   one folder per area: DiceKeys, Keys, Load (scanning and typing), Catalog
              (import, export, restore), Paper, Settings
  Shared/     components used across features, and the layout tokens
Packages/     Derivation, ReadDiceKey
Tests/        DiceKeyVaultTests (Swift Testing), DiceKeyVaultUITests (ScreenWalk, run by
              scripts/screen-walk.sh, not by CI)
```

The XcodeGen spec includes all of `DiceKeyVault/`.

## Compatibility

Everything the app writes outside itself must read the same in every later version. A test
pins each part. If one of these tests fails, the change breaks data that the app already
wrote. Fix the change, never the test. Formats grow only by adding. Anything else needs a
migration, which you decide on purpose.

| What | Pinned by |
|---|---|
| Derived keys, seeds and the DiceKey id (`derivation.md`) | `kinds.json`: `KindVectorTests`, `DiceKeySeedTests` |
| Paper and exported files (`catalog-format.md`) | the file fixture (v1) and the paper fixtures (v2): `CatalogFormatV1Tests`, `PaperFormatV2Tests` |
| The store, which syncs to devices on other versions: you may add attributes, but never rename, remove or retype them | `CompatibilityTests` |
| The bundle identifier, store name, sync setting, URL scheme and recovery prefix | `CompatibilityTests` |
| A saved DiceKey: its text, named by its id | `SavedDiceKeysTests` |

## Patterns

- **Errors**: the app catches an error into a `PresentableError?` and shows it with
  `.errorAlert(_:)`.
- **Async**: the app uses `async/await` and `Task`, and defines no actors of its own. The
  only `DispatchQueue` in the app is the serial queue that AVFoundation requires, where the
  app scans camera frames. The scanner itself uses `DispatchQueue.concurrentPerform`.
- **Look**: `design.md`.

## Working on it

The Xcode project is generated and git-ignored. **Edit `project.yml`, never the project.**

Signing needs one per-developer file, `Config/Signing.local.xcconfig`, which is git-ignored.
`Config/Signing.xcconfig` holds a committed default for everything else, including the
bundle identifier. The identifier is `com.cafedomingo.dicekeys`, because `com.dicekeys`
belongs to DiceKeys, LLC, and identifiers are globally unique.

1. Generate the Xcode project:

   ```
   swift run --package-path BuildTools xcodegen generate
   ```

2. Create `Config/Signing.local.xcconfig` with your development team:

   ```
   DEVELOPMENT_TEAM = ABCDE12345
   ```

3. Open the project in Xcode, and use the scheme `DiceKeyVault`:

   ```
   open DiceKeyVault.xcodeproj    # scheme: DiceKeyVault
   ```

4. If Xcode offers to change project settings, cancel. The next `xcodegen generate` discards
   anything that Xcode writes, and the prompt comes back. Put the setting in `project.yml`
   instead.
5. From Xcode, run the app on My Mac (Mac Catalyst) once. This registers the Mac.

The project does not offer Designed for iPad. When the app ran that way, macOS:

- reported every camera as upright at 0 degrees, though each camera needed its own turn
- did not list a USB webcam anywhere
- zoomed a Continuity Camera too far

## Getting a build onto a device

`scripts/testflight.sh` archives and uploads the iOS and Mac builds. The script computes the
versions at upload time, so nothing in the repository needs a new version number. The
marketing version is the build date (`2026.9.23`). The build number is a minute-resolution
timestamp.

The script needs a **paid** Apple Developer Program membership. A free Personal Team cannot
upload to App Store Connect at all. It can only install over a cable, or over Wi-Fi after
you pair the phone once in Xcode. Its builds expire after seven days.

Before a first upload:

1. Create an app record for the bundle identifier under My Apps in App Store Connect. App
   Store Connect needs this record, and you create it by hand.
2. If the membership is freshly upgraded, accept the Program License Agreement. A freshly
   upgraded membership usually has this agreement unsigned. Until you accept it, it blocks
   distribution profiles with a confusing permissions error.

Before shipping, deploy the CloudKit schema to production. The development schema gains a
field only once a development build syncs a record that has it. So when a release adds a
field:

1. Run a build from Xcode with sync on.
2. Use whatever stores the new field.
3. Check that the record type has the field (`CD_KeyEntry` has `CD_publicKeys`, for
   instance).
4. In the CloudKit console, deploy the schema to production.

TestFlight builds expire after ninety days. No setting changes this. To get a new build, run
the script again.

## What CI covers

`.github/workflows/build.yml` sets the Xcode version on GitHub-hosted macOS runners. CI
covers:

- `swift test -c release` for each package. In `Packages/Derivation`, it tests the kinds
  fixture, recipe validation, the key formats and RFC 5869's HKDF vectors. In
  `Packages/ReadDiceKey`, it tests the scanner over its photo corpus and drawn keys.
- XcodeGen runs first. Then CI builds the iOS app for the simulator and runs its Swift
  Testing suite there.
- CI builds the Mac app with Mac Catalyst, unsigned. This covers the code under
  `targetEnvironment(macCatalyst)`, which the iOS builds skip.
- On Ubuntu, CI runs `swift format lint --strict`, SwiftLint, ruff, shellcheck and
  actionlint. The toolchain formatter decides the layout, and `.swift-format` configures it.
  CI also runs `derive-kinds.py --tools`, which checks the public keys against `ssh-keygen`,
  `wg` and `age-keygen`.

If a pull request changes only `docs/`, `scripts/` and top-level Markdown, CI skips the
macOS jobs.
