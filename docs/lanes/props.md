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
  re-judge the rest. The props sit in his rooms only by the lab's `dress.json` until his spec takes them.
  The Studio's branch `claude/studio-doctor-bag` (the bag's card, pictures, model, ledger at $64.89 of $66)
  is unmerged: Sean's OK needed.
- Parked until after the slice: the Concord-bodied coach (#787; `tools/props/coach.py`, the boxy
  `baron_coach` stays), farmhouse props (#540).
- Then the jail's and the store's props as those buildings land (art's #765 order).

## Traps
- A lavapipe view ~10-15 min; never two renders at once; Blender bakes share the CPU.
- Never two renders, or a render and the suite, at once. A same-kind member thinner than 12 mm isn't "on" the
  one under it (CONTACT_EPSILON). The valley has no StaticBatch (glass props draw part by part).
- A hung cloth needs `hang_over` (a bar slips between points).
- `model_paint` refuses a StandardMaterial3D; Rodin props need mipmapped paints.
