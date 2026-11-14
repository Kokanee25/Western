class_name RoomLightTuning
extends Resource
## RoomLight's dials (issue #608 part 1, structure-aware indoor light): the lamps' bounce, each
## room's own fill, the openings' sky and the room's haze. config/room_light.tres; the lab's
## variants (experiments/light_lab/) try others.

@export_group("Bounce")
## A bounce light's energy over what its patch is given back (the lamp's energy x the patch's
## share x the surface's lightness): over 1 is art's (the painting's warm rooms), 1 the physics.
@export var bounce_gain := 1.5
## The bounce's half angle (degrees): under 90, so it never lights the surface it comes off (that
## surface has the lamp's own light: no double counting).
@export var bounce_spread := 78.0
## Its reach, over the lamp's range (never under bounce_reach_min metres): short, so a floor's
## bounce stays low and the roof stays dark (round 1's 0.9 lit the roof as bright as the floor).
@export var bounce_reach := 0.6
@export var bounce_reach_min := 2.0
## Off the surface into the room (metres): far enough that a wall beside a floor bounce isn't
## burnt by it (trial 1's red blotches at 0.08; the lab's results/2026-11-03_r1/).
@export var bounce_offset := 0.25
@export var bounce_attenuation := 0.5
@export var bounce_angle_attenuation := 1.2
## Bounces light the haze this much (the lamps' own light does the pools).
@export var bounce_haze := 0.0
## Bounces of different lamps nearer than this (and facing the same way) are one light.
@export var bounce_merge := 1.2
## The most bounce lights a room keeps (the strongest).
@export var max_bounces_per_room := 24
## Weaker than this, no light.
@export var min_bounce_energy := 0.01
## How much of the surface's own hue the bounce takes (0 the lamp's colour, 1 lamp x surface: the
## saloon's red-brown walls bounced a hot red at 1).
@export var tint := 0.0
## A surface with no texture to read (props, the ground): this colour.
@export var default_albedo := Color(0.42, 0.3, 0.2)

@export_group("Room fill")
## The room's flat fill at night with the bounces on, over what it was (they do its work now).
@export var ambient_scale := 0.5
## And its colour: dark amber, not the flat gold.
@export var ambient_colour := Color(0.95, 0.6, 0.32)
## The fill follows the room's lamps: put half out and the night fill halves.
@export var ambient_follows_lamps := true

@export_group("Openings")
## Sky through an opening by day: its energy for a metre square at full daylight, and colour.
@export var opening_day_energy := 0.35
@export var opening_day_colour := Color(0.82, 0.88, 1.0)
## By night the moon's (DayCycleConfig moon_window_*), for a metre square over a front window's.
@export var opening_night_gain := 1.0
## The most a single opening lets in, over a metre square's.
@export var opening_max_area := 2.5
## Smaller holes than this (m2) let in nothing worth a light.
@export var hole_min_area := 0.03
## The grid a broken wall is probed on (metres), and the most cells a region is probed in.
@export var hole_cell := 0.12
@export var hole_max_cells := 144
## Rays a physics tick, at most, probing holes.
@export var hole_rays_per_tick := 48
## Wait this long after a break before probing (the pieces fly clear).
@export var hole_delay := 0.4
## And once more this long after that, with the rubble down.
@export var hole_settle := 2.5

@export_group("Daylight (a spec building's rooms, #829)")
## A building that names its openings and its light (a spec's `light`, RoomLight's `daylight`
## rooms) has its windows light the room, not the wall under them: each window's sky spot sits at
## day_window_height of the window up, aimed day_window_tilt degrees down from level, across the
## room (its reach the distance to the far wall times day_window_reach_over, between the two
## limits: the engine's range window, (1 - (d/reach)^4)^2, has a light at a fifth by 0.87 of its
## reach, so the far wall needs about twice its distance), falling off with distance (the window
## side bright, the far side dim). The sky through a
## window is a big soft source low in the wall: its light runs across a room, not down it.
@export var day_window_height := 0.6
@export var day_window_tilt := 18.0
## Or, over 0, aimed at the floor this share of the way to the far wall (a high window steeper, a
## low one flatter: the sky comes down through a window onto the floor in front of it), its tilt
## between day_window_tilt_min and day_window_tilt_max.
@export var day_window_aim := 0.6
## A daylight room's windows cast shadows by day (the desk's on the wall beside it; and a partition stops
## a window's light, so it lights its own room, not the next: judge round 1 of #829, "no shadows,
## nothing shows where the light comes from"). Doors don't (they stand open or shut).
@export var day_window_shadows := true
## And their colour: the sky's is opening_day_colour (pale blue: the rooms read a blue-grey wash
## to the judge, round 1); a daylight room's windows take this, near white.
@export var day_window_colour := Color(1.0, 0.97, 0.92)
@export var day_window_tilt_min := 12.0
@export var day_window_tilt_max := 50.0
@export var day_window_spread := 62.0
@export var day_window_attenuation := 1.4
@export var day_window_angle_attenuation := 1.5
@export var day_window_reach_over := 2.0
@export var day_window_reach_min := 3.0
@export var day_window_reach_max := 10.0
## The sun through a window: where its rays land (a grid of sun_patch_rays x sun_patch_rays over
## the window, each tested against the sun outside: a porch roof shades it) a soft spot faces
## back into the room off the patch, the light the sunlit floor gives back (instant radiosity's
## virtual point light, as the lamps' bounces). Its energy is the sun's x the window's area seen
## by the sun x the share that gets in x the patch's lightness x sun_patch_gain (1/pi is a
## Lambertian patch's; more is art's).
@export var sun_patch_gain := 2.5
@export var sun_patch_rays := 3
@export var sun_patch_spread := 80.0
@export var sun_patch_reach := 4.5
@export var sun_patch_offset := 0.3
@export var sun_patch_attenuation := 1.0
@export var sun_patch_angle_attenuation := 1.0
## How much of the patch's own hue its bounce takes (0 the sun's colour, 1 sun x surface).
@export var sun_patch_tint := 0.5
## Recast when the sun has moved this much (degrees).
@export var sun_patch_degrees := 0.5

@export_group("Haze")
## Room haze (fog density) a shot fired inside adds, and its half-life in seconds.
@export var haze_per_shot := 0.004
@export var haze_per_blast_kg := 0.04
@export var haze_half_life := 60.0
@export var haze_max := 0.06

@export_group("Refresh")
## How often lamps are looked at for moving or going out (seconds), and how far one must move.
@export var refresh_seconds := 0.2
@export var lamp_moved := 0.06
## Lamps re-cast a physics tick, at most.
@export var lamps_per_tick := 6
