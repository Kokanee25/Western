# Brief: the material lab (roadmap 1.4a; art; Sean 2026-10-21)

**Goal.** A permanent bench for the world's materials: one material at a time on a test stand
(a wall, a post and beam, a deck and steps) under the game's three lights (noon, golden hour, the
lamplit saloon), with the Character Studio's three men in front of it (`bold_cowboy_s0`,
`old_rancher_s1`, `young_drifter_s1`). The men are the style reference for every material: a
material passes when it reads as painted by the same hand as them, at the same detail per metre,
inside their range of light and colour under the same light. Wear-down (worn paths, paint gone
where hands touch, new / a year / ten years) waits for Gate A; its plan is below.

**References, in order:** the Studio men themselves (their textures and the lab's renders of them;
their source pictures aren't in the repo); `docs/concept/approved-saloon-exterior.png` and the
wood sheet (`docs/concept/wood-materials.png`) for construction and the wood language;
`material-lab-timber.md` (the Oct 14 lab: the stand's sizes, end grain, the production list).

**Baseline:** the game's woods today (`assets/textures/woods/`: the lab's C of 2026-10-15, painted
in the layered cowboy's hand on 2026-10-16), A on every sheet.

## The lab

- `src/art/material_stand.gd` (`MaterialStand`): the stand, built as boards of their real sizes
  (lap siding 150 x 20 mm at the butt, 125 to the weather; deck planks 150 x 45 with 8 mm gaps,
  30 mm past a rim joist; joists 45 x 190 on pads; posts 150 square; the beam 150 x 200 past
  them; open steps: two-board treads with a nosing, set-back risers, three stringers; studs 45 x 95
  at 400 behind the siding's open end; a corner board; siding below 1 m from the wood's `_low`).
  Every cut end is flagged for end grain and every long face carries its own place along its strip
  (texel_grid's `end_tex` and `lab_u0`, on main since the woods merge); no board takes the strip of
  the board beside it. Drawn only: no members, no collision.
- `tools/material_lab.gd`: the stand out west of town, the three men (the cowboy on the deck before
  the wall, the rancher by the open end and the post, the drifter by the steps), the three lights
  (the saloon's: its sconces' and hanging lamps' settings, made brighter as SaloonDressing makes
  the room's, one across the "room" so the men are lit from the front too). `--material=` the
  wood under test (its parts take it; the rest stay the game's), `--set=mlab_NAME` a candidate set
  (only the woods it has), the masks (each man and the parts under test, once a view), the numbers
  (`numbers.json`), `--repeats` Main Street's neighbour repeats. Views: `stand` and `gameplay`
  (always) and the part's own (`wall`, `wall_end`, `post`, `deck_ends`, `steps`); `men` for the
  reference sheet. Every view has a man in it.
- `tools/material_measure.py`: `measure` (colour against the men, detail size, the numbers),
  `sheet` (A/B per material: a row a light, its views across), `crops` (the blind critic's, a man
  and the wood in each).
- Candidate sets: `tools/textures/material_lab.json`, painted or cut by `paint_woods.py --set=NAME`
  into `assets/textures/mlab_NAME/`; `PixelArt` lays them on the world's texel grid like the game's
  woods. A set may re-cut kept paintings (`raw`, no calls), paint more boards than the game has
  (`boards`) and grade a wood into the men's range when it's cut (`grade`, no calls).
- The style sheet: `docs/concept/targets/9_studio_men.png` (`tools/textures/men_reference.py`: the
  men in the lab's noon light and patches of their own painted cloth), sent by `paint_woods.py` and
  `paint_textures.py --style=man` in place of target 8.

### Running it

```sh
godot --headless --import                                   # after a set is painted or cut
python3 tools/textures/paint_woods.py --set=NAME --cut      # a set with `raw` / `weather`: no calls
xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/material_lab.gd -- \
    --out=OUT/base --material=all                           # the baseline, with masks (~1 min a view)
xvfb-run ... -- --out=OUT/NAME --set=mlab_NAME --material=all --no-masks   # a candidate
xvfb-run ... -- --out=OUT/stair --set=mlab_studio4 --material=stair        # the oak stair
python3 tools/material_measure.py measure OUT/NAME --masks=OUT/base
python3 tools/material_measure.py sheet --a=OUT/base --b=OUT/NAME --out=SHEETS [--light=golden]
python3 tools/material_measure.py crops OUT/NAME --out=CROPS --masks=OUT/base   # for the critic
```

Paid painting runs on Actions (openrouter.ai is blocked from the workspace): People workflow,
`textures = mlab:NAME`; the set's `budget` stops it short. Renders stay out of git (`build/` or a
scratch folder); sheets and the critic's crops go in `docs/screenshots/material_lab/<date>/`.
The sets in git: studio1-5 (painted). Remade with no calls and ignored: recut256/512, fit512,
studio1_384, studio5w.

## The tests and how each is judged

| Test | Measured | Passes when |
| --- | --- | --- |
| Colour | L* and C* of the wood's pixels and of the men's, same frames, each light | the wood's 10th, 50th and 90th percentiles inside the men's 5th-95th |
| Detail (texel density) | the size of the painting's detail in mm on the thing (half its fine variance gone), the men's cloth from their textures and meshes, the wood's from its strips and density | within x1.5 of the men's |
| Grain and knots, repeats | strips used on the stand; Main Street's side-by-side pairs sharing a strip | no neighbour repeats on the stand; on the street at or under chance |
| Thickness and ends | the boards' sizes (numbers.json); end grain on every cut end (the stand's flags) | the sizes above; end grain reads in `wall_end`, `post`, `deck_ends` |
| Dirt and splash, sun-greying, weather streaks, paint wear | by eye on the sheets (A/B), the blind critic | Sean on the A/B sheet; the critic's answer |
| The same painting | the blind critic, one question a crop: "Do the man and the wood look like the same painting? What gives it away?" | the critic finds nothing in the wood that gives it away |
| Cost | draws, triangles, texture memory (with mipmaps) of the stand | inside the frame budget's render line; memory listed |

A material that passes goes into the texture factory (`assets/textures/woods/` and its
`lab.json`) with its numbers (thickness, texel size, draw calls, texture memory) and a golden
view (`material_<wood>`: the stand's part view at golden hour, a man in it), judged by Sean on its
A/B sheet and by the blind critic.

## Results

### Round 1 (2026-10-21): the baseline and the first candidates

Sheets, the critic and the stairs in `docs/screenshots/material_lab/2026-10-21/`. Paint: ~$4.44 of
Sean's $9 ($4, then $5 more): studio1 $2.11 (run 94), studio2 $1.70 (run 95), the runner and a
first dark oak $0.41 (run 96), the painted dark oak ≤$0.22 (run 98); run 97 was refused by
OpenRouter's monthly guardrail ($40.32 of $40; Sean raised it) and cost nothing.

| Set | What | Detail (mm; the men's cloth 5.5-7.1, pass 4.3-9.6) | Colour (pooled, 3 lights) |
|---|---|---|---|
| woods (C, today) | the game's | 14-34: fails every wood | fails at golden and lamplit on most; the paint itself is far lighter than the men's (median L* 52-74 against 27.5) |
| recut512 | today's paintings cut at 512 a metre (no call) | 3.7-7.9: passes all but store_boards (too fine) | as today |
| fit512 | recut512 graded to the men's lightness (no call) | as recut512 | weathered pine passes noon, fascia and floor golden; the sunlit top tenth still over the men at golden |
| studio1 / studio2 | repainted with the Studio men's sheet, 512 a metre, graded; dark trim 7 boards, framing 8, floor 10, timber 3 m, dark trim 4 m; the props | 3.3-6.3: most too fine at 512 | dark trim (studio2) passes noon and golden |
| studio1_384 | studio1's paintings cut at 384 (no call) | 5.2-7.1: passes every wood | (rendering) |

Stand cost: 37 draws whatever the set; texture memory 1.3 MB today, 18-31 MB at 512 (RGBA8 with
mipmaps, as the woods import today), about 0.56 of that at 384.

The blind critic (`critic.md`): today 4 CLOSE / 5 DIFFERENT, the 512 repaint 3 CLOSE / 6 DIFFERENT,
none SAME. The floor improved, saloon red and dark trim got worse. What gives the wood away is
photographic grain (sharp knots, grain lines, nail holes, speckle) beside men painted in broad
shapes and hard tone bands; then the wood's lightness (bleached or blown to orange-white beside
warm dark men); then edge flaws (black seam dashes on the walls, square blocks on the fascia and
steps). The detail measure (the size of the finest variance) said the 512 repaint matched; the
critic says finer grain reads more photographic. **Next round:** paint broad (few grain lines,
knots as soft shapes), darker and warmer, cut at 384; fix the seam dashes (texel_grid's
edge_shade on boards) and the mosaic blocks on the fascia and steps.

**Round 2** (studio5, $2.14): every wood repainted broad (a few close tones a board, the grain
suggested, knots soft, no nail holes or speckle), darker and warmer, from blurred boards, at 384 a
metre (`round2_boards.jpg`). Sean: "nice, but too clean". studio5w lays weathering on each clean
board when it's cut (`weather`: grime patches, dirt along the edges, bleached streaks, mud on the
low siding; no call; `round2_weathered_boards.jpg`).

Round 2's blind critic (`critic_round2.md`): **store_boards repainted read as SAME** (clean and
weathered; today's DIFFERENT), the first wood to pass; floor and dark trim CLOSE either way;
weathering per board lifts weathered pine back to CLOSE (clean round 2 DIFFERENT, patchwork); round 2
loses on timber (candy stripes), saloon red (loud swirling grain) and framing (today SAME). Today's
framing SAME. What now gives the wood away, in order: fine drawn grain and crisp knots against the
men's broad flat areas; lightness (bleached boards, blown highlights); **plank-to-plank colour jumps**
(stripes, patchwork) where the men keep one muddy palette; dirt as specks rather than big soft
stains; stair-stepped shadow edges and blocky pixels on the risers and fascia. Measures: round 2
darker and warmer (timber passes every light, dark trim noon and golden), its detail measure now
over the men's (10-12 mm): the measure can't tell broad paint from coarse cutting, so the critic
decides. Sheets: `round2_sheets/` (A today, B round 2 clean, C weathered; three lights).

**Round 3, weathering as a layer (proposed):** weathering belongs to the building, not the board:
mud splashes up from the ground across several boards, rain streaks down from the eaves and from
under nails, the sun bleaches what faces it. A painted stain sheet in the men's hand (splash,
streaks, grime, bleach; one or two calls) laid by texel_grid in the structure's own space (height
above the ground, distance below an overhang, facing the sun), on top of clean painted boards; one
more texture fetch on weathered members. The per-board `weather` is the quick stand-in.

**Nothing has passed yet**, so nothing went into the texture factory and no golden view was made;
Sean's picks on the A/B sheets decide what goes in. A passing wood's golden view will be a
`material_<wood>` view in `tools/screenshots.gd` (the stand's part view at golden hour with a man)
added in the merge that moves it into `assets/textures/woods/`.

### The hotel's oak stair (Sean, 2026-10-21)

`OakStair` (`src/art/oak_stair.gd`, `--material=stair`): 13 risers of 190 on a 270 going to a
landing, a bullnose first step round a turned newel, two turned balusters a tread, a moulded rail,
cut and wall strings cut as built (the open string dies into the newel with a level cut on the
first step: Sean saw the first version's run through the bottom step), the landing's balustrade,
a runner on brass rods, in a lobby of painted boards over an oak skirting. Two oaks: studio3 cut
with no call from the walnut painting the gun stocks use (warm, red-brown, eight boards), studio4
painted from words (darker, browner, four wide boards). Sheets `stair_ab_golden.jpg`,
`stair_walnut_*.jpg`.

## What's next, in order

1. ~~Round 2's verdict~~ (done 2026-10-21, above): store boards round 2 SAME; the rest mixed.
2. **Round 3, the weathering layer** (Sean, 2026-10-21; see Round 2 above): a stain sheet painted in
   the men's hand (mud splash, rain streaks, grime, sun-bleach; one or two calls, ~$0.22-0.44 of the
   $2.42 left of Sean's $9) laid by texel_grid in the structure's space over round 2's clean boards;
   judged on the stand against studio5 and studio5w, then the critic. From round 2's critic: the
   stains big and soft (never specks or spatter), and with them, free in the cut: each wood's boards
   graded toward one shared muddy palette (no candy stripes or patchwork), the bleached highs pulled
   down, saloon red's swirling grain calmed (a repaint of that wood alone if grading can't).
3. **Edge flaws** the critics named (round 2 adds the shadows' stair-stepped edges on the wood): the black dashes along the walls' board seams (texel_grid's
   `edge_shade` on boards) and the square blocks on the fascia and steps (mosaic on thin faces).
4. **Sean's picks.** A wood he approves moves into `assets/textures/woods/` (its `lab.json`
   entry, 384 a metre) with a `material_<wood>` golden view in `tools/screenshots.gd`, the goldens
   re-approved in the same merge, the judge and the blind critic as for any art merge; the woods
   import VRAM-compressed first (memory, below).
5. **The props and the stair.** The chair, table and barrel textures (studio2) and the oak stair's two
   oaks (studio3 walnut cut, studio4 painted) wait on Sean's pick; the stair goes into the hotel
   when the building lab builds its interior.
6. **Gameplay's half** (below): end grain and strip offsets in MemberMesh, a neighbour-aware strip
   pick, the `_low` siding, the walk as built. Listed for the gameplay lane; nothing done here.
7. **Wear-down** after Gate A (the plan at the end).

## What production needs (none of it done; the structure code is gameplay's)

Carried over from the Oct 14 notes (`material-lab-timber.md`), checked against main today:

- **End grain and strip offsets in MemberMesh** (`src/structures/member_mesh.gd`): main's
  texel_grid already draws a cut end from `<wood>_end.png` where a mesh flags it (COLOR r 1 g 0)
  and starts a long face at its own place along its strip (COLOR r 0 g 0, b = offset / 2 m), and
  the woods ship their end textures, but MemberMesh flags nothing: no cut end in the game shows end
  grain. Its boxes need the COLOR array (ends and long faces), indexed, ends as two triangles; its
  per-size cache can't share a mesh once each member has its own offset, so the offset goes into
  the batch's vertices (batches are merged per structure anyway) and a member's own mesh is made
  only when it leaves its batch. The voxel mesher must carry both, or a shot board's ends pop.
- **No neighbour repeats** (`structure.gd` 118 and 473, `facade_art.gd` 113 pick a strip by
  `hash(member_id)`): measured on Main Street (`--repeats`), dark trim's side-by-side pairs share a
  strip 60% of the time, framing 22% (two and three strips); the other woods at or below chance.
  Either more strips (art: candidate sets paint dark trim 6 and framing 8) or a pick that avoids
  the touching members' strips (gameplay's).
- **Splash under 1 m**: the woods set has `saloon_red_low` and `store_boards_low` (splashed, worn
  more) that nothing in the game uses; the fronts' siding boards below 1 m should take them
  (`facade_art.gd` / `false_front_building.gd`, whichever lays the front's boards).
- **The walk as built** (`src/structures/boardwalk.gd`): planks 45 mm (`PLANK_T` 30 mm today) and
  30 mm past a rim joist, joists on pads instead of solid sleepers, open steps (treads on
  stringers, set-back risers), as real members so each breaks, burns and is supported on its own;
  their collision boxes follow.
- **Density and memory**, if Sean approves a set at 384 (or 512) texels a metre: no code (PixelArt
  reads `lab.json`'s `texels_per_metre`), but the woods import lossless (RGBA8 in video memory):
  at 512 the stand's textures alone are 18-31 MB against 1.3 today. The woods should import
  VRAM-compressed (BPTC/S3TC, ~4x smaller; art's import settings, checked for the look in the lab)
  before a fine set goes in.
- **Furniture as members** (3.3, the breakage lab): a chair or table built of members draws from
  the woods' strips, not a 0.5 m prop tile; it wants a furniture wood in the woods set (an oak,
  painted as the woods are), one painting.
- **Goldens**: every fixed view with a board in it re-approved in the same merge as any of this.

## Wear-down: the plan (after Gate A; not built)

What it is: boards worn where people walk (the saloon's door, the bar rail, the steps' middle),
paint gone where hands touch (door edges, rail tops, a post at hitching height), and every wood
at three ages, new, a year and ten years, so a new store and an old livery read differently.

1. **Ages as sets.** Each wood painted three times from the same strips by `paint_woods.py`, an age
   in the prompt (new: fresh-sawn or fresh paint, sharp arrises; a year: today's woods; ten years:
   silvered, checked, paint mostly gone, edges rounded), into `mlab_new`, the game's, `mlab_ten`.
   Cost ~$0.22 a wood an age: ~$4.40 for ten woods' two new ages.
2. **Where it wears: data, not paint.** A wear mask per structure in member space, made from what
   the building spec already holds (`building-pipeline.md`: openings, stairs, use points) and, for
   floors, the walking graph's traffic (gameplay's town life): high by a door, in the middle of
   each tread, along the bar's foot rail. Small (a floor at 8 texels a metre), one per structure,
   not a texture per member.
3. **The shader.** texel_grid already swaps a painted board to its bare wood near its ends
   (`wear_tex`, `end_wear`); the same swap driven by the wear mask (paint gone where hands touch),
   and the floor's worn path drawn lighter and smoother with dirt kept in the gaps. One more
   texture fetch on worn members only.
4. **Age per building.** A field in the building spec (`age`: new, year, ten), picking the set;
   per-board variation inside it (a replaced board new in an old walk).
5. **The lab.** Three stands side by side, new / a year / ten, the men in front; use points on the
   stand (a door in the wall, the rail, the steps); judged as every material is; memory per age
   only for the ages a scene uses.
6. **Later, with gameplay:** wear that grows with play (traffic counted over days), the
   persistence the pillars ask for ("consequences that stay"), saved as the difference from the
   authored town.

Who: art (the paintings, the shader, the lab), gameplay (use points in the spec, the traffic, the
save). Gate: after Gate A, when the look is locked.
