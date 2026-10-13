#!/usr/bin/env bash
# PLCYIO harness verdict. Runs the TK5 job twice:
#   1. as shipped (shop macro maclib/ASHRLEN.mac)
#   2. with the proposed macro (proposals/ASHRLEN.proposed.mac), WITHOUT changing maclib/
# and checks: every step COND CODE 0000; unblocked output equals goldens/unblocked.txt;
# as shipped, the blocked file overwrites the caller's guard on every read (FINDING-001);
# with the proposed macro, the blocked output equals the golden and the guard is never touched.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd); work=$here/harness/work; mkdir -p "$work"
golden=$(cat "$here/goldens/unblocked.txt")
check() { # <results> -> prints "unblocked|blocked|overwrites|steps_ok"
  local f=$1
  local u b n s
  u=$(grep '^RESULT POLICIES' "$f" | sed -n 1p); b=$(grep '^RESULT POLICIES' "$f" | sed -n 2p)
  n=$(grep -c '^RESULT GUARD OVERWRITTEN' "$f" || true)
  s=$(grep -c 'COND CODE 0000' "$f" || true)
  echo "$u|$b|$n|$s"
}
RESULTS=$work/results-shipped.txt bash "$here/harness/run_tk5.sh" >/dev/null
RESULTS=$work/results-proposed.txt ASHRLEN_MACRO=$here/proposals/ASHRLEN.proposed.mac bash "$here/harness/run_tk5.sh" >/dev/null
IFS='|' read -r su sb sn ss <<<"$(check "$work/results-shipped.txt")"
IFS='|' read -r pu pb pn ps <<<"$(check "$work/results-proposed.txt")"
ok=1
row() { printf '  %-34s %-10s %s\n' "$1" "$2" "$3"; }
eq() { if [ "$1" = "$golden" ]; then echo yes; else echo NO; fi; }
echo "PLCYIO on MVS 3.8j (TK5): 24 policies, POLMAST unblocked (BLKSIZE=80) and blocked (BLKSIZE=800)"
echo
row "check" "expected" "observed"
row "shipped: job steps COND CODE 0000" "7" "$ss"
row "shipped: unblocked = golden" "yes" "$(eq "$su")"
row "shipped: blocked guard overwrites" "24" "$sn   <- FINDING-001 reproduced"
row "proposed macro: steps COND 0000" "7" "$ps"
row "proposed macro: unblocked = golden" "yes" "$(eq "$pu")"
row "proposed macro: blocked = golden" "yes" "$(eq "$pb")"
row "proposed macro: guard overwrites" "0" "$pn"
[ "$su" = "$golden" ] && [ "$pu" = "$golden" ] && [ "$pb" = "$golden" ] && [ "$sb" = "$golden" ] && [ "$ss" = 7 ] && [ "$ps" = 7 ] && [ "$sn" = 24 ] && [ "$pn" = 0 ] || ok=0
echo
echo "golden: $golden"
if [ $ok = 1 ]; then
  echo "verdict: FINDING-001 confirmed (PLCYIO copies BLKSIZE bytes, not LRECL). Proposed macro clears it. maclib/ASHRLEN.mac not changed: shared, no owner (see docs/ESCALATION.md)."
else
  echo "verdict: harness did not behave as specified"; exit 1
fi
