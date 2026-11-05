# Masonry destruction: the spec

The rules for how masonry walls crack, hole and come down, in plain English, written so another
engine can follow them. Salt Creek's Godot code is the test bench; **this file and the data in
`config/destruction/` (`materials.json`, `structures/*.json`) are the product** (Sean's lab brief, `Salt_Creek_Masonry_Destruction_Lab.pdf`
in this folder; the Salt Creek side is `docs/briefs/masonry-lab.md`).

Status: **step 1 of 8, first draft (2026-11-04)**. Every rule marked *proposed* is a first guess
for a later step to prove or change. Change a behaviour here and in the data first, then in code
(section 1, rule 1).

Contents: 1 the portability rule · 2 the model · 3 the materials · 4 a hit, two scales ·
5 big hits break joints · 6 the solver: what holds up what · 7 collapse and debris ·
8 cracks before failure · 9 determinism and saving · 10 what must never happen ·
11 open questions · 12 changes.

## 1. The portability rule

| Lives outside the engine (carries to Normandy and Unreal) | Lives in the engine (rewritten there) |
| --- | --- |
| this spec | scripts and scenes |
| `materials.json`: per-material numbers | physics bodies, joints, collision |
| `structures/*.json`: each test building as elements and what rests on what | meshes cut for the engine, shaders, particles |
| `benchmarks.md`: each test scene, its numbers and results over time | the engine's performance workarounds |
| source assets: meshes, textures, recordings | |
| the reference library (`references/`) | |

Rules for every session:

1. Change a behaviour here and in the data first, then in code.
2. No magic numbers in code: every tuning value is read from `materials.json`.
3. The solver (section 6) is plain logic over plain data: no physics engine calls, no scene
   reads, so it ports line for line to C++. The engine hands it records and gets back lists.
4. Every finished step updates `benchmarks.md`.

## 2. The model

A wall (or pier, vault, chimney) is a set of **elements** joined by **joints**.

- **Element**: one solid piece the solver reasons about: a stone, a cut block, an adobe, a clump of
  bricks (a brick each would be thousands; `materials.json` `element` says how many units make one),
  a lintel, a joist, a beam, a plate. Each has an id, a material, a box (centre, size, turn about
  the vertical), its weight (box volume x density), and the course and wythe it sits in.
- **Joint**: the mortar between two elements that touch: a **bed** joint (one on top of the other),
  a **head** joint (side by side in a course), or a **collar** joint (wythe to wythe through the
  wall). Each has its two elements, its contact area, its mortar, and a state: *bonded* (mortar
  holds), *broken* (cracked through: it still bears weight in compression and by friction, but
  holds no tension), or *gone* (one side has fallen).
- **Rests on**: an element rests on the elements under it across its bed joints, and a timber rests
  on the masonry under each bearing end. This is the support graph; a file may give it
  (`rests_on`) or leave it to be worked out from contact.
- **The ground** holds up everything in the lowest course and every footing.

