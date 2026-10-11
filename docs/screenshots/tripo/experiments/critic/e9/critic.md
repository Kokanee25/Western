# Blind critic: E9 (moustache)

Two panels, A and B, against the MASTER. A and B are the same render except in the moustache
and the skin next to it. A pixel diff of the two shows they differ only at the moustache's two
ends, at its top edge under the nostril, and at the corner of the mouth. Everything else (eyes,
ear, collar, the squares' grid) is identical, so most scores tie. I based my scores on
nose_moustache.png.

## nose_moustache.png

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Master's style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 3 | 3 |
| B | 2 | 3 | 2 | 2 | 2 |

**Best (A) vs the master: colour and outline.** The master's moustache is a dark-brown mass
with warm lighter clusters through it and a rounded outline. Its sides curve down past the mouth
at both ends, with a small lit gap of skin where the two halves meet above the lip. A's
moustache is near black and flat; about three-quarters of its dark pixels are near black,
against about a third in the master. Its top edge is notched like battlements, and the gap in
the middle (centre-left, under the nostril) is a large wedge of lit skin. That wedge reads as a
bite out of the moustache, not a small philtrum gap. A does have the master's drooping ends.
The right end runs down past the corner of the mouth toward the chin (lower right of the
panel), and the left end hangs lower (lower left).

**Worst (B): no droop.** Both ends stop at the line of the lip (lower left, and centre-right
beside the mouth), so the moustache is a flat dark bar with notches on top. It reads as a black
band over the mouth, not as a walrus moustache. Under the nostril (upper centre) there is a
fringe of reddish half-tone squares along the top edge. This softens the edge a little but adds
nothing readable.

Shared by both panels:
- The squares are slanted, uneven quadrilaterals, and inside the dark mass they melt together.
  The master's squares sit on a steady upright grid.
- The nostril is a small black notch with a lit speck, where the master's nostrils are two dark
  clusters.
- The lip is a bright stripe over a red-brown band. It reads as a lip, though harder and more
  banded than the master's.

## face.png

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Master's style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 3 |
| B | 2 | 3 | 3 | 3 | 2 |

**Best (A) vs the master: the tilted grid and the hard black features.** The whole face's
squares are tilted and trapezoidal, smaller and noisier on the cheeks. The master's are upright
and even. The features are drawn in pure black and white rather than the master's browns:
- The eyes are dark slots with star-shaped white glints (upper middle).
- The brows are black bars.
- The moustache is a black crenellated block.

At this size, A's drooping right end (beside the mouth, centre-right) is the one thing that
moves it toward the master's silhouette.

**Worst (B): a rectangle for a moustache.** It is the same face, but the moustache (centre) is
a rectangle cut level at the lip line. Next to the master's curved, drooping shape it reads as
a black mask over the mouth. B also shares A's flaws, worst first:
- The eyes are white specks.
- The ear is a lit orange wedge with no rim or hollow (right edge).
- The collar is broken into scattered white shards (bottom).

## Final ranking

1. **A**: the only panel whose moustache droops past the mouth at both ends, as the master's
   does. It is still near black, flat inside and notched along the top, with an oversized gap
   in the middle.
2. **B**: the same face, but its moustache is a flat black bar cut level at the lip. It reads
   less like a moustache and is further from the master's shape.
