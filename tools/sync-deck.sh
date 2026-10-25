#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
#
# Write the shared CI layer from this template into one or more decks.
#
# What is shared, and how each entry is treated, is listed in tools/shared-files.
# Every shared file is copied verbatim and its sha256 recorded in the deck's
# tools/shared.lock, which tools/check-shared.sh then holds the deck to in CI.
# The deck's own files - src/, docs/, examples/, tools/check-examples.sh,
# tools/check-extra.sh, extra workflows - are never touched, except where
# shared-files says to seed, merge or import into one.
#
# It overwrites, so it refuses a deck that is not a git repository, or that
# has uncommitted changes in a file it would write, unless given --force. Run
# with --dry-run first to see what it would do.
#
# This script belongs to the template only. tools/init-deck.sh runs it with
# --lock to record the lock of a new deck, which then deletes it.
#
# Usage: tools/sync-deck.sh [--dry-run] [--force] <deck-dir>...
#        tools/sync-deck.sh --lock <deck-dir>   (write the lock only)
set -euo pipefail
shopt -s extglob

template="$(cd "$(dirname "$0")/.." && pwd)"
list="${template}/tools/shared-files"

die() { echo "error: $*" >&2; exit 1; }

dry_run=0; force=0; lock_only=0; targets=()
for arg in "$@"; do
    case "$arg" in
        --dry-run) dry_run=1 ;;
        --force)   force=1 ;;
        --lock)    lock_only=1 ;;
        -*)        die "unknown option $arg" ;;
        *)         targets+=("$arg") ;;
    esac
