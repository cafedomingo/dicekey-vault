## Writing

Docs (`docs/`, `README.md`) and code comments follow three rules from ASD-STE100:

- One term per concept. Keep the term the text already uses, and never introduce a synonym for it.
- Name the actor in every sentence: "the app clears it", not "cleared". A doc comment's opening
  summary fragment is the exception.
- Keep words that carry a claim exact, such as never, always, only, must, may, every, until, at
  least. Rewording never weakens a security or format claim.

## Documentation

Docs also follow the [Google developer documentation style guide](https://developers.google.com/style),
except for two habits of their own: no serial comma, and no contractions. App strings follow the
Content rules in `docs/design.md` instead.

## Code comments

- Comment only what the code cannot say: a quirk, an ordering constraint, or a reason that is not
  obvious. Never restate the code or repeat a name or signature. Most declarations need no comment.
- In Swift, put a comment in the declaration's doc comment (`///`), not as a `//` line inside a
  body. Tool directives such as `// swiftlint:disable:next` are not comments.
- Start a doc comment with a summary fragment, as the
  [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) ask.
