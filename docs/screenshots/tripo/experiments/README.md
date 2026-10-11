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

**Centring his face's grid** (`fit_tripo.py --cells=labels:1,face_centre:1`: his face's columns laid
so one is centred on his face's middle line, a regular grid in his own space, not the shot's) put the
gap under the middle of his nose as one column (`e3/centred_in_shot.png`: master / apart / apart
centred / apart centred with inner tones, `keep:1,dark:40/27/19`). **Blind critic**
(`critic/e3b/critic.md`; `critic/e3b_key.json`: A = centred + tones, B = centred, C = apart, not
centred): **C first**, B and A behind and alike. Shifting his face's grid half a square changes every
face square, not just the gap (38 % of the moustache crop's pixels), and the critic found the
original phase's cheek, chin and collar squares bolder and more even; the centred gap read as "a pale
bar cut through the moustache, too tall and too evenly bright", the original's as a narrower sliver.
The inner tones didn't read at all (still "a flat near-black silhouette"): `keep` of his own hairs'
lightness is lost when each square takes its middle colour.

**E3 so far:**
- Drawing his moustache from his own outline, with a gap under his nose to his lip, is a clear win
  over r10 by both critics: two crisp masses with drooping ends, the lower lip readable under them.
- Owning whole squares by label adds little over drawing alone at the shot's size (the squares'
  middle colour already takes the majority).
- A gap joined below (a notch) vanished in 7 mm squares; a full-depth gap reads, but too tall and
  too even: the master's is a small notch where the halves meet. A notch that survives needs finer
  squares there: the regular sub-grid the plan allows next.
- Centring the grid isn't a win: the grid's phase changes his whole face as much as the gap.
- Still missing against the master: inner tones in the moustache (squares of several dark browns),
  and the nostrils (two dark squares).

**Tones and nostrils** (`--moustache=gap:8,tones:8,nostrils:1,dark:34/23/16`: 8 L* of smooth noise
7 mm across on him, about a square, so neighbouring squares differ; two dark ellipses 7 mm across
under his nose between its wings and its middle, on what faces down or forward;
`e3/tones_in_shot.png`: master / r10 / apart / apart + tones + nostrils). **Blind critic**
(`critic/e3c/critic.md`; A = apart, B = + tones and nostrils): **B, narrowly**: a near-black block
under his nose's wing reads as a nostril, but it is fused into the top of the moustache (no skin
between). Measured by the critic, the moustache's dark pixels average L* 18 (A) and 20 (B), the
master's 29, with visible square-to-square tones: ours is too dark and too flat still. The gap
reads as a hole two to three squares wide down to the lip, not the master's small notch.

Next for the moustache: lighter (L* ~29 in the shot) with bolder tones; its top a little lower so
skin shows between it and the nostrils; the notch needs squares finer than 7 mm there (a regular
sub-grid), since a 7 mm square can only show a gap as a whole column.

## E4: the collar

