# The doctor's office: the blind critic, 2026-11-10

Judged from the eight pairs only (target left, game right). Paint and furniture/props are left out
as asked; where their absence hides a judgement, it says so. Crop boxes are in pixels of the pair
image (1810x506); the game's half starts at x ~905.

## Pair by pair (the building's form)

| Pair | Grade | Why |
|---|---|---|
| front | **CLOSE** | Right type: gable-front cottage, sign board under an attic window, full-width porch on four posts, door between two big windows; but the windows are bare holes with no sash, the door stands open so you see straight through the house, the porch roof reads as open framing, and no chimney shows. |
| side_yard | **CLOSE** | The long side with its row of windows, side door, picket fence and porch read right; one stub chimney (target: two tall brick ones), roof a rusty red against the target's dark shingle, the porch ends in boxy step blocks that read as lumber piles. |
| rear | **DIFFERENT** | Target is a low one-storey L (a rear ell with its own gable, a low deck and two steps, gutters and a stovepipe); the game is a tall, narrow gable end that reads a storey and a half, raised high with an outside stair and railing to a hooded door, and a ladder up the gable to a loft door. No ell. |
| front_office | **DIFFERENT** | Target: one bright office, a door at the side into the dispensary, the street windows in view; game: a dim room with exposed posts and a brace, looking straight down a long central corridor through the house, a floating board hatch on the left wall, a red-orange glitch panel at the right edge and two bare light glints on the walls. |
| surgery | **CLOSE** | The best interior: two windows side by side on one wall, a door on the side wall, sun patches on the floor. The game's windows are wider, lower and plate-glass (no sash bars), with a board between them that looks like a shutter hung indoors; board-and-batten walls; ceiling unseen. |
| dispensary | **DIFFERENT** (view blocked) | An open door fills the right half of the frame at point-blank; what's left is a dark wall with a small high window. Target is a long narrow room with a lit doorway at the far end. The missing shelving also hides whether that window would clash with floor-to-ceiling shelves. |
| sick_room | **DIFFERENT** | Two-thirds of the frame is black; one wall lit orange with a square window off-centre; the lit wall's edge slants as if leaning or the camera rolled. Target: a lamp-lit room, the window centred between two beds, an open door to the next room. The missing lamp hides the night-light judgement. |
| quarters | **DIFFERENT** (view blocked) | The camera is pressed against an open door slab (two-thirds of the frame) and a dark wall with a window; none of the target's room shows: the glazed back door, the brick chimney breast, the doorway to the bedroom. |

Exterior wood (grey weathered lap siding at the front, warm streaky boards at the rear) reads as
believable bare wood; the interior walnut is very dark, which makes the light problem below worse.

## The five biggest differences (ranked)

1. **Interiors are near black: no daylight fills the rooms.** The targets are bright, with soft
   bounce from every window; the game's rooms are caves except where direct sun lands, and the
   sick room is two-thirds black. The dark walnut plays a part (pale paint will help), but even the
   lit surgery has an unlit ceiling and black corners.
   Evidence: sick_room (1380,0,1810,506); front_office (905,0,1690,506); surgery (1600,0,1810,506).
   Cheapest fix: raise the indoor ambient/bounce (room fill or SSIL strength, sky light through
   the openings) for the judge renders; re-judge once the pale interior paint is in.
2. **Three of five interior cameras are blocked by doors or walls**, so the rooms' shapes can't be
   judged at all.
   Evidence: quarters (1260,0,1810,506); dispensary (1375,0,1810,506); sick_room (1010,0,1380,400)
   (the slanted wall edge).
   Cheapest fix: move each view's camera to the target's position and eye height, and close the
   doors or swing them away from the camera, before the next round.
3. **The rear is the wrong building: tall and raised, no ell.** The game's back gable reads a
   storey and a half, with an outside stair, a hooded landing and a ladder to a loft door; the
   target is a low one-storey L, its floor a step or two off the ground.
   Evidence: rear (1208,79,1530,383); stair and ladder (1233,122,1389,383).
   Cheapest fix: lower the floor to ~0.4 m (a low deck, two steps), drop the gable ladder and the
   hood, and add the rear ell (or a lean-to) with its own gable.
4. **Windows and doors are empty holes.** No sash bars, frames or visible glass on the front and
   side; the front door stands open so you see through the whole house to daylight. With no
   paint, this is what makes the front read as a shed.
   Evidence: front (1220,235,1500,335); side_yard (1170,220,1330,300).
   Cheapest fix: give the window part 2-over-2 sash bars and a casing (it will carry the green
   trim later), glass that catches the sky, and the front door shut by default.
5. **Roof line: chimneys and the porch roof.** The target has two tall brick chimneys (front and
   rear of the ridge) and a shingled shed roof on the porch tucked under the sign; the game has
   one thin stub chimney mid-ridge and a porch roof that reads as bare rafters from the street.
   The red tin-coloured main roof against the target's dark shingle is the next thing you see.
   Evidence: front porch roof (1165,195,1565,235); side_yard chimney (1285,115,1320,155).
   Cheapest fix: a second chimney, both brick, wider and taller; board or shingle the porch roof;
   a dark weathered-shingle roof material.

Also noticed: in front_office a red-orange square-patterned plane fills the right edge
(1690,0,1810,506), like a broken texture or a near object in the camera; bare point-light glints
float on the walls with no lamp under them (front_office (1205,205,1230,230), dispensary
(1465,180,1495,210)); the front porch has steps in the middle plus step blocks at both corners
where the target has one run of steps at the end onto the boardwalk.
