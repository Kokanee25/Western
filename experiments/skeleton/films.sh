#!/bin/bash
# Before | after side by side from sk_film's frames: each shot real time (60 fps), then half speed.
# films.sh FRAMES_DIR OUT_DIR   (FRAMES_DIR holds <shot>_old/ and <shot>_new/, 0000.png...)
# The two labels: OLD_LABEL, NEW_LABEL (#696's by default).
set -e
old_label=${OLD_LABEL:-before (17 bones, stretched)}
new_label=${NEW_LABEL:-fuller skeleton, his own lengths}
src=$1; out=$2; mkdir -p "$out"
font=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
lab() { echo "drawtext=fontfile=$font:text='$1':x=16:y=16:fontsize=26:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=6"; }
for d in "$src"/*_old; do
  name=$(basename "$d" _old)
  [ -d "$src/${name}_new" ] || continue
  n=$(ls "$d" | wc -l)
  [ "$n" -gt 4 ] || continue   # stills go on the sheet
  ffmpeg -loglevel error -y -framerate 60 -i "$d/%04d.png" -framerate 60 -i "$src/${name}_new/%04d.png" \
    -filter_complex "[0]$(lab "$old_label")[a];[1]$(lab "$new_label")[b];[a][b]hstack,split[r][s];[s]setpts=2*PTS,drawtext=fontfile=$font:text='half speed':x=(w-tw)/2:y=h-48:fontsize=26:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=6[h];[r][h]concat=n=2:v=1,scale=1280:-2,format=yuv420p" \
    -r 60 -c:v libx264 -crf 22 "$out/$name.mp4"
  echo "$out/$name.mp4"
done
