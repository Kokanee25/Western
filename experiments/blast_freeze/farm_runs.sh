#!/bin/bash
# #584: the farmhouse's ring of sticks, several runs, two at a time (ports 8741/8742).
#   experiments/blast_freeze/farm_runs.sh DIR OUT_PREFIX N [SECONDS] [EXTRA bf_blast ARGS...]
# DIR is the checkout to run (this one, or a worktree at origin/main with this lab's bridge.gd
# copied in); runs land in DIR/build/farm/OUT_PREFIX_K.json. Physics outcomes only: two games at
# once share the cores, so don't read frame times off these (run one at a time for those).
# GAME_ARGS=--no-ground-lift (say) passes the game its arguments.
dir=$1; pre=$2; n=$3; secs=${4:-30}; shift 4; extra="$*"
cd "$dir" || exit 1
mkdir -p build/farm
run() {
	local k=$1 port=$2
	printf 'bf_blast in=farm fire=0 fuse=1 gap=3 seconds=%s %s out=build/farm/%s_%s.json\nquit\n' "$secs" "$extra" "$pre" "$k" > "build/farm/${pre}_$k.txt"
	python3 tools/bridge.py run "build/farm/${pre}_$k.txt" --headless --fps=60 --port=$port ${GAME_ARGS:+--game-args=$GAME_ARGS} > "build/farm/${pre}_$k.log" 2>&1
}
k=1
while [ $k -le $n ]; do
	run $k 8741 &
	if [ $((k + 1)) -le $n ]; then run $((k + 1)) 8742 & fi
	wait
	k=$((k + 2))
done
