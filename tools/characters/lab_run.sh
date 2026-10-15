#!/bin/bash
# Run the art_lab test scene; once it says it's done, give it 15 s to quit, then end it (under
# lavapipe it sometimes hangs on quit after writing everything). Usage: lab_run.sh LOG args...
LOG=$1; shift
TMP=$(mktemp)
setsid xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/art_lab.gd -- "$@" > $TMP 2>&1 &
PID=$!
for i in $(seq 1 360); do
  sleep 5
  if ! kill -0 $PID 2>/dev/null; then break; fi
  if grep -q "art_lab: done" $TMP; then sleep 15; kill -- -$PID 2>/dev/null; break; fi
done
kill -- -$PID 2>/dev/null
cat $TMP >> $LOG; rm -f $TMP
