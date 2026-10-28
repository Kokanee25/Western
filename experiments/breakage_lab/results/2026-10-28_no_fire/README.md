# Dynamite lights nothing itself, 2026-10-28 (issue #449)

Sean (2026-10-28): "Let's do less fires. TNT just doesn't cause a fire unless it hits a lamp that
gets knocked down." `BlastTuning.ignite_chance` 0.12 -> 0 (`config/blast.tres`); `Blast` otherwise
unchanged (the fireball still burns people). A fire after a blast now comes only from a lit lamp it
breaks: past `shatters_kpa` (15) where it stands, thrown and landing hard, or down with its shelf
(GlassProp -> `OilLamp.smash` -> `FireSystem.spill`). No lamp needed tuning: within a metre or two
every lamp in the saloon breaks (4-7 a stick), and one 3 m off is thrown (0.2 m) and stays whole.

## The three runs (40 s each, outlaw bystander, seed 1; `runs.json`)

    python3 experiments/breakage_lab/run.py --scenario=lamp_dynamite_1m,lamp_dynamite_3m --bodies=outlaw --seconds=40 --out=.../night
    python3 experiments/breakage_lab/run.py --scenario=lamp_dynamite_1m,lamp_dynamite_3m --bodies=outlaw --seconds=40 --hour=12 --out=.../day
    python3 experiments/breakage_lab/run.py --scenario=wall_dynamite_1m --bodies=outlaw --seconds=40 --hour=21 --out=.../nolamp

| run | stick | lamps lit (15 m) | lamps smashed | what caught in 40 s |
|---|---|---|---|---|
| **night** (21:00, the saloon) | 1 m from the card table's lamp (it shatters) | 42 | 7 | 315 members: a crate 5.5 s on (the oil), the floor 8.5 s, the posts 9.5 s, the roof 20 s |
| night | 3 m off (that lamp thrown, whole) | 42 | 5 | 502: crate 5.5 s, floor 8.0 s (111 boards) |
| **day** (12:00, the same sticks) | 1 m / 3 m | 0 | 4 / 3 | nothing |
| **no lamp** (21:00, the store's front, 1 m) | | 0 near | 0 | nothing |

Before (the baseline, `baseline/baseline.md` finding 5): every stick in the saloon lit 2-7 boards
itself, at any hour.

## The look (`sheets/look_before_after.jpg`)

`run.py --look=0.05,0.5,1,2,4,8 --bodies=bold_cowboy_s0 --scenario=wall_dynamite_0m,floor_dynamite_0m`,
main (721f68c) above, this branch below:

- the store's front at 16:00: before, the sill and siding catch 2-2.5 s on (3 boards) and burn by
  8 s; after, dust and nothing alight;
- the saloon floor at 21:00: before, the floor boards the flash lit catch 1.5-2 s on (45 members);
  after, the same four lamps smash and their oil lights a crate at 5.5 s (41 members by 8 s): it
  burns, later, from the lamps.

## Found on the way

- **A blast's collapse could be lost** (fixed, `FireSystem.queue_settle`): a stick going off while
  the fire's slices were part-way through the building's routine analysis (the spec saloon's first
  look, begun before the blast) left the blast's 1 overloaded and 37 unsupported members standing:
  `queue_settle` skipped the building being checked, and that analysis, of the saloon as it stood
  before, found nothing. On main the fire's next look at the burning building brought them down
  ~5 s on; without the fire nothing did (`test_settle_incremental`: 38 broken, 38 five seconds on).
  Now the check begins again: 76 down by frame 40.
- The lab's lamp target hadn't been found since the lamp went into the kit (GlassProp isn't a
  KitProp): the finder takes it, and a GlassProp result (shattered, thrown, its own lamp).
