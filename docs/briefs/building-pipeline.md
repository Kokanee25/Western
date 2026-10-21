# Brief: the material lab, the building lab and the town (Sean, 2026-10-20)

Three stages, each feeding the next: the **material lab** approves the woods and finishes, the
**building lab** builds one building at a time from its sheet and spec using only approved
materials, and **the town** places the buildings on the map. A building can't be judged fairly
while its woods are still changing. When each starts is in `docs/ROADMAP.md` ("When the labs
start").

## Material lab (art)

One material at a time on a test stand (a wall, a post, a deck and steps) under the game's three
lights, with a man beside it for scale. It already exists: `tools/material_lab.gd` ran the timber
pass on 2026-10-14 (`docs/briefs/material-lab-timber.md`), and its third version became the game's
woods on 2026-10-15. This makes it permanent and wider. **Built 2026-10-21: `docs/briefs/material-lab.md`**
(the stand, the measures against the Studio men, round 1's results, what production needs, the
wear-down plan).

| Tests | Examples |
| --- | --- |
| Colour | The red siding's light and chroma against the approved exterior |
| Grain and knots | Knots per board, checks, saw marks, no repeats between neighbours |
| Thickness and ends | Plank, board and siding thickness; end grain on every cut end |
| Dirt and weather | Splash at the foot of walls, sun-greying, long weather streaks |
| Paint wear | Worn lap edges, flakes along the grain, bare board ends |
| **Wear-down (new, after Gate A)** | Boards worn where people walk (the saloon door, the bar rail, the steps), paint gone where hands touch; one board new, a year old, ten years old |

Its output: approved materials in the texture factory, each with its numbers (thickness, texel
size, draw calls, texture memory) and a golden view.

**Carried over:** `material-lab-timber.md`'s "What production needs" (rim joists, open steps as
real members, chamfers carried into the voxel carving) is the bridge into the building lab, and the
building lab picks it up first.

## Building lab: the steps

1. **The target.** An image sheet of the building from every side: floor plans, elevations, a
   cutaway, interior views. Sean approves it, as he does a man's pictures. It's the look to match,
   not a drawing to build from.
2. **The spec.** A session turns the sheet into a text spec: rooms, sizes, openings, stairs and the
   frame. It fixes the views that disagree, fits the building to its lot in `config/town.json`,
   frames it from published period references (as the timber numbers already come from the USDA
   Wood Handbook), and asks Sean about each conflict.
3. **The build.** Code builds the members from the spec, as `FalseFrontBuilding` does today: load
   paths, burning, carving and breaking all work from the start.
4. **The look.** Woods, signs and dressing from the texture factory, only materials the material
   lab has approved.
5. **The judge.** Renders from the sheet's own views, side by side with it, for the judge and the
   blind critic, plus the checks below.
6. **The recipe.** What went wrong gets written into the recipe, so the tenth building is easier
   than the first.

## The building spec

One text file per building, in the repo, read and edited like any other data. Changing the building
means changing the spec, never hand-placing members.

| Part | What it holds |
| --- | --- |
| Identity | Owner, trade, means, age and repair, and five clues to who uses it (Prompt 17's card) |
| Lot | Its entry in `town.json`: width, depth, which side of the street |
| Floors | Heights, and which floor each room is on |
| Rooms | Size, walls, what the room is for |
| Openings | Doors, windows, the batwings, with sizes |
| Stairs and balconies | Where they run and what holds them up |
| Frame | Posts, beams, joists and studs, with sizes and spacing from period references |
| Materials | Which factory wood or material each surface takes |
| Use points | Where people sit, stand, work, drink and take cover |
| Sources | The references the frame and sizes came from |

## Worked example: the saloon sheet (`docs/concept/saloon-sheet.png`)

A strong target and a poor blueprint. Use it for the look and the layout's ideas; the spec settles
everything below before anything is built.

**What it gets right**

- **Every side at once:** two floor plans, front and side elevations, a cutaway, the view from the
  entrance and the view from the balcony. Each becomes a fixed camera to judge the game's render
  against.
- **A great gameplay shape:** the balcony open over the bar gives shooting from above, cover behind
  the railing and men falling over it. The stairs, back room and rear door to the alley give
  missions more than one way in and out.
- **Floor heights:** the cutaway gives 12 ft (3.7 m) for the ground floor and 10 ft (3.0 m)
  upstairs, a usable starting number.

**Critiques the spec has to settle**

| Critique | What the spec does |
| --- | --- |
| The side elevation shows an outside staircase that neither floor plan has | **Sean, 2026-10-21: keep it** (a second way up) |
| The front elevation has a balcony over the street that the second-floor plan doesn't clearly show | **Sean: both balconies**, the one over the street and the gallery looking down into the saloon; draw both on the plan with their posts and what carries them |
| Too big for its lot: by the scale bar it's roughly twice the 10 m the saloon has in `town.json` | **Sean, 2026-10-21: widen the lot**, as big as the saloon needs ("an important building"); the spec sets its width and `town.json` moves its neighbours along the street, in the same merge, with the town's tests and views |
| No frame: nothing shows posts, joists, spans or what holds up the balcony and its open well | Frame it from period references, sized from the Wood Handbook, so it stands and falls for real |
| Indoor men's and women's restrooms are unlikely in an 1882 saloon | **Sean: an outhouse out back** |
| Upstairs | **Sean: several bedrooms upstairs** (the sheet shows five) |
| A cellar | **Sean, 2026-10-21: yes, and big** (bigger than a real one would be is fine): kegs and spirits kept cool, reached by a trapdoor in a room behind the bar (a kitchen, as the sheet's back rooms already have); the floor over it on real joists, so a blast or fire can drop it in |
| The views were each drawn separately by an image model, so sizes don't match between them | Take sizes from the spec, never measured off the pictures |

## Checks

A building isn't done until it passes all of these, automatically, on every change to its spec.

- **It stands:** `StructuralAnalysis` passes with no member over its limit, the balcony included.
- **It falls right:** knock out a post and what it carried comes down; nothing floats.
- **People fit:** every door and stair clears a man; no use point sits on a step or in a doorway.
- **It's used:** each room's use points work for the people who'd be there (the barman behind the
  bar, a gambler at a table).
- **It burns and breaks** like the rest of the town: fire spreads through it, shots carve it.
- **Everything in it is destructible** (Sean, 2026-10-21): every object is a member, a kit prop or
  a fitting that falls with what holds it; no drawn prop, scenery mesh or solid box. A test walks the
  built building and fails on anything else, listing each allowed exception with its owner.
- **It fits the budget:** draw calls and frame time inside the render budget, with its lamps lit.
- **It matches the target:** renders from each of the sheet's views beside it, judged, with the
  blind critic's top three.
- **It's of its time:** nothing the period references rule out, or Sean has said it's fine.

## The town

Buildings from the building lab placed on Sean's map (`docs/concept/town-map.png`,
`config/town.json`): streets, lots, the yards and the dressing between them. It's judged as a place,
not building by building: walks down each street at dawn, noon, golden hour and night, the blind
critic's report, and the checks again for the whole street (draw calls, frame time, people's routes
from door to door).
