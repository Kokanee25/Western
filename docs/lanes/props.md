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
- **Saloon B's batches S1 and S2 are made and judged, not placed** (#866, #879). S1: hanging lamps (plain and
  shaded), shot glass, schooner, decanter, work board, box stove, faro table and lookout's high chair, piano
  stool, wheel of fortune (the Evans dice wheel), gold scales, till, slat mat, deck and chips, the bar's arm rail.
  S2: wall bench, handsaw, fiddle and bow, beer keg (full) and keg rack, cookstove. `tools/props/saloon.py`,
  `saloon_s2.py`; `tools/blender/props/saloon_s1.py`, `saloon_s2.py`; the stand `experiments/prop_lab/saloon/
  s1_sheet.py` (both batches' groups). Where each goes and its bodies: `experiments/prop_lab/README.md`
  "Saloon B, batch S1" and "batch S2" (~365 bodies as listed).
- **Open from S2's critic:** the keg rack is DIFFERENT (kegs lie on their sides in a rack: a kit prop is held
  only under its own bottom, so a lying keg needs its own kit file, staves laid out round a horizontal axis);
  CLOSE notes in the README (the wheel's dice, the fiddle's f-holes, the saw's teeth and grip, the scales'
  size, the faro's chips, the kegs' colour).
- **Next:** S3 (#892): the lying keg and its rack, the beds and the owner's desk; then the
  placing session once #865's body fix and #862's route land.
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
- A kit prop is held only by what's under its own bottom (its local -y): turned on its side it goes loose.
- The lab bridge's `prop_light HEIGHT` takes the kit's `light_height` (the flame); the lamp goes 0.16 under it,
  as the game places it. A chimney whose flame isn't the table lamp's: `prop:chimney_glass@<y>`.
- The dev bridge already has `stand` (the player): the lab's stand is `prop_stand`. The old factory sheet's
  spot before the saloon has a tied horse in view; the S1 stand is on the road east (40, 0, -5.4).
- A repeated member's mesh draw isn't renumbered: lay meshed members out one by one.
- Saloon B's bars, chairs and walks are in the valley: any member added there (even to `bar`) shifts Jolt's
  contact order and tips CI's card-game chair tests (#834). Add props as their own kits, placed later.
