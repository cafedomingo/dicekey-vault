# Derivation

A key is a pure function of a DiceKey, a kind and a name, and, for a passphrase, its style.
The default keys have no name. The same inputs give the same key on any device, forever.
The app never stores a derived secret. The catalog keeps only the DiceKey's one-way id and
public keys, and the app derives everything else again when it needs it. This document is the
specification. It is exact enough for you to reimplement on another platform.
`scripts/derive-kinds.py` is such a reimplementation, and
`Packages/Derivation/Tests/DerivationTests/Fixtures/kinds.json` is its conformance suite.

## The seed

A DiceKey is 25 dice in a 5×5 box. Each face is three ASCII characters. The first is a letter
(`A`–`Z` without `Q`). The second is a digit (`1`–`6`). The third shows which way the top of
the letter points: `t`, `r`, `b` or `l`, for up, right, down or left. An example is `A1t`.
The 25 faces in reading order make a 75-character text. Reading order is row by row, left to
right. The position of a face is 5 × row + column.

A person can hold the box four ways, and all four must give the same keys. A clockwise
quarter turn moves the die at row r, column c to row c, column 4 − r (so
new[r][c] = old[4 − c][r]). It also turns the top of each die: `t` → `r` → `b` → `l` → `t`.
The seed is the smallest of the four texts, compared byte by byte (`DiceKey.seed`). This is
the original DiceKeys rule. kinds.json's `seeds` pins it with DiceKeys. The original C++
derived their seeds, and the fixture records them.

## The construction

The construction is HKDF (RFC 5869) with SHA-256 and no salt, from CryptoKit
(`Engine.bytes`):

```
info = type || recipe                    UTF-8, no separator
PRK  = HMAC-SHA256(key = 32 zero bytes, message = seed)
T(i) = HMAC-SHA256(key = PRK, message = T(i-1) || info || i)     i = 1, 2, …; T(0) is empty
out  = the first L bytes of T(1) || T(2) || …
```

In RFC 5869, no salt is the same as 32 zero bytes. The counter is one byte. The longest
output is 512 bytes, for a 64-character passphrase. That is far below the 255 blocks that the
counter allows. Any standard HKDF-SHA256 gives these bytes (Android's, WebCrypto's, Python's
`hmac`). kinds.json's `hkdf` pins the construction alone.

## Recipes

A recipe says what to derive. It is JSON, and the derivation hashes its text:

```
{"kind":"ssh","name":"github"}
{"kind":"passphrase","length":24,"list":"letters-digits","name":"nas"}
{"kind":"passphrase","length":6,"list":"eff_large_wordlist","name":"nas","separator":"digits","uppercase":true}
```

The fields are `kind` (`ssh`, `wireguard`, `age`, `passphrase` or `wallet`) and `name`. A
passphrase also has `length` and `list`. A memorable passphrase also has `separator` and
`uppercase` (see Passphrases). A recipe has nothing else. Only the default keys have no
`name` (see Default keys). The types are not in the JSON. The kind decides them.

**One spelling.** A recipe is written as RFC 8785 (JCS) canonical JSON, with these rules:

- Keys are sorted by UTF-16 code unit.
- There is no whitespace.
- Integers are in plain decimal.
- Non-ASCII is written as raw UTF-8 (never `\uXXXX`).
- Strings are escaped minimally. For a valid name, this means only `"` and `\`.

Text is a recipe only if it is, byte for byte, the canonical text of a valid recipe
(`KeyRecipe(json:)`). The check decodes the text, writes it back, and compares the bytes.
That check refuses all of these:

- reordered keys
- whitespace
- escapes that are not necessary
- duplicate, missing or unknown fields
- `24.0` for `24`
- a name that is not already trimmed and normalized

**Names** follow these rules. The app trims a name at both ends of Unicode `White_Space`
(U+0009–000D, 0020, 0085, 00A0, 1680, 2000–200A, 2028, 2029, 202F, 205F, 3000). It
normalizes the name to NFC. A name is 1 to 64 scalars long. A name may not hold any of these:

- a control character (`Cc`)
- a format character (`Cf`) other than the zero-width joiner, which most emoji sequences need
- a code point that Unicode has not assigned (`Cn`)

So these rules refuse an emoji built from tag characters, such as a subdivision flag.
Invisible characters would let two names that print the same derive different keys. An
unassigned code point could normalize differently once Unicode assigns it. NFC is stable for
assigned characters. Otherwise a name is exactly as typed. `'` is not `’`. A different capital
or a different inner space gives a different key.

