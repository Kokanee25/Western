# Brief: Main Street to Sean's map (gameplay's part)

The town brief (`docs/briefs/town.md`, the art session's) has the target; this is the gameplay
session's plan for its part: the layout, the buildings, the routes and the tests.

## Sean's words (2026-10-05)

- "The sun sets right down the Main Street" (the street picture `street-golden-hour.png`).
- "We're using the map, so that means we need to change the layout of our current map": one town,
  `docs/concept/town-map.png`; what isn't on the map (newspaper, laundry and eating house, land
  office) isn't built for now.
- "Buildings need to change same as the art, up on steps": the boardwalks stand up off the street
  with steps down to it, as in the picture.
- "Pushing mountains out is good."
- "It's gotta match this art."

## The layout

Main Street runs along X, west (−X) toward the mesas and the sunset; north is −Z, so looking down
the street at sunset the saloon's side is on your left (+Z, the south side) and the livery's on
your right (−Z, the north side), as in the picture and on the map.

- Fronts 17 m apart (Sanborn), the south fronts at z = 0, the north at z = −17; boardwalks 2.4 m
  deep, raised ~0.6 m, with steps down to the street.
- South side, from the east end: **saloon** (the real one, with its room), **general store** (the
  real one), telegraph, barber, doctor; Market Street; hotel.
- North side, from the east: **livery** (corral behind), **sheriff/jail**, the yard with the water
  tower and the well and windpump behind, assay office; Market Street; bank.
- Freight Street crosses at the east end (the reference view stands just inside it); the stage
  stop beyond it. Church Street, Stable Road and the edges come later, a block at a time.
- Lots 7–16 m of frontage and ~35 m deep. Proposed: ~90 m from Freight Street to Market Street
  (the map isn't to scale; the picture's street is compact, and every building we add costs
  frame time).
- The range moves out past the east end (it isn't on the map; it stays for the shooting match).

## Steps (one merge each)

1. **The layout as data, nothing moved.** `config/town.json` (buildings with kind, lot, facing and
   shape; boardwalks; the places people go) read by a `TownLayout`; the waypoints inside the
   store and the saloon given in each building's own space, so they move with it. Same street,
   same tests, same goldens.
2. **Main Street to the map.** The data changed to the layout above: one saloon (the façade one is
   gone), the store beside it, the livery and jail across; raised boardwalks with steps the
   player climbs (a step-up in the controller, the ramps gone) and the townsfolk walk; the
   gang's day, the townsfolk's posts, the dev bridge's places, the tests; the street dressing
   re-placed with the art session; goldens re-approved.
3. **Main Street's missing buildings:** telegraph, doctor, bank; the water tower, well and windpump
   behind the jail (the well a water source for the buckets); the corral; the ground out to the
   new edges.
4. Then the cross streets, a block at a time (town brief, step 3).

## Who does what

- Gameplay: steps above, the frame budget for a bigger town (draw and simulate only what's near).
- Art: the look, the sun down the street, the backdrop pushed out, the dressing and signs to the
  picture, the reference view, the judge, critic and goldens.
- Characters: the new buildings' people.

## How it's judged

- A top-down render of the town over `town-map.png`.
- The reference view against `street-golden-hour.png` (art).
- Every test passing; the playtest agent walking the new street; the frame budget.
