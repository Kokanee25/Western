#!/bin/sh
# The CMU motion-capture clips the walk and run experiment uses, into build/cmu/ (never into git).
# Source: B. Hahne's 2010 BVH conversion of the CMU Graphics Lab Motion Capture Database
# (mocap.cs.cmu.edu), as mirrored at github.com/una-dinosauria/cmu-mocap (mocap.cs.cmu.edu itself
# isn't reachable from the cloud workspace). Index of clips: cmu-mocap-index-text.txt there.
set -e
cd "$(dirname "$0")/../.."
mkdir -p build/cmu
for c in 07_01 35_17 "$@"; do
	s=${c%%_*}
	curl -sSf -o "build/cmu/$c.bvh" "https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/0$s/$c.bvh"
	echo "build/cmu/$c.bvh"
done
