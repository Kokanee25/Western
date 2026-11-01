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

## Round 2 (#547): steps 1 to 3

Sheets in `round2/` (renders only; made by `make_round2_sheet.py` from `real_shots.py`'s game
shots: the men in the saloon at 21:30 and the street at 14:00, faces at 0.9 m and half figures at
2.2 m, and their Blender renders by Studio `hg_render.py`).

**Step 1, the conversion's faults** (`round2/step1_rancher.jpg`; Studio `hg_real.py`, `hg_render.py`):
- No beard or brows painted on the skin any more; only the scalp's hair under the hair cards.
- Strand colours measured in his Blender render: masks of his hair, beard and brows (flat
  renders), the strands lit alone, his skin's base colour. Each strand's lit colour over his
  skin's, times the skin's base colour, is the base colour a strand texture needs beside the same
  skin. The rancher's cards now match it to 0.005: hair 0.28, beard 0.30, brows 0.21 sRGB (round 1:
  hair 0.42 picked by hand, beard 0.24, brows 0.22).
- Round 1's near-black beard and brows were the paint under the caps, not the caps' colour.
- Blender's view (AgX) compresses his very bright skin, so there his hair looks lighter than its
  measure: in Blender's frame the hair is 0.60 of the skin's brightness, in the game's street shot
  about 0.55. What's left of "too dark" is the game's light on faces (step 4), and solid cards
  (step 3).

**Step 2, the cowboy remade with Human Generator's own face** (`hg_real_cowboy2`, `round2/step2_cowboy.jpg`):
- Its Julius's face (the most rugged of its men) with the sliders moved to his brief: a squarer
  jaw and chin, heavier brow, leaner cheeks, age 42, deep wrinkles. No landmark warp.
- Its Medium Side Part cut to the collar, heavier brows, the mutton-chops, a measured dark brown.
- Found: its face sliders move a face only millimetres (jaw_width from -0.56 to -1.0 moves 2.5 mm
  at most), so three slider sets rendered alike; its face is mostly its base mesh, skin and age.
  He reads younger and softer than the brief in Blender, and darker and rounder in the game.
- In Blender his trousers render tan, though their recoloured base colour (what the game gets) is
  dark brown: its trouser material colours them by more than that input. Not chased.

**Step 3, the game drawing them better, people only** (`round2/step3_pairs.jpg`, one pair a
change, each shot in the same moment by the lab's `real_off`; `experiments/realistic_men/bridge.gd`):
- **Soft hair edges:** `realistic_hair.gdshader` draws each card's near-solid core (alpha over 0.6,
  writing depth, casting shadows), and `realistic_hair_fringe.gdshader` (its next pass) blends the
  thin strands round it, writing no depth. Not alpha to coverage: the game draws no MSAA. The hair
  reads fuller, and the brows and the beard's edge softer.
- **Strand highlight:** Kajiya-Kay with Scheuermann's two shifted highlights (a white one and one in
  the hair's colour), along the strand's direction from the card's UVs. Full on scalp hair, a third
  on beard and brows: at full, the rancher's grey beard went white.
- **Soft skin:** the diffuse light wrapped past the terminator per channel, red furthest (Green,
  GPU Gems 1 ch. 16), and a trace of light through him (Barré-Brisebois and Bouchard, GDC 2011).
  Two fixes: the first wrap (0.42 red) and a through-light at round 1's 0.15 laid a red patch across
  the face against the sun; now 0.2/0.08/0.05 and 0.02, a faint warm edge where the sun meets the
  face.
- **More cards:** not needed. Human Generator's "high" density reads full once the fringe is drawn.
- Each change can be left out: `-- --real-off=fringe+highlight+soft`, or live by the bridge's
  `real_off`. `test_bodies` holds the switches. Skin and cloth use their own `light()` now
  (`realistic_light.gdshaderinc`: GGX shine as Godot's, Lambert where it isn't soft).

**What's still between the game and Blender** (step 4 is art's ground; ask Sean first):
- The light on faces: the saloon's lamps turn them orange, and the street leaves them dark against
  a bright day.
