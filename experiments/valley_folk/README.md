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
