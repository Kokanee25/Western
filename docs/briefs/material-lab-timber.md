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
