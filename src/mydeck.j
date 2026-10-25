# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

/**
 * The entry module, the one consumers import. Replace it with the deck.
 *
 * tools/deck-lib.sh detects one of two shapes:
 *
 *   modules  one file per subject in src/, importing each other as needed
 *            (this template; @deckyard/ngs)
 *   topics   src/<slug>.j `include`s the files in src/topics/; the splice is
 *            textual, so the entry file holds every export
 *            (@deckyard/routeros)
 *
 * @module mydeck
 */
use strings;

/**
 * Greet someone by name. Placeholder export for the template's test, example
 * and docs check; delete it.
 *
 * @param name {string} who to greet; trimmed, blank means "world"
 * @return {string} `"hello, <name>"`
 * @example
 *   mydeck.greet("Ada");   # "hello, Ada"
 */
export func greet(name as string) {
    def who as string init strings.trim($name);
    if ($who == "") {
        $who = "world";
    }
    return "hello, " + $who;
}
