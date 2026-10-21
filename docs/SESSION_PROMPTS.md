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
Characters lane, branch claude/characters-studio-<id>. Bring the Character Studio's approved, frozen man [id] into assets/people the way PRs #157–159 did (body, head, hat pieces, bones by name, textures with mipmaps, <id>.json). Run godot --headless --import and commit every .import file it writes (the .glb.import too), so no other session sees them as changes. Check him in the game: geometry, tests/test_bodies.gd, tools/characters/works_check.gd. One PR per man, with a sheet of him in the street at golden hour and in the saloon at night.
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

## Fire flipbooks (now; moved up by Sean 2026-10-21) [Salt Creek]

```
Art lane, branch claude/art-fire-flipbooks. Read the "next approach" section at the end of docs/briefs/fire-look.md, the src/fire section of docs/LAYOUT.md (FireFX, flame.gdshader, SmokeColumn) and docs/PARTS.md. Put the simulation scripts in tools/textures/fire_sim/ (art's folder) and run Blender headless as tools/blender/ does.

Bake a few flame types from a Blender Mantaflow fire simulation (a small lick, a tongue, a big column), each a looping 64-frame sheet with motion vectors. Write the new flame shader: motion-vector frame blending, a bright core layer that keeps its colour and an alpha-blended tip and smoke layer, soft edges against walls and floors, plus heat haze. Swap it in for the script-drawn tongues behind a setting so I can compare both on livery_fire_dusk and a burning saloon interior. Push the colours toward docs/concept/livery-fire-painted.png now, but leave the final painted pass for after Gate A. Fire's spread and FireFX's spawning are gameplay's: ask for any change there. Measure frame time with a building fully alight. Judge beside the painted target with the blind critic, give me an A/B video, and add the flipbooks to docs/PARTS.md.
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

Built 2026-10-21 (`claude/gameplay-breakage-lab-ksr17d`, merged): the bench, its README and the
baseline (`experiments/breakage_lab/baseline/baseline.md`); blast-surfaces steps 1 and 2 and the
blast's look made in the same branch (below).

## Ground that can be dug, and craters (blast-surfaces step 3) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-dig-ground. Step 3 of docs/briefs/blast-surfaces.md: ground that can be dug, with a blast's crater as its first user. Read that brief (its step 3, its decisions and "Later: digging with a shovel"), the src/world, src/structures and src/blast sections of docs/LAYOUT.md, and the breakage lab's README and baseline (experiments/breakage_lab/). Steps 1 and 2 and the blast's look (docs/briefs/blast-look.md) are merged.

First write its own brief, docs/briefs/dig-ground.md, and stop for my decisions: height field or ground voxels (the choice, its costs in collision, drawing and the frame); how earth comes out at one point and goes down at another, many times over the same spot; what rests in a hole and what walks, falls and rolls into it (the player, the men's feet, ragdolls, a strongbox, a stick of dynamite); nav, bullets glancing off dirt; how the save records it as a difference from the authored town; and the crater's size from the published fits (cube root of the charge). The ground's look (ground.gdshader, the textures, the crater's earth and lip) is the art lane's: say what it needs from them.

Then build it in the brief's order, one step a merge, each measured in the breakage lab against its baseline (ground_dynamite_0m and _1m, the surface scan, the blast frame) with before-and-after sheets in the PR, and the lab's run.py --look sheet for the crater.

Also from the prop lab (its kit, claude/prop-lab-inventory-kit-*, once on main): the breakage lab's chair and card_table targets look for a StaticBody3D with prop_id and will find nothing in its KitProps (runner.gd _find_target, _target_result, _man's table height): read them as members. Its other notes (Blast and KitProp, kit props' smoke joining the room's SmokeField, splitting a holed slender member, _batch_all's index merge, range_cover's ungrounded members) are for gameplay to weigh, not this job.
```

## Blast damage to surfaces (after Sean's decisions in its brief) [Salt Creek]

Steps 1 (the near field queried on its own) and 2 (boards cut, not broken whole) merged with the
breakage lab, 2026-10-21. Step 3 is the prompt above. The original prompt:

```
Gameplay lane, branch claude/gameplay-blast-surfaces. Brief: docs/briefs/blast-surfaces.md (read its decisions first: they're mine). Read the src/structures and src/blast sections of docs/LAYOUT.md and the breakage lab's README and baseline. In the brief's order, one step a merge: Blast's near field queried on its own; boards cut over the stretch the blast overcomes (not broken whole); then craters in the dirt. Measure each step in the breakage lab against its baseline (the surface scenarios and the blast frame) with before-and-after sheets in the PR. The look of the cut ends and the crater's earth is the art lane's (4.4a).
```

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

