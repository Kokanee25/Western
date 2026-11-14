# The card cheat (experiments/card_cheat)

The showcase moment (`docs/briefs/showcase-moments.md`, `src/moments/card_cheat.gd`,
`config/moments/card_cheat.json`) run, measured and filmed.

    export PATH=$HOME/godot:$PATH
    python3 experiments/card_cheat/run.py --runs=20 --animated=1 --out=build/card_cheat/runs_animated   # 20 runs, tally.md
    python3 experiments/card_cheat/run.py --runs=20 --animated=0 --out=build/card_cheat/runs_pose       # the pose-to-pose kick
    experiments/card_cheat/film.sh build/card_cheat/films [bar|door|old|all]                             # the films (~8 min each on lavapipe)

In a game: `python3 tools/bridge.py start`, then `moment card_cheat [animated=0] [hour=17.5]
[reach_k=0.65]`, `moment_result [wait [S]]`. In a build: `-- --moment=card_cheat` and walk into the
saloon (it starts when you're within 7 m of the table).

Results by date in `results/`.
