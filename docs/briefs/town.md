# Brief: Salt Creek's town, to Sean's map and the bold street painting

Sean, 2026-10-05: "I want the game town to look like this, same layout", with the map. Two
pictures are the target:

- **The layout:** `docs/concept/town-map.png` (west at the top, toward the mesas and the
  sunset; the "reference view" marker is where the street picture is taken from). Made from the
  1886 Tombstone and 1887 Dodge City Sanborn fire-insurance maps (connected blocks, narrow shop
  fronts, deep lots, working yards behind); the town itself is fictional.
- **The look:** `docs/concept/street-golden-hour.png` (the street concept painting, the street
  target all along) and, inside, `docs/concept/saloon-blocks.png` (the saloon painting redrawn
  in the street painting's style; Sean, 2026-10-05: the bold style everywhere, the old
  `saloon-night.png` kept for its lamplit mood only): crisp, bold squares on every surface (larger
  than ours, each a clearly different colour from the next), pale weathered boards with a dark
  line at every seam, signs lettered square by square, the sun low at the end of the street.

One town, on the map we have: the test street becomes Main Street and the town grows round it.
No second map (the gang's routes, the townsfolk's posts, the tests, the goldens and the dev
bridge's places all live on this street; git keeps the old one).

## What the map has, against what we have

Main Street, looking west from the reference view (the map's "up"):

| Left (the saloon's side) | Right (the livery's side) | In the game now |
|---|---|---|
| Saloon | Livery (corral behind) | both, in this order |
| General store | Sheriff / jail | both |
| Telegraph, barber, doctor | Assay office | barber and assay; no doctor, no telegraph |
| *(Market Street)* Hotel | *(Market Street)* Bank | hotel; no bank |

Behind and around: Church Street (church, school, houses and gardens), Stable Road (feed store,
blacksmith, wagon repair, freight storehouse), the water tower and a well with a windpump in a
yard behind the jail, Freight Street and the stage stop at the east end, the cemetery on a rise
in the north-west, a dry arroyo to the north.

Against `docs/TOWN.md`'s fourteen: the map has all but three. **Not on the map:** the newspaper
(11), the laundry and eating house (13: the Chinese family, to be written with care), and the
land office (10: the map has the telegraph alone). **New on the map:** the school, the feed
store, wagon repair, the freight storehouse, the stage stop's buildings, the cemetery, the well.
**Split:** the blacksmith is its own building (TOWN.md has it with the livery); the barber
stands without the bathhouse and undertaker.

## Things to settle (Sean)

1. ~~Which picture is the target for the look.~~ **Settled** (Sean, 2026-10-05): the street
   painting's bold style everywhere; the judge and the blind critic measure the saloon shot
   against `saloon-blocks.png` from now on (rounds before `2026-10-05_r14` were against
   `saloon-night.png` and don't compare).
2. ~~The sun.~~ **Settled** (Sean, via the gameplay session): "The sun sets right down the Main
   Street": `sun_azimuth_degrees` 0, due west (on the art branch; lands with the bold look).
3. ~~The three buildings the map leaves out.~~ **Settled:** "we're using the map": the map is the
   town; the newspaper, the laundry and eating house and the land office aren't built for now.
4. ~~Scale.~~ **Settled:** "pushing mountains out is good"; the street is compact as in the
   painting, about 90 m from Freight Street to Market Street (the gameplay session's
   `docs/briefs/main-street.md`). And "buildings need to change same as the art, up on steps":
   raised boardwalks with steps down to the street.

The gameplay session's `docs/briefs/main-street.md` has the street's layout and its steps; the
art session re-places the reference view and pushes the backdrop and the ground's edge out once
the new street is in `config/town.json`.

## Who does what

- **Art** (this session): the look (the renderer's settings, the textures re-cut as bold pixel
  art, lettered signs, the light and sun, the backdrop moved out), the street dressing, the
  judge and critic against the new pictures, golden images.
- **Gameplay:** the layout as a data file (TOWN.md asks for one), the buildings and their
  interiors one per session as TOWN.md says, waypoints and routes, the townsfolk's posts and
  the gang's day, the tests, and the frame budget for a whole town (drawing and simulating only
  what's near: today's one street is already at the render budget).
- **Characters:** the townsfolk the new buildings need (the doctor, the banker, the
  blacksmith...), in the bold style.

## Order

1. **The reference view, first.** The look on the street we have, judged against the street
   picture from the map's reference view: hard block edges and far blocks kept (two settings),
   wood, road and signs re-cut as bold pixel art at 16 texels a metre, the sun at the end of the
   street. One merge; Sean's eye is the gate.
2. **Main Street to the map.** The layout file; Main Street's buildings moved and the missing
   ones added (doctor, telegraph, bank), the slight bend, the water tower and well behind the
   jail, the corral behind the livery. Gameplay moves the routes and tests in the same merge.
3. **The cross streets and the edges**, a block at a time: Market Street, Stable Road, Church
   Street, Freight Street and the stage stop, the cemetery, the arroyo.

## How it's judged

- The reference view against `street-golden-hour.png`: judge v2, the blind critic, Sean's eye.
- The layout against the map: a top-down render of the town over `town-map.png`.
- The frame budget (`config/frame_budget.tres`) at the reference view and walking the town.
