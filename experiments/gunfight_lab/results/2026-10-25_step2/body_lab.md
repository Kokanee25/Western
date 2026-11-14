# The body lab, before (8cbfa2c2) against step 2

`python3 experiments/body_lab/run.py --out=build/body_lab/<run>` on each build (216 records: every
scenario on bold_cowboy_s0, old_rancher_s1, young_drifter_s1, hothead_lyle_s1). Its `report.py
gather` stops on `KeyError: 'check'` on both builds (the lab's script), so each `summary.json`
was compared whole.

| Runs | Same |
|---|---|
| before, twice | 216 of 216 |
| before against step 2 (43f9ef3c) | 176 of 216: 40 differ in `body.splats` alone (a splat's ml by 0.1, its size by a millimetre), in grab_chest/hand/neck/upper_arm, revolver_15m_hand/neck/upper_arm, shotgun_05m_belly/neck, soak_hand, all four men |
| the same 40 under `deterministic` (override.cfg) | 0 of 40: not the clock |
| before against (ab) and (abcd) on those 40 | 0 of 40; (a) alone (441ccb16) the same as step 2: (a) |
| before + the WoundSigns phase fix, against step 2 with it (4a858272) | **216 of 216** |

(a) adds 30 `FingerBone` objects a Studio man. `WoundSigns` took its every-fourth-tick phase from
`body.get_instance_id() % 4`, and instance ids count every object made before him, so his drips
fell on other ticks. The phase is his seed's now.
