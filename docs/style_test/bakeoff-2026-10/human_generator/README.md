# The character bake-off, route C: one Human Generator man (#522)

Sean bought Human Generator Commercial ($128, his own money; #518) and put 4.0.29 and its
content packs on the Studio's private release `humgen-4.0.29`. He OK'd running its add-on code
in the session (2026-11-01). The painted Studio look stays; this man is a try beside the bold
cowboy, not a switch. **Sean's verdict (2026-11-01): "unacceptable as a Salt Creek character."**
The diagnosis and one corrected bald head: `DIAGNOSIS.md`, `head_sheet.jpg`.

**Sheets:** `sheet.jpg` (the saloon by lamplight close and across the room, the street at 14:00
close and across, golden hour, the four faces, his face in the baked skin), `faces_saloon.jpg`
(both faces in the saloon, Human Generator left). Game renders under lavapipe (no real GPU).
Remade by `make_sheet.py` from the bridge shots in `build/hgshots/`.

**Where he lives:** only in the private Studio (`Kokanee25/saltcreek-characters`,
`tools/humgen/`, its README): the recipe, our preset numbers and the scripts are in git there;
the add-on, its content and the exported man stay in its git-ignored `store/humgen/` (his licence:
its exported files are never shared). This repo's `.gitignore` keeps `assets/people/hg_*` out:
the man is copied in only to take shots. To put him in a checkout: Studio `tools/humgen/fetch.sh`,
then `hg_man.py --man=hg_bold_cowboy --game=<this checkout> --install`, then `godot --headless --import`.

## What was made

`hg_bold_cowboy`, to the bold cowboy's brief: a weathered man of about 40, heavy brows, dark wavy
hair to the collar, mutton-chops, a drooping moustache.
- **Human Generator's own code** built him headless (bpy 5.0.1, `Human.from_preset`) from our
  preset: its Theo, aged 40, 1.80 m, broader and more muscular, heavier brow ridge, wider jaw,
  hollower cheeks, beard shadow; hair "Medium Side Part" in dark brown; a mutton-chop set made
  of three of its own face-hair systems (moustache, sideburns, the cheek lines between); its
  Extra Outfits pack's Pirate shirt, trousers and boots (the nearest it has to period clothes; its
  tricorn dropped). No hat.
- **Textures** baked by Cycles from its own materials: the skin at 4096 (his head has half of it,
  ~1,000 px for the face against the Studio man's ~350), clothes at 2048, eyes at 1024. The game
  draws no normal maps, so each surface's own shading under an even sky (wrinkles, pores, folds)
  is laid into its colour.
- **Haircap only, painted onto the skin:** the game draws no see-through cards, and 4.0.29's
  "haircap only" makes no cap for scalp hair without density groups, so every visible hair system
  was turned into thin tubes and baked lit onto the skin where it lies within 1.5 cm of it.
- **On our 17 bones:** his rig's limb bones carried onto our joints, his weights summed into ours,
  the neck re-blended to our joints (the MPFB route's idea, written fresh in the Studio). He stands,
  is drawn smooth (`smooth_texels`, from route A on this branch) and wears his clothes as a "whole" man.

## The numbers

| | Human Generator man | Studio man (bold_cowboy_s3_talking) |
|---|---|---|
| triangles | 91,308 (skin 31,176, eyes 5,504, shirt 33,036, trousers 5,852, boots 15,740) | 34,182 + bandanas, hands |
| textures | 4096² skin (21 MB png) + 3 × 2048² clothes + 1024² eyes | 2048² skin + 3072×2048 head |
| a build | ~11.5 min on 4 cores, $0 (11.3 of them Cycles baking) | $1.60 Rodin + pictures |
| eyes | 1.686 m (our anatomy's 1.655: the face's hitboxes 3 cm low for him, as MPFB's) | |

## What's rough (each fixable, none fixed: one man, then Sean's word)

- **Haircap hair reads as a cap**: flat on the scalp, a lock over the brow, no volume at the collar.
  The bold cowboy's hair is a shape. Real volume would need cards (the art lane's alpha in the skin
  shader) or hair made as a mesh.
- **His face is young and smooth** next to the bold cowboy: Human Generator's detail is in its normal
  maps and subsurface light, which the game doesn't draw; the baked shading brings back only part.
- **Modern-cut clothes**: the pirate shirt's laced front and sash; no period shirt, waistcoat or hat
  in its library.
- **Heavy**: 2.7× the Studio man's triangles (its shirt alone is the Studio man's whole body).
- **Not run**: the works check (poses, ragdoll), the talking face (its FACS shape keys would map to
  our 20 expressions), skinned hands, the frame cost.
- **4.0.29 has no game-export recipes** (the docs read in `human_generator.md` were 4.0.38's): the
  `HG_Export` pack's Godot recipe isn't used; the fit is ours.
