#!/bin/bash
# #626: Sean's one stick inside the farmhouse, the mission running, SECONDS recorded after it; one
# run a variant, in turn, one game at a time (for frame times).
#   experiments/blast_freeze/collapse_runs.sh OUT_DIR SECONDS VARIANT...
# A VARIANT is NAME[:GAME_ARGS][@V/P]: the game's flags comma separated (--game-args), and Jolt's
# velocity/position steps for that run (written to override.cfg, removed after). Run in the
# checkout it's in (or set DIR=a worktree). Runs: OUT_DIR/NAME.json and .log.
out=$1; secs=$2; shift 2
dir=${DIR:-$(cd "$(dirname "$0")/../.." && pwd)}
extra=${EXTRA:-}
# #642: WORLD (sticks, `;` between), STAND and GAP override #626's one stick and where Sean stood.
world=${WORLD:-97.8,2.34,-48.94}; stand=${STAND:-96.3,1.1,-33.6}; gap=${GAP:-0.4}
mkdir -p "$out"
for v in "$@"; do
	steps=""; [[ $v == *@* ]] && { steps=${v#*@}; v=${v%@*}; }
	name=${v%%:*}; args=""; [[ $v == *:* ]] && args=${v#*:}
	(cd "$dir" || exit 1
	rm -f override.cfg
	if [ -n "$steps" ]; then
		printf '[physics]\njolt_physics_3d/simulation/velocity_steps=%s\njolt_physics_3d/simulation/position_steps=%s\n' "${steps%/*}" "${steps#*/}" > override.cfg
	fi
	printf 'bf_blast in=farm mission=1 world=%s stand=%s gap=%s fire=0 fuse=1 seconds=%s %s out=%s/%s.json\nquit\n' "$world" "$stand" "$gap" "$secs" "$extra" "$out" "$name" > "$out/$name.txt"
	ga=""; [ -n "$args" ] && ga="--game-args=$args"
	python3 tools/bridge.py run "$out/$name.txt" --headless --fps=60 $ga > "$out/$name.log" 2>&1
	rm -f override.cfg)
	echo "$(date +%T) $name done" >> "$out/progress.log"
done
