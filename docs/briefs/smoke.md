# Smoke that knows the buildings (gameplay session, 2026-10-06)

**Sean:** "Can we have realistic smoke that will sit under the overhang of the building then roll
out and start going up in the air?" Yes.

## Goal

Smoke from a fire behaves as smoke does round buildings: it rises, meets a roof or a porch's
overhang and spreads along its underside, rolls out at the edge and climbs, and the wind leans
the column over. Inside, a room fills from the ceiling down, and the smoke pours out of the top
of the doorway and out of broken windows. Today's fire smoke is particles drifting straight up,
through roofs.

## How

- **The grid (gameplay, `src/fire/` + the native plugin).** A box of cells round each fire,
  0.5 m a side, from the ground to a few metres over its roof. A cell holding a member (a roof,
  a floor, a wall, glass not yet broken) blocks smoke; doorways, broken windows and burnt-away
  boards don't. Each step: the burning members put smoke and heat into their cells; hot smoke
  rises into the cell above while there's room in it (a cell holds so much), so it fills a room
  from the ceiling down; smoke under a ceiling spreads sideways faster (the ceiling jet), so it
  reaches the edge, finds open air above and goes up; cells open to the sky drift with the wind;
  smoke thins with time, faster in the open. Stepped 15 times a second in Rust (`SmokeGrid`,
  `smoke.rs`): a few thousand cells in well under a millisecond. The members are drawn into the
  grid when it's made and again as they burn away.
- **Drawing it (the art session's to judge and own).** First version: one `FogVolume` per fire
  with the grid's density uploaded as a 3D texture (`FogMaterial.density_texture`), so Godot's
  volumetric fog draws it, lit by the sun and the fire's lights. The art session may prefer
  painted puffs that follow the grid's flow; the grid gives either.
- **Numbers** in `FireTuning` (config/fire.tres): how fast it rises, how much a cell holds, the
  ceiling spread, how fast it thins, the wind.

## Later (not this job)

Smoke that blocks sight (Senses) and chokes (Physiology), so men leave a smoky room and smoke is
cover; gun smoke on the same grid indoors.

## Done when

- A board burning under a porch roof: smoke gathers under the roof, reaches its edge and rises
  past it; little goes straight up through the roof. A test says so.
- A burning room: it fills from the ceiling down, and smoke leaves by the top of its doorway.
  A test says so.
- In the street, the telegraph's front alight: stills of the smoke under its porch, rolling out,
  climbing; sent to Sean and to the art session.
- Within the frame budget's fire share (2.0 ms) on the bench's fire scene.
- No plugin (the web build): the old particle smoke, as now.

## Judged by

Sean's eye in the stills and in a build; the tests; the bench.
