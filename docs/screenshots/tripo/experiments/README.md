# The stylised stranger's crispness experiments (characters session, 2026-10-07)

Branch `claude/characters-protected-features`, from `d31f6a1` (round r10's assets). Lead: one
session; the blind critic a fresh sub-agent that sees only a packet of anonymous crops beside the
master's own crops (Sean's reference pack: `01_MASTER_full_saloon.png` and its exact crops
02–08). No paid calls (fal, Rodin, Tripo) in any of this.

Tools (all characters-owned, committed on the branch):

- `tools/characters/man_diag.gd` + `tools/screenshots.gd --man-diag=PASSES [--man-normals=DIR]
  [--man-pose=...]`: the seated man's diagnostic passes from a copy of his shader patched at run
  time (the art session's `body_skin.gdshaderinc` is read, never written). `lit` (his albedo
  grey: the light alone), `id` (each square of his texture its own colour), `wire` (his
  triangles), `fix`/`litfix` (one normal a square), `fixp`/`litfixp` (one normal and one light
  point a square), `_nmsq`/`_nmtx` (the Rodin normal map, a square's mean / texel by texel), `ns`
  (shadows off). The lamps are held at their steady energy and the man held still while the
  passes are drawn.
- `tools/blender/fit_tripo.py --cells=normals:DIR[,normal_map:PNG]`: the textures' rest normals,
  square normals, square offsets and the Rodin normal map carried into the square layout (off by
  default; the assets come out byte for byte the same with or without it).
- `tools/characters/square_split.py DIR --lit=PASS --boxes=...`: how much the light varies inside
  each square on screen.
- `tools/characters/structure_views.py`: grey Cycles renders of the Rodin head with and without
  its normal map, and of the fitted head, with crops framed on his landmarks.
- `tools/characters/critic_pack.py`: the blind critic's packet; the key kept apart.

## E0: the baseline

| | Command | Time |
|---|---|---|
| r10 shot | `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- --out=DIR --only=shot_match_saloon --model=stranger2s --fresh --no-mosaic --man-mask` | 590 s |
| r10 bake | `python3 tools/characters/head_paint.py bake --id=stranger2s` | 95 s |
| r10 fit | `~/bpyenv/bin/python tools/blender/fit_tripo.py --only=stranger2s` | 22 s |
| D2r fit | `... fit_tripo.py --only=stranger2s "--cells=face:0.0055,soft.head:0,face_front:80"` | 22 s |
| D2r shot | the r10 shot command + `"--man-pose=head:6,-13.25,0;neck:0,-0.5,0"` (his head upright for this run only; `ShotMatch` untouched) | 467 s |

- The bake and the fit rebuild r10's assets **byte for byte** in this workspace.
- The r10 shot reproduces the committed r10 render (`judge/renders/face_modelled/`) to within
  1/255 on every pixel; his outline mask is identical. `judge_man.py --dry`: committed render
  0.499, this render 0.501 (its palette clustering moves a hair on 1/255 differences).
- **Correction (found during E3):** a plain `godot --path . -s ...` run uses the editor's import
  cache (`.godot/imported/`), so after a fit changes his glb or textures the renders show the old
  ones until `godot --headless --import` is run. The first D2 render here ("D2r", judge 0.526,
  `e0/d2r_*`) was taken without it: it is r10's textures with his head upright, not D2. Re-run with
  the import (`e0/d2_reimported_*`) D2 **reproduces from its recorded command**: judge 0.521
  against 0.520 recorded, and by eye the same face as Sean's crop 09 (the same small hard squares,
  the same mottle: `e0/d2_reimported_vs_reference_09.png`, 09 / the stale render / the
  re-imported one). The E0 blind critic below judged r10 against the stale render, so it compared
  r10 with r10 upright; a second critic on r10 against the real D2 is `critic/e0b/`.
