# Blind critic: building lab, 2026-10-22

Judged only by eye: the five reference paintings in `build/bl/refs/` against the six renders in
`renders/` (1280x720). Crop boxes are [x0, y0, x1, y1] in the render's pixels.

## front.jpg (golden hour) vs sheet_front — CLOSE

The layout matches: two storeys, a gallery across the front, five bays, a central door and a sign
up top. The silhouette and dressing do not.

1. **The false front is a plain flat box.** The painting has tall capped corner posts and pilasters
   rising above the roof and a raised, scrolled pediment holding the sign. The render's parapet is a
   flat rectangle with a thin cap and no posts. [355, 165, 925, 360]
2. **The windows are dark and nothing glows.** The painting's four windows shine amber and wall
   lamps flank the doors. The render's windows are dark shuttered panels, with no lamps on the
   porch. [400, 290, 880, 520]
3. **The sign is small and dark.** The painting has a big red board with large cream letters
   filling the pediment. The render has a small brown plaque with dark letters on a darker patch
   of wall. [570, 205, 720, 255]
4. **The gallery and porch framing is spindly.** The render has a dense run of thin spindles and
   thin porch posts with no knee braces. The painting has chunky balusters, heavy posts that carry
   through both storeys, curved brackets under the gallery and small hipped roofs at each end.
   [285, 340, 950, 540]
5. **The siding and the porch differ.** The render's walls are streaky grey-brown weathered
   planks. The painting's are evenly painted barn red. The render's porch is empty: no benches,
   chairs, barrels or wide front steps. Its door is a plain tall opening with a pale patch, not
   framed batwings. [380, 470, 900, 560]

## front_night.jpg vs sheet_front — DIFFERENT

At night it reads as a closed, empty shell, not the lit saloon of the painting.

1. **It is almost unlit.** The whole building is one flat blue-grey wash. Only two upstairs
   doorways glow faintly amber and one lower window shows a small light. Nothing like the warm
   lit windows and lamps of the painting. [285, 270, 950, 560]
2. **One upstairs window glows cold blue-white,** a hard rectangle that stands out from everything
   else. [420, 270, 460, 320]
3. **The porch is lit flat and pale.** Its front fascia and posts read as pale lavender against
   the dark ground, with no lamp pools. [280, 520, 950, 565]
4. **The sky is busy.** Big streaky blue-grey cloud shapes with stars dominate the top half and
   pull the eye from the building. [0, 0, 1280, 260]
5. **A dark object sits in front of the porch at lower left,** a small black bench or post shape
   that is unreadable at night. The sign stays the same dark plaque and hardly shows.
   [350, 440, 450, 495]

## side_east.jpg vs sheet_side_east — DIFFERENT

1. **The side is one blank flat wall.** It is a single plane of vertical grey-brown boards. The
   painting has a main block with red horizontal siding, a wrap-round gallery with posts on the
   front third, and a lower rear annex with its own roof. [230, 200, 960, 560]
2. **The outside staircase is nearly invisible.** It shows as a faint thin diagonal the colour
   of the wall. In the painting the stair is the main feature, with a heavy stringer, a turned
   balustrade and newel posts. [600, 350, 900, 560]
3. **The porch and gallery are a shallow stub at the opposite (right) end.** In the painting the
   gallery and porch posts run along the left third, with the balcony above. [880, 310, 1080, 560]
4. **The windows are few, small and dark,** three small upper panes and one shuttered lower
   opening. The painting has warm lit windows on both floors. [320, 260, 820, 330] and
   [270, 420, 330, 490]
5. **The ground and roofline are bare.** No crates, bench or barrels stand along the wall, and
   there are no capped corner posts. A slanted shard sticks up above the roof at the right, and
   an orange sunburst sky with a canyon backdrop fills the view. [850, 120, 960, 215]

## entrance.jpg vs sheet_entrance — CLOSE

The shape of the room carries over: galleries on two levels, a chandelier in the middle, tables
on the left and a bar on the right. The life and light do not.

1. **It is much darker.** Most of the frame is brown-black, lit by a few small sconces. The
   painting is bathed in amber light from many glowing lamps, with a bright floor and walls.
   [0, 0, 1280, 720]
2. **A big dark post in the foreground** blocks the left-centre of the view from floor to ceiling.
   [300, 0, 420, 720]
3. **The back wall is bare.** The painting's back wall has tall double doors, an upright piano,
   framed pictures, and windows along both galleries. The render shows plain planking, arched
   openings and a few sconces. [420, 160, 800, 460]
