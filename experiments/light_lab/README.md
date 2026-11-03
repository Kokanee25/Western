# The light lab (issue #608 part 1: indoor light that knows the building)

Art's lab for `RoomLight` (`src/render/room_light.gd`, dials `config/room_light.tres`,
`RoomLightTuning`). **Off in the game** (`Settings.room_light`); for one run `-- --room-light=on`,
in play the look address `settings.room_light` (the bridge's `set settings.room_light true`), and
every dial is a look address `room.<dial>` (`room.bounce_gain`, `room.ambient_scale`...).

What it does (the class's header has the detail):

1. **Bounce lights from every lamp**: three rays from each lit lamp (down, up, the nearest wall in
   the building's axes); a soft, shadowless spot where each lands, facing into the room, its energy
   the lamp's by the engine's own falloff times the surface's lightness, its colour the lamp's
   times the wood's (its texture averaged once). Under 90 degrees, so it never lights the surface
   it comes off (that surface has the lamp's direct light). Near ones merged, the room's strongest
   24 kept; they follow the flicker. A lamp moved, put out or smashed re-casts its rays (looked at
   every 0.2 s, six lamps a tick).
2. **Each room's own fill**: the building's interior probe at night dark amber and at
   `ambient_scale` of what it was, times the share of its lamps still lit (DayCycle reads the
   probe's `room_light_scale` meta).
3. **Openings let light in**: the door, the front windows and every hole a break makes in a wall
   get a soft spot just inside, sized to the opening: moonlight by night (MoonWindows' numbers,
   whose spots stand down while it's on) and skylight by day. A hole: `Events.member_broken`
   names the member, its box says which wall and where, and a grid of rays through that patch says
   how much is open (again 2.5 s later, with the rubble down). Only that patch; nothing rebuilt.
4. **Haze**: the room's fog volume thickens with every shot (`haze_per_shot`) and blast inside
   and clears with a half-life of a minute; the lamps' pools show in it.

## Running it

```sh
# before / after / off-again at the four views, one load (the variant waits for RoomLight):
xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- --out=DIR \
    --only=saloon_night,saloon_back_wall_night,saloon_toward_door_night \
    --variants=res://experiments/light_lab/room_on.json,res://experiments/light_lab/room_off.json
# the films (bridge commands rl_*, this folder's bridge.gd):
experiments/light_lab/films.sh OUTDIR
```

Bridge commands: `rl_where`, `rl_cam` (a free camera in the saloon's own space), `rl_lamps`,
`rl_carry INDEX LX LY LZ S`, `rl_knock INDEX`, `rl_blast LX LY LZ [FUSE]`, `rl_state`.

## Results

See `results/` (each round's sheet, numbers and the cheap judge's verdict).
