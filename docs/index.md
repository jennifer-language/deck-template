<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# @myscope/mydeck

One paragraph: what the deck is for and what it replaces doing by hand.

Add one guide per subject and list it in `docs/SUMMARY.md`; the build fails
when the outline names a chapter with no file.

## Conventions

Snippets assume this import:

```jennifer
import "@myscope/mydeck/" as mydeck;

io.printf("%s\n", mydeck.greet("Ada"));
```

The trailing slash resolves to the entry module. Always use the deck's name as
the alias: `tools/check-docs.sh` then checks every `mydeck.<name>(...)` in the
docs against the code, function name and argument count.

Errors: list the `Error` kinds the deck throws and when. Each should carry a
`kind` of its own and a message a reader can act on. Catch them with
`try { ... } catch (e) { io.printf("%s\n", $e.message); }`.
