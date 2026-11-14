# The cheap judge's numbers and self-test

For the people running the cheap judge (`tools/critic.py cheap`, rubric `../CHEAP.md`, #609), not for
the judge: it reads only the rubric, so nothing here can tip it off.

## The numbers beside the eye

`critic.py cheap` also measures each picture (reusing `tools/judge.py`'s Lab and light measures)
into `numbers.md`. They are **not shown to the judge**: the eye stays independent, and the two are
read side by side afterwards.

- **Light:** the deep-shadow share (L* < 10), the spread of the L* percentiles (95th - 5th), and the
  black floor (the 1st percentile of L*: a lifted black is high).
- **Atmosphere:** local contrast and chroma far against near. With a depth image
  (`VIEW_depth.png`, 0 near to 1 far) the near and far are by depth; without one, the near is the
  frame's bottom third and the far the band round the horizon. A ratio near 1 is "no atmosphere".
- **Repetition:** the strongest repeat in the high-passed luminance's autocorrelation away from its
  centre (0 none; above ~0.3 a tile you can see).

## Trust: the probe self-test

`python3 tools/critic.py cheap-probes OUT` lays out the game's own old renders of one shot (the
street at golden hour, `docs/concept/judge/cheap_probes/`, ranked in `ranking.json`) in a shuffled
order under letters, and prints the same prompt. `--check` reads the judge's `cheap.md` and fails
unless it ranks them as the ranking says (the verdict scale first, then the FAIL count). `--numbers`
checks the measures alone (no agent): the deliberately broken probe (ambient doubled, fog off) must
measure flatter and with less atmosphere than the render it was broken from.

The probes (`ranking.json` says what each is, where it came from, and the rules): `now` (the street
at golden hour on main, 2026-11-03), `broken` (`now` with `broken_look.json`: ambient doubled, fog
off), `early` (round 0, 2026-10-01_r1), `noon_before` (the store front at noon before the light pass,
the look Sean called "too cheap, too indie", #318) and `noon_now` (the same view today, through the
same 480x270 JPEG); for the numbers only, `ambient_x2` and `fog_off` (broken's two causes apart).
`now`, `broken`, `ambient_x2` and `fog_off` are one run (`screenshots.gd --only=shot_match_street
--variants=...`): the same view in two runs differs by more than the probes do (people and horses
move), so number rules compare within a run only. Sean confirmed the ranking on 2026-11-04 (#612), and
said the broken probe looks about the same as `now` to him, as the judge saw it: the rule that the judge
must name broken's flat light or lost haze (a warning on the second run) was dropped.

The first eye run (`docs/screenshots/judge/2026-11-03_cheap_p/`) failed 3 of 4 rules: it put three
pictures in "good indie" with nothing to order them, and its "too cheap" probe (the street at golden
hour, 2026-10-22) didn't carry Sean's words (#318: golden hour "holds up better"). Two fixes, the most
the rules allow: the noon pair in its place, and a closing `## Ranking` in the judge's answer that
orders the pictures within a band.
