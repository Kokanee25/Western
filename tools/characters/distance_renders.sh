#!/bin/bash
# The distance test's renders (claude/characters-face-distance), one man, four versions of his head
# texture (as imported, mipmaps made at load, painted mips, painted mips with the value pass):
#   tools/characters/distance_renders.sh MODEL OUT CUSTOM_MIPS_DIR VALUE_MIPS_DIR
# the saloon at night (1.2, 3, 6, 10 m: the room is shorter than 20) and the street at golden hour
# (1.2, 3, 6, 10, 20 m), the game's 1280x720 and its x3 nearest. Each log has his head's place and
# size in the frame (man_head_px). ~36 runs, ~75 min under lavapipe.
MODEL=$1
OUT=$2
declare -A VAR=([asis]="" [mips]="mips" [custom]="dir:$3" [value]="dir:$4")
for v in asis mips custom value; do
    for scene in man_saloon_night man_store_golden; do
        dists="1.2 3 6 10 20"
        [ "$scene" = man_saloon_night ] && dists="1.2 3 6 10"
        for d in $dists; do
            o="$OUT/$v/${scene}_$d"
            mkdir -p "$OUT/$v"
            hv=""
            [ -n "${VAR[$v]}" ] && hv="--head-variant=${VAR[$v]}"
            timeout 1500 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- \
                --out="$o" --only=$scene --model="$MODEL" --man-dist=$d $hv --fresh > "$o.log" 2>&1
        done
    done
done
ls -R "$OUT" | grep -c png
