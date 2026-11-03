# What is stored, and why it is safe

The DiceKey is the only secret. Everything else is either derived from it on demand, or public. `derivation.md` explains why the derivation is safe. This document is about what the app and the user keep, and where.

## Who learns what

- **Someone with the DiceKey, or a recovery sheet,** has every key.
- **Someone with the catalog, a list card, the iCloud copy, a public key or the id** learns key names, kinds and public keys (a list card has no public keys). They also learn about 9 bits of the dice, from the center die. They can derive nothing, because the dice carry about 196 bits.
- **Someone who learns one derived secret** learns nothing about the DiceKey or any other key.
- **Someone who saw part of the dice** can use the id or a public key to check guesses for the rest. That stays harmless only while most of the dice are unseen.
- **If you lose the DiceKey and every recovery sheet, you lose every key.** Nothing that is stored can recover them.

| What | Where | For how long |
|---|---|---|
| The DiceKey | Memory (`UnlockedDiceKeys`) | See the first list after this table |
| The DiceKey, if "Keep on this device" | Keychain: `WhenUnlockedThisDeviceOnly`, `.userPresence`, not synchronizable | Until you turn it off or use Forget |
| Derived keys | Memory | The app drops them on Hide, on lock, on background, on screen capture and on a screenshot, and when you leave New key. The second list after this table has more |
| The catalog | SwiftData store, with iOS's default file protection (complete until the first unlock after a restart). After that unlock, the app can access it while the device is locked, so synced changes can arrive then. It holds nothing secret | Until you use Forget |
| A copied secret | Pasteboard, local only (no Universal Clipboard) | 60 seconds. The system enforces this |
| A list card | Paper, kept in the box | No secret: the same fields as the catalog, without public keys |
| A recovery sheet | Paper, and a PDF only if you save the sheet, or save it from the print dialog | The DiceKey itself, until someone destroys the paper or file |
| A shared secret | Wherever you send it from the share sheet. This includes the sheet's own Copy, which neither stays local nor expires. The app exports SSH and age identities as plain files, with no passphrase | The destination decides |

- **The DiceKey in memory.** The DiceKey in use is the last one opened or unlocked. The app keeps the DiceKey in memory while it is the DiceKey in use and the app is open. Otherwise, the app keeps it for the lock delay, 59 seconds (`UnlockedDiceKeys.lockDelay`), after it stops being in use. When the app goes to the background, the DiceKey stays in memory. It stays until the app comes back at least the lock delay later, or until iOS ends the app.
- **Derived keys in memory.** The app holds a derived key while New key shows its draft, and while the key is revealed on screen. The draft derives the whole key, even when only the public half shows. To fill in a key's public keys, the app derives the whole key. The app keeps the public keys and drops the rest at once.

## The keychain copy

The keychain requires Face ID, Touch ID or the passcode to read the copy back, and enforces this itself. The copy is never synced to iCloud Keychain. It is never in a backup that another device can restore. It is unreadable while the device is locked. Forget deletes it before it does anything else, and stops if it can't delete it.

## The catalog, and iCloud

The catalog holds what the app needs to derive each key again, and nothing that unlocks one. For each DiceKey, it holds its id, name, center die and the date the app first saw it. For each key, it holds its DiceKey's id, its recipe, each algorithm's public key and the date it was created. `catalog-format.md` has the fields.

A DiceKey's default keys (`derivation.md`) are keys like the rest. The catalog holds their recipes, which are the same fixed texts for every DiceKey, and their public keys. For age, the public keys are both recipients, X25519 and post-quantum.

The Sync with iCloud switch is in Settings, and it is off by default. When it is on, SwiftData sends the catalog to the user's private CloudKit database, `iCloud.com.cafedomingo.dicekeys`. This is safe because:

