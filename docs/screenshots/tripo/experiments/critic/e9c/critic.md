# Blind critic: e9c

Two images: `nose_moustache.png` (weighted most) and `face.png`. Panels A and B are the same render
except inside the moustache. Pixel for pixel, they differ only over the moustache's area: about 5 %
of the nose/moustache crop and 1.4 % of the face crop. Everything else (nose, cheeks, eyes, lip,
ear, collar) is identical, so the scores differ only where the moustache counts.

The moustache's tone, measured on its dark pixels (mean luminance / spread, 0-255):

| | Mean | Spread |
|---|---|---|
| MASTER | 30 | 15 |
| A | 24 | 12 |
| B | 16 | 11 |

Across the band where A and B differ, A averages 37 and B 22.

## nose_moustache.png

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Resemblance to master's style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 3 |
| B | 2 | 3 | 2 | 3 | 2 |

**Best (A) against the master.** The squares are the main difference. The master's sit level on
the screen's grid and are nearly all one size, while A's tilt about 15-20° with the head and come
in mixed sizes and odd L- and Tetris-shaped clumps. This shows most across the cheek above the
moustache and along the lit band under it. The moustache's shape differs as well. The master's is
one heavy mass that sweeps down past the corner of the mouth (lower right of the master panel).
A's is a flat horizontal bar with blunt, square-cut ends and no droop. Its middle has a large
wedge of lit skin, roughly triangular and about three squares wide (centre of the panel, under the
nose), where the master shows only a slight notch.

**Worst (B), biggest flaw.** The moustache (left half and centre of the panel) is a near-black
silhouette, darker than the master's. Inside it the squares are barely told apart, so it reads as
a flat cut-out pasted on the face rather than a mass of hair with brown variation and volume, which
is what the master draws. It also makes the jagged outline look even harsher against the bright
skin.

**Shared by both:**
- The nostril is only a tiny dark tick next to the eye-line glint (upper centre). The master's
  nose has broad planes of shadow under it.
- The cheek and the line between the face and the ear (right third) is a long, soft-edged
  diagonal ramp of slanted slivers, not squares.
- The lower lip (the lit band under the moustache) is readable in both.

## face.png

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Resemblance to master's style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 3 |
| B | 2 | 3 | 3 | 3 | 3 |

At face scale the gap between A and B is small. A's moustache reads a little more as hair and a
little less as a black stencil, but both get the same scores here.

**Best (A) against the master.**
- **The moustache's shape:** the master's is a thick drooping horseshoe whose ends run down past
  the mouth. A's is a short bar split by a big pale V in the middle, which reads almost as two
  separate dark blocks under the nose.
- **The eyes:** the master's are drawn with a lid line, a brown iris and a modest white. A's are
  dark slots with bright white star-like specks (both eyes, upper middle), which read as glints,
  not eyes.

**Worst (B), biggest flaw.** The same eyes, plus the near-black, flat moustache. Further flaws:
- the near ear (right edge) is a lit orange wedge with no rim or hollow;
- the collar (bottom left) is a scatter of slanted white and black shards, not the master's tidy
  collar with its shadow;
- the face's squares are visibly tilted and uneven against the master's level grid.

## Final ranking (all features, nose_moustache weighted most)

1. **A**: same drawing as B everywhere else, but its moustache keeps brown tonal variation inside
   its squares, nearer the master's dark-brown mass, so it reads as hair with some volume. It still
   has the wrong shape: a flat bar with blunt ends and a big gap of skin, no droop.
2. **B**: the moustache is a near-black, flat silhouette, darker and plainer than the master's, so
   it reads as a cut-out stencil. Its other faults are A's: slanted, irregular squares; star-speck
   eyes; a plain ear wedge; a shard-like collar.
