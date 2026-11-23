# The undertaker's (#1141)

14 Undertaker, the east end of Main Street's north side (`config/valley.json` town.north `undertaker`):
an 1882 undertaker and cabinetmaker with a period-true, walkable cellar. Sean's brief is #1141's body.

## Step 1: the target sheet (waiting on Sean's OK of the cost)

`sheet/request.json`: twelve views (front, plan with the cellar's, the east yard with the side door and
bulkhead, the back and hearse shed, the cutaway with the cellar, showroom, parlour, workroom, the cellar
stair, the embalming room, the ice room, the coffin store), ~$0.14 each, about **$1.70**, cap $2.50.
Not painted yet. The workflow (`building_sheet.yml`) fires only on a `claude/art-building-*` branch: push
the request there once Sean says yes, merge the panels back.

## What the lot gives (probed 2026-11-23 from `config/valley_ground/heights.r16.gz`)

- The lot: x 106.0-128.0 (22 m, 72 ft), the front at z -10.05, depth 18 (to z -28); the back street at
  z -48. It faces south (facing 180): **its x runs from its EAST corner** (RECIPE step 2).
- The ground falls east ~0.12 m across the lot and rises to the back: about -0.40 m at the front's middle,
  -0.05 at z -20, +0.20 at z -28, +1.3 at z -40. The walk's top (`h` 1.15) puts the floor near world +0.75:
  1.15 m over the dirt at the front, ~0.55 m at the back. A cellar 2.4 m under the floor is ~1.3 m below
  the dirt at the front and ~1.9 m at the back: the bulkhead's steps want ~4 risers at the back, ~3 at the
  front. Plan: the building on the lot's west (against the junk alley, x 106-115.75, 32 ft), the yard east
  with a wagon gate to the street, the hearse shed at the yard's back, the walk's `span` the building's.
- Neighbours: the junk alley (`alley_n8`, crates across it 6-9 m back) and the barber west; nothing east
  (Main Street ends at x 130).

## How the town uses him today

- The undertaker (`config/valley_folk.json` `undertaker`) works by day at `undertaker_walk` (the lot's
  [5.0, -1.2], tool `bench`: planing on the walk) and eats and sleeps `in` the lot. Earl and the dead go
  "to the undertaker's" as a story fact and leave the world (`ValleyFolk.to_undertaker`): no body is laid
  in the building yet. The parlour's bier and the cellar's sheeted board are where a body could lie
  (gameplay's to wire, after the building).

## Period notes for the props (checked against what's known; the archives are blocked here)

- Arterial embalming spread after the Civil War; in 1882 it was often done at the dead man's house, but an
  undertaker's own room in a town is right. Tables then were wood (a cooling board of slats or cane on
  trestles; a board table with a zinc-lined, sloped top and a drain). Porcelain tables are 1890s on.
- Fluids in glass carboys and bottles (arsenic and zinc chloride solutions in the 1880s); a hand pump and
  rubber tubes, a gravity bottle.
- Ice: corpse coolers (a box with an ice pan over the chest) were sold from the 1870s; ice cut in winter
  and kept in sawdust.
- Coffins: the six-sided "toe-pincher" still common in the West, rectangular caskets coming in; a child's
  often white.
- Safety coffins: many patents 1850s-1890s, a bell on a frame at the grave's head with a cord to the hand.
  A sample one in a town undertaker's cellar is plausible, not common.
- Hair wreaths: Victorian mourning work, framed under glass: true.
- **The posing stand:** photographers' iron stands held living sitters still for long exposures; that they
  propped up the dead is mostly a modern myth. It stands by the stair as the photographer's kit, with a
  draped chair, never with a body in it.
