#!/usr/bin/env bash
# The card cheat filmed (Sean, 2026-10-24): from the bar where the player stands, from the door,
# golden-hour light through the windows; and the old pose-to-pose kick beside the new animated one
# from the door. Godot's Movie Maker through the dev bridge (tools/bridge.py --movie, as the
# movement films were made), ffmpeg to mp4. Under lavapipe a film is ~8 min of rendering.
#   experiments/card_cheat/film.sh build/card_cheat/films [bar|door|old|all]
set -euo pipefail
OUT="${1:-build/card_cheat/films}"
WHICH="${2:-all}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
mkdir -p "$OUT"
export PATH="$HOME/godot:$PATH"
cd "$ROOT"

film() {  # name, camera line, animated
  local name="$1" cam="$2" anim="$3"
  cat > "$OUT/$name.txt" <<CMDS
time 17.5
$cam
wait 1.5
moment card_cheat animated=$anim hour=17.5
moment_result wait 40
wait 1
CMDS
  python3 tools/bridge.py run "$OUT/$name.txt" --size=960x540 --movie="$OUT/$name.avi" --port="${PORT:-8737}" > "$OUT/$name.log" 2>&1
  ffmpeg -y -loglevel error -i "$OUT/$name.avi" -c:v libx264 -crf 24 -preset slow -pix_fmt yuv420p -c:a aac -b:a 96k "$OUT/$name.mp4"
  grep -o '"state": *"[a-z_]*"' "$OUT/$name.log" | tail -1 || true
}

# The bar: the player's eyes at the middle of the bar's front, looking at the card table.
# The door: just inside the batwings, looking in at the table.
case "$WHICH" in
  bar|all) film bar "camera 11.2 2.35 5.75 7.6 1.0 4.2" 1 ;;&
  door|all) film door "camera 9.4 2.1 1.9 7.7 0.9 4.4" 1 ;;&
  old|all) film old_door "camera 9.4 2.1 1.9 7.7 0.9 4.4" 0 ;;&
esac
if [ -f "$OUT/door.mp4" ] && [ -f "$OUT/old_door.mp4" ]; then
  # Side by side: the old pose-to-pose kick left, the animated one right, each labelled.
  ffmpeg -y -loglevel error -i "$OUT/old_door.mp4" -i "$OUT/door.mp4" -filter_complex \
    "[0:v]scale=640:360,drawtext=text='pose to pose (the kick pose, #204)':x=12:y=12:fontsize=20:fontcolor=white:box=1:boxcolor=black@0.5[a];[1:v]scale=640:360,drawtext=text='animated (Uthana, played as targets)':x=12:y=12:fontsize=20:fontcolor=white:box=1:boxcolor=black@0.5[b];[a][b]hstack=inputs=2[v]" \
    -map "[v]" -map 1:a? -c:v libx264 -crf 24 -pix_fmt yuv420p -shortest "$OUT/old_vs_new.mp4"
fi
ls -la "$OUT"/*.mp4
