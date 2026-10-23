# Old buildings (issue #326, street session 2 of 4)

Sean, 2026-10-23: the street looked "too perfect", "cheap indie". Each building now shows the years
it has stood: `BuildingAge` (`src/structures/building_age.gd`, dials `config/building_age.tres`),
by the age `config/town.json` gives it. LAYOUT.md "src/structures" has how it works.

| Building | Years | Wear (`(years / 30)^0.7`) |
| --- | --- | --- |
| Bank | 2 | 0.15 |
| Telegraph | 4 | 0.24 |
| Assay office | 9 | 0.43 |
| Saloon (and its walk) | 12 | 0.53 |
| Hotel | 14 | 0.59 |
| General store (and its walk) | 15 | 0.62 |
| Doctor | 18 | 0.70 |
| Barber | 20 | 0.75 |
| Jail | 22 | 0.80 |
| Livery | 45 | 1.0 |

What shows, at full wear (each building seeded its own way): porch roofs sag up to 15 cm between
posts and the porch racks 2.2 deg along the street; a post kicked out 4.5 deg at the foot (never one
a railing is nailed to); the ridge sways 35 cm; the false front leans 2.2 deg out over the street,
hinged at the roofline or under its painted letters; rough siding of differing widths, boards pulled
off their nails, gone, or rotted short at the foot; stretches of wall in newer boards; shutters ajar
on the side and back windows; the framed sign (the saloon's) and the livery's gable board off level;
porch roof boards gone; treads worn hollow, one step cracked in two, planks rocked, a plank replaced.

## The shots

`sh experiments/old_buildings/shoot.sh OUT` renders `views.txt` (each building's front at noon, the
doctor's side, the livery broadside and from the east, under the store's porch, the street west)
twice: as new (`--game-args=--young-town`) and as old. `python3 experiments/old_buildings/sheet.py
OUT sheet.jpg` puts them side by side. About 2 minutes a shot under lavapipe. The sheet and the
blind critic's report are in `results/` (`sheet.jpg`, `critic.md`; Godot doesn't import it).

## Cost

Built once at load; nothing per frame. Bent members are drawn with more vertices: the street's
structures' batches grow (the swayback's roof boards and rafters are most of it), and a batch
rebuilt when a member is hit takes a little longer (measured in the PR).
