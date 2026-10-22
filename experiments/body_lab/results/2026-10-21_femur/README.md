# A broken femur bleeds into the thigh (fix 9)

**Before:** a broken bone cost pain and what the bone stops a man doing, but no blood. A closed
femoral shaft fracture loses about 1.2–1.3 L into the thigh (Lieurance, Benjamin & Rappaport,
*J Orthop Trauma* 1992; README source 9).

**The change:**
- The anatomy gives the femur `fracture_bleed = 1200` ml (`tools/anatomy/build_anatomy.py`).
- Once broken, by a ball, a blow or a bone smashed by a blast, the bone bleeds inside him at
  `PhysiologyTuning.fracture_bleed_rate` (0.4 ml/s, about 50 minutes) until 1.2 L is gone, then
  stops.
- Packing can't reach it. A belt above it on the limb stops it, as it stops the arteries below it.
- Only the femur has a figure with a source; other bones get none until one is found.
- Test: `test_injuries.gd`, `test_a_broken_femur_bleeds_into_the_thigh` (1.2 L ± 60 ml, then
  stopped).

**Measured** (all 160 runs against fix 2's): only the thigh shots changed, on every man:

| revolver, thigh (femoral artery + vein, femur broken) | before | after |
|---|---|---|
| untreated | dead 3:09 | dead 3:05 |
| belt at 30 s | lives, −0.5 L | lives, −0.5 L |
| packed at 30 s (held) | lives, −1.1 L | lives, **−2.3 L** (shock, near the end) |
| packed, then the doctor at 10 min | lives, −1.1 L | lives, −1.2 L |

A man packed but not belted now bleeds into his thigh for the next hour, which is the medicine.
