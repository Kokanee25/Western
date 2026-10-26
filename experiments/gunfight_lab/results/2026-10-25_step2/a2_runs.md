# The (a2) build's two runs (9f155bc4, before the seeding fix)

Their records were deleted by mistake before they were copied here; this is the `perf.py` table
as printed (the final build, 4f8c8986, differs only in the two seeds, so its runs `step2_a` and
`step2_b` stand for it). `same_fight.py` on these two: **8 of 10 the same**: s4 by the player's
blood alone (4694 vs 4699), s6 from 91% in, after him. That is what found the unseeded
`Physiology.roll_rng` of the player (README, "The gate").

| | step2_a (a2) | step2_b (a2) |
|---|---|---|
| frame_ms | 14.70 | 14.80 |
| frame_p95_ms | 19.05 | 19.30 |
| people_ms | 8.04 | 8.10 |
| people_p95_ms | 10.60 | 10.80 |
| three_men_ms | 3.47 | 3.62 |
| window / step / rest | 10.06 / 1.58 / 2.99 | 10.13 / 1.59 / 3.02 |
| people_body | 3.16 | 3.18 |
| people_skeleton | 0.48 | 0.48 |
| outlaw_brain | 2.43 | 2.45 |
| senses | 1.11 | 1.12 |
| q_writes | 60.13 | 60.13 |
| q_cover | 71.13 | 70.98 |
