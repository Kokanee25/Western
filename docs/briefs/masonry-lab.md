# The masonry lab: stone, brick and adobe that crack, hole and come down

**Goal** (Sean, 2026-11-04, `docs/destruction/Salt_Creek_Masonry_Destruction_Lab.pdf`): stone
walls that crack, hole and collapse believably in Salt Creek (a dynamite jailbreak, the bank, the
powder magazine, a stone bridge pier under the train, the Baron's house in the finale), with the
rules and numbers written so Normandy 1944 starts from them. Godot is the bench; the rules in
`docs/destruction/` are the product.

The engine-neutral part is `docs/destruction/` (the spec, `benchmarks.md`, `references/`) and its
data in `config/destruction/` (`materials.json`, `structures/`: there because `docs/` is
`.gdignore`d and an exported game couldn't read it; Sean's brief suggested `docs/destruction/`). This file is the Salt Creek side: how the lab sits on what the
game already has, the steps, how each is judged, and the traps.

## Lane and where the work goes

Structures and blast are gameplay's files (CLAUDE.md). The lab lives in `experiments/masonry_lab/`
(its bridge commands in its own `bridge.gd`, `BridgeLab`), as the other labs. What it proves is
**promoted** into `src/structures/` with a `docs/PARTS.md` row. Whether it's its own session or the
explosions coordinator's is Sean's (below). It doesn't block the farmhouse mission or the
explosions work; it feeds them.

## What the game already has (use it; never build a second one)

Read `docs/LAYOUT.md` "src/structures" and "src/blast" before step 2.

| The spec asks for | The game has | So the lab |
| --- | --- | --- |
| elements and what rests on what | `Structure` + `StructureMember` (boxes with ids, kinds, a `wood`, support tiers and bands, `infer_supports`) | makes each stone, block, adobe or brick clump a member (wood = the material id; `stone` exists in `TimberTuning`), new kinds for masonry units |
| a solver with no engine physics, portable to C++ | `StructuralAnalysis`: pure rules over `LoadRecord`s, runs on a worker, incremental (`begin_update`, `mark_dirty`), deterministic (id order) | **extends it** with the masonry checks (spec S1-S5) and the arch rule (S3) as a pass over each wall's courses; S6 is its timber rules as they are |
| a hit breaks joints in its radius | `Blast` (Kinney-Graham, reflected pressure, `gather`, `detonate`; timber by impulse energy against bending) | adds joints as data on a masonry structure and a masonry branch in `detonate` (spec section 5) fed by `Blast`'s own pressure and impulse |
| small hits only mark the surface | `Ballistics` + voxel carving (`VoxelMember`; `stone` carves at 150 J/cm³ in `config/voxel_damage.tres`); ricochet off stone; `impact_stone` sounds | small hits on masonry are the existing carving and chips, at each material's `j_per_cm3`, and never mark a member dirty for the analysis |
| pre-cut pieces | `Structure.cut_member` and `_make_chunks`; `SpawnQueue` | per-material chunk sets made ahead (step 2 decides: Blender stones or code-made hulls) |
| settle, sleep, merge into still geometry | `RubbleRest` (20 m cells), `RubbleSleep`, rubble's contact reports (#626) | measures them on masonry rubble (step 6) and sets the debris cap |
| dust and sound by material | `BlastCloud.dust_of`, `BlastSounds` (Sean's dynamite, #605), `GameAudio` | adds the materials' dust colours and sound sets (step 7) |
| buildings from data | the building spec (`experiments/building_lab/FORMAT.md`: the saloon, the farmhouse; `foundation`/`pier` already `stone`) | reads `structures/*.json` for the lab's pieces; the jail and the bank later as building specs with masonry walls that expand to the same elements |
| craters, ground | `Ground`, `Blast.crater` | unchanged |

The trestle's stone piers (`src/train/trestle.gd`, #623) and the well's ring stones
(`src/structures/well.gd`) are masonry members already: the lab's rules apply to them when they're
promoted.

Numbers: the spec's rule is "no magic numbers in GDScript, read `materials.json`" (`config/destruction/`). The game's own
convention is `config/*.tres`; for this lab the JSON is the source (Sean's portability rule), read
by a small loader in `src/structures/`, and a test holds `timber_in_masonry` to `TimberTuning`'s
`framing`.

## The steps (one session each; each ends with its result and the next step's issue)

| Step | Done when | Judged by |
| --- | --- | --- |
| 1. The spec and data skeleton | Sean has read the spec and approved the material list | his word on the `waiting on Sean` issue |
| 2. One rubble-stone wall panel (test piece 1): stones and mortar joints, hits break joints | a charge at the base blows a ragged hole and the stone above it falls | film and stills; the "never" column; benchmarks row |
| 3. The solver (S1-S6, the arch rule) | a hole low in the wall drops what's above it; a hole with stone arching over it stays | headless tests (each rule a test), the panel films |
| 4. All five materials on the panel | side-by-side clips of all five, Sean approves | Sean; a blind critic against the reference library |
| 5. Two scales of damage | 50 rifle hits pockmark a wall without collapsing it; one charge breaches it | test + film; benchmarks "wall stress" |
| 6. Debris lifecycle | rubble from three breaches still there after a full in-game day, no frame-rate drop | benchmarks "persistence" (Sean's F3 on Shadow) |
| 7. Dust and sound by material | Sean can tell the material by ear with eyes closed | Sean's ears, blind |
| 8. The jail (rubble stone, timber roof) | passes the jail benchmark, Sean has played the breach | benchmarks "jail breach", "street test"; Sean's play |

After step 8: the bank, the powder magazine, the bridge pier and the Baron's house, each its own
step, in the order the missions need them.

## Decided (Sean's brief)

- The lab runs inside this repo, in Godot, beside the other labs.
- Period-correct masonry only: adobe, rubble stone, cut stone, fired brick, timber in masonry. No
  reinforced concrete (an 1882 anachronism; Normandy's bunkers are the Unreal phase's).
- Rules and numbers live outside Godot code so they carry to Normandy 1944.
- The finale: after the train is destroyed, the player raids the Baron's barricaded masonry house,
  blows open a wall and arrests him. His house is the lab's last and toughest test piece.

## Waiting on Sean (the step 1 issue)

1. The material list and its first numbers (`materials.json`; the spec's sections 3 and 5).
2. Proposed: rubble stone first; the frame-rate targets (`benchmarks.md`); the Baron's house brick
   or cut stone (Italianate) or a thick-walled hacienda; a separate destruction-lab session or the
   explosions coordinator's.
3. Open: which Salt Creek buildings are masonry beyond the jail and bank (today every building in
   `config/town.json` is timber, the jail and the bank included); where the reference library
   lives (`docs/destruction/references/README.md` proposes the private Studio repo); fire in
   timber-in-masonry buildings later (fire is out of play).

## Traps (for step 2 on)

- Member count: a 4 x 3 m panel is ~300 stones, ~550 adobes, ~70 blocks or ~315 brick clumps
  (`materials.json` `element`). The jail's walls are ~2,000+ members: members at rest are batched,
  but `infer_supports` grows as n² without the building lab's broadphase (its README, item 2).
- The current analysis brings load straight down; masonry over a hole needs the sideways route
  (S3), or every hole drops the wall above it to the top.
- `TimberTuning.stone`'s bending (1.5 MPa) is a whole-member stand-in; a mortared joint holds far
  less in tension (~0.08 MPa). Don't let the stone members fail by the timber bending check.
- The game asks `wood == &"stone"` in many places (fireproof in `FireTuning`, `Ballistics`' surface
  and ricochet, `BlastCloud`, the voxels' stone carving, `ImpactEffects`): new material ids
  (`rubble_stone`, `adobe`...) need one shared "is masonry" test there, not five copies of a check.
- Compare runs alternately on this VM, never two games at once; a `-s` script can't build a
  structure (autoloads): probe through a test or the bridge.
