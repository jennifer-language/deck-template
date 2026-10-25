<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# mydeck cheatsheet

Every export of `@myscope/mydeck`. Guides are listed in
[the introduction](index.md).

```jennifer
import "@myscope/mydeck/" as mydeck;
```

`tools/check-docs.sh` checks this page against the code on every push. It
reads three forms:

- **Functions**: the first cell of a table row, with the real parameter names
  in order: `` `greet(name)` ``. A modules deck (this one) may qualify names
  and add types: `` `mydeck.greet(name as string)` ``. A topics deck writes
  names bare.
- **Constants**: rows of a table with a `Value` column holding the declared
  value.
- **Structs and enums**: a `### `Name`` heading over a table of fields
  (`` `name as type` ``) or variants.

Known gaps go in `docs/.cheatsheet-todo`, one name per line; they are reported
as a backlog instead of failing the build (`tools/check-docs.sh --todo`).
Remove lines from that file; never add them.

## Greeting

| Function | Returns | Does |
|---|---|---|
| `greet(name)` | `string` | `"hello, <name>"` with `name` trimmed; `"hello, world"` when it is blank |
