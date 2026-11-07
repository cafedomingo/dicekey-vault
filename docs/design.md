# DiceKey Vault design

DiceKey Vault turns a DiceKey (25 dice in a sealed box) into the few keys that you rarely use and that are expensive to lose. These are SSH client and host keys, WireGuard, age, a wallet's recovery phrase, and passphrases for anything that needs only a password. The app regenerates those keys. You never use them in the app. You open the app a few times a year. So every screen must be clear the first time you see it, with nothing to learn first.

"DiceKey Vault" is the working name. The name refers to the DiceKey that the app works with, and About credits DiceKeys, LLC, who make the dice. The app uses none of their branding. The app stores no secrets: the vault is the box of dice.

## Principles

- **The derivation is the product.** A DiceKey plus a kind plus a name always gives the same key. The interface's only job is to make those three inputs unambiguous and to show the output carefully.
- **The camera is the only setup.** The app has no assembly walkthroughs, illustrations, tours or onboarding. Before the first DiceKey, home is one line and one button to the camera.
- **Public by default, secret on purpose.** The public half or fingerprint of a key shows freely. The secret half stays concealed until you deliberately tap Reveal. When you copy the secret, the app says when it clears. `security.md` has the protections behind both.
- **The scan is the only check.** A scanned DiceKey is either one the app recorded before, with its name and keys, or one it records for the first time. The status calls the second kind "New DiceKey". An unexpected "New DiceKey" is the sign of a misread die or the wrong box, so the status says it plainly. Keys carry no verify state of their own. Each key derives the same way every time.
- **Making a key is looking it up.** A kind plus a name gives the key immediately. So New key shows the result live as you type. Save only adds the key to the catalog.
- **Capture on the best camera, derive on the safest machine.** The phone reads the DiceKey best. The Mac app scans with the Mac's cameras or Continuity Camera. So a desktop is a suitable place to derive and export, on the same screens.

## Platform: iOS 27 and later, Liquid Glass

- The app is a native SwiftUI app built from stock components. It has one two-column `NavigationSplitView` for every size. The sidebar is home, with every DiceKey and its keys. The detail column shows whichever of them is selected. The app pushes a key that you open from a DiceKey over that DiceKey. A phone shows the columns as a stack. The system draws the glass. This design only decides what goes on the glass.
- **There are two layers.** The navigation layer is glass: toolbars, the sidebar, sheets, and controls over the camera. The content layer is flat: rows, the DiceKey grid, keys and secrets. Never put glass on content, and never stack glass on glass.
- The tint is `accent-ink`. Use `.buttonStyle(.glassProminent)` only for the screen's one primary action, and `.glass` for the other controls on the glass layer.
- The Mac app uses the iPad layout and is built with Mac Catalyst. Its first window fits home beside a DiceKey's screen at `content-width`, because a wider window only widens the margins.
- New key is a draft of the key's own detail, never a sheet. It is a pushed screen on iPhone. Where there is a detail column, it is in that column. Keep sheets for Settings and the paper previews. The app asks for a confirmation, such as Forget, in a dialog.
- Controls over the camera are system glass.

## App icon

The icon is a layered Icon Composer icon: a deep petrol ground, with the DiceKey grid as the foreground layer. All 25 cells use the dark value of `accent`, which stays visible on the petrol. Each cell has its `on-accent` orientation bar, as in a whole DiceKey. The icon has all four appearances: Default (petrol), Dark (near-black ground), Clear (glass cells, light bars) and Tinted (monochrome, where the system supplies the hue). The files are in `docs/design/`. `app-icon-foreground.svg` is the grid layer for Icon Composer. The other two are flattened Default and Dark renders. Don't add a letterform, a die in perspective or a key glyph.

## Content

- Use sentence case everywhere except `label` section labels, which are capitals. Address the user as "you" and never say "we".
- Put the verb first on buttons: "Scan DiceKey", "Type it in", "New key", "Reveal", "Copy", "Share", "Delete key", "Forget", "Forget DiceKey and its keys".
- Call the thing the user holds a "DiceKey". Call each derived output a "key", even a passphrase or recovery phrase. Call the free-text input the "name", never "label", "purpose" or "recipe".
- Status lines state facts: "Home box · 5 keys", "New DiceKey", "17 of 25 dice read", "Locks in 4:52", "Clears in 1 minute". Don't use exclamation marks or emoji.
- The default name of a DiceKey is "DiceKey with M1 in center", which uses its center die. The user can rename a DiceKey at any time, and the center die stays its avatar whatever the name.
- Never explain cryptography in the interface. Name each kind for the tool that it feeds: SSH, WireGuard, age, Passphrase, Wallet.