4. **The staircase barely shows.** The painting's broad stair with its turned balustrade climbs
   prominently on the left. The render shows a faint dark slope against the left wall.
   [0, 280, 300, 500]
5. **The bar and the furniture are sparse.** On the right is a long plain dark counter with pale
   empty arched niches above, no stools and no bottles. The few tables have green baize tops. The
   painting has red-topped stools, a lamp-lit back bar, round wooden tables with many chairs and
   candles, and a large iron ring chandelier of glass oil lamps (the render's is a small candle
   wheel). [950, 330, 1280, 560] and [0, 440, 700, 620]

## from_balcony.jpg vs sheet_from_balcony — DIFFERENT

1. **The room sinks into darkness.** Floor, walls and the near gallery are mostly black-brown.
   The painting glows warm everywhere, with a bright plank floor and many lamps. [0, 0, 1280, 720]
2. **The railing is thin.** It is plain square slats under a plain rail, one run slanting across
   the frame. The painting frames the view with a corner of chunky turned balusters and a thick
   moulded handrail on both sides. [150, 320, 1100, 720]
3. **No bar fills the centre.** The painting's middle has a bar with stools and a back bar of
   bottle shelves. The render's floor is open and empty, with two small green tables and a dim
   counter far back. [600, 230, 1000, 360]
4. **The chandelier is small.** The render has a modest ring of candle lamps. The painting has a
   large tiered iron chandelier of many lamps on a long chain, the bright centre of the picture.
   [540, 140, 680, 210]
5. **The galleries and walls are bare planking.** The painting has doors, windows and framed
   pictures along both gallery levels. The render also leaves a large empty dark slab of gallery
   floor and wall on the right. [150, 0, 1050, 180] and [900, 150, 1280, 720]

## picture.jpg vs picture.png — DIFFERENT

1. **There are no people.** The painting is a busy night: a cowboy at the near table, card
   players, a barkeep, a man at the piano, a figure on the gallery. The render is an empty room.
   [0, 0, 1280, 720]
2. **The back bar is unrecognisable.** The render has pale beige arched niches with empty shelves
   above a plain dark counter. The painting has a dark back bar crammed with bottles, a mirror
   and lamps. [400, 250, 780, 400]
3. **The light is one dim brown.** The painting plays blue moonlight against amber lamps through
   an open doorway onto the moonlit street at left. The render's left side is a closed dark wall
   and doorway, and the whole frame is brown. [0, 100, 260, 500]
4. **The finish and woodwork are plainer.** The render is smooth 3D shading on plain square posts,
   arched braces and flat plank walls. The painting is chunky painted pixels, with panelled walls,
   framed paintings, a mounted elk head, a staircase and turned gallery balusters.
   [250, 0, 1280, 450]
5. **The foreground differs.** The painting looks across a close round wooden table with an oil
   lamp, tin cups, a bottle and the player's own hand. The render has a green baize table with
   chairs off to the right and a railing fragment cutting into the bottom edge.
   [780, 370, 1280, 720]

## Overall top three

1. **The interiors are far darker and emptier than the paintings.** None of the paintings' warm
   amber glow comes through: rooms are mostly brown-black, the walls are bare planking (no doors,
   pictures, piano or windows), furniture is sparse, and there are no people
   (entrance, from_balcony, picture).
2. **The woodwork is thin and plain where the paintings' is heavy and ornamented.** Thin square
   spindles and slats stand where the paintings have chunky turned balusters and thick handrails.
   Plain posts lack capitals, brackets and mouldings, and outside there are no capped pilasters
   and no raised pediment for the sign (front, side, from_balcony, picture).
3. **The outside reads as a plain weathered box, not the painted saloon.** It has streaky
   grey-brown boards instead of red painted siding, dark unlit windows, and no porch furniture.
   The side elevation is a blank wall with its staircase and gallery all but missing
   (front, front_night, side_east). Inside, the back bar's pale empty arches replace the bottles
   and mirror.

## Verdicts

| Render | Reference | Verdict |
|---|---|---|
| front.jpg | sheet_front | CLOSE |
| front_night.jpg | sheet_front | DIFFERENT |
| side_east.jpg | sheet_side_east | DIFFERENT |
| entrance.jpg | sheet_entrance | CLOSE |
| from_balcony.jpg | sheet_from_balcony | DIFFERENT |
| picture.jpg | picture.png | DIFFERENT |
