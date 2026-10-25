# Blind critic: the factory's batch 2 (the street's soft stuff, the deer head)

References: `street-golden-hour-painted.png` (the livery's stalky golden hay, the barrels and sacks on the porches), `saloon-painted.png` / `saloon-night.png` (a deer head on a dark plaque, pale spread antlers). Crops in `build/critic_2/`.

## Verdicts

- **Hay bale: CLOSE.** The shape and the two ties read right, but it's a pale lemon cushion with soft pillow corners and no loose stalks. The painting's bales are golden and bristly.
- **Straw pile: DOESN'T.** It reads as a smooth sheet over a sand dune, or a tent, not loose straw. The few stray stalks at its foot don't save it.
- **Feed sack: CLOSE.** The silhouette and tied neck are right. It's too clean and uniform, with no seam, weave, stencil or slump.
- **Grain sacks: CLOSE.** The stack is right, but they're overstuffed pillows or bread loaves. A full sack sags into the one below it, and these balance on top.
- **Horse droppings: CLOSE.** The scale and placing are fine, but they're five identical olive pebbles in a neat ring, dry and clean, with no fibre or flattening.
- **Deer head: CLOSE.** At a distance it matches the painting's mount. Up close it's a faceted toy with a bead eye and a button nose, and from the side it's hollow.

## Five biggest differences, most important first

1. **The straw pile isn't straw.** It's one smooth draped surface, almost white at noon, with no clumps, stalk direction or broken outline. `straw_pile_noon.png` (300,220,650,450).
2. **At night the soft props stop being their material.** The droppings render as pure black cut-outs, like holes in the ground. The straw pile is a black pit with a lit rim. The bale's side goes blue-grey stone while its top glows orange. `horse_droppings_night.png` (438,318,515,363); `straw_pile_night.png` (285,240,645,450); `hay_bale_night.png` (308,165,660,420).
3. **The deer head is a hollow, low-poly shell.** From the side there's a dark open cavity between the neck cape and the plaque. The faceting is visible all over the head, the snout is a short cone ending in a black ball, and the antlers are smooth cream plastic tubes without burr or roughness. `deer_head_night_side.png` (320,0,600,330), cavity (440,165,535,310).
4. **The sacks are inflated, not filled.** They have rounded pillow ends and even tension everywhere, with no gathered corners, seams, weave, patches or dirt. They read as cushions or loaves, not burlap carrying 100 lb of grain. `grain_sacks_noon.png` (330,150,690,450); `feed_sack_noon.png` (405,132,555,387).
5. **The hay bale is too clean and too soft.** It has a flat pale-yellow checker with no straw ends sticking out of the faces, no bristle on the silhouette and rounded box corners. The painting's livery bales are deep gold, hairy and shadowed between flakes. `hay_bale_noon.png` (305,165,660,412).

Also: every soft prop shares one smooth, clean, new look. None of them shows the street's dust, trampling or sun bleach that the painting puts on everything at ground level.
