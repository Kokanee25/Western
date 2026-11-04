# The trestle lab: a towering timber viaduct, its destruction, and the train falling with it

Issue #623 (Sean, 2026-11-03); the plan is #542 (the trestle, after step 5) and #466 (the last
act). The lab is `experiments/trestle_lab/`; the part is `src/train/trestle.gd` (`Trestle`, dials
`TrestleTuning`, `config/trestle.tres`). Nothing in the town changes.

## Goal

The game's biggest moment (Sean: "the one *oh my god that's awesome* moment"): a towering timber
viaduct across a deep gorge, the tallest and longest structure in the game, that the player can
bring down under the train. Systems, not a script: the bridge is members in one support graph
(`Structure`/`StructureMember`, never a second system), the train's weight goes into it as it
crosses, charges cut posts and the load paths decide what falls, a light charge leaves it standing
empty and the engine finishes it, and when the deck goes from under a truck the train hands off to
Jolt (step 5's `TrainWreck`) with its momentum. "Performance never fakes the game": every frame of
a collapse is measured against #492's gate.

## References (period practice; each number a proposed dial)

- **Scale** (Sean's, #623: 60-75 m high, 250-350 m long, curving slightly): the Erie's **Portage
  Viaduct** over the Genesee (1852; ~234 ft / 71 m high, 800-900 ft long, all timber on stone
  piers; burned 1875), and the Union Pacific's **Dale Creek** trestle (1868; ~126 ft high, 650 ft
  long). Wikipedia "Portage Viaduct"; structurae.net's entries. The lab's: 66 m from the gorge
  floor to the rail at the middle, 300 m long, on a 900 m curve.
- **Framed bents:** posts and sills 12 x 12 in, caps 12 x 14 in, sway and longitudinal braces
  3 x 10 in (the NMRA's data sheet D6b3, framed trestles, compiled from railroad standard plans);
  bents 10-16 ft apart (16 ft here, the fewest members); a bent split into stories by
  intermediate sills once it passes 16-20 ft (20 ft stories here).
- **Deck:** stringers two chords of 8 x 16 in a rail, ties 6 x 8 in, guard timbers 6 x 8 in (the
  Elgin & Belvidere Electric Railway's 1907 trestle standard). Stringers two panels long with their
  joints broken (period practice in W. C. Foster, *A Treatise on Wooden Trestle Bridges*, 1891:
  its table of contents covers framed bents, the floor system and bracing; the text itself
  wasn't reachable from this session: archive.org and distantreader.org are outside its network
  policy). The line's own ties and rails (step 5's sizes) are kept on the bridge, so the track's
  state and the derail read them as anywhere on the line.
- **Batter:** the outer posts lean 1.5 in a foot (proposed; 1-3 in a foot is the usual range for
  framed bents), so a 66 m bent is ~20 m wide at its foot: Portage-like towers.
- **Timber strengths:** the game's (`config/timber.tres`, the USDA Wood Handbook's figures cut
  down for rough stock).

## How it's built (`Trestle`)

A `TrackChunk` over the crossing's stretch (so its ties and rails are the line's: the track's
state, a charge, the derail all read them as anywhere), and under them, from the route's crossing
and the ground under each panel point: per bent a stone pier, a mud sill, stories of posts counted
down from the cap (a story's top at the same height in every bent, so girts run level), outer
posts battered, plumb inner posts and more plumb lines where it's wide, an intermediate sill
between stories, X sway braces on both faces; girts and longitudinal X braces bent to bent;
two-panel stringers in two chords a rail, joints broken; stone abutments on the rims; guard
timbers. The links are set as framed (no search by pairs). The route names the crossing
(`"crossings"`, TrainRoute), so the bridge moves with the line; `TrackLine` lays no fill under it.

## What done looks like (the issue's proof)

- A sheet: golden hour and night, from the gorge floor, the rim a few hundred metres off, the deck.
- Its member count, node count, idle cost (with the train crossing and without).
- Films: the train crossing whole; one bent blown with no train; a light charge then the engine;
  the train going over at line speed from the floor, the far rim and the coach's platform; the
  coach full (`Seating`).
- A frame table of every collapse against #492's gate (one hitch under ~100 ms at Sean's, back
  above 50 fps within half a second), headless at Sean's clock, with piece and body counts.
- Tests: it stands; a crossing breaks nothing; cut posts fall by the support graph; a light charge
  holds empty and fails under the engine; the hand-off keeps momentum; save and load keep the wreck.

## How it's judged

By the numbers (the frame table, the member count and idle cost, the tests), then by Sean's eye on
the films and the sheet. Every number is a proposed dial: the height and length, the timber
sizes, how big a charge brings a bent down, whether the train should break up more or less.

## Results

`experiments/trestle_lab/results/` (one folder a round); the README there says how to run it.
