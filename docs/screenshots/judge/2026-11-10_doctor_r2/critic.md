# The doctor's office: the blind critic, round 2, 2026-11-10

I judged only the eight pair images (target left, game right; game half x 905-1810, 506 px tall).
The interiors are very dark: the game halves' mean brightness is 9-23 of 255 (sick room 8.9,
quarters 9.9, surgery 20.0, dispensary 20.6, front office 23.0). I read their form from copies
brightened 4x. Crop boxes below are in the pair image's own pixels.

**What the exclusions hide.** Leaving out paint hides most of the interior light judgement. With
dark walnut on every wall and ceiling there is nothing pale to bounce the window light, so I
can't tell whether the rooms would read right once painted. A test render with a pale placeholder
on the walls and ceiling would settle it. Leaving out furniture hides the dispensary's built-in
shelving, which is that room's whole character. Outside, the missing paint hides the trim's job
(the green casings that outline every opening), so the bare openings look even plainer.

## Grades (the building's form)

| Pair | Grade | Why |
|---|---|---|
| front | **CLOSE** | The gable front, full-width porch, sign board under a gable window, and window, door, window are all in place. But the porch roof reads as a thin flat rack instead of a shingled shed roof, the steps are centred (with extra stepped blocks at both corners) instead of one flight at the right end, the windows have no sashes, and no brick chimneys show. |
| side_yard | **CLOSE** | The long gable body, side windows in a row, picket fences and a door near the back match. The roof is rust-red with a sawtooth edge instead of grey-brown shingles under a trimmed eave, and the game has more side windows (about 5 against the target's 3). |
| rear | **DIFFERENT** | The target is an L-plan: a cross-gabled rear wing with a door, a stovepipe, and a low deck with two steps. The game is a plain gable end with a railed outside stair, a small hood roof, and a ladder up the gable to a loft door, so it reads as a two-storey barn. |
| front_office | **DIFFERENT** | The game has exposed heavy posts and a ceiling beam where the target has a finished beadboard ceiling. It has a hatch-like opening with a shutter in the left wall instead of a cased doorway to the dispensary, and it reads as a long hall rather than a small office. |
| surgery | **CLOSE** | There is a pair of windows on the far wall and a door beside them, as in the target. But the game's windows are oversized single panes with no sashes, the walls are vertical boards instead of smooth painted walls, and there are no casings or baseboards. |
| dispensary | **CLOSE** | It is a narrow galley with a door at the far end. The far wall has a small window beside the door where the target shows an open doorway into a lit room, and the built-in shelves are absent (excluded, but they define the room). |
| sick_room | **DIFFERENT** | The target's room is built around one curtained window centred on the end wall, with a doorway in the side wall. In the game the far wall has two doors and no window. |
| quarters | **CLOSE** | The chimney stack beside the bedroom doorway is in the right place. But it reads as a timber post with blotchy camouflage texture instead of brick courses, and the half-glazed back door isn't visible. |

Totals: 0 SAME, 5 CLOSE, 3 DIFFERENT.

## The five biggest differences a viewer would notice

**1. The rooms are near-black red caves; the target's are bright daylit rooms.**
Evidence: pair_sick_room (920,40,1800,500); pair_quarters (920,0,1800,500); pair_front_office (905,0,1810,506).
Every interior is maroon-black with a milky haze near the windows. Even allowing for unpainted
walls, the floor, which is bare honey pine in every target, is dark glossy red-mahogany in the
game. The view through the windows is flat featureless grey. The surgery's sun patches on the
floor (1230,330,1600,500) are the only thing that reads as daylight.
*Cheapest fix:* make the interior floor a honey or orange pine (the target's floors aren't
painted, so this isn't waiting on paint) and take the red out of the walnut. Raise the interior
exposure or fill until a room's mean brightness is in the target's range. Then re-judge with pale
placeholder walls.

**2. The inside isn't finished: exposed framing and the wrong boarding.**
Evidence: pair_front_office (1200,20,1450,340), the posts and beam; pair_quarters (1240,0,1320,390), the chimney as a post; any wall, e.g. pair_surgery (905,0,1260,420).
The targets have lined rooms: narrow horizontal beadboard or smooth walls, beadboard ceilings with
a cove, cased openings and baseboards. The game shows rough structural posts and beams, and its
walls are wide vertical boards with a huge flame grain (each figure about 20 cm across) that reads
as plywood veneer.
*Cheapest fix:* line the rooms: hide the frame behind a wall lining of narrow horizontal boards,
add a board ceiling, put the grain at a board's real scale, and give the chimney a brick texture.

**3. The rear is a different building.**
Evidence: pair_rear (1230,120,1540,385).
The target is an L-plan with a cross-gabled rear wing, a door onto a low deck with two steps, and
a stovepipe. The game is a plain rectangle whose gable end carries a railed outside stair, a small
hood roof, and a ladder up to a loft door. It reads as a two-storey barn or loft. The rear boards
also band in lighter horizontal stripes across the whole gable (1250,150,1480,300): a tiling tell.
*Cheapest fix:* remove the ladder, the loft door and the railed stair, and put a low deck with two
steps at the rear door. Add the rear wing (a small cross-gabled box) when there's time.

**4. Windows and doors have no joinery.**
Evidence: pair_front (1225,240,1290,330) and (1430,240,1500,330), the windows; pair_front (1340,140,1375,180), the gable window as a blank board; pair_surgery (1280,150,1355,360) and pair_front_office (1505,160,1625,400), the doors.
Outside, the windows are plain dark sheets with no sashes, muntins, sills or casings. The target
has two-over-two sashes and a shop window, each framed by trim. Inside, the doors are flat slabs
in a noisy orange speckle with no panels, no casings and no visible hinges. The target's are
four- or five-panel doors in cased openings.
*Cheapest fix:* one window part (two sashes, a muntin bar, sill and casing) used everywhere, and
one panelled door mesh with a casing, in a plain wood texture.

**5. The porch and roof are wrong in shape and edge.**
Evidence: pair_front (1170,200,1560,400), the porch and steps; pair_front (1180,85,1370,215), the rake; pair_side_yard (1300,120,1520,240), the roof.
The target's porch is a shingled shed roof sloping out from under the sign, over a deck skirted
with vertical boards, with one flight of steps at the right end down to the boardwalk. The game's
porch roof reads as a thin flat rack of rafters with no visible slope, and it has three flights of
steps (one centred, plus stepped blocks at both corners). The main roof is rust-red with a
sawtooth fringe along the rakes and eaves where the target has weathered grey-brown shingles under
a plain fascia. The target's two corbelled brick chimneys are a single thin dark stick in the game.
*Cheapest fix:* pitch the porch roof and give it boards or shingles, keep only the right-end steps
and drop the corner blocks, add a straight fascia or rake board to hide the shingle teeth, recolour
the shingles grey-brown, and make the chimneys brick boxes with a cap.

## Also noted (outside the building)

- The ground is a bare untextured tan plane: no ruts, dirt, grass or boardwalk. pair_front (905,390,1810,506).
- The sky's clouds are flat stepped tones, like a poster, beside the target's photographic sky. That's a long way from the realistic direction. pair_front (905,0,1810,90).
- The front is lit flat blue-grey in shade, so the house reads as one dark mass. pair_front (1190,220,1540,390).
