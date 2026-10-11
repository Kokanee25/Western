# Blind critic, E11: coat

One feature image (`coat.png`): MASTER, then panels A, B and C. The crop shows the jaw and neck
area, a diagonal fold or band of cloth below it, the pale collar and shirt front, and the dark
lapel edge at the lower left.

The three panels are almost the same picture. A and B differ only in the dark lapel strip at the
lower left (about 2 % of pixels). C differs from both by single squares changing shade across the
orange cloth and jaw (about 12 % of pixels). The scores differ by half a point at most, and the
reasons are given below.

## Coat

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Master's style |
|---|---|---|---|---|---|
| A | 2.5 | 3 | 3 | 2.5 | 2.5 |
| B | 2.5 | 3 | 3 | 3 | 2.5 |
| C | 3 | 3 | 3 | 3 | 3 |

**Best (C) against the master.** The master's squares sit on one steady grid. They grade gently
in even rows across the orange cloth, and its edges (the pale collar band, the dark lapel) step
in clean staircases at that same square size. In C the squares are still tilted, diamond-like
and of mixed sizes, and they follow the surface. Look at the band across the top right and the
orange area in the middle: the cells overlap like scales instead of forming a grid. C does read
a little calmer than A and B. Its orange squares are more even in tone (neighbour contrast about
7.4 against 7.6), and the dark crease under the upper band runs a little more continuously.

**Worst (A), biggest flaw.** Look at the lower left of the panel, the lapel and the shirt-front
area below the pale collar. The cloth there is drawn as thin diagonal streaks, one or two pixels
wide, instead of squares. Beside them, the dark lapel edge breaks up into lighter brown flecks
and a pale vertical sliver. The master's lapel is one solid dark mass with a stair-stepped edge
against the pale collar. In A the boundary between collar, lapel and shirt is muddled, so the
collar's edge and its shadow don't read. B has the same streaks, but its dark lapel strip is
more solid, so that edge reads a little better. All three share the streaks.

Shared by all three: the pale collar and shirt front at the lower centre are large, irregular,
angular slabs. The master's collar point is a crisp pale wedge with a dark shadow beside it.
Here the pale shapes run into each other, and the shadow under the collar is a set of scattered
dark squares (lower centre) instead of one drawn shadow shape.

## Final ranking

1. **C**: the calmest, most even mottle of squares on the cloth and a slightly more continuous
   crease. It is still off-grid and slanted, and it has the streaky lower lapel.
2. **B**: the same as A, but with a more solid dark lapel edge, so the collar and lapel boundary
   reads a little better. The cloth squares are a little blotchier than C's.
3. **A**: the lapel edge breaks into light flecks and a pale sliver, which adds to the streaky
   cloth below the collar. This makes it the least readable lower-left corner of the three.
