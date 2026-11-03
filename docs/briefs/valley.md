# The valley (inputs to #467)

Not the outline itself: #467 (parked) writes this brief's measured outline, `config/valley.json`
and the drawn map. This file holds what Sean has **DECIDED** so far, so that session builds on it,
plus what's **PROPOSED** and **OPEN**. Source: Sean's design lock of 2026-11-03. No place here is
built; building beyond the block still waits on the roadmap.

## DECIDED

**Scale and layout.** Broadly **4 km × 4 km**. Salt Creek (the town) near the base of the western
foothills; ranching flats to the east; the Baron's ranch to the southeast; Harlan's homestead
nearby, southeast; a sheltered Southern Ute community to the southwest; the widow's property east;
the railway's landmark order as already locked in the planning chat (east entrance → overpass →
canyon trestle → depot → Ore Works → western section → exit). The valley stays **dry and largely
open**: not a forest.

**Town.** The railway runs along the **north side of Main Street**. The Salt Creek watercourse runs
along the **south side of town**, then bends toward the trestle canyon. The creek's source upstream
is clean; the mines' drainage bypasses town and joins it downstream.

**The canyon.** The large railroad trestle is east of town and west of the small overpass, over the
canyon's dramatic **northern, deeper** part. The canyon carries on **south**, widening and
shallowing into passable ground. It does not end just below the trestle.

**The widow's homestead.** East of town, **north of the railway**, near Salt Creek. A historic
**eastern wagon road** reaches it by skirting the canyon's shallow southern end and crossing the
creek at a modest, passable crossing; it then goes **over the railroad by the small timber
wagon-road overpass** and on past her property toward the valley's eastern exit.

**The overpass.** Kept for the older through-road when the railroad was cut beneath it. **Not on
Harlan's routine commute** between his homestead and town. In one or two early missions Harlan
crosses it and a train passes beneath (foreshadowing); later it's a possible boarding point in the
Payroll Train mission. The eastern road is a possible interception area for the Baron's Shipment.

**The mine and the Ore Works.** Different facilities. The hillside rescue mine sits on a fairly
gentle **foothill bench**, reachable, with a practical wagon road down to the Ore Works.

**The timber camp** exists (an operating place; `docs/briefs/town-economy.md`); where, see below.

## PROPOSED

- The timber camp in the **northwestern/western foothills** on gentle, accessible ground, apart
  from the hillside mine, on an ordinary wagon road to town.

## OPEN

- The timber camp's forest edges, the sawmill's site (at the felling or nearer town), its road
  junction, ride time and worker count.
- The Baron's Shipment: its direction and the ambush spot.
- Ride times and the exact positions (the #467 session proposes, Sean picks).

## Against what's built

- `config/town.json` has no rail or creek yet. The train lab's test line runs **south** of town
  (`experiments/train_lab/`); the decided line is **north** of Main Street, so train step 6 lays
  the real route from this outline.
- The farmhouse sits "on its knoll in the hills east, north of the road" (`Farmhouse`): east and
  north fit; the road it's on becomes the eastern wagon road with its creek crossing and overpass.
- DESIGN.md §1/§5 still have the railroad *arriving* on day 30; a daily train and the Payroll Train
  need the line running (#546, #542's canon call).