## Treatment lab, part 1: field first aid (3.1c, after the body lab's baseline) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-treatment-lab. Roadmap 3.1c. Read the Treatment lab section of docs/briefs/labs.md, DESIGN.md §7 ("Treatment" and "Field first aid"), the body lab's README and baseline, and the src/bodies and src/player sections of docs/LAYOUT.md.

Bench and baseline first: experiments/treatment_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded. Measure today's treatment (the player's tend key, outlaws tending themselves, the doctor's patch-up) on the body lab's wounds, against the untreated baseline, on the Studio's men.

Then build part 1, one treatment at a time, each measured: the player treating someone else; pressure, tourniquets (tight and loose), packing, sealing a sucking chest wound (a hand at once, then something airtight, watched in case it traps air), splints, whiskey, moving a casualty; NPCs treating themselves and each other by their relationships. Each with its cost in hands, time and cloth.

Write the rules as a short list in the README and ask me to check them against my first-aid training before they're final. Coordinate with whoever is changing HumanBody or Physiology. The playtest agent tries it blind before I do; tell me exactly what to try.
```

## Treatment lab, part 2: the doctor (Phase 5, with 5.4 and 5.6) [Salt Creek]

```
Gameplay lane (characters for his lines), branch claude/gameplay-doctor. Roadmap 5.4 and 5.6, through the Treatment lab's part 2 (docs/briefs/labs.md). Read the brief, DESIGN.md §7 and the doctor in §5, and the treatment lab's README and results.

Build the doctor as a person with 1882's tools and limits, treating anyone brought in: probing for and removing a ball (and leaving one in when that's safer), cleaning (or not), chloroform, amputation, what he can and can't do for a gut or chest wound, and infection days later. It takes time and costs money; the ball he digs out is evidence. Measure each body-lab wound brought in at once, after an hour, and after a bad field dressing, against the field-only results. Cite period medical sources in the README (don't copy their text). Show me the plan before building.
```

## Perception and information lab (now) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-perception_lab. The perception and information lab (docs/briefs/labs.md, "People and systems labs"; its row in docs/ROADMAP.md's "When the labs start"). Read that section, experiments/physics_lab/README.md as the lab pattern, and the docs/LAYOUT.md sections for the systems it touches.

Bench and baseline first, changing nothing about how the game plays: experiments/perception_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded, on the Studio's men. Scenarios: sight lines by day and night, through smoke and cover; a shot inside the saloon heard outside; a man seen, then lost, then searched for; news passed from one person to another until a deputy knows. Measure false detections, reaction delays, how news spreads, and every time someone acts on what he couldn't know. Builds on Senses. No scripted outcomes: a result that needs a special case is reported as a failure, not fixed with one.

Report: a baseline table, the five biggest problems ranked by what a player would notice, and the first fix you'd make (don't make it).
```

## Confrontation and escalation lab (Phase 3, before 3.5) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-confrontation_lab. The confrontation and escalation lab (docs/briefs/labs.md, "People and systems labs"; its row in docs/ROADMAP.md's "When the labs start"). Read that section, experiments/physics_lab/README.md as the lab pattern, and the docs/LAYOUT.md sections for the systems it touches.

Bench and baseline first, changing nothing about how the game plays: experiments/confrontation_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded, on the Studio's men. Scenarios: a drunk insults me in the saloon; I ignore him, threaten him, shove him, or draw; the same with a hothead, a coward and a proud man; bystanders and the barman react by what they see. Measure how often it escalates, whether each choice is believable, and how many different outcomes come out. Builds on deeds, the escalation ladder and relations. Include answering yes or no with a nod or a shake (DESIGN.md §9, "Answering with a nod"): measure false answers while I look around, missed nods, and how long the blind playtest agent takes to discover it. No scripted outcomes: a result that needs a special case is reported as a failure, not fixed with one.

Report: a baseline table, the five biggest problems ranked by what a player would notice, and the first fix you'd make (don't make it).
```

## Physical interaction lab (Phase 3, with 3.3 and 3.4) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-interaction_lab. The physical interaction lab (docs/briefs/labs.md, "People and systems labs"; its row in docs/ROADMAP.md's "When the labs start"). Read that section, experiments/physics_lab/README.md as the lab pattern, and the docs/LAYOUT.md sections for the systems it touches.

Bench and baseline first, changing nothing about how the game plays: experiments/interaction_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded, on the Studio's men. Scenarios: pick up, carry, place and throw a bottle; push and pull a chair and a table; open and shove a door, whole and broken; drag a wounded man away from a fire. Measure response time, hand placement, collision faults, how things settle, and first-person feel, with mouse and controller. Coordinate with the furniture and shoves work. No scripted outcomes: a result that needs a special case is reported as a failure, not fixed with one.

Report: a baseline table, the five biggest problems ranked by what a player would notice, and the first fix you'd make (don't make it).
```

