# The church: the blind critic, round 1, 2026-11-22

Crop boxes are `x y w h` in the pair image's own pixels (each pair is 1810 wide; the left half, the target, is x 0-900, the right half, the render, is x 910-1810).

## Grades

| View | Grade | Why |
|---|---|---|
| front | CLOSE | Right scheme: white gable front, centred square tower, a lancet window either side. But the door is a plain rectangle with no pointed-arch double door or little gabled hood over it, there is no stone foundation, and the belfry sits on a flat dark cornice with a squat pyramid on top instead of a shingled skirt and a tall flared spire. |
| side | CLOSE | Long gabled nave with four lancets and the tower at one end is right. The lancets are about half the target's height and width, sitting high on the wall; the nave reads lower and boxier, no stone footing or piers under the sill. |
| tower | DIFFERENT | Target: a slender steep spire with flared eaves, a shingled sloped skirt between base and belfry, louvered side panels flanking a pointed bell opening. Render: a squat pyramid roof, flat cornice, a square opening with a cross-shaped mullion and the bell sitting low, no louvers. |
| nave | DIFFERENT | Pews in two blocks and lancets down each wall are right, but a thick white post stands in the middle of the aisle, the ceiling is a flat boarded tunnel instead of exposed collar beams, and the stove with its pipe, the hanging lamps and the front rail/pulpit are not readable. Pews are smooth slabs without the target's scrolled ends. |
| pulpit | CLOSE | Raised platform, a rail in front, a pulpit box, a lancet behind and a stove to the right: the layout is there. The rail is split in the middle and painted green, the pulpit is a small dark green box rather than a tall white one, the hymn board is missing (an orange chair instead), and the window is much narrower. |
| graveyard | DIFFERENT | The fence and wooden crosses are there, but the graves are dark flat-topped box slabs instead of earth mounds, there is no open grave with its spoil heap and planks, a tall bare plank stands upright in the yard, and the target's dense crowd of crosses and headstones is a sparse scatter. |
| grave | DIFFERENT | The subject of the target (an open hole, a big pale spoil heap, boards across it, a shovel, rope) is absent; the render shows a box slab and a cross, plus the same tall plank. |

**Totals: 0 SAME, 3 CLOSE, 4 DIFFERENT.**

## The five biggest differences

1. **No open grave in the cemetery.** The target's centrepiece (dug hole, heaped pale earth, planks and rope across, shovel) does not exist; graves are instead dark, sharp-edged rectangular boxes that read as coffins or slabs, not mounds. Evidence: grave left `0 160 900 340` vs right `930 280 600 170`; graveyard left `350 210 300 130` vs right `1170 330 380 100`.
2. **The spire and belfry are the wrong shape.** Target: tall steep spire with flared eaves, a shingled skirt below the belfry, louvers either side of a pointed bell opening. Render: a squat pyramid, a flat dark cornice, a square opening with a cross mullion, no louvers. Evidence: tower left `150 30 640 900` vs right `1230 60 260 290`; front left `290 10 110 170` vs right `1310 60 100 160`.
3. **A post in the middle of the nave aisle.** A thick white column stands centred in the aisle; the target has an open aisle under exposed collar beams and hanging lamps, with a stove and pipe at the front right. Evidence: nave left `180 0 560 320` vs right `1330 120 50 260` (post) and `1100 0 500 160` (flat ceiling).
4. **The front entrance is plain.** The target's pointed-arch double door with a small gabled hood, the steps with handrails and the stone foundation are replaced by a flat rectangular opening and a dark step, flush with the wall. Evidence: front left `270 250 130 180` vs right `1330 290 60 90`.
5. **Small windows and a stray tall plank.** The nave lancets are about half the target's size (side left `200 190 400 170` vs right `1230 235 230 75`), and a tall bare upright plank stands in the graveyard with no counterpart (graveyard right `1250 205 20 90`; grave right `1190 155 20 140`).
