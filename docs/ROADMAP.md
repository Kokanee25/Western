# Salt Creek: the roadmap

Sean, 2026-10-14: one plan for every session. **This file says what's being worked on. Nothing
else is.** DESIGN.md says what the game is; CLAUDE.md says how we work; this says in what order.

**The target: a demo.** A stable 20–30 minute piece of Salt Creek that a stranger can play
without help: ride into a small, finished block of town that looks like the paintings, meet
people who notice what you do, and find that what you did is still true the next morning. It
isn't the whole game; it's the proof of it, and the base the rest is built on.

## How it runs

- **Steps, not weeks.** Each step is one finished thing with a test of done. It takes as long as
  it takes: usually one to three sessions. What limits the pace is Sean's review time and the
  weekly usage, not the calendar.
- **One step per lane, at most two lanes at once.** A lane is a session (art, characters,
  gameplay). Each phase below names its lanes; the others are parked, apart from fixing a red
  main. **In Phases 2 and 3, up to four sessions at once** (Sean, 2026-10-21): the gameplay lane
  may run more than one session, each on its own step, its own branch and (for the labs) its own
  `experiments/` folder.
- **Finish before starting.** A session works only on its lane's current step. Anything else
  that comes up (an idea, a bug in another system, a better approach to a later step) goes in
  the step's notes or `docs/BACKLOG.md`, not into the work.
- **Evidence or it isn't done.** A step ends with what proves it: a side-by-side sheet, a
  video, a playtest report, test results, and a short status entry saying what passed and what
  didn't. Then it waits for Sean if its row says so.
- **Gates don't move with the calendar.** A phase ends at its gate: Sean's yes on the evidence.
  If a gate fails, the phase goes on: the failure becomes the next step, and later steps are
  cut, not the gate.
- **Fix, don't rebuild.** Most of what the demo needs exists. A step improves and joins what's
  there; a rewrite needs Sean's OK first, with a reason.
- **A red main comes first,** in any lane, any phase.
- **Spending:** each step that needs paid calls says its budget; up to it, the session spends
  and logs; past it, it asks.
- **Keeping this file:** a session ticks its step (`✅`, the date, the PR or build) and moves
  the **▶ Now** marker. Only Sean adds, removes or reorders steps.

## The phases

Sean, 2026-10-17: lock the look, make a few generic bad guys to stand in for everyone, then find
out whether missions are fun **before** the world is built out. The world and the art are the
easy part; making it fun is the hard part, so it comes first.

| Phase | What it proves | Lanes | Gate |
|---|---|---|---|
| 0. Clean slate | the build is trustworthy | gameplay | main green 3 nights |
| 1. The look (parked 2026-10-21) | it looks like the paintings | art, characters | A: Sean's yes on the shots, before Phase 4 |
| 2. Stand-ins | enough people to test with | characters | Sean's quick OK |
| 3. Is it fun? | the fight and rough missions are fun to play | gameplay (+ characters for fixes) | C: Sean plays them again by choice |
| 4. The place | a block of town worth standing in, built for the missions that worked | art, characters, gameplay | B: the block at four hours |
| 5. Consequence and story | what you do changes how people treat you; the opening of the real game | gameplay, characters | D: the slice, played blind |
| 6. The demo | a stranger can play it | all, in turn | F: the demo ships |

### When the labs start (Sean, 2026-10-21)

Labs measure a system in fixed scenarios before anything is fixed (`docs/briefs/labs.md`); the
pipelines make a kind of asset the same way every time. Each starts when its row says, and only
then.

