# Dynamite up close, option (c), 2026-10-28 (issue #220, step 1 of #298)

Sean picked (c), for everything (people, buildings and windows): a charge on the ground counts as
about 1.8 times its TNT, and what faces the blast takes the reflected pressure. The options were
in `../2026-10-21_dynamite_options/README.md`.

## What changed

- **The ground** (`Blast.effective_kg`, `ground_share`; `BlastTuning.ground_factor` 1.8,
  `ground_height` 0.6 m per cube root of kg). A charge on, or just over, the ground or a floor hits
  as 1.8 times its TNT, fading to its own by 35 cm up for a stick, so a stick held at the chest
  hits as its own. `Blast.detonate` uses it for everything it acts on except the crater (Kinney and
  Graham's fit is already for surface charges) and the look. `report.kg` and `Events.exploded` carry
  it. A stick lying on the dirt hits as 0.36 kg. The store's floor test gives 0.27 kg: the ray
  meets the ground under the floor's edge, 0.2 m down.
- **Reflection.** Each part of a man (and the player) takes the reflected pressure on the side
  facing the blast (`Blast.reflected_kpa`). He is still knocked down by the side-on pressure at his
  chest, because that is the blast wind. Walls and panes already took the reflection. I checked
  `Blast.reflection()`: it is the Rankine-Hugoniot normal reflection for gamma 1.4, Pr/Ps =
  2 + 6Ps/(Ps + 7P0).
- **Lamps and bottles** (`GlassProp`) stay on the side-on pressure. On a thing a few centimetres
  across, the reflected spike clears in about 0.1 ms, against a stick's pulse of about 1 ms. With
  the reflection on, a stick in the saloon at night smashed 15 to 25 lamps (2 to 8 before) and lit
  170 to 330 members in 8 s (`runs/breakage_c.json`); without it, 3 to 12 lamps (below).
- **Blast lung** by the reflected pressure at his chest: bruised from 400 kPa, torn from 1,000
  (was 250 / 700 side-on). The values are from Bowen, Fletcher and Richmond's curves for a 70 kg
  man (DASA-2113, 1968), which use the reflected pressure for a man facing the blast, at a stick's
  ~1 ms pulse. Bass, Rafaels and Salzar (J Trauma 2008) refit them for short pulses. **I quoted
  both from memory**: the papers' sites aren't reachable from this workspace (as in #227).
- Unchanged: the limb thresholds (they now read the reflected pressure, as the options table
  assumed), `open_kpa`, concussion (150 kPa, now reflected), eardrums (35 / 140, now reflected),
  and the gut shot at 30 game hours (Sean: "don't care").

## People (the body lab, one stick on the ground in front of him, 4 men each)

`python3 experiments/body_lab/run.py --scenario=group:dynamite --jobs=2` on main (9061863) and on
this branch; `blast_table.py` gives the lines (`body_lab.txt`, the runs in `runs/body_*.json`).
Distances are along the ground to his feet.

| stick | main | option (c) |
|---|---|---|
| 0.5 m | both feet off, dead untreated in 287 s | every limb chain off (feet to thighs, hands), lungs torn, senseless, dead in 55 s |
| 0.8 m | eardrums, thrown down | feet, shins and hands off, lungs bruised, senseless, dead in 136 s |
| 1.0–1.2 m | eardrums, thrown down | both feet off, lungs bruised, senseless, dead in ~275 s untreated |
| 1.4 m | thrown down | lungs bruised, senseless, eardrums (dead in ~96 min of the bruised lungs, untreated) |
| 1.7 m | thrown down | senseless, eardrums |
| 2–3 m | thrown down to 2 m, eardrums to 1.2 m | eardrums, thrown down |
| 5–6 m | nothing | nothing (eardrums go out to between 3 and 5 m) |

Against the options table (distances to the part's skin):

- A foot or shin off within about a metre: yes, to 1.2 m.
- Lungs torn within about 1.4 m: now within ~1.3 m of his chest, so only with the stick at about
  half a metre. Bruised to 1.4 m on the ground (~1.7 m to the chest). This is the raised
  threshold.
- Eardrums out to about 5 m: out to 3 m sure, none at 5 m (his head is 5.3 m off).

## Buildings and glass (the breakage lab, outlaw bystander, seed 1, 8 s)

`breakage.md` (`brk_compare.py`): main → (c). The saloon's rows (lamp, bottle, chair, table, floor)
are with lamps on the side-on pressure. The runs are in `runs/breakage_*.json`.

- **More breaks everywhere:** 1.1–2.9 times the members broken, panes 9–20 → 10–27, holes in boards
  1.3–1.9 times the area (the floor 8.3 → 13.6 m², the roof 9.0 → 16.9 m²). Every window scenario
  now breaks ~25 panes, even from 6 m (13 before).
- **Sean's call (one stick on the floor against a wall: a crawl hole; three: a doorway).** On the
  store's side wall, at 8 spots 0.5 m apart, one stick at a time:
  - main: a full-height slot at 4 spots, 1.0–1.3 m holes at the rest;
  - (c): a full-height slot at 5 spots, ~1.4 m holes (stooped through) at the rest;
  - three sticks: a doorway at every spot, both (with (c) the roof over it goes too: 11–21 roof
    boards).

  So the call was already only half true before (the test's spot was one where it held). It's
  less true now: **one stick usually blows a hole a man walks or stoops through**. Raising the
  timber's `absorb_factor` doesn't bring it back: 0.3–0.8 still gave full-height slots, and 0.6+
  stopped three sticks making a doorway. The test (`test_a_stick_inside_against_the_wall_blows_a_way_out`)
  checks the crawl hole and leaves the upright check out. Sean's call: #484.
- **Fires at night** (lamps lit, the saloon): a fire after a blast comes only from a lamp it
  smashes (#449), and on main every stick in the saloon at night already started one. With (c),
  lamps smashed 2–8 → 3–12, members alight within 8 s 25–111 → 31–176 (the lamp at 1 m: 31 → 67).
  So the fires are bigger and start sooner, but they don't start more often. By day nothing burns.

## The cost (`hitch.txt`, `--serial`, one game at a time)

| scenario | blast frame, main → (c) | 1–3 s after, mean (p99) |
|---|---|---|
| boardwalk, stick on it | 271 → 402 ms | 8.0 (23) → 11.1 (20) |
| floor | 288 → 247 | 12.8 (19) → 18.3 (31) |
| wall, 1 m | 262 → 236 | 9.0 (16) → 12.2 (21) |
| window, 3 m | 118 → 124 | 4.2 (10) → 6.8 (15) |

This is this workspace; Sean's is about 0.65 of it. The blast's own frame was already far over
the budget (0.2–0.65 s at Sean's in the baseline), and it is no worse except on the boardwalk
(+130 ms: more of it cut, and `blast_response` doubled because the reach is 1.22 times wider).
The seconds after cost 3–5 ms more a frame, from more rubble. The hitch itself is
more-cores/#373 territory.
