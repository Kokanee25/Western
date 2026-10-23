#!/bin/sh
# Shots of every building at noon, as new (--young-town) and as old: experiments/old_buildings/
#   sh experiments/old_buildings/shoot.sh OUTDIR
set -e
OUT=${1:-build/old_buildings}
DIR=$(dirname "$0")
for run in ${RUNS:-new old}; do
	mkdir -p "$OUT/$run"
	sed "s#SHOTS#$(realpath "$OUT/$run")#" "$DIR/views.txt" > "$OUT/$run.txt"
	if [ "$run" = new ]; then extra="--game-args=--young-town"; else extra=""; fi
	python3 tools/bridge.py run "$OUT/$run.txt" --size=960x540 $extra
done