- Blind critic, r10 against the stale render (`critic/e0/critic.md`; `critic/e0_key.json`: A =
  r10, B = the stale render): A slightly ahead overall, B's squares closer to a steady grid (his
  head upright); both far off: the moustache one soft band with no philtrum, the eye whites
  sparkle specks, no ear rim or hollow, a blown collar with black holes, slanted stretched squares
  on the cheek and temple.

## E2: where his 3D form comes from

`~/bpyenv/bin/python tools/characters/structure_views.py --out=DIR --what=a,b,c --size=640
--samples=48` (Cycles CPU, 347 s for the three). `e2/structure_abc.png`: rows a (the Rodin man as
made, grey, with his normal map), b (the same without it), c (the fitted man the game draws,
grey); columns front, three-quarters, side, ear, nose, nostrils, lips, eyelids. The Rodin face
lines up on the fitted one to 0.04 mm (median; 0.06 mm at the 95th percentile) by a rigid move
and one scale: **the fit doesn't change his head's shape at all** (his head isn't cut down: 5,750
triangles, under his 10,000 budget), so a Blender "d" (fitted geometry with the map) is a; the
game's d is the normal map carried into his squares (E1's `nmsq`, `nmtx`).

| Form | Geometry | Normal map | Notes |
|---|---|---|---|
| Skull, brow ridge, cheekbones, jaw, chin | yes | wrinkles, pores | the broad planes are in the mesh |
| Nose: bridge, tip, side planes | yes, soft | crisper edges | the big form reads grey |
| Nostril openings | barely a dent | yes: the rims and the dark openings | |
| Ear: as a flap off the skull | yes (silhouette, a soft lump) | | |
| Ear: outer rim (helix), inner hollow (concha), lobe | no | yes, all of it | the mesh ear is a flat lump |
| Upper lip, lower lip, the line between | no (one smooth mound) | yes | |
| Eyelids, lid creases | no (a smooth socket) | yes | the eyes themselves are only paint |
| Moustache | a soft bulge | hair strands | its shape and dark are texture |
| Stubble, pores, crow's feet, hatband studs | no | yes | noise at our square size |

So the grey mesh can't carry the ear, the nostrils, the lips or the lids. That information is in
Rodin's normal map (and its colour map's baked shading), and today none of it reaches the game.
Also seen: dark fins (folded triangles) in Rodin's own mesh at a nostril, a mouth corner and behind
the ear, in b and c alike.

## E1: does one square take two tones of light?

`screenshots.gd ... --man-diag=id,wire,lit,litfix,litfixp,fixp,litfixp_nmsq,fixp_nmsq
--man-normals=DIR --man-zoom=4:head,4:chest` after `fit_tripo.py --only=stranger2s
"--cells=normals:DIR,normal_map:stranger2_rodin_normal.png"` (the Rodin normal map, cut from his
glb). ~80 s a pass. `square_split.py DIR --lit=PASS`: a square "splits" when its light (L*, 90th
less 10th percentile) varies by more than 2 inside it.

What it took to measure this at all:

- The passes didn't repeat at first (the same pass rendered twice differed by a mean of 14/255 on
  him): the lamps flicker (±7 %) and he breathes, so the square-id pass and the light passes no
  longer lined up and square edges read as splits. With the lamps held at their steady energy and
  him held still during the passes, a pass repeats to 0.05/255.
- In the shot his triangles are 3-4 px (their edges cover 54 % of his pixels), too fine to say
  which side of a triangle edge a tone change falls on. Zoomed 4x (`--man-zoom=4:head`: the passes
  only, the camera turned onto his head and its lens narrowed), triangles and squares separate.
- The first fix (each square's rest normal turned by the turn from the texel's rest normal, from
  the bake, to his normal there) made it worse (23 % → 29 % in the shot): that turn changed texel
  by texel. The fix kept carries each vertex's own rest normal into the shader (CUSTOM1 on a
  copy of his mesh), so the turn is the bones' turn, the same all over a square.

