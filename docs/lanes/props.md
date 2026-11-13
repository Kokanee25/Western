# Prop lab: current state

Branch `claude/prop-lab-…` or `claude/props-…`; brief `docs/briefs/prop-lab.md`. May edit art's `src/props/`
and `assets/props/` (say so in each commit); members, fire or blast code go to gameplay. Replace your lines
here at the end of a session; no history. Keep under ~10 KB. History to 2026-11-11:
`docs/status/current-state-2026-11-11.md` "Prop lab".

## How props are made
- Every prop is in `docs/PARTS.md` "Props". The kit: `assets/props/kit/`, `PropKit`/`KitProp`/`GlassProp`/
  `LooseProp`, `PropContents` (barrels that hold and leak).
- The factory's recipe (`docs/briefs/prop-factory.md` "The recipe brought up to date"): woods from the
  material library (`lib:` looks), metal the gun way (`pbr:`, `tools/blender/props/metal.py`), CC0 scans for
  natural things, Rodin pay-per-call for soft hero props, each prop checked against a period reference and
  judged blind in its room (`experiments/prop_lab/doctor/dress.gd`).

## Open
- **Saloon B's batch S1 is made and judged, not placed** (#866): hanging lamps (plain and shaded: hooked,
  they swing and fall with their joist), shot glass, schooner, decanter, the bartender's work board, the box
  stove (its coals spill lit), faro table and lookout stool, piano stool, wheel of fortune, gold scales, till,
  slat mat, deck and chips, and the bar's brass arm rail. `tools/props/saloon.py`, `tools/blender/props/
  saloon_s1.py`; judged on the lab's stand (`experiments/prop_lab/saloon/s1_sheet.py`, results
  `experiments/prop_lab/results/2026-11-13_saloon_s1/`). Where each goes in saloon B and its physics bodies:
  `experiments/prop_lab/README.md` "Saloon B, batch S1" (~215 bodies for the whole set as listed).
- **Next:** batch S2 (#879: the wheel, lookout stool and till redone first; then the brief's rest of the twelve: the wall bench, handsaw, fiddle and bow, beer keg and
  rack, beds and washstand sets, the owner's desk, the cookstove), then the placing session once #865's
  body fix and #862's route land.
- The doctor's office is furnished (D1-D3 merged); his coat and bookcase wait on Sean's pick (#871). The
  Studio's branch `claude/studio-doctor-bag` is unmerged: Sean's OK needed.
- Parked until after the slice: the Concord-bodied coach (#787; `tools/props/coach.py`, the boxy
  `baron_coach` stays), farmhouse props (#540).

## Traps
- A lavapipe view ~10-15 min; never two renders at once; Blender bakes share the CPU.
- Never two renders, or a render and the suite, at once. A same-kind member thinner than 12 mm isn't "on" the
  one under it (CONTACT_EPSILON). The valley has no StaticBatch (glass props draw part by part).
- A hung cloth needs `hang_over` (a bar slips between points).
- `model_paint` refuses a StandardMaterial3D; Rodin props need mipmapped paints.
- Every kit member is a physics body standing: put small things on a prop as its `dress`, give hollow
  members `"solid"` (the share that's material) or their weight is the box's.
- The dev bridge already has `stand` (the player): the lab's stand is `prop_stand`. The old factory sheet's
  spot before the saloon has a tied horse in view; the S1 stand is on the road east (40, 0, -5.4).
- A repeated member's mesh draw isn't renumbered: lay meshed members out one by one.
