> Round 1: on the first build (the bar on the east wall, on your left from the door; its renders were replaced by round 2's after the mirror). Its crop boxes refer to those.

# Blind critic: building lab, 2026-10-22

Renders are 1280x720; crop boxes are [x0, y0, x1, y1] in render pixels. Mean luminance (0-255) is
given where brightness matters: the interior references sit at 56-61, the interior renders at 20-27.

## front.jpg (golden hour) vs sheet_front: **CLOSE**

1. **Silhouette.** The render is a plain flat-topped box with a thin cornice; the reference has a
   stepped false front with tall capped corner pilasters rising above the roof, a raised sign
   pediment, and small roofed wings at each end of the gallery. [350, 160, 930, 260]
2. **Windows.** The render's windows are dark, plain openings; the reference's are warm, glowing,
   multi-pane mullioned windows that are the brightest thing on the facade.
   [400, 295, 880, 530]
3. **The sign.** A small dark plaque with thin letters in the render; in the reference a big carved
   sign board with large cream letters dominates the top third. [565, 210, 720, 255]
4. **Openings.** The render has five equal windows upstairs and four windows plus a narrow door
   below. The reference has two windows and a centre cluster (window, door, window) upstairs, and two
   windows either side of big batwing double doors at the top of wide steps below.
   [280, 290, 960, 570]
5. **Porch and gallery.** The render has thin pale stick posts and a fine spindle rail with no
   brackets, and the porch is bare. The reference has heavy posts with knee brackets, a chunky turned
   balustrade, chairs and benches along the porch, and wall lamps by the door. Posts and rail:
   [280, 340, 960, 560]

## front_night.jpg vs sheet_front: **CLOSE** (the same building, but the mood is DIFFERENT)

1. **No warm light.** Nearly every window is dark and there are no lamps glowing by the door. The
   reference's identity is its amber windows and porch lamps. [400, 290, 940, 540]
2. **Cold cast.** The whole building is washed blue-lavender. The porch posts, beam and steps glow
   pale lilac as though lit from in front, not the dark red-brown of the reference.
   [280, 380, 960, 570]
3. **One cold window.** The one bright upstairs window glows a cold blue-white, not amber.
   [420, 300, 460, 350]
4. **Sky.** The top half of the frame is a busy navy sky of smeared white streaks that pulls the eye
   away from the building. [0, 0, 1280, 330]
5. **The same build differences as the golden-hour view:** flat box with no false front or
   pilasters, a small sign, plain windows and thin porch posts. [350, 160, 930, 560]

## side_east.jpg vs sheet_side_east: **DIFFERENT**

1. **The gallery is missing.** In the reference a deep two-storey roofed gallery with heavy posts
   and a balustrade covers the left third of the side. The render shows a long blank wall, with only
   a thin small balcony and porch at the far right (the building is mirrored relative to the sheet).
   [860, 300, 1080, 560]
2. **The staircase.** The reference's outside stair is a bold diagonal with a heavy turned
   balustrade, landing at the gallery. The render's is a faint thin stringer with no rail, the same
   brown as the wall and nearly invisible, and it climbs the other way. [620, 360, 900, 560]
3. **The walls.** The reference has a red-painted horizontal clapboard main block with grey
   weathered boards on the wings. The render is one uniform brown of vertical unpainted planks.
   [370, 230, 940, 550]
4. **Massing.** The reference is compact and nearly square, with tall capped pilasters above the
   roofline and a lower lean-to wing at the back. The render is a long, low box about twice as long
   as it is tall, with a flat roofline and a slanted false-front edge poking up at the right.
   [230, 120, 960, 560]; the false-front sliver is at [850, 120, 960, 220]
5. **Windows and dressing.** The reference has lit mullioned windows, and crates, a bench and boxes
   stacked under the stair. The render has dark shuttered blanks, and nothing stands along the wall
   or at the stair foot. Windows: [320, 265, 810, 340]; ground: [230, 500, 960, 560]

## entrance.jpg vs sheet_entrance: **DIFFERENT**

1. **Darkness.** The render is mostly brown-black (mean 24 against 58), lit by a few scattered
   sconces and three table lamps. The reference glows gold throughout, with many wall lamps, candles
   on every table and a blazing chandelier. [0, 0, 1280, 720]
2. **Mirrored layout.** The render's bar runs along the left wall and its stair rises on the right;
   the reference has the stair on the left and the bar, with its stools, on the right.
   Bar: [0, 410, 310, 550]; stair: [970, 280, 1280, 500]
3. **Scale and emptiness.** The render is a cavernous barn-like hall with an open truss roof, tall
   bare plank walls and arched openings under the gallery, and a few green-baize tables lost in the
   middle distance. The reference is a compact, low-ceilinged room crowded with round wooden tables,
   a piano, a rug, pictures, and back double doors, with the gallery's windows and doors on three
   sides. [300, 0, 1280, 640]
4. **The centre post.** A thick dark column stands dead centre in the foreground and splits the view
   in two; in the reference the centre is open down to the back doors and the piano.
   [850, 0, 990, 720]
5. **Artefacts.** A bright blue streak of sky shows where the right wall meets the roof, and a row of
   pale chequered blocks runs along the right wall like a missing texture. [970, 0, 1280, 290]

## from_balcony.jpg vs sheet_from_balcony: **DIFFERENT**

1. **Darkness.** The render is near-black at the edges with a dim haze in the middle (mean 20 against
   56). The reference is a bright golden room. [0, 0, 1280, 720]
2. **No bar.** The reference's centrepiece, the bar and a back bar lined with shelves of bottles, is
   not in view. The floor below is a large empty expanse with three green-topped tables.
   [480, 240, 1100, 640]
3. **The near railing.** Plain thin square slats, low and dark, run diagonally across from the left,
   and a dark balcony floor fills the left third. The reference frames the view with heavy turned
   balusters and a thick handrail in a V. [0, 180, 900, 720]
4. **The chandelier.** In the render it is a small dim ring of a few lamps, high up in the haze; in
   the reference a large multi-tier chandelier blazes in the centre of the frame.
   [600, 150, 740, 210]
5. **Gallery and stair.** The render's upper walls are bare planks with a few barely visible dark
   doors, the opposite gallery's rail reads as a sparse row of short pegs, and a big staircase drops
   down the right side. The reference's gallery is lined with doors, windows, framed pictures and
   sconces behind a turned balustrade, and has no stair in view. Gallery: [300, 40, 1280, 330];
   stair: [1000, 250, 1280, 700]

## picture.jpg vs picture.png: **DIFFERENT**

1. **No people.** The painting is full of life: the cowboy in close-up, card players, a bartender, a
   pianist, a man on the gallery. The render is an empty room. [0, 0, 1280, 720]
2. **The foreground.** The painting's foreground is a big round wooden table with a glowing oil lamp,
   tin cups, a bottle and the viewer's hand. The render has a small green-baize pedestal table with
   empty chairs at middle distance, with only a lamp on it. [80, 340, 560, 600]
3. **Light and colour.** The render is a uniform dim red-brown (mean 27 against 61). It has none of
   the painting's bright lamp glows, and none of the cool blue moonlit street seen through an open
   door at the left. [0, 150, 400, 450]
4. **The back bar.** Far off behind a dark low bar the render shows a row of pale, blank arched
   panels. The painting's back bar is close on the right, crowded with bottles, a mirror and the
   bartender. [560, 260, 1040, 440]
5. **Surface and dressing.** The render's wood is smooth and glossy, and the floor reflects like a
   polished surface. The painting is coarse and painterly, with visible square pixel blocks, and is
   dressed with a mounted deer head, a framed painting and a piano. Floor: [300, 450, 1200, 720]

## Overall top three

1. **The interiors are far too dark and monochrome.** The three interior renders have under half the
   references' brightness (mean 20-27 against 56-61). Where the references glow amber with many
   lamps, candles and a blazing chandelier, the renders are brown-black with a few scattered
   sconces.
2. **The rooms are empty, under-dressed and laid out differently.** The bar and stair are mirrored
   in the entrance view, the hall is a cavernous barn with an open roof, the bar and back bar are
   missing from the balcony view, and the tables are green baize. The references' crowd of tables,
   bottles, piano, pictures and, in the painting, people is absent.
3. **The exterior is plainer and differently built.** It is a flat box without the stepped false
   front, the tall capped pilasters or the big sign. Its windows are dark and plain, not warm and
   mullioned, and its porch posts and rails are thin where the reference's are heavy, bracketed and
   turned. The side view lacks the wraparound gallery and the bold outside stair.