| Lab or pipeline | Starts | Lane | Brief |
|---|---|---|---|
| Gunfight lab (3.0), body lab (3.1b), breakage lab (3.3a), ragdoll lab round 3 (3.1) | Now (Phase 3) | gameplay | `labs.md`, `fix-the-falls.md` |
| Prop lab: every prop end to end (look, members, breaking, burning, shattering), tables and chairs first | Now, with 3.3 (furniture) | gameplay and art (its own lane exception) | `prop-lab.md` |
| Face rig lab: every man's face rigged by one recipe, then a Character Studio stage | After the stand-ins (2.1) and wound paint (2.3), so faces are ready for 5.2 (talking) | characters | `labs.md` |
| Water lab 1, liquid in containers (slosh, holes that drain, pouring) | With the prop lab's bottles, cups and trough | gameplay (art for the look) | `labs.md` |
| Water lab 2, spills (whiskey and oil running, soaking, burning) | After part 1, with the fire lab | gameplay | `labs.md` |
| Water lab 3, the flood | Once the water tower is built as members | gameplay | `labs.md` |
| Fire flipbooks: the Blender fire simulation baked into sheets, the new flame shader (fire-look.md "next approach"); the final painted pass waits for Gate A | Now (Sean 2026-10-21: moved up from Phase 4) | art | `fire-look.md` |
| Perception and information lab | Now (Phase 3), beside the gunfight lab | gameplay | `labs.md` |
| Confrontation and escalation lab | Phase 3, beside 3.4, before 3.5 | gameplay | `labs.md` |
| Physical interaction lab | Phase 3, with 3.3 and 3.4; 4.7 finishes it | gameplay | `labs.md` |
| Combat decisions and morale | Inside the gunfight lab, after its baseline | gameplay | `labs.md` |
| Gun lab: the guns' look in the player's and men's hands, draw, cock, reload, holster, drop, and the handling and feel measures | Now, with 3.2 (guns agreed) | gameplay (art for the look) | `labs.md` |
| The Systems Playground (systems interaction) | Phase 3, once the gunfight lab's baseline is in; grows every phase | gameplay | `labs.md` |
| Navigation and avoidance lab | Phase 3 before 3.6; again before 5.7 | gameplay | `labs.md` |
| Law, witnesses and consequences lab | Phase 5, with 5.3 and 5.8 | gameplay | `labs.md` |
| World persistence and recovery lab | Phase 5, with 5.5 and 5.9 | gameplay | `labs.md` |
| Treatment lab part 1: field first aid (3.1c) | After the body lab's baseline (Phase 3) | gameplay | `labs.md` |
| Treatment lab part 2: the doctor (with 5.4 and 5.6) | Phase 5 | gameplay, characters (his lines) | `labs.md` |
| Sound lab: gunshots, ricochets, explosions, impacts, breaking, fire, steps; where they sit in space (distance, indoors, echo off the hills) | Now (Sean 2026-10-21: its own lab, moved up) | gameplay | `labs.md` |
| Material lab: colour, grain, thickness, end grain, dirt, paint wear (1.4a) | Now, beside Phases 2 and 3 | art | `building-pipeline.md`, `material-lab-timber.md` |
| Wound paint (2.3) | After the stand-ins (2.1) | characters (+ a line of gameplay) | `damage-pipelines.md` |
| Material lab: wear-down (worn paths, paint gone where hands touch, new / a year / ten years) | After Gate A | art | `building-pipeline.md` |
| Building lab: the saloon's spec and structure (frame, floors, walls, both stairs, both balconies, the bar, bedrooms; `docs/concept/saloon-sheet.png`), as an experiment first | When Sean has picked the interior woods (the material lab) and the breakable railing is promoted (Sean 2026-10-21; was "after Gate A") | gameplay (structures), art (look) | `building-pipeline.md` |
| Building lab for real: the saloon (4.3), furnished with the prop lab's pieces as each is promoted, then the block (4.4) | The saloon once its structure passes the checks; the block in Phase 4, after Gate C | art, gameplay | `building-pipeline.md` |
| Breakage paint (4.4a) | Phase 4, once the woods are locked | art | `damage-pipelines.md` |
| Fire lab, and finishing `fire-look.md` (4.4b; the flipbooks start now, above) | Phase 4, before 4.5 | gameplay (spread), art (look) | `damage-pipelines.md`, `fire-look.md` |
| Movement lab: walking, running, mocap | 4.6, when Sean records | gameplay | `MOCAP.md` |
| People lab: town life, memory, the next morning | Phase 5, once the memory store exists | gameplay | to write |
| The town, through the building lab | After Gate B, past the demo | all | `building-pipeline.md` |

---

## Phase 0: Clean slate

Lane: gameplay. Art and characters finish what they have open and stop.

| # | Step | Done when | Who |
|---|---|---|---|
| 0.1 | **Green and quiet** | Main green, and the nightly soak and visual checks green three nights running. Any flaky test fixed, or quarantined with a note saying why. | gameplay |
| 0.2 | **Sean's open list cleared** | Every "Waiting on Sean" in CLAUDE.md's Current state answered or moved to the backlog. | Sean |

## Phase 1: The look

Lanes: art and characters. Gameplay parked. **Gate A: the look is locked.**

