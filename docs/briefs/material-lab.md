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

(Filled in as the rounds run; the measures in `docs/screenshots/material_lab/<round>/measure.md`.)

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
- **Density**, if Sean approves a set at 256 texels a metre: no code (PixelArt reads `lab.json`'s
  `texels_per_metre`); the woods' texture memory about x4 (see Results).
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
