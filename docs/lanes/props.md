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
- **The undertaker's props, U1** (#1181; `tools/props/undertaker.py`, 33 kit props, members only, no
  Blender; placed by `experiments/building_lab/undertaker/make_spec.py` batch U1; README `experiments/prop_lab/undertaker/`,
  test `tests/test_undertaker_props.gd`). 345 bodies (valley 50,152 of 65,536). Tests green (building 9, valley, card_game).
  **Not judged:** two valley views rendered (parlour, embalming: the wreath a flat plaque, the zinc too dark); the stand
  sheet, the other four views and the critic still to run (README "What stands in"). Lantern and wreath hang on nails (a lantern's swing wants a baked GlassProp); glass is members, not GlassProps.
  **The hearse is made, not placed:** the yard's slope tips it loose (a kit prop's feet are looked for at one height); it wants
  a level pad under the shed. A prop's `kind` ladder bit twice (frame on trim, a trim hung under a top): `StructureMember.TIERS`.
- **The general store, G1 to G4 placed** (#1139, #1172, #1182, #1192; `tools/props/store_g1.py`, `store_g2.py` (numbers, kits, `STOCK` per
  board; its main also writes G3's), `store_g3.py` (the post office's `post_case` and mail, ledger, day-book, ink, cash; G4: the hung
  `hung_pails`, `hung_ham`, `hung_lantern`, `hung_boots`, bar clusters 1 to 1.3 m wide), `tools/blender/props/store_g2.py`, `store_g3.py`
  (models; `bpy` 5.0.1 in `~/.venvs/studio`, ~1.3 min); plan, judging and what's next in `experiments/prop_lab/store/README.md`;
  refs `refs/store/`). `gen_spec.py` imports all three (drops G1's `west_shelves_d`); edit there, re-run `store_g2.py` then
  `gen_spec.py`. G4's critic (two rounds spent): counter books CLOSE (a `counter_top` view in `render_valley.gd` now sees them), hung
  goods still DIFFERENT: too big from the door's camera (the cluster at z 2.6 to 2.7), hams read as gourds, boots as slabs. Next G5:
  shrink or drop that near cluster, net and string on the hams, boots with an opening. The room's ceiling, posts, light are art's.
  Rodin sack and boots wait on Sean (#1175). `probe_shelves.gd` reports "BAD" for anything not on a board (hung, counter goods): read `moved`.
- **Saloon B's S1, S2 and S3 are placed** (#950): its spec's `dressing`, written by `tools/props/saloon_b_dress.py`
  (edit there, re-run; it also moves the bar to x 2.25 and the use points it touches). What was decided: README
  "Saloon B, S1 to S3 placed". Kit files `tools/props/saloon.py`, `saloon_s2.py`, `saloon_s3.py`. **Judged by lamplight** (#987, `results/2026-11-15_saloon_b_placed/`): placement and lamps stand; kit faults in the README's "Judged by lamplight", for S4.
- **Open from S3's critic:** the kit's `bentwood_chair` DIFFERENT (a black tubular bistro chair) and `strongbox`
  DIFFERENT (a steamer trunk), both seen by the owner's desk; CLOSE notes in the README (kegs and rack near-black
  at noon, the bed too clean, the desk grainless, the ledgers blank slabs). S2's CLOSE notes still open (the
  wheel's dice, the fiddle's f-holes, the saw's teeth and grip, the scales' size, the faro's chips).
- **Saloon B's S5, the walls (#1030), merged with steps 1-6:** batch `S5` in `saloon_b_dress.py`: the back bar's every
  bay stocked, the **wall clock** (`WallClock`, a part: DayCycle's time, pendulum, tick, stops when shot through its works;
  `tools/props/wall_clock.py`, `tools/blender/props/wall_clock.py`), trophies (deer heads, the steer skull), the **rifle on
  pegs** (the game's own Winchester, `pbr:@<weapon sheet>`), spittoons, coat pegs, and #903's stage/dressing-room props placed
  (the footlights were #902's). The nude's place is beside the back bar (`NUDE_PLACE`, yard wall z 0.1-1.9). Critic round 1
  `results/2026-11-17_saloon_b_walls/critic.md`: skull, dress rail, trunk SAME; clock, rifle, deer head, mirror, screen,
  bottles CLOSE; spittoons DIFFERENT (the old drawn one reads as rocks: S4). **Steps 7-8 wait for #1032** (pictures and ads);
  the pronghorn is bought (up to $2, Sean #1042; no elk). No arm rail on the bar's top (Sean): the foot rail is the brass.
- **Next:** S5's steps 7-8 once #1032's `assets/props/paintings/` is on main (PR #1041 landed 2026-11-23); then S4 (the chair and strongbox, the spittoon, the CLOSE notes).
- **The booze, step 4 merged** (#1222, PR #1228, build 5335; `docs/briefs/booze.md`, `tools/props/booze.py` brands/shapes/kits, `tools/blender/props/booze.py`
  model + the one label sheet `pbr:booze_labels`): 50 bottled brands on 10 bottle kits (`variants`; a dressing entry's `variant`
  names the brand, `booze.variant_of`), 5 stencilled casks. Placed: saloon B (back bar, bar, No Law's table, Riedl's kegs, a Burnt
  Hollow barrel), the store's top grocery board, the doctor's three. **Not yet placed:** the hotel's F brands and the Railroad
  Saloon's R and dumb ones (Lowry's barrel, Wiener's, Uranus...): place them when those buildings are dressed. Critic r2
  (`results/2026-11-24_booze/r2/`): `glass:amber` reads opaque maroon under lamps; labels too alike (one layout, tone).
- **The doctor's office is furnished** (D1-D3 merged, #788/#805/#819; no D4). Coat and bookcase DIFFERENT, waiting on
  Sean (#871); don't re-judge the rest. The Studio's `claude/studio-doctor-bag` branch is unmerged (Sean's OK needed).
- **In the game since #844:** a building's props are its spec's `dressing` (`{"batches": {"D1": [...]}}`),
  placed by its build (`SpecBuilding._dressing` -> `PropDressing`); `dress.gd` only reads `building.dressed`.
  D3 moved there too, the sick room rearranged so no cot blocks a door; the jail's (#811) and the store's the same way.
  `Checks.people_fit` now checks each door's way in (0.45 m either side) and a use point's `prop`.
- Parked until after the slice: the Concord-bodied coach (#787; `tools/props/coach.py`, the boxy
  `baron_coach` stays), farmhouse props (#540).

## Traps
- `bpy`: `python3.11 -m venv ~/.venvs/bpy && ~/.venvs/bpy/bin/pip install bpy==5.0.1 pillow numpy` (pypi works); Vulkan:
  `apt-get install mesa-vulkan-drivers`, `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`; a room view ~5 min.
- A kit prop's going parts (WallClock's hands) are walked by the building lab's `Checks.destructible`: they're listed there.
- A lavapipe view ~10-15 min; never two renders at once; Blender bakes share the CPU.
- The valley render needs ~14 GB: on a 15 GB box add 8 GB swap (`fallocate`, `mkswap`, `swapon`) or it is OOM-killed.
- A fitted fixture is fitted to its members' own box: fit it smaller (G1's shelving, cornice and rail proud) and
  PropKit.fit squashes it, its boards no longer at the numbers its goods were placed by. `on` names its own batch only.
- New baked pngs import uncompressed without mipmaps headless: set their .import as the doctor's (mode 2, mipmaps).
- Never two renders, or a render and the suite, at once. A same-kind member thinner than 12 mm isn't "on" the
  one under it (CONTACT_EPSILON). The valley has no StaticBatch (glass props draw part by part).
- A hung cloth needs `hang_over` (a bar slips between points).
- A use point on furniture (a bed, a table, a chair) names it (`prop`), or the fit check fails it.
- Glass props cost at rest: the doctor's ~270 dressed props add ~0.3 ms a frame at Sean's (physics carrying ~390
  resting bodies; their own ticks ~0.06), ~1.7 us a prop here: a whole town dressed so would be ms. Their fixed
  parts draw through the dressing's `StaticBatch` (Forward+ only; this workspace needs `mesa-vulkan-drivers`
  or the bridge falls back to OpenGL, where neither batch runs and draws read ~2x).
- `model_paint` refuses a StandardMaterial3D; Rodin props need mipmapped paints.
- Every kit member is a physics body standing: put small things on a prop as its `dress`, give hollow
  members `"solid"` (the share that's material) or their weight is the box's.
- A kit prop is held only by what's under its own bottom (its local -y): turned on its side it goes loose. A
  lying thing is built lying (`beer_keg_side`): members by tier up its sides, feet whose four lowest corners
  are level and whose middles are over what it stands on (KitProp._set_down's ray is under each foot's middle).
- The lab bridge's `prop_light HEIGHT` takes the kit's `light_height` (the flame); the lamp goes 0.16 under it,
  as the game places it. A chimney whose flame isn't the table lamp's: `prop:chimney_glass@<y>`.
- The dev bridge already has `stand` (the player): the lab's stand is `prop_stand`. The old factory sheet's
  spot before the saloon has a tied horse in view; the S1 stand is on the road east (40, 0, -5.4).
- A repeated member's mesh draw isn't renumbered: lay meshed members out one by one.
- A sandbox under ~10 GB can't render the town or the valley (lavapipe is killed loading); no `cargo` crates
  there either (the native plugin's 10 tests fail locally, CI builds it). Vulkan: `VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json`.
- A hanging lamp's hook goes 1 cm under a joist: they're every 0.305 from z 0.157 (dance floor), 13.417 (upper
  hall), 15.297 (rooms), underside 3.635 over the ground floor; the ties' 7.31 (`joist_z` in saloon_b_dress.py).
- The stand puts props in the wall's shadow at noon: everything reads blue-black there (both critics said so);
  `prop:mirror` paints a lamplit room, so outdoors it reads as a dark window. Judge in the room once placed.
- Saloon B's bars, chairs and walks are in the valley: any member added there (even to `bar`) shifts Jolt's
  contact order and tips CI's card-game chair tests (#834). Add props as their own kits, placed later.
