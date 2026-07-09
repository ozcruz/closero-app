#!/usr/bin/env bash
# CLAUDE.md verification step 4: grep guards. Run from the repo root.
# Fails (exit 1) if any forbidden pattern appears in lib/.
set -u

fail=0

hits=$(grep -rn --include='*.dart' 'Color(0x' lib | grep -v 'tokens\.g\.dart' || true)
if [ -n "$hits" ]; then
  echo 'FAIL: Color(0x...) outside tokens.g.dart:'
  echo "$hits"
  fail=1
fi

hits=$(grep -rn --include='*.dart' -- '—' lib || true)
if [ -n "$hits" ]; then
  echo 'FAIL: em dash in lib/:'
  echo "$hits"
  fail=1
fi

hits=$(grep -rni --include='*.dart' 'founding' lib || true)
if [ -n "$hits" ]; then
  echo 'FAIL: "founding" wording in lib/ (membership naming is "Day One"):'
  echo "$hits"
  fail=1
fi

hits=$(grep -rniE --include='*.dart' 'E8D5A3|A89060|232, ?213, ?163|168, ?144, ?96' lib || true)
if [ -n "$hits" ]; then
  echo 'FAIL: retired gold hex/rgba in lib/:'
  echo "$hits"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo 'Grep guards: clean.'
fi
exit "$fail"
