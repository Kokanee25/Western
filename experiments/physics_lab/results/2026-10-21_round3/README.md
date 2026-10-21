# 2026-10-21: the falls' third round (proposed; Sean's OK needed before merging)

Sean (2026-10-21): the brief's "What's left" one family at a time, each against the last, then hit
reactions short of a fall ("make it the wound's consequence, at a believable speed"). Then: "run
this round's baseline and every fix" on the Studio's men (`bold_cowboy_s0`, `old_rancher_s1`,
`young_drifter_s1`) with `--model`, one run kept on the outlaw. Brief: `docs/briefs/fix-the-falls.md`.

## What changes in `HumanBody` (each step measured against the last)

| step | what | outlaw, 69 falls: flags |
|---|---|---|
| main (233c838 + the Studio's men) | | 90 |
| 1 | **The light links' inertia ×4 (neck), ×3 (hands, feet)** (`INERTIA_SCALE`), mass unchanged: Jolt couldn't hold a 1 kg neck between a 17 kg chest and a 5.5 kg head as he landed. Swing past the limit 12 → 0 (summed 685 → 340 deg), sunk 8 → 1, the beam's lingering 52 → 0 | 21 |
| 2 | **Parts only resting on each other collide** (`_keep_apart`, `_rejoin_apart`): left out because they touched as he went, seated at a table his forearm went 13 cm into his chest. Only pairs sunk > 1.5 cm in are left out, until they part or sink 2 cm further. Limbs through the body 4 → 0 | |
| 3 | **No more push than physics** on every path into `go_limp()`: `take_blow` (falling timber) puts him down only if its push would (`knockdown_speed`, as a blast) and gives the inelastic share (p·M/(m+M)); a blast throws along its own line (a +0.35 lift was added); a torn-off limb takes its own blast push for its face and weight (`_limb_throw`), no thrown-in 3 m/s or random spin ±8 rad/s. The other paths were already physics: the ball's own momentum on the part it hit; his own momentum when he can't stand | |
| 4 | **Hit and still up, the wound's consequence** (`_favour_step`), see below | (not falls) |
| 2-4 together | | 77 (61 of them one scenario: the beam's legs rolling over after he lands) |
| 5 | **His hat comes off when it meets the ground** (`_hat_meets_ground`): kept on as part of his head, its brim went 6-15 cm into the floor in 55-63 of the 69 falls | 77 |
| 6 | **Hip and spine cones centred on their anatomical middle** (`CONE_CENTRE`): the hip to 120 forward and 20 back (it went 60 back), the low back 38/14, the chest 34/18 | **17** |

Tried and dropped (numbers in the session; patch kept outside the repo): **anatomical 6-DOF
joints** for every ball joint (27 flags against step 1's 11 on the then 50 falls: feet sinking,
never settling); Jolt's Baumgarte 0.3-0.5 and 16 position steps (global, mixed); leather-soled feet
0.4-0.6 (kneeling 7.6 → 4.3 s but feet sliding where he slumps); tone order, asymmetric fades.

## The hit that doesn't drop him

No flinch or wince (Sean, 2026-10-18). What the wound does comes on as a hurt would: a critically
damped spring (90% in ~1.2 s, nothing in the first tenth of a second, never faster than ~12 deg/s)
toward how much he favours each part: the worst torn muscle there (at once) plus that part's share
of his pain (which arrives over Physiology's 3 s). A leg: weight off it, the knee eased (24 deg by
1.5 s), a shorter stride, slower (0.77 m/s asked 1.4), a limp past 0.6. An arm: the gun hand sags
out of the aim (20 deg at full), the other arm's held in and not swung. The body: guarding, bent
toward the wound (13 deg by 1.5 s), slower (1.40 → 0.99 m/s). Sheets `side_R_*.jpg` (main above:
nothing; this below), times after the ball.

## The Studio's men (`--model`)

- **Their physics is the outlaw's.** Every body shares the anatomy's capsules, masses and joints
  (`Anatomy.shared()`). At every step the outlaw, rancher and drifter give bit-identical numbers;
  the hatless bold cowboy diverges chaotically (no hat body changes Jolt's body list): main 101,
  step 1 19, round 3 16, cones 18.
- **Only on them: their meshes don't fit the capsules.** How far the skinned mesh lies past the
  capsules (rest pose; outlaw / bold / rancher / drifter): neck 10 / 18 / 21 / 18 cm, pelvis - / 9 /
  13 / 8, abdomen - / - / 11 / 7, shins 4 / 8 / 9 / 6. So lying down the mesh goes into the floor
  more than 5 cm in 34-64 of the 69 falls (outlaw 0-2): the rancher's belly 11 cm, the bold cowboy's
  boots 8, the drifter's head 8. Nothing this round changes it (it's the fit).
- **Their shoulders follow the neck.** 500-1,160 vertices of shoulder and collar, up to 26 cm out,
  are skinned mostly to the neck bone (the outlaw: 61, within 15 cm). The neck is its own joint, so
  when it turns in a fall the shoulders swing with it. A blind judge didn't see it at sheet size.
  For the characters session: the shoulders to the chest bone.
- **The hat** (rancher, drifter; the outlaw too): see step 5. The judge's table and kneeling
  sheets were decided by it.

## Blind judges (fresh sub-agents, sheets unlabelled and shuffled)

- First (8 outlaw falls, round 3 before steps 5-6): this round 2 (seated, blackout), main 3 (the
  beam: "a full backbend bridge on his head and heels"; the blast at his feet; the blast in front),
  even 3.
- Second (17 sheets: the outlaw's 7, the rancher's and drifter's 5 each, after step 6): **this round
  6** (the three standing blackouts and the three seated falls, mostly the hat), **main 4** (the
  beam on all three men, the blast in front), even 7.
- **Left for Sean (a call):** the beam and the blast in front look better on main because main
  pushes harder than physics allows: the beam's whole momentum (200 N·s where a collision gives
  123) throws him flat as a plank; the blast's added lift rolls him over. With the honest push the
  beam drives his chest down and back over planted feet and he arches (now within the joints'
  ranges: knees 45, hips 13 back, the low back at its end) and the blast sits him down. Keep the
  physics (and fix the planted feet and locked knees next), or keep main's pushes for those two.

## Still wrong (both versions)

- The torso standing on its stumps for ~0.9 s after a blast takes both shins (`N_blast_at_feet`).
- Face first from a shove behind: a head-first jackknife, the neck folded under, the arms limp.
- The standing faint folds his knees under him (items 2 and 6): his weight stands 1.2 cm ahead of
  his ankles (a real man's 4-5): any collapse goes straight down. A stance with the weight forward
  is a pose change (Sean's call).
- Running stumbles land with joints 3-4 cm apart and the low back past its range for a few ticks.

## Numbers

`tally.py build/physics_lab/men/<step>_<man>` (steps main, step1, round3, hat, cone; men as above).
Sheets: `side_<scenario>.jpg` (the outlaw), `<man>_<scenario>.jpg` (the Studio's men), main above,
this round below; columns 0, 0.15, 0.3, 0.45, 0.6, 0.9, 1.5, 3 s.
