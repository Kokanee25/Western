#!/bin/sh
# The three films, one a preset: film.txt's walk round the street and the new saloon, under
# Movie Maker (30 fps on game time), then each to an mp4. Usage: experiments/movement_feel/film.sh OUTDIR
set -e
OUT=${1:-build/movement_films}
mkdir -p "$OUT"
HERE=$(dirname "$0")
for preset in light middle heavy; do
	case $preset in
		light) presses="press movement_preset 0.05
wait 0.2
press movement_preset 0.05" ;;
		middle) presses="" ;;
		heavy) presses="press movement_preset 0.05" ;;
	esac
	{ echo "$presses"; cat "$HERE/film.txt"; } | grep -v '^$' > "$OUT/$preset.txt"
	python3 tools/bridge.py run "$OUT/$preset.txt" --size=640x360 --movie="$OUT/$preset.avi" > "$OUT/$preset.log" 2>&1
	ffmpeg -y -loglevel error -i "$OUT/$preset.avi" -c:v libx264 -crf 26 -preset slow -pix_fmt yuv420p -c:a aac -b:a 96k "$OUT/$preset.mp4"
	rm -f "$OUT/$preset.avi"
done
