# Main Street's width (#1295, art's look test)

Sean, 2026-11-26: "Do you think the streets are too wide ... it makes it maybe seem too spaced out?" The
valley's Main Street is 20.1 m between fronts (`config/valley.json` `town.main_street`; the old town's
16.8 m). Three looks, rendered for his pick; **nothing here changes the game's data**.

- **A** as is: 20.1 m between fronts.
- **B** 16 m between fronts, both sides moved in 2.05 m (boardwalks kept at 2.4 m), so the street's
  middle, the North-South Street, Back Street and the rear lane stay put. A throwaway build:
  `override_b.py` writes valley.json (the width, the three lots' pads), the six street-front specs'
  `lot.at` and the ground shader's `walk_edge` in place, then the heights and ground map are re-baked
  (`valley_plan.py --bake`, `tools/textures/valley_ground_map.gd`). **Never committed**: `git checkout` them after.
- **C** as is, made busier (`bridge.gd`'s `street_dress`): plain placeholder fronts in the gaps that
  allow one (saloon B's yard, the vacant lot, the gaps by the bank and land office, the house lots' street
  end, the assay office's yard), and the street dressed: wagons (two freight wagons, a covered wagon,
  three buckboards), 25-odd horses at seven hitching rails and in teams, five troughs, a freight pile at the
  store's dock and below it, barrels, kegs, trunks, hay, planks, eight men out in the street. Kit props;
  rails and fronts are boxes. Frozen once settled (stills only: its physics was ~40 ms a frame).

## The views (`shots.py`; they follow the width, so each stands on the same walk or door in every version)

| View | Where | Looking |
|---|---|---|
| `across` | the south walk before the bank (x 44.5) | across at the hotel's lot, the yard and saloon B |
| `mid_east` | the street's middle, x -40 | east along it |
| `mid_west` | the street's middle, x 40 | west along it |
| `saloon_door` | saloon B's corner door, on its walk | out across the street to the jail |
| `west_entry` | the ore road, x -150 | into town |

Each at noon and 17:36 (golden light: 18:30, the brief's hour, is past sunset on the valley's date: the
first try came out dark). The valley's own townsfolk in (the day's few), the real look, 1280x720 under lavapipe.

```sh
python3 experiments/street_width/shots.py build/sw/A                      # A
python3 experiments/street_width/override_b.py 16 && python3 tools/valley/valley_plan.py --bake \
  && godot --headless -s res://tools/textures/valley_ground_map.gd
python3 experiments/street_width/shots.py build/sw/B                      # B, then git checkout the override
python3 experiments/street_width/shots.py build/sw/C --dress              # C
python3 experiments/street_width/sheet.py experiments/street_width/results
```

`results/<view>_<hour>.jpg`: A | B | C, 800 px each. `results/critic.md`: the blind critic on them.