done
(( ${#targets[@]} > 0 )) || die "usage: tools/sync-deck.sh [--dry-run] [--force] <deck-dir>..."

# The entries of tools/shared-files, as "kind path [args...]".
entries() {
    grep -vE '^[[:space:]]*(#|$)' "$list"
}

# Where the files came from: the template's commit when it has one.
describe_source() {
    local rev
    if rev="$(git -C "$template" describe --always --dirty 2>/dev/null)"; then
        printf 'template %s, synced %s\n' "$rev" "$(date -u +%Y-%m-%d)"
    else
        printf 'template (no git), synced %s\n' "$(date -u +%Y-%m-%d)"
    fi
}

write_lock() {
    local deck="$1" kind path
    {
        echo "# tools/shared.lock - written by the template's tools/sync-deck.sh. Do not"
        echo "# edit: tools/check-shared.sh fails CI when a file below differs from it."
        echo "# source: $(describe_source)"
        while read -r kind path _; do
            case "$kind" in
                shared) (cd "$deck" && sha256sum "$path") ;;
                optional) [[ ! -f "${deck}/${path}" ]] || (cd "$deck" && sha256sum "$path") ;;
            esac
        done < <(entries)
    } > "${deck}/tools/shared.lock"
}

# --lock: record what is there now. Used on a deck that was just made from a
# copy of the template, whose shared files are the template's by construction.
if (( lock_only )); then
    for deck in "${targets[@]}"; do
        write_lock "$deck"
        echo "wrote ${deck}/tools/shared.lock"
    done
    exit 0
fi

# Only the template is a source: a deck that kept this script by mistake must
# not push its own copies around.
grep -q '^name = "@myscope/mydeck"' "${template}/deck.toml" 2>/dev/null ||
    die "${template} is not the template - sync from the template repository"

sha() { sha256sum "$1" | cut -d' ' -f1; }

sync_one() {
    local deck="$1" kind path args src dst plan=() writes=() dirty
    deck="$(cd "$deck" && pwd)" || die "no such directory: $1"
    [[ "$deck" != "$template" ]] || die "refusing to sync the template into itself"
    compgen -G "${deck}/deck.@(toml|yaml|yml|json)" >/dev/null ||
        die "${deck} has no deck manifest - is it a deck?"

    echo "=== ${deck}"

    # A deck that was synced before and has no copy of an optional file has
    # opted out of it; a deck synced for the first time gets it.
    local first=0
    [[ -f "${deck}/tools/shared.lock" ]] || first=1

    while read -r kind path args; do
        src="${template}/${path}"
        dst="${deck}/${path}"
        case "$kind" in
            shared)
                if [[ ! -f "$dst" ]]; then
                    plan+=("add      $path"); writes+=("$path")
                elif ! cmp -s "$src" "$dst"; then
                    plan+=("update   $path"); writes+=("$path")
                fi
                ;;
            optional)
                if [[ ! -f "$dst" ]]; then
                    (( first )) && { plan+=("add      $path"); writes+=("$path"); }
                elif ! cmp -s "$src" "$dst"; then
                    plan+=("update   $path"); writes+=("$path")
                fi
                ;;
            seed)
                if [[ ! -f "$dst" ]]; then
                    plan+=("add      $path"); writes+=("$path")
                elif [[ " $args " == *" $(sha "$dst") "* ]]; then
                    plan+=("replace  $path (an unmodified older template copy)"); writes+=("$path")
                fi
                ;;
            merge)
                if [[ ! -f "$dst" ]]; then
                    plan+=("add      $path"); writes+=("$path")
                else
                    local n
                    n="$(grep -vE '^[[:space:]]*(#|$)' "$src" | grep -cvxFf "$dst" || true)"
                    (( n == 0 )) || { plan+=("append   $path ($n line(s))"); writes+=("$path"); }
                fi
                ;;
            import)
                # `@AGENTS.md` means nothing in a deck that opted out of AGENTS.md
                if [[ "$args" == @* && ! -f "${deck}/${args#@}" &&
                      " ${writes[*]} " != *" ${args#@} "* ]]; then
                    :
                elif [[ ! -f "$dst" ]]; then
                    plan+=("add      $path"); writes+=("$path")
                elif ! grep -qxF -- "$args" "$dst"; then
                    plan+=("import   $path ($args)"); writes+=("$path")
                fi
                ;;
            retired)
                [[ ! -e "$dst" ]] || { plan+=("remove   $path"); writes+=("$path"); }
                ;;
            *)
                die "tools/shared-files: unknown kind '$kind' for $path"
                ;;
        esac
    done < <(entries)

    if (( ${#plan[@]} == 0 )); then
        echo "  already in sync"
    else
        printf '  %s\n' "${plan[@]}"
    fi
    (( dry_run )) && return 0

    # Overwriting is only safe where the old content can be got back.
    if (( ! force )); then
        if ! git -C "$deck" rev-parse --git-dir >/dev/null 2>&1; then
            die "${deck} is not a git repository, so nothing written could be undone - commit it to git first, or pass --force"
        fi
        if (( ${#writes[@]} > 0 )); then
            dirty="$(git -C "$deck" status --porcelain -- "${writes[@]}")"
            [[ -z "$dirty" ]] || die "${deck} has uncommitted changes in files the sync writes:
${dirty}
commit or stash them first, or pass --force"
        fi
    fi

    while read -r kind path args; do
        src="${template}/${path}"
        dst="${deck}/${path}"
        [[ " ${writes[*]} " == *" ${path} "* ]] || continue
        case "$kind" in
            shared | optional | seed)
                mkdir -p "$(dirname "$dst")"
                cp --preserve=mode "$src" "$dst"
                ;;
            merge)
                if [[ -f "$dst" ]]; then
                    grep -vE '^[[:space:]]*(#|$)' "$src" | grep -vxFf "$dst" >> "$dst" || true
                else
                    cp --preserve=mode "$src" "$dst"
                fi
                ;;
            import)
                if [[ -f "$dst" ]]; then
                    # After the title, if the file opens with one.
                    if head -1 "$dst" | grep -q '^#'; then
                        sed -i "1a\\
\\
${args}" "$dst"
                    else
                        sed -i "1i\\
${args}\\
" "$dst"
                    fi
                else
                    cp --preserve=mode "$src" "$dst"
                fi
                ;;
            retired)
                rm -f "$dst"
                ;;
        esac
    done < <(entries)

    write_lock "$deck"
    echo "  wrote tools/shared.lock"
}

for target in "${targets[@]}"; do
    sync_one "$target"
done

if (( dry_run )); then
    echo ""
    echo "dry run - nothing was written"
else
    echo ""
    echo "next, in each deck:"
    echo "  tools/check-all.sh"
    echo "  tools/check-docs.sh --todo     # gaps to seed docs/.cheatsheet-todo with"
    echo "  tools/check-coverage.sh --todo # gaps to seed tools/.coverage-todo with"
fi
