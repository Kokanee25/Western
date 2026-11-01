# MetaHuman experiment: the bold cowboy (2026-11-01)

**Result: BLOCKED at Phase 1.** MetaHuman can't be operated in the cloud workspace, so no MetaHuman
was made, exported, rendered or imported. There are **no MetaHuman renders** in this folder, and
nothing here is a stand-in for one. Phases 2–4 weren't started. This report gives what was checked,
the exact blockers, and the cheapest way to run the real test.

Nothing in the game was changed. This folder and the status entry are the whole diff, on branch
`claude/characters-metahuman-feasibility`.

## 1. The workspace, measured

| Check | Found |
|---|---|
| OS | Ubuntu 24.04.5 LTS, a cloud VM (kernel 6.18). Not Windows. |
| CPU / RAM | 4 cores, 15 GB |
| Disk | 22 GB left in the session's allowance |
| GPU | **None.** No `/dev/dri`, no NVIDIA device or driver. The only Vulkan is lavapipe (software, on the CPU). |
| Display | None. `xvfb-run` only (a virtual screen, no person at it). |
| Network | The policy **refuses every Epic host**: `www.unrealengine.com`, `www.epicgames.com`, `dev.epicgames.com` (the docs), `metahuman.unrealengine.com`, `www.fab.com`. `github.com/EpicGames` gives 403 (Unreal's source is private to Epic-linked GitHub accounts). `download.blender.org` is refused too. |
| Sean's own computer | None linked to this session (Remote Control lists no folders). |
| Installed | Godot 4.7.2 and Blender's `bpy` (via the Studio's `tools/setup.sh`); no Unreal, no Epic launcher. |

## 2. What MetaHuman needs (researched, 2026-11-01)

Epic's documentation host is blocked here, so these facts come from search results that quote it,
plus trade press. They are not verified against the current EULA or docs pages.

- **It runs inside Unreal Editor.** Since UE 5.6 (June 2025) MetaHuman Creator is an editor plugin;
  the web Creator is retired. UE 5.7 (Nov 2025) brought the plugin to Linux and macOS.
- **On Linux, the likeness route is switched off.** In 5.7, Linux and Mac can't create Identity
  assets or use *Conform from Identity*. That is Mesh to MetaHuman, the route that matches a man to
  a head mesh. Only Windows has it. MetaHuman Animator is Windows-only too.
- **It needs Epic's account and cloud.** An Epic Games account is listed as a prerequisite for
  creating a MetaHuman Character. Mesh to MetaHuman's Identity Solve and auto-rig run on Epic's
  servers. The skin textures (2K/4K/8K) are downloaded from Epic before the character can be
  assembled.
- **It needs a real GPU.** The Unreal editor is a GPU app; Epic's sample Linux workstation has an
  RTX 3080 (10 GB). The download is 20+ GB before install, against 22 GB of disk here.
- **It's a hands-on GUI tool.** Shaping a face (sculpting, blending presets, landmark tracking for
  Mesh to MetaHuman) is done in the editor's viewport. I couldn't confirm a scriptable path for
  that, because the docs are blocked.

**Why it can't run here.** Any one of these stops it:
1. no GPU;
2. on Linux, the likeness route (Identity / Mesh to MetaHuman) is disabled;
3. the Epic account sign-in and EULA acceptance are Sean's to do;
4. Epic's hosts are refused.

Opening the network alone wouldn't fix 1–3, so I don't recommend it.

## 3. Export to Blender and Godot (what to expect; not tested)

From community reports, not checked here:
- **The export.** The *DCC Export* assembly gives FBX plus textures. One 5.7.3 report says it
  exports at 2K even with 8K selected.
- **Hair.** Strand grooms don't come over in FBX. You get hair cards at some LODs or Alembic, and
  the hair materials are rebuilt by hand. Several users found the hair missing after import into
  Blender.
- **The face rig.** It is driven by Epic's RigLogic from the man's DNA file, and Godot has no
  RigLogic. For the game, expressions would be baked into blend shapes (as our talking faces already
  are) or into fixed joint poses. A community Blender add-on reads the DNA; it's untried here.
- **The skin.** Unreal's skin material (subsurface profile, animated wrinkle maps) doesn't transfer.
  It would be rebuilt in Godot's StandardMaterial3D (subsurface scattering, transmission) or our
  skin shader.
- **The skeleton.** MetaHuman's skeleton isn't the game's. The game owns the skeleton and hitboxes
  (HumanBody), so the body would be re-skinned or retargeted to ours, as every Studio man is.
- **The detail levels.** MetaHumans ship LOD 0–7. A main character would take a middle LOD and a
  background man a low one, with hair cards in place of strands. The real triangle counts, texture
  memory and draw calls have to be measured once there's a file.

## 4. Licence and cost

- **Licence (Epic, June 2025, as reported):** MetaHumans may be used in other engines, Godot by
  name, as "non-engine products":
  - free while the studio earns under $1M a year; above that, an Unreal seat licence ($1,850 a
    year);
  - characters may be used in AI workflows, but not to train or enhance AI models;
  - **read the current MetaHuman/UE EULA before shipping**; it couldn't be fetched here.
