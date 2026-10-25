#!/bin/bash
# chaos5.sh TAG: the chaos digest five times on one worker thread, with 4 busy loops loading the CPU.
TAG=$1; cd /home/user/Western
mkdir -p build/chaos/$TAG
printf '[threading]\n\nworker_pool/max_threads=1\n' > override.cfg
LOADPIDS=()
for i in 1 2 3 4; do ( while :; do :; done ) & LOADPIDS+=($!); done
for i in 1 2 3 4 5; do
  $HOME/godot/godot --headless --fixed-fps 60 -s res://tests/run_tests.gd -- --only=test_write_a_digest_when_asked --chaos-digest=$PWD/build/chaos/$TAG/d$i.json > build/chaos/$TAG/log$i.txt 2>&1
  echo "run $i: $(md5sum < build/chaos/$TAG/d$i.json | cut -c1-8)"
done
kill "${LOADPIDS[@]}"
rm -f override.cfg
