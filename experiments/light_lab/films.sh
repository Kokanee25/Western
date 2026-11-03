#!/usr/bin/env bash
# The light lab's two films (issue #608 part 1), the camera still in each:
#   1 a lamp carried across the saloon and knocked over (its bounce goes with it, then out);
#   2 a stick against the back wall, the wall blown open and the moonlight coming in.
#   experiments/light_lab/films.sh OUTDIR [on|off] [LAMP]
# on (default) with RoomLight, off the game's light now. LAMP: a lamp prop's name part or index
# (rl_lamps). Frames by the lab's rl_record at a fixed 15 fps step (lavapipe: ~10 s a frame at 640x360), then ffmpeg.
set -euo pipefail
OUT=$(realpath -m "${1:?OUTDIR}")
MODE=${2:-on}
LAMP=${3:-OilLamp2}
ON=$([ "$MODE" = on ] && echo true || echo false)
B="python3 tools/bridge.py"
mkdir -p "$OUT"
cd "$(dirname "$0")/../.."
$B start --size=640x360 --fps=15
trap '$B stop || true' EXIT
$B "time 22" "clock off" "set settings.room_light $ON" "wait 2" "rl_lamps" > "$OUT/lamps_$MODE.json"
# Film 1: from the back of the room toward the bar and the card tables.
$B "rl_cam 2.2 2.5 11.2 6.5 1.5 4.0 70" "wait 1" "rl_state" > "$OUT/state1_before_$MODE.json"
$B "rl_record $OUT/lamp_$MODE" "wait 1" "rl_carry $LAMP 6.0 2.0 5.2 4" "wait 1.5" "rl_knock $LAMP" "wait 2.5" "rl_record stop" "rl_state" \
    > "$OUT/state1_after_$MODE.json"
# Film 2: inside, looking at the back wall; a stick outside it.
$B "rl_cam 5.0 2.4 3.0 4.5 2.0 12.0 70" "wait 1" "rl_where 4.5 1.0 12.4" > "$OUT/state2_before_$MODE.json"
$B "rl_record $OUT/wall_$MODE" "wait 1" "rl_blast 4.5 1.0 12.4 1.5" "wait 8" "rl_record stop" "rl_state" > "$OUT/state2_after_$MODE.json"
$B stop
trap - EXIT
for f in lamp wall; do
  ffmpeg -loglevel error -y -framerate 15 -i "$OUT/${f}_$MODE/%04d.png" -vf "scale=640:-2" -pix_fmt yuv420p "$OUT/${f}_$MODE.mp4"
done
echo "films: $OUT/lamp_$MODE.mp4 $OUT/wall_$MODE.mp4"
