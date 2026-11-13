# The valley's townsfolk (#756, No Law step 1)

The code: `src/people/valley_folk.gd` (`ValleyFolk`), `src/people/sit_chore.gd` (`SitChore`); data
`config/valley_folk.json`; tests `tests/test_valley_folk.gd`; LAYOUT "src/people".

Sean hadn't answered #755 (the saloon onto its lot now, A, or in #695's week, B), so this is B: the
saloon stays a grey block and tonight's set is in its yard (`saloon_annex`, Sean's #700): a kit bar
with the barkeep behind it and two men drinking, the card table with Earl and the drifter sat at
it and the north and south chairs free, two lit oil lamps, tin cups. When the saloon goes onto its
lot the set moves inside (the data's `set` and `post`s) and the people with it.

## See it

```sh
godot -- --world=valley        # 7 (the hour key) three times: 21.30, everyone at his post
                               # 7 twice (17.36), then T to run the clock: they walk in from 19:00
python3 tools/bridge.py start --game-args=--world=valley
python3 tools/bridge.py "time 21" "wait 3" "camera 29.4 2.1 -7.2 28.4 0.9 -15.4 60" "screenshot /tmp/yard.png"
```

The yard is on Main Street's north side, ~30 m east of the crossroads, between the saloon's block
and the saloon lane.

| | |
|---|---|
| ![the yard at nine](results/2026-11-10_yard_night.png) | ![behind the bar](results/2026-11-10_bar_and_table.png) |

## The frame at the saloon's yard

`tools/valley/valley_bench.gd --spots=crossroads,saloon_yard` drawn under lavapipe (real look, 60
frames), `--no-folk` (the before) and with them; at the yard the clock set to 21 (all five in).
Render CPU scaled to Sean's (x0.65); each drawn frame here runs 2 physics ticks (the catch-up cap),
so the people's ms a frame is two ticks' worth:

| Spot | render CPU at Sean's | draws | primitives | people (ms a frame, here) |
|---|---|---|---|---|
| `crossroads` (noon), before | 0.82 | 538 | 430k | 0.18 |
| `crossroads` (noon), the folk built, out | 0.73 | 538 | 430k | 0.12 |
| `saloon_yard` (21:00), before | 0.59 | 230 | 468k | 0.10 |
| `saloon_yard` (21:00), five men in | 1.01 | 823 | 4,889k | 5.84 |

Inside the budget (4.0 ms render CPU, 4.0 ms people at Sean's): +0.42 ms of render CPU, and the
people on the main thread ~4.3 ms a frame here (5.84 less `people_prep_sum`, the men's own work on
the worker pool, which the bench's sum counts again) = ~2.1 ms a tick = ~1.4 ms at Sean's. The
primitives are the five Studio men (GPU, not this budget). Load: the five men are built while the
valley loads, ~4.3 s the first time a process builds their models (then ~12 ms a man), plus ~0.25 s
for the folk's places and ~0.09 s for the set.

A sitting man can now tick slowly far from you (`SitChore.lets_slow`; a busy chore kept every man
at it on every tick, PeopleTick's bands).

## Step 2 (#766): sat at the card table, the game going

The code: `src/player/player_seat.gd` (`PlayerSeat`), `src/people/card_game.gd` (`CardGame`),
`src/people/poker.gd` (`Poker`); data `config/card_game.json`; tests `tests/test_card_game.gd`;
LAYOUT "src/player" and "src/people". Still B on #755: the table is in the saloon's yard.

```sh
godot -- --world=valley        # 7 three times (21:30); walk to the yard; by a free chair, facing it, E
python3 tools/bridge.py start --game-args=--world=valley
python3 tools/bridge.py "time 21" "wait 3" "sit n" "cards wait 1" "nod" "stand"
```

Sat: you look round (110 degrees either way of the chair), can't walk, crouch, jump or draw (the gun
says "you're sat at the table" when you try); E stands you a step clear. The men deal you in from the
next hand: five-card draw, a dollar ante, bets of one then two chips, two raises a round; your cards
face up before you; on your turn the screen asks, a nod calls or checks and a shake folds, and if you
do neither for 7 s you check, or fold to a bet. Earl deals himself one off the bottom 30% of his deals
(`cheat`). A shot within 40 m stops the hand where it lies (the men, townsfolk, get up out of their
chairs anyway); a man out of his chair stops it; it deals again 25 s after it's calm with two sat.
An act can `interrupt(reason, hold)` the game and `hold` you in your seat (`PlayerSeat.hold`): the
next step's red shirt walks up. The chair kicked out from under you drops you flat for 1.4 s.

### The frame

`tools/valley/valley_bench.gd --spots=saloon_yard,card_seat` drawn under lavapipe (real look, 60
frames, 21:00); `card_seat` is you sat in the north chair, the game going (a betting round), looking
at the table and Earl past it:

| Spot | render CPU at Sean's | draws | primitives | people (ms a frame, here) | card game (ms a frame, here) |
|---|---|---|---|---|---|
| `saloon_yard` (step 1) | 1.01 | 823 | 4,889k | 5.84 | - |
| `saloon_yard`, the game going | 0.95 | 827 | 4,895k | 6.20 | 0.77 |
| `card_seat` | 1.14 | 1,067 | 4,660k | 7.93 | 0.51 |

Inside the budget: render CPU 1.14 of 4.0 at Sean's; the people at the table ~3.1 ms a tick here
(7.93 less `people_prep_sum` 1.77, two ticks a drawn frame) = ~2.0 ms at Sean's of 4.0 (three men
within arm's length look at you closely: `lines_senses` and `sight_sync` ~2 ms a frame here, 0.2 from
the street). The card game drawn ~0.25-0.4 ms a tick here while cards and chips move; headless
(`build`-style Prof sums, 600 ticks) 0.05-0.07 ms a tick, and sat or stood by the chair the same.
The cards and chips are two MultiMeshes (+4 draws; the faces up are text, a draw each).

## Step 3 (#773): the red shirt, the kick and the murder

The code: `src/moments/no_law_murder.gd` (`NoLawMurder`, a `CardCheat`, which is now an `Act`); data
`config/moments/no_law_murder.json`, the two men in `config/valley_folk.json` (`act`); tests
`tests/test_no_law_murder.gd`; LAYOUT "src/moments" and "src/people". Still B on #755: the yard.

```sh
godot -- --world=valley        # 7 three times (21:30); sit at the card table; after your first hand
                               # (or at 22:00 wherever you are) it happens
python3 tools/bridge.py start --game-args=--world=valley,--no-murder
python3 tools/bridge.py "time 21" "wait 3" "sit n" "look earl" "moment no_law_murder" "wait 30" "moment_result" "story"
experiments/valley_folk/film_murder.sh build/murder_films [seat|bar]   # the films (~25 min each here)
```

What happens (`moment_result`'s `events`, the test's run): the stranger in from the street and sat
in the south chair at 3.5 s ("Evening. Mind if I sit in a while?"); Cody in at 6.5 s; within 6 m of
the table the game stops and holds, you're held (E: "The stranger's hand is on your arm. Sit
still."), the stranger: "Don't move, friend..."; Cody's accusation at 3.5 m, Earl's "Now, Cody, I
never..." and the kick from behind (the clip's boot on the crest rail, then a spindle broken: the
chair goes, Earl with it) at ~12.5 s; the draw, over him, one shot at ~17 s ("Dead (brain)"); "Ain't
no law left in this valley to save you now, Earl."; he holsters and walks out; the barman's "Jesus,
Cody, my chair!" ~1.6 s on, the room silent till then (the folk hushed); out of the yard at ~23 s;
the stranger's word 4 s later, you let go, he goes; the drifter (5 s) and the miner (9 s) leave;
Cody and the stranger walk off east down Main Street and are taken out once out of your sight or
45 m on. Earl's body stays (ValleyFolk: `dead`). Not sat, it happens the same (`seen_from` heard /
yard / away). StoryState: `nolaw.murder` done, `nolaw.seen_from`, `nolaw.witnessed`, `nolaw.earl`.

