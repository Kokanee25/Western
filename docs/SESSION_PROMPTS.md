SALT CREEK — SESSION PROMPTS (2026-10-21)
==========================================

Keep this file current: a session that changes a step, a brief or a lab updates its prompt here in the same merge.
How to use: one prompt per new session. Start it in the repo named in brackets.
Up to four sessions at once in Phases 2 and 3 (roadmap rule). Every session ends
with its status entry and Current state lines, as CLAUDE.md says.
Repos: Salt Creek = Kokanee25/western. Character Studio = Kokanee25/saltcreek-characters.


------------------------------------------------------------
ANY TIME
------------------------------------------------------------

## Where are we? [Salt Creek]

```
Read docs/ROADMAP.md (the phases, "When the labs start" and ▶ Now) and the last few entries at the end of the newest docs/status/ file. Tell me in plain words: what each lane finished last, what's running or waiting on me, which decisions are mine to make, and what you'd start next. Change nothing.
```

## Adversarial review (a Fable session) [Salt Creek]

```
The refactor and adversarial review from CLAUDE.md. Review the codebase for what's fragile, slow, untested or likely to break, and what has grown messy since the last review (check docs/status/ for when that was). Report first, ranked by risk, with the files and a proposed fix for each. Change nothing until I say which to do.
```


------------------------------------------------------------
CHARACTERS
------------------------------------------------------------

## A new man in the Character Studio [Character Studio]

```
Characters, in the Character Studio. Read this repo's CLAUDE.md and README first. Make a new man: [describe him, or attach his pictures]. Follow the Studio's approved route for every stage, give me the cost before any paid generation, and show me a sheet at each stage for my OK before going on. Freeze him here once I approve.
```

## Bring finished men into the game [Salt Creek]

```
Characters lane, branch claude/characters-studio-<id>. Bring the Character Studio's approved, frozen man [id] into assets/people the way PRs #157–159 did (body, head, hat pieces, bones by name, textures with mipmaps, <id>.json). Check him in the game: geometry, tests/test_bodies.gd, tools/characters/works_check.gd. One PR per man, with a sheet of him in the street at golden hour and in the saloon at night.
```

## 2.1 Stand-ins: outfit and hat swaps [Salt Creek]

```
Characters lane, roadmap 2.1 (generic bad guys). The Studio's men are in (#157–159) and cast as Brody, the Kid and the storekeeper (#160). Give each a couple of outfit and hat swaps so a street of them isn't the same men repeated, within what the Studio's pipeline supports. Give me the cost before any paid generation. Every swap passes works_check.gd. Finish with a line-up sheet for 2.2, my quick OK.
```

## 2.3 Wound paint (after 2.1) [Salt Creek]

```
Characters lane (plus one line of gameplay), branch claude/characters-wound-paint. Roadmap 2.3. Brief: the Wounds section of docs/briefs/damage-pipelines.md. Paint the wound atlas in the men's hand (entry, exit, graze, soak in stages for shirt, vest and trousers, pools on boards and dirt) after a painted target I approve first. wounds.gdshaderinc reads it in place of noise; the soak grows with blood lost (Physiology). Reduced gore stays. Proposed budget ~$3: give me costs before painting. Judge on the two fixed views in the brief, beside the targets, with the blind critic.
```


------------------------------------------------------------
ART
------------------------------------------------------------

## 1.4a The material lab (now) [Salt Creek]

```
Art lane, branch claude/art-material-lab. Roadmap 1.4a, the material lab (runs now, beside Phases 2 and 3 while the rest of Phase 1 stays parked). Read the Material lab section of docs/briefs/building-pipeline.md, docs/briefs/material-lab-timber.md, tools/material_lab.gd, docs/concept/targets/README.md and the texture factory section of docs/LAYOUT.md.

Make the material lab permanent and wider: one material at a time on a test stand (a wall, a post, a deck and steps) under the three lights (golden hour, noon, the lamplit saloon). The game's current woods (the lab's C, Oct 15) are the baseline.

Match the men: the Studio's men (bold_cowboy_s0, old_rancher_s1, young_drifter_s1) are the style reference for every material. Paint with their own textures or source pictures as the reference (update --style=man from the old target 8 sheet to them), set each material's texel density so its detail reads at the same size on screen as their clothes, and keep each wood's lightness and colour inside the range the men measure under the same light. Judge every material with a man standing in front of it, never alone, and ask the blind critic one question about each crop: "Do the man and the wood look like the same painting? What gives it away?"

Test: colour, grain and knots (no repeats between neighbours), plank, board and siding thickness, end grain on every cut end, dirt and splash, sun-greying and weather streaks, paint wear. Give me the cost before any paid painting and stay inside what I approve. Each material that passes goes into the texture factory with its numbers (thickness, texel size, draw calls, texture memory) and a golden view, judged by me on an A/B sheet.

Don't touch gameplay's structure code (boardwalk.gd, member_mesh.gd): list what production needs instead. Wear-down waits for Gate A: write its plan, don't build it.
```

