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
- **The doctor's batch D2 (#805)**: bottles, mortar, scales, desk, chair. D1 merged (PR #802, build 3968).
  Nobody wipes with the towel yet (gameplay's hands).
- Parked until after the slice: the Concord-bodied coach (#787; `tools/props/coach.py`, the boxy
  `baron_coach` stays), farmhouse props (#540).
- Then the jail's and the store's props as those buildings land (art's #765 order).

## Traps
- A lavapipe view ~10-15 min; never two renders at once; Blender bakes share the CPU.
- A hung cloth needs `hang_over` (a bar slips between points).
- `model_paint` refuses a StandardMaterial3D; Rodin props need mipmapped paints.
