# Blind critic, e6

Each feature image has three panels: MASTER, A and B. Scores run 1 (far from the master) to 5 (as the master). Columns: Reg = square regularity, Crisp = crispness, 3D = 3D form, Read = semantic readability, Style = resemblance to the master's style.

## Face

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 4 | 3 | 3 | 3 |
| B | 2 | 2 | 3 | 3 | 2 |

**Square size and regularity (both panels).**
- The master's face squares are about 8–10 px in this panel. They sit on one steady, screen-aligned grid, and the cheek, jaw and chin step in even rows.
- A's squares are smaller, mostly about 5–6 px. Many are not square: there are thin upright strips and 2:1 bricks on the cheek under your-right eye, and the rows tilt with the face, running diagonally down the lit cheek toward the jaw. So the grid wanders from plane to plane, and at the cheek-to-nose turn it breaks into odd fragments.
- A's squares are hard-edged and flat inside. The master's have a slight soft fringe but a steadier grid, so A is crisper than the master but less orderly.

**Best vs master.** A's biggest difference is that its squares are smaller, slanted and uneven, against the master's larger, even, screen-aligned grid.

**Worst panel's flaw.** B's skin is smeared. The squares on the forehead and lit cheek melt into soft, averaged blotches, and on the lower jaw the grid barely reads.

## Eyes

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 4 | 3 | 2 | 2 |
| B | 2 | 2 | 3 | 2 | 2 |

**Best vs master.** The master's eyes are drawn almond openings: a clear warm white either side of a round brown iris, a dark upper lid, and a lid crease. A's eyes are dark pits with a few scattered single white pixels in stair-step shapes. Those whites are notched specks at the inner and outer ends of the opening, with no continuous white and no round iris. The brows are good: thick, near-black and blocky.

**Worst panel's flaw.** B has the same speckled eyes as A, and the skin round them is soft and smeary. The lid crease and socket under the far brow blur into the hat's shadow.

## Nose and moustache

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 4 | 3 | 3 | 3 |
| B | 2 | 3 | 3 | 3 | 2 |

**Best vs master.** The master's moustache is a drooping, textured mass with tone inside it (dark-brown clusters with lighter flecks) and a stepped outline. A's is a flat near-black slab. Its philtrum gap is a tall, sharp-sided rectangle of skin cut right through the middle, so it reads as a split block or a missing tooth rather than a small gap at the top of the upper lip. The nostrils are only a faint thin line under the nose tip.

**Worst panel's flaw.** In B the mouth under the moustache is a soft pale smear, with no defined lip line. The same over-tall gap in the middle reads even more like a hole.

## Ear

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 1 | 2 |
| B | 1 | 2 | 2 | 1 | 1 |

**Best vs master.** The master's ear is clearly an ear: a lit outer rim, a dark hollow, and the tragus, drawn in deliberate blocks. A shows no ear shape. On the right there is a flat orange wedge with a red blotch in the middle, and a jumble of stretched slivers under the hat brim. There is no rim or hollow to find.

**Worst panel's flaw.** B's wedge is the same, but smeared into a glowing gradient. On the left edge, the bright vertical streak is a soft blur rather than squares.

## Collar

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 1 | 2 |
| B | 1 | 2 | 2 | 1 | 1 |

**Best vs master.** The master has a crisp white turned-down collar point, a stair-stepped edge, a dark shadow and tie beneath it, and coat lapels with zigzag edges. In A, the white mass round the neck has no collar shape. It is a ragged cream blob with dark squares speckled through it, low on the left and lower middle, and no edge or cast shadow separates it from the throat.

**Worst panel's flaw.** B's white blob is softened as well, so its boundary with the neck smears. The dark squares inside it read as dirt.

## Hat

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 3 | 4 | 4 | 4 | 4 |
| B | 2 | 2 | 3 | 3 | 2 |

**Best vs master.** A's checked band is the closest thing to the master anywhere: hard, even, near-square blocks in warm golds and browns. They are about 1.5 times the master's stud size, though. The brim's top surface is fine streaky lines along the curve, a sub-square stripe texture that the master doesn't have; the master's brim is a broad, smooth dark plane.

**Worst panel's flaw.** B's band is blurred. Its blocks glow into each other like an out-of-focus photo, especially the bright cluster in the middle of the band.

## Coat (this crop shows the chin, throat and collar)

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 2 | 2 |
| B | 2 | 2 | 3 | 2 | 2 |

**Best vs master.** The master shows a tweed lapel with a clean zigzag outer edge, a white collar point and the dark tie, all in ordered squares. A has little readable coat: a dark smeared edge on the left with slanted slivers, a big blotchy white collar mass, and the chin's squares in tilted rows.

**Worst panel's flaw.** In B the left coat edge and the collar's boundary are soft, so the coat, collar and throat run together in the lower middle.

## Final ranking

1. **A.** Crisper and harder-edged everywhere, and the hat band nearly reaches the master's language. But its face squares are too small, slanted and uneven (strips and bricks following the face's planes rather than a steady grid). Its eyes are speckles rather than drawn whites and irises, the moustache gap is a tall slot, and the ear and collar don't read.
2. **B.** The same drawing as A, but soft and averaged. Squares melt into blotches on the cheeks, hat band and collar, which loses the master's crisp, authored blocks. It has all of A's readability faults as well.

**Common to both, the biggest gap to the master:** the face's squares should be bigger (about 8–10 px here), even and on one steady screen-aligned grid. The small features (eye whites and irises, nostrils, a small philtrum notch, the ear's rim and hollow, the collar's edge and shadow) should be deliberately drawn rather than left to chance pixels.
