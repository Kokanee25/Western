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
    # Four men with no walk of their own crossing toward the camera (config/moments/library_walkers.json).
    for v in old new; do
      lib=$([ "$v" = new ] && echo on || echo off)
      film "street_$v" "library $lib" "time 17.5" "camera 5.0 1.6 -5.8 -3.0 0.9 -4.6 50" "wait 3" \
        "moment library_walkers" "waits 6" "moment_result" "library"
    done
    pair street ;;&
  saloon|all)
    # The gunfight lab's hall (spec_hall): the scripted careful player against the three, the
    # camera on Brody (gf_watch: from his side away from you).
    for v in old new; do
      lib=$([ "$v" = new ] && echo on || echo off)
      film "saloon_$v" "library $lib" "gf_play spec_hall seed=3 style=cover count=2" \
        "gf_watch brody 4.5 50 1.7 60" "waits 12" "gf_result" "library"
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

# The farmhouse (#520): the scripted player in by the back door, from his eyes (the mission's own
# film set-up, experiments/farmhouse/film.sh), old and new side by side.
if [ "$WHICH" = farmhouse ]; then
  for v in old new; do
    lib=$([ "$v" = new ] && echo on || echo off)
    printf 'library %s\ntime 15\nfarm_run back seed=2 max=200\nquit\n' "$lib" > "$OUT/farm_$v.txt"
    xvfb-run -a -s "-screen 0 640x360x24" godot --path "$ROOT" --rendering-driver vulkan --resolution 640x360 --fixed-fps 30 \
      --write-movie "$(realpath "$OUT")/farmhouse_$v.avi" -- --dev-bridge --deterministic --bridge-port=8772 \
      --bridge-script="$(realpath "$OUT/farm_$v.txt")" > "$OUT/farmhouse_$v.log" 2>&1 || true
    ffmpeg -y -loglevel error -i "$OUT/farmhouse_$v.avi" -an -c:v libx264 -crf 23 -pix_fmt yuv420p "$OUT/farmhouse_$v.mp4"
    rm -f "$OUT/farmhouse_$v.avi"
  done
  pair farmhouse
fi
