# Brief: the material lab's timber pass (art, 2026-10-14)

**Goal** (Sean's reference pack, `docs/concept/material_pack/`): the lab's buildings read as
assembled from solid timber: deck boards as thick planks with cut end grain and gaps, posts as one
timber each with grain along it, painted siding coherent, floors calm. Grounded 3D with controlled
stylization, beside the current characters; not the old pixel paintings, not voxels or watercolour.

**References, in order:** `docs/concept/approved-saloon-exterior.png` (the style target); the
character crops in the pack; the wood sheet's wood language (`docs/concept/wood-materials.png`, not
its resolution); real lumber construction (the pack's `photo_links.md`, links only).

**Diagnosis (code):** planks are 30 mm (`Boardwalk.PLANK_T`), their ends flush behind the fascia;
`MemberMesh` maps every face along its longer side, so a plank's end shows the long grain squashed
(no end grain anywhere); posts are sharp 0.26 m boxes in a 64x8 strip at 32/m: 3 cm squares lit
flat one by one (the "camouflage"); the lab's boardwalk at 16/m jumps tone plank to plank; the lab
red was greyed and goes dark at noon.

**Changes (lab only, behind `PixelArt.lab_set = "lab2"`):** a grain painter
(`tools/textures/grain_woods.py`, `woods_lab2.json` → `assets/textures/lab2/`, 128 texels/m,
mipmapped, coherent pieces, grain and knots along the length, checks, saw marks, wear where wood
wears, an end-grain texture a wood); texel_grid's `end_tex` for faces flagged as ends (vertex
colour, set only by the lab's own meshes); the lab's geometry variant (45 mm planks reaching past
the fascia, chamfered planks and posts) built over the real members' meshes, collision untouched.

**Done looks like / judged by:** A (production) | B (new woods, today's geometry) | C (new woods and
geometry), same cameras, three lights; end-on, side-on, 3/4, gameplay and close views of deck ends
and posts, a man for scale; a walk for shimmer; the numbers (thickness, texel size, draw calls,
triangles, texture memory). Sean's eye is the gate; nothing goes to production before it.

## The finish (Sean's notes on the timber pass, 2026-10-14)

Baseline (A): lab2's woods with LabGeometry `reshape` (45 mm planks, 30 mm overhang). The finish
(B): `tools/textures/woods_lab3.json` -> `assets/textures/lab3/` (`grain_woods.py --set=lab3`) and
LabGeometry `build` (`tools/material_lab.gd --lab3 --build`). Not in the game; nothing merged.

1. Plank ends: the walk drawn as built. Its fascia becomes a rim joist (0.2 m x 45 mm) under the
   planks, so their cut ends stand 30 mm clear above it (each ±8 mm, its end up to 5 mm off
   square); joists on edge on pads instead of solid blocks; end grain darker, closer bands, a
   dark rim. New view `deck_ends`: low and close, nothing in front of them.
2. Fascia: its own wood (`fascia`: darker, greyer, weathered streaks, splash at the foot).
3. Timber: 1-3 knots a board, checks with a lighter lifted lip, patchy saw marks, long weather
   streaks and sun-greyed patches, all stepped (no per-texel noise).
4. Paint wear: no edge strip; short broken runs of worn lap edge, some nails, a flake or two along
   the grain; paint worn at board ends by the shader (`end_wear`, `<wood>_bare.png`); the boards
   below 1 m from `<wood>_low` (splashed, worn more).
5. The red: the approved exterior's sunlit siding measures L* 21-27, chroma 25-34, hue ~44; lab2's
   rendered L* 40, chroma 66. lab3's ramp: light x0.62, chroma x0.55, hue +3 (albedo only; the
   light is the game's).
6. Construction: two nails a joist on every plank (one multimesh, one draw); steps as two tread
   boards with a nosing, a riser and stringers.

Judged by A/B sheets (`tools/material_compare3.py` -> `docs/screenshots/material_lab/finish/`).

## The final candidate and production readiness (Sean's notes on the finish, 2026-10-14)

C (`--lab4 --build2`; `woods_lab4.json`, LabGeometry `build` 2) against A (the game today) and B
(the finish). Sheets and Main Street's costs in `docs/screenshots/material_lab/final/`.

- Red: lab2's colours' light x0.8, chroma x0.62 (between lab2 and lab3). Golden-hour siding
  L* 32.5, chroma 52, hue 44 (A 42/68, B 26/40, the approved exterior 21-27/25-34, hue 44).
- End grain: `end_grain2`, coherent years (wide earlywood, narrow latewood), stepped tones, no
  per-texel randomness, at 256 texels a metre (`end_texels`, its own shader density) so the arcs
  don't staircase; lab3's `end_rim` was drawn on the texture's tile edges, not the board's (part
  of the checkerboard), and is gone. Posts' and beams' rings round an off-centre heart.
- Steps: B's never changed (LabGeometry's step test never matched: kept so for B). C's are open:
  two tread boards with a 35 mm nosing, a riser set back under it, a gap at the ground, three
  stringers; treads in the deck's wood, the rest grey pine (two surfaces, drawn unbatched).
