# Brief: ground that can be dug, and the crater (Sean, 2026-10-21)

Step 3 of `docs/briefs/blast-surfaces.md`: the street's flat ground becomes ground that can lose
earth in one place and gain it in another, with a blast's crater as the first thing that does it.
Sean's words on it (decision 2 there): **"not worried about when the shovel comes, just that the
ground is ready for it."** Gameplay lane (the ground's data, collision, mesh, the rules, saving, the
lab); the ground's look is the art lane's (below, "What art needs"). **Sean's decisions are in
(2026-10-22, at the end); built in the order below.**

Read for it: `blast-surfaces.md` (step 3, its decisions, "Later: digging with a shovel"), DESIGN.md
§8 (persistent rubble), §11 (the ground remembers; the parked shovel), `docs/LAYOUT.md` (src/world,
src/structures, src/blast), the breakage lab's README and baseline, and a survey of the code that
touches the ground (in the PR).

## What the ground is today

- **One flat plane.** `Ground` in `scenes/test_street.tscn`: a StaticBody3D with a
  `WorldBoundaryShape3D` (an endless plane at y 0, layer WORLD) and a 600 m `PlaneMesh` drawn with
  art's `src/world/ground.gdshader`. No metas, no groups, no physics material. No height or terrain
  code anywhere in the game or the native plugin.
- **What you see isn't what you stand on.** The shader paints the street's ruts up to ±0.12 m of
  relief (`street_rut_range`); the collision is flat.
- **A lot of code assumes the street is at y 0**: grounded members (`Structure.GROUND_EPSILON`: a
  member within 2 cm of y 0 is held by the ground for ever), Fittings (`GROUND` 0.08: anything that
  low stands on the ground and is never checked), the kit props' feet (any static body is "the
  ground: never goes"), the street waypoints and flee points (built at y 0), the smoke box's floor,
  the soak's and the chaos test's "under the ground" (y −1.5), the far dressing, grass and sagebrush
  (placed at y 0, no ray). Most of it is fine for craters inches deep and matters once holes are a
  man deep (below, "What it touches").
- **The breakage lab** (`ground_dynamite_0m` and `_1m`): no crater (depth 0), a 1.3 m scorch decal,
  gravel thrown, 4–5 panes broken in the store front.

## The choice: a height field (chosen) or ground voxels

| | Height field (chosen) | Ground voxels |
| --- | --- | --- |
| What it is | The ground's height at every cell (5 cm), in 3.2 m tiles; only tiles that have been dug hold data | The members' carving (the native plugin's `VoxelMember`) laid on the ground in chunks |
| Does | Craters, holes, graves, trenches, piles, a hole filled back in | All that, plus overhangs and tunnels |
| Can't | Overhangs, tunnels: the mine is its own thing when it comes | – |
| Collision | Jolt's height field (`HeightMapShape3D`): made for terrain, cheap contacts, no seams between triangles for a ragdoll or a rolling stick to catch on; one per dug tile | A triangle mesh per chunk (`ConcavePolygonShape3D`, as a carved member's): dearer contacts, and the seams catch rolling things |
| Drawing | One mesh a dug tile, a grid of 65×65 points; the undug ground drawn as now (below) | Meshed on the plugin's workers (as `VoxelWorks` does); the shader must texture walls and overhangs from any side (triplanar) |
| An edit | Write the cells, rebuild one tile's shape and mesh: the shape measured 0.42 ms here (0.27 at Sean's) for a 65×65 tile, the mesh in step 2 | Carve, re-mesh a chunk on a worker, swap it in a frame or more later |
| Memory | 65×65 floats a dug tile, ~17 KB; the whole town dug would be tens of MB, and it never will be | Cells in three dimensions: a 2 m deep layer at 5 cm is 160 cells a column; large even sparse |
| Save | The height each changed cell differs from the authored ground (below) | The changed voxels; larger |
| Standing ground | No dearer than the plane (below) | The same, if undug chunks stay unmade |

**Chosen: the height field** (Sean: "whatever works best"), as `blast-surfaces.md` had it. It does everything the shovel needs
(Sean's list: a scoop and its pile, many times over the same spot, things resting in and buried
under it, walked and fallen into, saved as differences, local edits). The voxels' only gain is
tunnels, and the mine's tunnels will be timbered, so they're better built as members (shoring,
lagging) round a dug space anyway, when the mine comes.