| 4x on his head | Squares split | Mean spread inside a square (L*) | Its tone edges on triangle edges | By chance |
|---|---|---|---|---|
| The game's light (`lit`) | 20.4 % | 2.98 | **77 %** | 48 % |
| One normal a square (`litfix`) | 14.0 % | 1.53 | 54 % | 48 % |
| One normal and one light point a square (`litfixp`) | 14.7 % | 1.60 | 50 % | 48 % |
| + the Rodin normal map, a square's mean (`litfixp_nmsq`) | 14.4 % | 1.67 | 48 % | 48 % |

| In the shot, squares split | All of him | Face | Cheek | Collar | Coat |
|---|---|---|---|---|---|
| The game's light | 23.2 % | 21.1 % | 11.6 % | 23.6 % | 25.5 % |
| One normal a square | 22.7 % | 14.9 % | 9.9 % | 16.4 % | 27.2 % |

**Confirmed for the face:** where a square takes two tones under the game's light, the line between
them is a triangle edge three times in four (chance: one in two): the light at a square's middle
is worked out from each pixel's own triangle (`tiles.gdshaderinc` `tile_light_at`, by screen
derivatives), and two triangles' guesses differ. One normal a square takes that out: the splits
left are no more on triangle edges than chance (shadow edges, the eyes' own texels, Rodin's folded
triangles at the nostril). `e1/zoom_head_compare.png`: the game's light, top left (diagonal
slivers through the cheek square, under the eyes, along the brim), one normal a square, top
right; their splits below (cyan his squares, magenta his triangles, yellow the tone edges inside
split squares). Moving the light point to the square's middle as well adds nothing over the
normal: the normal is what splits a square.

**Not the coat's trouble:** in the shot the coat doesn't improve (25.5 % → 27.2 %), and its light
alone is smooth (`e1/shot_regions_sheet.png`, second column); its slanted pieces are the texture's
squares lying slant on a sleeve seen at an angle (the projection, E6/E7), not its light.

Zoomed 4x on his chest and forearm (`--man-zoom=4:chest --man-zoom-only`, 638 s for six passes):

| 4x on his chest | Squares split | Mean spread (L*) | Tone edges on triangle edges | By chance |
|---|---|---|---|---|
| The game's light | 28.6 % | 4.19 | 76 % | 53 % |
| One normal a square | 27.9 % | 4.57 | 68 % | 53 % |
| One normal and one light point | 29.6 % | 4.93 | 65 % | 53 % |

`e1/zoom_chest_compare.png`, `e1/zoom_sleeve_id_lit_fix.png` (id, game light, fix, fix with the
point). On the coat the splits aren't the face's kind: the sleeve's squares (id) are regular,
and the splits gather at the cuff and the coat's front edge, where the cloth folds over and where
the forearm's and hand's skin weights blend (the shot pose turns his hand 22°). There the turn
from rest to posed normal really does change across a square, so the fix's one normal a square
leaves streaks of its own. Not chased further here: the coat is E7, after the grid work.

**The normal map in the squares** (`e1/zoom_head_nmsq.png`): a square's mean of the Rodin map
changes little at 7-9 mm squares; where the squares are texels (round his drawn eyes) it brings
the lids' creases. Nostrils, lips and the ear's rim are averaged away: those want drawn accents
(E3 and after), not light.

