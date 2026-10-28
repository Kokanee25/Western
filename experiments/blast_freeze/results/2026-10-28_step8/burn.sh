#!/bin/bash
# The whole-saloon burn (../2026-10-27_whole_burn/run_burn_headless.sh): every 15 s of game
# time for 3 minutes, in the repo $1, readings to $2.
set -u
cd "$1"
OUT=$2
python3 tools/bridge.py start --headless --fps=60 > /dev/null 2>&1
B() { echo "### $*"; python3 tools/bridge.py "$@" 2>&1 | cut -c1-500; }
{
B "gf_ways" > /dev/null
B "time 17.6" "goto -60 4 28" "wait 2" "read frame" "read counts"
B "ignite -66 1.5 32" "ignite -62 1.5 30" "ignite -68 2.5 34" "ignite -64 2.5 33" "ignite -66 3.5 32" "ignite -70 1.5 36"
for k in $(seq 1 12); do
  B "wait 15" "read frame" "read counts"
done
} > "$OUT" 2>&1
python3 tools/bridge.py stop > /dev/null 2>&1
