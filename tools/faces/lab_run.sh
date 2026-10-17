#!/bin/bash
# Run the face lab under xvfb; once it says it's done, give it 10 s to quit, then end it (under
# lavapipe Godot sometimes hangs on quit). Usage: tools/faces/lab_run.sh LOG args...
LOG=$1; shift
TMP=$(mktemp)
setsid xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/faces/face_lab.gd -- "$@" > $TMP 2>&1 &
PID=$!
for i in $(seq 1 720); do
  sleep 5
  if ! kill -0 $PID 2>/dev/null; then break; fi
  if grep -q "face_lab: done" $TMP; then sleep 10; kill -- -$PID 2>/dev/null; break; fi
done
kill -- -$PID 2>/dev/null
cat $TMP >> $LOG; rm -f $TMP
