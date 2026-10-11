# Blind critic, e6b: three renders (A, B, C) against the MASTER

Scores run from 1 (far from the master) to 5 (as the master). Columns: Reg = square regularity,
Crisp = crispness, 3D = 3D form, Read = semantic readability, Style = resemblance to the master's
style.

A side measure on the face panel's cheeks and nose, horizontal runs of near-equal pixels:

| Panel | Mean run (px) | Flat share |
|---|---|---|
| MASTER | 3.2 | 0.62 |
| A | 5.1 | 0.74 |
| B | 6.1 | 0.78 |
| C | 6.6 | 0.79 |

So all three renders have bigger, flatter squares than the master, which has more small variation
inside each square. A is the nearest in size and C the furthest.

## face

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 3 | 3 | 4 | 4 | 4 |
| B | 4 | 4 | 3 | 3 | 3 |
| C | 4 | 4 | 3 | 2 | 2 |

- **Best (A) against the master:** A's moustache is the only one with a real mass shape and a
  skin gap under the nose. It still sits as a level bar, where the master's droops in two curved
  masses past the corners of the mouth. A's cheek squares are tilted, soft-edged quads, not the
  master's crisp clusters that read as drawn.
- **Worst (C):** the moustache, mid-panel, is a hard rectangular black slab with one isolated
  skin-coloured square punched in its centre. It reads as a hole rather than a philtrum, and it
  turns the face into a cartoon.

## eyes

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 2 |
| B | 3 | 3 | 3 | 3 | 2 |
| C | 2 | 3 | 3 | 2 | 2 |

- **Best (B) against the master:** in all three the brow, upper lid and eye fuse into one
  near-black mass. In the master the brow is a separate drawn bar with a band of lit skin under
  it, and an almond eye whose whites show on both sides of the iris. In B the whites are
  one-pixel fragments with jagged glints, an "L" and a "Z" in the right-hand eye.
- **Worst (C):** the skin round both eyes is cut into large slanted, trapezoidal patches of
  uneven size, worst at the upper right over the brow. The right eye's white is an arrow-shaped
  fragment, and fine speckle sits at the left eye's inner corner.

## nose_moustache

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 3 | 3 | 4 | 4 | 3 |
| B | 4 | 4 | 3 | 3 | 3 |
| C | 4 | 4 | 2 | 1 | 2 |

- **Best (A) against the master:** A has the philtrum gap, a skin wedge rising to the nose, and a
  thin nostril line. Its moustache is a stiff black slab with hard square steps, though, where
  the master's is a soft-edged, droopy, dark-brown mass with fine hair texture and a full lower
  lip under it. A's cheek squares are softer and lower in contrast than its moustache.
- **Worst (C):** in the centre, the moustache is a solid horizontal block with a single square
  hole. There's no nostril, no philtrum and no shape to the lip, and the slab's flat bottom edge
  meets a pale stripe of lip like a bar code.

## ear

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 3 | 3 | 2 | 2 | 2 |
| B | 3 | 4 | 2 | 2 | 2 |
| C | 3 | 4 | 2 | 2 | 2 |

- **Best (B/C, nearly identical; the ear itself is the same in all three) against the master:**
  the master's ear is broad, with a drawn rim, a dark hollow and the hair over it. Ours is a thin
  lit sliver seen edge-on (lower right of each panel) with a flat hot-red patch in it. That patch
  reads as a stain, not as the ear's hollow.
- **Worst (A):** the temple and sideburn area above the ear (upper left) is broken into smaller
  slanted fragments than in B and C, and looks smeared.

## collar

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 2 | 2 |
| B | 3 | 3 | 3 | 2 | 2 |
| C | 3 | 3 | 3 | 2 | 2 |

- **Best (B/C) against the master:** the master draws a crisp cream collar point with a stepped
  edge and a dark cast shadow under it, against a dark neckerchief. In B and C the collar (left
  half, and lower right) is a blotchy cream area mottled with brown squares. It has no edge and no
  shadow, and the neckerchief at the lower left is a checker of dark and grey squares that reads
  as noise.
- **Worst (A):** the chin and neck squares are smaller and softer. The cream collar on the left
  breaks into jagged one-off fragments, with a brown smear in the middle where the collar edge
  should be.

## hat

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 4 | 3 | 4 | 4 | 3 |
| B | 4 | 3 | 4 | 4 | 3 |
| C | 4 | 3 | 4 | 4 | 3 |

- **All three are effectively identical.** The band's squares are regular but larger and lower in
  contrast than the master's, whose gold-and-dark checks are sharper and smaller.
- **Flaw common to all three:** the brim's underside below the band, running left to right
  across the middle of the panel, is filled with fine streaky, smeared lines (anisotropic
  texture noise). The master's brim is a clean, plain dark shape.

## coat

The crop mostly shows the chin, moustache and collar. The coat itself appears only at the lower
left.

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 2 |
| B | 3 | 4 | 3 | 3 | 3 |
| C | 3 | 4 | 3 | 2 | 2 |

- **Best (B) against the master:** where the coat and lapel show (lower-left corner), they are
  smeared diagonal streaks. The master's lapel and coat edge are crisp, stair-stepped bands with a
  dark outline.
- **Worst (A):** the chin squares are soft and blended, and the lapel at the lower left is the
  most streaked. C's moustache, at the top, again shows its punched-out square.

## Final ranking

1. **B (108/175):** the most even, crisp squares on the face and chin, and a moustache with a
   partial notch for the philtrum. Its squares are still bigger and flatter than the master's,
   and the eyes are fused to the brows.
2. **A (102/175):** the best-drawn moustache, with a skin gap under the nose and a nostril line,
   and squares closest to the master's size. Its squares are slanted and soft, and the collar and
   lapel are the most smeared.
3. **C (98/175):** crisp and regular, but the biggest, flattest squares. The moustache is a
   rectangular slab with one isolated skin square in its middle, the most cartoon-like and least
   readable feature in the set.

## Common to all three

- The eyes fuse brow, lid and eye into one dark mass, with only fragmentary whites.
- The ear is a thin red-stained sliver.
- The brim's underside carries streaky texture noise.
- The collar has no edge and no shadow.
