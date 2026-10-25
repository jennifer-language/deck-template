# @myscope/mydeck

[![test](https://github.com/jennifer-language/deck-template/actions/workflows/test.yml/badge.svg)](https://github.com/jennifer-language/deck-template/actions/workflows/test.yml)
[![Documentation](https://img.shields.io/badge/docs-github%20pages-blue)](https://jennifer-language.github.io/deck-template/)
[![release](https://img.shields.io/github/v/release/jennifer-language/deck-template)](https://github.com/jennifer-language/deck-template/releases/latest)

One short paragraph: what this deck does for a
[Jennifer](https://jennifer-lang.dev/) program.

**[Documentation](https://jennifer-language.github.io/deck-template/)**

## Install

```sh
jvc add @myscope/mydeck
```

This vendors the deck to `vendor/<scope>/mydeck/`. Without `jvc`, unpack the
`src/` subtree of a release archive (`<scope>-mydeck-<version>.tar.gz`) there.

## Usage

```jennifer
import "@myscope/mydeck/" as mydeck;

io.printf("%s\n", mydeck.greet("Ada"));
```

## Requirements

Jennifer 0.25.0 or newer. List what the deck needs at run time (network, a
binary on PATH, a database) and whether it runs on `jennifer-tiny`.

## Development

```sh
tools/check-all.sh                   # the full gate, as CI runs it
jennifer test src/mydeck_test.j      # the test overlay
tools/check-docs.sh                  # docs against the code
tools/pack.sh dist                   # build the release archive
```

## Licence

LGPL-3.0-only, see [LICENSE](LICENSE). Copyright (C) 2026 mplx &lt;mplx@jennifer-lang.dev&gt;.

`tools/check-headers.sh` checks every source file's SPDX header against
`deck.toml`.