## Phase 1 resumed (when I unpark it) [Salt Creek]

```
Art lane. Phase 1 is unparked (Sean, [date]). Read the Phase 1 rows and the art lines in CLAUDE.md's Current state. Pick up art's paused list now that the men are done, judged with the Studio's men in every render: my pick on the how-square sheet (docs/screenshots/sky/how_square.jpg), the back bar's dark void, the table's flat top, the street all one orange and its canyon end (ask me the hero rocks' size). One merge per fix, the judge and the blind critic each time, costs before paint.
```

## 1.5 Gate A shots [Salt Creek]

```
Art lane, roadmap 1.5, Gate A. Render the two fixed shots (the man at the saloon table, the street at golden hour) with the Studio's men, side by side with their targets in docs/concept/targets/, plus the judge's scores and the blind critic's top three. Give me one sheet to say yes or no on. Change nothing; if I say yes, re-approve the goldens and freeze the look's settings as the row says.
```


------------------------------------------------------------
GAMEPLAY (non-lab steps)
------------------------------------------------------------

## Next gameplay step [Salt Creek]

```
Gameplay lane. Take the next open gameplay step in docs/ROADMAP.md's ▶ Now that no other session is on (check open branches and PRs first). Read its brief, say in one line which step you're taking, and work it to its "done when", one finished, tested merge at a time.
```

## 3.2 Guns: the smoke, then a hit man's behaviour [Salt Creek]

```
Gameplay lane, roadmap 3.2 (guns agreed). The kick is merged (#153). Next, the smoke: pick up claude/gameplay-smoke (simulated puffs, GunSmoke.transmittance(), its six proposed feel ranges), then a hit man's behaviour after the shot (no jolt, no wince; the wound's consequence at a believable speed). Read the gunplay lines in CLAUDE.md's Current state and the 2026-10-18 status entries. Videos with sound in the PR (bridge.py --movie), and tell me exactly what to try.
```

## 3.3 Furniture (after the breakage lab's baseline) [Salt Creek]

```
Gameplay lane, roadmap 3.3 (furniture), built against the breakage lab's baseline (experiments/breakage_lab/). Prompts 03 and 06 as one job, per their notes in docs/prompts/STATUS.md: chairs and tables built as members that break by how they're built, doors that give way, a seated man dropped when his chair goes, men using furniture as cover. Measure every change in the breakage lab against its baseline.
```

## 3.4 Shoves / 3.5 Acts / 3.6 Missions [Salt Creek]

```
Gameplay lane, roadmap [3.4 shoves | 3.5 acts | 3.6 three rough missions]. Read the row and anything it names (DESIGN.md §5 "Story shape" for acts and missions). Write a short brief in docs/briefs/ first if it's bigger than a day, show me the plan, then build it to the row's "done when". The playtest agent plays it blind before I do.
```

## 0.1 Nightlies green [Salt Creek]

```
Gameplay lane, roadmap 0.1: main green and quiet, nightlies green three nights running. Read the last nightly results and the soak and visual check reports, fix what failed (flakes first), and report each night's result until three in a row pass.
```


