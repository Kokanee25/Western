# Brief: how a man collapses (the even knee-buckle)

Gameplay lane, roadmap 3.1 (the falls). Written 2026-10-21, after rounds 3 and 4 and the faint
(`experiments/physics_lab/results/2026-10-21_round3/`, `_faint/`, `_round4/`).

## The problem

Every fall from standing starts the same way: his knees fold evenly and his hips drop back over his
heels into a balanced squat, with his trunk upright. Then he tips one way or the other.

- **Blind critics:** "knees-first into a squat or kneel" on 17 of 33 sheets (round 4) and ~15
  (round 3). The faint's judges called it "a controlled crouch, not legs giving way unevenly".
- **On stairs and at edges:** his weight stays over his feet, so he doesn't pitch over the drop.
  Shot at the head of the saloon's stair or the oak stair, he crouches or kneels on the top step
  and sticks there (round 4: friction, tried as the cause, wasn't). People expect a man shot at
  the top of a stair to go down it (Sean, 2026-10-21).
- **Shot from behind**, he often ends up behind where he stood (15 of 36 ahead, with or without
  the back arch).

**Why:** `HumanBody._start_tone` holds every joint toward the pose he went limp in, and the hold
fades over the same time for all of them (TONE_FADE 0.35 s; dead 0.15 s). The legs carry all his
weight, so they give first; the trunk's hold keeps it upright over the hips as he sinks. The
balanced squat is what that leaves.

## What a real collapse does (references to gather and cite)

- **Fainting (syncope)** and a fatal wound take the postural muscles all together, but the trunk
  and neck extensors carry no load to hold up. As the knees give, the trunk and head fold forward
  (or slump to the side), so the body's weight moves off the feet. A crumple, not a squat.
- **Video of real falls:** Robinovitch et al., "Video capture of the circumstances of falls in
  elderly people residing in long-term care", Lancet 2013 (how often falls go forward, sideways
  or back, and what's hit first). Sean's own references (news footage, film) if he has any.
- **The legs give unevenly:** one leg goes first, so he turns and falls to a side. Round 3 tried
  asymmetric fades and dropped them; why it failed should be read before trying again.

## What to try, one at a time, each against main in the lab

1. **The trunk lets go first:** abdomen, chest and neck tone fade faster than the legs' (or start
   lower), so he folds forward at the waist as he sinks.
2. **The hips with the knees:** as the knees bend, the hip's hold eases with them, so the pelvis
   goes forward over the knees instead of back over the heels.
3. **Uneven legs:** one leg's tone goes a moment before the other's (the side seeded), only after
   1 and 2 are judged.

Not on the list: any scripted push, or a pose or animation for the fall. It's all in the tone,
his own muscles, as now.

## Done looks like

- **Blind judges:** pairwise against main over the standing falls (groups A, K, M, P, S, T),
  sheets shuffled, a clear preference for the change.
- **Stairs:** shot at the head of the saloon's stair and the oak stair (T_stair_top_*,
  S_oak_top_*), he goes down the flight in at least 3 of 4 `--jitter` runs (now: none).
- **Flags and budget:** lab flags no higher than main's; physics within budget with ten men
  going down (`--perf`).
- **Unchanged:** hit registration, wounds, dropped guns, the drag, the kneel of a man who gives
  himself up.
- **Sean's play:** he judges it on a build (F11/K drops a man; the saloon's stair). Any change to
  `human_body.gd` goes to him as a proposed patch with before/after sheets and real-speed footage
  before merging.

## How it's judged

The lab's numbers (`tally.py`, `spread.py`), then blind pairwise judges (`blind.py`), then Sean.
