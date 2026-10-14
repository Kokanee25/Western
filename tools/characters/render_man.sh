#!/bin/bash
# tools/characters/render_man.sh MAN DIR: his build, the import, his renders at his portraits' turns
# (distance_lab.gd, 1.2 m) and in the saloon (shot_match_saloon, shot_match_close), his 3x sheet.
M=$1; D=$2
~/bpyenv/bin/python tools/characters/rodin_portrait.py build --man=$M > build/rp_build_$M.log 2>&1
godot --headless --import > build/import.log 2>&1
rm -rf $D && mkdir -p $D/dist $D/shots
T=$(python3 tools/characters/rodin_sheet.py --turns --man=$M | tail -1)
timeout 1500 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/distance_lab.gd -- --out=$D/dist --ids=${M}_rodin --distances=1.2 --turns=$T > $D/dist.log 2>&1
timeout 2700 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- --out=$D/shots --only=shot_match_saloon,shot_match_close --model=${M}_rodin > $D/shots.log 2>&1
~/bpyenv/bin/python tools/characters/rodin_sheet.py --man=$M --dist=$D/dist --shots=$D/shots --out=docs/screenshots/portrait/${M}_rodin_sheet.png > $D/sheet.log 2>&1
echo DONE $M