------------------------------------------------------------
LABS RUNNING NOW (Phase 3)
------------------------------------------------------------
Bodies paragraph for every lab: the Studio's men are in assets/people
(bold_cowboy_s0, old_rancher_s1, young_drifter_s1), already cast as the gang (#160).

## Gunfight lab (3.0) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-gunfight-lab. Build the gunfight lab: the arena and measures for roadmap 3.0. Read the gunfight section of docs/briefs/labs.md, docs/briefs/three-gunmen.md, and experiments/physics_lab/README.md as the pattern.

Bench and baseline only: change nothing about how the game plays. Lab in experiments/gunfight_lab/ with a README, its bridge commands in its own bridge.gd (BridgeLab), outputs in build/, seeded so the same build gives the same numbers.

Scenarios: the street (me at the trough, Brody, Lyle and the Kid round the saloon porch and crates), the saloon inside with lamps lit, and an ambush where they fire first. Each at golden hour and night, revolver and shotgun. A scripted player in three styles: holds one spot, moves cover to cover, pushes hard. Enough runs per setup for steady numbers.

Bodies: the Studio's men (bold_cowboy_s0, old_rancher_s1, young_drifter_s1), one per gunman, plus one set on the old outlaw body so earlier results compare.

Measure: fight length, who hits first, hits per side, time before I'm first hit, near misses a minute, cover changes, flanks and suppression per man, situation changes (cover shot away, lamp hit, dust hiding a man, surrender, flight), longest quiet stretch, how fights end, and what the men cost a frame.

Report: a baseline table, a contact sheet of a typical fight, the five biggest reasons fights aren't 45–90 tense seconds, anything that doesn't work on the new men, and the first fix you'd make (don't make it).
```

## Body lab (3.1b) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-body-lab. Build the body lab, roadmap 3.1b. Read the body section of docs/briefs/labs.md, the src/bodies section of docs/LAYOUT.md, and experiments/physics_lab/README.md (reuse its harness where you can).

Bench and baseline only: change nothing about how the game plays. Don't edit HumanBody, Anatomy or Physiology: the falls session owns HumanBody. Lab in experiments/body_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded.

Scenarios: revolver and shotgun at 5, 15 and 30 m into marked spots (thigh, neck, upper arm, chest, belly, hand); dynamite at 1, 3 and 6 m; then the same wounds treated (tourniquet, packing, the doctor).

Bodies: every scenario on the Studio's men (bold_cowboy_s0, old_rancher_s1, young_drifter_s1), plus one set on outlaw. Check wounds, severing and stumps, and the hat on the rancher and the drifter.

Measure: what each ball's path crosses (artery, bone, organ) against the aim; bleed-out time per artery, untreated and treated; which bones break and what that stops a man doing; limbs lost, from what and where the cut falls; frame time with ten wounded men against the 4 ms people budget. Check against published trauma figures, cited in the README (don't copy their text).

Report: a baseline table, a sheet of the wounds on each man, where the game is furthest from the medicine, anything that doesn't work on the new men, and the first fix you'd make (don't make it).
```

## Breakage lab (3.3a) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-breakage-lab. Build the breakage lab, roadmap 3.3a. Read the breakage section of docs/briefs/labs.md, the src/structures and src/blast sections of docs/LAYOUT.md, Prompts 03 and 06 and their notes in docs/prompts/STATUS.md, and experiments/physics_lab/README.md as the pattern.

Bench and baseline only: change nothing about how the game plays. Lab in experiments/breakage_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded.

