#!/usr/bin/env bash
# A private man into the game (#933): a MetaHuman the Character Studio made (#889) laid into the
# git-ignored assets/people/private/ (his model private/<build>, his lighter levels <build>_lod1..3),
# by the Studio's own lay step (its studio/routes/metahuman_game.py, PLAYBOOK §4b), from his frozen
# files in the private Studio. MetaHuman files never go in this public repo (#692's licence): they
# stay in the Studio, and only this script's copy (git-ignored) is here. Where they come from:
#   - the Studio checked out beside the game (../saltcreek-characters, or STUDIO=path), else
#   - a sparse clone of it (only what the lay needs) with STUDIO_TOKEN (read access to the Studio;
#     CI's secret, #970; never written to disk), into build/studio_fetch/.
# Without either it says so and exits 0: the game builds and runs without him (Studio men instead).
#   tools/characters/fetch_private.sh [build] [--no-import]     # default sean_metahuman_s3
set -euo pipefail
cd "$(dirname "$0")/../.."
BUILD=sean_metahuman_s3
IMPORT=1
for a in "$@"; do
    case "$a" in
        --no-import) IMPORT=0 ;;
        -*) echo "unknown option $a" >&2; exit 2 ;;
        *) BUILD="$a" ;;
    esac
done
PY="${PY:-python3}"
STUDIO="${STUDIO:-../saltcreek-characters}"
NEED=(studio config/metahuman.yaml "frozen/$BUILD")
# A frozen GLB over GitHub's 100 MB limit is in parts (<build>.glb.part0, .part1: the dressed townsman,
# #1282); the Studio's lay step joins them.
have() { [ -f "$1/frozen/$BUILD/$BUILD.glb" ] || [ -f "$1/frozen/$BUILD/$BUILD.glb.part0" ]; }
if ! have "$STUDIO"; then
    if [ -z "${STUDIO_TOKEN:-}" ]; then
        echo "fetch_private: no Studio at $STUDIO and no STUDIO_TOKEN: $BUILD not fetched (the game falls back)"
        exit 0
    fi
    STUDIO=build/studio_fetch
    rm -rf "$STUDIO"
    mkdir -p build
    # The token goes in a header for this one command, never into the clone's config.
    auth=$(printf 'x-access-token:%s' "$STUDIO_TOKEN" | base64 -w0)
    git -c http.extraheader="AUTHORIZATION: basic $auth" clone -q --depth 1 --filter=blob:none --sparse \
        https://github.com/Kokanee25/saltcreek-characters.git "$STUDIO"
    git -C "$STUDIO" sparse-checkout set --no-cone "${NEED[@]/#//}" >/dev/null
    git -C "$STUDIO" -c http.extraheader="AUTHORIZATION: basic $auth" checkout -q
    have "$STUDIO" || { echo "fetch_private: the Studio has no frozen/$BUILD" >&2; exit 1; }
fi
git check-ignore -q "assets/people/private/$BUILD.glb" \
    || { echo "assets/people/private/ isn't git-ignored: refusing (#692)" >&2; exit 1; }
STUDIO=$(cd "$STUDIO" && pwd)
mkdir -p build
PYTHONPATH="$STUDIO" "$PY" -m studio.routes.metahuman_game --build="$BUILD" --game="$PWD" --no-import \
    > build/fetch_private.log 2>&1 || { tail -20 build/fetch_private.log >&2; exit 1; }
tail -1 build/fetch_private.log
if [ "$STUDIO" = "$PWD/build/studio_fetch" ]; then rm -rf "$STUDIO"; fi
if [ "$IMPORT" = 1 ]; then
    GODOT="${GODOT:-$(command -v godot || echo "$HOME/godot/godot")}"
    "$GODOT" --headless --import > build/fetch_private_import.log 2>&1 || true
fi
test -s "assets/people/private/${BUILD}_lod1.json"
echo "fetch_private: private/$BUILD and its levels in assets/people/private/"
