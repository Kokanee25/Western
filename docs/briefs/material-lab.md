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
studio1_384, studio5w, studio6, studio6p, studio7, studio8, studio8t (round 5 with no stains: copy studio8
and drop its `weathering`), studio9, studio10, studio11 and the memory test's studio10_384, _384c, _256c, _192c (`--cut`; their stain sheets in `assets/textures/weather/`, 9 on
re-made by the cut and ignored). Sean's pick sheet: `material_measure.py pick --cands=A:DIR,B:DIR2 --out=F.jpg`.

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

**Round 3** (2026-10-21, $0.60 of the $0.90 Sean approved for two takes; sets studio6 and studio6p,
cut from studio5's paintings with no call): three things, judged on the stand against studio5 and
studio5w (sheets `round3_sheets/`: A studio5, B studio5w, C studio6, D studio6p, three lights).
- **The weathering layer** (texel_grid `weathered`, one fetch): a stain sheet of four masks (mud
  splash, rain streaks, grime, sun-bleach) laid in the structure's own space where a board's mesh
  carries its frame (MaterialStand: ground, drip line, amount; the siding's nails), so a splash runs
  up across several boards from the deck, streaks hang from the wall's top and the planks' edge,
  rust drips under one nail in four, grime gathers low and toward the ends, the bleach is on what
  faces the sky; each board takes them a touch differently (3b, after the first critic pass called
  the stepped tones "tide marks" and the stains "stamped"). studio6 uses the free stand-in sheet
  (`stain_sheet.py --procedural`, `round3_stains_studio6.jpg`); studio6p the painted one: takes a
  and b (run 106, $0.38) edited the men's sheet instead of painting panels (the men holding a
  board up) and are unused; take c (run 107, $0.22) painted onto four blank grey panels with the
  men's cloth swatches as the style gave good mud and bleach (big soft shapes) but dots for streaks
  and spatter for grime, so those two are the stand-in's (`round3_stains_studio6p.jpg`).
- **Grading in the cut** (free; `round3_boards.jpg`): each wood's boards pulled toward the wood's
  median (`unify` 0.7, lightness 0.6; timber and weathered pine 0.85), bands along the grain toward
  the board's (`rows`: the cream streak down a red board), the top fifth's lightness compressed
  (`highs`), fine detail calmed (`calm`, saloon red most). Saloon red needed no repaint.
- **Edges**: the black dashes along the walls' seams were the strips' outer rows (the painting's
  seam wavering past the cut: `seams` fills them from the row inside) and the laps' undersides, a
  real strip under a pixel tall above eye level, rasterised in segments; on the lab's sets the
  seams are drawn at least a pixel wide and a lap's butt as a dark line (`edge_aa`), which takes
  them in. The square blocks on the fascia and risers were today's 128-a-metre woods seen close:
  at 384 they're gone. The shadows' stair-steps are the light's (the sun's hard 4096 shadow map,
  stepping the men's sleeves too), not the material's: left alone (production list).

The blind critic (`critic_round3.md`, 32 crops): round 2 clean 0 SAME / 4 CLOSE / 4 DIFFERENT,
round 2 per board 0 / 3 / 5, **round 3 free sheet 2 / 5 / 1, round 3 painted sheet 1 / 6 / 1**.
Saloon red and timber go from DIFFERENT to CLOSE, weathered pine to SAME (free) and CLOSE
(painted), the store boards stay SAME; framing (free) and dark trim (painted) are the one
DIFFERENT each. Its top three now: board-to-board stripes and bleached boards (all round 2's
crops); **the weathering reads as light, not dirt** (pale soft blobs, worst on the lower wall and
the framing view; the men's stains are darker than their cloth); fine photographic detail (crisp
knots and cracks, a sandy speckle on the dark trim post). Measures (L* and C* inside the men's
range, 24 wood-and-light cells): studio5 9, studio5w 10, studio6 12, studio6p 12; the detail
measure as round 2. Stand cost unchanged (49 draws, 876 triangles); the sheet adds 1.4 MB a set.

**Round 4** (2026-10-21, free; set studio7, round 3's studio6 changed; sheets `round4_sheets/`: A
studio5, B studio6, C studio7): the stains darker than the board (`weathering.multiply`: mud
multiplies the board down, grime stronger), bleach only on what faces the sky (`bleach_walls` 0),
dark trim's speckle and timber's cracks calmed in the cut (`calm`), less sheen (`specular` 0.08).
The blind critic (`critic_round4.md`, 24 crops): round 2 clean 0 SAME / 2 CLOSE / 6 DIFFERENT,
round 3 1 / 6 / 1, **round 4 1 / 7 / 0: no wood DIFFERENT** (saloon red DIFFERENT -> CLOSE; the
deck SAME). The colour measure: 13 of 24 cells (round 3 12, round 2 9). What's left: "pale cloud
stains" on the low wall at golden hour, which are the low siding's own paler cream boards showing
between the mud (figure and ground swapped: at noon the mud reads as dark dirt shapes); fine
photographic grain and knots on posts and beams; dark stains on beam ends and step faces read as
airbrushed blots; the wood brighter and more orange than the men at golden hour (the dark decks
match).

**Round 5** (2026-10-21, free; set studio8, round 4's changed; sheets `round5_sheets/`: A studio6,
B studio7, C studio8): the low siding graded to its wall's palette (`match`: round 4's "pale clouds"
were the low boards' paler cream between the mud), the mud capped short of covering the foot
(`weathering.mud_cover` 0.7), timber and fascia's dark blots lifted (`lows`) and their grain calmed,
every wood's chroma down 12%. The blind critic (`critic_round5.md`, 24 crops; a harsher pass than
round 4's, so compare within it): round 3 0 SAME / 7 CLOSE / 1 DIFFERENT, round 4 0 / 6 / 2,
**round 5 2 / 4 / 2** (timber and the deck SAME). Still DIFFERENT: weathered pine in every round
("photographic knotty pine": crisp concentric knots) and the fascia steps in rounds 4 and 5
(lacquered, a dark blotch like a scorch). Its new top finding: **the men's light falls in
hard-edged painted bands, the wood's in smooth gradients** (a shading difference, not the
texture); then photographic figure, pale bleach reading as glare, the steps' gloss. Colour measure
13 of 24 (round 4 13).

