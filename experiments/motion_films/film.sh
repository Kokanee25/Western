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

film() {  # name, the command lines (a line "waits N" becomes N lines of "wait 2")
  local name="$1"; shift
  : > "$OUT/$name.txt"
  for line in "$@"; do
    if [[ "$line" == waits\ * ]]; then
      for i in $(seq 1 "${line#waits }"); do echo "wait 2" >> "$OUT/$name.txt"; done
    else
      echo "$line" >> "$OUT/$name.txt"
    fi
  done
  python3 tools/bridge.py run "$OUT/$name.txt" --size=960x540 --movie="$OUT/$name.avi" > "$OUT/$name.log" 2>&1
  ffmpeg -y -loglevel error -i "$OUT/$name.avi" -c:v libx264 -crf 24 -preset slow -pix_fmt yuv420p -c:a aac -b:a 96k "$OUT/$name.mp4"
  grep -o '"state": *"[a-z_]*"' "$OUT/$name.log" | tail -1 || true
}

case "$WHICH" in
  walks|all)
    # Down the street at the walkers coming on (a side view had him a speck for most of the walk).
    film walks "time 17.5" "camera 9.0 1.6 -3.2 -6.0 1.0 -3.4 50" "wait 3" "moment walks_lineup" "waits 11" "moment_result" ;;&
  barkeep|all)
    # Over the bar at the barkeep. At 11 the bar has no customers (a man at the bar stops the
    # wiping: WipeBar._customer). The cloth and the mop each in a game of its own: the mop chore
    # starts on the floor's spill within seconds, and a man at one chore isn't asked for the other.
    film barkeep_cloth "time 11" "rag_do wipe" "camera 10.6 2.0 7.2 13.2 1.1 5.4 55" "waits 11" "rag"
    film barkeep_mop "time 11" "mop_do look" "camera 10.6 2.0 7.2 13.2 1.1 5.4 55" "waits 11" "mop"
    ffmpeg -y -loglevel error -i "$OUT/barkeep_cloth.mp4" -i "$OUT/barkeep_mop.mp4" -filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]" -map "[v]" -map "[a]" -c:v libx264 -crf 24 -pix_fmt yuv420p "$OUT/barkeep.mp4" ;;&
  trough|all)
    # The store's trough from the street, three-quarters on (a porch post hid it from the walk).
    film trough "time 17.5" "camera 1.0 1.6 -2.6 3.4 0.7 -4.2 50" "wait 3" "moment trough_scoop" "waits 6" "moment_result" ;;&
esac
ls -la "$OUT"/*.mp4
