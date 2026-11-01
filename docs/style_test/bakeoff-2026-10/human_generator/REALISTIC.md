# Realistic men in the game (#522): a look at a possible change of art style

Sean (2026-11-01): "I was wanting to see what a more realistic looking character would look like for a
possible full art style change: keep working on the bold cowboy with proper hair and facial hair,
and also make another face that would fit the scene." **Sheet: `real_sheet.jpg`**: the saloon by
lamplight and the street at 14:00, close and across the room, golden hour, and the faces: the
realistic cowboy, a realistic rancher and the painted bold cowboy beside them. Game renders under
lavapipe (no real GPU); the game's own lights, 1280x720 internal.

## The two men (Studio `tools/humgen/hg_real.py`; their files only in the Studio's store)

- **`hg_real_cowboy`**, the bold cowboy as a real man:
  - Human Generator's body with his face fitted to the bold cowboy's proportions (`face_fit.py`);
  - its "Slicked Back Side Part" hair as hair cards (swept back, as his; it has no thick, wavy,
    collar-length style that isn't a modern cut);
  - the mutton-chops (its moustache, sideburns and cheek lines) and brows as its see-through haircaps, eyelashes;
  - its dress shirt in off-white, its tie in black, its chinos in dark brown, its pirate boots.
    It has no waistcoat or hat.
- **`hg_real_rancher`**, a second man of my own for the street:
  - Human Generator's Jack, aged 58, heavier and sun-reddened;
  - salt-and-pepper hair as cards and a full grey-brown beard;
  - its "On the road" outfit (flannel overshirt, T-shirt, jeans) recoloured to brown, drab and
    dark wool; its pirate boots.

Each surface is baked from Human Generator's own materials: colour (no light in it), a tangent-space
normal map (pores, wrinkles, cloth weave) and roughness. Hair, beard, brows and lashes are colour
with alpha. Under the cards and caps, the hair and beard are also painted onto the skin, so the
scalp isn't bare between cards. Fitted to the 17 bones as before. ~80-88k triangles each, about
5 minutes a build, $0.

## How the game draws them

**`src/bodies/shaders/realistic_person.gdshader`** (art's folder, used only by these test men):
- Godot's own physically based light (Burley diffuse, GGX specular);
- colour, normal and roughness maps; hair cut by alpha; a little backlight through ears and hair.

The body pieces carry no tangents, so the normal map's frame is made per pixel from screen-space
derivatives (Schueler's cotangent frame).

**Which men get it:** a man's report lists shapes under `"realistic"`, and `PeopleBodies._realistic_material`
builds their materials. `HumanBody` uses them (2 lines), and the wound loop skips them (2 lines).
Every other man is drawn as before; `test_bodies` passes (37 of 37).

**What a realistic look doesn't have yet:**
- wounds, blood and the wound openings (the people shader cuts them, this one doesn't);
- talking faces (Human Generator's FACS shapes would map to our 20 expressions);
- skinned fingers;
- subsurface light in the skin;
- the frame cost (not measured).

The rest of the world is still the painted, squared look, so a style change would be the whole
game's art, not only its people.

## Is it Human Generator, or the game? (`blender_vs_game.jpg`)

The same two men rendered in Blender as Human Generator's own showcase images are (Studio
`tools/humgen/hg_render.py`): its strand hair as real curves, its skin with subsurface scattering,
its own materials and 4K textures, Cycles, a three-light studio, about a minute a render. Beside
them, their faces in the game.

- **Human Generator is fine:** in Blender the rancher looks like its website.
- **What my conversion did wrong:** in the game his grey beard and brows came out near-black and
  heavy. The brows were painted onto the skin with thick strands under its brow cap, and the beard
  cap was baked dark. The cowboy's brows have the same fault. Fixable in `hg_real.py`.
- **What the game's rendering costs:**
  - strand hair becomes cards and caps;
  - no subsurface light in the skin;
  - the saloon's warm lamps turn faces orange and the street's light leaves them dark;
  - 1280x720 with hard pixels.

A realistic style would mean the game's lighting and render settings reworked for it, not only
its people.