- No tone curve like Blender's.
- 1280x720.

## Round 3 (#547): the cowboy's hat and hair, groomed by us

Sean, after round 2: "the hair is just not cowboy hair, not the facial hair". Human Generator's hair
library is modern (fades, side parts, trimmed beards) and it has no western hat, so round 3 makes
both ourselves, on the cowboy only (`hg_real_cowboy3`: round 2's face and clothes). Sheet
**`round3/round3_cowboy.jpg`**:
- top row, round 3: his Blender render (front and his left three-quarter), the game (saloon at
  21:30, street at 14:00), his Blender full figure;
- middle row: the painted bold cowboy (his portrait, then the game);
- bottom row: round 2's cowboy, cut from `round2/step2_cowboy.jpg`.

**What was made** (Studio `tools/humgen/groom.py`, `strand_atlas.py`, its README "Round 3"):
- **Hair groomed by script.** Blender's hair node assets aren't in the headless bpy 5.0 module, so
  the grooming operators are our own, in numpy on the strands' points:
  - roots are sampled on his skin where Human Generator's own face-hair density groups say
    (`fh_mustache_*`, `fh_sideburns_high`), and for the scalp near its own scalp hair's roots;
  - each strand is grown along a comb rule per region, lifted near the root, drooped under
    gravity and kept off the skin;
  - then clumped, frizzed and waved.

  The same strands are drawn as Blender hair curves (Principled Hair BSDF) for his render and as
  hair cards for the game: a ribbon per clump along its mean strand, two or three crossed, textured
  by a strand atlas drawn by code and coloured from his render's measure.
  - **Walrus moustache**: 6,000 strands, 2.4-3 cm, the ends half as long again, drooping over the
    lip past the mouth's corners.
  - **Mutton-chops**: 8,000 strands, bushy, down the cheeks to the jaw angle; the chin and under
    the mouth shaved.
  - **Period cut**: 45,000 strands, to the collar behind, shorter over the ears, unkempt (frizz,
    a slow wave), dark brown with a quarter of the strands grey.
  - His own brows and lashes kept.
- **A felt hat by script** (`groom.felt_hat`): the opening fitted to the slice of his head where
  the band sits (221 x 171 mm with an 8 mm hair gap); a 11.5 cm crown with a centre crease and a
  front pinch; a 7.5 cm brim curled up at the sides; a leather band with ten brass studs. Felt with
  its nap's mottle and a fine bump, baked to the game's colour, normal and roughness maps like the
  clothes. Inside the crown the hair is held flat, and cards wholly under it are dropped. The game
  can knock it off like any hat (`HAT_SHAPES`).
- In the game: 105.6k triangles in all (hat 13.9k, beard cards 15.0k, hair cards 8.9k; Human
  Generator's "high" hair cards were about 8k). The frame cost is step 5's.

**Faults met and fixed on the way:**
- Felt sheen made the hat read tan in Blender and near-black in the game; the sheen is off now
  and the felt's colour carries it.
- At high melanin, Blender's hair model shows only its white highlight, so dark hair read ash
  grey; now less melanin with more redness.
- The atlas's grey strands at a fixed brightness pushed the dark strands to flat grey; grey is
  now relative to the measured colour.
- Narrow cards with gathered tips drew the moustache as a comb's teeth in the game; now wider
  cards, tips that don't gather, and denser strands.

**Honest result:**
- In Blender he now reads as the bold cowboy's type: hat, walrus moustache, chops, hair under
  the brim.
- In the game the shapes carry over, but the chops read thinner and darker than in Blender: their
  cards lie along the cheek, so from the front they're near edge-on. Fanning them to ±40° helped a
  little; that was the second fix, so it stops there.
- The hat reads tan under Blender's bright studio and dark brown in the game, darkest in the
  street's shade. Like the faces, that is the game's light (step 4), not the hat's colour, which
  both draw from the same felt.
- His face is still Human Generator's Julius (younger and softer than the brief); round 3 didn't
  touch it.
- $0 spent.
