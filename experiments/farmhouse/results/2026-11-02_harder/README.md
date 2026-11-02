# The farmhouse made harder (issue #565, 2026-11-02)

Sean, after playing (the build before the surprise assault): the guards give up too easily, they
can't see him outside a window, they don't really shoot from inside to outside, and it needs
roving guards outside.

Each step measured on its own, 8 seeds a way, the scripted player (`farm_bot.gd`), the same seeds
throughout. `base` is main at 7705909 with only the new measures added (each man's quit, the
gang's shots out of the house); the switches `--farm-rovers=0` and `--farm-cornered=off` give the
befores. `nerve_bot2` is round 2 again with the floor fight and the scripted player's new routes
(below), no rovers: the rovers' own share is `all` against it.

```sh
python3 experiments/farmhouse/run.py --ways=front,breach,back --seeds=1-8 --jobs=4 --out=experiments/farmhouse/results/2026-11-02_harder/all
python3 experiments/farmhouse/run.py ... --args="--farm-rovers=0 --farm-cornered=off"   # glass alone
```

| round | way | won | rancher lives | you down | first quit (s after the alarm, median) | men who gave up (of them on the floor) / ran | their shots out of the house / all theirs | a rover found you first |
|---|---|---|---|---|---|---|---|---|
| main (7705909), the new measures | front | 4/8 | 8/8 | 4/8 | 2.7 (none in 1) | 21 / 2 | 106 / 143 | - |
|  | breach | 7/8 | 8/8 | 0/8 | 0.0 | 32 / 8 | 0 / 0 | - |
|  | back | 5/8 | 8/8 | 2/8 | 0.5 | 28 / 0 | 0 / 69 | - |
| 1. glass | front | 4/8 | 8/8 | 4/8 | 5.7 | 16 / 0 | 135 / 139 | - |
|  | breach | 5/8 | 8/8 | 2/8 | 0.0 | 31 / 9 | 0 / 5 | - |
|  | back | 5/8 | 8/8 | 2/8 | 0.5 | 28 / 0 | 0 / 69 | - |
| 2. + harder to break (no floor fight) | front | 3/8 | 6/8 | 4/8 | 23.5 (none in 3) | 10 / 0 | 137 / 150 | - |
|  | breach | 4/8 | 8/8 | 2/8 | 0.0 | 27 / 0 | 1 / 59 | - |
|  | back | 3/8 | 8/8 | 5/8 | 2.1 | 14 / 0 | 4 / 82 | - |
| 2. + the floor fight, the new routes, no rovers | breach | 1/8 | 8/8 | 1/8 | 0.0 | 26 (23) / 0 | 1 / 57 | - |
|  | back | 0/8 | 8/8 | 8/8 | 3.0 | 12 (10) / 0 | 0 / 86 | - |
| **3. + the rovers (all of it: the game now)** | front | **1/8** | 4/8 | 3/8 | 21.3 (none in 2) | 12 (10) / 0 | **193 / 219** | 8 |
|  | breach | **0/8** | 8/8 | 8/8 | 0.0 | 18 (15) / 0 | 13 / 48 | **0** |
|  | back | **1/8** | 8/8 | 7/8 | 2.1 | 21 (20) / 0 | 0 / 138 | **0** |

(The breach way's first quit at 0.0 is Hollis, blown off his feet by the stick a metre from him,
giving up from the floor. The back way's alarm is Hollis seeing you at the back door, as on main.)

## 1. Seeing through glass

Every pane was a wall to the eye (the perception lab's baseline item 4). Now the sight service
holds an unbroken pane on a sight-only bit, so sight, shot lines, Cover and the light pass it, and
the physics keeps it solid (a ball breaks it, nobody walks through it); Senses dims a man seen
through glass and for glare. The perception lab's sight group: only its three window cases change
(`experiments/perception_lab/results/2026-11-02_windows/`). In the farmhouse: the front way's
shots from inside at you outside 106 -> 135; the breach way harder (won 7 -> 5).

## 2. Harder to break

What made them quit on main (`base`): past their nerve they gave up or ran in the first seconds
(the breach: the Kid ran and Hollis gave up at the blast; the back way: Hollis at the alarm, Dutch,
the Kid and Lyle within 8 s), half of it "covered close" (a gun on him within 12 m: the whole
house), and the leader's surrender taking the rest. Now (`FarmhouseTuning.house_nerve` 0.25 more
nerve, `hold.cornered`): past his nerve, armed and not covered within 6 m, a man holds on where he
is for 8 s, up to three times (`OutlawBrain._cornered_break`), and "fall back" doesn't send him
off; shot down and still with it he fights from the floor (`house_floor_fight`). Nobody runs any
more; standing surrenders nearly gone (the men who give up now are mostly down on the floor);
the front way's first quit 2.7 -> 21-24 s.

## 3. The rovers

Pike walks the yard round the house (the lane, the east side, the outhouse, the back, the west
side; pauses 4-16 s, looking out at the road and the hills), Wes the lane and the east yard
(`config/farmhouse.tres` `rovers`, `beats`). There's no corral at the farm (the town's corral is
in town), so the beat is the yard's places. Before the alarm they see you and it's the warning or
the alarm, as from the house; on it each falls back into the house by the nearer door if he's
nearer it than you are to him (most runs: both), else takes cover in the yard and falls back once
you're in the house or he's hit. A house man no longer goes to a window over a rover's footsteps.

**The quiet ways, timed:** each stop of a beat says which side of the house it leaves unwatched
(`quiet`). The scripted player waits at a gate out of sight for the beat (the back way: Pike on
the west of the yard; the breach: Pike at the front or east, Wes always), then goes, freezing
crouched if a rover within 45 m looks his way along a clear line. Its routes changed too, since the
windows see out now: the breach swings wide round the far north (50 m behind the house) and comes
in from the west at z 7, along the lean-to's west wall to its corner (still hidden from every
opening: `farm_hide`, `hide_glass.txt`); it crouches in the last 25 m (45 before). A rover found
the quiet ways in 0 of 16 runs; the surprise holds (the blast is the alarm in 8 of 8).

## What it means

The scripted player wins 2 of 24 (main 16 of 24). It isn't a person: it shoots what it sees and
walks its route, and the men it puts down get it from the floor. The dials to ease it, in order of
how much they did: `house_floor_fight` (false), `house_nerve` (lower), the rovers (`rovers = []`).

## Checks

- The perception lab's sight group, main against the branch: only the three window cases differ
  (`experiments/perception_lab/results/2026-11-02_windows/results.md`).
- The gunfight lab's determinism pair (`same_fight.py`, the spec saloon with its windows, 20
  fights: seeds 1-4, every setup, D+ as the posts round ran it): 20 of 20 the same twice.
- `tests/test_sight_world.gd` holds the plugin to Jolt's answers with panes passed (its Jolt side
  `Sight._jolt_hit`), and asks the glass bit too.
