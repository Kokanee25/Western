# Brief: the prop factory (Sean, 2026-10-23, issue #338)

Sean: "a session that creates clutter and props in Blender — a list of things we want out there
and it can start pumping them out". The town is empty and cheap-looking; street session 3 (#327)
places what this makes. The factory is the prop lab (`docs/briefs/prop-lab.md`) run as a line:
every prop made **the same way**, in batches of about five, each batch judged and merged so #327
can take it at once.

## The recipe (every prop)

1. **Check `docs/PARTS.md` first.** If the thing exists (the spittoon, the mop, the barrel), use
   or extend it; never a second one.
2. **Pick its route** (the table below says which for each item):
   - **Kit** (members in code, `assets/props/kit/<id>.json`): anything built of boards, planks,
     staves, spokes or iron straps, so it splinters, breaks, carries weight and burns member by
     member as the buildings do. Long or repetitive files are written by a generator in
     `tools/props/` (one script a family, e.g. `wagons.py`), never by hand, so a change is one
     number and a re-run.
   - **Blender** (`tools/blender/props/<id>.py`, run headless with bpy, exported glTF to
     `assets/props/models/<id>.glb`, low poly): organic or lumpy things code does poorly (a sack, a
     bale, a skull, a mount's head). The mesh is only how it's **drawn**: the prop is still a kit
     file whose members (or loose body) carry it, by the kit's `"draw": {"shape": "mesh"}`
     (members) or `"model": "glb:<id>"` (loose and glass props). So a Blender prop breaks, burns
     and is thrown by the same code as the rest.
   - **Rodin through the Character Studio** (Sean, 2026-10-24: its deer head, #361, was far better
     than the Blender one): **every organic or "hero" prop**, anything whose shape and paint carry it
     (animals and skulls, tack and leather, sacks and bales, cloth, cast iron with character). Pictures
     of the thing (Sean's, or the Studio's image model) -> Rodin Gen-2.5 on the Studio's paid workflow
     (`prop3d`, **~$1.60 a prop, cost asked first**) -> a script like
     `tools/blender/props/deer_head_rodin.py` that puts it in the kit's space, cuts it to a few
     thousand triangles, splits it into the kit file's parts and keeps its own paint (the kit's look
     `model:<name>`). It is still drawn on kit members, so it hangs, breaks, burns and is thrown as
     the rest. Code-built Blender stays only for cheap lumps where shape barely matters.
3. **Its body** (`PropKit.make` decides by `kind`): `members` (KitProp: stands on its feet, tips,
   breaks, burns, is carved), `loose` (LooseProp: rolls, dents, is knocked, spills, never burns),
   `shatters` (GlassProp), `cloth`. Each file states its **mass** (from its real materials, the
   Wood Handbook's densities in `TimberTuning`), **what a hit does** (`splits_below`, `breaks_at`,
   `wall`, `dent`), **whether it burns** (any member not iron, stone or glass does), and what it
   **holds** (`contents`).
