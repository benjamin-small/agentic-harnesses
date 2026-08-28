#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/autopoietic-builder/bin/scaffold-autopoietic-skill"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local file="$1" expected="$2"
  grep -Fq "$expected" "$file" || fail "$file does not contain: $expected"
}

help_output="$TEST_ROOT/help.txt"
"$SCRIPT" --help >"$help_output"
assert_contains "$help_output" 'scaffold-autopoietic-skill <name>'

if "$SCRIPT" --mission 'missing name' --target "$TEST_ROOT/output" >"$TEST_ROOT/missing-name.txt" 2>&1; then
  fail 'missing name was accepted'
fi
assert_contains "$TEST_ROOT/missing-name.txt" 'missing <name>'

if "$SCRIPT" 'Invalid_Name' --mission 'invalid name' --target "$TEST_ROOT/output" >"$TEST_ROOT/invalid-name.txt" 2>&1; then
  fail 'invalid name was accepted'
fi
assert_contains "$TEST_ROOT/invalid-name.txt" 'lowercase letters, digits, and hyphens only'

target="$TEST_ROOT/generated"
"$SCRIPT" sample-skill \
  --mission 'Verified sample domain' \
  --target "$target" \
  --license 'Proprietary' \
  >"$TEST_ROOT/success.txt" 2>&1

skill="$target/sample-skill"
test -f "$skill/SKILL.md" || fail 'SKILL.md was not generated'
test -f "$skill/mission.md" || fail 'mission.md was not generated'
test -f "$skill/references/growth-protocol.md" || fail 'references were not copied'
assert_contains "$skill/SKILL.md" 'name: sample-skill'
assert_contains "$skill/mission.md" 'Verified sample domain'
if grep -Fq 'mission_hash: "pending"' "$skill/SKILL.md"; then
  fail 'mission hash was not computed'
fi

if "$SCRIPT" sample-skill --mission 'overwrite attempt' --target "$target" >"$TEST_ROOT/overwrite.txt" 2>&1; then
  fail 'existing target was overwritten'
fi
assert_contains "$TEST_ROOT/overwrite.txt" 'target already exists'

printf 'PASS: scaffold-autopoietic-skill\n'