**Parked (Sean, 2026-10-21): "the look is good enough to test with."** What's open here waits;
Gate A (1.5) is signed off before Phase 4 starts, not before Phases 2 and 3.

The approach is settled (the paintings' squares on the surfaces, smooth light, faces by
`tools/characters/RECIPE.md`). This phase makes it right in the game's own light, not a new style.

| # | Step | Done when | Who |
|---|---|---|---|
| 1.1 ✅ 2026-10-15 | **The targets locked** | One folder, `docs/concept/targets/`, holds the pictures the game is judged against: a man close at a table, the saloon at night, the street at golden hour, a wall and a post up close, a prop. Each has its three biggest gaps written beside it, from a render made today. One session. | art |
| 1.2 | **Faces in the game's light** | A portrait man in the saloon at night and on the street at golden hour: no burnt orange, eyes readable under the brim, skin matching his portrait's lit and shadow cheeks. Measured with `tools/face_light.py`, judged on a sheet. | art (light), characters (paint) |
| 1.3 | **The man complete** | The bold cowboy whole: the portrait's hat (brown, dented crown, studded band) as its own piece that can be shot off, his hair edges, coat, vest, shirt, tie and hands as separate pieces, through the pose check (stand, sit, hands up, crouch, back) with no tears. | characters |
| 1.3b | **Faces that move** (Sean 2026-10-16) | A test on the bold cowboy, before more men are made: his head gets a mouth that opens (lips, teeth, tongue dark), eyelids that close and a jaw, and 10–15 expressions that read at the game's square size (jaw, the main speech shapes, blink, squint, brows up and down, scowl, half smile), carried from MakeHuman's free expression shapes onto his Rodin head by script. Then one short line of Sean's iPhone performance (Live Link Face's recording, his voice through ElevenLabs' voice changer) played on him in Godot. Done when he speaks and pulls faces without losing his look, and the recipe (`RECIPE.md`) says how every man after him gets the same rig. | characters |
| 1.4 | **Surfaces to the man** | Wood, end grain, posts, planks and the road at the same square size and finish as his face and coat: they look like one picture, close and far. | art |
| 1.4a | **The material lab** (Sean 2026-10-21; runs now, beside Phases 2 and 3) | `tools/material_lab.gd` made permanent and wider (`docs/briefs/building-pipeline.md`): one material at a time on a test stand (wall, post, deck, steps) under the three lights with the Studio's men for scale; colour, grain and knots, thickness and end grain, dirt and splash, sun-greying, paint wear. Each approved material goes into the texture factory with its numbers and a golden view. Wear-down waits for Gate A. | art |
| 1.5 | **Gate A** | Two fixed shots, the man at the saloon table and the street at golden hour, side by side with their targets. Sean says yes. Then: goldens re-approved, the look's settings frozen, and later changes only to close a gap Sean names. | Sean |

## Phase 2: Stand-ins

Lane: characters. Small and quick.

| # | Step | Done when | Who |
|---|---|---|---|
| 2.1 | **Generic bad guys** | Two or three rough men made by the recipe (`RECIPE.md`, `LAYERED.md`), each with a couple of outfit and hat swaps, so a street of them isn't one man repeated. They stand in for everyone (the gang, the townsfolk, the storekeeper) while missions are tested; the real cast comes in Phase 4. Each passes the pose check. | characters |
| 2.2 | **Sean's quick OK** | A line-up sheet; Sean says they'll do for testing. Not a look gate. | Sean |
| 2.3 | **Wound paint** (after 2.1) | The painted wound atlas in the man's hand (`docs/briefs/damage-pipelines.md`): entry, exit, graze, soak in stages, pools; read by `wounds.gdshaderinc` in place of noise, the soak growing with the blood lost. Judged on two fixed views beside painted targets. Reduced gore stays. ~$3 proposed. | characters, gameplay (one line) |

## Phase 3: Is it fun?

Lane: gameplay. Characters only to fix the stand-ins. **Gate C: Sean plays them again by choice.**

Rough on purpose: stand-in men, typed lines instead of voices, missions in the street and saloon as
they are. The question is only whether it's fun; anything that doesn't serve that waits.

