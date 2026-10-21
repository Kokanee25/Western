# Brief: how a charge looks going off (Sean, 2026-10-21)

Sean asked for the explosion's look to be reworked now ("Can you try doing the art right now"),
in the gameplay session that was fixing the blast's damage (`docs/briefs/blast-surfaces.md`).
This is the art lane's ground (effects, how they take light); done here at Sean's request and
handed back to art for judging. No separate lab: the breakage lab draws a blast over time
(`run.py --look=...`, `sheets.py look`).

## The reference

Sean's pick: a road-blasting video on YouTube by @SandeepGodiyal, "Powerful Dynamite Explosion for
constructing Road and Da…", 0:24–0:25 (six phone screenshots in the chat). **The screenshots and
the video are not ours to redistribute and stay out of this repo;** what they show, in our words:

- **No fireball.** The flash is over in a frame or two; after that nothing glows. What reads as
  "explosion" is dust and rock, not flame.
- **A jet, not a ball.** The first thing is a dark, dense column of grit thrown out of the open side
  of the charge (up and away from the rock face it was packed against), narrow at the root.
- **The cloud is the ground.** It's the colour of what was blown apart (tan dirt, grey rock), dark
  and heavy at the root where it's thickest, pale and lit where it billows out on top and the sun
  catches it.
- **It rolls out along the ground.** A low surge of dust spreads sideways from the foot.
- **Dark chunks in arcs.** Rock and clods flung out and falling back, darker than the dust behind
  them, some well beyond the cloud.
- **Slow after fast.** The jet is out in a fraction of a second; the cloud then climbs and spreads
  slowly for many seconds and drifts off on the breeze.

## What's built (`src/effects/blast_cloud.gd`, `BlastCloud`)

`BlastEffects.spawn` makes one `BlastCloud` in place of the old orange light, three impact bursts and
a gun-smoke puff:

- a flash: a light alone, gone in ~0.12 s (hot puffs were tried and dropped); wood it lights catches 1–4 s later;
- dark chunks flung in arcs (count and speed by the cube root of the charge);
- a jet of dust out of the open side (`vent_of`: rays a metre out every way, away from the ground or
  the wall it lay against, leaning up), dark at the root;
- a billow that climbs and pales, lit by the world (the gun smoke's lit puff material);
- a surge along the ground; a fog volume for the body of the cloud;
- the colour from what it blew apart (`dust_of`: dirt, wood, stone); it drifts with the gun smoke's
  wind and is seeded by where it went off. The scorch is darker and wider.

## Rounds (2026-10-21, the breakage lab's look runs: ground, wall and floor, a stick lying on each)

1. First cloud: on the street a narrow near-black column (chimney smoke, not dirt) and black dice
   for chunks; a lit board's whole sheet of flame at 0.05 s read as the fireball the reference
   hasn't got.
2. Wood the blast lights smoulders 1–4 s first (`BlastTuning.ignite_delay`,
   `FireSystem.ignite_after`): the flash is the only light when it goes off. The dust bigger, wider
   and the dirt's colour at the root; chunks smaller and lighter. Now tan, dark at the root,
   spreading, gone by 8 s with the scorch left.
3. A hard dark band at the cloud's foot: not the fog volume nor the surge's one plane (both tried);
   the scorch decal painting the dust (Forward+ decals paint transparent particles). The dust is on
   its own render layer (`Layers.VIS_AIR`) and fades where it meets the ground.

Still off, for the art session: against the store front the dust is a faint haze under the porch
roof; once wood catches, a whole board's sheet of flame stands at once (the fire's look, not the
blast's, `docs/briefs/fire-look.md`); gun smoke near a scorch or blood decal likely takes the same
band (not checked).

## What done looks like, and how it's judged

- In the lab's look sheet (`sheets.py look`), from 0 to 8 s: no orange after the first tenth of a
  second; a jet that leans away from the wall or floor it lay on; the cloud dark below and paler
  above; a surge you can see at the foot; dark chunks against the dust.
- The art session judges it against the reference (the observations above) and the concept
  paintings; the blind critic gets the sheet.
- The frame: the first frame of a blast is already the hitch (`blast-surfaces.md`); the cloud adds
  nothing measurable to it (warm-up covers its materials) and its particles cost under the smoke
  budget while it hangs.

## Open

- Night: the flash lights the street for a blink; whether it should light the cloud from inside.
- Indoors: the cloud fills the room (the fog volume) and should leave by doors and holes (with the
  smoke work, `docs/briefs/smoke.md`).
- Sound and the shake are the gunplay audit's (roadmap 3.2), not this brief's.