## Color

- The neutrals are iOS's own. The `ink` and `ink-muted` text, the `bg-raised` rows and the `line` separators come from stock components. So dark mode and Increase Contrast work without a custom palette. The one custom neutral is the ground, `bg`. It is plain, with one motif and no wash or gradient. The app uses the elevated level, as a sheet does. So in dark the `bg-raised` rows are iOS's elevated gray, a step lighter than its usual gray. They stand out from the ground.
- In dark, the dice and the neutrals invert. Each keeps its hue and flips its lightness, so nothing that is neutral in light is tinted in dark.
- `accent` (petrol) is the one hue. It marks the moment when the machine reads something: a die that the camera just read, the selected die, and the primary action. Use it as a fill only, and put `on-accent` text on it. When you need the accent as text or a mark, use `accent-ink`, which is also the app's tint. `accent-soft` is the ground of a key's kind icon. Home's list is the exception. Its selected row is a fill with white text, so the list has the tint `accent`.
- The one motif of the ground is the corner dice: outlined dice with their bars, turned as on the icon. They sit on a grid tilted 15° from the top right corner, and they fade out within 460 points of that corner. They are `ink`, with an opacity of at most 10% for outlines and 16% for bars (12% and 18% in dark), never the accent. On a phone they extend past the title and the first section headers. They are faint enough to read through, and rows sit on `bg-raised` above them. `appBackdrop()` draws them behind every list and form, once per screen. A sidebar beside a detail column leaves them out. The app leaves them out under Increase Contrast, and behind the camera and the typing screen, where the real dice are.
- The primary action is `accent` with an `on-accent` label. This is the glass-prominent tint, in both themes. Allow one primary action per screen.
- `danger` means only destruction, and the recovery sheet's warning that the page is the DiceKey. The app tells you about a misread die in words under the camera, in `ink-muted`. Success has no color of its own. A passphrase's strength bar is the one graded scale (`strength-weak` to `strength-strong`).
- The camera image sits on `camera` black in every theme. `camera-dim` covers everything outside a window in the middle of the image, where the DiceKey goes. It shows only while the camera reads no die.
- Draw a die as the real one looks: a light `die-face` with an `on-die` glyph, in the dark `die-box`. In dark, all three dim, and the dice stay lighter than the box: gray dice with light glyphs in a near-black petrol box. So 25 faces don't glare. In dark, a `die-edge` outline sets the box off from `bg-raised`. A dark die has a `die-edge` rim only where it sits outside the box. The rim gives it the outline that its shadow gives a light die. In the box, a rim on every die blurs the grid.
- Put a `die-dot` at each crossing where four dice meet, in both themes. Without the dot, the eye fills every crossing that it isn't looking at with a gray haze (the Hermann grid illusion). Rounder corners, a softer box and dice set askew don't stop the haze. A dot that is just big enough to see does.

## Type

- Use system faces for everything except the dice: `sans` for interface text, and `mono` for secrets, public keys and fingerprints.
- `dice` (Inconsolata Bold) is the face printed on the physical dice, so a die on screen looks like the die in your hand. The app uses it only in the `die` style, wherever it draws a DiceKey, and never for other text.
- Each screen has one `display` title. Use `headline` for row names, `subhead` for the line under a name, `caption` for status and `label` for section labels. Every style except `die` is an iOS text style, so it follows Dynamic Type.
- `secret` and `key` text wraps between any two characters. The app adds no hyphen at the break, because a hyphen would look like part of the value. The app never truncates this text with an ellipsis. Shorten a fingerprint by choosing a shorter format, never by cutting it. The one exception is age's post-quantum recipient, about 1,950 characters. It opens folded to four lines with "Show all 1959 characters", and Copy and Share always take the whole recipient.

## Layout and shape

