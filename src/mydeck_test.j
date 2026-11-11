# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * White-box tests for the entry module: jennifer test src/mydeck_test.j
 *
 * The overlay is compiled with its module, so it reaches unexported helpers.
 * Test the logic that does not touch the network.
 */
use testing;

func testGreet() {
    testing.assertEqual(greet("Ada"), "hello, Ada");
}

func testGreetTrimsItsInput() {
    testing.assertEqual(greet("  Ada  "), "hello, Ada");
}

func testGreetFallsBackToTheWorld() {
    testing.assertEqual(greet(""), "hello, world");
    testing.assertEqual(greet("   "), "hello, world");
}
