# The farmhouse on the widow's pad (G6, #731, 2026-11-09)

The same scripted runs (`farm_bot.gd`, 8 seeds a way, `--deterministic`) on the old town's
farmhouse (`town/`, main at 1a57e08 with this branch's changes, the switch off) and on the valley's
(`valley/`, `--args="--world=valley"`): the same house from its spec, on the widow's pad at
(1712, -560), its hills carried from the old town into the bake, the bot's ways round the house and
its start carried with them (`Farmhouse.carried`).

```sh
python3 experiments/farmhouse/run.py --ways=front,breach,back --seeds=1-8 --jobs=2 --out=experiments/farmhouse/results/2026-11-09_valley/town
python3 experiments/farmhouse/run.py --ways=front,breach,back --seeds=1-8 --jobs=2 --args="--world=valley" --out=experiments/farmhouse/results/2026-11-09_valley/valley
```

| way | site | won | rancher lives | you down | cut loose | a rover found you first | the surprise (alarm at the blast) | alarm (s, median) |
|---|---|---|---|---|---|---|---|---|
| front | town | 0/8 | 4/8 | 5/8 | 1 | 8 | - | 13.0 |
| | valley | 0/8 | 6/8 | 7/8 | 4 | 8 | - | 12.9 |
| breach | town | 1/8 | 8/8 | 7/8 | 2 | 0 | 8/8 | 159.7 |
| | valley | 1/8 | 7/8 | 6/8 | 4 | 0 | 8/8 | 159.6 |
| back | town | 0/8 | 7/8 | 7/8 | 0 | 0 | - | 124.8 |
| | valley | 0/8 | 6/8 | 8/8 | 1 | 0 | - | 125.8 |
| **all** | town | **1/24** | **19/24** | 19/24 | 3 | 8 | 8/8 | |
| | valley | **1/24** | **19/24** | 21/24 | 9 | 8 | 8/8 | |

The same within noise: the alarm at the same moment each way (the rovers' beats, the windows and
the hiding spot as in town), the quiet ways (the back, the breach's wide round) found by no rover in
either, the surprise holding 8 of 8 in both; one win in 24 in each (#565's record was 2 of 24), the
rancher alive 19 of 24 in each. The valley's runs get him cut loose more (9 against 3), then lose on
the way out as the town's do.

A first valley round removed the blast's rubble as "fallen through the ground" (Structure's
`lost_below` was Y -5 everywhere; the widow's pad is at -8): now a structure standing below the
town's ground loses rubble 5 m below itself (the town's, all at or over Y 0, unchanged). These are
the runs after that fix; none fell through. Each run's record is in `*/runs/`, the tables
in `*/summary.md`.
