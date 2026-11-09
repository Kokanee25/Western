# The build order: missions one by one, from the beginning

Sean, 2026-11-09: "So once the map's complete should we start building the missions one by one
starting from the beginning?" Answer, and his "yes write the build order" the same day: **yes, in story
order**, with the riskiest set pieces proved in labs ahead of their turn, and one foundation step first.

**Status:** PROPOSED as a whole (this session's plan). The roadmap (`docs/ROADMAP.md`) is Sean's: only he
adds, removes or reorders its steps, so where this plan touches it, the change is listed under "Calls for
Sean" and nothing moves until he picks. The map needn't be finished first: Act I is settled enough to
start; the planning lane keeps the later cards and `DECISIONS.md` ahead of the builders.

## How each mission is built (the loop)

The same seven steps for every mission, one issue each, handed over as now:

1. **The card settled.** Sean's ticks are on it; its rows in `DECISIONS.md` checked (every fact it reads
   is set earlier, for every value). Anything OPEN that the build needs is asked first (`waiting on Sean`).
2. **The build check re-run** against main (`JUDGE.md` "The build check"): every idea with file:line and a
   verdict. Anything LARGE or NOT FEASIBLE goes back to the card before code starts.
3. **Labs for what's new and risky:** the set piece and anything LARGE, measured on a bench first
   (`docs/briefs/labs.md`'s way: a baseline, then fixes against it), as #745 does for the Payday floor.
4. **Rough, in acts** (roadmap 3.5): stand-in men, typed lines, playable start to finish, **every way on
   the card** reachable. Rough means rough: no polish, no new art.
5. **Played:** the playtest agent plays it blind (`tools/playtest.md`), then Sean. What they hit is fixed.
6. **The gate:** Sean plays it again a different way by choice (Gate C's rule, a mission at a time), and
   the facts it sets are saved and read by the next mission. Then, and only then, the next mission.
7. **Polish later,** with the place and the demo (Phases 4 and 6): voices, the look, motion.

## Step 0: the foundations

Every mission needs these, and the build checks found them missing (`MAP.md`, "What the build checks
found missing everywhere"). Built first, in this order, each as a gameplay step with its own issue:

| # | Foundation | Why first | State on main | Roadmap |
|---|---|---|---|---|
| 0.1 | **Acts:** missions and scenes as data (who goes where, says what, beat by beat; hands back to the systems when you interfere) | Every mission is written in it | new | 3.5 |
| 0.2 | **Story state and saves:** the facts in `DECISIONS.md` as its keys, saved when you sleep (DESIGN), read by later missions | No mission can remember anything without it; the decision tree stays on paper | new, LARGE | 5.5 |
| 0.3 | **People where the missions are:** the valley's townsfolk, the saloon on its lot | The valley has no people yet (`valley_world.gd:12`); the opening needs the town full | new (the valley's next G-steps, waiting on #695) | the valley plan |
| 0.4 | **The nod and shake** | Sean: "to build first" (No Justice); No Law's deputizing uses it | decided in outline, not built | (none; part of 5.2) |
| 0.5 | **Carrying things and doors** (pick up, carry, drop; doors that open and shut) | The badge, the revolver handed over, the boot's find, papers, barricades | new | 4.7 |
| 0.6 | **Long memory** (gratitude and grudges that last days, not an hour) | The widow, Joe, the camp, "owes Harlan" | new (`Relations` fades in about an hour) | 5.3 |

0.1 and 0.4 are small and can start now; 0.2 is the big one and starts beside them. 0.3 is the valley's
own work: if it isn't ready, the opening is built in the town world (`--world=town`, people and saloon
exist) and moved when the valley has people (OPEN, Sean's call, below).

## The order

Each step names only what's **new** for it (what earlier steps built is reused), the labs to run **ahead**,
and the calls to settle before it starts. "Facts" are `DECISIONS.md`'s.

### Step 1: the opening (the demo's prologue and day 1; roadmap 5.6, Gate D)

`the-sheriff` → `no-law` (night 1) → day 2, deputized → the funeral.

- **New:** words by blood loss carried overnight (physiology exists); first aid on another man (treatment
  lab part 1, partly); the seated player who can't act (small); the card game and its interruption; an
  owner caring about his broken things (a rule); the funeral gathering, the grave that stays; the badge
  and revolver handed over (0.5); the red shirt's ride out, seen by a player who follows (a horse
  ridden by an NPC, partly).
- **Labs ahead:** none big. The card game is a small bench in the saloon (the card cheat's moment exists).
- **Facts set:** `sheriff.care`, `harlan.deputized_with`, `funeral.attended`, `nolaw.followed_red_shirt`.
- **Calls first:** none blocking. The doctor's ball as evidence stays out (evidence is "a maybe").

### Step 2: `no-justice`

- **New:** Joe as a companion who fights, keeps quiet with you, can go down and be helped up; surrender with
  begging and an escort; a barricaded cabin to force (kick and shove exist); the knife and the scalping on
  the wound system (the knife is #733's); the faded red shirt readable at range, Joe's disguise (Studio);
  the prisoner's transfer on the daily train; the kin's response decided by the witnesses.
- **Labs ahead:** a companion bench (Joe beside the player in the gunfight lab's setups: does he help, does
  he get in the way, is he believable when he's down). Start it during Step 1.
- **Facts set:** `joe.question`, `red_shirt.fate`, `joe.disguise_held`, `camp.trust`.
- **Calls first:** DECISIONS gap 1 (the rope's cause if Harlan murders the surrendered man).

### Step 2b: `widows-place` (the quiet ride; Sean, 2026-11-09)

Placed here PROPOSED: a quiet mission after No Justice's fight, the widow met before the farmhouse (the
lock's order), and the Winchester in hand before the rope (if she gives Harlan the sheriff's rifle).

- **New:** riding a horse and leading one (horse lab P2, #478), the first long ride with nothing at stake;
  the two boys (child bodies, `ProtectedChild`) and Blue (a dog never hurt, who learns a man); the boys'
  play; chores with a helper (partly).
- **Labs ahead:** riding is the horse lab's own next step (start it during Step 1: every later chase
  needs it); the boys and Blue are characters' and prop-lab work, asked early (#728). Meeting them here,
  where nothing's at stake, is the cheap place to tune them before the farmhouse puts them in a fight.
- **Facts set:** `widow.visited`, `blue.knows_harlan`, `boys.know_harlan`, `widow.told_end`,
  `harlan.has_winchester` (if option A).
- **Calls first:** why he rides out (the card's A, B or C).

### Step 3: `joe-on-the-rope`

- **New:** the Winchester (#734, next in the arsenal anyway); rope a ball can cut at 30–60 m; a hanging
  body (airway compression on the ragdoll and physiology); a mob with a rope and nerve.
- **Labs ahead:** the rope lab (a ball against a thin target at range, the hanging body); start it during
  Step 2. The mob reuses the crowd from Payday's floor lab (#745) where it can.
- **Facts set:** `joe.alive` (and the "Without Joe" paths from here on).
- **Calls first:** DECISIONS gap 2 (who gives Harlan the Winchester, and when; Step 2b's option A answers it).

### Step 4: Act II

`buried-alive` → `demolition-mentor` → `farmhouse-rescue` (v2).

- **New:** an adit of timber sets underground, digging rock, gas, crushed limbs; teaching as how the player
  learns (signature 8: dynamite unlocked by being taught, not a menu), half-sticks. The farmhouse is built:
  it moves onto the story state, then v2's additions (the boys and Blue protected, the yard's phases, the
  peaceful visit, lived-in props).
- **Labs ahead:** the underground lab (the adit holding and failing by its sets, gas, digging under rock);
  start it during Step 3. Children and the dog are characters' work: ask early (#728).
- **Facts set:** `dynamite.level`, `miner.alive`, `widow.signed`, `kid.state`, `farm.prisoners`.
- **Calls first:** DECISIONS gap 4 (who teaches if the miner dies).

### Step 5: Act III

`hell-on-wheels` (v2) → `payday-night` (v6) → `i-am-the-law`.

- **New:** fighting on a moving train, the cab's controls (train step 7); the express car's robbery as a
  gang plan; the crowd's weight on a floor, falls that hurt, the traces (sawdust, the day-book); Rourke
  (his rule, his letter as an object you read); the captain on his own agenda, his tally of deeds and
  shots, provocateurs, overhearing through a wall.
- **Labs ahead:** **the Payday floor (#745, open now)**; the Water Tower (`hold-him`'s set piece) if
  `hold-him` lands in this act; the train's step 7 is the train lab's own next step (#542).
- **Facts set:** `payroll.fate`, `gang_a.fate`, `gang_b_man.taken`, `payday.floor`, `payday.letter`,
  `payday.proof`, `law.tally`, `law.joe`.
- **Calls first:** DECISIONS gap 3 (I Am the Law without Joe: who the Baron's men goad).

### Step 6: Act IV

`barons-shipment` (v2, waiting on Sean) → `the-bridge-is-out` → `barons-house`.

- **New:** a log as a heavy rigid body; the coach tipping, traces breaking; dented steel (one dent system
  with the train); papers that burn or are lost (if evidence stays in); soldiers and hired guns fighting
  from a train; turning soldiers; the Sap (a covered trench, props as the load path, a wall dropping off
  them); a man who must survive a breach.
- **Labs ahead:** the masonry lab's steps 3–8 (#663, already running: the arch rule S3 matters for the Sap);
  a Sap bench on the masonry panel (props pulled one at a time); the coach and log bench. The trestle
  already collapses (#623, #637, #658).
- **Facts set:** `ledger.held`, `bookkeeper.state`, `trestle.state`, `baron.fate`, `baron_house.wall`.
- **Calls first:** Shipment v2's ticks and its two calls (can the log hurt the horses; the coach standing at
  the bend for v1); Rourke's fate on the bridge; whether evidence and the trial stay in.

### Beside the main line

Side missions and set pieces are built between main steps once Sean has reviewed them and placed them
(DECISIONS gap 7): `hold-him` (the Water Tower), `dig-him-up` (reads `sheriff.care`, so any time after
Step 1), `the-bounty`, `kid-wants-out`, `dry-creek`, `vaqueros-horses`, `balcony-ambush` (after dynamite).
The cheapest on today's systems go first when a main step is waiting on a lab.

## The labs, started ahead of their mission

A lab takes longest to get right, so each starts about one step before its mission needs it:

| Lab | For | Start | State |
|---|---|---|---|
| The Payday floor (crowd load, a sawn joist, falls that hurt) | `payday-night`; its crowd for `joe-on-the-rope`'s mob | now | #745 open |
| The companion (Joe beside the player) | `no-justice` on | during Step 1 | to open |
| Riding (and leading a horse) | `widows-place` and every chase | during Step 1 | horse lab P2 (#478) |
| The boys and Blue (protected, at play, learning a man) | `widows-place`, `farmhouse-rescue` | during Step 1 | characters, #728 |
| The rope (cut by a ball; the hanging body) | `joe-on-the-rope` | during Step 2 | to open |
| Underground (the adit's sets, gas, digging rock) | `buried-alive` | during Step 3 | to open |
| The Water Tower (a stave tank on four legs, axe strokes, the hoop lug) | `hold-him` | when Sean places it | to open |
| The Sap (a masonry wall on props) | `barons-house` | after masonry S3 | after #663 |
| The coach and the log | `barons-shipment` | during Step 5 | to open |

## Calls for Sean

1. **The roadmap:** Phase 3's 3.6 builds three rough missions (the saloon table, the store robbery, a
   bounty) for Gate C. Proposed: 3.6 becomes **the opening in story order** (Step 1: the saloon table is
   `no-law` now), with the store robbery and the bounty as side missions later. Keep 3.6 as written, or
   change it?
2. **When:** ▶ Now is the realistic look (R0–R3, C1, M1). Do the missions start beside it (the gameplay
   lane is free for Step 0's acts and the nod), or after?
3. **Where the opening is built first:** in the valley once it has people (waits on #695 and the valley's
   next steps), or in today's town world now, moved to the valley later?

## Keeping it true

- When a mission's gate passes, mark its step here (done, the build number).
- When a card changes its systems or facts, update its step here with `DECISIONS.md` in the same commit.
- A lab's results go in its own `experiments/` README; this page only points at it.
