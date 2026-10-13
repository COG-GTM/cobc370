#!/usr/bin/env bash
# Back to a clean state: removes harness/work only. Nothing on the MVS guest persists (temporary datasets).
set -euo pipefail
rm -rf "$(cd "$(dirname "$0")" && pwd)/work"
echo "ashgrove-policy: reset (harness/work removed)"