From step 2's playtest, where it touches this scene (CivilianBrain): a man's lines 2.5 s apart at
least (fire, thanks and his chair aside); a shot's cries spread 0.15-1.1 s, kept back if another just
cried, never a line another man said in the last 4 s; a gun drawn within 9 m that a man sees: a line
("Whoa, now. Easy with that iron.") and his eye on the gunman; a man whose chair went from under him
says so once he's up.

### The frame and the films

`tools/valley/valley_bench.gd --spots=saloon_yard,card_seat,murder_seat` drawn under lavapipe (real look,
60 frames, 21:00); `murder_seat` is you sat in the north chair as it plays, measured from Cody's arrival at
Earl (the kick, Earl going over, the draw; seven men in the yard):

| Spot | render CPU at Sean's | draws | primitives | people a tick at Sean's | card game (ms a frame, here) |
|---|---|---|---|---|---|
| `saloon_yard` | 1.13 | 827 | 4,895k | ~1.6 | - |
| `card_seat` | 1.33 | 1,067 | 4,660k | ~2.3 | 0.13 |
| `murder_seat` | 1.42 | 1,138 | 6,116k | ~3.2 | 0.07 |

People a tick as step 2 counted them: (people less `people_prep_sum`) over two ticks a drawn frame, x0.65.
This VM ran `saloon_yard` and `card_seat` ~17% slower than step 2's did (its 5.84 and 7.93 ms of people a
frame then are 6.85 and 9.08 now, with nothing changed there but when the brains speak), so `card_seat`
is as it was. The murder is in budget: render CPU 1.42 of 4.0, people ~3.2 of 4.0.

