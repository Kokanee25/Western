# The first instant's cost (#596 step 3), 2026-11-05

The flash (one light and 12 unlit glows), the dust ring (~88 puffs) and the dirt thrown up (~240
streaks) added to `BlastCloud`, against main's three files (`blast_cloud.gd`, `blast_tuning.gd`,
`dynamite_stick.gd`), alternately on one machine, three runs each:

```sh
build/gate/run2.sh   # (the session's: before = `git show origin/main:<file>`, after = the branch)
printf 'bf_blast in=street fuse=1 seconds=6 out=X.json\nquit\n'      # Main Street, one stick
printf 'bf_blast at=6.0,0.8,6.0 fuse=1 seconds=6 out=X.json\nquit\n' # the spec saloon, one stick
python3 experiments/blast_freeze/gate.py X.json ...  # -> gate.jsonl
```

| one stick | worst frame after it, here (Sean's x0.65) | `blast_fx` on its tick (ms here) |
|---|---|---|
| street, main | 143, 130, 112 (93, 85, 73) | 4.6, 6.2, 5.1 |
| street, first instant | 103, 116, 106 (67, 76, 69) | 4.2, 4.9, 4.6 |
| saloon, main | 102, 101, 94 (66, 65, 61) | 5.0, 4.6, 4.6 |
| saloon, first instant | 106, 93, 83 (69, 60, 54) | 4.3, 4.3, 4.3 |

**One hitch under ~100 ms at Sean's: passes** before and after (worst 76). The same members break
(street 358-360 both, saloon 632). **Back above 50 fps within 0.5 s: fails before and after alike on
this machine**: after the session's worker restarted, its steady frame is ~19-20 ms at Sean's scale
(the 5 s mean after the stick, `mean5_sean`, is the same both ways), so no run gets 15 frames running
under 20 ms. It isn't the blast's look: the after runs are back as soon as main's (street 1.9-3.2 s
both ways). Before the restart (a faster machine) main's street came back in 0.65-1.4 s.

**What it found:** each new `ParticleProcessMaterial` cost ~4 ms when first given to its particles
(`GPUParticles3D.process_material = ...`, every material every blast, warm or not): the flash's on the
blast's own tick (`blast_fx` 3.6 -> 8.5 ms with the first version), and the ring's, the dirt's and the
dust's own three on the tick after (10.6 ms; the dust's three were #538's "5-8 ms"). Now each kind
takes one of two materials made once (`BlastCloud._pm`, `POOL`): the cloud's part of the blast's tick
4.3 -> 0.33 ms, the tick after 10.6 -> 0.42 ms (in-game prints, the street). They're made at load by
the revolver's warm-up (drawn games), or by the first stick to enter the world (headless runs: ~26
ms once, seconds before any bang). Caching the curve and ramp textures alone didn't move it.

**At Sean's:** the first instant itself is ~0.2 ms of CPU on the blast's tick and ~0.3 ms the tick
after (the dust's own three no longer pay the material either; main's paid it on that tick); on the GPU ~340 more particles for
0.1 s (the glows), 3 s (the ring) and 4 s (the dirt): three more draws while they last. The drawn
frame's GPU cost wasn't measured (lavapipe); by count it is a small share of the dust's own.
