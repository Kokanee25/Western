# Raised arms: the shoulder helpers (issue #388, 2026-10-26)

Sean's fault: a Studio man with his hands straight up (`hands_up`: upper arms 150°, forearms 25°)
has upper arms far too thin, and the sleeves pinch at the shoulder.

**Why.** The Studio's fit (`studio/steps/body.py`, `config/ai_whole.yaml`) eases his chest into
his upper arm over his whole deltoid (`shoulder_blend_m: [-0.02, 0.07]` from the shoulder joint,
then 12 smoothing rounds). The deltoid stays on the chest at rest. Linear blend skinning turned 150°
folds that blend in, so the arm comes out of the armpit as a wedge. Measured on the doctor
(`tools/characters/arm_dump.gd` + `arm_measure.py`), his raised arm kept 0.63 of its width seen
from in front a fifth of the way from shoulder to elbow, 0.76 at 0.3, 0.85 at 0.4, and was whole
only from 0.5.

**Tried** (on the doctor, his Rodin model refitted by the Studio's own fit in numpy, posed as
HumanBody poses him; the same numbers as the game's own skinning to 0.01):

| try | 0.2 | 0.3 | 0.4 | stretch (works check, cm²) |
|---|---|---|---|---|
| as now | 0.62 | 0.76 | 0.86 | 216 |
| the fit's blend moved in (−8 to 0 cm; a rebuild of every man) | 0.78 | 0.87 | 0.91 | 218 |
| a shoulder helper at 0.5 of the turn | 0.76 | 0.81 | 1.04 | 646 |
| **a shoulder helper at 0.35 of the turn (kept)** | 0.95 | 1.02 | 1.08 | 620 |
| both | 1.15 | 1.17 | 1.17 | 631 |

A collarbone and shoulder blade take part of a real raised arm; the game's 17 bones have none,
and every vertex of the shoulder blend turned the full 150°. The helper turns a share of the way
and carries the blend, so no vertex blends across more than 0.65 of the turn. It needs no rebuild:
`PeopleBodies` spreads the blend over it when it loads a Studio man (`shoulder_share`, 0 turns it
off), and `HumanBody` poses it each tick.

**Its cost.** The armpit's crease opens and stretches: the works check's `hands_up` sheet goes
from 216 to 626 cm² on the doctor. That pose already failed the check; every other pose stays at 0.
Up close (`doctor_armpit.jpg`) the stretch reads as the underarm of a sleeve.

**The men** (`men_1_before_after.jpg`, `men_2_before_after.jpg`; top row before, bottom after):
every raised arm is fuller near the shoulder. The barkeep's and the rancher's shoulders lift and
read broader. Near the shoulder the measure catches a lifted shoulder, a collar or hair on men with
bulky clothes, so judge those by the pictures.

**Not done** (the Studio's change, Sean's call): moving the fit's blend in as well takes the doctor
to 1.15/1.17/1.17, but it means rebuilding all of the men.
