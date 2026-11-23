# Saving by sleeping

Issue #1138 (step 1), the slice's "Saving by sleeping" (#953). DESIGN.md §3: **only when you sleep in a
bed**; "Persistent rubble": the save records only the difference from the original town. ROADMAP 5.5
(the outcome survives sleeping, quitting and loading) and 6.6 (a soak with saves and loads).

**Step 1 (built):** what a save holds, written to one file and read back whole into a valley built
fresh. **Step 2 (built, #1148):** sleeping in a bed ends the day, saves, wakes you at dawn; Continue at
the start. **Step 3 (built, #1154):** a hurt townsman stays hurt indoors, overnight and across a load;
your horse where you tied him.

## Step 2: sleeping, Continue (#1148)

- **A bed** is any node in the group `beds`: every spec building's use point with `use: sleep` (the
  doctor's cot, the jail's bunk, saloon B's lodgers' beds). Harlan's cabin (#1126) isn't on main yet:
  once its spec has a `sleep` use point it's a bed with nothing more to do.
- **E at a bed** (`PlayerSleep`): the screen fades out; the clock goes on to the next 06:00
  (`hours_to_dawn`; under an hour to go, the dawn after); blood and floor marks dry and each hour and
  midnight are announced (`DayCycle.pass_hours`), so the news goes overnight and the folk are placed by
  their day; `Events.hours_passed(h, &"sleep")` mends you (`PlayerWounds.mend_hours`) and runs a hurt
  townsman's wounds on; the town is given a dozen frames to place itself; **then the save, taken after
  the night** (a load puts you at dawn, up where you lay down, guns away); the fade in, a line: "You
  sleep till dawn. Day N, 06:00. Saved."
- **Refused, with a line on screen:** bleeding ("bind it before you lie down"); a man by the collar or
  a chair; a shot fired within 60 m in the last 30 s, yours too ("Not with shooting this close."); an outlaw on his
  feet within 60 m who has you as his target or as a threat, or Joe turned; a scene in play (a Moment
  not done). Any hour is allowed: from noon you sleep 18 hours.
- **Continue** (`ContinueCard`; there's no title screen): the plain valley start with a save in
  `slot1` shows a card (Enter: Continue, day and hour; Space: a new game). Continue reads the save,
  clears the world's statics and puts its story back (a retry's shape), reloads the scene; the valley
  puts the save on under black once its folk are in and lifts the black. A command line's mission and a
  retry's flag don't start on a load. A new game leaves the save alone; only your next sleep writes
  over it (the one before kept as `.bak`). **Quitting doesn't save.**
- **Measured** (this workspace): a sleep's capture and write are in the PR; a load onto the fresh valley
  as step 1's.
- **The playtest** (`docs/playtests/2026-11-22.md`): sleep and Continue gave back the same world (the
  dead where he lay, the blood, the clock, the gun's rounds; load 77 ms, nothing missed). Fixed from it:
  your own shot now refuses a sleep; who died in the night is said on waking. Not fixed: the valley
  jail's bed couldn't be walked to (art's building); under the bridge the world is the old town unless
  `--world=valley` (it has no beds).
- **The town overnight:** see step 3: a hurt man stays hurt; the dead stay dead.

## Step 3: hurt men indoors, the horse (#1154)

- **A hurt man indoors** (`ValleyFolk.kept`): a day man alive and hurt (a wound on him, bleeding, blood lost,
  out cold) as he goes in (`_gone`) leaves his body's state on the book (`HumanBody.save_dict`, his model and
  seed, `since`: the absolute clock hour his wounds have run to). His wounds run on by the clock while he's in
  (a `Physiology` of his made from the book's, `pass_time`): on every `hours_passed` (a sleep, a ride, you out
  cold) and when he's brought, so a clock jump never skips them. Brought out (`_bring`, `seize`, `borrow`:
  `_put_back`), his state goes on the new body (`load_dict`, standing where he's brought, not limp), his brain
  told he's been hurt all along (no fresh fright). Saved with the book (`save_dict`'s `kept`).
- **A bad wound, decided:** a man who **can't stand** when his day would bring him out (`Physiology.can_stand`:
  a broken pelvis, a leg that won't hold, out cold, deep shock) **stays in**, laid up where he went, his row
  on the book unchanged, till he can. One whose wounds **kill him in there is dead by morning**: never
  brought out (`buried`, `gone_for_good`), the story's `death.<id>` ("dead of his wounds at ..."),
  `ValleyFolk.died_indoors`, and a sleep names him on waking. Not done: the doctor doesn't come to him or
  take him in (his doctor's cot); nobody carries his body; the news isn't told of it.
- **Your horse** (`RideThere.save_dict`/`load_dict`, SaveGame's `horse` section): the rail he's tied at. A
  load stands him there (at once, or when he's made, `_horse_soon`). The places you know are story facts.
- **Mission casts across a sleep:** none to do. No slice mission can be slept across with its cast alive:
  every mission's living cast is inside a Moment (sleep refused) or is started only by a `--mission=` flag
  or the act before it (the list below).
- **Beds on foot** (the playtest: the valley jail's couldn't be reached, art's building): walked through the
  bridge from the front doors, the doctor's two cots and his own bed (by the hall's doors) and saloon B's
  lodgers' beds (up the stair hall's stair) are all reachable. Saloon B's plank beds were taken as chairs (E
  sat you on them, no sleep offered): `PlayerSeat.chair_here` now passes over a bed prop;
  `test_every_bed_offers_the_sleep` holds it.

### The missions across a sleep (what a load brings back from the story's facts alone)

- **The sheriff on the road** (day 1's dawn): started only by `--mission=sheriff`; nothing in play
  starts it, so a load never does. What it leaves (`sheriff.care`, `sheriff.blood_loss`) is in the
  story and No Law's day 2 reads it.
- **No Law's night (the murder, the carry):** ValleyFolk starts the murder from the clock and the story
  (no `nolaw.murder` yet, at 22:00 or after your hands at the table). Slept through before it, it plays
  the next night: a load brings it back as it stood. You can't sleep in it (a Moment).
- **No Law's morning, the sheriff's death, the funeral:** ValleyFolk starts each from the clock and the
  facts (`nolaw.morning`, `sheriff_from`, `nolaw.sheriff` and when it was set, `funeral`'s hours): a load
  between them brings the next one on as it would have come. Nothing to wire.
- **No Justice** (camp, hideout, cabin): started only by its `--mission=` flags or the act before it;
  there's no start in play after the funeral yet, so a load between No Law and No Justice brings nothing
  back (nor would playing on). Its retry flag (`NoJusticeHideout.retry_on_load`) isn't taken on a load.
- `SaveGame.apply`'s `missed` is empty for a sleep between missions (the test holds it): no mission's
  cast is in the world then.

## On one screen

- `SaveGame` (`src/save/save_game.gd`): `capture(tree)` takes the world as one dictionary, `write(d,
  slot)` puts it in `user://saves/<slot>.save`, `read(slot)` gets it back, `apply(tree, d)` puts it on a
  valley built fresh and says what it couldn't place. `differences(a, b)` compares two captures.
- **The file:** a first line of JSON anyone can read (version, day, hour, world, when written), then the
  dictionary in Godot's own binary form, compressed. Written to a temp file and renamed; the save it
  replaces is kept as `.bak`, and a file cut short or spoilt falls back to it. Version 1;
  `SaveGame.MIGRATIONS` brings an older one up a version at a time; a newer build's save isn't loaded.
- **Each system keeps its own state** (`to_dict`/`from_dict` or `save_dict`/`load_dict` on it). SaveGame
  only gathers them, in an order that works: story, clock, structures, ground, floor, blood, dynamite,
  the town's day, people, you.
- **Measured** (the valley, this workspace's 2.1 GHz core; Sean's is about 0.65 of it): an untouched
  valley saves in about 60-80 ms into 2.5 KB. After a charge against the general store (300 members
  broken, a man dead, another shot): capture 80-140 ms, write 6-10 ms, 104 KB; putting it back
  280-360 ms, nearly all of it the structures. All of it is hidden by a sleep's fade; none of it is
  spread over frames yet.
- **Held by** `tests/test_save_game.gd` (7 tests): the file, a structure, a man, the marks and blood,
  and the whole valley changed, saved, read into a new valley and compared system by system.

## What a save holds

"Size" is in the 104 KB save above, or what one entry costs. "Authored" = built the same every time
from data, so not saved.

| What | Where it lives | Kept as | Size | Authored or changed |
|---|---|---|---|---|
| The story's facts, when each was set, the checkpoint | `StoryState` (static) | the three dictionaries | bytes a fact | changed |
| The clock: hour, day, rate, held | `DayCycle` | four numbers | bytes | changed |
| Broken members | `Structure.to_dict` `broken` | member ids | ~40 bytes each | changed; only structures something's happened to (`maybe_changed`) |
| Bullet holes and carved wood | `StructureMember.holes` | entry, exit, radius, spall per hole, in order | ~60 bytes a hole | changed; the voxels are carved again in the same order with the same seeds (`restore_holes`) |
| Cut members | `cut` meta | the stretch cut, per member | bytes | changed; cut again quietly, the ends stand as `<id>/a`, `/b` |
| Rubble: where each piece lies | `Structure.rubble` | members, transform; a part of a member (a snapped half, a cut's short piece) its length too | ~120 bytes a piece | changed; laid asleep |
| Char, water, burnt away, alight | members' fire fields | four values per member the fire touched | bytes | changed |
| Dents, torn plates | `Dents.state` | as it was | small | changed |
| A kit prop knocked over | `KitProp.loose` | a flag; its pieces are rubble | bytes | changed |
| Dug ground | `Ground.to_dict` (the old town's) | tiles' heights, deflated | small | changed; **the valley's ground has none yet** |
| Floor marks (dirt, mud, liquid, stains) | `FloorMarks.cells` | the cells | ~80 bytes a cell | changed |
| Blood on the ground | `Blood` (static, 160 at most) | place, ml, length, how dry | ~100 bytes a mark | changed |
| Dynamite lying, planted or wired | `DynamiteStick.save_all` | as it was | small | changed |
| The town's day: who's a body and who's on the book, the dead, the buried, who's laid out, who an act sent off, your hands at cards | `ValleyFolk.save_dict` | ids and rows | ~1 KB | changed; the schedule itself is authored |
| A hurt man indoors: his body as he went in, his wounds run to when | `ValleyFolk.kept` | `HumanBody.save_dict` a man, `since` | ~4 KB a man | changed |
| Where your horse is tied | `RideThere.save_dict` | the rail's id | bytes | changed |
| The town's news (#1051): every record, everyone's version, what's been said; the dead not yet taken away | `TownNews.save_dict`, `ValleyFolk.dead_out` | as they are; frames as how long ago | ~200 bytes a record and version | changed |
| Each person in the world: where, his body (blood, bleeds, bones, infections, dead or alive), every wound, the holes in him and his clothes, dressings, limbs off, and limp, how every part of him lies | `HumanBody.save_dict` | per person, by `person_id` | ~3 KB alive and unhurt, ~8 KB shot dead | changed; who he is and what he wears are authored (a dead man no roster makes keeps `made`, enough to make his body again) |
| His dropped gun | `HumanBody.dropped_gun` | where it lies | bytes | changed |
| His mind: fear, still shaken since when, turned on you (Joe), what he thinks of each person | the brain, `Reaction`, `Relations.to_dict` | a few numbers a person | ~100 bytes | changed |
| You: where, where you look, your body and wounds and mending, what you lack, each gun's chambers and belt, sticks, bundles, the bucket's water, blood on you | `Player`, `PlayerWounds.save_dict`, the guns' `to_dict` | one dictionary | ~3 KB | changed |

## Deliberately not saved

| What | Why |
|---|---|
| Anything in flight (falling rubble's speed, a thrown stick, a ball) | A save is a sleep: by then it's landed. Rubble is laid asleep where it is. |
| Wood chips, glass shards, bone fragments, smoke, sparks, dust, gun smoke | DESIGN: "only dust, splinters and sparks fade". They're capped and already fading. |
| Sound, the band's place in its tune | Nothing to come back to. |
| What a man's senses hold this second, his mood, his cower | He wakes to his day. What he thinks of you (opinions), whether he's still shaken, and the news are kept, so the day after still knows. |
| An act half played (the murder, the funeral, a card hand), a man running for the doctor | Nobody sleeps in the middle of one. A man an act had goes back to his day; the story's facts say what's happened. |
| Weapon in hand, crouch, composure, ringing ears | You wake standing, guns away. |
| Where the living stand, beyond where they were | Step 2 wakes you at dawn: the clock jumps and each man is where his day puts him. |
| The train's place | It follows the clock (`ValleyRailway.sync_to_clock`). |
| Lamps lit | They follow the hour. |
| Building ageing, settle-in | Seeded by the build: the same every time. |

## Not yet (found in the inventory; none blocks step 2)

- **Mission casts.** Outlaws, Joe, the sheriff and horses are made by their missions, not the roster. A
  save keeps them (dead ones are made again from `made` and lie where they fell); a living one the
  fresh world hasn't got is reported in `apply`'s `missed`. Resuming a mission's cast from the story's
  facts is step 2 or 3's, per mission (`retry_on_load` is the existing shape).
- **Horses** beyond yours (a mission's) have no id, no health and no state to save; yours keeps only his rail.
- **Loose and glass props, oil lamps smashed, fallen fittings** (`LooseProp`, `GlassProp`, `OilLamp`,
  group `fallen`) have no ids. Kit props (chairs, tables, the bar) are structures and are saved.
- **Kit prop hinges and contents** (a door open, a trough's water).
- **The valley's dug ground** (`ValleyGround` has no `to_dict`; the old town's `Ground` has).
- **A wrecked train** (`TrainWreck` has `to_dict` and no way back); the trestle has its own
  `save_dict`/`restore_dict`, not yet called by SaveGame.
- **Capture and load in one frame each.** Fine under a fade; a save while you watch would need the
  structures' part spread over frames.
- `SaveGame.loading` is set during `apply` and nothing reads it yet (a body laid on load already tells
  nobody it fell: `HumanBody._restoring`).

## How loading a body works (what went wrong, so it isn't tried again)

A dead man must lie as he lay, and stay there. Laying his ragdoll's parts where they were isn't enough:

1. **Tone.** A man let go keeps his muscle tone for an instant, as he stood. On a restored body it
   threw him a metre. Cleared on load.
2. **Joint limits** are taken from the pose he goes limp in. Let go standing, then laid, an elbow lying
   bent was pushed towards a standing arm's limits (a hand lifted 4 cm off the boards). He's posed as
   he lay first (`_pose_as`), knees' and elbows' bend from the angle between the two bones (an Euler
   angle let a knee fold backwards).
3. **Which parts pass through each other** (`_apart`) is saved and put back as it was; worked out
   afresh it let a forearm he was propped on through him.
4. **Sleep.** Moving a body wakes it at the next physics step whatever it was told. He's laid, then put
   to sleep on two later frames without being moved.
5. **Carved wood.** A carved plank's collision comes from worker threads a few frames on; until then
   it's a whole board. `Structure.from_dict` waits for the carving (`VoxelWorks.finish`) before
   anything is laid on it.

The same holds for rubble only loosely (it rests on the ground, not on its own joints).

## Judged by

- `tests/test_save_game.gd`: the valley test shoots a townsman in the leg, kills another, holes, breaks
  and cuts the general store's boards and sets a 0.4 kg charge against it, moves the clock to day 3,
  sets story facts and a checkpoint, moves and hurts you, takes your shotgun; saves; builds a new
  valley after `GameReset.clear_statics()`; loads; and compares story, clock, you, the town's day and
  news, the floor, the blood, each person and each changed structure. A second and a half later the
  dead are within 3 cm of where they lay.
- Step 2's own test (`tests/test_sleep.gd`): sleep in a bed, the file there and the clock at dawn;
  the world freed, a fresh valley built with the save pending (as Continue's reload), and the capture
  taken as you slept compared with the loaded world's; a sleep refused shooting and bleeding;
  Continue offered only with a save. Step 3's: a townsman shot in the shin and bound, sent in, slept on,
  loaded onto a fresh valley: he's still on the book and comes out with his wounds and his splinted leg;
  the horse at the rail you tied him; and one kept man laid up (broken pelvis), one dead of a gut wound in
  the night (`died_indoors`, `death.<id>`, buried).
- ROADMAP 6.6: the soak saves and loads as it goes (`SaveGame.differences` is its check).
