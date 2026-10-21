# Brief: painted damage pipelines (Sean, 2026-10-20)

Wounds and breakage get new pipelines; fire already has one and needs finishing. All three only
change how existing systems look: the simulation underneath stays as it is. When each starts is in
`docs/ROADMAP.md` ("When the labs start").

## At a glance

| | Wounds | Breakage | Fire |
| --- | --- | --- | --- |
| Drawn today by | `wounds.gdshaderinc`: a ragged rim from random noise, soaked cloth, blood further out | `VoxelWorks`: every carved or torn face is one "fresh wood" material | `fire-look.md`'s pipeline: flipbook flames, char, smoke column, embers |
| What's new | A painted wound atlas in the man's hand | Painted insides, torn and split faces, per wood | Nothing new: finish it, then repaint into the locked look |
| Painted by | The texture factory (`paint_textures.py --style=man`, `reduce.py`) | The texture factory (`paint_woods.py`) | `draw_flames.py` by script; the factory for char |
| Hooks into | `wounds.gdshaderinc`, the blood pool, `Physiology` | `VoxelWorks`, the chips, `char_overlay.gdshader` | `FireFX`, `SmokeColumn`, the fire lights |
| Lane | Characters (paint), gameplay (soak growth) | Art | Art |

## The shared recipe

1. **Paint the target first.** `paint_reference.py` repaints a game render in the man's hand (a
   man with a wound, the store front shot up). Sean approves the target before anything else is
   painted.
2. **Paint the material.** The texture factory paints it (on GitHub Actions; OpenRouter is blocked
   from the workspace) and `reduce.py` cuts it smooth at the man's texel density. Every call prints
   its cost.
3. **Hook it in through data.** A texture and a few numbers in `config/`, read by the system that
   already exists. No new systems.
4. **Judge it.** A fixed view with a golden image, side by side with the target, and the blind
   critic's top three.
5. **Write the recipe.** One page saying how the next one is made (a knife wound, a new wood), as
   `tools/characters/RECIPE.md` does for men.

## Wounds (characters, plus a line of gameplay; proposed budget ~$3)

| Piece | What it shows |
| --- | --- |
| Entry | A small dark hole with a bruised rim |
| Exit | A larger torn opening, a ragged rim of flesh |
| Graze | A torn furrow across skin or cloth |
| Soak | Blood through cloth in stages: fresh red spreading, then dark, then dried brown; white shirt, dark vest, trousers |
| Pool | Blood on floorboards and on dirt |

- `wounds.gdshaderinc` samples the atlas for the rim and the soak round each opening, instead of
  `wound_hash` noise. Still up to 8 openings a body.
- The soak grows with the blood lost from that wound, which `Physiology` already tracks (gameplay's
  one change).
- The blood pool (`BloodPool` in `human_body.gd`) takes the painted pool.
- Reduced gore stays: the closed, dark soaked wound, painted too.

Judged on two fixed views beside painted targets: a man at the table shot in the shoulder; a man on
the street at golden hour shot in the chest and thigh. Not in this round: severed limbs and the
insides (`BodyInterior`).

## Breakage (art; proposed budget ~$3)

| Piece, per wood | What it shows |
| --- | --- |
| Inside | Fresh pale wood, grain running along the member |
| Torn | Splintered fibres where wood was ripped out round a hole |
| Split | A crack along the grain |
| Charred break | Black outside, brown then pale further in |

- `VoxelWorks` gives carved faces the member's own wood's inside and torn faces its torn piece, in
  place of the one fresh-wood material. Painted woods keep their paint on the outside only.
- The thrown chips take the same insides.
- Where `char_overlay.gdshader` has charred a member, a break through it shows the charred break.
- **Performance:** the wall scene's render CPU is already over budget (6.1–6.4 ms against 4.0). The
  new pieces go into one material as a texture array or atlas, not a material per wood.

Judged on the wall scene at golden hour, before and after, beside a painted target of the shot-up
front. Not in this round: brick, stone and glass.

## Fire (art; $0)

`docs/briefs/fire-look.md` is already the pipeline, and most of it is built (flipbook flames, char,
`SmokeColumn`, embers, judged on `livery_fire_dusk`). Left: the firelight reaching the street (a
stronger try was reverted 2026-10-11 for crushing the deep shadows) and the smoke the critic still
calls a flat maroon cut-out. After Gate A: redraw the flames in the painted-illustration look
against `docs/concept/livery-fire-painted.png`. The frames stay drawn by script: an image model's
frames don't match each other, and flames flicker between mismatched frames.