Scenarios: a chair, a table, a door, a bottle on the bar, a lamp, a window and the store front wall, each against the revolver at 5 m, the shotgun at 5 m, and dynamite at 1, 3 and 6 m. Add a man dropped onto a table from about a metre (the Studio's men, plus one set on outlaw).

Measure: breaks or holds and where (against the USDA Wood Handbook strengths the frame already uses), pieces and the largest piece, how far debris flies, what catches fire, physics faults (pieces through the floor, jitter, things flung at speed), same seed same result, frame time per blast.

Report: a baseline table, before-and-after sheets per target, what doesn't break that should (and the reverse), and the first fix you'd make (don't make it).
```

## Ragdoll lab: next round of the falls (3.1) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-falls-round<N>. Roadmap 3.1, falls and hits, the next round. Read docs/briefs/fix-the-falls.md, experiments/physics_lab/README.md, the newest results in experiments/physics_lab/results/, and the latest falls entries in docs/status/ to see where the last round stopped.

Re-run the lab on main first, on the Studio's men (--model) and on outlaw: that's this round's baseline. Then the brief's "What's left", one variable family at a time, each measured against the last result. Hit reactions short of a fall: no flinch or wince for a ball that doesn't drop him, but I see he's hit through the wound's consequence at a believable speed (favours a hit leg, gun hand drops with a hit arm, slows with a body hit).

You're the only session changing HumanBody; the other labs only measure. Any change to human_body.gd comes to me as a proposed patch with before-and-after sheets and real-speed footage before merging. Physics within budget with ten men going down (--perf). Videos in the PR, not git.
```

## Lab fixes (after a lab's baseline) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-<lab>-fix-<n>. The [gunfight | body | breakage] lab's baseline is in. Read its README and results, then make the first fix it proposed (or the one I name: [fix]). One change at a time, measured in the lab against the baseline, with the before-and-after numbers in the PR. If it touches HumanBody, check no other session is changing it first. After a gunfight change, give me three fights to play and tell me what to look for.
```


------------------------------------------------------------
FUTURE LABS AND PIPELINES (start when the roadmap row says)
------------------------------------------------------------

## Material lab: wear-down (after Gate A) [Salt Creek]

```
Art lane, branch claude/art-wear-down. Gate A is passed; the woods are locked. Build the material lab's wear-down from its plan (docs/briefs/building-pipeline.md, Material lab): boards worn where people walk (the saloon door, the bar rail, the boardwalk steps), paint gone where hands touch, and every wood at new, a year old and ten years old. Judged with the Studio's men in front of it, on A/B sheets and by the blind critic. Costs before painting.
```

## Building lab: spec trial on the saloon (after Gate A) [Salt Creek]

```
Gameplay lane (structures) with art for the look, branch claude/gameplay-building-spec. Read docs/briefs/building-pipeline.md and docs/concept/saloon-sheet.png. Write the building spec format, then the saloon's spec from the sheet, settling every critique in the brief's table: ask me each conflict (outside stairs, the street balcony, the lot size, the restrooms). Frame it from period references sized by the Wood Handbook. Build it from the spec in an experiment only, changing nothing in the game, and run the brief's checks. Report what the format needs before it's used for real.
```

## Building lab for real: the saloon, then the block (Phase 4, after Gate C) [Salt Creek]

```
Roadmap [4.3 the saloon | 4.4 the block], through the building lab (docs/briefs/building-pipeline.md), using only materials the material lab has approved. Start with the material-lab-timber.md "What production needs" list (rim joists, open steps as members, chamfers into the voxel carving). Build from the spec, pass every check in the brief, judge renders from the sheet's views beside it, and write what went wrong into the recipe.
```

## Breakage paint (4.4a) [Salt Creek]

```
Art lane, branch claude/art-breakage-paint. Roadmap 4.4a. Brief: the Breakage section of docs/briefs/damage-pipelines.md. Per-wood insides, torn, split and charred-break faces for VoxelWorks and the chips, in one material (texture array or atlas, no new draw calls), after a painted target I approve. Judged on the wall scene at golden hour, before and after, with the blind critic. Proposed ~$3: costs before painting.
```

## Fire lab and fire finished (4.4b, before 4.5) [Salt Creek]

```
Gameplay (spread) and art (look), roadmap 4.4b. Build the fire lab in experiments/fire_lab/ on the labs.md pattern: a room, a building, then the block; measure spread speed against published fire-science figures, how smoke fills, and frame time, baseline first. Then finish docs/briefs/fire-look.md: firelight reaching the street, the smoke column (the critic's "flat maroon cut-out"), and the flames redrawn by script in the locked look against docs/concept/livery-fire-painted.png.
```

## Movement lab (4.6, when I record) [Salt Creek]

```
Gameplay lane, roadmap 4.6. My mocap recordings are in assets/mocap/raw/ (shot list docs/MOCAP.md). Build the movement lab in experiments/ on the labs.md pattern, starting from experiments/mocap_walk/: retarget, clean (foot sliding, jitter, loops), and measure walk, run, turn, idle, sit, stand and draw on the Studio's men, with procedural breathing, aim and flinches on top. Baseline first, then fixes one at a time.
```

## People lab (Phase 5, once the memory store exists) [Salt Creek]

```
Gameplay lane, Phase 5. Build the people lab in experiments/people_lab/ on the labs.md pattern: town life over a day, what people see and remember, and what they do the next morning after something happens (a fight, a theft, a kindness). Write its brief first (docs/briefs/people-lab.md) and show me the scenarios before building. Baseline first.
```

## The town (after Gate B, past the demo) [Salt Creek]

```
The town, through the building lab (docs/briefs/building-pipeline.md, The town). Buildings placed on my map (docs/concept/town-map.png, config/town.json) with streets, lots, yards and dressing. Judge it as a place: walks down each street at dawn, noon, golden hour and night, the blind critic's report, and the checks for whole streets (draw calls, frame time, people's routes door to door).
```


------------------------------------------------------------
SIDE EXPERIMENT
------------------------------------------------------------

## Unreal test scene [new private repo saltcreek-unreal-test, with Kokanee25/western added read-only]

```
Build the Salt Creek Unreal test from the brief I've attached (Salt Creek: Unreal Test Scene Brief, exported as Markdown). Save it as BRIEF.md. This session does the export step only: export_street.gd, run on the Salt Creek clone with Godot 4.7.2 headless, writes the five-building block as glTF plus a JSON of each surface's texture and texels per metre. Push it. The Unreal steps run later on my Shadow PC.
```
