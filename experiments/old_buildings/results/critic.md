# Blind critic, 2026-10-23 (round 1)

A fresh agent that hadn't seen the code or this work, given the street painting
(`docs/concept/street-golden-hour-painted.png`) and the 15 noon views as shuffled A/B pairs (new
and old), asked which is older, what reads as a bug, whether the age reads as caused, and the five
biggest differences from the painting.

**Score: 14 of 15 picked the older render.** The miss was the bank (2 years: meant to be nearly
new). Its words: "the ageing is very faint ... a player would not see it without the fresh version
beside it" (1–8% of pixels differ at 960x540).

## What it read as bugs, and what was done

| It saw | Done |
| --- | --- |
| Porch beams kinked like hinges beside a post; the low point over a post | The sag eases into each post (sin squared, level where a post holds it) |
| Hard rectangles of sun under porch roofs, read as a shadow fault | Fewer porch roof boards gone (0.10 -> 0.04 at full wear) |
| A 1 px seam between the eave and the porch roof's boards | Porch members bend from 2 mm (not 8), so the eave and its boards sag together |
| The livery's sign "sheared"; a pale board proud at the barn's corner | Looked at: the sign tilted 2-3 deg, the board one of a patch of newer boards. Kept |
| Dots in arcs on the barn's roof | In the new render too: the roof boards' texture, not ageing (art) |
| Jagged board tops and dark slots on the jail's side wall | Boards of differing widths, pulled off their nails: kept |

## Does it read as caused?

"Partly. The sag in porch beams between posts, gapped side boards, a missing barn board, a sagging
ridge and a skewed sign are the right kinds of damage in the right places ... So the age is mostly
in the shapes, while the surfaces still look brand new."

## The five biggest differences from the painting (its order)

1. Surfaces new and evenly toned: no bleaching, grime, peeling sign paint (art: the wear-down plan).
2. An empty, tidy street: few rails, barrels, crates, people between the buildings (street sessions 3-4).
3. The ground: smooth pale sand, two thin ruts; each building on a dirt pad with a ruler-straight edge.
4. Vegetation and light: repeated black-and-cream grass cards; flat noon light, cold porch undersides.
5. Geometry still too regular: "even the aged ones have only a slight beam wave".