**Sean's pick on round 5** (2026-10-22): one sheet, `2026-10-22/pick_exterior.jpg` (a row a wood at
golden hour, A the game's today, B round 5 as the town would draw it: the boards, no stains, since
the game's members don't carry the stain frame yet). The colour measure at golden hour: today 1 of
8 woods inside the men's range, round 5 6 of 8. What he picks is promoted with
`promote_woods.py --set=studio8 --as=wood:wood,... --extra=wood:edge_aa=1,wood:specular=0.08`
(the game's names; the old strips cleared first; PixelArt gives a wood with `edge_aa` in its
lab.json entry the lab's seams, and its `specular` the lab's sheen), the goldens re-approved in
the same merge.

**Round 6** (2026-10-22, free; sets studio9 and studio10, round 5's changed; sheet
`2026-10-22/round6_sheet.jpg`: round 5, 6 and 6b with the stains, golden hour):
- **Banded light on the woods** (studio9): a set's `light_bands` draws its woods with the blocks
  light at its own count (`wood_bands` in texel_grid's blocks `light()`, 4 steps; the hole material
  keeps it), on the woods only. It barely moves a flat sunlit wall (one light, one angle): it bands
  lamp falloff and shadow edges, not what the critic reads.
- **Weathered pine's knots** (`knots` in the cut: a round dark blot and its halo blurred to a soft
  shape and lifted), its grain calmed: the critic no longer names knots on it; it read
  washed-out grey once (6b warms it).
- **The fascia** (contrast and chroma down, the dark blot lifted, `knots` on it too): still
  DIFFERENT, and what the critic names is now the geometry's (crisp bevels, hairline seams, an
  even sheen on the steps and the rim), not the paint.
- **6b** (studio10): every board's tone laid in flat steps (`poster`: broad shapes, one colour a
  step), as the men's cloth is painted.

The blind critic (`critic_round6.md`, 16 crops; `critic_round6b/`, 16 more): round 5 0 SAME / 4
CLOSE / 4 DIFFERENT, round 6 0 / 5 / 3 (the floor DIFFERENT -> CLOSE), round 6b 0 / 4 / 4 against
round 6's 0 / 4 / 4 in the same pass (the same verdict wood by wood: the flat steps changed
nothing it sees). Both passes harsher than round 5's own (2 / 4 / 2). Its first difference both
times: **the light rolls smoothly on the wood and steps on the men** (posts and steps worst). Not
the boards' edges (a hard line already) and not the bands on the light; the next step finds where
it comes from (the stand with its woods flat grey: if the roll stays it is the light, the sky's
ambient or the AO; if it goes, the paint). Then: pale washed-out siding without the men's darks;
fine streaky grain; the steps and posts as untextured CG; hot stripes and dappled stains. Colour
measure at golden hour: round 5 6 of 8 woods, rounds 6 and 6b 5 (saloon red out). Stand cost as
round 5 (49 draws; 11.4 MB of texture).

