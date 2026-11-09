# The Bridge Is Out (`the-bridge-is-out`)

Other names: "the trestle finale" (`config/valley.json` `trestle_finale`), "the train of hired guns
and the trestle (the last act)" (#466), "the near end game with the army train" (#623). Sources:
#466 and comments; #623; #638; #658 and comments; #542; #546; `docs/briefs/trestle.md`;
`docs/briefs/valley-plan.md` §10.

- DECIDED (Sean, 2026-11-09, #466): "this mission's name is 'The Bridge Is Out' (the trestle
  finale)."
- DECIDED (Sean, 2026-11-03, #623): "the tracks and rail and bridge all need to break for the near end
  game with the army train." (#466, 2026-11-03): "the one oh my god that's awesome moment".
- DECIDED (#546, Sean 2026-11-04): "**the finale goes past the trestle**" (the raid on the Baron's
  house comes after it; `barons-house`).
- PROPOSED: #466 carries the label `idea` and "**After the demo.**"

## How you hear of it

- OPEN: no source says how Harlan learns the train is coming or what it carries.
- PROPOSED (#546, 2026-11-01): "The finale comes when the threads are ready, not on a date: the
  trestle and the train (#466) once Vale and Rourke's thread reaches it."

## The situation

- PROPOSED (#466): a special train of hired guns (the cattle baron's and the railroad's men, perhaps
  a bought army officer and his men "to make it look lawful") comes to take the town down. Historical
  basis: the Johnson County War, 1892.
- PROPOSED (#466 comment, 2026-11-01; #542): it is the same daily train the player has seen all game;
  the soldiers and hired guns sit in the coach.
- PROPOSED (#546 P4, not accepted): "Rourke as Harlan's mirror. The final confrontation opens with
  Rourke's words from the opening dream ('Do your duty, Sergeant'), offering the same bargain as
  before. Harlan's answer is the real climax. The trestle is its consequence."

## The ways to do it

- PROPOSED (#466): blow the trestle as the train crosses; or "stopping it another way, the men getting
  off at the depot, or the town choosing a side".
- PROPOSED (#546 P4): "A real choice: blow the bridge, or use the Baron's evidence to turn the soldiers
  and stop the train another way."
- DECIDED (Sean, 2026-11-04, #658 comment): "that is of course all dependent on how the bridge is
  destroyed - the player still has to do a proper job of it".
- DECIDED (`valley.json`, as recorded): "structural damage and train loads, never scripted".
- DECIDED (#546, Sean 2026-11-04): "**charge sizes as progression.** Single sticks earlier (from the
  miner), bundles at the end."

## The big choice and its cost

- PROPOSED (P4): blow the bridge (the men aboard die) or turn the soldiers with the Baron's evidence.
- OPEN: "Rourke's fate and the soldiers' outcome stay open" (#546, 2026-11-04).
- PROPOSED (#546 P5, not accepted): "After the trestle, the town holds an inquest into the deaths,
  **with Harlan the one judged.**" (`the-trial`)

## What happens after, in the world

- DECIDED: the raid on the Baron's house follows (`barons-house`).
- PROPOSED (#546): "After the ending, the town goes on (free roam)"; listed among the open questions.
- PROPOSED: the wreck stays (train step 5 saves `TrainWreck` by route place, #616).

## Where on the map

- DECIDED (`valley.json`): Bridge C, "the great trestle", 130 m, rail ~27 m over the creek, east of
  the depot, west of the overpass; viewpoints `vp_trestle_overlook` (1120, 180), `vp_east_rim_north`
  (1280, -300), `vp_canyon_floor` (1163, 15).
- PROPOSED (valley-plan §10): "the canyon floor from Bridge A or the mouth to reach the bents; the
  train seen every day from town and the East Road."

## Which threads it moves

_PROPOSED: this session's mapping from the sources (threads in `MAP.md`); lines without a status word are that mapping._

- Rourke and the train; the Baron (or Vale; see `MAP.md`); Harlan's past (PROPOSED P2, P4); the
  soldiers ("orders built on lies", P1). It is the last act.

## Which systems it needs

_PROPOSED: this session's reading of what the ways above need. Each line ends with its state on main, 2026-11-09: exists, partly, being built, decided (not built) or new._

- The trestle as members, its collapse by load paths (`Trestle`, `TrackChunk`): exists (#623, #637;
  round 2).
- Rails torn at the hole, the train flying coupled until it lands (#658, round 3): being built.
- Dynamite bundles and the plunger box (#647, #648): exists.
- `TrainWreck`, `TrainLookout`, the timetable: exists.
- Soldiers and hired guns riding and fighting from a train: new (seating exists).
- Turning soldiers with evidence (talk, evidence, nerve): new.
- The frame gate during collapse (#638: "Accept the ~1 s dip under 50 fps"): measured.

## Where the sources disagree

- OPEN: size. #466/#623: 60–75 m high, 250–350 m long. #638 (Sean, 2026-11-04): "toooo big"; round 2:
  ~130 m, rail ~27 m over a river. `valley.json` follows round 2.
- OPEN: timing. #466 body: day 30 (DESIGN.md §5). #546 (Sean, 2026-11-01): no day count; "when its
  thread is ready".
- OPEN: who's aboard: hired guns plus perhaps a bought officer (#466) / "the army train" (#623) / "the
  hired guns and soldiers" (#542).
- OPEN: whose thread: "Vale and Rourke's" (#546 body) / the Baron (later #546 comments, #736).
- OPEN (Sean, 2026-11-04, #658 comment 2): "if you put enough bundles at the base maybe it bends the
  tracks above enough to have it dip down? Or how would it actually behave? Could the tracks come
  apart?"

## Sources

#466 (2026-10-28) and comments (2026-11-01, 11-03, 11-09); #623; #638; #658; #542; #546;
`docs/briefs/trestle.md`; `config/valley.json`; `docs/briefs/valley-plan.md` §10.
