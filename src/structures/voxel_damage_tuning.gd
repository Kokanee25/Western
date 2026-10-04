class_name VoxelDamageTuning
extends Resource
## How members take damage as voxels (config/voxel_damage.tres; docs/DESTRUCTION_BRIEF.md step 2).
## A member is voxelised by the native plugin (addons/saltcreek_native, VoxelMember) the first
## time something hits it; a ball or pellet carves a channel its own size, and the energy it
## spends in the wood plus any muzzle blast it brought tears out more round it (the spall), ragged
## and wider at the exit, thrown as chips. What's left of the section goes to StructuralAnalysis.
## Without the plugin (the web build), holes are drawn by member_holes.gdshader as before.

## Off: every member keeps the old drawn holes, plugin or no plugin.
@export var enabled := true
## About this many cells a metre along each side of a member (a whole number of them per side,
## so the uncarved member is exactly its box). 64: cells ~16 mm, half the texture's squares (31 mm
## at 32 texels a metre), so a bite reads in the game's chunky look; a 25 mm siding board is 2
## cells through. 96 is truer to a pellet's size and reads as specks (docs/destruction/step2).
@export var cells_per_metre := 64.0
## No member's volume bigger than this: a long sill is cut coarser.
@export var max_voxels := 250000
## The channel's radius against the projectile's.
@export var channel_scale := 1.0
## Share of the energy a projectile spends in the wood that tears it out round the channel, and
## share of the muzzle blast (a shotgun's charge at contact arrives as one mass) that does.
@export var spall_share := 0.5
@export var blast_share := 1.0
## Energy to tear out a cubic centimetre, J, by wood: old dry weathered boards split and splinter
## easily, sound framing less, stone hardly. A charge at contact (1,600 J of blast) takes ~130 cm³
## out of a weathered siding board: a hole ~7 cm across through 2.5 cm, split along the grain.
@export var spall_j_per_cm3 := {&"weathered_pine": 12.0, &"painted_ochre": 13.0, &"painted_rust": 13.0,
		&"sign": 13.0, &"floor": 18.0, &"framing": 20.0, &"dark_trim": 22.0, &"stone": 150.0}
@export var default_spall_j_per_cm3 := 18.0
## Wood splits along its grain: the torn-out wood reaches this many times as far along the
## member as across it.
@export var grain_split := 2.5
## The spall's edge (0 a clean cone, 1 very ragged), and how much wider it is at the exit than at
## the entry (wood splinters out of the back).
@export var ragged := 0.6
@export var flare := 0.8
## Splinters joined to the rest by nothing this big or smaller (voxels) go with the spall.
@export var island_max := 48
## Holes within this share of the member's depth of each other along the grain weaken it
## together (wood splits from one to the next).
@export var window_of_depth := 1.0
@export_group("Chips")
## Chips thrown per hit (the biggest lumps of what went), and the most lying about at once (the
## oldest go first).
@export var chips_per_hit := 3
@export var max_chips := 80
## Seconds after it's thrown a chip lies still for good (frozen: no more physics).
@export var chip_settle := 2.5
## Lumps smaller than this many voxels make no chip.
@export var chip_min_voxels := 4
## How fast chips leave, m/s, along the shot (out of the exit) and back out of the entry.
@export var chip_speed := Vector2(1.5, 6.0)
## Colour of fresh-cut wood (the carved faces and chips); stone's.
@export var fresh_wood := Color(0.78, 0.66, 0.48)
@export var fresh_stone := Color(0.62, 0.6, 0.56)


func spall_cost(wood: StringName) -> float:
	return float(spall_j_per_cm3.get(wood, default_spall_j_per_cm3))
