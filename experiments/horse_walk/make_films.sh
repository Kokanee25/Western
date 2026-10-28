#!/bin/sh
# The walk's films: renders (render.py) then ffmpeg into experiments/horse_walk/films/.
# Run from the repo root; frames stay in build/horse_walk/.
set -e
B=~/bpyenv/bin/python
R=experiments/horse_walk/blender/render.py
O=experiments/horse_walk/films
mkdir -p "$O"
for kind in side threeq; do
  $B $R -- --film=$kind --strides=${STRIDES:-3} > build/horse_walk/film_$kind.log 2>&1
  ffmpeg -v error -y -framerate 30 -i build/horse_walk/film_$kind/f%03d.png -vf "scale=640:-2" \
    -c:v libx264 -pix_fmt yuv420p -crf 26 "$O/walk_$kind.mp4"
  ffmpeg -v error -y -framerate 30 -i build/horse_walk/film_$kind/f%03d.png \
    -vf "scale=480:-2:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer" \
    "$O/walk_$kind.gif"
done
ls -la "$O"