**Sean picked 6b** (2026-10-22, issue #217): studio10's woods promoted under the game's names
(`promote_woods.py`; seams a pixel wide, sheen 0.08, light in 4 steps from each wood's own
`light_bands`); floor, framing and dark trim keep their old strip counts (7, 3, 2: the game draws a
batch a strip, and 10 and 8 put the store at 43 meshes against its 32). Texture memory for the
exterior woods 4.2 -> 25.7 MB (RGBA8 with mipmaps; VRAM compression later, with a look check).

**Round 7** (2026-10-22, the probe): `mlab_flat`, studio10 with every board one flat colour (its
median) and no stains. Under golden hour every face renders flat and the light only steps between
faces (lit treads, shaded risers, the laps alternating): the game's light does not roll on a
board. What the critic reads as smoothly rolling light is the paint: the boards' soft tones and
the stains' soft blobs (the stains aren't in town; the paint is). Next: studio11, the boards'
tone in broader, fewer flat shapes (`poster` [3, 10]), judged by the critic against 6b.

**Round 7a** (2026-10-22, free; studio11 against studio10, both with the stains, golden hour, each
wood on its part's view; sheet `2026-10-22/round7a_sheet.jpg`, critic `critic_round7a.md`): the
critic 6b 0 SAME / 5 CLOSE / 3 DIFFERENT, 7a 0 / 6 / 2 (pine and dark trim up, saloon red down to
DIFFERENT as "saturated salmon, rubber-stamp blotches"): one wood net, inside a pass's spread, so
**it didn't move** and studio10 stays. In both, the rolling light is no longer its first
difference (only the steps' smooth bevels, round 7c's); first now: grain and stains read as
stamped decals, then the wood redder than the men at golden hour, crisp even seams and bevels,
hard aliased dapples and shadow edges, steps and posts as CG or blank cream. Colour at golden
hour (part views only): studio10 3 of 8 woods in the men's range, studio11 4 (saloon red in);
detail 15.9-17.7 mm -> 17.0-18.2 mm (the men 5.5-7.1).

**The memory test** (2026-10-22, free; studio10 with its stains at nought, as the game draws it,
at 384 lossless (`studio10_384`) and VRAM-compressed `studio10_384c`, `_256c`, `_192c`; saloon red,
floor, timber and fascia at golden hour; Sean's sheet `2026-10-22/memory_test_pick.jpg`, the blind
check `critic_memory.md`): **384 BC7 can't be told from lossless** in any wood (a pixel diff of at
most 4/255) at a quarter the memory (the town's exterior woods 25.7 -> 6.4 MB; the stand 10.76 ->
3.62 MB measured); 256 BC7 (2.9 MB) first softens fine streaks and knots; 192 BC7 (1.6 MB) merges
the grain into fewer patches and leaves small dark blocks in two stains. No colour shift or
banding in any. **Sean picked 384 BC7** (2026-10-23, issue #286): the game's ten exterior woods
import VRAM-compressed at high quality since (`promote_woods.py --vram=...`: each png's `.import`
edited in place, its uid kept; a later promotion keeps the wood's compression); 25.7 -> 6.4 MB.
The interior woods stay lossless.

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
`stair_walnut_*.jpg`. **Sean picked B, the painted oak** (2026-10-21), and asked for the stair for
the ragdoll session: `dark_oak` (studio4's four boards, 512 a metre) is in the game's woods set and
`stair_runner` in the factory (nothing else uses them, so no golden moves), and `OakStair.solid`
gives it collision (a box a board, the turnings by their bounds, on Layers.WORLD; `room = false`
for the stair alone). Its golden view waits for the hotel.

Worn treads (Sean, 2026-10-21: "round the edges of the stairs out ... they'd be round down from
foot traffic"): `MaterialStand._worn_box` rounds a tread's front top edge, most in the middle of
its length (where feet go) and least at its ends, and wears its top a few mm hollow there; one
long face wraps top, round and front (no seam line on the round), the ends in the worn profile's
end grain. The oak stair's nosings 10 mm at the strings to 16 mm in the middle, 2 mm down
(`NOSING_WEAR`; the runner wraps the round); the stand's outdoor steps' front boards 10 to 25 mm,
5 mm down, their back boards eased (`TREAD_WEAR`). Collision stays a box a board.

## What's next, in order

1. ~~Round 2's verdict~~ (done 2026-10-21, above): store boards round 2 SAME; the rest mixed.
2. ~~Round 3, the weathering layer~~ (done 2026-10-21, above): the layer and the grading lift every
   stripy wood to CLOSE or SAME; the stains read as light, not dirt.
3. ~~Round 4~~ (done 2026-10-21, above): no wood DIFFERENT.
   ~~Round 5~~ (done 2026-10-21, above): timber and the deck SAME.
   ~~Round 6~~ (done 2026-10-22, above): pine's knots gone; banded light and flat tone steps don't
   move the critic; Sean picked 6b, promoted. ~~Round 7~~ and ~~7a~~ (done 2026-10-22, above): the probe says
   the paint, not the light; studio11's broader shapes don't move the critic. The memory test
   made (384 BC7 looks the same at a quarter the memory), waiting on Sean. Next: 7b harder-edged
   stains (once gameplay's frame is in), 7c the steps' and posts' CG look (bevels, sheen), 7d the
   siding's darks; a palette-indexed wood (R8 index + palette) if memory matters more. **The interior stand** (Sean, 2026-10-21, his saloon picture): one dark umber
   stain for interior woodwork (the picture's timbers measure L* ~20 median, 5-10 in shadow, 35-60
   lamplit, C* ~20-30, hue ~45, one family) and a profile builder (chamfers, beads, mouldings,
   casings, raised panels, brackets, from `_worn_box`), judged under the saloon's lamps against
   crops of his picture, for the saloon session to build with.
4. **Sean's picks.** A wood he approves moves into `assets/textures/woods/` (its `lab.json`
   entry, 384 a metre) with a `material_<wood>` golden view in `tools/screenshots.gd`, the goldens
   re-approved in the same merge, the judge and the blind critic as for any art merge; the woods
   import VRAM-compressed first (memory, below).
5. **The props and the stair.** The chair, table and barrel textures (studio2) and the oak stair's two
   oaks (studio3 walnut cut, studio4 painted) wait on Sean's pick; the stair goes into the hotel
   when the building lab builds its interior.
6. **Gameplay's half** (below): end grain and strip offsets in MemberMesh, a neighbour-aware strip
   pick, the `_low` siding, the walk as built, the weathering frame on members. Listed for the
   gameplay lane; nothing done here.
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
- **The weathering layer (round 3)**: texel_grid weathers a member only where its mesh carries the
  frame, in the structure's own space: CUSTOM0 (its ground's height, the drip line above it, how
  much) and CUSTOM1 (nails: pitch along, the first, the rows' pitch, the first row), RGBA float.
  MemberMesh and the structure's batch would write them from what the building spec holds: a wall's
  ground is the walk or the street it stands on, its drip line the eave or the porch roof's edge;
  the walk's frame splashes from the street and streaks from the planks' edge; nails at the studs.
  Batches are already in the structure's space; a member's own mesh (when it leaves its batch) must
  keep its vertices in that space or its stains slide (fine once it has fallen). Each structure
  wants its own offset into the sheet (from its ID, so two fronts side by side don't wear the same
  stains): a fourth number in CUSTOM0. The voxel mesher must carry the frame too.
  Cost: one 512 x 512 RGBA sheet a set (1.4 MB with mipmaps), one more fetch and two vec4s a
  vertex on weathered members only (none elsewhere: `use_weather` off, no fetch).
- **The edge fixes**, when Sean picks a wood: `edge_aa` (seams at least a pixel wide, the lap's
  butt a dark line) is on for the lab's sets only, so the game's woods and goldens are untouched;
  the game's woods take it with the wood that moves in, and their strips re-cut with `seams` (the
  painting's dark seam remnants out of a board's outer rows). The square blocks on the fascia and
  risers were today's 128-a-metre woods seen close; at 384 they're gone with no code.
- **The shadows' stair-steps** are the light's, not the material's: the sun's shadow map (4096,
  `soft_shadow_filter_quality` 0, hard) steps every shadow edge, on the men's sleeves as on the
  wood. Softening it is a look and a cost call (with gameplay's open question on the sun's cascades).
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
