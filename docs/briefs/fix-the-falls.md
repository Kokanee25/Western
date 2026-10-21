# Fix the falls (gameplay session; Prompt 09)

**Sean (2026-10-16):** "Yes fix the falls". Earlier: "as real as possible so just drops if dead esp
running".

## Goal

A man who goes down falls the way a real one would, every time: no puppet fold, no limbs through
him, no joints coming apart or overrunning, no throw a ball couldn't give, and he comes to rest. The
passive ragdoll is kept (`HumanBody.go_limp()`); this isn't an active controller.

## References

- `docs/prompts/09_Passive_Ragdoll_Hit_Reactions.md` (the brief's source).
- `experiments/physics_lab/README.md`: the lab, its baseline (2026-10-11) and the five faults.
- `experiments/physics_lab/results/2026-10-11_carry/` (fault 2 and the scripted pushes: fixed) and
  `results/2026-10-12_tone/` (faults 1 and 3 mostly: muscle tone, self-collision).

## What's left (from the lab and the 10-12 results)

1. **Joint overruns and gaps at impact** (fault 4): head, hands and feet past their limits for a
   tenth of a second, feet and shins 2–6 cm off their joints. Next to try: solver iterations,
   then the limits' axes (anatomical, not "the pose he went limp in").
2. **A standing blackout ends in a hunched heap**, knees under him, face down. A faint from
   standing usually ends flat (sideways or back) as the knees give and the trunk topples.
3. **Hands rest a few cm into his thigh or chest** (left out of self-collision for jitter).
4. **The test matrix not yet run**: seated, facing different ways, stairs/table, dragged by the
   collar, a limb gone, repeated contacts, 5 and 10 at once; blasts (a wind on all of him) kept
   apart from shots (the ball's momentum on one part).
5. **Hits that knock down**: a fall comes from the injury (legs, shock, blackout), never from the
   ball's push; check every path into `go_limp()` gives no more than physics would.

One variable family at a time, each measured against the last result.

**After round 3 (2026-10-21, `experiments/physics_lab/results/2026-10-21_round3/`):** 1, 3 and 5
done (the light links' inertia; resting parts collide; no push past physics; hip and spine cones
centred anatomically); 4 run (groups M, N, R). Still open:
- 2 and the knee fold: his weight stands right over his ankles, so a faint goes straight down
  (a stance with the weight forward is Sean's call).
- Pushed over backwards on planted feet he arches (the beam); the torso stands on its stumps after
  a blast takes both shins; face first, a head-first jackknife.
- The Studio's men: meshes past the shared capsules (into the floor lying down), shoulders skinned
  to the neck (characters).
- **Sean (2026-10-21): falls down stairs (a real flight), over railings (a porch rail, a
  balcony) and into tables, chairs and props** (the game's own: tables, chairs, barrels, crates,
  the bar), facing every way.

## Done looks like

- The lab's flags down from 54 (after 10-12) with none in the joints-apart family; the
  before/after sheets at the lab's cameras for each change; footage at real speed looked at.
- Tests green, a regression test per fix where the lab's numbers allow one; hit registration,
  wounds, severing, dropped guns, the gang's rescues (drag) unchanged.
- Physics within its budget with ten men going down at once (lab `--perf`).

## How it's judged

The lab's numbers and sheets first; Sean's eye on a build (F11/K drops a man; the gang fight).
**Any change to `human_body.gd` goes to Sean as a proposed patch with its before/after before
merging** (Prompt 09). Results go in `experiments/physics_lab/results/<date>_<name>/`.
