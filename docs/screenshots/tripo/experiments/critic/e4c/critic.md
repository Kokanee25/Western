# Blind critic: e4c (MASTER vs A, B, C)

The three panels are almost the same image. Measured pixel by pixel, the eyes, hat, ear and
nose/moustache panels differ by 0.01 to 0.07 of a level on average, which is invisible. Only the
collar, the coat and the lower edge of the face crop differ in a way you can see, and even there
only slightly. Mean differences are about 1 level, with no pixel more than 39 levels apart. The
differences all sit in the band where the neck meets the collar, the shirt front and the
neckerchief:
- A is darker there, by about 10 RGB levels on average.
- B and C differ from each other only in a few small patches: C's pale shirt-front cluster at the
  bottom centre is brighter and flatter, and a few small squares at the collar's right point differ.

Where the three tie, I give them the same scores. My working crops (the panels side by side at
1x to 4x, and maps of the differences ×8) are in `scratchpad/critic_e4c_work/`.

## Face

| | Squares | Crisp | 3D form | Readable | Master's style |
|---|---|---|---|---|---|
| A | 2 | 2 | 4 | 3 | 2 |
| B | 2 | 2 | 4 | 3 | 2 |
| C | 2 | 2 | 4 | 3 | 2 |

**Best vs master:** in the master, every surface of the face is a steady grid of square tiles, and
the jaw, nose and cheek outlines step crisply in them. The renders' squares lie on the face's
curved planes: across the forehead and cheeks they are slanted, smeared, trapezoidal patches, and
the outline of the jaw and cheek against the dark background is smooth or slanted rather than
stepped.

**Worst flaw:** none of the three is worse than the others. In all three the shirt collar and
neckerchief at the bottom left read as a churn of cream and black blotches, with no collar point
and no cloth knot.

## Eyes

| | Squares | Crisp | 3D form | Readable | Master's style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 2 |
| B | 2 | 3 | 3 | 3 | 2 |
| C | 2 | 3 | 3 | 3 | 2 |

**Best vs master:** the master's eyes are calm almond shapes: a dark iris, a small glint, a
continuous dark upper lid line and a soft lower lid. The brows are bold squared bars set clearly
above them. The renders' eyes are jagged clusters of hot white pixels (the right-hand eye is
especially speckled), with no continuous lid line. They read as sparkle, not as an eye shape. The
brows are present but smeared.

**Worst flaw:** the same in all three. The right-hand eye, centre-right of each panel, is a broken
scatter of white specks with no lid or almond outline.

## Nose and moustache

| | Squares | Crisp | 3D form | Readable | Master's style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 3 | 2 |
| B | 2 | 2 | 3 | 3 | 2 |
| C | 2 | 2 | 3 | 3 | 2 |

**Best vs master:** the master's moustache is two thick, crisply stepped dark masses with a small
gap of skin at the middle of the upper lip, a lit lip and a defined nostril. The renders'
moustache is one soft dark band with no philtrum gap, and its edges are blurred. The nose is a
broad lit slope with no squared nostril. The lip line is a soft reddish smear.

**Worst flaw:** the same in all three. There is no gap between the moustache's two halves, centre
of the panel, so it reads as a single blurred bar.

## Ear

| | Squares | Crisp | 3D form | Readable | Master's style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 1 | 2 |
| B | 2 | 3 | 2 | 1 | 2 |
| C | 2 | 3 | 2 | 1 | 2 |

**Best vs master:** the master's ear is a readable rim and hollow, drawn in squares, against dark
hair. The renders show a flat orange wedge with a red blot in the middle, lower centre, cut by a
smooth diagonal silhouette edge. There is no rim, no hollow and no lobe.

**Worst flaw:** the same in all three. The ear is unreadable: a red-centred orange sliver, not an ear.

## Collar (the shirt collar's edge, the neckerchief, the shadows where collar, neck and coat meet)

| | Squares | Crisp | 3D form | Readable | Master's style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 2 | 2 |
| B | 2 | 2 | 2 | 2 | 2 |
| C | 2 | 2 | 2 | 2 | 1 |

**Best (A) vs master:** the master's collar is a crisp white point with a hard, stepped zigzag
edge. Under it is a solid near-black neckerchief, and a clean dark shadow line where the collar
meets the coat. In all the renders the collar is an amorphous cream blob with ragged, irregular
edges, left side and bottom of each panel. It has no collar point and no clean edge line, and the
neckerchief is scattered dark islands rather than one shape. A is marginally the best because its
band of neck skin just above the collar is a little darker. That gives a slightly deeper shadow
between neck and collar and separates the two a touch better. It is still far from the master's
crisp shadow edge.

**Worst (C) flaw:** C's shirt front at the bottom centre, about x 260-300, y 340-390 of the panel,
is a brighter, flatter pale cluster. The cream there has merged into one washed-out shape, so what
little modelling the collar had is gone. Neck, collar and shirt front blur together most in C.

## Hat

| | Squares | Crisp | 3D form | Readable | Master's style |
|---|---|---|---|---|---|
| A | 2 | 2 | 4 | 3 | 2 |
| B | 2 | 2 | 4 | 3 | 2 |
| C | 2 | 2 | 4 | 3 | 2 |

**Best vs master:** the master's band is a clear row of crisp square studs and checks against a
cleanly stepped brim. In the renders the band is a soft, blurred row of warm blobs, and the brim's
edge is a fine anti-aliased line with thin streaks, not stepped squares. The brim reads well as a
3D form.

**Worst flaw:** the same in all three. The hat band, centre of the panel, is out-of-focus blobs
rather than authored squares.

## Coat (and the collar, neck and coat junction)

| | Squares | Crisp | 3D form | Readable | Master's style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 2 | 2 |
| B | 2 | 2 | 2 | 2 | 2 |
| C | 2 | 2 | 2 | 2 | 2 |

**Best (A) vs master:** the master's coat and lapel are a mottled tweed of even squares. The lapel
edge is a hard stepped diagonal with a dark outline, and it is clearly separate from the cream
collar and black neckerchief. In the renders the left edge of the panel, where the coat should be,
is mostly dark slanted streaks and smooth anti-aliased diagonals. There is no readable lapel, and
the cream collar blob runs straight into the neck skin. A's darker neck-and-collar band gives the
junction a little more shadow and depth than B and C, but there is still no defined edge.

**Worst flaw (B and C, nearly tied):** where the neck meets the collar, centre-left of the panel
at about y 150-300, the skin and the cream collar fade into each other with no shadow line. The
collar reads as part of the neck, not cloth laid over it.

## Final ranking over all features

1. **A.** It ties B and C everywhere except the collar and coat, where its slightly deeper shadow
   between the neck and collar separates them a little better. It is still far from the master's
   crisp collar edge and its stepped squares.
2. **B.** The same as A except that the neck-and-collar band is a touch lighter and flatter, so
   neck, collar and coat merge more.
3. **C.** The same as B, but its shirt-front cream at the bottom of the collar is brighter and
   flatter, the most washed-out collar of the three.

Overall the three are nearly indistinguishable. All three share the same main gaps from the
master's style, and none of these gaps is touched by what separates them:
- The squares lie on surfaces, slanted and fragmented, not on a steady grid.
- The outlines are smooth or anti-aliased rather than stepped.
- The eyes are white sparkle with no lid line.
- The moustache has no philtrum gap.
- The ear is unreadable.
- The collar has no crisp point or edge, and the neckerchief has no shape.
