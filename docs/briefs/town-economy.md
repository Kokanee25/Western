# The timber camp and the town's working economy (brief)

Source: Sean's design lock of 2026-11-03. **DECIDED** is Sean's; **PROPOSED** and **OPEN** are not
canon. Goes with `docs/TOWN.md` (the buildings), `docs/briefs/valley.md` (where), DESIGN.md §11
"townsfolk with lives". Sean (2026-11): the living-world layer comes once the missions and the map
work, so this is planned now and built after them unless he moves it.

## DECIDED

**The town.** Salt Creek feels like a working 1882 frontier town. It isn't self-sufficient: finished
industrial goods come by rail; local people make, repair, sell and deliver everyday needs. Visible
labour, freight, repairs and routines; businesses that act on each other, not fronts.

Story functions that exist: saloon, general store/grocer, blacksmith, livery, doctor, sheriff and
jail, depot and freight, the mining and timber operations, the widow's and the ranching economy.
(TOWN.md's other buildings — bank, church, barber/bathhouse/undertaker, hotel, land office and
telegraph, newspaper, laundry and eating house, assay office — are unchanged by this.)

**The timber camp.** A small working forest and camp supplying the town's building. Seen working:
1. men cutting suitable trees in a modest stand;
2. limbing and handling the logs;
3. moving logs to a small sawmill, sawpit or work area;
4. planks, beams and posts made;
5. raw logs and finished lumber in distinct piles, with stumps, sawdust, chips and cleared patches;
6. lumber loaded on horse-drawn wagons and carted into town, with real deliveries.

**Simulation goal.** The player sees the work happen and the materials move.

**Glass and building materials.** No glass or window factory. Panes are made outside the valley and
come by rail as crated, fragile freight. A carpenter/joiner makes and mends sashes and frames from
local lumber; a carpenter, glazier or handyman fits the glass (no storefront needed). Nails, hinges,
hardware, glazing materials and most finished goods come from outside, through the depot and the
merchant. The timber camp supplies planks, beams and posts for building and repairs.

## PROPOSED (not canon until Sean picks)

- **Candidate businesses:** carpenter/joiner (maybe coffins), hardware/building supply (maybe
  inside the general store), wagonwright/wheelwright, saddler/harness maker, butcher, bakery,
  boarding house or hotel, barber/baths, undertaker, assay office, tinsmith or metal bench,
  newspaper printer. Several are already in TOWN.md (hotel, barber/baths/undertaker, assay office,
  newspaper); the new ones are the carpenter, hardware, wheelwright, saddler, butcher, bakery and
  tinsmith. Size: ~12-16 working shopfronts plus jail, depot, housing and yards in the ~250 m street.
- **Damage that stays and gets mended:** a shot-out window boarded, then reglazed by the carpenter
  when glass is in; a broken wagon to the wheelwright; broken furniture, funerals and deliveries
  carrying on from what happened.
- **The first loops:** timber (cut → logs → stacks → wagon → unload at the carpenter or a site); rail
  freight (train → crates at the depot → merchant → carpenter fits glass or hardware);
  blacksmith/livery (horse in → shoeing → out); ranch/butcher (wagon in → restock → customers);
  repair (damage → boarded → repair visit → mended).

### How to build it cheaply (PROPOSED engineering)

Rule: **a few convincing loops across several places beat many detailed shops.** One
`Economy` autoload holds stock as numbers; everything you see is drawn from those numbers.

- **Stock as state, piles as pictures.** `config/economy.json`: each stockpile (logs, beams, planks,
  posts at the camp; lumber at the carpenter; crates at the depot) is a count with a cap. A pile's
  look is drawn from its count (instanced boards in a batch, as `PropBatch`), never a physics body
  each. A board you knock or blast becomes real then (the `StructureMember.rest`/`realise` pattern).
- **Work as a few deterministic task cycles.** A worker's day is a short loop of chores
  (`CivilianBrain.chores`, the barkeep's `WipeBar`/`MopFloor` pattern): saw at the pit for T s, carry
  to a stack (+1), load the wagon. Seeded and on the game clock, so far away it's skipped by
  arithmetic: arrive in view and the piles are where the clock says.
- **Trees that don't run out.** A stand of N fixed tree slots: standing → felled (a log) → stump.
  A stump is replanted only while nobody's near and unseen, and only K slots are ever down. A
  felled tree is a timed fall of one rigid trunk, then a static log; no voxel tree.
- **The wagon is a 1D mover.** The train's `TrackLine` (a curve) and a simple speed profile carry a
  wagon along the road; a team of horses walks with it (the horse's walk is still in progress,
  #478, so a stand-in until then). Far off it's a point on the curve, not physics.
- **Deliveries that are real.** The wagon's arrival moves stock from the wagon to the destination,
  and the unload is a visible task by whoever's there.
- **Budget:** one camp crew (2-3 men), one wagon, ~6 piles: under ~0.3 ms of people and nothing in
  physics at rest. Measured with `perf_bench` before it merges.

### The first proof (PROPOSED, one session after the valley outline)

A small stand of trees and a cutting place; logs, beams and planks in distinct piles; one loaded
wagon on a plausible road; unloaded at a real town destination. Done when you can watch one tree
become planks and those planks arrive in town, and leave and come back to find the piles moved on.
Where the camp and the destination are waits on Sean (OPEN), so the proof runs at a greybox spot.

## OPEN

The final business list, which share buildings, their plots, owners and NPCs, how deep the economy
goes, build priority; the camp's place, sawmill site, road and crew size.

## Against what's built

- No wagons move yet (the street's wagons are props; the freight wagon in the lot, #366, parked);
  no horse walks yet (#478). The timber loop needs both or stand-ins.
- The rail-freight loop needs the train in the world (train step 6), which needs the valley outline.
- TOWN.md has 14 buildings in ~250 m already; 12-16 *working* businesses means some share buildings.
