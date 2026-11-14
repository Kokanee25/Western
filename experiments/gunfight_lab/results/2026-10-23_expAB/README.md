# Experiments A and B (2026-10-23/24)

These two experiments come from the consolidated combat review that Sean sent (four reviews: "the
existing systems need to survive the opening seconds of a gunfight").

- **A, wounded but dangerous:** if a man takes a survivable wound, does he keep making trouble?
- **B, get to cover:** can the three get out of the first exchange and make a second one?

Each experiment changed one thing, measured over 100 fights: five setups, two player styles,
seeds 1–5, and both openings (they draw first, you shoot first), against the baseline `base_now`.
Then the parts that worked were run together.

## What changed

| Run | Change | Where |
|---|---|---|
| `A_pain` | `pain_fight`: pain past disabling comes in bouts, not as a wall. The first bout, 1–2 s, comes as the pain passes 0.9 (longer for a green man), then more now and then while it stays past. Between bouts he fights hurt: worse aim, slower shots. | `OutlawBrain._pain_step`, `_pain_locked` |
| `A_floor` | `floor_fight`: shot off his feet and still conscious, with a gun in a hand that holds it and his fear under his nerve, he comes to on his belly and fights from there. | `HumanBody.come_to_ground` (the get-up stages, ending prone); `OutlawBrain._down_but_awake` |
| `A_both` | Both | |
| `B_doors` | The new saloon's partition doors swing into their rooms. The back rooms' doors stood open across the gallery, and the back room's door across the hall. | `building_lab/saloon.json` `"leaf": "outward"`; `spec_building._partitions` |
| `B_way` | Doors, plus `way_cost`: a cover spot is scored by the way he'd run to it, not the straight line | `Cover._best_in_town` (`ctx.by_way`) |
| `C_AB` | Doors + `pain_fight` + `floor_fight` | |
| `C_ABw` | Doors + `pain_fight` + `floor_fight` + `way_cost` | |

**The lab's measure changed too.** With `floor_fight`, a man down but conscious isn't counted out
of the fight for 6 s, because he may come to. Without that, the fight ended the instant the last
man went limp.

## Do wounded men keep fighting? (`wounded.py`)

A "ball" is one bullet that hits a man; a ball through two parts counts once.

| Run | Balls on them | Fired again after | Stayed up: fired again | Dropped: fired again | Downed men who fired from the floor | Shots from the floor | Their shots after being hit, a fight |
|---|---|---|---|---|---|---|---|
| base_now | 404 | 11% | 20% | 0% | 0% | 0 | 0.9 |
| A_pain | 404 | 15% | 29% | 0% | 0% | 0 | 1.2 |
| A_floor | 418 | 12% | 18% | 5% | 6% | 18 | 1.0 |
| A_both | 429 | **20%** | 29% | 11% | 12% | 42 | **1.7** |
| B_doors | 384 | 11% | 18% | 0% | 0% | 0 | 0.9 |
| B_way | 361 | 11% | 19% | 0% | 0% | 0 | 0.9 |
| C_AB | 419 | **20%** | 26% | 11% | 12% | 41 | **1.6** |
| C_ABw | 399 | 16% | 21% | 9% | 10% | 30 | 1.4 |

- **`floor_fight` alone does almost nothing:** pain pins a man on his belly as it pins him
  standing. With `pain_fight` the two together nearly double the shooting a wounded man does.
- **What still stops a hit man who stays up** (`A_pain`, the 71% who don't fire again):
  - about 45% are hit again before they can shoot;
  - about 35% give up at once, a median 0.15 s after the ball. The hit pushes fear past nerve, and
    pain past disabling means he can't run, so he gives up.
  - That's spec item 1C (surrender), the next lever.

## Getting to cover (`cover_runs.py`)

| Run | Runs for cover | Stuck | Hit on the way | Time to get there (median / 90th) | Straight-line speed | Brody: no cover he can reach | Brody's first run (median) | Spot still in view within 2 s |
|---|---|---|---|---|---|---|---|---|
| base_now | 532 | 52 | 16 | 0.6 / 3.3 s | 2.6 m/s | 21 of 100 | 3.2 s | 79 of 375 |
| B_doors | 758 | **8** | 25 | 0.6 / 3.4 s | 2.5 m/s | **8 of 100** | 3.2 s | 97 of 420 |
| B_way | 801 | 4 | **11** | 0.5 / **2.7 s** | **3.3 m/s** | 9 of 100 | **2.7 s** | 91 of 465 |
| C_AB | 791 | 22 | 23 | 0.7 / 3.3 s | 2.5 m/s | 9 of 100 | 3.2 s | 101 of 421 |
| C_ABw | 767 | 4 | 14 | 0.5 / 2.7 s | 3.3 m/s | 9 of 100 | 2.0 s | 84 of 436 |

What the time went on, traced (`gf_trace`):

- **The route, not the speed.** Brody's "2 m" spot behind the bar is about 10 m round its end: 3 s at
  full speed. Spots were scored by the straight line; `way_cost` scores the way.
- **A door in the way.** Lyle on the west gallery ran into the back room's open door every fight
  (37 of the 52 stuck runs). The doors fixed: 8 stuck.
- **A spot that no longer hides him.** About one arrival in five, you can see him there within 2 s,
  because you've moved. That's realistic and was left alone.
- **No acceleration or reaction lag** to blame: he's at full speed in the first tick, and a hit
  doesn't hold him up.
- **Stuck runs in `C_AB` (22):** these come from men crawling for cover from the floor, which is
  slow at 0.35 m/s.

## The fights (`quits.py`)

| Run | Opening | Shooting s (med) | 20 s+ | 45–90 s | Anyone quits | First quit s | Quits a fight | Men who fired | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|
| base_now | they | 17.1 | 40% | 12% | 80% | 4.7 | 1.40 | 54% | 1.1 | 24% |
| A_both | they | 18.0 | 44% | 12% | 84% | 4.9 | 1.60 | 62% | 1.3 | 22% |
| B_doors | they | 15.0 | 44% | 10% | 74% | **11.2** | 1.18 | 64% | 1.5 | 38% |
| B_way | they | 12.6 | 34% | 10% | 68% | 9.3 | 1.16 | 70% | 1.8 | **50%** |
| **C_AB** | they | 16.2 | 44% | 8% | 80% | **13.2** | 1.50 | **70%** | 1.5 | 34% |
| C_ABw | they | 13.2 | 34% | 12% | 72% | 11.4 | 1.30 | 73% | 1.8 | 50% |
| base_now | you | 14.7 | 36% | 8% | 84% | 3.9 | 1.54 | 34% | 0.6 | 8% |
| A_both | you | 16.8 | 42% | 10% | 88% | 4.0 | 1.80 | 44% | 0.8 | 18% |
| B_doors | you | 16.4 | 40% | 8% | 82% | 4.3 | 1.48 | 33% | 0.6 | 12% |
| B_way | you | 15.8 | 42% | 6% | 74% | 3.9 | 1.30 | 36% | 0.8 | 20% |
| **C_AB** | you | **18.5** | **50%** | **12%** | 84% | 4.4 | 1.68 | **46%** | 0.8 | 24% |
| C_ABw | you | 17.4 | 46% | 8% | 84% | 4.2 | 1.70 | 44% | 1.0 | 24% |

## What it means

1. **The best version is `C_AB`** (the doors, `pain_fight`, `floor_fight`).
   - Hit men fire again twice as often, and they fire from the floor.
   - When they draw first, the first quit comes at 13 s, not 5, and 70% of the men fire.
   - When you shoot first, the shooting is 4 s longer, and half the fights have 20 s or more of it.
2. **Fights got more dangerous more than they got longer.** The gang is now good enough that the
   scripted player goes down in a third of the fights where they draw first. Length is capped by the
   player dying, not only by the gang being hit.
3. **`way_cost` does what it says, but costs the fight length.** They get to cover faster and are
   hit less on the way, but they're deadlier still: the scripted player goes down in half the
   fights where they draw first, and the shooting is shorter. Keep it on trial, and judge it when
   the scripted player is more human.
4. **Fear on the hit is now what limits wounded men** (spec 1C). A third of hit men who stay up
   give up within a fraction of a second.
5. **The surrender count went up, not down.** `floor_fight` turns men who lay "down" into men who
   come to and give up when you walk up to them.

## Next, in order

1. **1C, surrender.** A hit shouldn't make him give up on the spot. Consider whether he can still
   fight, hide or back off, and judge the odds with a moment's delay. Measure "gave up within 1 s of
   a hit".
2. **A more human scripted player** (#317 item 0). The scripted player now dies often, and the
   fights' length is partly its doing.
3. **Brody's opening position** (spec 2C). He still needs 2.7–3.2 s to reach the bar.
4. **Then 3A/3B,** suppression and first-shot reactions.

## Films

- `brody_floor.mp4` (`C_AB`, 13 s). The lab's sure shot (`gf_hit`) puts a ball through Brody's
  belly. He can't stand, so he goes straight onto his belly (the old crawl path, not
  `come_to_ground`). Lyle drags him behind the bar. With `pain_fight` he then calls "Covering!" and
  fires from the floor, and your arm is broken in the exchange. A friend's ball also catches him
  ("Hey! That was me!"). The follow camera clips through the bar in places.

## 1C: weighing it, not a white flag (2026-10-24, `D_odds`)

**What changed.** `odds`, on top of `C_AB` (`OutlawBrain._break_odds`, ODDS_*):

- **A moment after a hit:** fear can't break him for 0.8–2 s (longer for a green man), unless he's
  far past his nerve.
- **"Covered close" is a gun on him within 6 m** (it was 12, which in a saloon is everyone).
- **When he does break, he weighs it:**
  - covered close (unless a hothead) or with no gun: gives up;
  - a hothead who's cornered: fights it out for 8 s;
  - able to stand: gets away, at a run or, hurt past running, backing off at a walk (more often for
    a green man);
  - otherwise: lies low once for 5 s more before he weighs it again.
- **A leader's surrender** takes a man only if he's 0.6 past his nerve (it was 0.3).

Why: in `C_AB`, 98 of 159 quits came within 1 s of a hit. Of the quits that came straight after a
hit, 45 were "covered close" and 32 more were "his friends' word".

| Run | Opening | Shooting s (med) | 20 s+ | 45–90 s | Anyone quits | First quit s | Quits a fight | Men who fired | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|
| C_AB | they | 16.2 | 44% | 8% | 80% | 13.2 | 1.50 | 70% | 1.5 | 34% |
| **D_odds** | they | **25.5** | **58%** | **14%** | 70% | 15.4 | **1.08** | 70% | 1.6 | 32% |
| C_AB | you | 18.5 | 50% | 12% | 84% | 4.4 | 1.68 | 46% | 0.8 | 24% |
| **D_odds** | you | **22.5** | **58%** | **20%** | 72% | 5.2 | **1.18** | 52% | 1.0 | 28% |

- **Quits within 1 s of a hit:** 98 of 159 in `C_AB`, 43 of 105 here. Balls on the gang went up
  (419 to 485): they stay in it to be hit.
- **What they chose when they broke:**

| Man | Lie low | Fight it out | Get away (run) | Back off (walk) | Give up |
|---|---|---|---|---|---|
| Brody | 11 | – | – | 4 | 6 |
| Lyle | 3 | 8 | – | 6 | 6 |
| The Kid | 4 | – | 25 | 7 | 21 |

  The personalities show without being scripted: Brody lies low, Lyle fights it out when cornered,
  and the Kid runs or gives up.
- **Endings when they draw first:** 11 fled, 4 gave up (in `C_AB` giving up was the most common
  ending).
- **Quit rates:** Brody 28–30%, Lyle 18–24%, the Kid 62–64%.

**Against the first baseline (`base_now`):** the shooting runs 17.1 to 25.5 s when they draw first
and 14.7 to 22.5 s when you shoot first. The share of fights with 45–90 s of shooting goes 12% to
14% and 8% to 20%.

## A more careful scripted player (2026-10-24, `E_careful`)

**What it is.** `player_bot.gd`'s new `careful` style is the cover style played the way a cautious
person plays it. It runs `D_odds`'s gang (the doors, `pain_fight`, `floor_fight`, `odds`) over
100 fights: five setups, seeds 1–10, both openings.

- **Cover first:** it gets to cover as the fight starts, found and reached by the building's ways
  (the gang's own cover finder, with its places).
- **Pop and drop:** it comes up or out for about 1.6 s, fires a shot or two if there's a man there,
  then goes down for 1.2–2.8 s.
- **When hit:** it gets down for 3 s, and presses on a wound that's still bleeding once it's quiet.
- **Ammunition:** it tops up its rounds while it's down.
- **Under fire:** its shots are hurried (a wider aim, less settling) with balls cracking past.
- **Aim:** 1.6 times the cover style's spread.

| Scripted player | Opening | Shooting s (med) | 20 s+ | 45–90 s | Anyone quits | First quit s | Men who fired | Shots a man | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|
| cover/hold (`D_odds`) | they | 25.5 | 58% | 14% | 70% | 15.4 | 70% | 2.4 | 1.6 | 32% |
| **careful** | they | **36.1** | **74%** | **36%** | 44% | 26.4 | 85% | 3.9 | 2.3 | 54% |
| cover/hold (`D_odds`) | you | 22.5 | 58% | 20% | 72% | 5.2 | 52% | 1.5 | 1.0 | 28% |
| **careful** | you | **36.5** | **78%** | **34%** | 46% | 16.8 | 69% | 3.5 | 2.2 | 52% |

| Scripted player | Its shots | Hit | Gang's shots | Hit you | Hit men who fired again | Gave up or ran within 1 s of a hit |
|---|---|---|---|---|---|---|
| cover/hold | 718 | 67% | 592 | 22% | 19% | 43 of 105 |
| careful | 411 | 54% | 1,101 | 20% | **42%** | 22 of 67 |

**What it means.**

- **Fight length:** played carefully, a third of the fights land in the 45–90 s target, and three
  in four have 20 s or more of shooting. With the quick shooter it was one in seven to one in
  five. So the length limit was partly the scripted player.
- **Wounded men:** they fight on (42% fire again after a hit). The gang fires nearly twice the
  shots, and their aim is unchanged (20%).
- **The cost:** the careful player goes down in half the fights. It takes 2.2 hits a fight against
  three men with nerve. Whether that's too hard is a question for a person's play.
- **The personalities hold:** the Kid quits most (34–40%), Lyle least.
- **How fights end:** it's no longer mostly giving up. When they draw first, the endings were 25
  you down, 11 they lost you, 6 quiet, 2 ran, 1 gave up.

## 3A: a ball past him spoils his shot (2026-10-24, `F_flinch`)

**What changed.** `flinch` (`OutlawBrain._on_near_miss`, FLINCH_*), on top of `E_careful`, with the
careful player and the same 100 fights:

- **Closeness matters:** the near-miss jerk grows with how close the ball came, up to 3 times.
- **His aim is thrown:** up to 4° off, fading at 4° a second. A ball past him as he squeezes throws
  that shot 3° more.
- **A hothead or a frightened man** fires through it, hurried.
- **Anyone else** holds his next shot for 0.3–1.0 s and aims again.

| Run | Opening | Shooting s (med) | 45–90 s | Anyone quits | Hits on you | You down | Gang's hit rate |
|---|---|---|---|---|---|---|---|
| E_careful | they | 36.1 | 36% | 44% | 2.3 | 54% | 20% (222 of 1,101) |
| F_flinch | they | 37.5 | 34% | 40% | 2.3 | 56% | 20% (220 of 1,103), both openings |
| E_careful | you | 36.5 | 34% | 46% | 2.2 | 52% | |
| F_flinch | you | 38.1 | 30% | 50% | 2.1 | 54% | |

**No measurable effect: the gang hits 20% either way.** The careful player fires about 4.5 shots a
fight and hits with half of them. Its misses seldom pass close to a man just as he's aiming, so
there's little to flinch at. It stays on trial; it may matter more against a person who fires to
keep heads down.

**Why the careful player goes down.** It goes down after 3–5 balls, a median of 3 hits. Most land in
the chest (65 of the hits), abdomen (28) and pelvis (18). It goes down with almost all its blood
(median 4,917 of 5,000 ml), so it's fainting from pain (felt pain 1.8), not bleeding out. These are
the same rules the gang lives by. So the player's chances turn on how often he's hit (about 2 balls a
fight from three men at saloon range), not on how much a ball does.

**Levers for the player, untried:** smoke that hides him when they look (3C), and their first shots
(issue 5 in #317: hit 1–3 s in at 8–14 m).