Films (`film_murder.sh`, Movie Maker under lavapipe; the crash guard's "stalled over 5 s" note on screen is
the movie writer's slow frames, not the game): `results/2026-11-10_murder/murder_from_the_chair.mp4` (sat in
the north chair, turned to Earl; the view turned down at 12 s), `murder_from_the_yard.mp4` (a camera by the
table's south-west corner). In both runs the kick's first touch stopped on the crest rail, the second broke a
spindle and the chair went (12.5 s), Earl pitched forward over the table's edge, one shot, "Dead (brain)".

## Step 4 (#796): the morning after and the sheriff's last day

Cody isn't the red shirt any more (Sean on #796): the role is `cody` in the data and code, his stand-in is the
blacksmith's model (grey-blue work shirt), and he shouts "Earl, you cheating son of a bitch!" as he's taken in
off the street, not at the table (Sean's note, 2026-11-12); the stranger's warning comes `warn_after_s` after.

The morning after (`config/valley_folk.json` `morning`, `talk`; ValleyFolk): with the murder done and the clock
come round to the day (`nolaw.morning`), Earl's body goes to the undertaker's once you're off it (out of the
world for good; `nolaw.earl` = undertaker, `death.earl` his record). Three day folk on the walks, 7-19: the
townsman (the hotel's walk) tells you "you were sat right there at the table" if you were, else the town's
versions; the loudmouth (the saloon's walk) that nobody'll take Cody in; the undertaker has Earl laid out.
Their lines are No Law's script's (`docs/scripts/no_law.json` on PR #837), chosen by StoryState facts
(`ValleyFolk.story_holds`). Nobody arrests Cody.

The sheriff's last day (`SheriffDies`, `config/moments/sheriff_dies.json`): from 7.5 a young man the doctor
sent finds you in town; the doctor at his door says his line by `sheriff.care` and leads you through the
front office and the hall to the sick room; the sheriff on his back on an iron cot (`on_back`, a new pose),
his wife sat by him (the widow's model). His words clear (care good) or fading (poor, left); poor or left,
Doc has you hold him (E); the oath; nod or shake (a shake or no answer: "That's not the way this works,
son."); the badge, his revolver (the story's Harlan is unarmed till now: `Player.lacks`), his last words, and
his gut takes him (Physiology's own death; he stays on the cot). Doc's the acting law and keeps you on.

See it: `-- --world=valley --mission=sheriff_dies [--care=good|poor|left]` (the morning set up, you on Main
Street west of the doctor's), or the bridge's `moment sheriff_dies set_up=1 care=poor`. Tests:
`tests/test_sheriff_dies.gd` (the facts and lines, the morning, both answers).