- Screens are stock lists and forms on `bg`, so the system sets margins, row padding and the gaps between groups. The spacing tokens are for what the app lays out itself. Use `space-3` between a control and its caption and around the camera's controls. Use `space-2` inside a footer or between the words of a recovery phrase. Use `space-4` between the parts of a screen that the app stacks itself, such as the grid and the keypad. Home before the first DiceKey is the exception: it uses `space-6`.
- Content is flat, and only the glass layer has depth. A key's kind icon sits on an `accent-soft` tile with `radius-sm` corners in a row and `radius-md` corners in a key's header. The camera frame has `radius-md` corners. Buttons are capsules.
- A component keeps its own proportions. For example, the corners, glyph and bar of a die scale with its size, and the keys of the keypad have their own gap.
- Content stops at `content-width` and is centered in a wider column. The typing screen, a DiceKey's screen, a key and New key stay phone-width on an iPad. The app insets the content of a list or form and doesn't cap the scroll view, so the margins beside the content scroll, and the scroll indicator and the top edge effect reach the edges of the column. The camera is square and the height of the column also sizes it, so it needs no cap. A compact window centers the camera and the typing screen. A regular-width window puts them under their title, so a tall column doesn't leave a gap between the title and them. A compact-height window, such as a phone in landscape, puts the camera's count and hint beside the camera. It puts the typing grid beside the keypad, and the keypad takes the rest of the width. Where a compact-height window shows home beside the detail, as on a large phone, the app hides home while the camera or typing screen is open.
- Touch targets are at least 44px. A die is 44px square in the grid, except while you type in a window that is too short for the grid and the keypad. There the grid shrinks, and the keys stay full size. Beside the keypad, the grid fits the height. The keys shrink to the height that is left, which keeps them at least 44px on every phone.

## The DiceKey on screen

The app draws a DiceKey only as a 5×5 grid of dice in reading order, never as an illustration of the box in perspective. Each die shows its letter and digit in `die` type, rotated to the orientation of the die. A short bar under the glyph, like the line printed on the real die, makes upright, right, down and left clear at a glance. The letters are A–Z without Q, and the digits are 1–6. The dice sit in a `die-box` ground, as in the real box, with a `die-dot` where four dice meet. The grid starts concealed, with every die a blank `die-face`, until you tap Show dice. While you type, the app marks the selected die with an `accent` outline.

## Motion

Motion is limited to state changes and to the system's own motion. Lists animate rows in and out, and nothing else fades. A die turns `accent` when the camera reads it, and it stays that color. The die of an unlocked DiceKey on home has a ring in `accent-ink`. The DiceKey in use is the last one that you opened or unlocked, and it keeps a full ring while the app is open. After you open or unlock another DiceKey, or leave the app, its ring drains over the minute before it locks. Respect reduced motion. When reduced motion is on, the ring moves in steps, once a second.

## Iconography

Use SF Symbols on Apple platforms, at the text's weight, colored `ink` or `ink-muted`. Use `accent-ink` for a plain-button icon and `danger` for a destructive one. On other desktops, use the closest outline equivalent at a 1.5px stroke. The kinds are: SSH `terminal`, WireGuard `network`, age `lock.doc`, Passphrase `key`, Wallet `list.number`. The actions are `camera.viewfinder`, `keyboard`, `eye`, `doc.on.doc`, `square.and.arrow.up`, `printer`, `exclamationmark.lock` (the recovery sheet), `trash`. The app icon takes the place of a logo. Where the app shows the icon, as on the cover that the app switcher shows, `AppMark` draws its grid from the tokens, without the ground: `accent` dice with `on-accent` bars. Wherever a wordmark would go, set the name in `title` type, as the app switcher's cover does. Home before the first DiceKey sets it in `wordmark` type.

## Tokens