| # | Step | Done when | Who |
|---|---|---|---|
| 3.0 | **The three-gunman fight** (Sean 2026-10-17; brief `docs/briefs/three-gunmen.md`) | The player against three gunmen of different temper on the existing street, run again and again: fights that can end with one good shot but usually become a tense 45–90 seconds of cover, flanking, suppression, reloads and retreats; misses that come from the gun's sway, not dice, for NPCs as for the player; enemies you can hear (steps, cocking, shouts) but who never know where you are by magic. Measured over many runs (fight length, hits per side, who hits first), then played by Sean. **Its arena is the gunfight lab** (`docs/briefs/labs.md`, `experiments/gunfight_lab/`): street, saloon and ambush setups at golden hour and night, revolver and shotgun, a scripted player in three styles; the baseline first, then the brief's gaps one at a time, each measured. | gameplay |
| 3.1 | **Falls and hits** | Prompt 09: the ragdoll lab's faults fixed against its baseline (no folding straight down, no limbs through the body, joints in their limits), and hit reactions short of a fall. | gameplay |
| 3.1b | **The body lab** (beside 3.1; `docs/briefs/labs.md`, `experiments/body_lab/`) | Shots at 5, 15 and 30 m and dynamite at 1, 3 and 6 m into a standing man at marked spots, then treated: what the ball crosses, bleed-out per artery, broken bones and what they stop, limbs lost, ten wounded men against the people budget, all checked against cited trauma figures. The bench and its baseline first; fixes (cut points and stumps, missing arteries, breaks that change what a man can do) measured against it. Reduced gore stays a setting. **Bench and baseline done 2026-10-21** (`experiments/body_lab/README.md`: the baseline, the gaps from the medicine, the first fix). | gameplay |
| 3.1c | **Field first aid** (Sean 2026-10-21; after 3.1b's baseline; `docs/briefs/labs.md`, Treatment lab part 1, `experiments/treatment_lab/`) | The player treats himself and others, and NPCs treat themselves and each other by who they are: pressure, tourniquets, packing, sealing a sucking chest wound, splints, whiskey, moving a casualty, each with its cost. Measured against the untreated baseline: time to stop each bleed, who lives, how often an NPC treats instead of fighting. Rules checked against Sean's first-aid training. | gameplay |
| 3.2 | **Guns agreed** | Revolver and shotgun against the feel ranges, every range `proposed` agreed or changed by Sean after he plays. | gameplay, Sean |
| 3.3a | **The breakage lab** (before 3.3; `docs/briefs/labs.md`, `experiments/breakage_lab/`) | A chair, table, door, bottle, lamp, window and the store front against the revolver and shotgun at 5 m and dynamite at 1, 3 and 6 m, and a man thrown into a table: breaks or holds (against the Wood Handbook), pieces and how far they fly, what catches fire, physics faults, same seed same result, frame time per blast. Its baseline is what 3.3 is built against. | gameplay |
| 3.3 | **Furniture** (through the prop lab, `docs/briefs/prop-lab.md`) | Tables tip, chairs break, doors give way, by how they're built, and men use them as cover. | gameplay |
| 3.4 | **Shoves** (Sean 2026-10-15) | You can shove a man (a key, a short reach), and people shove each other with the same physics. He staggers, catches himself, or goes down by how hard, how braced and how hurt he is, and into whatever's there: through a chair, onto a table that breaks, down the stairs, off the boardwalk into the street, leaving his print in the dust where he lands (the dust decal is art's). It's a deed, as now: the room sees it and it moves the escalation ladder. Needs 3.2 (falls) and 3.5 (furniture). | gameplay, art (the print) |
| 3.5 | **Acts** | A way to write missions and little scenes as data: who goes where, says what, beat by beat, and what hands back to the systems when you interfere (DESIGN.md §5 "Story shape"). Lines are typed on screen for now. | gameplay |
| 3.6 | **Three rough missions** (ideas: `docs/briefs/showcase-moments.md`; the card cheat for the saloon table) | Built in acts with the stand-ins, 10–20 minutes each: **the saloon table** (the stranger talks, a shooting at the bar), **the store robbery** (the gang leans on the storekeeper; pay, talk, threaten, fight, arrest), and **a bounty** (a wanted man camped outside town; alive pays more). Each has more than one way through. | gameplay |
| 3.7 | **Play, note, fix** | Sean plays a build for 15 minutes a few times a week and says what felt wrong; the playtest agent plays each mission blind. What they find is fixed here, in this phase, before moving on. | Sean, gameplay |
| 3.8 | **Gate C** | Sean plays all three missions and wants to play at least two of them again a different way. If not, this phase goes on: the missions or the feel change until he does. | Sean |

## Phase 4: The place