4. **Its look:** in the game's painted hand, worn and dirty, never clean, through **shared**
   materials (`PropKit.material`: the `prop:` looks and the woods), so a street of clutter is a
   handful of batches. A look that doesn't exist yet gets a **code-painted stand-in under its
   factory key** (`PixelArt.dirt/painted("prop_<name>", …)`): when the texture factory paints that
   key (`tools/textures/materials.json`, Sean's OK and the cost first) every prop wearing it changes
   with no code change. UVs are in metres (the texel grid lays the world's squares on them).
5. **Cheap:** a prop untouched is one batch a look (KitProp batches its members); members only
   where something should break on its own (a wheel's spokes, not a sack's stitches); the frame
   budget's Structures and Physics lines are checked for a street's worth at each batch.
6. **Made in batches of ~5.** Each batch: a test in `tests/test_prop_factory.gd` (built, its
   weight, it stands where it's put, its parts hold together, the batch counts), a contact sheet
   (`experiments/prop_lab/bench.gd --factory=…`: each prop in the street at noon and under the
   saloon's lamps at night beside a Studio man), a **blind critic** against `docs/concept/` ("does
   it belong in this town?", the five biggest differences), its rows in `docs/PARTS.md` marked
   **in the game**, merged. Results in `experiments/prop_lab/results/<date>_factory_<n>/`.
7. **Not placed here:** the factory never dresses the town; #327 does. A prop that replaces an old
   drawn one in place (the wagons) is the one exception, said in the commit.

## The recipe brought up to date (Sean, 2026-11-10, #788)

What the guns (#740, #776) and the material library (#721) taught us, laid over the recipe above.
Where it and the steps above disagree, this wins.

1. **Woods come from the material library** (#721, `config/material_library.json`), not the
   painted-hand stand-ins (`wood:<name>`, `prop:dark_wood`...). A prop's wood is one of the library's
   entries at one of its ages, by the kit look **`lib:<entry>/<age>`** (`new`, `few`, `old`; and
   `/floor` for a top that's walked or worked on): the member is drawn as a library board
   (`PropKit.board_mesh`, the doctor's builder's, #765, shared now) by the library's shader, indoors
   (no sun-fade, streaks or ground grime), a tenth of a wall board's warp (furniture is joined true);
   carved by a ball, the member falls back to its own wood's texel material in its own space. Only an age the
   materials judge passed is used (R1 new, C1 old, F2 new and a few years, 2026-11-10); a prop that
   wants another takes the nearest passing one, as the buildings do, and says which it wants in its
   `_doc`. **A prop's wood is never its floor's entry** (Sean, #821 picks 2 and 5; #825): furniture
   takes the library's **furniture** entries (family `furniture`: `furniture_oak` for office pieces,
   `furniture_painted_pine` for shelving, counters and plain pieces, `furniture_walnut` for one good
   piece a room), never a floor (`floor_*`) or a wall board's entry; a room holds at least three woods
   or finishes. Their finish is a joined piece's (rubbed arrises, grease round the pulls, dust on
   tops); a drawer's front takes **`lib:<entry>/<age>/front`** (its pulls at its quarters over 0.6 m,
   else its middle). **Paint** comes when the library has it (the
   next material round, #721: `painted_*`); until then the prop is unpainted on a passing wood.
   Library boards are boxes: a turned leg or a carved crest stays on a passing look of its own
   (the kit's lathes keep `wood:`) or is made square, as country furniture mostly was.
2. **Metal is made the gun way** (the Colt `experiments/gun_lab/saa/saa_paint.py`, the Winchester
   `win73_paint.py`): modelled in Blender, its finish made from 3D noise in each part's own space
   (no UV stretch), worn by its own shape (edges rubbed bright, hollows dark and duller), baked by
   Cycles into an albedo and an ORM (occlusion, roughness, metal), exported in the `.glb`; drawn by
   the kit look **`pbr:<model>`** (`PropModels.pbr`: metallic from the ORM, so it mirrors the game's
   sky and lamps), judged in the game's light. The finishes and their recipes are one shared script,
   `tools/blender/props/metal.py` (japanned iron, nickel-plated steel, polished steel, brass, tin,
   white enamel and china), each finish's evidence in its comment. No flat painted metal.
3. **Natural things from CC0 scans** (Poly Haven, ambientCG): rocks, logs, stumps, bark. Fetched on
   GitHub as the woods' are (`.github/workflows/scans.yml`), the licence recorded in `CREDITS.md`
   before it's used, the scan cut to the kit's body rules (a member's box carries it; a few thousand
   triangles; UVs in metres).
4. **Rodin stays for the soft, organic hero props** (sacks, hides, saddles, tack, food, animals, a
   doctor's leather bag), through the Character Studio's **pay-per-call** route (its `prop3d`
   request on GitHub; Sean is cancelling the Rodin subscription), **the cost asked first**, each call
   in the Studio's ledger. Code-built Blender stays for cheap lumps where the shape barely matters
   (a mattress tick, a folded blanket).
5. **Every prop is checked** before it's merged:
   - **a period reference**: a photograph (or a catalogue engraving) of the real thing from about
     1870-1890, in `experiments/prop_lab/refs/<batch>/` with its source and licence, and the prop
     set beside it on the sheet;
   - **judged blind in game light, beside the building it lives in**: the batch is dressed into its
     building's rooms on its valley lot (`experiments/prop_lab/doctor/dress.gd` and `dress.json`: each
     prop at the spec's use points, in the game's main scene and real look), rendered at the hours the
     rooms are used, and a fresh critic gets only those renders, the building's target sheet and the
     references ("does it belong in this room?", the five biggest differences);
   - **a cost limit**: triangles (a small prop ~1-3 k, a big one ~6 k), and **draw calls batched**
     (the doctor's 1,400-draw lesson: one material a look, shared across props; a room's props
     counted in the batch's test, `tests/test_prop_factory.gd`).

### The doctor's office batch (#788; the rooms in `experiments/building_lab/doctor/doctor.json`)

An 1882 country doctor. Made in batches of about five, each judged in his rooms and merged before
the next; the table and the cot first (the sheriff mission ends there, #746). Glass and china
shatter, wood breaks and burns, metal dents (the kit's bodies).

| Batch | Item | Route | Notes |
| --- | --- | --- | --- |
| D1 | Examining table | K (`lib:` walnut) + B tick | the surgery's `on_table`; a padded top on a plain frame, a raised head |
| D1 | Patient's iron cot | K (`pbr:` japanned iron) + B tick and blanket | the sick room's `cot_1`/`cot_2` (where you wake after you die) |
| D1 | Washstand with basin and pitcher | K (`lib:` pine) + G (china) | `wash_surgery`; the basin and pitcher shatter, the pitcher holds water |
| D1 | Instrument tray | L (`pbr:` nickel steel) | bone saw, forceps, probes on an enamelled tray; dents |
| D1 | Lamp with a reflector | G (`like` the oil lamp) + `pbr:` tin | the surgery's lamp held over the table at night |
| D2 | Medicine bottles (a shelf's worth, labelled), mortar and pestle, scales | G / L / L + K | the dispensary |
| D2 | Desk, his chair | K (`lib:`) | the front office's `desk`; the kit chair if it passes beside it |
| D3 | Books (two rows and a pile) and a bookcase, the hall's pegs with his coat and hat, chamber pot, folded blankets | K printed / K (`lib:`) / K + B / G / B | made (#819); the books' faces printed on one sheet. His bag (R, or B free) waits on #823 |

## Kinds of member the kit uses (so a prop stands and falls right)

The support graph (`Structure`): a member rests only on a lower tier (or the same kind stacked
under it); tier ≤ 1 at the bottom stands on the ground. A wheel standing on its rim is built down
that ladder: the felloe on the ground (`post`), the two spokes in it (`stud`), the hub
(`furniture_frame`), the other spokes (`cripple`), the rest of the rim (`board`); the axle on the
hubs (`cripple`, unchecked), the bolsters on the axles (`furniture_top`), the bed and all above it
(`trim`, each on the one under it). Shoot out the spokes under a hub and the wagon's corner drops.

## The list and each item's route

Sean can add; made top down, in the batches shown. **K** kit, **R** Rodin (the Studio) drawn on a kit body, **B** code-built
Blender on a kit body, **L** loose (LooseProp), **G** glass.

| Batch | Item | Route | Notes |
| --- | --- | --- | --- |
| 1 | Wagon wheel (lying loose), broken wagon wheel | K | hub, 12 spokes, 6 felloes, iron tyre (dress) |
| 1 | Buckboard, freight wagon, covered wagon | K | Sean's comment on #338: running gear, bed, sideboards, wheels with iron tyres, tongue, canvas on bows; replaces `PropModels.wagon` in the street (art's `street_dressing.gd`, said so). Wheels that turn and a hearse later |
| 2 | The mounted deer head | R + K (done, #361) | Sean on #338: a taxidermy mount (head, neck, antlers, glass eyes) on a shaped plaque, still on nails; hung clear of the stair (#308 is the saloon session's call on where) |
| 2 | Hay bale, loose straw pile, feed sack, grain sacks (stacked), horse droppings | B + K today; to remake **R**: bale, feed sack, grain sack (one sack laid three times), straw heap; droppings stay B | painted (run 125/126); the critics: cushions, pillows, too clean |
| 3 | Saddle on a rail, saddlebags, horse blanket, coiled rope, lasso on a post | R + K (the rail K) | |
| 3 | Horseshoes, anvil | L / R + K | the anvil iron (doesn't burn; balls glance) |
| 4 | Wheelbarrow, shovel, pickaxe, pitchfork, axe in a chopping block | K (+B heads) | handles break; iron heads |
| 4 | Split firewood stack, kindling pile, scrap lumber | K | each stick a member: burns well |
| 5 | Wooden ladder, water pump with handle, rain barrel, broken crate, crate lid, nail keg | K | the rain barrel and nail keg `like` the barrel |
| 5 | Rusty tin cans, broken bottles, old boot | L / G / R | the can a LooseProp, the bottles GlassProp pieces |
| 6 | Bench, rocking chair, A-frame sign, wanted-poster board, broom | K | the bench extends the street's code bench |
| 6 | Hanging lantern | G | the street's `lantern` with its `OilLamp`, as the sconce |
| 6 | Washtub and washboard, laundry basket | L / K | |
| 7 | Flour barrel, pickle barrel, cracker barrel | K (`like` barrel) | contents |
| 7 | Coffee sacks, bolts of cloth | R + K | as the sacks (one Rodin sack can serve) |
| 8 | Whiskey bottles (variants), shot glasses, beer mugs | G | the bottle extended (shapes) |
| 8 | Playing cards and chips, a dead man's hand, cigar box, ash tray, newspaper | K / L | small; burn |
| 9 | A dropped hat, a potted cactus, an oil can, a coat rack with coats | (the men's hats) / R + K / L / K + R coats | |
| 9 | Crates of goods, canned goods on shelves, a balance scale, a coffee grinder, candy jars | K / L / R / R / G | the shelves fixture filled |
| 10 | Pot-bellied stove with stovepipe | R + K (iron) | fireproof; a fire inside later |
| 10 | Rusted barrel hoop, steer skull and bones, broken chair, tarp over something, outhouse bucket | L / R / K / cloth | the broken chair: the kit chair less members |

The spittoon (cuspidor) and the mop exist.

## Done for each batch

- Kit files (and Blender scripts and `.glb`s with their `.import` files) on main; the generator
  re-run gives the same files.
- `tests/test_prop_factory.gd` green; the whole suite green.
- The contact sheet and the blind critic's top three in the status entry and the PR.
- `docs/PARTS.md` rows **in the game**.

## How it's judged

The blind critic: only the concept paintings and the sheet, "does it belong in this town", the
five biggest differences. Sean's eye on the sheets in the PR. A batch the critic finds looks
clean, new or toy-like goes back for weathering before the next batch starts.
