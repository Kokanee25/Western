# The prop factory, batch 1: wagons and wheels (2026-10-24)

`docs/briefs/prop-factory.md`; the kit files by `tools/props/wagons.py`; tests `tests/test_prop_factory.gd`.

- `sheet.jpg` (final) and `sheet_round2.jpg` (what the round-2 critic saw): each prop before the saloon's porch at noon and 21:30 (`experiments/prop_lab/factory_sheet.py`),
  after the round-2 fixes (old oak all through).
- `critic.md` (round 1, pale mid-wood wheels and pink pine): buckboard, covered wagon, wheel CLOSE;
  freight wagon, broken wheel DOESN'T. Fixed for round 2: darker woods, iron hub bands standing
  proud, the broken wheel's spokes snapped with slivers and its felloe, sprung tyre and a spoke lying
  by it, ribs over the bows and the canvas gathered at its ends, a brake beam and shoes on the
  freight wagon.
- `critic_round2.md`: buckboard, wheel, broken wheel CLOSE; freight wagon and covered wagon DOESN'T
  (the freight wagon's wheels not heavy enough to read; the canvas stiff, white and blotchy; the
  wheels' dark_wood cold lilac at noon (since moved to the bed's dark oak); nothing dusty or muddy).
  Left for the next round (the `next session` issue): dust and mud up the wheels and lower boards
  (the art lane's weathering layer on kit props), canvas sag between the bows and its painted
  texture, dished wheels and heavier freight running gear.
- Cost: 14 of the factory's props (the three wagons, both wheels, two bales, a heap, three sacks,
  three droppings; 345 members) +0.02 ms a physics frame on this 2.1 GHz core (~0.01 ms at Sean's);
  2-5 draws a prop untouched (a batch a look).
