#!/bin/bash
# Lines said by a talking man (face_lab.gd --mode=talk), as a video: a close view with the subtitle
# as the game shows it, and the game's own size (1080p, 75°, 2 m; each screen pixel shown 3x) side
# by side; a line with a recording (talk_audio.py's) has its sound laid where he says it.
#   tools/faces/talk_video.sh OUT.mp4 [MAN] [LINES.json] [none|mask (his bandana)]
# Frames go to build/faces/talk_video/{close,game}; the lab's log to build/faces/talk_video.log.
set -e
OUT=$1; MAN=${2:-hothead_lyle_s2_talking}; LINES=$3; BANDANA=${4:-none}
DIR=build/faces/talk_video; LOG=build/faces/talk_video.log
rm -rf "$DIR/close" "$DIR/game"; mkdir -p "$DIR"
ARGS=(--id=$MAN --mode=talk --turn=-15 --bandana=$BANDANA --aim=0,1.62)
[ -n "$LINES" ] && ARGS+=(--lines=$LINES)
tools/faces/lab_run.sh $LOG "${ARGS[@]}" --out=$DIR/close --fov=13 --dist=1.6 --size=720x720 --subtitle
tools/faces/lab_run.sh $LOG "${ARGS[@]}" --out=$DIR/game --fov=75 --dist=2 --size=1920x1080
IN=(-framerate 30 -i "$DIR/close/f_%05d.png" -framerate 30 -i "$DIR/game/f_%05d.png")
FILTER="[1:v]crop=240:240:840:405,scale=720:720:flags=neighbor[g];[0:v][g]hstack=inputs=2[v]"
# The recordings, each delayed to the frame he starts it on (beats.txt: frame, mood, text, audio).
N=2; MIX=""
while IFS=$'\t' read -r FRAME MOOD TEXT WAV; do
  if [ -n "$WAV" ]; then
    MS=$(( FRAME * 1000 / 30 ))
    IN+=(-i "$WAV"); FILTER="$FILTER;[$N:a]adelay=${MS}|${MS}[a$N]"; MIX="$MIX[a$N]"; N=$((N + 1))
  fi
done < "$DIR/close/beats.txt"
MAP=(-map "[v]")
if [ -n "$MIX" ]; then
  K=$(( N - 2 ))
  FILTER="$FILTER;${MIX}amix=inputs=$K:normalize=0[a]"
  MAP+=(-map "[a]" -c:a aac -b:a 128k)
fi
ffmpeg -y -v error "${IN[@]}" -filter_complex "$FILTER" "${MAP[@]}" -c:v libx264 -pix_fmt yuv420p -crf 18 "$OUT"
echo "talk_video: wrote $OUT"
