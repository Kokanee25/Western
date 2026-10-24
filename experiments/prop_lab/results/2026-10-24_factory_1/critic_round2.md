# Blind critic: the factory's batch 1, round 2

Images are `build/factory_1/`; boxes are in each image's own pixels (960x540). Crops in `build/critic_1b/`.

## Verdicts

- **Buckboard: CLOSE.** The box and its proportions read right, but the wheels are pale lilac-grey sticks on a dark brown box, and front and rear wheels are the same size.
- **Freight wagon: DOESN'T.** It's the buckboard's thin wheels under a slightly longer box. Nothing about it says heavy: no thick felloes, broad tyres, deep bed or bolsters.
- **Covered wagon: DOESN'T.** The canvas is a stiff, bright-white loaf with straight sides and camouflage blotches. It has no sag between the bows and no puckered, drawn ends.
- **Spare wheel: CLOSE.** The wheel reads as a wheel and lies flat, but the iron tyre is a mottled green-tan band, the hub is a tall pale bottle, and it's too clean.
- **Broken wheel: CLOSE.** The idea reads. The breaks are square saw cuts, and the loose spoke and felloe arcs are clean machined bars with no splinters or torn ends.

## Five biggest differences

1. **The wheel wood is cold lilac-grey, not warm sun-dried brown.** It's used on every prop and clashes with the warm boxes and the orange-tan world in the paintings. At night it turns electric blue. Boxes: `buckboard_noon.png` (270,250,455,440); `covered_wagon_night.png` (297,304,426,460).
2. **The iron tyres read as camouflage cloth.** They show as a grey-green-tan pixel mottle where they should be a dark, rust-edged iron band. Boxes: `wagon_wheel_noon.png` (318,345,643,438); `buckboard_noon.png` (520,250,640,385).
3. **The covered wagon's canvas is wrong.** It's dead white, rigid and box-sided, and covered in blocky blotches. At night a hard split runs down it, half lit and half black. Boxes: `covered_wagon_noon.png` (206,145,632,283); `covered_wagon_night.png` (207,146,415,281).
4. **Nothing is worn.** There's no dust or mud up the wheels and lower boards, no grey bleach on top edges and no grime at joints. The props look newly built, while the paintings' street is caked. The broken pieces have square, clean ends. Boxes: `broken_wagon_wheel_noon.png` (470,415,545,523) and (537,240,680,400); `freight_wagon_noon.png` (243,184,631,279).
5. **The three wagons are one kit at different lengths.** They share identical spindly wheels: straight bars of uniform thickness for spokes, no dish, and the same wheel size front and back. The bed sits on them with no visible running gear (axles, bolsters, brake). The freight wagon is the worst case. Boxes: `freight_wagon_noon.png` (551,242,651,360); `buckboard_noon.png` (290,240,690,330).