What masonry is like (Heyman, *The Stone Skeleton*): no useful tension across a broken joint, far
more strength in compression than a building ever asks, and it doesn't slide while pressed. So a
wall stands or falls by **geometry** (is the weight's line inside what it bears on?) more than by
strength. The mortar's small bond is what lets a hole's edge hang ragged instead of falling clean.

## 3. The materials

`materials.json` holds five: adobe, rubble stone, cut stone, fired brick, timber in masonry (and
two mortars, lime and mud). Each masonry material gives:

| Field | Means |
| --- | --- |
| `unit` | the real piece: density (kg/m³), compression and tension (Pa), stiffness (Pa), size `[along, high, deep]` (m), `size_jitter` (share), `shape` (which pre-cut set draws it) |
| `mortar`, `joint_thickness` | which mortar (its tension, cohesion, friction, compression) and how thick the joints are |
| `wall_k` | the wall's strength in compression, `wall_k · unit^0.7 · mortar^0.3` (MPa; the Eurocode 6 form) |
| `bond`, `wall` | how it's laid (running, coursed rubble, ashlar, common bond) and its usual thickness and wythes |
| `element` | units per solver element (brick: 2 along by 4 high) |
| `small_hit` | the surface: joules a cm³ it takes to dig a crater (`j_per_cm3`, and the mortar's), the crater's deepest, chip sizes, dust, the decal |
| `big_hit` | `breaks` (joints, or units and joints), `falls_as` (units, clumps, crumbs), the landing speed that breaks a falling piece (`land_break_speed`), chunk sizes, dust |
| `arch` | the load triangle's angle, the courses of cover over it and the abutment width it needs (section 6, rule S3) |
| `never`, `dust_colour`, `sound_set`, `burns` | what must never happen, the dust's colour, which sounds, whether fire takes it |

Timber in masonry gives the timber's own numbers (the same as Salt Creek's `framing`) and how far a
timber must bear into the wall (`bearing_min`). The `solver` block holds the dials every material
shares.

## 4. A hit, two scales

Every hit has a place, a direction and an energy (a ball) or a charge and a place (a blast).

- **Small hits** (bullet, buckshot, pick, kick): **surface only**. A ball digs a crater of
  `energy / j_per_cm3` cm³ (in rubble, a ball on a joint digs the mortar at `mortar_j_per_cm3`), no
  deeper than `crater_max_depth`, throws chips of `chips` size and a puff of `dust`, and leaves the
  material's decal. It **never** breaks a joint or changes what the solver sees, so fifty balls
  never cost what one charge does. (Open: whether many craters in one spot should, one day, count
  as lost bearing; section 11.)
- **Big hits** (a charge): break joints and sometimes units (section 5), then the solver runs.

## 5. Big hits break joints

The engine says, for each element the blast reaches, the peak pressure `p` on its exposed face
(reflected, Salt Creek's blast model) and the impulse `i`. Then, proposed:

1. **The push.** Each element takes a force `F = p · A_face · blast_dynamic_factor` along the face's
   normal (into the wall from the blast's side).
2. **Joints first.** A bonded joint between elements `a` and `b` breaks when what pulls them apart
   beats what holds them:
   - out of the wall's plane: the difference in push, `|F_a − F_b|`, against
     `tension · A_joint` (the mortar's bond);
   - sliding along the joint: the same difference against `cohesion · A_joint + friction · N`
     (`N` the weight pressing the joint);
   - an element pushed out of a wall whose other side is free: its whole push against the sum of
     its bonded joints' bond and the friction on its beds (`friction · N`, N the wall over it pressing
     them; step 2: without it a stone whose mortar had all cracked flew at any push).
3. **Units crack only when pressed far harder.** A unit cracks through when its face pressure passes
   `1.33 · unit.tension · (deep / along)²` (a block bent between its joints). For rubble that is ~2
   MPa against its joints' ~0.16 MPa, so stones crack only right at the charge; adobe's units and
   joints are about as weak as each other, so adobe crumbles (the "How it should break" table). A
   cracked unit becomes chunks of `chunk_size` (pre-cut shapes, section 7).
4. **What's freed flies.** An element with no bonded joint left and a push takes off at
   `v = blast_throw_factor · i · A_face / mass`, along the face's normal (step 2: `i` from the
   far-field impulse fit is ~4x short right by a contact charge).
5. Then the solver (section 6) decides what else falls, and section 7 throws it.

## 6. The solver: what holds up what

Pure rules over the records (element boxes, weights, joints and their states, materials). Loads come
down the support graph from the top, each element carrying its own weight and what rests on it,
at the point where it rests. Then each element is checked by S1-S6; utilisation (demand ÷ what
holds it) over 1 fails.

- **S1 Bearing.** An element is held if its bed joints on standing elements are at least
  `min_bearing_share` of its bed, and the line of its load (its weight and everything on it) comes
  down inside that bearing. Utilisation: how far the line is from the bearing's middle ÷ half its
  width. Broken joints still bear.
- **S2 Bond.** An element whose load line falls outside its bearing still hangs if its bonded joints
  can hold the overturning moment: `M ≤ tension · b · d² / 6` summed over its bonded bed and head
  joints (`b`, `d` the joint's width and length). This is a corbel and a hole's ragged edge: a
  stone half over a gap hangs by its mortar while its joints are whole.
- **S3 Arching (the load triangle).** Over a gap (a run of missing bearing of width `w` in a course,
  an opening's lintel, or a lintel that has broken), masonry arches. Draw the triangle on the gap
  with sides at the material's `arch.angle_deg` (60° stone and adobe, 45° brick: BIA Technical Note
  31B, Baker 1889). The arch forms when:
  - **cover**: there are at least `arch.cover_courses` courses of standing masonry over the
    triangle's peak; and
  - **abutments**: on both sides of the gap there is standing masonry at least `arch.abutment_units`
    elements wide at the gap's top; and
  - **no slide**: each abutment's sideways thrust, `H = W_over · w / (8 · rise)` (`W_over` the
    weight above the triangle spread over the gap, `rise` its height: a shallow arch's thrust), is less than `friction · N + cohesion · A` of its
    bed joints.

  When it forms, the weight above the triangle goes sideways into the abutments (half each, at the
  triangle's foot), not down onto what's over the gap. What's inside the triangle carries only its
  own weight and what's above it inside the triangle: those elements stand or fall by S1/S2, which
  is what leaves a ragged, roughly arched hole. When it doesn't form, everything above the gap
  bears straight down; elements over the gap fall by S1/S2, the gap widens and the check runs
  again (a chain collapse, up to the wall's top).
- **S4 Sliding.** An element whose bed joint takes a sideways force (an abutment's thrust, a push)
  slides when it passes `friction · N + cohesion · A` (cohesion only while bonded).
- **S5 Crushing.** A bed joint whose stress (load ÷ bearing area) passes the wall's strength,
  `wall_k · unit.compression^0.7 · mortar.compression^0.3` (MPa), crushes: the element breaks into
  chunks and stops bearing. Piers under a load and adobe at a wall's foot are where this matters.
- **S6 Timber in masonry.** A timber (lintel, joist, beam, plate) is checked by the engine's timber
  rules (bending, its joints). Each of its ends needs at least `bearing_min` of standing masonry
  under it; one that loses it drops that end, and the timber hangs by its other bearing and its
  fixings or falls. A lintel carries the triangle's weight while the arch over it forms, else
  everything above it. A lintel that snaps makes a gap of the opening's width (S3). A roof or
  floor whose wall goes **sags first, then drops in the section over the loss**: its members lose
  their bearing one by one and the timber rules decide; the rest of the roof keeps its bearing.
- **The re-check loop.** After every joint broken or element fallen, the solver runs again on what
  the change reaches: the elements touching it, everything resting on those up the graph, and
  every arch with the change in its cover or abutments. It repeats until nothing more fails.
  That loop is what makes chain collapses. Partial collapse is the norm; a full collapse needs the
  main supports actually gone.

Every check is deterministic: elements in id order, ties broken by id.

## 7. Collapse and debris

- **Pre-cut pieces**: each element has a few chunk shapes made ahead (`unit.shape`'s set), so a
  break looks varied without cutting geometry live. A falling element is drawn as its own mesh; a
  cracked one as its chunks.
- **How it falls** (`big_hit.falls_as`): **units** (stone and cut stone: whole stones and blocks,
  ragged at the edges, few cracked); **clumps** (brick: a clump still mortared, coming apart into
  bricks when it lands faster than `land_break_speed`); **crumbs** (adobe: blocks break apart into
  dirt-like rubble and dust on landing above a low speed).
- **Landing**: a falling piece that lands faster than its `land_break_speed` breaks into its
  chunks; the engine's own rule for falling weight breaking what it lands on applies (a stone onto
  a joist).
- **Dust** comes from the material's `dust` (0 none, 1 adobe's cloud) in its `dust_colour`, at
  every break and every landing, with the material's `sound_set`.
- **Debris lifecycle**: settled rubble goes to sleep, then is merged into still geometry so it can
  stay all game; pieces smaller than `debris_min_size` become dust and a decal, never bodies. The
  cap on live debris is set in step 6 and written into `benchmarks.md`.

## 8. Cracks before failure

So the player sees a wall about to go: every check's utilisation shows. Over `crack_warn` (0.6)
a hairline crack opens along the element's joints; over `crack_wide` (0.85) a wide one with dust
trickling. Proposed: an element at `delayed_fail_from` (0.95) up to 1 fails after a delay drawn
from `delayed_fail_s` (seeded), its crack widening first: the "it's going" moment.

## 9. Determinism and saving

Seeded randomness only (a structure's seed and the element's id). The same hit on the same wall
gives the same joints broken and the same elements fallen. A save stores only the difference from
the authored structure: joints broken, elements fallen and where each piece lies, craters and
decals.

## 10. What must never happen

| Material | Never |
| --- | --- |
| Adobe | clean, sharp-edged chunks |
| Rubble stone | stones splitting into neat cubes |
| Cut stone | a dressed wall shattering like glass |
| Fired brick | every brick flying individually |
| Timber | a beam vanishing, or snapping cleanly |
| All | a whole building falling at once while its main supports stand; a hole with masonry hanging over it in mid-air with nothing under it; fifty balls bringing a wall down |

## 11. Open questions

- **Craters as lost bearing**: should many balls in one spot of adobe (soft, a hand-span deep) one
  day open a hole? (Sean's table says small hits never collapse a wall; adobe may want an exception.)
- **The blast's push** (section 5) is a static stand-in for a short pulse (`blast_dynamic_factor`);
  step 2 tunes it against the reference library.
- **Water**: mortars carry `decay_when_wet` (rain, the bucket line); nothing reads it yet.
- **Fire** in timber-in-masonry buildings (fire is out of play since 2026-10-31): later.
- Which buildings are masonry and where the reference library lives: Sean's, later. (The Baron's
  house is brick or cut stone, Italianate: #666.)

## 12. Changes

- 2026-11-04, step 1: first draft: the model, the five materials, S1-S6, the arch rule, two
  scales, the debris lifecycle.
- 2026-11-04, #666: Sean approved the materials and their first numbers, rubble stone first, the
  frame-rate targets; the Baron's house brick or cut stone.
- 2026-11-04, step 2 (#667): the expander's rules (structures/FORMAT.md "The expander"); section 5
  as built (MasonryBlast): the push on the face toward the charge, the far leaf pushed by the near
  one through their collar joints (compression: they don't open), a stone freed only when its push
  beats its bonded joints **and the friction on its beds** (friction x the wall over it pressing
  them, S4's: without it a stone whose mortar had cracked all round flew at any push);
  `blast_dynamic_factor` 1.0 -> 0.01 (one stick holes a 0.55 m rubble wall ~1.5 m wide; the
  stick count a jail wall takes is Sean's). Rule 4 as built: a freed element is thrown along the
  face's normal (spread a little, leaning up) at `blast_throw_factor` (4) x I / m (Kinney-Graham's
  impulse is a far-field fit), the far leaf first; and rule 5 waits `free_before_settle_s` (0.1 s)
  so what falls over the hole doesn't pin what's on its way out. S1 and S2 in Salt Creek's
  StructuralAnalysis; S3-S5 are step 3's.

