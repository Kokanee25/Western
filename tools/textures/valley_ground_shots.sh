#!/usr/bin/env bash
# The valley's ground views (#891): six fixed cameras through the dev bridge, one game, the real look.
#   tools/textures/valley_ground_shots.sh OUT_DIR [extra game args, comma separated] [only=name,name]
# Views: name hour eye(x y z) target(x y z), from tools/textures/valley_ground_views.txt.
set -e
OUT=${1:?out dir}; EXTRA=${2:-}; ONLY=${3:-}
mkdir -p "$OUT"
ARGS="--real,--world=valley,--crash-watch=40,180${EXTRA:+,$EXTRA}"
python3 tools/bridge.py start --size=1280x720 --game-args="$ARGS" > "$OUT/bridge.log" 2>&1
cmds=("wait 8")
while read -r name hour ex ey ez tx ty tz; do
  [ -z "$name" ] && continue
  case "$name" in \#*) continue;; esac
  if [ -n "$ONLY" ] && [[ ",$ONLY," != *",$name,"* ]]; then continue; fi
  cmds+=("time $hour" "camera $ex $ey $ez $tx $ty $tz" "wait 12" "screenshot $(realpath "$OUT")/$name.png")
done < tools/textures/valley_ground_views.txt
cmds+=("read frame")
python3 tools/bridge.py "${cmds[@]}" >> "$OUT/bridge.log" 2>&1 || true
python3 tools/bridge.py stop >> "$OUT/bridge.log" 2>&1 || true
ls "$OUT"