Lanes: art, characters, gameplay. **Gate B: the block at four hours.** Starts after Gate C, with
Gate A (1.5) signed off first.

A small block finished to the look, shaped by what the missions in Phase 3 turned out to need:
the saloon, the store, the telegraph, the jail and the livery, and the street between them.

| # | Step | Done when | Who |
|---|---|---|---|
| 4.1 | **The cast by recipe** | Brody, Lyle and the storekeeper made by `RECIPE.md`, each within ~2 h of session and ~$2, each passing the pose check and the art session's look. The recipe's real test: a fresh session makes the third man from the recipe alone. | characters |
| 4.2 | **Townsfolk** | Eight background people, cheaper than principals (shared bodies and wardrobe, their own faces), different enough that the street isn't brothers. | characters |
| 4.3 | **The saloon finished** (through the building lab, `docs/briefs/building-pipeline.md`) | Outside and in, to its set-direction card (`docs/briefs/set-direction.md`): lit, dressed, the critic's top three closed. | art |
| 4.4 | **The block finished** | The store, telegraph, jail and livery to their cards: fronts, signs, what's seen through the doors, the street's dressing. | art |
| 4.4a | **Breakage paint** | Per-wood insides, torn, split and charred-break faces for the voxel carving and chips, in one material (no new draw calls) (`docs/briefs/damage-pipelines.md`). Judged on the wall scene beside a painted target. ~$3 proposed. | art |
| 4.4b | **Fire, finished** | The fire lab (spread against fire-science figures, smoke filling, the look) and the rest of `docs/briefs/fire-look.md`: firelight on the street, the smoke column, the flames redrawn in the locked look. | gameplay, art |
| 4.5 | **Light across the day** | Dawn, noon, golden hour, night, and inside, each a fixed view with a golden image. None of them breaks the look. | art |
| 4.6 | **Motion** | Sean records the shot list in `docs/MOCAP.md` (walk, run, turn, idle, sit, stand up, draw); it's retargeted and the people move by it, with procedural breathing, aim and flinches on top. *Needs Sean's recording time: book it at the start of the phase.* | Sean, gameplay |
| 4.7 | **Hands on the world** | Pick up, carry, drop, throw, open, close: doors, bottles, chairs, a hat off the floor. It feels natural with mouse and controller. | gameplay |
| 4.8 | **Inside the budget** | The fight with a fire in the room fits the frame budget on Sean's PC (his F3 readout, not this workspace's guess). | gameplay |
| 4.9 | **Gate B** | A walk down the block at each of the four hours (the tour video), a blind critic's report, and Sean's yes: "it looks like the game". | Sean |

## Phase 5: Consequence and story

Lanes: gameplay; characters for voices. **Gate D: the slice.**

