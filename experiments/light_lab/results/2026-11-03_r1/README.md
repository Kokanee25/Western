# Round 1 (2026-11-03): RoomLight built, tuned twice, judged blind

Renders: lavapipe (`screenshots.gd --variants=`, before and after from one load; people and the
lamps' flicker move between the two, so a pixel diff can't prove "off is the old look": the tests
do, by state). Views `saloon_night`, `saloon_back_wall_night`, `saloon_toward_door_night`,
`man_saloon_night`.

**The dials as they stand (r2a, `config/room_light.tres` defaults):** bounce gain 1.5 (the
physics: a patch's share x the wood's sRGB lightness), lamp colour only (tint 0), reach 0.6 of the
lamp's (min 2 m), off the surface 0.25 m, falloff 0.5; the night fill at 0.5 of the game's, dark
amber.

| What | Result |
|---|---|
| `sheet_before_after.jpg` | before / after (r2a), the four views |
| mean lightness, before -> after | saloon_night 0.265 -> 0.272; back wall 0.213 -> 0.209; toward door 0.234 -> 0.225; man 0.233 -> 0.229 |
| near-black share | 0.7 -> 0.5 %; 3.8 -> 4.1 %; 2.1 -> 2.3 %; 0.4 -> 0.3 % |
| cheap judge round 1 (`docs/screenshots/judge/2026-11-03_room_light_r1/`, dials "e": gain 4.5, tint 0.4) | saloon_night before **good indie**, after **cheap indie** ("a pink-lilac wash"); man's view before good indie, after cheap indie (the man hidden behind her hair: people, not light); the two wide views cheap indie both, after ranked above before |
| cheap judge round 2 (`..._r2/`, before vs r2a vs r2b) | all twelve **cheap indie**; within each view: door before > r2b > r2a; man before > r2a > r2b; back wall r2b > r2a > before; saloon_night before > r2a > r2b |
| headless cost, calm street at 23:00 (every lamp lit) | `room_light` 0.29 ms a frame here (~0.19 at Sean's by x0.65); 0.81 before caching the fill's share and the openings' sky |
| tests | `tests/test_room_light.gd` 6/6 |

**What it found.** Bounces that summed past the lamps themselves (gain 4.5: single bounces of 4-5
energy off the roof over the sconces) lit the roof as bright as the floor: the judge's first tell
in every view. The wood's hue on the bounce (tint) turned the floor mauve under the red walls and
grey roof. With the physics' gain, no tint and a short reach the room is close to the game's light,
a touch darker in the back and warmer round the sconces; the judge doesn't find it less cheap. Its
tells in every picture (before and after alike) are the base look's: the pale even pine ceiling,
the walls one orange between the sconces, no haze, clean ruler-straight wood, the plastic hand,
cloned sconces, an empty room.

Trials: `trial1_sheet.jpg` (a defaults / b strong bounce, low fill / c middle), `trial2_sheet.jpg`
(d, e), `round1_sheet_before_after.jpg` (dials e at the four views). The lab's trial files are
`../../trials/*.json` (LookPreset files: `settings.room_light` and `room.<dial>`).

**Films** (`../../films.sh`, 640x360 at 15 fps, the camera still, RoomLight on with the r2a dials):
`lamp_on.mp4` (the near card table's lamp carried across the room, knocked over, smashed: its
bounces follow it and go; `film_lamp_on_strip.jpg`) and `wall_on.mp4` (a stick outside the back
wall: the gable blown open, the moonlit sky through it and the hole's spot of moonlight; RoomLight
found it from the breaks: a 9.75 m2 hole in the back wall and 0.83 m2 in the right-hand one;
`film_wall_on_strip.jpg`). At this size the bounce's change is hard to see; the mechanism works.

**Faces** (`tools/face_light.py` on `shot_match_close --face-probe`, off / on): face light median
0.90 / 0.87, p90 1.09 / 1.05, clipped 46.1 % / 44.2 %, L* 61 / 60 (paint 64): as readable as
before (the clipping is the view's own, off as much as on).
