# 2026-10-21: stairs, railings, tables, chairs and props (the baseline, main's HumanBody)

Sean (2026-10-21): "falling down stairs and falling over railings and falling into tables and
chairs and props". Groups P (21 falls: the saloon's stair and balcony rail as the lab builds them,
a porch edge and its step, the hitching rail, a card table and chairs, a barrel, the bar, crates)
and S (13: art's oak stair, #172, with its own collision: the flight, its foot, and the walkway's
1 m railing). Runs: `build/physics_lab/ps_main` (not in git). `S_oak_walk_down_ball` is left out: the
lab's walk doesn't climb steps, so his feet are in the treads before the ball.

Flags (`tally.py`): P 11 (never settled 5, awake at 6 s 3, one launch, one bounce, one twist);
S 18, 8 of them the walk down. Both knees folded > 120 deg at rest in 18 of 34.

## A blind critic (one fresh sub-agent, every sheet, scored 1-10 as real footage)

Mean ~5. Best: falls against a rail (he slides down the balusters to a slumped sit, 7), off a porch
edge (legs left on the boards, head in the dirt), backwards down a flight (a head-first slide on
his back). Worst:

1. **A blast behind him at the walkway rail** (2): still up a second after it, then crumples where
   he stands. It's round 3's honest push (0.3 kg at 1.5 m gives him ~21 N*s, 0.26 m/s): the same call
   Sean has on the blast in front.
2. **Shot dead on the top oak step**: he ends crouched on his heels, never settling.
3. **Shot from behind at the top of the saloon flight**: curls into a ball in the air and rolls off
   the landing (the hunch, `_hunch`, on a dead drop of 2.3 m).
4. **Shot from behind against the bar or crates**: knees jam into the face, the trunk bends back in
   one smooth C, head below the hips.
5. **Dead at a run past the hitching rail**: over as one straight plank, knees locked.

Recurring: the even knee-buckle into a squat before the fall (~15 sheets, the faint's fault,
`results/2026-10-21_faint`); the even backward arch (~7); never settled at 6 s (10, wedged and
seated poses); **forward falls stick on the stairs** (on the oak stair, from the top step he stops
within 0.5 s, no tumbling; his parts' friction is 0.9, cloth on oak is nearer 0.3-0.5); the
**props never move** (the game's props are `StaticBody3D`s, `PropLibrary.spawn`: a chair, barrel or
table doesn't rock or tip); nobody goes over a 1 m rail (ball, faint, blast, or dead at a run:
he drapes over the end rail and slides back).

Critic's full report: `critic.md`.
