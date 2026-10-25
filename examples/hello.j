#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

/**
 * Greet the world: jennifer run examples/hello.j
 *
 * Template: one example per subject, named after it. CI runs every example,
 * so one broken by a rename fails the build. When examples need a host or a
 * credential, override tools/check-examples.sh to parse-check them instead,
 * as deck-routeros does.
 */

use io;

import "../src/mydeck.j" as mydeck;

io.printf("%s\n", mydeck.greet("world"));
