# Using this template

`deck-template` is a minimal working deck: one exported function, one test,
one example, one guide, green CI. Copy it, initialise it, then replace the
example code.

```sh
cp -r deck-template ../weather && cd ../weather
tools/init-deck.sh deckyard weather "A typed client for the Weather API"
rm TEMPLATE.md tools/init-deck.sh tools/sync-deck.sh
jennifer test src/weather_test.j
tools/check-all.sh
```

`init-deck.sh` renames the module and rewrites the deck name and the
repository and Pages URLs in every file. The URLs point at the GitHub
organisation named like the scope (`jennifer` is `jennifer-language`), or at
the one `--org` names. It also writes `tools/shared.lock`.

`tools/check-identity.sh` fails CI while any `mydeck`, `myscope` or
`deck-template` remains, including in the three template-only files, so they
must be deleted. `@myscope/mydeck` is a deliberate placeholder: choose the
scope of whoever maintains the deck.

## Keeping decks in step

The files listed as `shared` or `optional` in `tools/shared-files` (the
workflows, most of `tools/`, `AGENTS.md`) are the shared CI layer. Change them
here and sync them to the decks; never edit them in a deck. `AGENTS.md` is
optional: a deck that does not want it deletes it, and the sync leaves it out
from then on. While a deck has it, `CLAUDE.md` must keep its `@AGENTS.md`
line; `tools/check-shared.sh` fails otherwise.

```sh
tools/sync-deck.sh --dry-run ../deck-weather ../deck-other   # show changes
tools/sync-deck.sh ../deck-weather ../deck-other             # write them
```

The sync copies shared files, seeds deck-owned files a deck lacks, removes
retired files and writes `tools/shared.lock`. It refuses a deck that is not a
clean git repository unless given `--force`. In each deck,
`tools/check-shared.sh` runs first in CI and fails when a shared file differs
from the lock.

## Layout

| Path | What it is |
|---|---|
| `deck.toml` | manifest: identity, licence, capabilities, interpreter floor |
| `src/<slug>.j` | entry module, the one consumers import |
| `src/<slug>_test.j` | its white-box test overlay |
| `docs/SUMMARY.md` | book outline; a chapter with no file fails the build |
| `docs/cheatsheet.md` | full API; `tools/check-docs.sh` checks every signature, value and type against the code |
| `examples/` | one runnable example per subject; CI runs or parses them |
| `tools/` | CI helpers, byte-identical across decks except the deck's own `check-examples.sh` and optional `check-extra.sh` |
| `grimoire.toml` | book configuration; `site/` is the gitignored output |
| `AGENTS.md` | coding-agent instructions, shared between decks |
| `CLAUDE.md` | imports `AGENTS.md`, then this deck's own notes |
| `JENNIFER.md` | language reference for coding assistants; vanilla, replace when it changes upstream |

## Shapes

`tools/deck-lib.sh` detects the shape and every helper follows it:

- **modules** (this template): one file per subject in `src/`, each its own
  namespace. The cheatsheet qualifies names: `weather.forecast(`.
- **topics**: a single `src/<slug>.j` that `include`s the files in
  `src/topics/`. `include` is a textual splice, so the entry file is the only
  namespace and holds every export; a topic cannot be imported alone. The
  cheatsheet writes names bare: `forecast(`. `@deckyard/routeros` is built
  this way. Use it when one namespace with many subjects reads better than many
  small modules.

To switch, create `src/topics/`, move the subject files into it, and have the
entry module `use` the shared modules and `include` each topic.

## Before the first release

- `deck.toml`: `description`, `keywords`, `capabilities` (empty means pure
  computation; add `net`, `exec` or `sql` only with a comment giving the
  reason).
- The repository URLs from `init-deck.sh`, if the repository is not
  `deck-<slug>` in that organisation.
- `CLAUDE.md`: fill in the sections or delete the empty ones. Keep the
  `@AGENTS.md` import line at the top.
- In GitHub, **Settings -> Pages -> Source -> GitHub Actions**, once, or
  `docs.yml` publishes nothing; and under **Settings -> Environments ->
  github-pages**, a deployment tag rule `[0-9]*.[0-9]*.[0-9]*`, or the deploy
  after a release tag is refused. `docs.yml` calls Grimoire's shared Pages
  workflow, which publishes the book of the highest release tag (main before
  the first one); see <https://grimoire.jennifer-lang.dev/github-pages.html>.
- The release workflow runs on a version tag and rejects a tag that differs
  from `deck.toml`: bump the manifest, then tag.
