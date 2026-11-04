class_name TrestleTuning
extends Resource
## The timber viaduct's dials (the trestle lab, #623; docs/briefs/trestle.md). Every number here is
## PROPOSED until Sean has seen it. Values: config/trestle.tres.
##
## A tall framed trestle as American railroads built them through the 1870s-80s: bents of squared
## timber across the line every panel, each bent in stories (posts, an intermediate sill on top of
## the story below, X sway bracing across it), outer posts battered so the bent widens toward the
## ground, longitudinal girts and braces tying bent to bent at every story; on the caps, stringers
## two panels long in two chords a rail, their joints broken; the line's ties and rails on them, a
## guard timber outside each rail. Where the sizes come from (each a typical published size, not a
## design calculation):
##   - posts, sills 12 x 12 in, caps 12 x 14 in, sway and longitudinal braces 3 x 10 in: the NMRA's
##     data sheet D6b3 on framed trestles (compiled from railroad standard plans);
##   - stringers two chords of 8 x 16 in a rail, ties 6 x 8 in, guard timbers 6 x 8 in: the Elgin &
##     Belvidere Electric Railway's 1907 trestle standard (the same sizes run through W. C. Foster,
##     "A Treatise on Wooden Trestle Bridges", 1891, which was not reachable from this session);
##   - bents 10-16 ft apart (16 ft here: the far end of the usual range, for the fewest members);
##     stories split by intermediate sills once a bent passes 16-20 ft (20 ft here).
## The scale is Sean's (#623): Portage-scale, ~71 m high at the middle (the Erie's Portage Viaduct
## over the Genesee, 1852: ~234 ft high, 800-900 ft long, all timber on stone piers), taller than
## the Union Pacific's Dale Creek trestle (1868, ~126 ft high, 650 ft long).

@export_group("The bents")
## Centre to centre of the bents along the line, m (16 ft). The crossing is split into whole panels
## of about this.
@export var bent_spacing := 4.88
## A story's height, post foot to post top, m (20 ft); the bottom story takes what's left over
## (from `min_story` to a story and `min_story`).
@export var story := 6.1
@export var min_story := 2.0
## The outer posts' centres apart at the cap, m (10 ft, a narrow-gauge cap's posts).
@export var top_width := 3.05
## The inner posts' centres from the middle (plumb, under the rails), m.
@export var inner_x := 0.6
## The outer posts lean out this much a metre down (each side): 1.5 in a foot. The bent at the
## bottom of a 66 m one is ~20 m wide.
@export var batter := 0.125
## Plumb post lines every this far out from the inner posts, each from the story where the bent is
## wide enough to have half this beyond it (the wide lower stories carry more posts), m.
@export var post_gap := 3.0
## Posts and intermediate sills (12 x 12 in), caps (12 wide along the line x 14 deep), m.
@export var post := 0.305
@export var sill := Vector2(0.305, 0.305)
@export var cap := Vector2(0.305, 0.356)
## Past the outer posts each end of a cap or sill, m.
@export var overhang := 0.3
## X sway bracing across each story, one brace on each face (3 x 10 in: thickness, width), m.
@export var brace := Vector2(0.076, 0.254)
## Girts bent to bent along the outer post lines at each sill (6 x 8 in: width, depth), m.
@export var girt := Vector2(0.152, 0.203)
## Longitudinal X bracing in each panel and story on the outer post lines (3 x 10 in). Off: girts only.
@export var long_braces := true
## Stone pier under each bent's mud sill: its height out of the ground and how far it's sunk in, m.
@export var pier_above := 0.4
@export var pier_depth := 1.2
## Its footprint past the mud sill each side, m.
@export var pier_margin := 0.4

@export_group("The deck")
## Stringers (8 x 16 in: width, depth), two chords a rail side by side, each two panels long, the
## chords' joints a panel apart ("broken"): lose one bent and half the stringers over it still
## span it, now twice as far.
@export var stringer := Vector2(0.203, 0.406)
@export var stringer_panels := 2
## Guard timbers (6 x 8 in) over the ties' ends, a panel long each, m.
@export var guard := Vector2(0.203, 0.152)
## The guard timbers' centres from the line's middle, m.
@export var guard_x := 0.78

@export_group("The ends")
## The abutments: stone on the rim the end stringers bear on (length along the line, depth), m.
@export var abutment := Vector2(1.5, 1.8)

@export_group("The load")
## The train's weight is put on the rails under its axles every this many physics ticks (and the
## loads worked out again where they changed).
@export var load_every := 3
## Each truck's share of its car's weight is put on two axles this far either side of the truck, m.
@export var axle_half := 0.6
## The engine's and tender's: their axle groups' half lengths (the 2-8-0's driving wheelbase is
## 13 ft: its four pairs at 1.3 m). Others take `axle_half`.
@export var engine_axle_half := 2.0

## A rail with no ties under it for this long under a wheel tears off its spikes and drops (the
## iron can't carry an axle over a hole), m (three ties).
@export var rail_span := 1.8

@export_group("The wreck")
## A falling piece of the viaduct (a bent's tower, a span) breaks up on landing into pieces of at
## most this many members, never every timber (sections, not splinters: #623).
@export var section_members := 24
## A tall piece (a bent's tower over a cut: more than `section_members` members, a story and a
## half high) can't stand on the stubs under it: `fold_after` s after it starts to fall it goes over
## as a unit, across the line (a seeded side), turning about the edge of its foot with `fold` times
## the turn it needs to tip past it, and breaks into sections where it lands. A model of the joints
## at its foot giving unevenly; 0 leaves it to land square and stand (a 60 m stack of sections).
## (Along the line it would lean on the next bent, which stands: a chain of bents is for later.)
@export var fold := 1.3
@export var fold_after := 0.6