- **Software cost: $0** for Unreal and MetaHuman at Salt Creek's size. Epic's Maya and Houdini
  plugins are optional, and Maya and Houdini cost money; Blender is enough.
- **Hardware:** a Windows PC with a recent NVIDIA or AMD GPU (around RTX 3070 or better is
  comfortable; not verified against Epic's page).
- **Spent on this experiment:** $0.

## 5. Evaluation (Phase 5)

| Criterion | Existing (`bold_cowboy_s3_talking`, Rodin + Studio) | MetaHuman test |
|---|---|---|
| Facial realism | Painted-illustration look by design (DESIGN.md §4), not realism | Not tested |
| Resemblance to approved art | Approved by Sean (2026-10-14; RECIPE.md §5) | Not tested |
| Skin and eye quality | Painted texture (head 3072×2048); wet eyes, no pores | Not tested |
| Facial hair quality | Painted into the head texture | Not tested |
| Clothing quality | Layered outfit exists (`bold_cowboy_layered`, 55k tris) | Not in scope yet |
| Animation compatibility | The game's own skeleton, ragdoll, 27 face blend shapes | Not tested (RigLogic and skeleton need conversion, §3) |
| Godot rendering quality | In the game now | Not tested |
| Performance cost | 49.5k tris, 1 head + 1 body texture set, 4.0 MB glb | Not measured |
| Repeatability for NPCs | Recipe + Studio, ~$1.60 of Rodin a man, ~a session each | Expected free per man, but by hand in the editor on a Windows PC |

## 6. Recommendation: INVESTIGATE FURTHER, only on a Windows PC, and only if the art target is changing

Not ADOPT: nothing was tested. Not REJECT: the blocker is this workspace, not MetaHuman.

**The art direction.** This brief's target (Red Dead-level realism) differs from DESIGN.md §4
(painted illustration, Sean 2026-10-16). Issue #547 (realistic Human Generator men) and #526 ("an
art style change is being tried") suggest it's moving. If realism is the new target, §4 needs
Sean's word, so every lane works to the same picture.

**The simplest way to run the real test** (about an evening of Sean's time, $0):
1. **Install, on a Windows PC with an NVIDIA/AMD GPU:** the Epic Games Launcher, then Unreal Engine
   5.7. Sign in, accept the EULA, and enable the MetaHuman Creator plugin.
2. **Make the likeness from our own head, not the painting.** Run Mesh to MetaHuman on the bold
   cowboy's Rodin head: a mesh with the approved portrait's proportions, which is what this route
   expects. Claude can prepare it as an FBX/OBJ here, neutral expression, front-facing. Then pick
   the skin, eyes, brows, moustache and hair in Creator to match `docs/concept/style/portrait-cowboy-*.png`.
3. **Export:** run *DCC Export* at 4K and copy the folder (FBX, textures, DNA) into the Studio's
   git-ignored `store/`. MetaHuman files are licensed, so they don't go in the public game repo.
4. **Back to Claude:** Phases 3–4 run here headless (Blender renders, the Godot test scene, the
   memory and draw-call numbers), against the same references and the existing man.

**Strongest alternatives:**
- **Human Generator (#547)** is already bought and runs headless in Blender here, so it's the one
  route that can be tested today with no new hardware.
- **Character Creator 5 + Headshot 3** is paid (Reallusion lists the bundle at about $329;
  Headshot's AI uses paid points) and Windows-only. Its game-export licence terms need checking
  before buying. Sean weighed it on 2026-10-01 before the Rodin route won.

## Sources

- [MetaHuman 5.7 release notes](https://dev.epicgames.com/documentation/metahuman/metahuman-5-7-release-notes), [MetaHuman 5.7 is now available](https://www.metahuman.com/releases/metahuman-5-7-is-now-available)
- [MetaHuman hardware requirements](https://dev.epicgames.com/documentation/metahuman/hardware-requirements), [UE Linux requirements](https://dev.epicgames.com/documentation/unreal-engine/linux-development-requirements-for-unreal-engine)
- [Mesh to MetaHuman: from mesh](https://dev.epicgames.com/documentation/metahuman/from-mesh), [from template mesh](https://dev.epicgames.com/documentation/metahuman/from-template-mesh), [creating a character](https://dev.epicgames.com/documentation/metahuman/creating-a-character)
- [CG Channel: MetaHumans in Unity or Godot (June 2025)](https://www.cgchannel.com/2025/06/you-can-now-sell-metahumans-or-use-them-in-unity-or-godot/), [Digital Production](https://digitalproduction.com/2025/06/05/metahumans-graduate-ready-for-unity-godot-and-the-fab-cash-register/)
- [DCC export at 2K (UE forums)](https://forums.unrealengine.com/t/mhc-ddc-export-wrong-texture-maps-resolution/2703076), [groom to Blender (UE forums)](https://forums.unrealengine.com/t/how-can-i-export-a-groom-asset-or-a-metahuman-hair-and-import-into-blender-with-textures/2707161), [MetaHuman DNA Importer for Blender](https://blenderartists.org/t/addon-metahuman-dna-importer-for-blender/1640070)
- [Reallusion CC5 pricing](https://www.reallusion.com/plan-and-pricing/individual/perpetual?product=cc), [Headshot 3](https://www.reallusion.com/character-creator/headshot)