A: `head_paint.py bake --id=stranger2s --collar=from:stranger2_rodin` (`model_collar`, written
2026-10-07 and never used: his shirt and neckerchief round his collar from his Rodin model's own
colours, the shirt toned to the painter's cream: 30,602 texels, L* 76 → 71, b* 9 → 13), fitted as
r10. B: A + `fit_tripo.py --cells=collar:0.0055` (his collar and shirt front in 5.5 mm squares).
`e4/collar_plain_light.png` (r10 / A / B, plain light: the painter's black smears in the white collar
gone in A, a clean cream collar either side of a black neckerchief), `e4/collar_in_shot.png` (master /
r10 / A / B). Judge (dry): A 0.500, B 0.505 (r10 0.501).

**Blind critic** (`critic/e4/critic.md`; `critic/e4_key.json`: A = r10, B = collar from his model, C
= + 5.5 mm collar squares): **B first**, C a close second (the same picture but for a few more stray
specks at the collar's lower left), A (r10) last: its collar "a blown-out scatter of white and pink
shards with black chips", its neckerchief "shattered into black islands". B's collar is "a ragged
cream ribbon with saw-tooth edges", its neckerchief "soft blurred blobs, not a shaped knot", the neck
under the chin "the most regular grid of blocks in any render here"; no collar points, no shadow
under them. Finer collar squares don't help at the shot's size.

**Lighter, a short notch, a regular sub-grid** (`--moustache=gap:7,notch:7,top:0,tones:10,
nostrils:1,dark:65/45/33`, his head at 8 texels a square so it can be halved; fitted
`labels:1,head_texels:8` and `labels:1,labels_sub:1,head_texels:8`: `labels_sub` cuts each square the
moustache or gap only partly covers into four regular half squares, each owned whole; 57 squares
cut). `e3/refined_in_shot.png` (master / tones + nostrils / lighter + notch / + sub-grid),
`e3/refined_plain_light.png`. **Blind critic** (`critic/e3d/critic.md`; A = + sub-grid, B = the dark
moustache with tones and nostrils and the full-depth gap, C = lighter + notch): **B first** ("the only
moustache with readable masses, philtrum gap and nostrils", still flat black and its gap too tall),
C second (the right brown and squared, but the notch and edges too soft to read: the 7 mm notch
was lost, no square mostly gap), **A last**: half squares made the moustache "a blurred smear with
stray skin squares in it". So the regular sub-grid doesn't buy a notch: at the shot's size 3.5 mm
squares read as softness, not drawing. The master's small notch can't be drawn finer than its own
squares; a gap one whole square wide is what reads.

**E3 verdict:** the moustache drawn from his own outline, dark, with tones at the squares' size, two
nostrils and a gap one square wide under his nose down to his lip (`--moustache=gap:8,tones:8,
nostrils:1,dark:34/23/16`), owned square by square (`--cells=labels:1`), on his ordinary 7 mm grid.

C: a restrained contact shadow (`--collar=from:stranger2_rodin,accent:0.45[,accent_mm:10]`: what
isn't his shirt within that of it on him darkened in linear light by up to 45 %, eased out with the
distance; 4 mm: 981 texels, 10 mm: 4,366). `e4/contact_shadow_plain_light.png` (none / 4 mm / 10
mm). At 4 mm it is narrower than one of his 9 mm squares and the square's middle colour takes it
out. Judge (dry): 0.500 / 0.500 / 0.495. **Blind critic** (`critic/e4c/critic.md`; A = 10 mm, B =
none, C = 4 mm): **A first**, narrowly: "its slightly deeper shadow between neck and collar separates
the two a little better, though there is still no crisp edge"; the three are otherwise the same
picture.

**E4 verdict:** his collar from his model's own colours (a clear win over r10), with a contact shadow
a square wide (a small one); finer collar squares, no. What's still wrong is the collar's shape, not
its squares or shading: the master's collar is two crisp cream points with a dark wedge under each
and one black neckerchief knot; ours is a ragged cream ribbon with no points and a neckerchief of
dark islands (the Rodin model's own collar is turned down flat). That is geometry or drawn shape,
not the bake's colour.

## E5: the winners as his defaults

`tools/characters/characters.json` `stranger2s.bake`: `"moustache": {"gap": 8, "tones": 8,
"nostrils": 1, "dark": [34, 23, 16]}`, `"collar": {"from": "stranger2_rodin", "accent": 0.45,
"accent_mm": 10}`; `assets/people/people.json` `stranger2s.cells`: `"labels": 1`. Rebuilt with
`python3 tools/characters/head_paint.py bake --id=stranger2s`,
`~/bpyenv/bin/python tools/blender/fit_tripo.py --only=stranger2s`, `godot --headless --import`
(his glb and report unchanged: only his head, skin and colour textures and the new
`stranger2s_labels.png`). Everything new is off for any other man. Character judge round
`2026-10-11_r1`: 0.495 (r10 0.499). `e5/face_master_r10_e5.png` (master / r10 / E5, the shot held
still), `e5/head_*.png` (plain light), `e5/pose_check.png` (stand, sit, hands up, crouch: no tears;
the coat's sheets under his raised arms are his mesh, as before).

## E6: the squares' grid and projection

`tools/characters/square_shape.py DIR` measures each square seen whole on screen in the id pass
(`--man-diag=id`): its aspect (long side over short, 1 a square), its tilt off the screen's rows
(0-45 degrees) and its size. `fit_tripo.py --cells=planes:18|26` (`_plane_set`): a triangle may go on
the twelve planes half way between his body's axes (18) and the eight corners (26) as well as the
six, so a surface turned between two axes is laid on a plane nearer its own. All on the E5 defaults;
`e6/*_shape.json`.

| Medians (p90) | Face aspect | Face tilt | Cheek tilt | Hat aspect | Hat tilt | Islands, head / body |
|---|---|---|---|---|---|---|
| 6 planes (E5) | 1.56 (3.78) | 18.6° (34.8°) | 17.9° | 2.25 | 19.2° | 102 / 251 |
| 6 planes, his head held upright (diagnostic only, `--man-pose`) | 1.64 (3.96) | 12.6° (36.2°) | 9.8° | 2.37 | 9.8° | 102 / 251 |
| 18 planes | 1.60 (3.77) | 18.1° (34.6°) | 18.0° | 2.12 | 17.9° | 266 / 809 |
| 26 planes | 1.59 (3.72) | 18.4° (33.6°) | 18.0° | 1.95 | 18.3° | 363 / 1,183 |

`e6/square_ids_face.png` (6 planes / head upright / 26 planes) shows why: **the squares on his face
are already in regular rows**; in the shot they slant with his head (the pose rolls it ~13°: held
upright, the tilt on his cheek halves, 17.9° → 9.8°, and on the hat 19° → 10°), and the long thin
pieces that make up the irregularity the critics see are squares **seen nearly edge-on**: the
brim, the sides of his face by the ear, his neck, the coat's shoulder and lapel. That is
foreshortening, inherent to squares fixed to his surfaces, and more planes can't change it (they
only triple the islands and seams). In character space the grid is as regular as it gets; what's
left is the shot's head roll (`ShotMatch.FITS`, the art session's: an upright head would halve the
slant on his face) and the edge-on surfaces (only screen-space squares avoid those, and the
paintings' look is not a screen filter: DESIGN.md §4, Sean 2026-10-06).
