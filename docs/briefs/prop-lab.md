# Brief: the prop lab (Sean, 2026-10-21)

**One lab makes every prop end to end:** its shape, its look, what it's made of, and how it
breaks, burns or shatters and what spills out. A prop is done when it looks right beside the men
and fails right under a revolver, a shotgun, dynamite and fire, and is promoted into the **prop
kit** (`docs/PARTS.md`, "Props"), where every building, room and lab takes it by name.

## Why one lab

Props are made in two places today that don't know about each other:

- **Drawn props** (art): `assets/props/manifest.json` lists 12 (`card_table`, `chair`,
  `bar_stool`, `upright_piano`, `barrel`, `spittoon`, `oil_lamp`, `whiskey_bottle`, `tin_cup`,
  `deer_head`, `framed_painting`, `wall_sconce`); `src/props/prop_library.gd` spawns them (a
  `.glb` if one exists, else a model built in code by `src/props/prop_models.gd`, else a box) with
  one collision box each. They look good and are judged in the shots, but they're solid: a chair
  can't lose a leg, a barrel can't burn stave by stave. A smashed lamp spills burning oil (through
  `Fittings`), and that's the extent of it.
- **Furniture as members** (gameplay): the store's counter and shelves, the telegraph's, the
  doctor's and the bank's rooms (`FalseFrontBuilding._furnish_*`), the saloon's bar, stair and
  balcony (`src/art/saloon_dressing.gd`, as members), the trough, hitching rail and well
  (`src/structures/`). These break and burn, but each is built by hand inside its building.

Splitting a prop's look and its breaking between two lanes is how things fall through. So one
lab owns both.

## What a prop is

Each prop is **defined once, as data** (one file per prop in the kit), holding its shape, its
materials and how it fails, in one of three kinds:

| Kind | Examples | How it fails |
| --- | --- | --- |
| **Built from members** | Tables, chairs, stools, benches, shelves, counters, crates, barrels (staves and hoops), troughs, doors, the piano | Like the buildings: legs snap, tops split, it carries weight, it burns piece by piece, shots carve it |
| **Shatters** | Bottles, glasses, lamp chimneys, plates, windows, mirrors | Breaks into pieces; what it held spills (whiskey; lamp oil that burns) |
| **Hung or loose** | Pictures, signs, horns, wall lamps, hats, cards, coins | A fitting: falls when its nail or board goes; burns if wood, canvas or paper |

Today's drawn props become the **targets** for their kit versions: the kit's chair must look at
least as good as `PropModels`' chair in the same shot, so nothing that already looks good is lost.

## Rules

- **Uses the shared systems, doesn't rewrite them:** members and the support graph, voxel carving,
  fire, `Fittings`, `Blast`, the texture factory. A new system a prop needs (shattering, spilled
  liquid) is built as a promoted part (`docs/PARTS.md`). A change to the members, fire or blast
  code goes to the gameplay lane's owner session, or to Sean if none is running.
- **Lane exception (Sean, 2026-10-21):** the prop lab may edit art's prop files
  (`src/props/`, `assets/props/`) and the prop kit's own structure code. It says so in each
  commit, as CLAUDE.md asks.
- **Looks:** materials approved by the material lab, matched to the Studio's men; a prop's own
  textures through the texture factory in the same hand. Costs before any paid painting.
- **Tested on the other labs' benches:** every prop passes the breakage lab's scenarios (revolver
  and shotgun at 5 m, dynamite at 1, 3 and 6 m, a man dropped onto it) and is judged on the
  material lab's stand with a man in front of it.
- **Budget:** a room full of props inside the frame budget. Untouched props draw batched, as the
  buildings do; a prop draws on its own only once it's damaged.
- **No scripted outcomes:** a prop that only fails right with a special case is reported, not
  patched.

## Order

1. **Tables and chairs** (roadmap 3.3, furniture: the fights need them), including a seated man
   dropped when his chair goes.
2. **Bottles and the oil lamp:** shattering, whiskey and burning oil.
3. **Then** stools, barrels, crates, the trough, shelves and counters (bringing the buildings'
   hand-built furnishings into the kit), wall decor, the piano, roughly in the order the missions
   need them.

## Done for each prop

- A kit file; the drawn prop it replaces (if any) gone from `PropLibrary`'s code models.
- Breakage lab numbers: what breaks at what, pieces, debris, what burns, physics faults, frame time.
- A sheet beside its target and a man, the blind critic's verdict.
- A test; its row in `docs/PARTS.md` marked "in the game"; the test saloon told it's ready.
