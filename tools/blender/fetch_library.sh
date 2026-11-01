#!/usr/bin/env bash
# The two CC0 animation libraries (issue #529) into build/library_src/ (not kept in the repo):
# Quaternius' Universal Animation Library (UAL1, the free Standard set, as glTF: J-Ponzo's mirror of
# the itch.io download of 2025-06-10) and KayKit's Character Animations 1.1 (Rig_Medium glTF, from
# GeorgeQLe's mirror of The Complete KayKit Collection v6). The asset sites (quaternius.com,
# itch.io) are outside this network's policy; both mirrors carry the packs' CC0 licence texts.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/build/library_src"
mkdir -p "$OUT" && cd "$OUT"
if [ ! -d gltf-universal-animation-library ]; then
  git clone -q --depth 1 https://github.com/J-Ponzo/gltf-universal-animation-library.git
fi
if [ ! -d kaykit-character-animations-1.1 ]; then
  rm -rf kk_mirror
  git clone -q --depth 1 --filter=blob:none --no-checkout https://github.com/GeorgeQLe/assets-kaykit-3d-characters.git kk_mirror
  (cd kk_mirror && git sparse-checkout set --no-cone '/assets/kaykit/character-animations-1.1/Animations/gltf/Rig_Medium/*' '/LICENSES/*' && git checkout -q)
  mkdir -p kaykit-character-animations-1.1
  cp kk_mirror/assets/kaykit/character-animations-1.1/Animations/gltf/Rig_Medium/*.glb kk_mirror/LICENSES/KayKit-CC0-License.txt kaykit-character-animations-1.1/
  rm -rf kk_mirror
fi
ls "$OUT"/*
