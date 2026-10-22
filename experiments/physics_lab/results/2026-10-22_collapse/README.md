# 2026-10-22: the stair head, the brief's tone experiments (docs/briefs/collapse.md)

Sean (2026-10-22): "the knee-buckle at the stair's head". All in the muscle tone, as the brief
says: no scripted push, no fall pose.

## The switch

`HumanBody.tone_fade_share` (empty on main: no change) gives a joint kind, or one side's joint,
its own share of the tone's fade. The lab sets it with `--fade-share=abdomen:0.4,...`. It's set
through the loaded script: naming HumanBody in lab.gd made the lab compile it before the
autoloads (Settings, used since the gore lab's merge) and fail.

## The runs

The seven stair-head falls (oak stair S_oak_top_*, the saloon's T_stair_top_*), rancher, 4 runs
each with `--jitter` (`jitter_spread.txt`). "Down" means his centre of mass dropped more than
1.2 m (down the flight).

| condition | oak, shot from behind | oak, dead | oak, faint | saloon, shot from behind | saloon, dead | flags/run |
|---|---|---|---|---|---|---|
| main | 2/4 | 3/4 | 1/4 | **0/4** | **0/4** | 10.0 |
| 1. trunk first (abdomen, chest, neck 0.4, head 0.5) | 2/4 | **4/4** | 0/4 | 0/4 | 0/4 | **6.0** |
| 1, stronger (0.25) | 2/4 | 2/4 | 0/4 | 0/4 | 0/4 | |
| 1 + 2. hips with the knees (thigh 0.5) | 2/4 | 0/4 | 0/4 | 0/4 | 1/4 | 7.8 |
| 3. uneven legs (right leg 0.35) | **4/4** | 1/4 | 0/4 | 0/4 | 0/4 | 9.2 |
| 3 + 1 | 4/4 | 0/4 | 0/4 | 0/4 | 0/4 | 11.8 |

Shot from in front facing up either stair (falling back down it), he goes down 4/4 in every
condition but the uneven legs (saloon 0/4).

## What it says

- **Nothing here gets him down the saloon's stair.** He stands 0.22 m back from its top step
  facing down it (lab_runner `_saloon_spot`), folds forward, and his chest lands on the top treads
  (centre of mass down 0.8-0.95 m) and stays. The tone isn't what holds him. The next thing to
  look at is what his chest and arms meet on the treads (their friction, the tread nosings'
  shape) and his forward momentum as he folds.
- **Trunk first** is the only variant that helps without hurting: the oak stair's dead fall 3/4 ->
  4/4, flags 10 -> 6 a run. It's the candidate for a blind judge over the standing falls (the
  brief's groups A, K, M, P, S, T); that render was cut short (time limit) and is the next step.
- **Hips with the knees** makes the oak stair's dead fall worse (0/4), and **uneven legs** helps
  one fall and hurts two. Neither goes forward.
