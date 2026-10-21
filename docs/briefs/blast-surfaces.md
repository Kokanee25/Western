# Brief: blast damage to surfaces (Sean, 2026-10-21)

Walls, floors, roofs and the boardwalk should hole where a charge goes off, and the dirt should take
a small crater. Today the frame breaks whole members or nothing, and the ground only takes a
scorch. Gameplay lane (the rules, the geometry, saving); the art lane paints the edges and the
earth (`docs/briefs/damage-pipelines.md`, "Breakage", roadmap 4.4a). **Draft for Sean: nothing is
built yet, and the decisions at the end are his.**

## What happens today (the breakage lab, `experiments/breakage_lab/`)

A stick (0.2 kg TNT) lying on or against each surface, 2026-10-21, on main at #164:

| Surface | Opened within 1 m of the stick | Opened in all (how far out) | Blast's own rule, if its query found everything |
| --- | --- | --- | --- |
| Store front wall (lap boards), stick at its foot | nothing | nothing | 11 boards, 7.3 m², out to 6.3 m |
| Saloon floor, stick on it | 3.2 m² | 22 m² (to the edge of the 6 m scan) | 22 boards, 31 m², out to 5.9 m |
| Store roof, stick on it | nothing | 1.4 m², 3.5 m away | 29 boards, 33 m², out to 6.0 m |
| Boardwalk, stick on it | nothing | nothing | 15 planks, 6.6 m², out to 1.9 m |
| The street's dirt | no crater (a 1.3 m scorch decal, gravel thrown) | – | – |

Two faults stack:

1. **Blast doesn't find what's near it on Main Street.** `Blast.detonate` takes at most 1024
   colliders of the ~2,000 in a stick's 14.6 m reach, in the physics engine's order; on the street
   it missed every member within 1 m (`baseline/baseline.md`, "What doesn't break that should").
2. **When it does find them, a member breaks whole or not at all.** A floor board is the room's
   width (9.8 m), a lap board the wall's, a roof board the slope's run; break one and it all goes.
   So the saloon floor loses a quarter of its boards in long lumps, and the rule (above) would take
   a third of a roof slope for one stick.

## What it should do

- **A hole about the charge, not a missing board.** The boards the charge overcomes are cut away
  over the stretch where it overcomes them; the rest of each board stays nailed in, its ends ragged.
  The cut stretch goes as splinters and short pieces (the rubble is the wall: DESIGN.md §8). The
  framing behind (studs, joists, rafters) breaks only where the rule says, at the point nearest the
  charge, as now.
- **Through a floor or roof, the room below takes it**: what stood on the cut boards falls through
  (Fittings already drops what loses its support), and the hole is a way through.
- **The dirt takes a crater**: a shallow scoop under a surface charge with a lip of thrown earth and
  clods round it, the scorch over it; a stick lying in the dirt makes a small one, one buried (later)
  a bigger one. On boards there's no crater, the boards hole.
- **It stays.** Holes and craters are part of the town until someone mends or fills them, and the
  save records them as differences from the authored town (member cut at t0..t1; crater at a point,
  its size), as it will members and rubble.

## The work, in order (each step measured in the lab against the baseline)

1. **Blast finds what's near it.** The near field (where timber can break: ~3 m for a stick) queried
   on its own with no cap, the 14.6 m sphere kept for glass, people and loose things. The lab's
   first fix (`baseline/baseline.md`); small, gameplay's own files.
2. **Holes in boards.** For a board, plank or roof board the blast overcomes, the stretch it
   overcomes (Blast's own windowed rule along the member: the same USDA strengths and Kinney-Graham
   impulse, worked over hand-spans either side of the nearest point) is cut out. The member becomes
   up to two shorter members (new ids `<id>/a`, `<id>/b`, still in the support graph, still
   batched); the cut stretch flies as splinters and short pieces, thrown by the impulse it took (not
   the 25 m/s cap); the cut ends carved ragged with the existing `VoxelMember` (as a bullet hole's
   edges are). A new `Structure` operation, used by Blast and later by axes and shoves.
