#!/bin/bash
# The burn, headless: physics ms a tick, nodes and burning members every 15 s of game time for 3 minutes.
set -u
export PATH=$HOME/godot:$PATH GODOT=$HOME/godot/godot
cd /home/user/Western
L=build/fire_draws
python3 tools/bridge.py start --headless --fps=60 > $L/start_h.log 2>&1; echo "start: $(tail -1 $L/start_h.log)"
B() { echo "### $*"; python3 tools/bridge.py "$@" 2>&1 | cut -c1-500; }
B "gf_ways" > $L/ways_h.txt 2>&1; echo "gf_ways: $(grep -c . $L/ways_h.txt) lines, $(head -c 120 $L/ways_h.txt)"
B "time 17.6" "goto -60 4 28" "wait 2" "read frame" "read counts"
B "ignite -66 1.5 32" "ignite -62 1.5 30" "ignite -68 2.5 34" "ignite -64 2.5 33" "ignite -66 3.5 32" "ignite -70 1.5 36"
for k in $(seq 1 12); do
  B "wait 15" "read frame" "read counts"
done
B "read all" > $L/read_all_h.txt 2>&1
python3 tools/bridge.py stop
echo BURN DONE
