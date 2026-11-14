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
# the banjo's reference (measured against, never shipped): Uncle Dave Macon, "Papa's Billie Goat"
# (Vocalion, 1924; US recordings of 1924 public domain since 2025), from the Archive's file server
if [ ! -s "$B/ref/macon_goat.flac" ]; then
  curl -fsSL -o "$B/ref/macon_goat.flac" \
    "https://dn801308.us.archive.org/0/items/78_papas-billie-goat_uncle-dave-macon-macon_gbia0237943b/PAPA%27S%20BILLIE%20GOAT%20-%20Uncle%20Dave%20Macon%20-%20Macon.flac"
fi
# the harmonica's reference (measured against, never shipped): Jenkins and Jenkins, "Mouth Organ
# Blues" (3 October 1924; US recordings of 1924 public domain since 2025); needs dn601306.us.archive.org
if [ ! -s "$B/ref/jenkins_mouth_organ.flac" ]; then
  curl -fsSL -o "$B/ref/jenkins_mouth_organ.flac" \
    "https://dn601306.us.archive.org/0/items/JenkinsAndJenkinsMouthOrganBlues1924/Jenkins_and_Jenkins-Mouth_Organ_Blues-1924.flac"
fi
# the piano's references (measured against, never shipped): Zez Confrey, "Kitten on the Keys" (1921),
# and Jelly Roll Morton, "35th Street Blues" (1924; a 1944 reissue, de-noised, cut at 5 kHz); US
# recordings of 1921 and 1924 public domain; need dn801309 and dn801304.us.archive.org
if [ ! -s "$B/ref/confrey_kitten.flac" ]; then
  curl -fsSL -o "$B/ref/confrey_kitten.flac" \
    "https://dn801309.us.archive.org/0/items/78_kitten-on-the-keys_zez-confrey-zez-confrey_gbia0566187a/KITTEN%20ON%20THE%20KEYS%20-%20ZEZ%20CONFREY%20-%20Zez%20Confrey.flac"
fi
if [ ! -s "$B/ref/morton_35th.flac" ]; then
  curl -fsSL -o "$B/ref/morton_35th.flac" "https://dn801304.us.archive.org/0/items/35th-street-blues/35th%20Street%20Blues.flac"
fi
if [ ! -d "$B/vsco/repo/.git" ]; then
  GIT_LFS_SKIP_SMUDGE=1 git clone -q --filter=blob:none --no-checkout https://github.com/sgossner/VSCO-2-CE "$B/vsco/repo"
fi
git -C "$B/vsco/repo" config gc.auto 0
git -C "$B/vsco/repo" checkout -q 440300901dfe9275fd84e0b7763af1f8443ae62e -- LICENSE Readme.txt \
  "Strings/Solo Violin/Arco Vib" "Strings/Solo Violin/spic"
# the travelling band's real instruments (#822: band_samples.py), into build/sound_lab/cornet/vsco
C=build/sound_lab/cornet/vsco
if [ ! -d "$C/.git" ]; then
  mkdir -p build/sound_lab/cornet
  GIT_LFS_SKIP_SMUDGE=1 git clone -q --filter=blob:none --no-checkout https://github.com/sgossner/VSCO-2-CE "$C"
fi
git -C "$C" config gc.auto 0
git -C "$C" checkout -q 440300901dfe9275fd84e0b7763af1f8443ae62e -- LICENSE Readme.txt "Brass/Trumpet/sus" "Brass/Trumpet/stac" \
  $(git -C "$C" ls-tree -r --name-only 440300901dfe9275fd84e0b7763af1f8443ae62e Percussion | grep -E "^Percussion/(BDrumNewhit|Snare2-)")
mkdir -p "$B/vsco/Strings"
ln -sfn "$(pwd)/$B/vsco/repo/Strings/Solo Violin" "$B/vsco/Strings/Solo Violin"
echo "fetched: $B/ref/sallie_gooden.flac, $B/vsco/Strings/Solo Violin"
