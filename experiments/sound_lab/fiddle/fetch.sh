#!/usr/bin/env bash
# What the fiddle experiment reads (#790), into build/sound_lab/fiddle/ (git-ignored):
# the 1922 reference record (Internet Archive; public domain in the US) and VSCO 2 CE's solo
# violin (CC0; only its two folders, at a fixed commit). Needs archive.org's file servers allowed
# (dn801308.us.archive.org) and the music21 package for nothing (the tune is in tune.py already).
set -euo pipefail
cd "$(dirname "$0")/../../.."
B=build/sound_lab/fiddle
mkdir -p "$B/ref" "$B/vsco"
if [ ! -s "$B/ref/sallie_gooden.flac" ]; then
  curl -fsSL -o "$B/ref/sallie_gooden.flac" \
    "https://archive.org/download/ACEckRobertsonSallieGoodenVictor18956/AC%20Eck%20Robertson%20-%20Sallie%20Gooden%20-%20Victor%2018956.flac"
fi
if [ ! -d "$B/vsco/repo/.git" ]; then
  GIT_LFS_SKIP_SMUDGE=1 git clone -q --filter=blob:none --no-checkout https://github.com/sgossner/VSCO-2-CE "$B/vsco/repo"
fi
git -C "$B/vsco/repo" config gc.auto 0
git -C "$B/vsco/repo" checkout -q 440300901dfe9275fd84e0b7763af1f8443ae62e -- LICENSE Readme.txt \
  "Strings/Solo Violin/Arco Vib" "Strings/Solo Violin/spic"
mkdir -p "$B/vsco/Strings"
ln -sfn "$(pwd)/$B/vsco/repo/Strings/Solo Violin" "$B/vsco/Strings/Solo Violin"
echo "fetched: $B/ref/sallie_gooden.flac, $B/vsco/Strings/Solo Violin"
