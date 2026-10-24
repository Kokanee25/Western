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
