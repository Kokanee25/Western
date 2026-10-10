# Blind critic: feature panels against the MASTER

Scores are 1 (far from the master) to 5 (as the master). The columns are: Reg = square regularity, Crisp = crispness, 3D = 3D form, Read = semantic readability, Style = resemblance to the master's style.

## face

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 4 | 4 | 3 |
| B | 3 | 3 | 3 | 3 | 3 |

- **Best (A, by a hair) vs master:** the master's squares are bold, one size and hard-edged across the whole face. A's cheeks and forehead melt into small soft blocks and smooth gradients, so the head reads as a lit 3D portrait with a light pixel texture, not a drawing in squares. This is clearest on the lit cheek, centre-left.
- **Worst (B):** the skin is in honest square tiles, but the forehead and the hat brim above the eyes break into stretched horizontal slivers. The eyes are small dark slits lost in that band, so the face's most important feature is the weakest. This is in the upper third of the panel.

## eyes

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 4 | 4 | 3 |
| B | 3 | 3 | 2 | 2 | 2 |

- **Best (A) vs master:** the master draws each eye as a clean almond, with a lid line, a white either side and a dark iris. A's eyes are dark irises with scattered pure-white star glints and cream flecks at the inner corners, with no drawn lid or white shape. They read as wet, glinting eyes, not drawn ones. The skin under them is a soft smear rather than squares; see the lower-left cheek.
- **Worst (B):** the brows and the brim's shadow merge into one dark band across the top half. Each eye is a tiny dark slit with a white block glint, so lid, white and iris can't be told apart. The brim above is smeared into horizontal streaks, not squares (top 40 % of the panel).

## nose_moustache

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 4 | 3 | 2 |
| B | 4 | 3 | 3 | 2 | 3 |

- **Best (B) vs master:** B's skin is a regular mosaic of near-square tiles, the closest in the set to the master's grid. But its moustache is a muddy dark mass with no hard outline and no gap of skin at the philtrum. The nose barely separates from the cheek; the master's moustache is a crisp, stepped, near-black shape with drawn edges. See the left-centre of the panel.
- **Worst (A):** everything is soft. The moustache is a blurred brown cloud with fuzzy edges and a warm red smudge in its middle, and the lip below is a smooth gradient. The square cells are small and averaged, so it reads as a smooth render under a faint pixel filter (centre of the panel).

## ear

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 3 | 3 | 3 | 2 | 2 |
| B | 3 | 3 | 2 | 1 | 2 |

- **Best (A) vs master:** the master draws the ear's rim and its hollow with deliberate darker squares inside a lighter shell. A's ear is a bright orange-cream wedge with one red blotch in the middle, so it has an outline but no drawn rim or hollow. Its silhouette steps cleanly; the inside is a soft gradient (centre-left).
- **Worst (B):** the ear is a flat glowing orange shape with blocky red patches and no internal structure. Against the dark hair it reads more like a flame or a lit cloth edge than an ear (left half of the panel).

## collar

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 2 | 2 |
| B | 3 | 3 | 3 | 2 | 3 |

- **Best (B) vs master:** the master's collar is two white points with crisp zig-zag stepped edges, and a dark shadow cut under each one. B's chin and neck are in clear square tiles. The collar, though, is a ragged field of cream blocks and dark shards with no collar points and no clean shadow under them (lower third of the panel).
- **Worst (A):** the collar is a soft, blown-out cream smear with scraggly, splintered edges and loose dark fragments. You can't tell collar from shirt from neckerchief; the bottom half of the panel reads as noise.

## hat

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 1 | 3 | 3 | 1 |
| B | 2 | 3 | 2 | 3 | 3 |

- **Best (B) vs master:** B's band is a row of distinct lit and dark tiles, close to the master's checkered band. The tiles are uneven trapezoids of different sizes, not the master's even squares. B's brim below the band is drawn as thin horizontal streaks with no form, where the master's brim is a smooth dark curve with a stepped edge (lower half of the panel).
- **Worst (A):** the band's highlights are large blurred blobs and the brim is a set of diagonal streaky lines. There is no square structure anywhere, so it looks like a low-resolution texture smeared by motion (whole panel, worst in the centre band).

## coat

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 2 | 2 |
| B | 2 | 3 | 2 | 2 | 2 |

- **Best (A, narrowly) vs master:** the master's coat is a dark tweed of near-square tiles with a hard, staircase edge against the collar and chin. A's coat at the left edge is a dark, near-smooth mass with no tile texture. Its edge against the collar is clean but its fabric is undrawn (left third of the panel).
- **Worst (B):** the coat at the left edge breaks into slanted shards and lit splinters where it meets the collar, so the garment's edge is fragmented rather than stepped (lower-left of the panel).

## Final ranking

1. **B:** the closer visual language. Its skin, chin and hat band are in fairly regular, hard-edged square tiles near the master's size. It is let down by smeared horizontal streaks on the brim and brow and by unreadable eyes. Its moustache has no philtrum gap and its collar points are lost.
2. **A:** the stronger readable features and 3D form: bold brows, dark irises, a solid moustache mass and a modelled face. But it is drawn soft: small averaged cells, blurred gradients, a blob-and-streak hat and a smeared collar. It reads as a smooth render under a light pixel filter rather than a painting in deliberate squares.
