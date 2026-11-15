#!/usr/bin/env bash
# Harlan's first-person hands (option 2, #914): MetaHuman Sean's hands cut at the wrist with his
# shirt's cuff and coat's sleeve (tools/blender/fp_arms.py), built into the git-ignored
# assets/people/private/, where HeldHand takes them (else the painted arms). MetaHuman files never go
# in this public repo (#692). Needs the private Studio checked out beside the game (or STUDIO=path)
# with its frozen sean_metahuman_s3, and the Studio's venv (bpy): its tools/setup.sh.
#   tools/characters/fetch_fp_hands.sh            # then: godot --headless --import
set -euo pipefail
cd "$(dirname "$0")/../.."
STUDIO="${STUDIO:-../saltcreek-characters}"
PY="${PY:-$HOME/.venvs/studio/bin/python}"
SRC="$STUDIO/frozen/sean_metahuman_s3/sean_metahuman_s3.glb"
[ -f "$SRC" ] || { echo "no $SRC: check out Kokanee25/saltcreek-characters beside the game" >&2; exit 1; }
mkdir -p assets/people/private build
"$PY" tools/blender/fp_arms.py --src="$SRC" --out=assets/people/private > build/fp_hands.log 2>&1 \
    || { tail -20 build/fp_hands.log >&2; exit 1; }
tail -1 build/fp_hands.log
echo "hands: assets/people/private/harlan_fp.glb; run godot --headless --import"