### How it's laid out

- **Dig anywhere** (Sean): the whole 600 m ground the street's plane covers. A tile is made where
  it's first dug, wherever that is.
- **Tiles of 3.2 m, cells of 5 cm** (65×65 heights a tile, the edges shared with the neighbours so
  there's no crack; Jolt rebuilds a tile's height field in 0.42 ms here, 2026-10-22, against 0.6 for
  81×81 and 2.0 for 161×161: smaller tiles keep a crater's edit, which touches up to four, cheap).
  Why 5 cm: one stick's crater is about 0.3–0.5 m across (below), 7–9 cells; at
  10 cm it'd be a pit of three to five squares. A shovel's blade is 5 cells. The ground's texels are
  2.5 cm (40 a metre), so a cell is two texels.
- **Undug ground costs what the plane costs now.** A tile holds data only once it's dug. The flat
  rest is drawn as one mesh (the ground less its dug tiles, as few big rectangles, rebuilt only when
  a tile is first dug) and collides as a handful of big flat boxes (the same rectangles, deep, the
  outer ones running on past the mesh's edge as the plane does now), or as one coarse flat height
  field with holes where tiles are dug (Jolt takes NaN heights as holes): step 1 measures both and
  keeps the cheaper. Under every dug tile the hardpan is a box too, so nothing falls out of the world. Each dug tile adds one height field and one mesh
  (one draw call; neighbouring dug tiles are merged into one mesh if the draws add up).
- **Two layers a cell**: the height of the packed, undisturbed earth, and the depth of loose earth
  lying on it (what was thrown or shovelled there). Packed earth stands steep (a grave's walls stand
  for a while); loose earth slumps to its angle of repose (~35° for dry loose earth) after every
  edit, cell by cell, over the edited patch only. The look can tell the two apart (fresh earth).
- **A floor**: the earth goes down `earth_depth`, 2 m (Sean: "enough to dig up a coffin"), then
  hardpan that a shovel won't take and a blast barely marks.
- **The authored ground** is flat at y 0 today. The height field could later carry authored shape
  (the ruts as real collision, a wash, a rise at the town's end): not part of this job, but the
  save's differences are taken from whatever the authored ground is, so it can come later.

## Earth out at one point, down at another, many times over

One small interface on the ground (`Ground`, `src/world/ground.gd`), used by the crater now and by
the shovel, graves and burying later:

- `take(at, radius, depth, shape) -> m³`: lowers the cells under a footprint (a bowl for a crater,
  a blade's scoop for a shovel), never below the floor; returns the volume taken (bank volume).
- `put(at, m³, radius)`: lays loose earth down, heaped (a pile, a lip), then lets it slump.
- `height_at(x, z)`, `loose_at(x, z)`: for anything that wants to know (feet, props, the lab).
- `Events.ground_changed(rect)`: what touched that rect re-checks itself (below).

Earth is counted: what `take` removes is what `put` lays down, swelled by `swell` (~1.25: loose earth
takes about a quarter more room than packed; a proposed number, from earthmoving tables), less what a
blast packs down instead of throwing (below). Dig the same spot ten times and it's ten edits on the
same cells: deeper each time, until the floor; fill it back in and it rises to about where it was,
heaped with loose earth by the swell, as a filled grave is. Every edit is deterministic (no draws but
the seeded clods), so the same seed gives the same ground.

## The crater

**Sized by scaled distance**, the cube root of the charge, as the blast's pressures are (Kinney and
Graham). The fit for a charge on the surface: **diameter D = 0.8 × W^(1/3)** (D in metres, W in kg of
TNT), from Kinney and Graham's regression over ~200 accidental surface explosions (spread about ±30%),
which Ambrosini, Luccioni, Danesi, Riera and Rocha's tests (Shock Waves 12, 2002) checked for charges
at ground level; a later refit over a wider range of charges gives D = 0.56 × W^(1/3). Depth about a
quarter to three tenths of the diameter (H/D 0.25–0.30, as later papers on small surface charges
quote it).

| Charge (0.2 kg TNT a stick) | D (0.8 fit) | D (0.56 fit) | Depth (H ≈ 0.25–0.3 D, 0.8 fit) |
| --- | --- | --- | --- |
| One stick lying on the dirt | 0.47 m (0.33–0.61) | 0.33 m | 12–14 cm |
| Three sticks tied together | 0.67 m | 0.47 m | 17–20 cm |
| Ten sticks (2 kg) | 1.0 m | 0.70 m | 25–30 cm |
| A crate of 50 (10 kg) | 1.7 m | 1.2 m | 43–52 cm |

This agrees with `blast-surfaces.md`'s guess ("a scoop well under a metre across and a few inches
deep"). **I couldn't read the papers themselves**: the hosts that carry them (cimec.org.ar,
famaf.unc.edu.ar, link.springer.com) are outside this workspace's network policy, so these
coefficients are as other papers quote them. They're confirmed from the papers' text before step 3
merges (Sean can allow those hosts in the environment's network settings, or a session with access
reads them). Proposed: 0.8, the depth 0.27 D, both in `config/blast.tres`, and the hole a feel range
once Sean has seen it (as `blast-surfaces.md`'s decision 4 has for the plank hole).

- **Its shape**: a bowl (the cells lowered by a smooth profile out to D/2), the lip a ring of loose
  earth peaking at about 1.25 × the crater's radius and thinning out to about twice it (the shape of
  the published crater profiles, scaled), lumpy by seeded noise so no two are the same.
- **Where the earth goes**: of the volume taken, a share is packed down into the crater's floor and
  walls rather than thrown (proposed 30%, Sean's or the paper's), the rest goes to the lip and as
  **clods**: a few dozen small bodies thrown by the blast (DEBRIS, as wood chips are), which on coming
  to rest fold back into the ground as loose earth where they lie, so the street is left with the
  crater, its lip and a scatter of earth, all of it the ground's own data (saved, dug, walked on), not
  hundreds of sleeping bodies. Gravel (`Blast`'s ejecta bullets) as now.
- **Only on dirt.** On boards the boards hole (step 2); a stick on the boardwalk doesn't crater the
  dirt under it. A stick under a boardwalk or a floor on the dirt craters the dirt (and the boards
  above take the blast as now).
- **Buried (later)**: a charge below the surface makes a bigger crater (Ambrosini et al.'s buried
  charges); `crater()` takes the charge's depth from the start, 0 for now.
- **The scorch** over it, as now, with its decal box made deep enough to reach the crater's floor.

## What rests in a hole, and what walks, falls and rolls into it

The physics does the resting and rolling once the ground has a real shape; what needs work is
everything that was told the ground is flat.

- **Waking**: a body asleep on ground that's just been lowered (a strongbox, a stick, rubble, a dead
  man) is woken by the edit (everything whose box touches the edited patch), or it'd hang in the air.
- **A stick of dynamite, a strongbox, a ragdoll** at the bottom of a hole rest on its floor and the
  walls stop them rolling out sideways: the height field does it; the lab checks it (below).
- **The player** (a CharacterBody3D, floor snap 0.3 m, slopes up to 46°) walks into and out of a
  stick's crater (its walls ~30°). A hole deeper than a step with steep walls (a grave) he falls into
  and can't climb out of: there's no climbing. Sean's call (below).
- **The men** walk by snapping to the ground under them (`HumanBody._snap_to_ground`: rays from 0.5 m
  up to 1 m down). A crater is fine. Off the edge of anything deeper than a metre the snap gives up
  and he walks on air: the snap's reach goes to the floor of the deepest hole, and a drop over a step
  (0.25 m) is a fall (the falls' work: he stumbles or goes down).
- **His feet**: a man's lower foot is put at his feet's height; on a crater's slope the other foot
  floats or sinks (the visual checks' `feet`). Foot placement on uneven ground is its own job (the
  bodies'), not this one; until then a man standing in a crater shows it.
- **Where the men go**: there's no nav mesh; ways between waypoints are judged by rays every 0.3 m
  (`Waypoints._no_step_up`: no rise or drop over 0.25 m between footfalls) and cover by the ground
  under it (`Cover._ground`). A stick's crater doesn't change a way; a hole a man deep blocks it, as it
  should. Whether a way is judged once or each time is checked in step 4: if once, a way is judged
  again when `ground_changed` touches it.
- **What stands on the ground**: a post or sill on the dirt (a grounded member), a kit prop's feet
  (the chair) and Fittings' low things all take the ground as there for ever. On `ground_changed`,
  each re-checks what's under it: a member whose foot has lost its earth (all its bottom corners over
  `undercut` above the ground, proposed 5 cm) loses the ground's support and the structure settles; a
  kit prop's foot the same. Kit props are the prop lab's files: the change there is one listener, said
  in the commit.

## Bullets, fire, smoke, blood

- **Bullets glancing off dirt**: today any static body facing up more than 45° is "ground" and
  anything steeper is "wood" (`Ballistics.surface_of`), so a ball striking a crater's or a grave's
  wall would glance as off a board. The ground carries `surface = &"ground"` so all of it glances as
  dirt (the 14° limit) and stops in it otherwise, with the dust it throws now. Holes in the ground
  from bullets aren't made (a ball's dent is below a cell).
- **Fire** never looks at the ground (only members burn); lamp oil spilled into a crater burns where
  it lands, as it does on the street. The smoke box's floor (`SmokeField`, y 0) becomes the ground's
  lowest point under it.
- **Decals** (scorch, blood pools and splats, road prints) project onto the mesh as they do now; their
  boxes are made deep enough for a crater's floor.

## Saving

There's no save yet (DESIGN.md §3: a bed), only `to_dict()`s; the ground gets its pair from the start:

- `Ground.to_dict()`: for each dug tile, its key and the cells that differ from the authored ground:
  the packed height's difference and the loose depth, in millimetres (16-bit), packed (zlib, base64);
  a stick's crater is a few hundred cells, a few hundred bytes. Plus what's buried (below). The
  scorch decals are saved with the blast's other marks, not here.
- `Ground.from_dict()`: lays them back, and a test makes sure ground saved and loaded is the same to
  the millimetre.
- **The difference, not the history**: `blast-surfaces.md` had "a crater at a point, its size". A
  list of edits grows with every scoop and replays only if every rule (slumping, clods) is unchanged;
  the heights themselves are small, final and survive rule changes. Proposed: the heights.
- **Buried things** (for later, but the data's there): `bury(id, at, depth)` records an item (a
  strongbox, bones, a cache) at a point under the surface; when an edit takes the ground down past its
  top, `Events.ground_uncovered(id, at)` hands it back. Graves are this plus a man.

## What art needs (the ground's look: `ground.gdshader`, the textures, the crater's earth and lip)

The ground's look is art's; gameplay hands it the shape and these channels, and until art's pass the
dug tiles are drawn with the ground's own material (it works from world XZ, so a dug tile meets the
flat ground with no seam).

1. **The mesh's normal**: the shader takes the road as flat ("the road is flat, so `facing` is that
   height's sine"; the relief built off straight up). A crater's walls need the mesh's own normal, with
   the ruts' relief laid on it (or faded out where the ground's been dug).
