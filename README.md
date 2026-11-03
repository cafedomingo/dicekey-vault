# DiceKey Vault

DiceKey Vault regenerates a few rarely used keys (SSH, WireGuard, age, passphrases and BIP39 wallet phrases) from a [DiceKey](https://dicekeys.com). It stores none of them. Scan or type the 25 dice, and the app derives the same keys every time.

It isn't a password manager. For daily use, a box of dice could never be better than a password manager. A DiceKey is an offline root secret. It suits the few keys that you rarely use and that are costly to lose. You regenerate these keys in the app, and you never use them there.

It reads DiceKeys. DiceKeys, LLC makes them. It isn't their app. It began as a fork of [dicekeys/dicekeys-app-ios](https://github.com/dicekeys/dicekeys-app-ios).

## Documentation

- [Architecture](docs/architecture.md): the shape of the app and how to work on it.
- [Derivation](docs/derivation.md): how keys are made.
- [Security](docs/security.md): what is stored and why it is safe.
- [Catalog format](docs/catalog-format.md): the file, link and code that carry the catalog.
- [Design](docs/design.md): the look, and the tokens behind it.
- [Scanning](docs/scanning.md): how the scanner reads a DiceKey.
- [Issues](https://github.com/cafedomingo/dicekey-vault/issues): what is left.

## Building

You need the Xcode version named by `xcodeVersion` in `project.yml`.
[XcodeGen](https://github.com/yonaskolb/XcodeGen) generates the project. `BuildTools/` pins
XcodeGen, and the first use builds it (about a minute).

1. Generate the Xcode project:

   ```
   swift run --package-path BuildTools xcodegen generate
   ```

2. Put your Apple Developer team id in `Config/Signing.local.xcconfig`.
3. Open the project:

   ```
   open DiceKeyVault.xcodeproj
   ```

4. Select the `DiceKeyVault` scheme and a device.
5. Choose Product → Run.

Before you commit, format the code:

```
swift format format --in-place --recursive DiceKeyVault Packages Tests   # before committing
```

Key derivation and the DiceKey scanner are pure Swift, in the local packages
`Packages/Derivation` and `Packages/ReadDiceKey`.

## Testing the app

You need a DiceKey, a box of 25 dice, to scan with the camera. If you don't have one, do
these steps:

1. Go to https://dicekeys.app.
2. Generate a random DiceKey: a throwaway one, never your real DiceKey.
3. Scan the picture of its 25 dice from another screen.

`scripts/testflight.sh` builds the app and uploads it to TestFlight. See the architecture
document.

## License

Original work here is MIT-licensed (see [LICENSE](LICENSE)), but parts derive from DiceKeys,
LLC's original code, which has no open-source license yet, so this app is for personal use
and TestFlight only until DiceKeys, LLC picks one. Every third-party component and its terms
is in [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES).
