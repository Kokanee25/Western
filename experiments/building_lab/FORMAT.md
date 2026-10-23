# The building spec (format 1)

One text file per building (`<id>.json`), read and edited like any other data: changing the
building means changing its spec, never hand-placing members (docs/briefs/building-pipeline.md,
"The building spec"). The builder (`spec_building.gd`) turns it into members of one `Structure`,
kit props and fittings; the checks (`checks.gd`) say whether it's done. The saloon's
(`saloon.json`) is the first.

**Space.** Metres in the building's own space, as FalseFrontBuilding's: x along the front from its
west corner, z back from the front wall's outer stud face, y up from the ground; the front faces
-Z (the street). The lot's entry in `config/town.json` places that space in the town. Name sides
by compass (west, east), never by "left" or "right": the sheet, Sean's picture and the old
saloon's code each meant something different by them.

**Sizes come from the spec**, never measured off the pictures (the sheet's views were each drawn
separately and don't agree). The pictures are the look to match.

## The parts

| Part | What it holds | The saloon's |
| --- | --- | --- |
| `identity` | owner, trade, means, age and repair, five clues to who uses it (Prompt 17's card) | Joe Doyle's saloon and lodging house |
| `lot` | its `town.json` node, side of the street, `at`/`facing`, width and depth, its yard, the footprint with its stairs and balconies | 50 ft by 56 ft, Freight Street moving east |
| `levels` | the cellar's floor, each floor's top, the wall plate, the false front's top, the roof's pitch | 12 ft and 10 ft storeys (the cutaway), 3/12 roof |
| `frame` | every member's section, spacing and wood by element (foundation, sill, pier, girder, joist, floor board, stud (and the walls that take `tall` studs), plate, ribbon, header, post, beam, bracket, wall post, truss), with the reference that sized it | the balloon frame, queen-post trusses |
| `girders` | the lines under the ground floor's joists (on piers; in a cellar, on its posts) | 10 ft or less between them |
| `cellar` | its rect, posts, flags, trap, stair | under the bar and the kitchen |
| `posts`, `beams` | free posts (on piers) and posts in a wall's line under a beam's end; beams by their ends, cut over each post | the gallery's posts and beams |
| `floors` | each floor: its level, rect, joists' direction, look, its rough part (finished plain), openings (a trap, with its leaves) | ground, three upper strips round the well |
| `walls` | outer walls by their line (the studs' outer face) and `out`, their top (`plate`, `gable` or a height), outside siding and wood, inside finish by level and stretch (`wainscot`, `boards`, `rough`), openings; partitions by their line, level, bearing, finish each side | four outer walls, eight partitions |
| `stairs` | each by its head's corner, the way it climbs, width, from and to, risers, going, rail side, posts under it, wood and look | the hall's, the outside stair, the back steps (and the cellar's) |
| `balconies` | posts, beams, ledgers on walls, decks (rect and joists), rails | the street balcony round the east corner |
| `galleries` | the well, its rails, their look | the gallery over the hall |
| `front` | the sign's text and height, the cornice | SALOON |
| `rooms` | each room's level, rect and use | 12, from the hall to the cellar |
| `fixtures`, `furniture` | kit props by id, place, facing, repeats; a table's chairs; furniture of members (`table`, `shelves`) | the bar and back bar in sections, 3 card tables, 14 chairs |
| `lamps` | sconces by wall, level, places along it, height; lamps on the tables and the bar; a chandelier | 31 OilLamps |
| `outbuildings` | each by kind, place, size | the outhouse |
| `use_points` | where people stand, sit, serve, work, sleep, watch and take cover; `seats` points at a kit prop's | 22, plus the tables' seats |
| `use` | how it's used day in day out (docs/briefs/lived-in.md): years in use; walking paths by level, who, passings a day and width; climbs a day on each stair; spots where people stand at a rail (`at`, `feet`); doors; spills; the kit's furniture; lamps' soot; weather (splash, bleach, streaks) | ten paths, four stairs, four spots, two spills |
| `past` | what happened, to what: each event's marks (`new`, `bullet` (`pried`, `filled`), `pale`, `holes`, `scrubbed`, `carved`, `scuff`...) at a point, within a reach, on members of given kinds | the 1880 brawl, the stag moved, the scrubbed floor, a thrown bottle, initials, a loose tread, the flood, the kicked kitchen door, a split tread |
| `materials` | which approved wood each surface takes | the interior woods inside, the exterior woods out |
| `sources` | the references the frame and sizes came from | Wood Handbook, Bell, Woodward, Tredgold, Hodgson |

## Bands: a second storey on the support ladder

A member rests on what it touches in a lower band, and within its band by StructureMember's tiers
(sill, post/joist, stud/floor board, plate/beam/ledger, rafter/cripple, board, trim). One ladder
was enough for one storey; a joist on a beam, a floor board on an upper joist, a partition's stud
on a floor board all need the band. The builder sets each assembly's band by what carries it:

| Band | What | Rests on |
| --- | --- | --- |
| 0 | foundation and cellar walls, piers, flags, wood sills, the gallery's posts, beams and brackets, the balcony's posts and beams, the outhouse | the ground |
| 1 | girders, ground floor joists and boards, the outer walls (studs, ribbons, plates, siding, finish, nailers, doors), ledgers, the false front | band 0 |
| 2 | what stands on the ground floor: partitions, the hall stair, the cellar stair, furniture of members | bands 0-1 |
| 3 | the upper floors and the balcony's decks, the gallery's and balcony's rails | bands 0-2 (ribbons, beams, the bearing partition's plate) |
| 4 | what stands on the upper floor: partitions, upper doors, the outside stairs | bands 0-3 |
| 5 | trusses (tie, principals, queen posts, purlins) | the outer walls' plates |
| 6 | common rafters, roof boards, the ridge cap, the chandelier | the purlins; the chandelier on a truss's tie |

## The framing rules the builder applies

- Joists at their spacing across a floor, each from support to support (a girder, a ribbon, a
  beam, a bearing partition's plate); a floor opening cuts the joists through it, with headers on
  the trimmers. An opening placed girder to girder needs no tail joists (the band ladder can't
  hang a tail from a header and still carry boards on it).
- Floor boards across the joists in stock lengths (~4.9 m), each joint on a joist, staggered.
- Studs at their spacing from the sill (outer walls: balloon, sill to plate) or the floor
  (partitions), king studs doubled beside each opening, headers, rough sills, cripples; plates and
  ribbons in stock lengths jointed over a stud, never over an opening.
- Inside finish boards on nailers (1x4 blocking flush between the studs); the wainscot, casings
  and picture rail as members drawn as woodwork (`PropKit.dress_member`).
- An upstairs partition stops 2 cm under the trusses' ties: trusses span wall to wall.
- Every lamp an OilLamp standing on a member (a sconce's bracket, a table, the bar, the
  chandelier's rim); every stair's walking ramp goes when its stringers do.

## The marks (`marks.gd`)

After the build, the lived-in pass turns `use` and `past` into marks on the members they reach
(each member's meta `marks`: `{kind, s, cause}` and where on it: `along` a stretch of its length,
or `at` a point within `r`; nothing marks a member without a cause). Nothing is drawn yet: the
woods' shader draws them after Gate A (docs/briefs/lived-in.md). `render.gd --wear` draws the
wear map (members tinted by their marks) for judging the placement.

## The checks (`checks.gd`, `tests/test_building_lab.gd`, `run.gd`)

| Brief's check | How |
| --- | --- |
| It stands | every member has a load path; none over its limit under its own weight, nor with a crowd on every floor (40 lb/ft2; 60 on the balcony and galleries) |
| It falls right | each post knocked out by the rules (what loses its path, what's over), and one for real with physics (nothing left floating) |
| People fit | each door 0.76 x 1.98 m or more and clear of members; 2 m of head room up each stair; each use point on a floor, with room for a man, not on a step or in a doorway |
| It's used | each room has its people's use points; the barman's between the bar and the back bar; seats at the tables |
| It burns and breaks | a fire lit by the bar spreads; balls carve the bar, a post, a wall, the rail, a chair; a stick of dynamite in the hall |
| Everything in it is destructible | the walk: every node under the building that collides or draws is a member, a kit prop's member, a fitting's, or one of `Checks.EXCEPTIONS` (each with its owner) |
| It fits the budget | draw calls counted (batches, own meshes, lamps); physics and process time standing with every lamp lit; the render CPU needs a render run |
| It matches the target | `render.gd` draws the sheet's views and Sean's picture's in the game's street, for the blind critic |
| It's of its time | the sources; the conflicts settled by Sean |
| Lived in (docs/briefs/lived-in.md) | every use and past event marks members, every mark of a known kind, the door's path worn and the quiet corner not, every tread of the stair worn, one replaced baluster |

## What using it for real needs (before it replaces `SaloonBuilding`)

See README.md, "What the format needs".
