# Hell on Wheels (`hell-on-wheels`)

Other names: "the runaway" (#542 step 7), "Runaway Payroll Train" (`config/valley.json`
`runaway_payroll`). Sources: #542 body and comments (Sean, 2026-11-01; name 2026-11-09);
`docs/briefs/valley-plan.md` §4; #546 P9 (Sean, 2026-11-07); #276 (2026-11-07); PR #621 `valley.md`.

- DECIDED (Sean, 2026-11-09, #542 comment): "the runaway train mission (step 7: tracks out, fight
  through the cars, stop it before it derails) is named 'Hell on Wheels'."
- DECIDED as #542 records "What Sean wants" (2026-11-01): "**A mission: the runaway, with the tracks
  out.** The player fights his way through the moving train to the cab and stops it before it
  derails. Physics decides, not a script".
- DECIDED as `config/valley.json` records it: "board by the overpass, fight back to front, stop before
  the broken track".
- PROPOSED (#542): step 7, "After the trestle lab".

## How you hear of it

- PROPOSED (#546 P9, Sean's example, 2026-11-07): "you've dealt with the men who blew the track, you
  race to the train, climb aboard and find it being robbed: *'Now what the hell is going on here?'*"
- OPEN: how Harlan learns the track is out or the train taken.

## The situation

- DECIDED (#542): the tracks are out ahead and the train is running toward the break.
- DECIDED (Sean, 2026-11-01, #552): the train is "engine and tender, two ore cars, a boxcar, an express
  car (payroll and guard), a coach".
- PROPOSED (#542): "the **payroll comes on the train** (an express or payroll car) ... A car worth
  robbing is a ready-made target and mission."
- PROPOSED (#276 comment, 2026-11-07): "a man alone practising his stick-up ... Later he's in the train
  robbery" (arrest him and the gang is a man short; follow him to the gang's camp; or recognise him on
  the train).
- OPEN: who started the runaway and why (robbers, the gang, the Baron's men).

## The ways to do it

- DECIDED (#542, valley.json): fight back to front through the moving train to the cab and brake.
- DECIDED (Sean, 2026-11-01, #542): "**The whole train is walkable, back to front** ... through the
  coach and express car by their end doors and platforms, over the boxcar's roof by its ladders and
  roof walk, across or along the ore cars, over the tender to the cab".
- PROPOSED (valley-plan §4): board from the overpass deck (2.0 m to the coach roof, 2.4 m to the
  boxcar, 3.8 m into an ore car); 679 m to the trestle, "1:51 at 22 km/h"; a full stop "54 m from 22
  km/h, 109 m from 32 and 166 m from 40".
- PROPOSED (valley-plan §4): "Where the gang breaks the track is the mission's choice (the trestle's
  approach, or past it toward town)."
- OPEN: a second way that really differs from fighting through (e.g. uncoupling, getting ahead of it,
  stopping it from the ground). No source names one.

## The big choice and its cost

- DECIDED (#542): "brake far enough before the break and it stops; too late and it derails for real."
- OPEN: no source names a choice beyond succeeding or failing (e.g. the payroll or the passengers).

## What happens after, in the world

- PROPOSED (#542 step 5, built): "the wreck persists; the repair crew comes and fixes it."
- OPEN: the payroll (saved, stolen) and payday (#276); the robbers caught, dead or gone.

## Where on the map

- PROPOSED (`valley.json`): `bridge_b` the overpass (1912, -229), deck 11.2, the rail cut under it at
  5.7; `bridge_c` the trestle; `depot` (61, -63).
- DECIDED (PR #621 `valley.md`, Sean's lock 2026-11-03): the overpass is "later ... a possible boarding
  point in the Payroll Train mission".

## Which threads it moves

_PROPOSED: this session's mapping from the sources (threads in `MAP.md`); lines without a status word are that mapping._

- Rourke and the train (PROPOSED); the gang (the stick-up man, PROPOSED); payday and the town's money.

## Which systems it needs

_PROPOSED: this session's reading of what the ways above need. Each line ends with its state on main, 2026-11-09: exists, partly, being built, decided (not built) or new._

- The 1D train, couplers, timetable, engineer (steps 1–2): exists.
- Walkable moving cars, ladders, roof walk (`TrainCars`, `Ladder`): exists.
- Breakable track, derail, `TrainWreck` (step 5): exists.
- Men fighting and taking cover on a moving car, crossing between cars: new (step 7).
- Cab controls the player can use (regulator, brake, reverser): new (step 7).
- A man thrown off at speed: partly (ragdoll, `keep_stride`).
- The express car's strongbox and guard: models exist (step 3); the robbery as a gang plan: new.
- Harlan's rare lines (P9, PROPOSED): new.

## Where the sources disagree

- OPEN: whether the train robbery (P9, #276's stick-up man, the express car "worth robbing") is this
  mission or a separate one. The sources place them on the same train; none says they are one mission.

## Sources

#542 body and comments; #552; #546 P9 (2026-11-07); #276 comment 2026-11-07; `config/valley.json`;
`docs/briefs/valley-plan.md` §4; PR #621 `docs/briefs/valley.md`.