## Navigation and avoidance lab (Phase 3, before 3.6) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-navigation_lab. The navigation and avoidance lab (docs/briefs/labs.md, "People and systems labs"; its row in docs/ROADMAP.md's "When the labs start"). Read that section, experiments/physics_lab/README.md as the lab pattern, and the docs/LAYOUT.md sections for the systems it touches.

Bench and baseline first, changing nothing about how the game plays: experiments/navigation_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded, on the Studio's men. Scenarios: a full saloon emptying when a fire starts; a blocked door and a body in a doorway; a gunman stepping over rubble; the doctor reaching a patient across a wrecked room. Measure stuck people, failed routes, rerouting time and CPU cost. Builds on Waypoints. No scripted outcomes: a result that needs a special case is reported as a failure, not fixed with one.

Report: a baseline table, the five biggest problems ranked by what a player would notice, and the first fix you'd make (don't make it).
```

## The test saloon: the Systems Playground (start now) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-playground. Start the Systems Playground, the permanent test saloon (docs/briefs/labs.md, "The Systems Playground"), in experiments/playground/. Read docs/PARTS.md first: build it only from parts marked "in the game", never from a lab's fixtures. Start from the game's own saloon (SaloonBuilding, its stair and corner balcony) and the stretch of street in front of it, with three or four of the Studio's men and every approved system on; don't build a new saloon.

For each part on a branch or waiting to be promoted (the walking-ramp stair and BodyImpacts on claude/gameplay-falls-props, the breakable railing, the Studio woods), list what it needs and take it in once it's in the game. Don't promote another lab's part yourself: say which session should.

Then the systems-interaction scenarios, one at a time, recording for each whether the whole chain runs with no special cases, which system fails first, and the combined frame time: a shot lantern (falls, breaks, lights the floor, smokes, hides men, drives people out, blocks a door); a man shoved through the balcony railing; a shoved drunk through a table. Then the moments in docs/briefs/showcase-moments.md, each once the parts it needs are in the game. Make it the playtest agent's standing setup every build. Update docs/PARTS.md with what the playground uses. Report before fixing anything.
```

## Prop lab (now, with 3.3) [Salt Creek]

```
Prop lab, branch claude/prop-lab. Read docs/briefs/prop-lab.md, the Props and Structures sections of docs/PARTS.md, CLAUDE.md's lane note for the prop lab, and the docs/LAYOUT.md sections for src/structures, src/props, src/fire and src/blast.

First, find every prop that already exists and write it into docs/PARTS.md's Props table: the 12 drawn props in assets/props/manifest.json (PropLibrary, PropModels), every hand-built furnishing (FalseFrontBuilding._furnish_*, saloon_dressing.gd's bar, the trough, rail, well), what Fittings and the smashed lamp already do, and what the breakage lab (claude/gameplay-breakage-lab-*, experiments/breakage_lab/) and the ragdoll lab's railing have built or measured. Note for each: how it's built, what it can and can't do (break, burn, shatter, carry weight), and which lane's files it lives in. Show me that inventory before building.

Then design the prop kit: one data file per prop (members, shatter or fitting), read by one builder, with the look from the texture factory's approved materials matched to the Studio's men. Build the table and the chair first (roadmap 3.3): legs snap, tops split, they carry weight, burn piece by piece, a seated man drops when his chair goes. Each must look at least as good as PropModels' version in the same shot, pass the breakage lab's scenarios, and fit the frame budget batched. Use the shared systems as they are; anything they need changed goes to gameplay. Costs before any paid painting. Promote each finished prop into PARTS.md and tell the test saloon session.
```

## Face rig lab (after 2.1 and 2.3) [Salt Creek]

```
Characters lane, branch claude/characters-face-rig-lab. The face rig lab (docs/briefs/labs.md, "Face rig lab"). Read docs/briefs/face-rig.md, the talking face section of docs/LAYOUT.md and tools/faces/. Rig the Studio's men (bold_cowboy_s0, old_rancher_s1, young_drifter_s1, sean_s2) by one recipe, on copies, starting with one man and showing me before doing the rest. Measure each: lip sync on the same take, the shapes reading at 2, 5 and 10 m, his painted look kept (a sheet beside his portrait), the face with wounds and his hat, frame time with a room of talking men. My own takes, face and voice stay out of the repo: test sean_s2 on a stand-in take. Then write the recipe into tools/characters/RECIPE.md for my OK, and say what the Character Studio needs to make it a stage so every new man arrives rigged. Costs before any paid call.
```

