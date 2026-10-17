#!/bin/bash
# His eyes and head following a marker round him (face_lab.gd --mode=gaze), as a video: a close
# view with the marker, and the game's own size (1080p, 75°, 2 m; each pixel shown 3x).
#   tools/faces/gaze_video.sh OUT.mp4 [MAN]
set -e
OUT=$1; MAN=${2:-bold_cowboy_talking}
DIR=build/faces/gaze_video; LOG=build/faces/gaze_video.log
rm -rf $DIR; mkdir -p $DIR
tools/faces/lab_run.sh $LOG --id=$MAN --mode=gaze --out=$DIR/close --fov=40 --dist=1.6 --size=720x720
tools/faces/lab_run.sh $LOG --id=$MAN --mode=gaze --out=$DIR/game --fov=75 --dist=2 --size=1920x1080
ffmpeg -y -v error -framerate 30 -i "$DIR/close/f_%05d.png" -framerate 30 -i "$DIR/game/f_%05d.png" \
  -filter_complex "[1:v]crop=240:240:840:405,scale=720:720:flags=neighbor[g];[0:v][g]hstack=inputs=2[v]" \
  -map "[v]" -c:v libx264 -pix_fmt yuv420p -crf 18 "$OUT"
echo "gaze_video: wrote $OUT"
