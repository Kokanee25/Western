#!/usr/bin/env bash
# Three films of people on Uthana's clips (Sean, 2026-10-24): five walks in a row across the street,
# the barkeep's cloth and mop, a man at the trough. Godot's Movie Maker through the dev bridge
# (tools/bridge.py --movie), ffmpeg to mp4; ~8-12 min a film under lavapipe. One at a time (two
# bridge games can't share build/bridge/).
#   experiments/motion_films/film.sh build/motion_films [walks|barkeep|trough|all]
set -euo pipefail
OUT="${1:-build/motion_films}"
WHICH="${2:-all}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
mkdir -p "$OUT"
export PATH="$HOME/godot:$PATH"
cd "$ROOT"

film() {  # name, the command lines
  local name="$1"; shift
  printf '%s\n' "$@" > "$OUT/$name.txt"
  python3 tools/bridge.py run "$OUT/$name.txt" --size=960x540 --movie="$OUT/$name.avi" > "$OUT/$name.log" 2>&1
  ffmpeg -y -loglevel error -i "$OUT/$name.avi" -c:v libx264 -crf 24 -preset slow -pix_fmt yuv420p -c:a aac -b:a 96k "$OUT/$name.mp4"
  grep -o '"state": *"[a-z_]*"' "$OUT/$name.log" | tail -1 || true
}
waits() { for i in $(seq 1 "$1"); do echo "wait 2"; done; }

case "$WHICH" in
  walks|all)
    # From the saloon's side of the street, looking across at the five walking left to right.
    film walks "time 17.5" "camera -2.0 1.9 3.5 -2.0 1.0 -5.5 60" "wait 3" "moment walks_lineup" $(waits 11) "moment_result" ;;&
  barkeep|all)
    # Over the bar at the barkeep: his cloth first (rag_do wipe starts it), the mop after (mop_do look).
    # At 11 the bar has no customers (a man at the bar stops the wiping: WipeBar._customer).
    film barkeep "time 11" "camera 10.6 2.0 7.2 13.2 1.1 5.4 55" "wait 3" "rag_do wipe" $(waits 9) "mop_do look" $(waits 10) "rag" "mop" ;;&
  trough|all)
    # The store's trough from the street.
    film trough "time 17.5" "camera 0.0 1.8 -1.2 2.6 0.7 -4.2 55" "wait 3" "moment trough_scoop" $(waits 6) "moment_result" ;;&
esac
ls -la "$OUT"/*.mp4