- Repetition: every member starts at its own place along its strip (0-2 m, COLOR.b; the shader's
  `lab_u0`) and on its end grain, and lab4 has 10-12 boards a wood where lab3 had 6-8: two posts
  sharing a strip no longer show the same knot at the same height. Nails jittered; ~6% of joists
  a nail short, ~8% a third.

What production needs (none of it done; the structure code is gameplay's):
- Geometry (`src/structures/boardwalk.gd`, gameplay's): the rim joist, joists on pads and the open
  steps as real members, so each breaks, burns and is supported on its own (planks on joists,
  joists on pads, the rim on the joists' ends, treads on stringers). The planks 45 mm thick and
  30 mm past the rim in their own size and place, not a drawn offset.
- Meshes (`src/structures/member_mesh.gd`, gameplay's): the end flag, the per-member strip
  offset and the chamfer in MemberMesh, indexed, ends as two triangles (four for a chamfered
  end's octagon, not the lab's eight-triangle fan); chamfer only where it shows (posts, beams,
  the walk's planks and joists; not the studs inside walls). The lab's builder is unindexed and
  chamfers every framing member: Main Street's measured mesh data 22.5 -> 89 MB, its triangles
  228k -> 393k (`MemProbe`). MemberMesh's per-size cache can't share a mesh once every member
  has its own offset: the offset goes in the batch's vertices (they're merged per structure
  anyway) and the members' own meshes are made only when a member leaves its batch (damage).
- Collision: today's boxes are the game's members; with members as built, their boxes follow
  (the rim 45 mm, not a 25 mm fascia 2 cm proud of it; joists and pads instead of solid sleepers,
  so a bullet under the deck goes through the gaps a player sees).
- Navigation: none to change: people walk the waypoint graph and the steps' invisible ramps; the
  open steps' treads stay where the blocks' tops were.
- Destruction: a carved member (voxels) is meshed from its box: chamfer, end flag and offset must
  carry into the voxel mesher or a shot post pops square. Fire and breaking need the new woods
  (`fascia`, the `_low` sidings) mapped to existing wood properties.
- Textures: lab4's woods into the texture factory's production set and WoodMaterials, with
  mipmaps; the shader's `end_tex`, `end_texels`, `wear_tex`/`end_wear`, `lab_u0` (renamed) on for
  members. ~3.3-4 MB of textures with mipmaps.
- Goldens: every fixed view with a boardwalk or a red front re-approved in the same merge; the
  judge and the blind critic as for any art merge.

Measured on Main Street (`tools/material_lab.gd --street`, five views, 30 frames each, each
variant run alone; `docs/screenshots/material_lab/final/street.md`): draw calls A -> C +18% at
noon, +21% at golden hour (B +10-11%: C's extra boards a wood are extra batches); render CPU
under lavapipe +14-20% (about ±1 ms a view run to run), ~0.4-0.6 ms at Sean's scale on the calm
street's 2.9. Triangles and mesh data: the lab builder's 228k -> 393k and 22.5 -> 89 MB; built
for production an estimated +19k triangles (+8.5%: posts 5.3k, planks 5.2k, joists and pads 3.9k,
steps 1.0k, nails as quads 4k) and ~24 MB.
