#!/bin/bash
# #584: main and this branch run ALTERNATELY, one game at a time (for frame times): N pairs of the
# farmhouse's ring of sticks, SECONDS recorded after the last.
#   experiments/blast_freeze/farm_pairs.sh MAIN_DIR N [SECONDS] [EXTRA bf_blast ARGS...]
# MAIN_DIR: a worktree at origin/main with this lab's bridge.gd, seconds.py and tools/bridge.py
# copied in. Runs: build/farm/pair_{main,branch}_K.json in each checkout.
main=$1; n=$2; secs=${3:-45}; shift 3; extra="$*"
here=$(cd "$(dirname "$0")/../.." && pwd)
tag=${TAG:-pair}
for k in $(seq 1 "$n"); do
	for side in main branch; do
		dir=$here; [ $side = main ] && dir=$main
		(cd "$dir" && mkdir -p build/farm && printf 'bf_blast in=farm fire=0 fuse=1 gap=3 seconds=%s %s out=build/farm/%s_%s_%s.json\nquit\n' "$secs" "$extra" "$tag" "$side" "$k" > "build/farm/${tag}_${side}_$k.txt" \
			&& python3 tools/bridge.py run "build/farm/${tag}_${side}_$k.txt" --headless --fps=60 > "build/farm/${tag}_${side}_$k.log" 2>&1)
	done
done
