# Brief: lived in (Sean, 2026-10-22)

**Every mark has a cause, every object a history, every place shows how people use it.** Not
broken windows and overturned chairs: the small evidence that people have lived, worked, drunk,
fought and mended things here for years. Wear isn't spread at random: a stair is worn deep in the
middle of its treads, its rail polished where hands grip it, and nearly untouched against the
wall. That difference is what makes a place feel observed rather than decorated. The most
convincing place isn't the dirtiest: it's the one where every imperfection is in the right place.
A well-run saloon has polished woodwork and clean mirrors, and its floor still shows decades of
boots; an abandoned boarding house is dusty everywhere but rotted only under the leak.

It builds on the material lab's wear-down plan (`docs/briefs/material-lab.md`, "Wear-down: the
plan"), which it widens from wear to history; it doesn't replace it.

## Four layers on every object

| Layer | Example (a card table) | Where it comes from |
| --- | --- | --- |
| 1. How it was made | a roughly planed oak top, uneven joinery | the material lab's woods and their ages (new, a year, ten years) |
| 2. Years of use | glass rings, elbow polish, knife cuts, rounded corners | the building spec's **use** (who does what where, how often) |
| 3. Its past | one replaced board, a wedge under a short leg | the building spec's **past** (what happened, to what) |
| 4. What the player did | a new bullet gouge, a spill, later a townsman's repair | the game's damage (holes, fresh-cut faces), saved as the difference from the authored town; repairs by a system (a carpenter's job), not a script |

## The rules

1. **Every mark is on the member it's on.** A ring is in the table board's drawing, not a decal
   floating over it: it burns, breaks and flies with the board, and the destructibility walk
   (`tests/test_building_lab.gd`) keeps passing. No free-standing decals.
2. **Every mark comes from a cause in the data.** The builder places marks from the spec's `use`
   and `past`: a walking path wears the boards it crosses, most on its centre line; a rail is
   polished where people stand at it; a lamp sooted the boards over it. Nobody paints wear by hand
   or scatters it by noise.
3. **Pick details that read at play distance** in our look (painted, squares several pixels big):
   a bowed tread, a polished rail section, the dirty band under the foot rail, a pale patch where a
   picture hung, one clearer pane. Fingerprints on a chimney mostly won't. The blind critic judges.
4. **Each building its own.** The spec's identity (owner, means, age and repair) sets how cared
   for it is: polish and clean glass where the owner keeps it so, dust where nobody reaches.
5. **Something happened before you arrived.** The `past` list holds small stories nobody
   explains: a ball in a post with a gouge where someone pried at it and the hole filled, a
   scrubbed patch cleaner than the grime round it, a replaced baluster in raw pine, initials cut in
   a window frame. No quests or lines: evidence.
6. **Routines, not only decay** (and later, the whole town): the barber's strop at the right height
   and hair in one corner, the store's counter dented where the scale weight sits, the stable's
   posts glossy at a horse's shoulder, the sheriff's armrests polished. One house with one clean
   window, because someone sits there and watches the street.

## The marks (the vocabulary the shader and geometry will draw)

`foot` (boards worn by traffic: lighter, smoother, dirt kept in the gaps), `heel` (dents where
people stand or turn), `scuff` (furniture and door arcs), `hand` (polish where hands grip or slide),
`grime` (fingers round a latch), `elbow` (polish where arms rest), `rings`, `spill`, `burn`
(tobacco), `cut` (knife), `soot` (over lamps and stoves), `splash` (mud at a wall's foot), `bleach`
(sun on south and west faces), `streak` (water off a sill, rust under iron), `new` (a replaced
member, younger than its neighbours), `pale` (where something hung), `holes` (nail, screw,
bullet), `filled`, `scrubbed`, `carved`. Each mark: its kind, strength (0-1) and where on the
member (a stretch along it, or a point and radius).

## How it gets into the game

| Technique | What | Who |
| --- | --- | --- |
| The data | `use` and `past` in each building's spec; the builder turns them into marks on members (`marks` on each member) | gameplay (the spec, the builder) |
| Material wear | the woods' shader draws the marks (the wear-down plan's mask, from the marks); the woods at three ages | art |
| Geometry | worth a silhouette: bowed treads, rounded nosings, chipped corners, a sagging door; kit props' draws and `PropKit.dress_member` shapes | art, the prop lab for props |
| Persistence | authored marks rebuild from the spec each load (nothing to save); the player's damage is already saved as the difference; repairs a townsman makes are saved the same way | gameplay |
| Accumulation | wear that grows with play (traffic counted over days), repairs as a job (a carpenter puts in a mismatched board, sands a gouge) | gameplay, later (needs brains that do jobs) |

**A lived-in pass** is a step of the building pipeline (`docs/briefs/building-pipeline.md`), after
the build, furniture, light and materials: for every major thing in the building, ask what happens
to it over its life, who uses it, and where that use shows; write it into `use` and `past`.

## Order

1. **Now (free, no look change):** the saloon's `use` and `past`, the builder's marks, a check that
   every mark resolves to members and lands where its cause is, and a wear map render (members
   tinted by their marks) for Sean to see the placement. (Gameplay, the building lab.)
2. **After Gate A (the look locked), as the wear-down plan has it:** the shader draws the marks, the
   woods' ages, the geometry. (Art; judged on the material lab's stand, then the saloon's views.)
3. **Later:** wear that accumulates, repairs, and the lived-in pass for every building in the town.

## Done, and how it's judged

- Every `use` and `past` entry lands on members; none lands where its cause can't reach (a test).
- The wear map: Sean sees the placement and says it's right before any of it is drawn.
- Drawn (step 2): the blind critic against Sean's saloon picture and the sheet, asked specifically
  whether the wear reads as caused (in the right places) or as decoration.
