#!/usr/bin/env bash
# The library clips (issue #529) on film, each scene twice, old (Settings.library_motion off) and
# new (on), side by side, and the lineup of every clip on three Studio men. Godot's Movie Maker
# through the dev bridge (tools/bridge.py --movie), ffmpeg to mp4; ~10 min a scene under lavapipe.
# One game at a time (two bridge games can't share build/bridge/).
#   experiments/library_motion/film.sh build/library_films [street|saloon|lineup|all]
set -euo pipefail
OUT="${1:-build/library_films}"
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
  python3 tools/bridge.py run "$OUT/$name.txt" --size=960x540 --movie="$OUT/$name.avi" > "$OUT/$name.log" 2>&1 || true
  ffmpeg -y -loglevel error -i "$OUT/$name.avi" -an -c:v libx264 -crf 23 -preset medium -pix_fmt yuv420p "$OUT/$name.mp4"
  rm -f "$OUT/$name.avi"
}

pair() {  # name: name_old.mp4 | name_new.mp4 side by side, labelled, as name.mp4
  local n="$1"
  ffmpeg -y -loglevel error -i "$OUT/${n}_old.mp4" -i "$OUT/${n}_new.mp4" -filter_complex \
    "[0:v]scale=640:-2,drawbox=x=0:y=0:w=150:h=34:color=black@0.6:t=fill[a];[1:v]scale=640:-2,drawbox=x=0:y=0:w=150:h=34:color=black@0.6:t=fill[b];[a][b]hstack=inputs=2:shortest=1[v]" \
    -map "[v]" -c:v libx264 -crf 23 -pix_fmt yuv420p "$OUT/$n.mp4"
}

case "$WHICH" in
  street|all)
    # The walkers' moment across the street (five men; Earl keeps his own walk_old, a played clip
    # leads the library's), from the middle of the street, then the town about its day.
    for v in old new; do
      lib=$([ "$v" = new ] && echo on || echo off)
      film "street_$v" "library $lib" "time 17.5" "camera 5.0 1.6 -5.8 -3.0 0.9 -3.3 50" "wait 3" \
        "moment walks_lineup from_x=-9 to_x=7" "waits 9" "moment_result" "library"
    done
    pair street ;;&
  saloon|all)
    # The gunfight lab's hall (spec_hall): the scripted careful player against the three, from the
    # hall's corner by the door.
    for v in old new; do
      lib=$([ "$v" = new ] && echo on || echo off)
      film "saloon_$v" "library $lib" "camera 11.5 2.6 1.2 5.0 0.9 6.0 62" \
        "gf_fight spec_hall style=cover seed=3 max=40" "library"
    done
    pair saloon ;;&
  lineup|all)
    xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 30 -s res://tools/library_lineup.gd -- \
      --out="$OUT/lineup" --film > "$OUT/lineup.log" 2>&1
    ffmpeg -y -loglevel error -framerate 30 -i "$OUT/lineup/frames/%05d.png" -c:v libx264 -crf 23 -pix_fmt yuv420p "$OUT/lineup.mp4"
    xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 30 -s res://tools/library_lineup.gd -- \
      --out="$OUT/lineup" --sheet > "$OUT/sheet.log" 2>&1 ;;&
esac
ls -la "$OUT"/*.mp4