3. **Craters in the dirt.** For a charge on or near the ground: a crater sized by scaled distance
   (radius proportional to the cube root of the charge; the constant from the published fits, below),
   drawn as a bowl and a lip over the ground, with the scorch and the thrown clods as now. Collision:
   the lip only, the ground staying flat (decision 2). Saved as the charge's point and size.
4. **Then** the frame: a blast's two big frames (0.3–1 s here today: `Blast.detonate`, then the settle) are
   measured at each step and must end no worse than the baseline; the near-field query should cut
   it.

Brick, stone and adobe (DESIGN.md §8: "crack into chunks") wait until the town has them.

## What done looks like (the breakage lab's numbers)

| Scenario | Today | Done |
| --- | --- | --- |
| `wall_dynamite_0m` | nothing opened | a hole round the stick: opened within 1 m ≈ all opened; nothing opened past ~1.5 m |
| `floor_dynamite_0m` | 22 m², out to 3.6 m+ | the same: a hole under the stick, the boards beyond it still down |
| `roof_dynamite_0m` | 1.4 m², none within 1 m | a hole at the stick; what's under it falls into the store |
| `boardwalk_dynamite_0m` | nothing | a hole through the planks |
| `ground_dynamite_0m` | no crater | a crater within the fit's range; nothing resting in it flagged as floating |
| every blast | target often not found | found (`blast_query.left_out_within_1_2_5m` 0, 0, 0) |
| frame per blast | 0.3–1 s in two frames | no worse; same seed, same result |

The exact hole size is set when step 2 is built, from the rule and the checks below, and written
here before it's judged. Judged by the numbers, then the lab's before-and-after sheets by eye, then
the playtest agent, then Sean.

## Checks against real figures

- **Timber**: the frame's strengths are the USDA Wood Handbook's (`config/timber.tres`). The US
  Army's timber-cutting formula for an external charge (FM 5-250, "Explosives and Demolitions":
  P = D²/40, pounds of TNT for timber D inches thick) says a contact charge of a stick's weight cuts
  timber to about 4 inches: every board it touches, but not a heavy post. The cut stretch from
  step 2 should agree at contact.
- **Craters**: surface-burst crater size scales with the cube root of the charge (Ambrosini,
  Luccioni, Danesi, Riera and Rocha, "Size of craters produced by explosive charges on or above the
  ground surface", Shock Waves 12, 2002). The constant for dry, packed dirt is read from that paper
  when step 3 is built; for one stick lying on the street, expect a scoop well under a metre across
  and a few inches deep (to be confirmed from the paper, not this brief).

## Lanes

- **Gameplay**: the query, the cut, the crater's shape, collision and saving, the lab.
- **Art**: how the cut ends and splinters look (4.4a's painted insides and torn faces), the
  crater's earth and lip in the ground's look (`ground.gdshader` and the textures are art's files),
  the scorch. Until then the crater uses the ground's own material and the cuts the fresh-wood one.
- The fire seen with it (a board that catches is drawn burning along its whole length at once) is
  the fire's look (art), noted in the lab's baseline, not part of this.

## Decisions for Sean

1. **Order**: the query fix first on its own (small, merges alone), then holes, then craters, as
   above? Or craters first (they don't depend on the others)?
2. **The ground**: (a) a crater drawn and its lip solid, the ground staying flat under it (cheap;
   a body or a piece lying in the crater rests a few inches above its floor), or (b) the ground made
   a height field round town so a crater is a real dip (everything that walks, falls or rolls on the
   ground changes; costs a frame budget check and a soak). Recommendation: (a), and (b) only if the
   lab and the playtest show things floating.
3. **Where it sits on the roadmap**: a new gameplay step beside 3.3 (furniture), since both cut and
   break members the same way? (`docs/ROADMAP.md` is Sean's to change.)
4. **How big a hole one stick makes** in a plank wall is a feel number once it's built: a range for
   `config/feel_ranges.json`, set by Sean after he's seen it.

## Sources

The breakage lab's baseline and surface runs (`experiments/breakage_lab/baseline/`), DESIGN.md §8,
`src/blast/blast.gd`, `src/structures/structure.gd`, `docs/briefs/damage-pipelines.md`,
`docs/LAYOUT.md` (structures, blast), FM 5-250, Ambrosini et al. 2002.