The unassigned check follows the Unicode tables of each platform. So a device refuses a name
that uses a code point newer than the tables of that device (in practice, a new emoji). That
only ever refuses a name. It never derives a different key.

## Kinds

`KeyRecipe` builds the recipe, and `DerivedKey` derives and encodes the key. A kind derives
an ordered list of algorithms from its one recipe, one key each (`KeyKind.algorithms`). An
algorithm is a type. The derivation hashes the type in front of the recipe. The type names
what the bytes become.

| Kind | Algorithms |
|---|---|
| ssh | `ed25519` |
| wireguard | `x25519` |
| age | `x25519`, `mlkem768x25519` |
| passphrase | `passphrase` |
| wallet | `bip39` |

| Type | L | Key |
|---|---|---|
| `ed25519` | 32 | The bytes are the Ed25519 seed. |
| `x25519` | 32 | The bytes are the X25519 scalar, unclamped. |
| `mlkem768x25519` | 32 | The bytes are the X-Wing seed that an age 1.3 identity holds. SHAKE256 of the X-Wing seed gives 96 bytes: ML-KEM-768's seed (d ‖ z), then the X25519 secret. |
| `passphrase` | 8 per entry | See Passphrases. |
| `bip39` | 32 | The bytes are the BIP39 entropy. |

