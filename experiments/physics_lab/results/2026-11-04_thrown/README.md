# Men thrown through the air (#596 step 3b), 2026-11-04

Sean (2026-11-03): a man close to a stick goes up and back in an arc and lands in the world,
tumbling as an active ragdoll, not a limp doll, and not cartoon. Brief: #596's comment.

## What changed

`BlastTuning.blast_lift` (`config/blast.tres`; **0 in the game until Sean picks**) adds a lift to the
real push in `HumanBody.take_blast`. Before 3b a stick on the floor a metre off pushed him at
~1.7 m/s along the line from the charge to his chest: knocked over where he stood.

- **How much:** `lift_speed` (7.5 m/s) x `Blast.lift_share(kg, r)`: 1 / (1 + (z / lift_reach)^4),
  z = r / cbrt(kg). For a floor stick (0.36 kg as it hits): ~0.86 at a metre off (r = 1.55 m to his
  chest), ~0.23 at 3 m, ~0.02 at 6 m. Times the shielding (0.35 behind timber) and the dial.
- **Which way:** away from the charge along the ground, up by `lift_angle` (55 deg) when the charge
  is well under his chest (level with it: little up; over him: none). Straight under him: back.
- **His turn:** a tumble, head away from the charge and feet coming up (`lift_tumble` 2.4 rad/s at
  the full lift, +/-30 % by his seed), a little twist (`lift_twist`), set as a rigid turn about his
  weight's centre so where he goes is the throw's alone. Its dice are its own (his seed and the
  blast's place): the same blast throws him the same way, and nothing else he draws moves.
- **Active, not a sack:** a thrown man braces for the flight: the brace's arms out and chin tucked
  (or arms ahead, thrown forward), knees up (`THROWN_TUCK`), held for the flight's length; out
  cold (most men a metre off are concussed) at half the hold. Dead, limp.
- **Landing hurts:** for 3 s a part that stops more than 3 m/s faster than gravity in a tick takes
  `take_blow` with half its kinetic energy (bruises, ribs, a concussion), once a part.
- **What he hits:** BodyImpacts and KitProp.take_blow as before (railings, tables, chairs). No new
  bodies.

## Numbers (ragdoll lab group Z, headless; `thrown_headless.txt`)

Arc top = his weight's centre over where it started; land = how far it went by the time he first
lies (centre under 0.35 m).

| scenario | lift 0 (today) | lift 0.8 | lift 1.1 | target |
|---|---|---|---|---|
| 1 m in front | knocked over, 0.5 m | 5.1 m/s: top 1.08, lands 3.4 m | 7.1 m/s: top 1.82, lands 5.3 m | 3-6 m, top 1-2 |
| 1 m behind | 0.7 m | top 0.92, 3.2 m | top 1.57, 4.9 m | |
| 3 m in front | knocked over, 0.8 m | off his feet, 0.8 m (top 0.06) | off his feet, 1.1 m, ends 2.0 | off his feet, 1-2 m |
| 6 m in front | standing | standing | standing | knocked down as now (he wasn't, at 6 m, before either) |
| off the porch (1 m behind) | 1.0 m | 3.3 m, off the boardwalk | 5.1 m | |
| hitching rail ahead | 0.8 m | over it, 3.1 m | over it, 4.8 m | |
| saloon table 3.5 m ahead | 0.7 m | **onto the table** (20 members broken) | over it, 4.9 m | |
| game saloon's balcony rail | slumps on the rail (3 broken) | through the rail and down (3) | through and down (4) | |
| three men, one stick | 0.8 m | 2.6 m | 4.0 m | |

Every run twice gives the same numbers (the lab's determinism). The landing's blows: bruises
everywhere; at 1.1, of the 8 men who landed from a flight, 4 concussed by the head's landing and 2 with broken ribs; at 0.8, bruises only.

## Films (`films/`, game speed then 3x slowed; sheets beside each)

The lab's matched cameras (lavapipe). Lifts side by side, left to right:
- `Z_thrown_1m`, `Z_thrown_3m`, `Z_thrown_6m`, `Z_thrown_three`: lift 0 / 0.8 / 1.1, 8-9 m off.
- `Z_thrown_table`, `Z_thrown_balcony_rail` (the game's saloon): lift 0 / 0.8 / 1.1, two views.
- `Z_thrown_1m_behind`, `Z_thrown_porch`, `Z_thrown_hitch`: lift 0 / 1.1.

At a metre the game's blast already takes his feet or shins (#220's pick); that's unchanged.

## The frame (#492's gate; `experiments/blast_freeze/results/2026-11-04_thrown/gate.jsonl`)

The real game, the spec saloon, one stick, `bf_blast men=3 men_r=1.0 lift=L` (three standing men a
metre round it), twice each, ms at Sean's (x0.65):

| | stick's worst frame | frames over 50 | mean of 5 s after |
|---|---|---|---|
| no men | 82, 85 | 3, 6 | 20.9, 23.0 |
| three men, lift 0 | 218, 143 | 11, 8 | 27.2, 25.5 |
| three men, lift 1.1 | 150, 140 | 8, 5 | 27.6, 23.4 |

**The throw costs nothing measurable.** Three men by a stick already fail #492's one-hitch line on
main: their `take_blast` on the stick's frame is ~120 ms here (`dynamite` 65 -> 180-200 ms with
them: going limp, 17 bodies and 16 joints each, wounds, limbs torn off), lift or not. Not 3b's;
the next step for it is spreading the men's going-limp over the next ticks (`SpawnQueue`).
In the ragdoll lab the game saloon's balcony rail's first break is ~100-110 ms here at lift 0 and
1.1 alike (run alone; three runs at once read 250).

## Traps

- `Z_thrown_three` rendered hangs Godot at quit every time (#392's pool exit); its files are all
  written first. The renders ran under a watchdog that killed a lab game 60 s after its summary.
- A scenario's own `views` win over `--views`.
- The lab's `take_blast` gets `kg` as given: 0.36 is a 0.2 kg stick on the ground.
