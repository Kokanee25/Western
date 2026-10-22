# Blind critic: worn vs plain wood (2026-10-22)

Judged from the ten renders in this folder and the target painting `build/bl/refs/picture.png`, and nothing else.
**Method:** I compared each pair by eye, brightened (gamma 0.5–0.6) and cropped to about 800 px. The marks are so faint
in four of the five pairs that I also made an A/B log-luminance ratio map to find where the two images differ.
That separates sharp-edged texture changes from smooth lamp flicker (every pair also differs by flicker: lamp halos and
the green table tops, which I've ignored). I then judged each place by eye. All crop boxes are `[x0, y0, x1, y1]` in the
1280×720 frame. Working images are in `/tmp/claude-0/critic3/`.

The marks are the same kind of thing in every pair, which helps tell the two images apart:
- **pale, scuffed floor** under chairs, on paths and where men stand at the bar
- **darker grime** along the foot of the bar
- **soot** round the wall sconces
- **paler newel and rail tops** on the stair

## 1. entrance: **B** has the marks (sure, from the ratio map; by eye alone "probably")

| # | Mark (in B) | Box | Caused / decoration |
|---|---|---|---|
| 1 | Pale, scuffed pool on the floor round the middle table's chairs and base | [560, 465, 730, 545] | CAUSED (chairs scraped back, feet under the table) |
| 2 | The same pools under the near-left table's chairs and bench | [0, 520, 300, 650] | CAUSED |
| 3 | Smaller pools under the far tables' chairs | [410, 425, 540, 475] | CAUSED, but too small to see from here |
| 4 | A pale strip worn across the boards, from just past the near post towards the middle table | [415, 490, 565, 545] | CAUSED (a walking line) |
| 5 | Paler, worn boards in front of the bar, near the camera on the right | [1100, 560, 1280, 720] | CAUSED (where men stand at the bar) |
| 6 | A darker grime band along the foot of the bar front and its kick | [960, 470, 1280, 560] | CAUSED (boots and spit) |
| 7 | Soot round the six back-wall sconces: a grey, speckled smudge that dulls each lamp's halo | [547, 168, 580, 240], [717, 168, 755, 240], [419, 312, 442, 416], [586, 312, 618, 416], [765, 312, 790, 416], [1024, 312, 1048, 392] | CAUSED in place, but it reads as "the lamp is dimmer", not as soot |
| 8 | A darker line on the left wall at the ledger | [0, 280, 260, 310] | Can't see it by eye |

**Strength: too faint.** At this distance only the chair pools (1, 2) and the sconce soot can be found, and only with the
two images side by side. Alone, B just looks like a slightly dustier floor.

## 2. picture: **B** has the marks (sure, from the ratio map; by eye "probably")

| # | Mark (in B) | Box | Caused / decoration |
|---|---|---|---|
| 1 | A sandy, blotchy, scuffed patch under the near chair by the table | [790, 560, 1000, 690] | CAUSED in place. The edge is blocky and ragged, like a pale decal laid on the boards |
| 2 | The same patch under the right-hand chair | [1080, 580, 1280, 660] | CAUSED |
| 3 | Smaller pools under the far chairs at the table | [770, 500, 900, 540] | CAUSED |
| 4 | Soot round the sconces at the back bar and right wall: duller halos with a grey smudge | [280, 200, 310, 330], [770, 240, 800, 330], [955, 210, 1010, 330] | CAUSED in place, but it reads as a dimmer lamp |
| 5 | A darker grime band along the floor at the foot of the back bar | [300, 416, 755, 444] | CAUSED |
| 6 | A darker band along the back bar's cornice, above the arches | [320, 248, 770, 266] | Could pass for smoke grime near the ceiling; invisible by eye |
| 7 | The door edge on the left is paler at hand height, and its threshold is paler | [186, 330, 222, 426], [120, 480, 222, 498] | CAUSED (hands on the door, feet over the sill) but only a few pixels |
| 8 | A darker band across the upper left wall | [72, 162, 216, 252] | Looks like DECORATION (nobody touches it there); invisible by eye |

**Strength: about right for the chair scuffs (1, 2)**, the only marks a viewer would notice on their own. The rest is too faint.

## 3. stair_close: **B** has the marks (sure, from the ratio map; by eye "probably", the soot gives it away)

| # | Mark (in B) | Box | Caused / decoration |
|---|---|---|---|
| 1 | A tall, speckled soot column round the right back-wall sconce, running both **above and below** it | [940, 140, 1020, 360] | Half CAUSED: soot above a lamp is right, but the part below the lamp reaches down towards the wainscot and makes the whole thing read as a dark rectangle |
| 2 | Soot round the left sconce under the stair | [745, 200, 810, 330] | CAUSED |
| 3 | A darker smoke line along the top of the back wall at the ledger | [880, 145, 1280, 190] | CAUSED (smoke collects under the ceiling) |
| 4 | Pale, scuffed patches in the middle of the lower treads | [418, 397, 548, 431], [514, 295, 594, 329] | CAUSED (the middle of the treads). Blotchy and square-edged |
| 5 | The newel post a shade paler and flatter, as if rubbed | [240, 280, 320, 704] | CAUSED (where hands grip at the foot of the stair) |
| 6 | A pale line along the top of the handrail | [320, 60, 680, 300] (along the rail) | CAUSED (hands on the rail), but only visible in the ratio map |
| 7 | Paler floor at the bottom right | [1150, 540, 1280, 610] | Unclear what it's a path to |

**Strength: the soot is about right, even slightly overdone** (1 is the most visible mark in the pair). The treads, newel
and rail are too faint: this is the view where hand polish should show, and it barely does.

## 4. bar_floor: **A** has the marks (sure, visible by eye without help)

| # | Mark (in A) | Box | Caused / decoration |
|---|---|---|---|
| 1 | A pale, scuffed patch of boards in front of the bar, a step back from its foot | [957, 534, 1280, 702] | CAUSED (where men stand at the bar). The patch is made of big, visible pale squares, a checker more than a wear pattern |
| 2 | A darker band of floor right at the bar's foot | [992, 427, 1280, 534] | CAUSED (dirt and spit under the rail) |
| 3 | A pale stripe across the boards to the left of the post | [718, 463, 895, 525] | Probably a path; reads as a lighter stripe |
| 4 | A hard-edged dark **rectangle** on the near timber's left face | [172, 213, 295, 450] | DECORATION: a pasted patch with straight edges, not where a hand or boot would wear |
| 5 | Big, stepped, hard-edged dark blocks across the near timber's right face, from the top of the frame to the bottom | [376, 0, 670, 720] | DECORATION: rectilinear, full height, and they look like a shadow-map error, not grime. The worst mark of the set |
| 6 | The whole near timber is darker overall | [0, 0, 720, 720] | Neutral |

**Strength: overdone and the wrong kind on the near timber (4, 5); about right on the floor (1, 2)**, though the pale
patch's squares are too regular.

## 5. gallery_close: **B** has the marks (probably)

| # | Mark (in B) | Box | Caused / decoration |
|---|---|---|---|
| 1 | Soot round the right-hand sconce on the upper wall, spreading sideways under the ledge above it (a "T" shape) | [988, 36, 1096, 200] | CAUSED, and the most physical soot in the set (it rises and spreads) |
| 2 | Soot round the two sconces on the far lower wall | [1000, 230, 1060, 330], [1140, 260, 1200, 360] | CAUSED |
| 3 | Darker vertical bands either side of the window, running from the ceiling down to the rail | [538, 0, 592, 288], [682, 0, 742, 288] | DECORATION: full-height streaks that read as stripes, not as hands at a window frame |
| 4 | The gallery handrail's top slightly darker in places | [700, 250, 1280, 450] (along the rail) | CAUSED (hand grime) but invisible by eye |
| 5 | Pale pools under the chairs on the floor below | [1100, 560, 1280, 720] | CAUSED (the same chair pools as the entrance) |
| 6 | **Missing:** no worn path along the gallery boards next to the rail, where everyone walks | – | – |

**Strength: too faint**, except the sconce soot. The gallery floor, the obvious place for a worn walking line, shows nothing.

## Overall

**The three most convincing marks**
1. **The scuffed pools under the chairs** (picture [790, 560, 1000, 690]; entrance [560, 465, 730, 545]). They are exactly
   where chairs scrape and feet rest, and they are the only floor wear a viewer would notice unprompted.
2. **The grime band at the foot of the bar, with a paler worn patch a step back where men stand** (bar_floor
   [992, 427, 1280, 702]; also entrance and picture). It tells a story: the bar is where people stand.
3. **The soot spreading under the ledge above the gallery sconce** (gallery_close [988, 36, 1096, 200]). It is the one soot
   mark that behaves like smoke.

**The three least convincing marks**
1. **The stepped, hard-edged dark blocks on the near timber in bar_floor** ([376, 0, 670, 720], and the rectangle at
   [172, 213, 295, 450]). They look like a shadow or texture bug, not age.
2. **The full-height dark bands flanking the gallery window** ([538, 0, 592, 288], [682, 0, 742, 288]). Stripes in a place
   nobody touches.
3. **The soot column that runs below the stair_close sconce** ([940, 140, 1020, 360]). Soot doesn't fall, so the mark
   reads as a dark rectangle. More generally, the soot dulls each lamp's halo and the lamps just look dimmer.

**What's missing:** the hand marks are barely there. The stair's newel and handrail, the gallery rail and the bar's top
edge show at most a few levels of change. These are exactly where a viewer looks for "lived in", and they are invisible
at this distance and light. The gallery floor has no walking path.

**Are the worn images closer to the painting?** Only slightly, and not everywhere. The painting's lived-in feel comes from
warm, glowing sconces, a floor with a soft lighter trodden zone towards the bar, and clutter and people. The floor marks
(chair pools, the standing patch at the bar) push the right way and add the unevenness the painting's floor has. But the
soot works against the painting: its sconces bloom warm and clean, and the soot dulls exactly those halos. In four of the
five views an untrained viewer would not tell the two images apart without flipping between them. In the fifth
(bar_floor) the most obvious difference is an artefact.

**Recommendations**
- Make the floor wear about 1.5–2× stronger and give it softer, less square edges.
- Make the hand polish (newel, rail tops, the bar's front edge) clearly visible.
- Keep soot above the lamp only, spreading under ledges, and keep it off the halo itself.
- Remove the full-height rectangles on the near timber and beside the window.
