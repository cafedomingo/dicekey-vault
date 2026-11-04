# The catalog's formats

Paper outlives app versions. A list card or recovery sheet printed today must import in every later version of the app, and so must exported files. There are three forms:

- **The file:** readable JSON, `{"v":1,"diceKeys":[…],"keys":[…]}`, from Settings ▸ Export. It is version 1. It has no size bound beyond the 1,000-item cap (see Reading it), and its purpose is to be readable.
- **The link:** `dicekeyvault://import?catalog=<payload>`, on the list card's QR code. It is version 2.
- **The recovery code:** `DKVR:<payload>`, on the recovery sheet. It is version 2. It is never a link, so the faces don't pass through iOS link handling.

The recovery prefix carries no version. So the app still recognizes a later version's code as this app's and asks for an update.

A version writes a file or paper only when it can write every key in it. A synced catalog can hold a key that a newer version made on another device. One example is a key of a kind that this version doesn't know. Another is a key with a field that this version doesn't know. While the catalog holds such a key, Export asks for an update instead of leaving the key out. The list card and the recovery sheet of that key's DiceKey ask for an update in the same way.

## The file (v1)

A DiceKey is `{"id","name","centerFace"}`. A key is its recipe's own fields, exactly as `derivation.md` defines them, plus `"diceKey"` and `"publicKeys"`. Here `"diceKey"` is the id of the DiceKey that the key belongs to. The default keys come first, written like any other key. The named keys follow, in order of name:

```
{"diceKey":"FDWCWOqOuLX6kRVI9K31_A","kind":"ssh","publicKeys":{"ed25519":"ssh-ed25519 AAAA…"}}
{"diceKey":"FDWCWOqOuLX6kRVI9K31_A","kind":"age","publicKeys":{"mlkem768x25519":"age1pq1…","x25519":"age1…"}}
{"diceKey":"FDWCWOqOuLX6kRVI9K31_A","kind":"ssh","name":"github","publicKeys":{"ed25519":"ssh-ed25519 AAAA… github"}}
{"diceKey":"FDWCWOqOuLX6kRVI9K31_A","kind":"passphrase","length":24,"list":"letters-digits","name":"nas"}
```

The values:

- `id` and a key's `diceKey`: the DiceKey's id as `derivation.md` defines it.
- A key's recipe fields: as `derivation.md` defines them. A default key's recipe fields are those of its literal recipe: `kind` alone. The JSON around them doesn't need to be canonical. The app rebuilds the canonical text of the recipe from the fields.
- `publicKeys`: each algorithm's public key, by its type (`derivation.md` lists a kind's types). It is for reading in the file. An app never imports it. A file could carry anyone's key, so a public key only ever comes from deriving it here. A key with no public half, which is a passphrase or a wallet, has none. A key also has none while the catalog doesn't yet record its public keys. An app counts a key whose `publicKeys` isn't a map of text as unreadable.
- `name` of a DiceKey: as `derivation.md` normalizes a name. The app replaces a name that fails those rules with the DiceKey's default name.
- `centerFace`: one face, such as `M1t`, as `derivation.md` writes faces.

## The link and the recovery code (v2)

Both carry one DiceKey and its keys as compact JSON, with sorted keys and no whitespace. The default keys come first:

```
{"centerFace":"M1t","id":"FDWCWOqOuLX6kRVI9K31_A","keys":[{"kind":"ssh"},{"kind":"age"},{"kind":"ssh","name":"github"},{"kind":"passphrase","length":24,"list":"letters-digits","name":"nas"}],"name":"Home box","v":2}
```

- `id`, `name` and `centerFace` are the DiceKey's. Their values are as defined above.
- Each key is exactly its recipe's fields, with no `diceKey` (it belongs to `id`) and no `publicKeys`.
- The recovery code's JSON also has `"diceKey"`, the DiceKey's 75-character text. When an app restores, it checks that those faces derive `id`.

`<payload>` is that JSON, compressed with raw DEFLATE (RFC 1951) and written as base64url, unpadded (RFC 4648 section 5). The decoder reads any key order and any valid DEFLATE stream. Text that doesn't decode, inflate or parse is "not a catalog". JSON that inflates past 256 KiB (`PaperPayload.maximumUnpackedBytes`) is also "not a catalog". The decoder stops there, since DEFLATE can inflate about 1,000 to 1 and a link can come from any source.

These sizes come from measurements with CoreImage. The keys are SSH keys with 12-character names that don't compress, and the code also holds the two default keys.

- The list card's code is a QR code (level M), held to 119 modules wide. That is version 25 plus the generator's one-module margin. It holds 55 named keys. 56 named keys need 123 modules.
- The recovery sheet's code is an Aztec code at 33% error correction, held to 188 modules wide but limited by the generator. The generator makes no code for 104 named keys. 103 named keys take only 155 modules.

Names that compress fit more keys. Longer names fit fewer keys. `PaperTests` pins a minimum of 40 named keys on the card and 80 on the sheet.

## Reading it

An app reads each key on its own. It leaves out and counts any key that it can't make again. Such a key is one of these:

- a key with a field, kind or value that the app doesn't know;
- a key with a name that the rules of the app refuse;
- in the file, a key with a `diceKey` that is neither in `diceKeys` nor already in the app.

So a newer key never stops the app from reading the rest of the paper. When a key has a field that this version doesn't know, the app never reads the key as a different recipe. A recovery code's `id` must be the one that its `diceKey` text derives. The app refuses a file with more than 1,000 DiceKeys and keys together. The total leaves out the first two kinds of unreadable key above, because the app finds them as it reads the file. It includes the third kind, which the app finds only when it imports. The app refuses a link or code when its DiceKey and its keys together come to more than 1,000, and there the total includes every key, readable or not. So the app accepts at most 999 keys in a link or code. The app also refuses a file, link or code whose `v` is newer than the app's, with "update the app".

Default keys (`derivation.md`) are in every form, as the fields of their literal recipes. So a later app can make each again from the file or paper alone. When the app imports or restores a default key that the catalog has, it adds nothing, as for any key. When the app imports or restores a DiceKey that it doesn't have, it records the DiceKey. Recording a DiceKey adds its default keys. The printed lists, and the counts that the app shows before an import or restore, leave out the defaults. They show the keys that the person made.

The rule: only add optional fields, kinds and values, in the file and in v2. Never rename, remove or reinterpret one. Raise `v` only when an older app would otherwise make a mistake. An app refuses a newer `v`. Every later paper version keeps v2's envelope (the prefix or link, raw DEFLATE, base64url, JSON with a top-level `v`). So an older app can say to update.

`Tests/DiceKeyVaultTests/Fixtures` holds the file as v1 (`catalog-v1.json`) and the link and recovery code as v2 (`catalog-link-v2.txt`, `recovery-v2.txt`). Never regenerate them. A failing fixture test means that the change breaks paper or files that exist already. The tests pin what the paper fixtures decode to. They don't pin the encoder's bytes, since DEFLATE output may differ between OS versions.
