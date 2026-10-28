class_name LoadRecord
extends RefCounted
## What StructuralAnalysis.advance reads of a member, copied off it on the main thread
## (more-cores step 8): the analysis works on these, not the member, so it can run on a worker
## that touches no Node. Each number is worked out by the member's own methods, the same
## expressions the analysis used to call as it went, so it comes out the same to the bit. A
## structure keeps one per member and copies again only what's changed since (Structure.mark_dirty,
## the dirty contract), and all of them for an analysis from the top.

var member_id: StringName
## The structure's record round it was taken in (Structure.load_record).
var taken_in := -1
var weight := 0.0
var extra_load := 0.0
var supported_by: Array[StringName] = []
var support_points := {}
var grounded := false
var upright := false
var origin := Vector3.ZERO
## Checked in compression (a post, stud, cripple): its capacity and what governs it.
var compression := false
var c_capacity := 0.0
var c_mode := &"compression"
## Checked in bending (a joist, board, beam, rafter...): its capacity over a span, the joint's when
## it rests on one support.
var bending := false
var b_capacity := 0.0
## Where it's weakest along it: `weak_given` (a hole or carved notch), else wherever's asked.
var weak_given := false
var weak_t := 0.0
## A lying member's geometry (StructuralAnalysis._geometry, its own copy: the analysis adds its
## support groups to it as it goes).
var geo := {}


## Copied (again) from `m` as it stands now.
func take(m: StructureMember, tuning: TimberTuning, structure: Structure) -> void:
	member_id = m.member_id
	weight = m.weight(tuning)
	extra_load = m.extra_load
	supported_by = m.supported_by.duplicate()
	support_points = m.support_points.duplicate()
	grounded = m.grounded
	upright = m.is_upright()
	origin = m.transform.origin
	compression = m.kind in StructuralAnalysis.COMPRESSION_KINDS
	bending = m.kind in StructuralAnalysis.BENDING_KINDS
	if m.voxels != null:
		weak_given = m.voxel_section.x < 1.0
	else:
		weak_given = not m.holes.is_empty()
	weak_t = m.weakest_t(0.0) if weak_given else 0.0
	if compression:
		var w := tuning.wood(m.wood)
		var dims := m.cross_section()
		var b: float = minf(dims.x, dims.y)
		var h: float = maxf(dims.x, dims.y)
		var keep := m.section_left(tuning)
		var crush: float = w.compression * b * h * keep
		var k := tuning.braced_buckling_factor if m.kind in StructuralAnalysis.BRACED_KINDS else tuning.free_buckling_factor
		var length := m.length()
		var inertia := h * b * b * b / 12.0
		var euler: float = PI * PI * float(w.stiffness) * inertia * keep / pow(k * length, 2.0)
		c_capacity = minf(crush, euler)
		c_mode = &"compression" if crush <= euler else &"buckling"
	if bending:
		var w := tuning.wood(m.wood)
		var dims := m.cross_section()
		b_capacity = float(w.bending) * dims.x * dims.y * dims.y / 6.0 * m.section_left(tuning)
	geo = StructuralAnalysis.geometry_of(m, structure).duplicate() if not upright else {}


## Where along it it's weakest: its notch, else `default` (StructureMember.weakest_t).
func weakest(default := 0.0) -> float:
	return weak_t if weak_given else default
