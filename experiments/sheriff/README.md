# The sheriff on the road (#746): the first story mission, rough

The card: `docs/missions/the-sheriff.md` (PR #743, the planning lane). The code: `src/missions/sheriff_on_road.gd`
(`SheriffOnRoad`), `src/moments/act.gd` (`Act`, the first cut of acts), `src/missions/head_gesture.gd`
(the nod and shake), `src/missions/story_state.gd` (the story's facts); data
`config/moments/the_sheriff.json`; tests `tests/test_sheriff.gd`; LAYOUT "src/missions".

## Play it

```sh
godot -- --world=valley --mission=sheriff     # dawn at Harlan's place; Enter afterwards starts again
python3 tools/bridge.py start --game-args=--world=valley,--mission=sheriff
python3 tools/bridge.py "walk opening_site" "look sheriff abdomen" "nod" "press shove 7" \
    "walk sheriffs_horse" "press shove 0.5" "moment_result wait 30" "story"
```

The blind playtest's brief: `PLAYTEST.md` (`tools/playtest.py start --game-args=--world=valley,--mission=sheriff`).

## What was built, and what's a stand-in

| Beat | Built | Stand-in |
|---|---|---|
| Dawn at Harlan's homestead | you on its pad at 6.3 (first sun), the clock running, facing down the ford path | the pad is the greybox's (no cabin yet) |
| The ford path to the East Road | the path is now one of the valley's ways (`ValleyMarkers.WAY_ROADS`), joined to his homestead and the East Road: `walk opening_site` goes by it (~350 m) | |
| The sheriff gut-shot at `opening_site` | a real ball through the belly (the hole, the blood on his shirt), then his body as the data has it; down (limp), conscious; lines by his blood loss (clear / weak / fading / out) | the man is the Studio's `sean_s3_talking`; typed lines; the red shirt described, not named |
| His horse at the site | the bay (`Horse`), reins hanging to the ground, a place `sheriffs_horse` | no rifle on the saddle (no new art) |
| Help or leave | your head: a nod or a shake read from your view (`HeadGesture`); walking off 45 m once you've found him is leaving him | the smallest nod/shake: no head animation, no prompt beyond a line on screen |
| First aid on another man | E held by his belly: your hand on the wound (bleed x0.25 while there); 6 s of it all told packs and binds it (`Physiology.apply_pressure`, the bandage drawn) | no kneel pose, no hands shown |
| Into town | E by his horse: a typed card, the road's length (~480 m) at a led horse's 1.3 m/s plus a minute getting him up, run on his body and the clock | the card stands for leading the horse (riding and leading aren't built: the horse lab's P2) |
| The doctor | `doctor_s2_talking` beside him before the doctor's lot; two lines by his state and your care; the horse put up at the livery's front | a greybox block for the doctor's; no interior; the end card |
| Leaving him | a card: a freighter finds him later (25 minutes on his body) | typed only |
| The story's first fact | `sheriff.care` = good / poor / left him, `sheriff.blood_loss`, `sheriff.packed`, `sheriff.answer`, in memory (`StoryState`), bridge `story` | not saved to disk yet (BUILD_ORDER 0.2) |

## His body, by the numbers (`tests/test_sheriff.gd`, Physiology run on the data's wound)

Gut-shot two game hours before dawn: 450 ml lost lying there; the belly wall weeps 2.4 ml/s and
doesn't clot (to 1,350 ml), 0.2 ml/s inside (to 300 ml). `care` good = packed, and no more than 0.30
of his blood lost at the doctor's.

| What you do | lost when you reach him | at the doctor's | care |
|---|---|---|---|
| run down (80 s), pack it, take him in | 0.127 | 0.157 | good |
| walk down (240 s), pack it, take him in | 0.197 | 0.224 | good |
| walk down, a few seconds' pressure, not packed | 0.197 | 0.355 | poor |
| walk down, never touch the wound | 0.197 | 0.355 | poor |
| dawdle 7 minutes more, then pack it | 0.354 | 0.377 | poor |
| leave him (found 25 min later) | 0.197 | 0.407, out cold | left him |

Untended he passes out (~0.41) and doesn't bleed to death on the road; the gut does for him ~30
game hours after the shot (Physiology's `gut_death_game_hours`): on day 2, as the story has it.
Whether the packing "holds" (clots under the pressure, `packing_holds` 0.5) is rolled by his seed:
in the bridge runs it held (0.155 at the doctor's after a `goto`).

## Played over the bridge (headless, 2026-11-10)

- **Well:** walked from the homestead by the ford path (350 m, 128 s), hailed at 25 m, asked at 3.5 m;
  nod; E 7 s: packed; E by his horse: 479 m, 429 s; the doctor; `sheriff.care` good (0.155).
- **Poorly:** nod, E 2 s, straight to his horse: poor (0.28 at the doctor's: not packed).
- **Left him:** shake ("You'd leave a man in the road? Then go on. Damn you."), walked home: past 45 m
  "Harlan! HARLAN!", the card, left him (0.40, out cold). Enter: dawn again.

## The frame at the opening site

`tools/valley/valley_bench.gd --spots=harlan_home,sheriff_site` drawn under lavapipe (real look, 60
frames), without and with `--mission=sheriff` (the sheriff, his body ticking, and his horse); render CPU
scaled to Sean's (x0.65); the budget is 4.0 ms of render CPU and 4.0 ms of people:

| Spot | render CPU at Sean's | draws | people (ms, here) |
|---|---|---|---|
| `harlan_home`, before | 0.81 | 390 | 0.09 |
| `harlan_home`, the mission on | 0.92 | 426 | 0.73 |
| `sheriff_site` (4 m from him), before | 0.65 | 247 | 0.10 |
| `sheriff_site`, the mission on | 0.73 | 302 | 0.71 |

Inside the budget: +0.08-0.11 ms of render CPU at Sean's and ~0.6 ms of people (one wounded man's
body; the train's engineer is the rest). (The mission run's `crossroads` row isn't the crossroads:
the mission put you at Harlan's place after the bench had placed you, so it's left out.) Logs:
`build/vb_before.log`, `build/vb_sheriff.log` (not kept).

## The blind playtest (`docs/playtests/2026-11-10-sheriff.md`)

Three tries, each ended right (good, poor, left him); his words changing with his state and how long
you took worked. Fixed after it: a shake or nod counts only when it changes your answer (turning away
to leave read as more shaking: "Damn you" three times); your hands on his wound are a yes (he asked
"Well? Nod or don't" after being packed); no debug words on the cards (`sheriff.care: ...`, "A
stand-in: ..."); a line at the start pointing you down to the road; the clock runs from first sun (6.3,
was 5.6: the road was near black at 50 m); a restart levels your view. Left for later: the
arrival in town is still a card and a man lying in the street (the doctor's "up the steps" with nobody
moving), and nothing you see shows the care's difference, only the doctor's words.