2. **The fresh earth**: each dug tile's vertices carry `COLOR` (proposed: r the loose earth's depth,
   g how freshly it was turned, b how deep below the authored ground), for the shader to paint loose,
   darker, lumpier earth on the lip and the clods, cut earth on the walls, and the packed road
   elsewhere.
3. **Steep walls** (a grave, later): the texture projected from above stretches on a near-upright
   wall; a side projection (or triplanar) where the normal's near level.
4. **The scorch** in the crater: the decal as now, or the shader's own (b above) if art prefers.
5. **The ruts**: today they're painted relief only; whether they become the authored ground's real
   shape is a question for art and Sean (it'd make the visible ruts collide), not part of this job.

Art's judge and goldens: street views with no crater should render the same before and after step 1
(the same shader on the same flat ground); `ground_dynamite_0m`'s look sheet is art's view of the
crater.

## The work, in order (one merge each, measured in the breakage lab against its baseline)

1. **The ground as tiles, still flat.** `Ground` (`src/world/ground.gd`, `GroundTuning` in
   `config/ground.tres`): the dig-able area, the undug rectangles' mesh and boxes, the far ground, the
   `surface` meta; the street's plane replaced; the lab's ground target finds it. Done when every test
   passes, the goldens of the street views are unchanged (or within their noise), the perf bench's
   calm street is no dearer (draw calls, physics), and `ground_dynamite_*` reads as its baseline.
2. **Take and put.** The cells, the two layers, slumping, a tile made dug (its height field and mesh),
   waking what's on it, `ground_changed`, `to_dict`/`from_dict`, buried things as data. Tests: earth
   counted (taken = put ÷ swell), ten scoops over one spot, a hole filled back, the floor, slumping to
   the angle, a save round trip to the millimetre, same seed same ground; the cost of an edit measured
   (target under 1 ms for a stick's crater at Sean's).
3. **The crater.** `Blast` calls `Ground.crater(at, kg, depth)` for a charge on (or just over) the
   dirt: the bowl, the lip, the packed share, the clods folding back, the scorch reaching the floor.
   Lab: `ground_dynamite_0m` and `_1m` (the scan at 2.5 cm for the ground: a 10 cm cell is a fifth of
   a stick's crater), the crater's diameter and depth within the fit's range, the lip, the blast
   frame no worse than the baseline; `run.py --look` sheet; before-and-after sheets.
4. **What's in and round a hole.** The men's snap and the fall off an edge, ways and cover across
   holes, grounded members and kit props re-checking on `ground_changed`, bullets on crater walls,
   the smoke floor, decals' depth. New lab scenarios: a stick, a strongbox and a dead man lying where
   the crater opens (each must end resting in it, nothing flagged floating or sunk); three sticks in
   a row on one spot (the crater deepens, the earth is counted); a man walking across a crater; the
   player in and out (the bridge).
5. **The frame**: the perf bench with dug ground and a blast's frame, against the budget table; an
   edit's tile rebuild moved to the native plugin only if step 2's measure says so.

## What done looks like

| Measure (the breakage lab, the tests, the bench) | Today | Done |
| --- | --- | --- |
| `ground_dynamite_0m` crater | none | 0.33–0.61 m across, 8–17 cm deep (the fit's range), a lip of loose earth round it |
| Same seed, same crater | – | to the millimetre |
| A stick, strongbox, dead man in the crater | – | resting on its floor; no piece floating or sunk (the lab's flags) |
| Three sticks on one spot | – | deeper each time, the earth counted |
| Save and load | – | the ground the same to the millimetre |
| Street goldens with no crater | – | unchanged |
| Calm street's frame (perf bench) | 6.0 ms + render | no dearer |
| A blast's frame | 0.3–1 s in two frames | no worse; the crater's edit under 1 ms at Sean's |

Judged by the numbers, then the lab's sheets and the look run by eye, then the playtest agent, then
Sean.

## Decisions (Sean, 2026-10-22)

1. **Height field or voxels**: "whatever works best or experiment with both?" The height field: it
   does all the shovel needs and is far cheaper. The one experiment that would change it is in step
   2: the same crater as a height field and as a triangle mesh (what voxels collide as), a stick, a
   strongbox and a dead man dropped in each, rest and cost compared. The mine's tunnels, when they
   come, as timbered members round a dug space.
2. **Cell size**: 5 cm (each cell is two of the ground's paint squares; a stick's crater is about
   nine cells across, a coarser 10 cm would make it a pit of four or five).
3. **Where**: anywhere (Sean): the whole ground.
4. **Depth**: 2 m of earth, then hardpan (Sean: "enough to dig up a coffin").
5. **The crater**: the 0.8 fit and 30% packed, for now (Sean: "sure"); a feel range once he's seen
   it. The papers' hosts are still blocked (2026-10-22); the numbers stay as quoted until a session
   can read them.
6. **A hole deeper than a step**: nothing for now (Sean: "dig out or climb later"): the shovel digs
   a way out, or a climb comes later.
7. **A floating foot in a crater**: accepted for now (Sean).
8. **The save keeps the heights** (Sean: "do what's best"): the ground as it is now, not the list of
   every scoop that made it, so it stays small and still loads after the rules change.

## Sources

`docs/briefs/blast-surfaces.md`; DESIGN.md §3, §8, §11; the breakage lab's baseline; the code survey
(in the PR); Kinney, G. F. and Graham, K. J., *Explosive Shocks in Air*, 2nd ed., Springer, 1985 (the
crater regression, as quoted); Ambrosini, R. D., Luccioni, B. M., Danesi, R. F., Riera, J. D. and
Rocha, M. M., "Size of craters produced by explosive charges on or above the ground surface", *Shock
Waves* 12 (2002) 69–78, and Ambrosini and Luccioni's later papers on craters from surface explosions
(as quoted; to be read in full before step 3); Glasstone and Dolan, *The Effects of Nuclear Weapons*,
ch. 6 (a surface crater's profile in dry soil: the lip's crest about a quarter of the radius beyond
the rim, depth about half the radius; its shape only, scaled).
