# The Baron's Shipment, version 2: a proposal (`barons-shipment`)

**A proposal by this planning session (2026-11-09), for Sean.** Everything here is PROPOSED unless it is
marked DECIDED with Sean's words. It keeps the decided parts of the card (`../barons-shipment.md`) and
adds what the judge found missing (`../judged/2026-11-09.md`: 20/35; "no person at the centre of the
choice", "the showpiece's whole chain is new and mostly one-off"). It is designed to be built on what
exists, after the build checks: the train's 1D-on-a-curve mover, `TrainWreck`'s hand-off to rigid bodies,
`LooseProp`'s dents, members that a ball or a kick breaks, arrest and follow.

- DECIDED (Sean, 2026-11-09, #736): "a must-have spot for the armoured wagon heist": the Baron's
  iron-plated coach carries his papers; "The player releases a big log from above. It rolls or swings
  down, knocks the iron-plated wagon over, and **dents its plates**."
- DECIDED (inventory, "Locked mission"): "Harlan and Joe plan a disguised robbery"; approaches
  "impersonation, disguises, a prepared ambush or direct interception"; "The objective is to recover the
  documents, not simply eliminate the guards"; it connects the Baron to Rourke.
- OPEN (Sean, 2026-11-09): what the papers are; the evidence and the trial are "a maybe".

## How you hear of it

PROPOSED: three ways, and the place shows the showpiece itself.
- **You've seen it.** On ordinary days the plated coach rolls between the Baron's ranch and his town
  house, four horses, a driver, two riflemen on top. Anyone on the road sees it pass.
- **Joe's plan** (#738, proposed): Joe pitches the log once. Without Joe, the place does it (below).
- **The run day.** The coach is shod and loaded the day before a run: the blacksmith says so, and the
  driver drinks in town that night and talks.
- **The place.** Above the slow bend on the ranch's canyon road the Baron's men have decked logs for his
  flume (the water he's taking, `dry-creek`), held by stakes and a chain. Anyone on the road below looks
  up at them.

## The situation

- PROPOSED: the coach carries the strongbox **and the Baron's bookkeeper**, the one man who can read the
  ledger: the Baron keeps it in his own cipher of initials and sums. With him it's a record; without him
  it's columns of figures.
- PROPOSED: the driver is a townsman the player knows (from the town's people); the riflemen are the
  Baron's hired men.
- DECIDED (#736): the coach is iron-plated (the Deadwood stage line's *Monitor*, 1878, is the period's
  own plated coach); the log dents the plates.

## The ways to do it

PROPOSED. One log, three timings; two more ways that need no log.
1. **The log on the coach** (the showpiece): break the stakes (a shot through a stake, or a kick) as the
   coach slows into the bend; the log rolls down, strikes, dents the plates, the coach goes over. The
   riflemen are thrown and dazed; the driver may be crushed. Timing is the skill.
2. **The log across the road:** release it before the coach comes. It blocks the bend; the coach stops;
   the riflemen climb down to clear it with the driver. Then: hold them up, slip round to the strongbox,
   or fight on the ground.
3. **The log too late:** it misses, or catches the team; the coach runs on, the riflemen awake. A
   running fight, or let it go.
4. **Hold it up on the road** without the log: in the open, at the bend, against two rifles on the roof.
5. **Let it go home and follow:** the papers and the bookkeeper go to the Baron's town house, where they
   are at the raid (`barons-house`): better guarded then, but no fight on the road now.

## The big choice and its cost

PROPOSED: the bookkeeper, with no clean answer.
- **Take him alive** and the ledger can be read, but he has to be kept alive and walked to town under the
  Baron's guns; the Baron's men come for him, and a frightened man may lie.
- **Take only the ledger** and nobody is at risk, but it's half a record: figures without names.
- **The driver** is a man from town: the log's fastest way can kill him, and the town will know who
  dropped it.

## What happens after, in the world

PROPOSED, in what the game can carry now and what waits for saves:
- **Now:** the tipped, dented coach stays in the ditch where it fell (a rigid body, as the train's
  wreck); the riflemen who saw Harlan's face remember it; the bookkeeper walks with Harlan or doesn't;
  the driver lives or is carried to the doctor's.
- **Later (needs story state):** the Baron's next run has more outriders or takes the South Road; the
  bookkeeper, if kept, names the payments (to the gang, to Rourke) when the threads need it; the town's
  view of Harlan follows the driver's fate.

## Where on the map

- PROPOSED: the slow bend on the ranch's canyon road (`ranch_canyon_road`, `baron_ranch` (1320, 1260)
  north to Bridge A (965, 288)), under a cut bank with the flume timber decked above; "away from town,
  where help can't arrive fast" (DECIDED, #736). An outcrop opposite to watch from; a way out over the
  rimrock trail (#736 A.2).

## Which threads it moves

- T4 the Baron (the ledger, the payments); T5 Rourke (his name in the sums); T2 Joe (his plan, if alive);
  `dry-creek` (the flume timber, the water).

## Which systems it needs

PROPOSED, each built on what exists (to be confirmed by the build check):
- The coach on the road as a 1D mover on a curve, as the train runs on its track (`TrainSim`,
  `TrackLine`): one car, four horses drawn with it.
- The hand-off to rigid bodies when the log strikes, as `TrainWreck` does for a derail; the traces part
  and the team stands (no running horses needed).
- The log as a heavy rigid body on the bank, held by stake members that a ball or a kick breaks (members
  break today; `PlayerShove`'s kick).
- Dents in the plates, as `LooseProp` dents a cup (the mesh copied and pushed in), on the coach's plate
  pieces.
- The strongbox (shared with Hell on Wheels' payroll).
- The bookkeeper walking with Harlan (arrest and follow, today the gang's; for a civilian).
- Carrying the ledger (new, shared with every paper in the game).
- People on the road and the driver's talk (needs the valley's people).

## True to 1882 (to check)

- The Deadwood stage line's steel-lined *Monitor* (1878).
- Log decks held by stakes and chains, released by knocking the stakes out: period logging practice.
- A ledger kept in private abbreviations or a simple cipher: plausible for a man hiding payments; check.

## Where the sources disagree

- OPEN: the trap: a log deck released from a bank (#736, used here) / a timber swung from a tree, rigged
  in a fade (#546). This proposal takes #736's.
- OPEN: who proposes it: Joe or the miner (#546) / Joe (#738); the place shows it either way.
- OPEN: "impersonation, disguises" (inventory): no disguise system exists; this proposal leaves them for
  when one does.
