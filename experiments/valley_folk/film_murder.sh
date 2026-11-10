#!/usr/bin/env bash
# No Law's murder filmed (#773): sat at the card table (your eyes, turned to Earl) and from the bar
# (a free camera looking at the table). Godot's Movie Maker through the dev bridge, the valley at
# night, ffmpeg to mp4. Under lavapipe a game second is ~30 real ones: a film is ~25 min.
#   experiments/valley_folk/film_murder.sh build/murder_films [seat|bar|all]
set -euo pipefail
OUT="${1:-build/murder_films}"
WHICH="${2:-all}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
mkdir -p "$OUT"
export PATH="$HOME/godot:$PATH"
cd "$ROOT"

film() {  # name, camera line
  local name="$1" cam="$2"
  cat > "$OUT/$name.txt" <<CMDS
time 21
wait 3
sit n
$cam
moment no_law_murder
$(for i in $(seq 1 18); do echo "wait 2"; done)
moment_result
CMDS
  python3 tools/bridge.py run "$OUT/$name.txt" --size=960x540 --movie="$OUT/$name.avi" --game-args=--world=valley,--no-murder \
      --port="${PORT:-8737}" --timeout=1800 > "$OUT/$name.log" 2>&1
  ffmpeg -y -loglevel error -i "$OUT/$name.avi" -c:v libx264 -crf 24 -preset slow -pix_fmt yuv420p -c:a aac -b:a 96k "$OUT/$name.mp4"
  rm -f "$OUT/$name.avi"
  grep -o '"end": *"[a-z_]*"' "$OUT/$name.log" | tail -1 || true
}

case "$WHICH" in
  seat|all) film seat "look earl" ;;&
  bar|all) film bar "camera 26.2 2.3 -11.8 31.4 0.8 -15.3" ;;&
esac
ls -la "$OUT"/*.mp4
