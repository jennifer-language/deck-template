#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
#
# Turn deck-template into a named deck: rename the entry module and rewrite the
# identity everywhere it is written down.
#
# The slug becomes a Jennifer module name, so it is letters and digits only -
# no underscores, no hyphens (the *repository* is deck-<slug>, the module is
# <slug>). The template's placeholder module is `mydeck`, a word that never
# occurs in prose, so every occurrence is identity and is rewritten blindly.
# tools/check-identity.sh fails CI on any that survive.
#
# The template's URLs point at its own GitHub organisation; they are rewritten
# to the new deck's, which is the scope unless --org says otherwise. The one
# exception is `jennifer`, whose organisation is `jennifer-language`.
#
# Delete this script once it has run; a deck has no use for it.
#
# Usage: tools/init-deck.sh [--org <github-org>] <scope> <slug> ["one-line description"]
#    eg: tools/init-deck.sh deckyard weather "A typed client for the Weather API"
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "error: $*" >&2; exit 1; }

usage='usage: tools/init-deck.sh [--org <github-org>] <scope> <slug> ["description"]'
org=""
if [[ "${1-}" == --org ]]; then
    (( $# >= 2 )) || die "$usage"
    org="$2"
    shift 2
fi
(( $# >= 2 )) || die "$usage"
scope="$1"; slug="$2"; description="${3-}"
if [[ -z "$org" ]]; then
    case "$scope" in
        jennifer) org=jennifer-language ;;
        *)        org="$scope" ;;
    esac
fi

[[ "$slug" =~ ^[a-z][a-z0-9]*$ ]] ||
    die "the slug is a Jennifer module name: lowercase letters and digits, starting with a letter (got \"$slug\")"
[[ "$scope" =~ ^[A-Za-z0-9_-]+$ ]] || die "the scope looks wrong: \"$scope\""
[[ "$org" =~ ^[A-Za-z0-9-]+$ ]] || die "the GitHub organisation looks wrong: \"$org\""
[[ -f src/mydeck.j ]] || die "src/mydeck.j is gone - has this template already been initialised?"

mv src/mydeck.j "src/${slug}.j"
mv src/mydeck_test.j "src/${slug}_test.j"

# Only files that carry the identity. LICENSE and JENNIFER.md are verbatim
# upstream copies and are left alone; TEMPLATE.md is about to be deleted.
files=(deck.toml grimoire.toml README.md docs/*.md examples/*.j "src/${slug}.j" "src/${slug}_test.j")

for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    sed -i \
        -e "s|@myscope/mydeck|@${scope}/${slug}|g" \
        -e "s|jennifer-language/deck-template|${org}/deck-${slug}|g" \
        -e "s|jennifer-language\.github\.io/deck-template|${org}.github.io/deck-${slug}|g" \
        -e "s|deck-template|deck-${slug}|g" \
        -e "s|mydeck|${slug}|g" \
        "$f"
done

if [[ -n "$description" ]]; then
    sed -i "s|^description = .*|description = \"${description}\"|" deck.toml
    sed -i "s|^description = .*|description = \"${description}\"|" grimoire.toml
fi

# The shared files are the template's, untouched by the rewrite above; record
# them so tools/check-shared.sh holds the new deck to them from now on.
tools/sync-deck.sh --lock . > /dev/null

echo "initialised @${scope}/${slug} (repository github.com/${org}/deck-${slug})"
echo
echo "next:"
echo "  rm TEMPLATE.md tools/init-deck.sh tools/sync-deck.sh"
echo "  jennifer test src/${slug}_test.j"
echo "  tools/check-all.sh"
