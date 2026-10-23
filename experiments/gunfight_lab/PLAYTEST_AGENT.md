# Playtest: ten gunfights in the new saloon

You are a playtester. You have **not** read the game's code and mustn't: don't open anything under
`src/`, `experiments/` (but this file), `tests/`, `DESIGN.md` or `docs/briefs/`. Play the way a
player would and report what you find.

The game is a first-person Western, Salt Creek, 1882. Three gunmen, Brody, Lyle and the Kid, are
in a saloon with you. You have a single-action revolver (cock, then fire; `shoot N` does both) and
five rounds; reloading is one cartridge at a time (`press reload 3`). Nobody's an enemy until it
comes to shooting: you can start it with your first shot, or wait and they'll go for their guns
after about six seconds.

You play through a command line (the "dev bridge"); every command answers with one line of JSON.

## Starting and stopping

```sh
python3 tools/bridge.py start --headless          # the game, not drawn (a minute to start)
python3 tools/bridge.py "COMMAND" "COMMAND" ...    # any number of commands, run in order
python3 tools/bridge.py stop
```

## A fight

`gf_play SETUP seed=N` sets one up and answers once they're in (it can take ~20 s the first time:
the saloon is being built). Setups: `spec_hall`, `spec_stair`, `spec_gallery`, `spec_back`,
`spec_front`. `gf_result` says whether it's over, how long it's run and each man's state. Play it
with the ordinary commands:

- `read all` (where you are, who's near: distance, side, armed, mood), `read people`, `events 20`
  (what was said and done: **their words are your best clue**).
- `look NAME` (turn to face a man), `turn DEGREES [PITCH]`, `shoot N`, `press aim 1`,
  `press crouch_toggle`, `walk X Z` / `walk X Z run` (metres; `read all` gives yours),
  `press reload 3`, `wait SECONDS`, `press shout` ("Drop it!" with your gun out).
- `weapon revolver` draws (your gun starts away).

## What to do

Play **ten fights**: each setup twice, seeds 1 and 2 (`gf_play spec_hall seed=1`, then
`gf_play spec_hall seed=2`, ...). Play each one for real until `gf_result` says it's over (or
you're down). Vary what you do: shoot first in some, wait for them in others; stand and shoot,
crouch, move, back off through a door. Note after each: how long it lasted, what each man did, who
gave up or ran and when, whether that seemed earned (was he hurt? were his friends down? was he
alone or cornered?), and anything that felt wrong or unfair.

## The report

Write `docs/playtests/2026-10-23-gunfight.md`, in plain English for the game's director (not a
programmer):

- **The ten fights**: a line or three each (setup, what you did, what they did, how it ended, how
  long).
- **Did they fight?** Did they shoot back, take cover, move, come at you? Or fold?
- **Who quit, and was it earned?**
- **What broke**: commands that did nothing, men stuck or walking through walls, anything odd.
- **What was fun**, and **what was flat**.
- **The top three things to fix**, most important first.

Short sentences. Don't guess at causes in the code.
