#!/bin/bash
# The style lab (docs/briefs/style-lab.md): the same scope rendered for each candidate, the only
# difference the look's flag. Needs the candidates' textures first:
#   python3 tools/sheet_style.py world painted real sheet
#   tools/style_lab.sh [a b c d]        (default all four; renders into build/style_lab/<cand>/)
# then python3 tools/style_lab.py boards. Lavapipe here: ~40 minutes a candidate.
cd "$(dirname "$0")/.." || exit 1
OUT=build/style_lab
CANDS="${*:-a b c d}"
G="xvfb-run -a godot --path . --rendering-driver vulkan"
for c in $CANDS; do
	case $c in
		a) F="" ;;
		b) F="--sheet-style=painted" ;;
		c) F="--sheet-style=real" ;;
		d) F="--sheet-style=sheet" ;;
		*) echo "unknown candidate $c"; exit 2 ;;
	esac
	D=$OUT/$c
	mkdir -p "$D"
	LOG=$D/run.log
	: > "$LOG"
	start=$(date +%s)
	# 1. The two men, five views and their heads, in each light.
	for L in day lamp golden; do
		timeout 900 $G -s res://tools/people_lineup.gd -- --out="$D/lineup_$L" --ids=stranger2s,kid --poses=stand --light=$L $F >> "$LOG" 2>&1
		timeout 900 $G -s res://tools/people_lineup.gd -- --out="$D/lineup_$L" --ids=stranger2s,kid --poses=stand --light=$L --head $F >> "$LOG" 2>&1
	done
	# 2. The props (chair, barrel, table and the rest of the manifest) in lamplight, far and close.
	mkdir -p "$D/props"
	timeout 900 $G -s res://tools/prop_views.gd -- "$D/props/props.png" $F >> "$LOG" 2>&1
	timeout 900 $G -s res://tools/prop_views.gd -- "$D/props/props_close.png" --close $F >> "$LOG" 2>&1
	# 3-4. The saloon corner in lamplight, the façade at golden hour, dusk and noon, the Kid in the street.
	timeout 3600 $G -s res://tools/screenshots.gd -- --out="$D/views" --fresh \
		--only=shot_match_saloon,shot_match_street,saloon_front_dusk,wall_closeup_noon,kid_street,kid_close $F >> "$LOG" 2>&1
	# The camera path: the saloon walk, half its frames.
	timeout 3600 $G --fixed-fps 30 -s res://tools/probe_walk.gd -- --out="$D/walk" --paths=walk --frames=0.5 $F >> "$LOG" 2>&1
	# The seated man's outline (tools/characters/judge_man.py) and the draw cost.
	timeout 1800 $G -s res://tools/screenshots.gd -- --out="$D/man" --fresh --only=shot_match_saloon --man-mask $F >> "$LOG" 2>&1
	timeout 1800 $G --fixed-fps 60 -s res://tools/look_cost.gd -- --frames=60 --out="$D/cost.json" $F >> "$LOG" 2>&1
	echo "candidate $c done in $(( $(date +%s) - start )) s: $(find "$D" -name '*.png' | wc -l) images" | tee -a "$LOG"
done