In code, a token keeps its name in lower camel case. The color sets in `DiceKeyVault/Resources/Colors.xcassets` are named as in the table below, so `on-accent` is `Color.onAccent`. Spacing and radii are `CGFloat` constants, such as `.space3` and `.radiusMd`, in `DiceKeyVault/Shared/LayoutTokens.swift`. If you change a token there, everything drawn with it changes too. A token marked "system" is iOS's own and has no color set.

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#eff3f4` | `#081012` | Ground behind lists and forms, under the corner dice. |
| `bg-raised` | system | system | List rows and sheets: the grouped background that stock components draw, at the elevated level (`#2c2c2e` in dark, 1.38:1 on `bg`). |
| `ink` | system | system | Primary text and icons: `.primary`. |
| `ink-muted` | system | system | Secondary text, captions and placeholders: `.secondary`. |
| `line` | system | system | Row separators, which stock lists draw. |
| `accent` | `#14596b` | `#1b7a8e` | The one hue. Fill only: the primary action, a just-read die, the selected die, the dice of the app mark. Text on it is always `on-accent`. It is lighter in dark, so it stays visible on black. It is still dark enough for white text: toolbar buttons that use it draw their glyph white, whatever the app asks. |
| `on-accent` | `#ffffff` | `#ffffff` | Text and icons on `accent` (4.9:1 or better). |
| `accent-ink` | `#135466` | `#86d0e0` | The app's tint: accent as text and marks, such as links, plain buttons, a kind's icon and the lock countdown. 7.5:1 or better on `bg` and `bg-raised` in both themes. |
| `accent-soft` | `#d5e8ec` | `#133540` | Ground of a key's kind icon, under `accent-ink`. |
| `danger` | `#b81d16` | `#ff7b6b` | Destructive actions and the recovery sheet's warning band. Always with a word or an icon. 5.5:1 or better on `bg` and `bg-raised` in both themes. |
| `die-face` | `#fbfbf7` | `#3a3a3c` | A die's face, a concealed die, and the recovery sheet's concealed code. |
| `on-die` | `#121411` | `#e4e4e4` | A die's glyph and bar. |
| `die-edge` | clear | `#636366` | The rim of a dark die outside the box, and the outline of the dark box: 3.2:1 on `bg`, 2.3:1 on `bg-raised`. |
| `die-shadow` | `rgba(0, 0, 0, 0.25)` | `rgba(0, 0, 0, 0.25)` | A die's faint shadow. |
| `die-box` | `#142b33` | `#0f181b` | The ground that the 25 dice sit in. It is darker than the dice in both themes: 14.2:1 against them in light, and 1.6:1 in dark, where its `die-edge` outline sets it off from `bg-raised`. |
| `die-dot` | `#889395` | `#25292c` | The dot where four dice meet, halfway from `die-box` to `die-face`. |
| `camera` | `#000000` | `#000000` | Behind the live camera image, in every theme. |
| `camera-dim` | `rgba(0, 0, 0, 0.75)` | `rgba(0, 0, 0, 0.75)` | Darkens the camera image outside the window in its middle, while the camera reads no die. |
| `strength-weak` | system red | system red | A passphrase's strength bar, weakest to strongest. |
| `strength-fair` | system orange | system orange | |
| `strength-good` | system yellow | system yellow | |
| `strength-strong` | system green | system green | |

| Style | iOS text style | Use |
|---|---|---|
| `display` | `.largeTitle` (navigation title) | One per screen: the screen's title. |
| `title` | `.title2`, semibold | A DiceKey's name on its recovery sheet, and the app's name on the app switcher's cover. |
| `wordmark` | `.largeTitle`, bold | The app's name on home before the first DiceKey. |
| `headline` | `.headline` | A key's name in a row; the read count under the camera; button labels. |
| `body` | `.body` | Running text and field values. |
| `subhead` | `.subheadline` | The line under a name. |
| `caption` | `.footnote` | Status and helper lines, in `ink-muted`. |
| `label` | list section header | Section labels above groups, in capitals, `ink-muted`. |
| `die` | `dice`, sized to the die | A die's letter and digit, wherever the app draws a DiceKey: grid cells, the scan overlay and the keypad. Nothing else uses it. |
| `secret` | `.body`, monospaced | A revealed recovery phrase's words. A passphrase is `.title3` monospaced. An SSH, age or WireGuard secret is `.footnote` monospaced, as `key` is, but isn't selectable. Wraps anywhere. Never truncated. |
| `key` | `.footnote`, monospaced | Public keys and fingerprints. Selectable, wraps anywhere. |

Families: `sans` is the system font. `mono` is the system monospaced font. `dice` is Inconsolata Bold (`Packages/ReadDiceKey/Sources/DiceKeySpecification/Resources/Inconsolata-Bold.otf`, registered by `PrintedFont.name`).

| Spacing | Value | Use |
|---|---|---|
| `space-1` | 4px | Around the camera frame. |
| `space-2` | 8px | Inside a footer; between a recovery phrase's words. |
| `space-3` | 12px | Between a control and its caption; around and between the camera's controls. |
| `space-4` | 16px | Between the parts of a screen the app stacks itself. |
| `space-6` | 24px | Between examples in previews. Between the parts of home before the first DiceKey. |