- **The id is one-way.** It is a 16-byte HKDF output from the DiceKey's 196 bits (`derivation.md`). Nothing about the dice can be recovered from it. To check a guess, you need the guess.
- **Public keys are public.** They exist to be given to other people. A name says only what the key is for.
- **Nothing derives without the dice.** Kind, name and style are inputs, not secrets. Without the physical DiceKey, they open nothing. The center die is one face of 25, which is about 9 of the DiceKey's 196 bits. The app shows it so the user can distinguish the boxes.
- The DiceKey itself never syncs. Each device scans it, or keeps its own keychain copy.

What Apple could see is metadata. It could see that a key named "wallet" exists. It couldn't see the wallet. With Advanced Data Protection, the catalog is end-to-end encrypted. When you turn sync off, syncing stops, but the iCloud copy stays. Delete it in the device's iCloud storage settings.

You can export the same catalog from Settings as a readable JSON file, and keep the file anywhere instead of iCloud. The app also prints a list card for each DiceKey's box. The card's QR code restores the DiceKey's list. Both hold only non-secret fields, and the card has no public keys. When you import, the app only adds what is missing.

A change to the switch applies at the next launch. The store opens once for each launch, because two CloudKit mirrors of one store file aren't supported. If the synced store won't open, the app opens the same store without sync, and Settings says why. The app does this so that it doesn't fail at every launch. Changes from other devices can arrive at any time after the device's first unlock.

When two devices each scan a DiceKey before they sync, each device makes a record. One record represents the DiceKey everywhere, and it is the same record on every device. The app chooses it in this order:

- a renamed record, over a record still named for its center die
- then the oldest record
- then by name

Forget removes all the records. Keys need no such step. The app tells keys apart by what they derive, so copies of one key show once. This includes default keys.

## The recovery sheet

The recovery sheet is the one place where the app puts the DiceKey on paper. It holds the grid, the faces written out, and a code that holds the faces and the list. The app allows this on purpose, for someone who accepts that the sheet is the DiceKey. The app makes the choice deliberate:

- The app asks for Face ID or the passcode first.
- The preview stays concealed until Show. The app conceals it again on background, capture or a screenshot.
- You can't print or save the sheet while the screen is captured.

Print goes straight to AirPrint and leaves no file. However, the system's print dialog can still share the page as a PDF. Save as PDF warns first. The preview on screen is an image of the page, so you can't select or copy its text. The code is text with its own prefix, not a link. So iOS never handles the faces as a link. The code is an Aztec code, not a QR code, so the Camera app doesn't offer to search its text. When you restore, the app asks first. In the same alert, it asks whether to keep the DiceKey on this device.

## On screen

The app switcher shows a plain cover. The app shows the cover synchronously when the scene goes to the background. UIKit takes the switcher's snapshot at that time (Apple's QA1838), so the snapshot that UIKit keeps holds no secret. The DiceKey's grid starts concealed. The app hides it again when the user leaves the app, and on capture or a screenshot. A screenshot can't be blocked. The app hides any revealed secret afterwards, so that the next screenshot doesn't capture it. The app drops typed dice when it comes back at least the lock delay after it left. The app locks an unlocked DiceKey in the same case.

Before the app shows the cover, the switcher can briefly show the screen as it was. Other password managers do the same. A revealed secret and the grid hide as soon as the app stops being active, so they are hidden by then. But typed dice and the camera's view stay until the scene goes to the background. Apple has no app API for more protection. The system applies `privacySensitive()` only for widgets on the Lock Screen and Always On displays. If the app put the content inside a secure text field's layer, that would block screenshots, recording and snapshots. But this method is undocumented, and it can break with any iOS release. So the app doesn't do it.

## Limits

Swift can't reliably zero memory, so a derived value may remain in memory until the app reuses that memory. If someone compromises the device while a DiceKey is unlocked, they can read the DiceKey. The lock delay keeps that time short. A suspended app runs no timer. So a DiceKey that is unlocked when the app leaves stays in memory. It stays until the app comes back and locks it, or until iOS ends the app. You can't rotate a key in place. A key is a function of the DiceKey and its name. A default key has no name. So a new key needs a new name, and you can't replace a default key.
