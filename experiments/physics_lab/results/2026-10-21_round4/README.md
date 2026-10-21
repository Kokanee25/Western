# 2026-10-21, round 4: stairs, rails and props on the new men; a railing that breaks

Runs are in `build/physics_lab/` of the session's worktrees (not in git). The numbers are on
`old_rancher_s1` and `young_drifter_s1`; the sheets are spread over all five new men. Every body
shares the outlaw's physics shapes (`Anatomy.shared()`), so the two men's numbers are identical.

## The baseline on the new men (groups P and S)

- **Cameras chosen by what they see.** Each summary now has `seen`: for each camera direction
  and height, the share of his parts in frame and not hidden by the world, sampled to the end. In
  the outlaw baseline about 17 of 33 sheets had a view seeing under half of him (a rail, the bar,
  the stair's post). 30 scenarios now name their own `views` (a direction, and a height such as
  `back^3.0`). The long drops have `cam_dist` 5 and a focus that takes in both his standing head
  and where he lands.
- **Two lab mistakes fixed.** The hitching rail stood in the oak-stair fixture, behind the man at
  the stair's foot, so the hitch falls had no rail. It's now its own `hitch` fixture. Also,
  `--model` stops if the body isn't imported.
- **Flags**: P+S 20 over 33 falls (the outlaw's 29 less the held walk down the stair, 8 of them).
  With the rail where it belongs, the run into the hitching rail now flags (a hand's whip at
  8.7 m/s, a foot past its limit).
- **The blind critic** (`critic_baseline.md`, before the camera fixes for the long drops): mean
  **4.8** (the outlaw's ~5). Recurring faults:
  - he goes down knees-first into a squat (17);
  - on stairs he sleds or sticks and never tumbles (6 of 11);
  - shot from behind he falls back toward the shooter (5 of 10);
  - the props never move.

## Forward falls stick on the stairs: friction (not kept)

Jolt takes the lower of two surfaces' frictions (measured: (0.3, 1.0) gives 0.32, (0.9, 0.4) gives
0.43). His parts are 0.9 and the fixtures 1.0. Each setting was run 4 times with `--jitter`
(`friction_jitter.txt`; `spread.py`):

| fall (median m he travels) | main | body 0.6 | stair 0.6 | stair 0.45 |
|---|---|---|---|---|
| shot from behind, mid oak flight | 0.37 | 1.35 | 1.50 | 1.49 |
| shot dead, top oak step | 0.45 | 2.01 | 0.83 | 1.37 |
| shot from behind, top oak step | 0.50 | 0.57 | 0.49 | 0.67 |
| 20 deg dirt slope | 0.39 | 0.52 | 0.39 | 0.39 |
| creeping > 5 cm after stopping | 22/108 | 12/108 | 21/108 | 25/108 |

Body 0.45 or lower on dirt: he never stops on the slope. A blind pairwise judge on 12 falls, main
against body 0.6 (`judge_friction.md`, key `key_friction.json`): **main 4, body 0.6 3, even 5**.
It was surest about the oak flight, where at 0.6 he slides down "like a toboggan"; "a real body
snags on stair nosings and stops part way far more often than it toboggans." **Not kept.** The
drag is velocity-driven and still works at 0.6; he coasts 0.42 m further.

What holds him on the top step isn't friction. His knees buckle evenly first, he lands on them on
the landing, and he pitches his chest down the treads with his hips up; the folded knees anchor
him. That's the knee-buckle Sean is still to rule on (a brief first).

## Shot from behind he falls toward the shooter: the back arch (kept)

`HUNCH_BACK` arches him away from a wound in his back. With it off (only the sideways bend kept),
on flat ground he still ends behind where he stood (15 of 36 ahead either way), so the arch isn't
why. A blind judge on 12 back-shot falls (`judge_back_arch.md`): **main 7, no arch 2, even 3**.
Without it he drops straight down on buckling knees into a posed curl; with it the trunk leads the
fall. The two wins without it were the bar and the crates (the arch bends him away from what he
faces). **Kept.**

## The 1 m rail: should he go over at a run? (no change)

Shot dead 0.08 s before the oak walkway's end rail at 3.5 m/s, his centre of mass reaches it at
0.93 m, under the 1.0 m rail.

- **Before contact:** his angular momentum about the rail is -2 to -10 kg·m²/s (backward). The
  legs below it (-40) outweigh the trunk above it (+35).
- **After the legs stop** (balusters and floor, 0.07 s): the trunk's +15 to +18 turns him forward
  at about 1.6 rad/s, roughly 14 J.
- **To go over:** rolling his centre of mass over the rail would lift it about 0.19 m, about 150 J.

So he drapes over a 1 m balustrade and slides back as his feet go out: the lab's fall is right.

## Sean (2026-10-21): the saloon stair's ramp, and a railing that breaks

**The ramp.** The saloon stair's walking ramp stood half a riser above each tread's back, on
WORLD, so a man falling down the game's stair met a smooth ramp. It's now on `Layers.WALK`, used
only by walkers (`STAND` = WORLD | WALK); `tests/test_stair_ramp.gd`: 29 of 40 points down the
flight met the ramp before, 0 now.

**The railing.** `BodyImpacts`, one per limp man, applies two rules near timber:

- **Impact:** a member breaks when the level work of stopping him on it passes
  `impact_toughness` × its volume. That's the falling-rubble rule: a baluster ~35 J, a 1.2 m oak
  cap rail ~150 J.
- **Nails:** an upright member with nothing holding its top tears off its nails when his bearing
  on it times the height passes `joint_moment` scaled by its section (a 35 mm baluster ~43 N·m).

The lab builds the walkway's railing from the game's own members (`lab_railing.gd`: a deck 2.47
up, newels every 1.2 m, balusters every 0.12, a 70 x 60 cap at 1.0). Shoves go through
`take_blow`, which passes on only the momentum a shover's weight can leave in him:

| group Q (rancher, cowboy, widow) | breaks | ends |
|---|---|---|
| faint against it | nothing | slumped on the deck |
| standing shove backwards (250 N·s, ~1.6 m/s) | nothing | folded back over it |
| standing shove face-first | cap at 0.2 s, 6-7 balusters by 0.7 s | over and down, on the floor |
| running charge (320 N·s, ~2 m/s), either way | cap and 5-6 balusters within 0.3-1.2 s | on the floor |
| dead at a run | cap and 6-7 balusters by 0.7-1.6 s | through, ~3 m out on the floor |

- **Cost:** ten men going down at once in the open: collapse frame 2.45 ms with it, 2.58
  without (medians of four runs in one worktree), within the noise. Contact reports and reads
  run only near timber; ten men on contact reports all the time had p99 spikes to ~25 ms.
- **Tests:** `tests/test_body_impacts.gd`. Thrown into a railing at 3.5 m/s it breaks (and fails
  without the hook); slumped against it nothing; dropped on boards nothing.
- **Footage:** for the PR. The game's breakable rails are those built of members (the saloon
  balcony's, the saloon stair's hand rail and balusters, the hitching rail; the porches have
  none); the oak walkway's in the hotel is art's drawn boards and won't break until it's built of
  members.

