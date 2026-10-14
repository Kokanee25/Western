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
