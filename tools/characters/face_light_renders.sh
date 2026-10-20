#!/bin/bash
# The renders for the head's sheet in three lights (claude/characters-whole-man-face), one man:
#   tools/characters/face_light_renders.sh MODEL OUT
# art_lab.gd's neutral light and the warm light made to his portraits, front, three-quarter and side
# (turns 0, -45, 80; a long lens, head and shoulders), and the saloon at night (screenshots.gd
# man_saloon_night, him 1.6 m from the camera, turned the same). Logs to OUT/*.log; ~25 min.
MODEL=$1
OUT=$2
mkdir -p "$OUT"
timeout 1200 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/art_lab.gd -- \
    --out="$OUT/lab" --id="$MODEL" --turns=0,-45,80 --lights=neutral,warm --materials=game --fov=22 > "$OUT/lab.log" 2>&1
for t in 0 -45 80; do
    timeout 1500 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- \
        --out="$OUT/saloon_$t" --only=man_saloon_night --model="$MODEL" --man-dist=1.6 --man-turn=$t --fresh \
        > "$OUT/saloon_$t.log" 2>&1
done
ls -R "$OUT" | grep png
