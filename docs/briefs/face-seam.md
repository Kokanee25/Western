# Brief: the talking face's seam (the storekeeper's forehead lines and chin holes)

Sean, 2026-10-23: "Give me a brief on the issue". Characters lane, game repo. Branch
`claude/characters-studio-miner` (the miner and the storekeeper, not merged). The face tool is
`tools/faces/talking_face.py` (its section in `docs/LAYOUT.md`, "The talking face"); the brief it
came from is `docs/briefs/face-rig.md`.

## What was seen

The storekeeper (Studio build `storekeeper_s1`: balding, clean-shaven chin under a moustache, a
receding chin) through `tools/to_game.sh` (the Studio's: talking face, then hands). His Studio
head is clean. With the talking face:

1. **Dark arcs high on his forehead**, about 3 cm above his brows, both sides.
2. **Pale dashes round his jaw and neck.**

Sean's bald head (`sean_s3_talking`) shows neither; on the haired and bearded men the same places
are under hair or beard. Renders: `build/faces/lab_storekeeper_s1_talking/` (rebuilt by the lab
command below); the Studio repo's `docs/STATUS.md` 2026-10-23.

## What was found (measured, in order)

- **Not his landmarks:** brow-to-eye 2.3 cm, eye-to-chin 12 cm, as the miner's. His chin landmark
  sits 4 cm behind his lips (the miner's level with them): a receding chin.
- **Not the patch's paint:** the patch's texels 3-7 cm above his eyes take his skin from 0.4 mm
  away (the only darker texels there are his real brows).
- **Not the strip's UVs:** the strip from his cut edge to the patch's edge takes UVs from the
  kept triangle nearest each strip triangle, extrapolated 5-25 times past it (50-160 texels across
  his texture). Clamping them inside the source triangle changed nothing on screen (not kept).
- **Not the stitch weights:** `neck_seam.py` reports 212 stitch points, worst difference 0 after.
- **The cause of the arcs, fixed:** the patch's outer edge wasn't on his skin. MakeHuman's face is
  pulled onto his only where it's near and facing alike (`PULL_NEAR`, `PULL_OUT`, `agree`); the rest
  is filled in by `laplace_fill`. On him 22 of the 28 jaw-edge points weren't pulled (median 4 mm,
  up to 27 mm, into the receding chin) and 6 of 18 forehead points sat up to 4 mm off, so the strip
  stood as a step with a shadow. **Fix (committed):** the patch's outer loop is pinned onto his
  skin before the fill (`rim` in `build`); every edge point now 0 mm. The arcs went, and most of the
  neck marks. `tests/test_face_rig.gd` passes.

## What's left: holes under his chin

A few small holes under his chin, where the jaw meets the neck: the grey background shows
through at rest; with his mouth open (`aa`) they turn black. Hidden by his head at normal viewing
angles. Two fixes so far (the Studio's rule: then report):

1. The pinned edge: shrank them.
2. Each strip triangle faced as the kept triangle beside it (instead of the centre test at his
   eyes' height): no change, so not orientation. Not kept.

**Likely next places to look** (measure first; the playbook's way):
- **Missing triangles**, not wrong ones: `zip_loops` zips his cut edge (`hole`) to the patch's
  edge (`outer`) by walking both loops; where the two loops are very unequal or fold (under a
  receding chin the patch's edge was pulled 27 mm), it may skip a span. Count strip triangles
  against both loops' lengths and render the strip alone.
- **The cut**: `cut = inside_polygon(flat(cen), poly) & (cen[:, 2] < axis[1])` on the
  cylinder about his head's axis. Under the chin the surface faces down, and the cylinder map
  folds; a triangle may be cut that the patch doesn't cover, or the patch's throat `holes` (capped
  dark) may be the black ones.
- **The patch's own throat holes**: `holes` are capped dark (`cap`); with the edge pinned, a cap
  may now sit outside the surface (the black triangles when his mouth opens).

**How to see it:** after `talking_face.py`, `hands.py` and `godot --headless --import`,
`tools/faces/lab_run.sh LOG --id=storekeeper_s1_talking --out=DIR --mode=sheet --turns=0,-40
--fov=12 --dist=1.7 --aim=0,<between his eyes and chin> --only=rest,aa`, then crop under the chin at
nearest-neighbour scale. A hole counter (background-coloured pixels inside his face's silhouette, as
the jaw-crack counter was) makes it a number.

## What done looks like

- No background or black pixels inside his face and neck silhouette at rest and in every
  expression, front and turned 40°, for the storekeeper.
- **Every talking man rebuilt with the fix and checked the same way** (the edge pin changes how
  every man's face is made). Commit only the men whose numbers changed; say which in the PR. Sean's
  OK first: it changes every man.
- `tests/test_face_rig.gd` passes; the town and body tests still pass.

## How it's judged

The hole counter at 0 on every man; Sean's eye on the storekeeper's sheet (rest, `aa`, smile,
blink, brows up, turned), close and at game distance.

## Also noticed

`miner_s4_talking.json` reports `facerig.stitch.stitch_points: 0` (the others 109-212): either his
stitch wasn't bound or the count was written over. Check it when he's rebuilt.
