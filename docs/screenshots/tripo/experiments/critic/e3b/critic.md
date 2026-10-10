# Blind critic: e3b

A and B are nearly the same picture. Measured pixel by pixel, they differ on under 1 % of pixels, and in eyes, hat and ear not at all. B only differs on the lower-left jaw and mouth, where its jaw shadow is a little darker. C differs from both on 7–16 % of the face, nose/moustache, collar and coat pixels, and barely on the hat (0.9 %) and ear (2.7 %). So A and B tie on most features, and C is the real alternative. My working crops are in `scratchpad/critic_e3b_work/`.

Scores are 1–5 on: Reg = square regularity, Crisp = crispness, 3D = 3D form, Read = semantic readability, Style = resemblance to the master's style.

## face

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 4 | 3 | 2 |
| B | 2 | 2 | 4 | 3 | 2 |
| C | 3 | 3 | 4 | 3 | 3 |

- **Best (C) against the master:** the master's skin is a dense, even grid of small squares all one size. C's cheeks and forehead are still pale patches of mixed sizes, and they slant. Under the left eye and down the nose, broad smooth light sits across several squares at once, so the face reads as a lit 3D render cut into tiles, not a picture drawn in tiles.
- **Worst (A):** the left cheek and the bridge of the nose are big soft quadrilaterals with blurred edges between them. A hard diagonal seam runs from the inner corner of the left eye down toward the moustache: a texture-island edge, not drawing.

## eyes

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 2 | 2 |
| B | 2 | 3 | 3 | 2 | 2 |
| C | 3 | 3 | 3 | 2 | 2 |

- **Best (C) against the master:** the master draws each eye as a clean almond: a lid line, a block of warm white each side of a dark iris, and one glint. In C, and in A and B, the eye is a dark mass with scattered pure-white specks at the corners and on the iris (the right eye's lower-left corner, the left eye's outer corner). They read as sparkles or noise, not as the whites of the eye.
- **Worst (A):** the skin under the left eye breaks into fine, irregular one-pixel crumbs at the inner corner. The brow-to-lid area is a soft dark smear with no clean lid line.

## nose_moustache

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 2 |
| B | 2 | 3 | 3 | 3 | 2 |
| C | 3 | 4 | 3 | 3 | 3 |

- **Best (C) against the master:** C's moustache outline steps in cleaner, more even stairs, nearest the master's. The master's moustache, though, is a textured mass of several dark-brown tones with squares inside it. C's, and A's and B's, is a flat near-black silhouette with no inner drawing.
- **C's philtrum gap** is a narrow, tilted sliver set high in the moustache. The master's gap is a small skin notch where the two halves meet under the nose.
- **The nose itself:** none of the panels draws a nostril. The nose is a soft vertical highlight stripe plus a glowing orange patch beside it. The master marks the nostrils with two dark squares.
- **Worst (A, with B the same):** the gap in the moustache is a pale rectangle, too tall and too evenly bright. It reads as a missing tooth or a bar of skin cut through the moustache, not as a philtrum.
- **A and B also share a fault:** a thin dark diagonal line crosses the skin from the top of the gap toward the right cheek, a seam artefact. Across the upper lip and cheek, A's lit skin is soft blur rather than squares.

## ear

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 1 | 1 |
| B | 2 | 3 | 2 | 1 | 1 |
| C | 2 | 3 | 2 | 1 | 1 |

- **Best (any; they are almost the same) against the master:** the master's ear has a drawn rim, a dark hollow and a lobe in clear squares. Here the ear is a flat, bright orange wedge with one red blot in the middle, and its staircase edge is cut against black. No rim and no hollow.
- **Worst:** the same in all three. The lower half (the red blot and the jagged right edge) reads as a flame or a cut shape, not an ear.

## collar

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 2 | 2 |
| B | 2 | 2 | 3 | 2 | 2 |
| C | 3 | 3 | 3 | 2 | 2 |

- **Best (C) against the master:** the master's collar is clean cream points with crisp, zig-zag stepped edges, a dark tie, and a clear shadow under the jaw. C's chin and neck squares are firmer and larger than A's. But the collar is still a ragged cream blotch broken by black holes (lower left), and there is no shaped collar point and no clean shadow line under it.
- **Worst (A):** where the collar meets the neck, A dissolves into soft cream-and-tan mush with uneven, fragmented blocks. You can't tell collar from skin from shirt.

## hat

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 4 | 3 | 2 |
| B | 2 | 2 | 4 | 3 | 2 |
| C | 2 | 2 | 4 | 3 | 2 |

- **Best (all near-identical) against the master:** the master's hatband is a sharp checker of small bright and dark squares. Here the band is a row of large, soft-edged blurry gold blobs, and the brim's edge is a fine slanted staircase much smaller than the band's blobs. That mixes two scales.
- **Worst:** the same in all three. The band's lit squares (centre of the panel) are smeared, like an out-of-focus mosaic.

## coat (crop shows chin, neck and collar)

| | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 2 | 2 |
| B | 2 | 2 | 3 | 2 | 2 |
| C | 3 | 3 | 3 | 2 | 3 |

- **Best (C) against the master:** the master's coat is a dark, textured mosaic with a sharply stepped lapel edge. C's chin and neck squares are bolder and more even than A's. The cloth on the left, though, is a smooth dark-brown slope streaked with fine diagonal lines, with no squares.
- **Worst (A):** the lower lip and chin (upper right) are soft blur with only faint, uneven blocks. The left collar edge is a jagged white band chopped by black holes.

## Overall ranking

1. **C:** the boldest and most regular squares on face, moustache, chin and collar, and the closest of the three to the master's grid. It still has a flat black moustache with a thin, tilted philtrum, no drawn nostrils, noisy white specks for eyes, and a flat ear.
2. **B:** effectively the same as A, with a hair more jaw shadow. Soft patchwork skin, a pale bar for the philtrum, a seam line across the cheek, and blurred hatband and collar.
3. **A:** the same faults as B, and very slightly flatter at the lower-left jaw. Its skin is the softest and least square of the three.
