# The perception lab

Roadmap Phase 3, beside the gunfight lab (`docs/briefs/labs.md` "People and systems labs",
"Perception and information"): what people see, hear and know, and whether anyone acts on what he
couldn't know. **It changes nothing in the game and claims no improvement.** The men are the
game's: their eyes and ears are `Senses` (`src/people/senses.gd`), their minds `CivilianBrain` and
`OutlawBrain`, the sounds the game's own (`DeedWatch`, `Player._footsteps`), all untouched. Only
where the men stand, which of the Studio's bodies they wear (`bold_cowboy_s0`, `old_rancher_s1`,
`young_drifter_s1`), the hour and the lamps are the lab's, and the two things it does to set a
case up (named in each case's `setup`): it starts a fight (`OutlawBrain._provoked`) and has a
gunman hold his fire (`_next_shot`), so a search can be watched without the player being shot.

**No scripted outcomes.** Every case is judged against expectations written by hand in
`scenarios.json` (what any person standing there would have noticed, and why). A result that
would need a special case to come out right is reported as a failure, never fixed with one.

Everything is in this folder. Outputs go under `build/perception_lab/` (git-ignored). The
baseline's tables and findings are in `baseline/`.

## Commands

```sh
# every group, one fresh game each (~12 min on this workspace's 4 cores; --repeat=2 checks the seed)
python3 experiments/perception_lab/run.py --out=build/perception_lab/base
python3 experiments/perception_lab/run.py --group=sight,hearing --out=...
python3 experiments/perception_lab/run.py --case=street_10m,through_window --out=...
python3 experiments/perception_lab/run.py --list
python3 experiments/perception_lab/run.py --repeat=2 --out=...           # same seed, same verdicts?
python3 experiments/perception_lab/run.py --table=ROOT [--keep=experiments/perception_lab/baseline]   # no Godot
# in a game you're driving (one group a game: it clears the town first)
python3 tools/bridge.py start --headless
python3 tools/bridge.py "perception hearing out=build/perception_lab/try" "quit"
python3 tools/bridge.py "perception_probe 10 0 0 8"     # windows, doors and lamps within 8 m: for placing cases
python3 tools/bridge.py "perception_known brody"        # what a man knows right now (any game, any lab)
```

`run.py` takes `--seed=N` (default scenarios.json's) and `--jobs=N` (3).

## The groups (`scenarios.json`)

Positions are in the street's space (Main Street along X at z −9; the saloon x 4.7–15.3 and the
store x −4.3–5.3 with their fronts on z 0 and their insides toward +z; the jail across at z −14 to
−25). `expect` is `true` (he should: missed if he doesn't), `false` (he can't: a false detection
if he does) or `"either"` (not judged), each with its `why`.

- **sight** (15 cases × day 12:00, golden 17:36, night 23:00 with the lamps as the game lights
  them, night with every lamp out): a watcher with bare `Senses` and a target standing or walking.
  The open street at 10, 25 and 45 m; a man under the porch lanterns at night; crouched in the
  dark; behind his back; walking across his side; behind the store's wall; round the saloon's
  corner; through the saloon's window; through the store's open door; through the batwings; across
  the saloon with its lamps out; behind four shots' gun smoke; behind a stick's dust. Measured:
  seconds to `spotted` (the reaction delay; `notice_s` 1 s is what a person needs to pick out a man
  in plain view), what the line from his eye meets first, the light Senses used.
- **hearing** (7 cases, night): listeners with bare `Senses`, a sound made by the game's own path
  (`Events.shot_fired`, `Events.shouted`, the player walking and cocking with real input). A shot
  in the saloon heard in the room, the street, the store, the jail and 50 m off; a shot in the
  street heard indoors; a shout at 20, 45 and 60 m; steps on the boardwalk and on dirt at 2, 5, 9
  and 16 m; running; the hammer cocked at 1.5, 4 and 6 m. Measured: heard or not, what he took it
  for, how far off his guess of where (m and degrees), and whether he now knows *who* made it
  without seeing him. The expectations follow the reference in `scenarios.json` (`_reference`).
- **search** (4 cases): an `OutlawBrain` gunman in a fight with the player (holding his fire); the
  player walks round the saloon's corner and stands still, or paces, or ducks into the store, or
  walks off into the dark. Measured: how long before he knows he's lost him (from the moment the
  line from his eye is truly blocked), his last-known against the truth, how near he goes to it
  and to where the player really is, when he gives up.
- **news** (2 cases): townsfolk (`CivilianBrain`) round a deed done by the player with real
  input: a shooting in the saloon (the barkeep sees it, the storekeeper next door and the deputy at
  the jail hear it, a passer-by 35 m off), and a hold-up in the store nobody hears (the deputy at
  his desk). Each man's knowledge at 1, 5, 30 and 90 s: heard a shot (and how near his guess), saw
  who, knows who (and whether only from the sound), knows a man was hit, knows of the hold-up.
- **leaks** (3 cases): a man who can't know something, and whether he acts as if he did: an
  outlaw 50 m off facing away when the player shoots a man in the saloon; a gang man whose friend
  faints silently behind the store's wall; an outlaw told to call the player out who has never
  seen or heard him.

In every group with brains, `_watch` samples each man four times a second against the truth and
logs as **leaks**: his idea of where the player is moving while he neither saw nor heard him
(`knows_without_sensing`, with the event that told him if any) and his facing the player's true
place, unseen and unheard, while facing away from where he thinks he is (`faces_unseen`).

## Files

- `bridge.gd`: the lab's bridge commands (`BridgeLab`, docs/LAYOUT.md "The dev bridge"):
  `perception`, `perception_list`, `perception_probe`, `perception_known`. Nothing in
  `src/debug/dev_bridge.gd` changed.
- `runner.gd`: one group (or case) in the running street, measured, written to `summary.json`
  (with each brain's track, four rows a second). `Runner.knowledge(man)` is what
  `perception_known` answers.
- `scenarios.json`: the cases, the roles' bodies, the hours, the expectations and their reasons.
- `run.py`: the runs (one fresh game a group, through the bridge's `--bridge-script`), the tables,
  the same-seed comparison and `--keep` for the baseline.
- `baseline/`: `baseline.md` (the table, the five biggest problems, the first fix), `tables.md`
  (every case), `baseline.json` (every summary without the tracks).

## Shared with the gunfight lab

The gunfight lab's fairness rests on this one: whether the gang sees and hears you fairly.
`perception_known PERSON` works in any game (a `gf_fight` included) and answers from the same
`Runner.knowledge`; the search cases use the gunfight lab's street; and `runner.gd`'s `_watch` (the
leak monitor) takes any man and any target, so a fight can be watched for leaks the same way.

## Determinism

The men's senses are seeded from `rng_seed` (the lab's seed × 100 + their order), Ballistics from
the seed, and each group runs in a fresh game on the same frame. `run.py --repeat=2` runs each
group twice and compares every verdict and delay.