Local only: the fix lives in `man_diag.gd`'s patched copy of the art session's shader; nothing of
theirs changed. For the game it would be the art session's change to `tiles.gdshaderinc` /
`body_skin.gdshaderinc` (a square's normal from a texture, turned by the bones), with
`fit_tripo.py` writing the normals (already written, off by default).

**Blind critic, E1** (`critic/e1/critic.md`; the packet's renders all drawn in one run with the
lamps and him held still; labels in `critic/e1_key.json`: A = r10 as the game draws it, B = one
normal a square, C = one normal a square + the Rodin normal map's square mean). Ranked C, B, A,
half a point apart at most: C's cheek, nose bridge, throat and chin squares lit as single tiles
(no sliver down the nose), but a crumbly ring round the near eye; B close to A. All three far from
the master on every feature, and for reasons the light can't fix: squares slanted and stretched,
the eyes dark blobs with star glints, the moustache one band with no philtrum, the ear a wedge
with no rim, the collar a ragged cloud, the hatband soft patches. So the one-normal fix is a real
but small step (worth handing the art session for the shaders); the big gaps are E3-E6.

**Blind critic, r10 against the real D2** (`critic/e0b/critic.md`; `critic/e0b_key.json`: A = r10,
B = D2 re-imported): B (D2) ranked first for the visual language (skin, chin and hat band in fairly
regular hard square tiles near the master's size), let down by streaked brim and brow, unreadable
slit eyes and a moustache with no gap; A (r10) has the stronger readable features and 3D form but
reads "a smooth render under a light pixel filter".

## E3: the moustache and the gap under his nose

`head_paint.py bake --id=stranger2s --moustache=gap:8[,notch:8]` (`draw_moustache`, `bake.moustache`;
off unless set) draws his moustache over his texture from **his model's own outline** (seen from in
front on a 0.5 mm grid: what's darker than L* 28 under his nose, closed over 1.5 mm, opened over 1.5
mm, the pieces reaching the middle kept, holes filled, kept above his mouth's line between its
corners), solid dark with 0.3 of his own hairs' lightness; cuts a gap of skin 8 mm wide at the middle
under his nose (his cheek's skin in the nose's shadow) down to his upper lip (`notch` less: the two
masses joined below); turns what's left of his model's moustache outside it to skin; and writes
`<id>_labels.png` (1 moustache, 2 gap, 3 a 4 mm ring round them). `fit_tripo.py
--cells=labels:1` gives each square the labels reach **wholly** to the moustache (when most of it is)
or to his skin, coloured from its own kind's part (no square split along the moustache's edge).
A first try drawing a polygon from the landmarks was too small for his own moustache and left it
showing round the drawn one (`e3/moustache_drawn_flat.png`: his own, then the outline-based one,
seen flat from in front).

**Trap:** the first E3 render showed no change: Godot was still drawing the imported copies of his
old textures (see E0's correction). Every variant below is fit → `godot --headless --import` →
render (`run_variant.sh` in the session's notes: the head bake 70 s, fit 22 s, import ~60 s,
plain-light head 5 s, the shot with a held-still pass and a 4x head ~7 min).

| Variant | Squares owned | Judge (dry) |
|---|---|---|
| r10 | | 0.501 |
| Drawn, no ownership | | 0.498 |
| Drawn + owned, gap to the lip (apart) | 45 moustache, 57 mixed squares given whole, 4 mostly gap | 0.499 |
| Drawn + owned, gap 8 mm deep (joined) | 47 moustache, 2 mostly gap | 0.495 |

`e3/moustache_in_shot.png`: master / r10 / apart / joined (the saloon shot, held still);
`e3/owned_squares_debug.png` (`LABELS_DEBUG=1`: the moustache's squares magenta, the gap's green);
`e3/*_head_front.png` plain light. The judge doesn't see it (it weighs light and colour); drawing
alone and drawing + ownership look nearly alike at the shot's size, ownership a little cleaner on the
edge.

**Blind critic** (`critic/e3/critic.md`; `critic/e3_key.json`: A = joined, B = apart, C = r10):
B > A > C. A and B are identical but for the gap: in the joined one the notch is lost in the
squares (a solid dark slab), in the apart one it reads as a lit notch of skin, the reason B wins.
Against the master: B's moustache is a flat near-black cut-out with no inner squares (the master's is
a mid-dark brown in several tones), and its gap is a hard slot **left of centre**: his face's square
edges fall on his middle line, so the 8 mm gap went whole into the column left of it. Everything
else the critic marks (slanted squares, 1 px stair silhouettes, the ear, the collar, the hat band,
the eye whites, hot colour) is shared by all three and is E4-E7's.
