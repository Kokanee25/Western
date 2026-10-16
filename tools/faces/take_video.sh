#!/bin/bash
# A take played on a talking man, as a video: a close view and the game's own size (1080p, 75°,
# 2 m; each screen pixel shown 3x) side by side, with the take's sound.
#   tools/faces/take_video.sh TAKE_DIR OUT.mp4 [MAN] [PERFORMER.mov]
# With the performer's own .mov, it goes alongside (scaled to the same height) to judge the sync.
# TAKE_DIR holds take.json and audio.wav (tools/faces/arkit_take.py). Frames go to TAKE_DIR/close
# and TAKE_DIR/game; the lab's log to build/faces/take_video.log.
set -e
DIR=$1; OUT=$2; MAN=${3:-bold_cowboy_talking}; SRC=$4
LOG=build/faces/take_video.log
rm -rf "$DIR/close" "$DIR/game"; mkdir -p build/faces
tools/faces/lab_run.sh $LOG --id=$MAN --mode=take --take=$DIR/take.json --out=$DIR/close --turn=-15 --fov=13 --dist=1.6 --size=720x720
tools/faces/lab_run.sh $LOG --id=$MAN --mode=take --take=$DIR/take.json --out=$DIR/game --turn=-15 --fov=75 --dist=2 --size=1920x1080
IN=(-framerate 30 -i "$DIR/close/f_%05d.png" -framerate 30 -i "$DIR/game/f_%05d.png")
FILTER="[1:v]crop=240:240:840:405,scale=720:720:flags=neighbor[g];[0:v][g]hstack=inputs=2[v]"
N=2
if [ -n "$SRC" ]; then
  IN+=(-i "$SRC")
  FILTER="[1:v]crop=240:240:840:405,scale=720:720:flags=neighbor[g];[2:v]scale=-2:720,fps=30[s];[0:v][g][s]hstack=inputs=3[v]"
  N=3
fi
MAPA=()
if [ -f "$DIR/audio.wav" ]; then
  IN+=(-i "$DIR/audio.wav"); MAPA=(-map $N:a -c:a aac -b:a 128k)
fi
ffmpeg -y -v error "${IN[@]}" -filter_complex "$FILTER" -map "[v]" "${MAPA[@]}" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -shortest "$OUT"
echo "take_video: wrote $OUT"