WireGuard and age share the type `x25519` and differ by `kind` in the recipe. An age key
derives both of its identities from its one recipe. Their types keep them independent. The
curve library clamps the X25519 scalar when it uses the scalar (CryptoKit, libsodium and
Python's `cryptography` all clamp internally). So every tool agrees on the public key. A port
must use a library that does the same.

The rules for algorithms:

- A kind's algorithm set only grows. A released algorithm is never removed or retyped.
- The types within a kind are distinct, because the same type would derive the same bytes.
- The order is emphasis only, and it may change, since nothing stored depends on it.

**Encodings.** These turn key bytes into the text that each tool reads. They are standard
formats, and kinds.json pins them. They are not key material. A change to an encoding would
leave the key the same and change the exported text.

- **ssh**:
  - The public key line is `ssh-ed25519 <base64 of the public key blob> <name>`. For a
    default, it has no name and no trailing space (see Default keys).
  - The fingerprint is `SHA256:` and the unpadded base64 of SHA-256 of that blob.
  - The private key is an unencrypted OpenSSH `openssh-key-v1` file (PROTOCOL.key). Its
    cipher and KDF are `none`, its KDF options are empty, and it holds one key.
  - The private section holds the check value twice, the key type, the public key,
    seed ‖ public key, and the name as the comment. The check value is the first 4 bytes of
    SHA-256 of the raw 32-byte public key.
  - The private section is padded with bytes 1, 2, 3, … to a multiple of 8.
  - The PEM is wrapped at 64 columns and ends with a newline.
- **wireguard**: The private scalar and the public key are in standard base64.
- **age**:
  - `AGE-SECRET-KEY-1…` is Bech32 (BIP 173) with HRP `age-secret-key-`. You compute it over
    the lower-case string and then upper-case it.
  - The recipient is `age1…`, with HRP `age`.
  - The post-quantum identity is `AGE-SECRET-KEY-PQ-1…`, with HRP `age-secret-key-pq-`, over
    the 32-byte seed. You upper-case it the same way.
  - Its recipient is `age1pq1…`, with HRP `age1pq`, over the 1,184-byte ML-KEM-768
    encapsulation key followed by the 32-byte X25519 public key. The recipient is 1,959
    characters long.
  - Bech32 here has no length limit.
- **wallet**: The key is the 24-word BIP39 English phrase, with no BIP39 passphrase.

## Passphrases

A passphrase's style is part of its recipe. So it is part of the key.

| Style | Fields | List |
|---|---|---|
| Random | `length` 12–64 characters, default 24 | `letters-digits` (57): `ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789`; `letters-digits-symbols` (67): the same followed by `!@#$%&*-_?` |
| Memorable | `length` 4–10 words, default 6; `separator`; `uppercase` | `eff_large_wordlist` (7,776): EFF's large wordlist, its words in file order without the dice numbers |

- `length` is how many entries: characters or words.
- `list` names the list that the entries come from, and so the style.
- `separator` is for memorable only, and the recipe text always includes it. `-` joins the
  words with hyphens. `digits` joins them with digits.
- `uppercase` is for memorable only. `true` writes one whole word in capitals. It goes with
  `"separator":"digits"` and only with it. So a memorable recipe has two forms: `-` without
  `uppercase`, and `digits` with `"uppercase":true`. Anything else is not a recipe, and that
  includes `false`.

The type is `passphrase`, and L is 8 bytes per character or word. Each entry is one 8-byte
big-endian block of the output modulo the list size. The quotient of that division is
independent of that choice. The derivation concatenates random characters. It writes
memorable words in lower case, as the list has them. With `-`, hyphens join the words. With
`digits`, for n words indexed from 0:

- The word at index (block n − 1's quotient modulo n) has every letter upper-cased, not just
  its first. The words in the list are ASCII letters and hyphens, so this maps `a`–`z` to
  `A`–`Z` alone.
- One digit goes between word i and word i + 1. The digit is block i's quotient modulo 10.
  So there is no trailing digit.

Take three words whose blocks pick `abacus`, `abdomen` and `abdominal`, with quotients 17, 3
and 4. They give `abacus7ABDOMEN3abdominal` (4 modulo 3 is 1). A list's content and order
are part of the format. The SHA-256 of a list's entries joined by `\n` pins the list
(`PassphraseListTests`).

The strength is exact, because every entry is uniform. A passphrase of 24 random characters
has about 140 bits, and one of 6 words has about 77. The digits and the uppercase word add a
little more.

## Default keys

Every DiceKey has an SSH key and an age key that need no name. Each recipe holds `kind`
alone. The code holds it as a literal, and this literal is the text that the derivation
hashes. So no change to the code that writes recipes can change a default key:

| Kind | Recipe text |
|---|---|
| ssh | `{"kind":"ssh"}` |
| age | `{"kind":"age"}` |

A default derives like any key, from `type || recipe`. The parser (`KeyRecipe(json:)`)
accepts a recipe without a name only if its text is, byte for byte, one of these two. It
refuses `{"kind":"passphrase"}`, `{"kind":"ssh","length":24}` and `{ "kind":"ssh" }`. No
literal equals a named recipe's text, since those hold `"name"`. Each literal starts with
`{`, so `type || recipe` still reads only one way.

Never edit or remove a literal once an App Store release has it. This is because a default
has no name to make its key again and synced catalogs hold its rows. You change the set only
by adding a literal. An added literal reaches every DiceKey: the app adds each default that a
DiceKey lacks. If the app ever stops adding a default to new DiceKeys, the parser still
accepts its literal. So files and paper that carry it can still make the key. The app leaves
out a catalog row whose recipe has no name and is not one of these. It does the same for any
recipe that this version cannot read. The DiceKey's other keys load as usual.

A key with no name changes the encodings that use a name. The SSH public key line is
`ssh-ed25519 <base64>`, with no comment and no trailing space. The private key's comment is
empty. Exported files take the tool's name alone: `id_ed25519`, `age.txt` and `age-pq.txt`.

## The DiceKey id

The DiceKey id is 16 bytes with type `dicekey-id` and an empty recipe, so `info` is just
`dicekey-id`. The app writes it as unpadded URL-safe base64 (`DiceKeyID`). It names a
DiceKey in the catalog and on paper without revealing anything about the dice.

## Why keys are stable

A key depends on three byte strings and nothing else: the seed, the type, and the recipe
text. The derivation uses no randomness, clock, device, app version or stored salt. So these
must never change:

- The seed's text and the rotation rule.
- The construction (HKDF-SHA256 with no salt, as above).
- The type strings, and the types that each kind derives. That set may only grow.
- Each kind's fields: their names, their values, the list names, and when an optional field
  is written (`uppercase` only with digits, and only as `true`).
- The default recipe texts, which are literals.
- The lists' contents and order.
- The name rules, except that you may loosen them. A name accepted today must stay
  acceptable.
- The JCS rules, which are a published standard.

Every (kind, name, style) has exactly one recipe text, because names are normalized and the
JSON is canonical. The parser accepts nothing else. A default has exactly one too: its
literal. The format grows by adding. A new kind, a new type, a new algorithm for a kind, a
new list or a new default leaves every existing string alone. A new field must never be
added to an existing kind with a default that changes its text. To replace a key, give it a
new name (`github 2`). So a default key cannot be replaced. There is no other version
counter.

If a test below fails, a derived byte changed. Fix the code. Never change the fixture.

## Why it is safe

- **The seed is the secret, and it is strong.** 25! orderings × 6^25 digits × 4^25 turns is
  about 2^198 arrangements. The four turns of a box are one key, so there are about 2^196
  seeds. Nobody can search that many seeds. This is why the construction is a fast hash and
  not a slow password-hashing function. A slow function would be needed for a secret that a
  person chooses.
- **The construction is a standard KDF.** It is HKDF-SHA256 from the platform's own
  cryptography, with nothing hand-written. Extracting without a salt is fine, because the
  seed already has full entropy.
- **Every key is independent.** `info` differs for every (type, recipe), so the outputs are
  unrelated. A leaked SSH key reveals nothing about the same name's WireGuard key, about
  another name's key, or about the DiceKey. No type string is a prefix of another, and every
  recipe starts with `{`. So `type || recipe` reads only one way, and the id's `info` cannot
  equal the `info` of any key.
- **Nothing can be reversed.** No output reveals the seed. You can store and share the id
  and the public keys.
- **Choices are uniform.** An 8-byte block modulo a list of n entries is biased by at most
  n / 2^64. For the largest list, that is under 2^-51.

`security.md` covers what the app stores, where it stores it, and the limits.

## What the tests pin

- **kinds.json**: `scripts/derive-kinds.py` writes it. The script shares nothing with the
  Swift code but the word lists. The file has these sections:
  - `seeds`: the text as typed and its canonical seed (the script checks it against the
    seeds that the original DiceKeys C++ derived).
  - `hkdf`: seed, type, recipe text, length and the raw output in hex.
  - `diceKeyIds`: seed and id.
  - `cases`: derivations across every kind and style. Each case has `seed`, `kind`, `input`
    (the name as typed, to exercise normalization), `name`, `style`, `recipe` and
    `algorithms`.
    - `algorithms` has one entry per algorithm of the kind, in order. Each entry has its
      `type` and the `publicKey`, `fingerprint` and `secret` that its tool reads.
    - A passphrase or a wallet has no `publicKey` or `fingerprint`. Age's post-quantum key
      has no `fingerprint`.
  - `defaults`: each default for each seed, with `seed`, `kind`, `recipe` (its literal) and
    `algorithms` as above.

  `KindVectorTests` and `DiceKeySeedTests` check the app against it. They check each kind's
  algorithms in order, and that every recipe parses back to itself. CI runs the script with
  `--tools`, so that these checks run too:
  - `ssh-keygen`, `wg` and `age-keygen` 1.3 read every key back.
  - `age` encrypts to every age recipient, and the identity decrypts it.
  - The BIP39 reference decodes every phrase.
- `KeyRecipeTests` check the name rules, JCS escaping and ordering, text that is not a
  canonical recipe, and the default literals byte for byte. They also check that the parser
  refuses any other text that has no name.
- `PassphraseListTests` and `PasswordFormatterTests` check the lists' digests and literal
  character sets. They also check blocks, quotients, digits and the uppercase word.
- `OpenSSHFileTests`: `ssh-keygen` reads the private key file.
- `age-pq-spec.txt` holds the post-quantum example pair from the age specification.
- The script checks HKDF-SHA256 against RFC 5869's test cases 1 and 3. The Swift tests check
  it against case 3, the no-salt form. The tests also check BIP39 against its reference
  vectors.
