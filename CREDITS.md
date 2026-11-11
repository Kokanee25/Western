# Credits

Everything used under a licence (code, models, sounds, fonts, data) is credited here. Each session
adds its own lines.

## People (the characters session)

- **MakeHuman** base mesh and targets, v1.2.0 (makehumancommunity/makehuman): CC0. Fetched by
  `tools/blender/fetch_makehuman.py` into `build/`; the men in `assets/people/` are made from them.
  Also its face pose units, default skeleton and weights (`poseunits/`, `rigs/`; CC0, fetched by
  `tools/faces/mh_units.py --fetch`): the talking men's mouths, lids and expressions.
- **MediaPipe Face Landmarker** (Google, `face_landmarker.task`): Apache-2.0. Fetched into
  `build/mediapipe/` at run time and used by the tools only (the portrait factory's fit,
  `tools/paint/align.py`); not in the repo or the game.
- **Blender** (`bpy` 5.0.1): GPL, a tool run headless; nothing of it ships.
- **Mantaflow** (Apache-2.0, inside Blender's `bpy` 4.5.3): the fire simulation the flame
  flipbooks are baked from (`tools/textures/fire_sim/`); only its output, our sheets in
  `assets/textures/fire/`, is in the game.
- **NumPy** (BSD-3), **SciPy** (BSD-3), **Pillow** (MIT-CMU), **scikit-image** (BSD-3): Python libraries the tools use.
- The portrait factory's reference pictures (`docs/concept/style/factory/`): made by Sean in ChatGPT.
- **Hyper3D Rodin** Gen-2.5 (Deemos), through **fal.ai**: paid API generations, output owned by the
  customer with commercial use allowed (as understood; the terms pages couldn't be opened from the
  workspace, shipped on that basis with Sean's OK, 2026-10-21). The meshes and paint of
  `bold_cowboy_s0`, `old_rancher_s1`, `young_drifter_s1`, `hothead_lyle_s1`, `barkeep_s1`, `widow_s1` and
  `sean_s2`, `doctor_s1`, `colter_rider_s1` (and the earlier Rodin men); the horse's shape and paint
  (`assets/creatures/horse/`, 2026-10-24: from Sean's pictures and views drawn from them by Nano
  Banana Pro in the Character Studio, Sean's OK, the game's #340); the saloon's deer head
  (`assets/props/models/deer_head*`, 2026-10-24) and the steer skull (`steer_skull*`, from pictures drawn by
  OpenAI's GPT-5.4 image model through OpenRouter, output owned by the customer). The train's engine and tender paint
  (`assets/train/*_paint.png`, `experiments/train_lab/paint/real_dirty.png`, 2026-11-02: Nano Banana
  Pro, Google's Gemini 3 Pro Image through OpenRouter, repainting the game's own clay layout in the
  Character Studio, Sean's OK, the game's #569/#577), baked onto the models by our own code.
- `bold_cowboy_s0`, `old_rancher_s1`, `young_drifter_s1`, `hothead_lyle_s1`: made by the Character Studio
  (Kokanee25/saltcreek-characters) from pictures by Sean (ChatGPT) and views drawn from them by
  Google's Gemini 3 Pro Image (through OpenRouter); fitted, rigged and written by the Studio's code.
- `barkeep_s1`, `widow_s1`, `sean_s2`, `doctor_s1`, `colter_rider_s1`: made by the Character Studio the same way, their pictures by Sean
  (ChatGPT) or OpenAI's GPT-5.4 Image 2 (through OpenRouter), `sean_s2` from Sean's own photo.

## Materials (the art session)

- **Scanned woods for the material library** (#701; `assets/textures/scans/<id>/`, fetched on GitHub
  by `.github/workflows/scans.yml`, cut to 2048 albedo / 1024 normal / 512 roughness JPEGs): CC0 1.0,
  no credit asked; credited all the same.
  - **Poly Haven** (polyhaven.com, CC0): `black_walnut_veneer_02` (https://polyhaven.com/a/black_walnut_veneer_02), `oak_veneer_01` (https://polyhaven.com/a/oak_veneer_01), `red_oak_veneer` (https://polyhaven.com/a/red_oak_veneer), `sapele_veneer` (https://polyhaven.com/a/sapele_veneer).
  - **ambientCG** (ambientcg.com, by Lennart Demes, CC0): `Wood009` (https://ambientcg.com/view?id=Wood009), `Wood014` (https://ambientcg.com/view?id=Wood014), `Wood015` (https://ambientcg.com/view?id=Wood015), `Wood047` (https://ambientcg.com/view?id=Wood047), `Wood048` (https://ambientcg.com/view?id=Wood048), `Wood050` (https://ambientcg.com/view?id=Wood050), `Wood051` (https://ambientcg.com/view?id=Wood051), `Wood058` (https://ambientcg.com/view?id=Wood058), `Wood059` (https://ambientcg.com/view?id=Wood059), `Wood061` (https://ambientcg.com/view?id=Wood061), `Wood062` (https://ambientcg.com/view?id=Wood062), `Wood063` (https://ambientcg.com/view?id=Wood063), `Wood081` (https://ambientcg.com/view?id=Wood081), `Wood086` (https://ambientcg.com/view?id=Wood086), `Wood087` (https://ambientcg.com/view?id=Wood087).

## Prop references (the prop lab)

- **Period references for the doctor's props** (#788; `experiments/prop_lab/refs/doctor/`, reference
  only, not in the game): ten photographs and engravings from Wikimedia Commons under public domain,
  CC BY 2.0, CC BY 4.0 (Wellcome Collection, Auckland Museum) and CC BY-SA 3.0/4.0, each file's author,
  source page and licence in that folder's README.md. One (the 1880 Stohlmann, Pfarre & Co.
  catalogue engraving) is tagged "no known copyright restrictions": a US book of 1880, public domain
  by age.

## Motion (the gameplay session)

- **CMU Graphics Lab Motion Capture Database** (mocap.cs.cmu.edu): "free for use in research and
  commercial projects worldwide". The data used in this project was obtained from
  mocap.cs.cmu.edu; the database was created with funding from NSF EIA-0196217. In B. Hahne's 2010
  BVH conversion (cgspeed.com; no further restrictions), fetched by
  `experiments/mocap_walk/fetch.sh` into `build/cmu/`. The walk (35_01) and run (35_17) are
  retargeted onto our rig in `experiments/mocap_walk/clips/` (an experiment, off by default). Since #539 also the library clips in `assets/animations/library/` (a walk, a run, walking
  backwards and sideways, a creeping walk, standing: which take each is in its `manifest.json`),
  by `tools/blender/library_motion.py`, fetched by `tools/blender/fetch_library.sh`.
- **Uthana text-to-motion** (`uthana/text-to-motion-diffusion-v2`, run on Replicate under its
  terms by the Studio, 2026-10-24): the card cheat's four clips in `assets/animations/` (a walk,
  a kick, a draw, standing over a man) were generated from text for this project and retargeted
  onto our rig by `tools/blender/retarget_motion.py`; the generated takes are kept in the Studio
  (`motions/card_cheat/`). Since #539 also the gun moves (a walk and a run with the revolver in
  hand, an aim stance, a reload, a stagger; the Studio's `motions/gun_moves/`, $7.50), in
  `assets/animations/library/` by `tools/blender/library_motion.py`.
- **Quaternius, Universal Animation Library** (UAL1, the free Standard set; quaternius.com): CC0
  1.0. **Kay Lousberg, KayKit Character Animations 1.1** (Rig_Medium; www.kaylousberg.com): CC0
  1.0. Retargeted onto our rig by `tools/blender/library_motion.py` (issue #529) into
  `assets/animations/library/` (which clip from which pack: its `manifest.json`); the packs
  themselves are fetched into `build/` by `tools/blender/fetch_library.sh` (from GitHub mirrors of
  the itch.io downloads, J-Ponzo/gltf-universal-animation-library and
  GeorgeQLe/assets-kaykit-3d-characters, each with the pack's CC0 licence text) and not kept here.

## Sounds (the gameplay session)

The train's recorded sounds (train sound 2, #586): cut from these Wikimedia Commons recordings
by `experiments/train_lab/recordings.py` (which part of which file each sound is: its
`recordings.json`) into `assets/audio/train/`; trimmed, filtered and set in level, otherwise
unchanged. The brakes' squeal and grind are still synthesised (`src/audio/train_synth.gd`).

- **"South Australian Railways Garratt 406 starts off"** by SCHolar44, CC0 1.0
  (https://commons.wikimedia.org/wiki/File:South_Australian_Railways_Garratt_406_starts_off.ogg):
  the long and mid exhaust beats, rolling, the engine standing.
- **"Train sounds from Iowa"** by Glaneur de sons, CC BY 3.0
  (https://creativecommons.org/licenses/by/3.0;
  https://commons.wikimedia.org/wiki/File:Train_sounds_from_Iowa_-_Glaneur_de_sons.ogg): the
  chime whistle, the bell, the rail joints, the couplers.
- **"Steam locomotive S06-018, steam release"** by Work With Sounds / Technical Museum of Slovenia,
  CC BY 4.0 (https://creativecommons.org/licenses/by/4.0;
  https://commons.wikimedia.org/wiki/File:WWS_SteamlocomotiveS06-018Steamrelease.ogg): the
  cylinder cocks and the safety valve.

- The dynamite's recorded layers (issue #596; `assets/audio/blast/`, `BlastSounds`): only
  Freesound sounds under **Creative Commons 0**, fetched through Freesound's API by
  `tools/sounds/fetch.py` (each file's id, title, author and page in `assets/audio/blast/sets.json`;
  listed here as they come in, though CC0 asks for no credit). The Sonniss GDC bundles are not
  used while this repo is public: their licence forbids publishing the files as sound effects.
  Freesound's API terms (https://freesound.org/help/tos_api/, read 2026-11-03): the API only, no
  scraping; the fetched pool is an intermediate copy, kept encrypted and deleted once the sets are
  chosen; only the files the game uses are in this repo, under their own CC0.

The dynamite's recordings (#596), Freesound, cut by `experiments/train_lab/recordings.py
--manifest=experiments/sound_lab/blast_recordings.json` (trimmed, filtered, levelled):

- **m-150-020927-24-bit** by boilingsand, CC0 (https://freesound.org/s/49711/): downloaded by hand by Sean from Freesound's CC0-only search (#599). Cut into `assets/audio/blast/s1/crack`.
- **dynamite explosion in the mountain** by felixblume, CC0 (https://freesound.org/s/251401/): downloaded by hand by Sean from Freesound's CC0-only search (#599). Cut into `assets/audio/blast/s1/boom`, `s1/sub`, `s1/roll`.


The fiddler's sound experiment (#790, the sound lab; `experiments/sound_lab/fiddle/`); nothing
of it is in the game yet:

- **VSCO 2 Community Edition** by Versilian Studios (Sam Gossner; the solo violin "LLVln" set),
  CC0 1.0 (https://github.com/sgossner/VSCO-2-CE, commit 4403009; its Readme asks for a credit
  and that the samples aren't sold as they are). The solo violin's sustains (`Arco Vib`) and short
  strokes (`spic`), fetched into `build/` by `experiments/sound_lab/fiddle/fetch.sh`; render A and
  the hybrid C are made from them.
- **"Sallie Gooden"** played by A. C. "Eck" Robertson, recorded for Victor in 1922 (Victor 18956),
  public domain in the US (a sound recording published before 1923: its federal protection under
  the Music Modernization Act ended on 1 January 2022; the tune is traditional). From the Internet
  Archive (https://archive.org/details/ACEckRobertsonSallieGoodenVictor18956). The experiment's
  reference only, to compare against: a 20 s excerpt in its results, not in the game.
- The room's crowd under the fiddle heard from outside: the cinematic's generated take
  `sfx_room.mp3` (ElevenLabs sound effects v2 through fal, 2026-10-26; branch `claude/cinematic-saloon`),
  cut into a steady bed by `experiments/sound_lab/fiddle/crowd_bed.py`; a lab stand-in, not in the game.
- **"The Soldier's Joy"**, traditional, as printed in O'Neill's *Music of Ireland* (1903), No. 1642,
  public domain; the ABC transcription from music21's corpus (`oneills1850`; music21 is BSD-3).
- **"Arkansas Traveller"**, traditional, as printed in *Ryan's Mammoth Collection* (1883), public domain;
  the ABC transcription from music21's corpus (`ryansMammoth`), turned into note data by
  `experiments/sound_lab/fiddle/abc_tune.py`.
- **"Devil's Dream"** and **"Turkey in the Straw"** (printed as "Old Zip Coon"), traditional, as printed in
  *Ryan's Mammoth Collection* (1883), public domain; ABC from music21's corpus (`ryansMammoth`).
- **"Oh! Susanna"** (Stephen Foster, 1848), **"Buffalo Gals"** (1844), **"Sailor's Hornpipe"** (the College
  Hornpipe, 18th century) and **"Red River Valley"** (1870s-1890s): public-domain melodies, written out
  for Salt Creek in `experiments/sound_lab/fiddle/tunes/` (our own ABC; the notes of the first three
  checked against the Nottingham Music Database's versions, GPL, which aren't copied or shipped).