| # | Step | Done when | Who |
|---|---|---|---|
| 5.1 | **Money** | M4 step 5: a purse of coins, the barkeep's prices and tabs, "a round on me". | gameplay |
| 5.2 | **Talking** | M4 steps 7 and 9 for the prologue: written lines for its cast, voiced (ElevenLabs, budget stated first); what you type or say read into a deed. | gameplay, characters (voices) |
| 5.3 | **Witnesses and memory** | M4 step 8: who saw what, who heard about it, and it changes how they treat you. | gameplay |
| 5.4 | **The jail and the doctor** (the doctor through the Treatment lab's part 2, `docs/briefs/labs.md`) | An arrested man stays jailed; the wounded are treated; you sleep in a bed and wake at the doctor's if you went down. | gameplay |
| 5.5 | **Saving** | The outcome survives sleeping, quitting and loading. | gameplay |
| 5.6 | **The sheriff opening** | M5: you find him on the road at dawn, treat him, his words follow his blood loss, the ball the doctor digs out is evidence. | gameplay, characters |
| 5.7 | **A day for everyone** | The block's dozen people work, eat, drink and sleep on routines, and break off from them when something happens. | gameplay |
| 5.8 | **The law answers** | The sheriff (or his deputy), the gang and the town respond to what they witnessed, the same day and the next. | gameplay |
| 5.9 | **The next morning holds** | Three different playthroughs, each followed into the next day: what changed makes sense every time. | gameplay |
| 5.10 | **Gate D** | The prologue and on into the next morning, 20–30 minutes, played blind by the playtest agent (report in `docs/playtests/`), then by Sean. | Sean |

## Phase 6: The demo

All lanes, one at a time. **Gate F: the demo ships.**

| # | Step | Done when | Who |
|---|---|---|---|
| 6.1 | **Sound** | Guns, steps, rooms, the street, fire: coherent, nothing missing or wrong-sized. | gameplay |
| 6.2 | **Motion polish** | Nothing in how people move pulls you out of it. | gameplay |
| 6.3 | **Art consistency** | Everything in the demo meets the locked look (Gate A). | art |
| 6.4 | **Menus and onboarding** | A start menu, settings, controls shown, the first minutes teaching what you need. | gameplay |
| 6.5 | **Performance** | The demo holds 60 fps on Sean's PC throughout. | gameplay |
| 6.6 | **Reliability** | A full soak of the demo, saves and loads included, green. | gameplay |
| 6.7 | **Strangers play it** | Two or three people who've never seen it play the build; what they hit is written down. | Sean |
| 6.8 | **Fixes** | Their worst problems fixed and checked again. | all |
| 6.9 | **Gate F** | A standalone build with install notes and a known-issues list, and a plan for the full game from what the demo taught. | Sean |

---

## ▶ Now

Sean, 2026-10-21: the look is good enough to test with. Phase 1 is parked (Gate A before Phase 4);
**Phases 2 and 3 run now, up to four sessions at once.**

- **Phase 2** (characters): **2.1** the generic bad guys, then 2.2 Sean's quick OK.
- **Phase 3** (gameplay):
  - **3.0** the three-gunman fight, in the **gunfight lab** first (bench and baseline, then fixes).
  - **3.1** falls and hits (moved up 2026-10-16; brief `docs/briefs/fix-the-falls.md`), with
    **3.1b** the **body lab** beside it.
  - **3.2** guns: the kick merged (#153), the smoke next (`claude/gameplay-smoke`).
  - **3.3a** the **breakage lab**, before 3.3.
- **Phase 1, beside them** (art): **1.4a** the **material lab** (Sean 2026-10-21). Progress: the lab
  built (stand, three lights, the Studio men, the measures, the critic's question;
  `docs/briefs/material-lab.md`); round 1 measured and painted (~$4.44): no wood passes yet, the
  critic finds the repaints' fine grain photographic; round 2 (broad paint, 384 a metre): the store
  boards SAME; round 3 (the weathering layer in texel_grid, the boards graded to one palette in the
  cut, the seam dashes fixed): saloon red and timber up to CLOSE, weathered pine SAME, 2-3 SAME of
  8 against round 2's none; round 4 (free: stains darker than the wood, bleach on sky faces only):
  no wood DIFFERENT for the first time (1 SAME, 7 CLOSE); round 5 (free): timber and the deck SAME;
  round 6 (free: banded light on the woods, pine's knots soft, flat tone steps): knots gone, the
  critic otherwise unmoved (the wood's light still rolls; its source next); Sean's pick on round 5's
  exterior woods waits on him (`2026-10-22/pick_exterior.jpg`); the interior woodwork (Sean's saloon picture: profiles,
  the interior stand, one umber stain, `interior-woodwork.md`) waits on his pick. Nothing in the
  game's woods until Sean picks. The hotel's oak stair on the bench. Wear-down planned (after Gate A).
- When the other labs start: "When the labs start", under the phases table.
- Still open from Phase 0: **0.1** green and quiet (nightlies green three nights).
- Parked with Phase 1: 1.2, 1.3, 1.3b and 1.4 where they stand (1.3's proper garments were
  next; art had paused 2026-10-17 until the man was done). Gate A (1.5) before Phase 4.

## Decisions Sean can change

- The look is painted illustration (Sean, 2026-10-16; DESIGN.md §4): smooth painted surfaces,
  the squares retired surface by surface (road and wood done, the men's clothes in 1.3). Gate A
  (1.5) is judged on it, its street target brought into line.

- The story's shape is a rough idea (DESIGN.md §5 "Story shape", 2026-10-15): ten days of about
  an hour, opening at the saloon table, then the sheriff on day 1. The demo is the prologue and
  day 1; the saloon table, the store robbery and a bounty are Phase 3's rough missions (3.6). All of it may change.
- The block is five buildings. Anything more waits until after Gate B.
- Fun first (Sean, 2026-10-17): the world is built out only after Gate C says the missions are fun.
- No new systems before Gate D unless a step needs one. DESIGN.md §11's backlog and
  `docs/prompts/` stay frozen until a step names one.