| Width | Value | Use |
|---|---|---|
| `content-width` | 480px | The maximum width of the typing screen, a DiceKey's screen, a key and New key. The app centers them in a wider column. It is wider than any phone's window in portrait (the folded Duo's window is 466px), so a phone reaches it only in landscape. |

| Radius | Value | Use |
|---|---|---|
| `radius-sm` | 9px | A key's kind icon tile in a row. |
| `radius-md` | 16px | The camera frame, and a key's kind icon tile in its header. |

Sheets, rows and buttons take their corners from the system. Buttons are capsules.

## In the app

This section is the interface contract. `security.md` covers what the app stores and protects, and why.

- **Home** never says "New DiceKey"; the DiceKey's screen says it. Scan DiceKey is in the toolbar, because scanning is rare once you keep DiceKeys. Unlock on a kept DiceKey's row opens the DiceKey's screen, because you unlock a DiceKey to use its keys. Before the first DiceKey, Scan your DiceKey is the primary action of home. The detail column then shows it as a plain button, because home beside it has the primary action.
- **The DiceKey grid** (`DiceKeyGrid`, `DieView`) is the only way the app draws a DiceKey. The center die alone (`DiceAvatar`) identifies a DiceKey in lists, whatever its name.
- **A DiceKey's screen** has the DiceKey's name as its title. The subtitle gives the count of keys and says whether the DiceKey is unlocked. The Mac app doesn't show the subtitle, so it doesn't say "New DiceKey". The selected row of home beside the screen gives the same count and state. The screen lists the two defaults first, SSH then age, each tagged "Default". The named keys follow, sorted by name. Counts include the defaults. "New DiceKey" shows only when you scan or type a DiceKey that the app records for the first time ("New DiceKey · 2 keys · unlocked"). The plain count shows after a later correct scan, after you reopen the DiceKey, and after you restore it from a recovery sheet, which the app doesn't read from the dice. A new DiceKey is also normal on the first run, so the notice is plain, not an error.
- **Keeping a DiceKey on this device**: the app offers it whenever you scan or type a DiceKey that isn't kept. The offer is an alert as the screen of the DiceKey opens, with the choice Keep on this device or Not now. The DiceKey's menu lets you change the choice later.
- **The camera** opens over the detail column where home is beside it, and Back returns to what the column showed.
- **Typing a DiceKey**: you enter each die in three steps. These are its letter, its number, then which way is up. Nothing defaults to upright. You can't type a letter that is already on another die. The keypad is always whole, and the grid shrinks to the height that is left. After you leave the app, a half-typed DiceKey stays for as long as an unlocked DiceKey stays unlocked.
- **Key rows** show the name and the kind, or a default's kind and "Default", never a status or any part of a secret. Kinds aren't color-coded. Spell them as their tools do ("age", "WireGuard").
- **New key** is a live draft in the detail column, never a sheet. The public keys update as you type. The preview comes straight after the name, before options such as the style of a passphrase. Save is the one primary action. For a key that already exists, Save is disabled, and the group of the name says so and offers to open the key.
- **A key** shows its public half in full, always, and its secret only after Reveal, never as dots or a length hint. Each value has the same two actions, Copy and Share. When you copy a secret, the app says when it clears. SSH and age identities share as the file that their tool reads. An age file has the format that `age-keygen` writes, with its `# created:` and `# public key:` lines. The public half of a key has one section for each algorithm of its kind that has a public half. A kind with several algorithms titles each section by its algorithm, and each section has a footnote that says when to use it. An age key has an "X25519" section and an "ML-KEM-768 + X25519 (post-quantum)" section. The post-quantum recipient is folded, as under Type. The X25519 footnote says that it works with every age and mixes with SSH recipients. The post-quantum footnote says that it needs age 1.3 for everyone, and that you can't mix it with X25519 or SSH recipients in one file. The catalog doesn't hold the public keys of a default, imported or restored key until its DiceKey is next unlocked. It also doesn't hold a public key for an algorithm that the app added after it recorded the key. Until then, its section says "Shows once the DiceKey is unlocked." For a kept DiceKey, the first such section has Unlock under it. A wallet's recovery phrase is the one exception: you write it down, and it never has Copy or Share. You delete a key by swiping its row or from its screen, and a confirmation first says how to make it again. A default key can't be deleted. Its row doesn't swipe, and its screen has no Delete key.
- **Paper** comes in two pieces, and each has a preview in a sheet that shows the page exactly as it prints. The list card is sized for the box and carries a QR code that restores the keys. The recovery sheet is the DiceKey on paper, so the app gates it and conceals it until Show (`security.md`). The camera reads both codes and asks before it loads either. The codes carry the default keys, but the printed lists leave them out, so the printed lists show only the keys that the person made. While the DiceKey has a key that a newer version made, neither piece opens. An alert says to update the app, because the page would leave that key out. The app lays out printed pages in points on the page, not with the screen's spacing tokens, and prints them in the light appearance.
- **Buttons**: one glass-prominent primary action per screen. Forget is destructive, and the app always asks for confirmation.

## Settings

Settings is a sheet that opens from the gear in the toolbar of home. It is a stock form with Done in the toolbar, shown as an ✕ because every change applies at once. The Sync with iCloud footer says what syncs: never the dice or a secret. Export catalog is dimmed, with a footer that says to update the app, while the catalog holds a key that a newer version made. Import catalog reads a file back in (`catalog-format.md`).