## After Sean's "keep going" (2026-10-21, later)

- **He carries on through.** The engine holds a member rigid until it breaks, so it stopped him
  harder than a real rail could. Now what it took past what breaks it goes back to him
  (`_give_back`, and its like on the nail rule). Trim (balustrades, hand rails) gives way at its
  nails before its wood: each member it touches is a joint worth ½ × `nailed_moment` × 0.15 rad
  (~10 mm of slip at its nails, after the USDA Wood Handbook's load-slip of nailed joints; to be
  judged by eye). A 1.2 m oak cap goes at ~51 J (its wood ~150), a baluster at ~6.5 J.

| group Q, rancher | before | now |
|---|---|---|
| dead at a run: speed through the rail | 0.6 m/s, landing 3.1 m out | 1.5 m/s, landing 4.5 m out |
| charge face-first | 0.5 m/s, 1.0 m out | 1.2-1.5 m/s, 2.0 m out |
| shove backwards | holds | goes through (it's a full-weight shove) |
| faint | holds | holds |

  `tests/test_body_impacts.gd` guards it: his chest still at 0.87 m/s through the rail without the
  give-back, more than 1 with it. The test railing's deck is now a sill (grounded): before, the
  first break dropped the whole test railing, so the "it breaks" test passed for the wrong reason.

- **The game's own saloon in the lab** (group T, fixture `saloon_game`: `SaloonBuilding`, its stair
  of members up the front wall, its balcony's rail of trim; places by name, `spot`):

| fall (rancher) | his centre of mass fell | broke |
|---|---|---|
| shot from behind at the balcony rail | 0.83 m (on the balcony) | 1 baluster |
| faint at the balcony rail | 0.83 m (on the balcony) | nothing |
| shot dead at the balcony rail | 0.84 m (on the balcony) | nothing |
| shoved face-first into the balcony rail | 0.63 m (draped over it) | nothing |
| charged backwards into the balcony rail | 3.13 m (to the floor below) | the cap and 4 balusters |
| shot from behind on the stair, mid-flight | 1.42 m (a few steps down) | |
| shot in front at the stair's head, facing up it | 1.39 m (slides about 1 m down) | |
| shot from behind at the stair's head | 0.94 m (stuck at the top) | |
| shot dead at the stair's head | 0.67 m (crouched at the top) | |

  The stair's head is the even knee-buckle: `docs/briefs/collapse.md`.
