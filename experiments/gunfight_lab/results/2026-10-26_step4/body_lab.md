# The body lab, main (c1352a34) against step 4 (c69aa698, people threads on)

`python3 experiments/body_lab/run.py --out=build/body_lab/<run> --jobs=1` on each build (216
records: every scenario on bold_cowboy_s0, old_rancher_s1, young_drifter_s1, hothead_lyle_s1).
Its `report.py gather` stops on `KeyError: 'check'` on both builds (the lab's script, as in step
2), so each `summary.json` was compared whole.

**216 of 216 records identical, byte for byte as JSON.**
