#!/usr/bin/env bash
# Harlan's first-person arms (#890): the Character Studio's MetaHuman arms file into the git-ignored
# assets/people/private/, where HeldHand takes it (else the painted arms). MetaHuman files never go in
# this public repo (#692). Needs the private Studio checked out beside the game (or STUDIO=path).
#   tools/characters/fetch_arms.sh [build]      # default harlan_arms_s1
set -euo pipefail
cd "$(dirname "$0")/../.."
STUDIO="${STUDIO:-../saltcreek-characters}"
BUILD="${1:-harlan_arms_s1}"
SRC="$STUDIO/frozen/$BUILD/harlan_arms.glb"
[ -f "$SRC" ] || { echo "no $SRC: check out Kokanee25/saltcreek-characters (its branch with $BUILD) beside the game" >&2; exit 1; }
mkdir -p assets/people/private
cp "$SRC" assets/people/private/harlan_arms.glb
echo "arms: $SRC -> assets/people/private/harlan_arms.glb; run godot --headless --import"
