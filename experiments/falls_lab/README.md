# The falls lab

Issue #759 (#736 D, "falling from height"). Sean's table of heights and injuries and the heights a
body breaks through are on #762 ("yes to all", 2026-11-10). This lab tunes the game's fall rules
to that table and checks them:
- `Falls`, `FallTuning` (`config/falls.tres`), `HumanBody._step_fall`;
- `Physiology.axial` and PhysiologyTuning.blunt's fall keys;
- `PlayerWounds.take_fall`;
- BodyImpacts' from-above case, with TimberTuning's `body_stop`, `body_above_speed` and
  `body_feet_share`.

```sh
# men dropped onto the ground: 9 heights x feet first / flat on the back / head first, 20 men a cell (~1 min)
godot --headless --fixed-fps 60 -s res://experiments/falls_lab/falls.gd -- --out=build/falls_lab/run
python3 experiments/falls_lab/falls.py build/falls_lab/run [--md=OUT.md]   # the table beside Sean's targets
# onto a bay of the game's members (lab_roof.gd: roof boards on rafters 0.61 apart, PorchRoof, floor
# boards on joists 0.406 apart), its top at 3 m; --body-stop=100 holds every board and reads `need`
godot --headless --fixed-fps 60 -s res://experiments/falls_lab/falls.gd -- --out=DIR --onto=roof --heights=1,2,3,3.5,4.5,6,9 --poses=back,feet --men=20
# the building lab's saloon: through the gallery's rail, over the balcony's, onto the roof, off its eave
godot --headless --fixed-fps 60 -s res://experiments/falls_lab/falls.gd -- --saloon --out=DIR [--cases=gallery,balcony,roof,roof_edge] [--seeds=6]
```

## How a cell is run

- Each man is let go limp, still, at the height. His lowest part is at the height.
- He is turned to the pose about his middle, with up to 15 deg of tilt each way drawn by his seed.
- His ragdoll falls as the game's does. Nothing about how bodies fall is changed.
- After `--seconds`, his body is run on alone for ten minutes (`Physiology.step`). That is "dead".
- Each row in `falls.json` has every man's landings, blows, harm, cause of death, whether he's still
  drawn where he lies (#562's culling box), and with `--onto` the boards broken and whether he went
  through.

## What was found (2026-11-10)

**Results:** `results/2026-11-10/`
- `injuries.md`: the table against #762.
- `onto_*.md`: through and broken, at the dial.
- `need_*.md`: the stop distance each landing would need to hold.

**The ragdoll's damping.** HumanBody's `linear_damp` (0.2) takes about 20% off a 22 m fall's speed
(16.6 against 20.8 m/s), far more than air would. A landing is scored by the height his middle came
down from, or his speed if that's more. The damping is part of how he falls, so it is left alone.

**The parts down first.** At speed the joints pass a stop up the whole chain in the same tick: at
4.5 m head first, every part "stopped" at once. The parts down first are the ones whose undersides
are within 15 cm of the lowest.

**The first parts' share depends on how he lands:**
- Head first, the head carries the body behind it: 75% of the hurt, however light it is.
- Feet first, his legs give: 50%, and the whole hurt is softened by 0.75.
- Flat, nothing is stacked over the first parts, so each part takes its own stop.

**Deaths.** The blunt rule's chance jumps from 0 to 0.4 at its threshold, too steep for death
rates that rise evenly with height. The deep injuries (neck, low back, aorta) are linear ramps
instead (`Physiology.axial`). The aorta goes by the whole body's stop.

**Boards from above.**
- A limp man's contacts carry his own momentum, not the body behind: his knees fold at once. So
  each contact's push counts at the speed his middle is coming down. A foot or shin with his middle
  over it carries `body_feet_share` of his weight.
- Lying still on a board counts nothing, because his middle isn't coming down.
- A board lying flat is only ever judged from above. A part on the seam between two boards met an
  edge at a slant, and the side rule broke the board at any height.
- A board that breaks drops out between the rafters or joists either side of him
  (`Structure.cut_member`). The rest stays nailed.
- A man flat on his back mostly lodges in the hole he makes: rafters 0.61 m apart catch him. He goes
  right through when he lands feet first between them, or lying along them.
- A board bedded on the ground never breaks (`test_body_impacts`' dropped man).

**The lab's own trap.** `StructuralAnalysis.load_tuning()` hands back the cached resource only
while something holds it. A dial set on it and dropped is reloaded fresh, so the runner keeps it.
