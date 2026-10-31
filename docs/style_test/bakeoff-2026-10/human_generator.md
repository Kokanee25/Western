# The character bake-off, route C: Human Generator (issue #516) — research only, not bought

Sean, 2026-10-31: "I want human gen, more realistic", and "don't buy it": find the price, the
licence, whether it can run here, and what its hair and clothes would need. Nothing was downloaded
from its shop or run; the add-on's own source and docs (public, GPL) were read.

**Sources.** The add-on's public repo [OliverJPost/HumGen3D](https://github.com/OliverJPost/HumGen3D)
(v4.0.38, last commit 2026-10-17; its `docs/` are the help site's pages), and search excerpts of
[humgen3d.com/pricing](https://humgen3d.com/pricing) and the [licence FAQ](https://help.humgen3d.com/license).
Superhive (ex-BlenderMarket, where it's sold and downloaded) doesn't load from this session's
network, and the full **Asset License** text
([help.humgen3d.com](https://help.humgen3d.com/FAQ/Human+Generator+Asset+License)) wasn't read whole:
read it, or ask support@humgen3d.com, before buying.

## The buy decision

**Price:** lifetime, one user: **Personal $68**, **Commercial $128**
([pricing](https://humgen3d.com/pricing); upgrade later by paying the difference,
[help](https://help.humgen3d.com/upgrade)). Personal doesn't cover commercial games (the docs, below),
so **for Salt Creek it's Commercial, $128.** No team/studio tier found; no paid clothes or hair packs
found (a free "extra outfits" pack). The game-export data (`HG_Export.hgpack`) is included with a
licence, not in the trial.

**Recommendation: don't buy yet.** Run route A first ($2.60–3.00), which answers "is realistic the
direction" for a tenth of the price; buy Human Generator only if realistic wins and A's man falls
short. Reasons:
- **Its men can't live in the public game repo** (below), so they'd sit in the Studio and be pulled
  into the build: a change to how the game is built.
- **Its faces come from one base moved by sliders,** as MPFB's did (MakeHuman's faces were what made
  Sean's verdict "terrible"); its skin, eyes and hair are far better than MakeHuman's, but whether
  its faces have the character Sean wants is the same open question.
- **No period clothes** (its library is modern: office, smart-casual, suits, beachwear). The
  frontier outfits would be made once in its clothing system or Blender (~a day each), the same
  gap MPFB had.
- **It needs three things from Sean** before a session can use it: the purchase and the downloads
  (Superhive is outside this session's network), somewhere private to keep ~2.5 GB of content, and
  his OK to run its add-on code (the MPFB session's auto mode refused a downloaded add-on).

## The licence, point by point

The code and the content are licensed separately. The add-on's **code is GPL-3.0**
([LICENSE](https://github.com/OliverJPost/HumGen3D/blob/main/LICENSE)); its README: "the 3D assets and
textures are included with a purchase on BlenderMarket and come with a royalty free license". The
men you make with it fall under the **Human Generator Asset License**. Its own docs
([Output.md, "Licence of exported characters"](https://github.com/OliverJPost/HumGen3D/blob/main/docs/Process/Output.md)):

> With the commercial licence you can ship them in commercial games and software, as long as
> players can't take the character out and reuse it. The personal licence covers personal,
> educational and portfolio work, not commercial games. With either licence, don't share or sell
> the exported files themselves (the FBX, glTF or texture files), also not modified. glTF files
> carry a line about this licence in their copyright field.

| Question | Answer | Source |
|---|---|---|
| Ship its men in a **sold game** | **Yes, with Commercial** ($128), "as long as players can't take the character out". The pricing page: only refused if extracting them is "a clear feature you offer" (a download button); the FAQ allows sharing "within a closed format like a video game" | Output.md; [pricing](https://humgen3d.com/pricing); [FAQ](https://help.humgen3d.com/license) |
| Keep them in the **public** repo (Western) | **No.** A public repo shares "the exported files themselves" (glb, textures); the FAQ also bars sharing them with anyone without a licence "even if you have customized them". No clause for open-source projects | Output.md; [FAQ](https://help.humgen3d.com/license) |
| Keep them in the **private** Studio repo (`saltcreek-characters`), the game shipping them | **Likely yes, not written down.** Private storage isn't sharing; nothing addresses private repos or CI machines. "Amount of users: 1": Sean is the user; whether a cloud session or a GitHub runner working for him counts is not stated: ask support | [FAQ](https://help.humgen3d.com/license) |
| AI / automated / cloud use | Not stated anywhere found | — |
| Where its base mesh and skin scans come from | Not stated anywhere found (no mention of MakeHuman) | — |

**What "its men live in the Studio" would mean for the game:** `assets/people/` in Western is public,
so a Human Generator man can't be committed there (today every Studio man goes to the game as a PR to
`assets/people/`). The game's CI would fetch those men from the private Studio repo at build time
(a read token as a secret) and the export would carry them inside its `.pck`; local runs without
the token would fall back to the current men. The public build downloads (releases, Pages, the
tour) would then contain them only inside the game, which the licence allows. The game's tests that
load a man would use one that's in the public repo.

## Can it run headless here

**Yes, by its docs**, once the content is here and the code is allowed to run:
- A Python API (`from HumGen3D import Human, ExportSettings`; `Human.from_preset(...)`,
  `human.process.run(settings)`) and a documented background run:
  `blender -b characters.blend --python export_characters.py`, "tested with Blender 5.1 … a dressed
  human with hair cards to glb in about a minute, textures baked included"; "the add-on must be
  enabled in the Blender preferences of the machine"
  ([Python API.md](https://github.com/OliverJPost/HumGen3D/blob/main/docs/Process/Python%20API.md)).
- Blender 4.0 or newer (the add-on's `bl_info`); the Studio's `bpy` 5.0.1 (pip) would need checking
  against its process system, which is tested on 5.1.
- **Its content library** is separate `.hgpack` downloads into an empty folder with ~2.5 GB free,
  set in its preferences ([install](https://help.humgen3d.com/install)). No licence key or online
  activation in the code (the only network code is its updater); the trial is told apart by its
  content pack.
- **The game export is "early access"** in its docs (the Process tab, replacing 4.0's): whether the
  version on sale has it was not confirmed.

**Who downloads, where it's kept:** Sean buys it and downloads the add-on zip and packs from his
Superhive account (or the session's network policy allows `superhivemarket.com`); the ~2.5 GB of
content can't go in git (GitHub rejects files over 100 MB; LFS has quotas): a release asset on the
private Studio repo (2 GB a file, split if needed) or a private bucket, fetched by the session.
The add-on code itself is GPL and could live anywhere. **Sean's OK to run its code** in the session
is needed, or the auto mode refuses it, as it did MPFB's.

## Hair, faces, rig, size

- **Hair** is Blender particle hair, turned into cards on export (Ultra 24,000 / High 12,000 /
  Medium 7,000 / Low 4,500 triangles for the scalp, 10,000–3,500 for a beard), or **"haircap only"**:
  the hair painted on the skin, no cards ([Haircards.md](https://github.com/OliverJPost/HumGen3D/blob/main/docs/Process/Haircards.md);
  "hand-made hair cards will always look better"; long hair doesn't follow the shoulders). Its
  cards are alpha-scissor; the game's skin shader draws no alpha (the art lane's file), so: haircap
  only (works today; short hair and stubble under a hat), or art adds alpha-scissor cards to the
  skin shader behind a flag (the wounds' cut-outs must keep working through it).
- **Godot export:** one `.glb` with a 56-bone humanoid skeleton, baked textures, hair cards and the
  face as blend shapes; tested on Godot 4.7; a free MIT Godot companion plugin
  ([Export to Godot.md](https://github.com/OliverJPost/HumGen3D/blob/main/docs/Process/Export%20to%20Godot.md)).
  For us it would be refitted to the game's 17 bones as the MPFB man was (`mpfb_man.py` did that
  for a 53-bone rig).
- **Faces:** FACS shape keys (ARKit-compatible) and one-click expressions; they come out as static
  blend shapes to be driven in the engine ([Shape Keys.md](https://github.com/OliverJPost/HumGen3D/blob/main/docs/Process/Shape%20Keys.md)):
  `FaceSpeech`/`FaceLife` would map our 20 expressions onto them instead of grafting MakeHuman's face.
- **Size:** the body ~50,500 triangles, ~9,600 at a quarter; up to four LODs
  ([Optimize Meshes.md](https://github.com/OliverJPost/HumGen3D/blob/main/docs/Process/Optimize%20Meshes.md)):
  a man at 1/2 with hair is about the Studio man's 34,000.

## Clothes

The library is modern: office, smart-casual, suits, beach, footwear, recolourable with patterns
([base content](https://www.humgen3d.com/base-content); reviewers call it small). **Nothing western
or 19th-century**, and no pack for it found. Period clothes (collarless shirt, sack coat, waistcoat,
braces, wide-brim hat, boots) would be modelled once in its custom-clothing system or in Blender and
then fit every man; or its men wear the Studio's clothes, which aren't separate garments yet.

## If Sean buys it

Commercial, $128, after support answers the private-repo and cloud-session questions. Then a session
needs: the add-on and its packs where it can fetch them, his OK to run the add-on's code, and the
CI change above (the game's build fetching the men from the Studio). The first test: one man, the
#505 brief (about 40, stubble, a hat; the hat and clothes from the Studio or made once), haircap
only, refitted to the 17 bones and shot beside `bold_cowboy_s3_talking`.
