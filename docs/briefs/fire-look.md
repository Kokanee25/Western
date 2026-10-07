# Brief: how fire looks

Sean, 2026-10-06: the fire "looks pretty rough" (gameplay session, with the filter off: pale cream
teardrop blobs pasted over the wall, the colour washed out, little smoke), then "how should we make
really good looking fire?" Kept in the art session (Sean: "sounds good"), after the sun rays,
mountains and lettering merge.

## The target

`docs/concept/livery-fire.png`: the livery burning at dusk, the bucket line from the trough.
What the painting does:

- **Flames are shapes, not glows.** Tall licking tongues in clear bands: a near-white yellow core
  low down, orange through the body, deep red at the tips. They're drawn as solid colour, in
  the painting's squares, and they keep their hue; nothing goes cream. They pour out of
  openings (doors, the loft, gaps in the walls) and run up the framing. The fire's top edge is
  ragged and lifts away into separate licks.
- **The building burns from inside its own boards.** Edges glow orange where the wood is going.
  Charred members are near-black squares with orange seams. The frame shows through as dark
  timbers against the flames behind it.
- **Smoke is a big dark column**, warm grey-brown to near-black, lit orange from beneath by the
  fire and purple-grey at the top against the dusk sky. It's soft-edged, in big heaps, and leans
  with the wind.
- **Sparks and embers** rise far above the fire in single bright squares, scattered thinly.
- **The fire lights the world.** Every surface facing it goes orange: the ground, the
  people's fronts, the fence, the troughs. The water in the puddles reflects it. That light is
  most of the picture's drama.
- **Debris:** burning boards falling at angles out of the frame.

## What we have (2026-10-06)

- `FireSystem` (gameplay's): member temperatures, ignition, char, collapse. It's sound and stays.
- `FireFX` (`src/fire/fire_fx.gd`, gameplay's: where flames spawn, how many, the fire lights).
  - Flames are additive billboard sprites (`src/fire/flame.gdshader`, mine). Additive goes
    cream wherever two overlap, the first fault Sean saw.
  - Smoke is a few particle puffs a member.
- `char_overlay.gdshader` (mine): hashed noise per texel; reads as speckle, not as char.
- Grid smoke is coming (`SmokeField`, gameplay's: half-metre cells, a FogVolume with a Texture3D
  density). Its look is mine.

## The plan, in order (each step judged before the next)

1. **Flames as painted flipbooks.** A sprite sheet of tongues drawn square by square in the
   painting's three bands (`tools/textures/draw_flames.py`, like the boards and letters: no
   image model, so every frame is clean). Four to six frames a loop, two or three tongue shapes,
   drawn alpha-blended (not additive), unshaded, their colour as drawn. Faded by the fire's heat
   from small licks to tall tongues. Gameplay's `fire_fx.gd` spawns them: ask for the size and
   count by heat, flames from openings and the members' tops.
2. **Burning boards.** The char overlay redrawn: whole squares going brown, then black with orange
   seams along the grain; the burning front glowing (emission) where the char meets sound wood.
   The member keeps its drawn texture underneath.
3. **Smoke.** The grid smoke's fog shader: albedo from density (warm grey-brown), lifted orange
   near the fire (from the fire's lights), gold on its sun side at golden hour, darker and
   bluer at the top. Big soft heaps, no particles needed for the body. A few painted puffs at
   the column's edge if the fog reads too smooth.
4. **Embers.** A few dozen single bright squares rising and drifting with the smoke's wind,
   fading orange to red.
5. **Firelight.** The fire lights' colour and flicker (a slow wander, not a strobe), their reach
   scaled by how much is burning. Wet ground or puddles are a later look.

## How it's judged

- A fixed view: the livery (or the store) burning at dusk from the trough, as the painting
  stands. Added to `tools/screenshots.gd`, judged side by side with the painting.
- The blind critic on the pair. Its top three go in the status entry.
- In motion: a 10-second pan with `tools/pan_frames.gd`. Flames should loop without strobing.
- Cost: the fire scene stays within its frame budget (fire and effects 2.0 ms). The flipbooks
  must cost no more than today's sprites.

## Who does what

- **Art (this session):** the shaders, the sprite sheets, the char, the smoke's look, the light's
  colour, the view and the judging.
- **Gameplay:** `fire_fx.gd`'s spawning (where, how many, how big by heat), the smoke grid, the
  fire lights' count and placement, anything in `FireSystem`. Asked for, never edited without
  saying so.
