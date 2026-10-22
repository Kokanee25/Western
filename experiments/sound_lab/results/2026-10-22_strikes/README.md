# Change 2: passes, impacts and ricochets by what they are (2026-10-22)

Against the baseline's items 5–7 (`../../baseline/baseline.md`). Before and after from one build
(`run.py --old-sound`). Runs `build/sound_lab/s_before`, `s_after`; tables `table_before.md`,
`table_after.md`. The lab now waits two seconds after quietening the town before it records (a
bottle in the saloon, the prop lab's `GlassProp`, smashed as the town was cleared, 23 m off, in
every run) and takes the noise floor as the median of the first 0.4 s.

## What changed

- **A ball going by** (`ImpactEffects._on_near_miss`): it snaps only if it's faster than sound
  (buckshot near the muzzle). A black-powder .45's ball (the game's 274 m/s; period loads quoted at
  850–1,050 ft/s) whirrs: `whirr`, a short tearing rush whose pitch drops as it goes (Doppler: a
  source at 0.8 of the speed of sound comes in at ~5x its pitch and leaves at ~0.55x). A tumbling
  ricochet still whizzes (`zip`). How close it came is how loud it is: full at a hand's breadth,
  −10 dB at a metre, −16 dB at two (it was capped: 0.3 m and 1 m were the same). The dial
  `subsonic_snaps` (`config/sound.tres`) puts back "every near miss snaps" (Sean's earlier rule).
- **A ball striking** (`impact_*`, `ImpactEffects._on_hit`): wood a dull thock (a board's low modes)
  and splinter ticks; dirt a soft thump and the patter of clods; iron a clank and a ringing ping
  (a bar's modes, 1 : 2.76 : 5.40 : 8.93); stone a hard click and chips. Wood and dirt were silent.
- **A ball glancing off** (`glance_*`): that surface's strike under the tumbling whine (lower and
  shorter off dirt). One ricochet sound served every surface before.
- **A charge's pellets**: the first strike or glance in 3 m and a tenth of a second is heard, not
  all nine.
- The lab's shooter fires through `GameAudio.gunshot`, as an outlaw does.
- All placed by `GameAudio` (late by distance, the air, walls: a sound made on a surface is judged
  from a hand's breadth off it, or the surface itself would be the wall).

## Measured (loudest 400 ms, LUFS; the ears 5–6 m off, or the ball 30 m off passing the ears)

| | before | after |
|---|---|---|
| A true pass at 0.3 / 1.0 / 2.0 m | −40.8 / −40.8 / −53.0 (crack) | −22.6 / −31.5 / −36.3 (whirr) |
| A tumbling pass at 1 m | −17.9 (zip, louder than any true pass) | −29.8 |
| Ball into wood / dirt | silent / silent | −25.6 (centroid 407 Hz) / −26.6 |
| Into a man / glass | −28.2 / −17.9 | −27.2 / −17.5 (each now also its exit's strike) |
| Glancing off dirt / stone / iron | −18.2 / −17.8 / −17.2, all centroid 2,263–2,272 Hz, decay 0.25–0.28 s | −18.5 / −13.8 / −12.7; centroid 2,358 / 2,280 / 1,882 Hz; decay 0.19 / 0.23 / 0.56 s (the iron rings) |

## Clips (`clips/`, before, a second's gap, after)

`pass_true_0.3`, `pass_true_1.0`, `pass_true_2.0`, `pass_true_1.0_report` (a man's shot from 30 m:
now the report comes first, 0.09 s, and the ball whirrs by after it, 0.11 s), `pass_tumbling_1.0`,
`impact_wood`, `impact_dirt`, `ricochet_stone`, `ricochet_iron`, `ricochet_ground`.

## For Sean's ears

1. The pass: does a .45 ball whirring by sound right, or do you want the snap back (one dial)?
2. Can you tell 0.3 m from 1 m from 2 m?
3. Wood, dirt, iron, stone: does each sound like what was hit?