## Water lab (part 1 with the prop lab's bottles and trough) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-water-lab. The water lab (docs/briefs/labs.md, "Water lab"). Read it, the src/fire section of docs/LAYOUT.md (water, douse, wet members, spilt oil) and docs/PARTS.md. Bench and baseline first in experiments/water_lab/ (README, its own bridge.gd, outputs in build/, seeded). Part 1, liquid in containers, on the prop lab's cup, bottle, barrel and the trough: a fill level, slosh when moved or bumped, a ball's hole draining by Torricelli's law until the level reaches it, pouring when tipped, a shattered bottle letting go. Check streams and drain times against the formula, and frame time with a bar full of glasses. No 3D particle fluid. Promote what works into the game and docs/PARTS.md. Parts 2 (spills) and 3 (the flood) come later, as the roadmap's schedule says.
```

## Promote a lab's part into the game [Salt Creek]

```
[Lane] lane, branch claude/<lane>-promote-<part>. Promote [part] from [lab] into the game, per CLAUDE.md "Labs measure; parts live in the game" and its row in docs/PARTS.md. Build it as a real game part in the shared code (for a structure: members, so it breaks, burns and carries load), keep the lab's results passing against the promoted part, add a test, and update its row in docs/PARTS.md to "in the game". Tell the playground session it's ready.
```

## Combat decisions and morale (inside the gunfight lab, after its baseline) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-gunfight-decisions. Extend the gunfight lab (experiments/gunfight_lab/) with the combat decisions and morale measures in docs/briefs/labs.md: log why each gunman made each choice (courage, aggression, skill, loyalty), and measure tactical variety, surrender and flight rates, the same man deciding the same way in the same spot, and how they adapt when cover is shot away. Baseline first; then the gunfight lab's fixes are judged on these numbers too.
```

## Weapon handling and feel (inside 3.2) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-weapon-handling. Inside roadmap 3.2: measure the guns without the AI (docs/briefs/labs.md, weapon handling and feel), on tests/test_gun_feel.gd and config/feel_ranges.json: draw to first shot, cocking, reload time one round at a time, practical accuracy, sight recovery after recoil, input response, and all of it wounded and rushed. Report against the feel ranges, mark anything that feels awkward rather than hard, and give me builds to try with exactly what to look for.
```

## Law, witnesses and consequences lab (Phase 5) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-law_lab. The law, witnesses and consequences lab (docs/briefs/labs.md, "People and systems labs"; its row in docs/ROADMAP.md's "When the labs start"). Read that section, experiments/physics_lab/README.md as the lab pattern, and the docs/LAYOUT.md sections for the systems it touches.

Bench and baseline first, changing nothing about how the game plays: experiments/law_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded, on the Studio's men. Scenarios: I shoot a man who drew first; I shoot an unarmed man in front of a witness; a theft nobody sees; a fight the deputy hears but doesn't see. Measure witness accuracy, time to report, false accusations, what the law does, and whether it holds the next day. Builds on deeds, Senses and the memory store (5.3). No scripted outcomes: a result that needs a special case is reported as a failure, not fixed with one.

Report: a baseline table, the five biggest problems ranked by what a player would notice, and the first fix you'd make (don't make it).
```

## World persistence and recovery lab (Phase 5) [Salt Creek]

```
Gameplay lane, branch claude/gameplay-persistence_lab. The world persistence and recovery lab (docs/briefs/labs.md, "People and systems labs"; its row in docs/ROADMAP.md's "When the labs start"). Read that section, experiments/physics_lab/README.md as the lab pattern, and the docs/LAYOUT.md sections for the systems it touches.

Bench and baseline first, changing nothing about how the game plays: experiments/persistence_lab/ with a README, its bridge commands in its own bridge.gd, outputs in build/, seeded, on the Studio's men. Scenarios: shoot out the saloon's windows, wound the storekeeper, wreck a room, then leave for a day, sleep, save and load. Measure what stays, how recovery runs over days, repairs scheduled, save and load holding it all, and what I see when I come back. Builds on saving (5.5). No scripted outcomes: a result that needs a special case is reported as a failure, not fixed with one.

Report: a baseline table, the five biggest problems ranked by what a player would notice, and the first fix you'd make (don't make it).
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
Gameplay (spread) and art (look), roadmap 4.4b. Build the fire lab in experiments/fire_lab/ on the labs.md pattern: a room, a building, then the block; measure spread speed against published fire-science figures, how smoke fills, and frame time, baseline first. Then finish docs/briefs/fire-look.md: firelight reaching the street, the smoke column (the critic's "flat maroon cut-out"), and the flames remade as fire-look.md's "next approach": flipbooks baked from a Blender fire simulation (headless), pushed into the painted style against docs/concept/livery-fire-painted.png, with motion-vector blending, a core and a tip layer, soft edges, heat haze and firelight on the street.
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
