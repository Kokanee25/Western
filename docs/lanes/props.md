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
- **The doctor's office is furnished: D1, D2 and D3 merged** (#788 PR #802; #805 PR #817; #819). D3: his books
  (`book_row_a/b/c`, `book_stack`), `bookcase`, `coat_pegs` (coat and hat hung), `chamber_pot`,
  `folded_blankets`, and `doctors_bag` (Rodin, Sean's A on #823). All his wooden kits are now
  `lib:furniture_oak/few` or `lib:furniture_painted_pine/few` (#825). No D4. Blind critic, two rounds
  (`experiments/prop_lab/results/2026-11-12_doctor_d3/r2/critic.md`): peg rail SAME; books, hat, bag, pot,
  blankets CLOSE; **coat and bookcase DIFFERENT** (the coat hangs stiff as on a hanger: code-built cloth
  doesn't drape; the bookcase is a low open oak shelf where the panel shows a tall dark glazed case on a
  cupboard base). Those two wait on Sean's pick (the `waiting on Sean` issue opened with the merge); don't
  re-judge the rest. Since #844 they're in his spec's `dressing`, placed in play.
  The Studio's branch `claude/studio-doctor-bag` (the bag's card, pictures, model, ledger at $64.89 of $66)
  is unmerged: Sean's OK needed.
- **In the game since #844:** a building's props are its spec's `dressing` (`{"batches": {"D1": [...]}}`),
  placed by its build (`SpecBuilding._dressing` -> `PropDressing`); `dress.gd` only reads `building.dressed`.
  D3 moved there too, the sick room rearranged so no cot blocks a door; the jail's (#811) and the store's the same way.
  `Checks.people_fit` now checks each door's way in (0.45 m either side) and a use point's `prop`.
- Parked until after the slice: the Concord-bodied coach (#787; `tools/props/coach.py`, the boxy
  `baron_coach` stays), farmhouse props (#540).
- Then the jail's and the store's props as those buildings land (art's #765 order).

## Traps
- A lavapipe view ~10-15 min; never two renders at once; Blender bakes share the CPU.
- Never two renders, or a render and the suite, at once. A same-kind member thinner than 12 mm isn't "on" the
  one under it (CONTACT_EPSILON). The valley has no StaticBatch (glass props draw part by part).
- A hung cloth needs `hang_over` (a bar slips between points).
- A use point on furniture (a bed, a table, a chair) names it (`prop`), or the fit check fails it.
- Glass props cost at rest: the doctor's ~270 dressed props add ~0.3 ms a frame at Sean's (physics carrying ~390
  resting bodies; their own ticks ~0.06), ~1.7 us a prop here: a whole town dressed so would be ms. Their fixed
  parts draw through the dressing's `StaticBatch` (Forward+ only; this workspace needs `mesa-vulkan-drivers`
  or the bridge falls back to OpenGL, where neither batch runs and draws read ~2x).
- `model_paint` refuses a StandardMaterial3D; Rodin props need mipmapped paints.
