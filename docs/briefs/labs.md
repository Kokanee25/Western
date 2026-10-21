# Salt Creek: The Labs

Oct 20, 2026 · @Sean

Three labs to build now, each a test bench like the ragdoll lab: the gunfight lab first, then the body lab and the breakage lab. Each measures before it changes anything, and each serves a Phase 3 step already on the roadmap.

## How every lab works

Every lab copies the ragdoll lab (`experiments/physics_lab/`, Prompt 01), which took the falls from 90 flagged faults to 10.

1. **Fixed scenarios.** The same setups every run, seeded, so two runs of the same build give the same numbers.
2. **Run headless, many times.** Through the dev bridge, so hundreds of runs cost minutes, not Sean's evenings.
3. **Numbers and contact sheets.** Each run logs what happened; a sheet of matched frames shows it.
4. **Baseline first, changing nothing.** The first session only builds the bench and measures today's game.
5. **Fixes measured against the baseline.** One change at a time, each with its before and after.
6. **Then people play it.** The playtest agent blind, then Sean. Numbers catch what's broken; only play says what's fun.

Each lab lives in its own folder under `experiments/`, with outputs under `build/` (never videos in git), and can merge once tested, since a lab changes nothing about how the game plays.

## Gunfight lab

The arena that step 3.0 (`docs/briefs/three-gunmen.md`) asks for, built as a lab: three gunmen on the existing street, fought hundreds of times, with numbers that tell a dead fight from a tense one. Today both playtests say the gang hits first and the player is down in a second or two. Your brief wants 45–90 seconds of cover, flanking, reloads and retreats, with one good shot still able to end it.

**Scenarios**

| Setup | What it tests |
| --- | --- |
| Street: you at the trough, three men round the saloon porch and crates | The brief's main arena |
| Saloon inside, lamps lit | Close quarters, lamps and fire as hazards |
| Ambush: they open fire first, from cover | Whether you get a chance to react |
| Each of the above at golden hour and at night, with revolver and with shotgun | Light and weapon change the fight |

The gang's three tempers (Brody cool, Lyle a hothead, the Kid timid) are in every fight. A scripted player runs each setup in three styles (holds one spot, moves cover to cover, pushes hard), so the numbers don't reflect one way of playing.

**What's measured**

| Measure | Why it matters | Target |
| --- | --- | --- |
| Fight length | Too short is a coin toss; too long is a chore | 45–90 s in most fights, a quick end still possible |
| Who hits first, hits per side | Today it's the gang, almost at once | You set it after the baseline |
| Time before you're first hit | Room to react | You set it |
| Near misses a minute (cracks, whizzes, dust close by) | Danger you feel without damage | Baseline first |
| Cover changes, flanks, suppressing fire per man | The fight moves | Baseline first |
| Situation changes: cover shot away, a lamp hit, dust hiding a man, a surrender or flight | "Every bullet should change the situation" | Baseline first |
| Longest quiet stretch | A tense lull versus dead time | Baseline first |
| How fights end: dead, surrendered, fled, you down | A spread, not one ending | Baseline first |

**What changes, after the baseline:** the brief's own gaps, one at a time, each measured. NPC aim from the same physical sway the player has, not a random spread; sounds you can hear (steps on boards versus dirt, a hammer cocked, a shout); dust that hides a man; small interactions like a chair leg shot out.

**How excitement is judged:** the numbers only catch dead fights. After each change you play three fights and say which was best and why. That's the real measure, and the numbers explain it.

## Body lab

A bench for wounds: shots and blasts into a standing man at fixed spots, with what the anatomy does checked against real trauma medicine, not guesses. It builds on what's there: `Anatomy` (bones, arteries and organs from `tools/anatomy/build_anatomy.py`), `Physiology`, `sever_limb`, `BodyInterior` and the wound shader.

**Scenarios:** revolver and shotgun at 5, 15 and 30 m into marked spots (thigh, neck, upper arm, chest, belly, hand); dynamite at 1, 3 and 6 m; then the same wounds treated (tourniquet, packing, the doctor).

| Measure | Checked against |
| --- | --- |
| What the ball's path crosses: which artery, bone, organ | The aim point, and anatomy references |
| Bleed-out time per artery, untreated and treated | Published trauma figures, cited in the lab's README |
| Which bones break, and what that does (can't stand on a broken thigh, can't grip with a broken hand) | Medical references |
| Limbs lost: from what, at what range, where the cut falls | The design's rule: dynamite at close range can take limbs |
| How it looks: wound, stump, blood pool | The painted wound targets, once the wound atlas exists |
| Frame time with ten wounded men | The people budget, 4 ms |

**What changes, after the baseline:** amputations with cleaner cut points and finished stumps; more of the named arteries where the baseline shows gaps; bone breaks that change what a man can do. "Better skeletons" here means anatomical bones. The animation skeleton, the one mocap needs, is Prompt 08's job and a separate lab.

Reduced gore stays a setting throughout.

## Breakage lab

The test bench for step 3.3 (furniture): what breaks, how, and what it costs a frame, with furniture, bottles and walls against each weapon at set distances. It builds on the members and support graph, voxel carving, `Blast` (timbers broken by blast energy against their strength, glass by pressure) and `Fittings`. New: bottles and small props that shatter, since today they're props, not members.

**Scenarios:** a chair, a table, a door, a bottle on the bar, a lamp, a window and the store front wall, each against the revolver at 5 m, the shotgun at 5 m, and dynamite at 1, 3 and 6 m. Then a man thrown into a table, ready for step 3.4 (shoves).

| Measure | Why |
| --- | --- |
| Breaks or holds, and where | Against timber strengths from the USDA Wood Handbook, as the frame already uses |
| Pieces, largest piece, how far debris flies | A chair should come apart into pieces, not dust or one lump |
| What catches fire | A smashed lamp should start one; a dropped bottle shouldn't |
| Physics faults: pieces through the floor, jitter, flying off at speed | The ragdoll lab's kind of flag |
| Same seed, same result | The repo's rule for every simulation |
| Frame time per blast | The wall scene's render CPU is already over budget, so every new piece counts |

**What changes, after the baseline:** Prompts 03 and 06 as one job (chairs and tables built as members that break by how they're built, a seated man dropped when his chair goes), bottles that shatter and spill, and furniture that dynamite throws and breaks.

## Treatment lab (Sean, 2026-10-21)

A bench for treating wounds: what the player, the townsfolk and the doctor can do for a wounded
man, checked against real first aid and against what an 1882 doctor could and couldn't do.
DESIGN.md §7 ("Treatment", "Field first aid") is the design; treatment rules follow Sean's
first-aid training, as DESIGN.md says. Two parts, run at different times.

**What exists to build on:** `Physiology.apply_tourniquet()` (every bleed below it stops) and
`apply_pressure()` (pressure or packing on one segment); the player's hold-to-tend key
(`tend_wounds`: pressure on the worst bleed, then a tourniquet high on the limb, then a bandage);
outlaws who stop to tend themselves when it's quiet (`OutlawBrain.tend_bleed`); holed lungs
tracked in `lung_damage` (a sucking wound when the ribs are blown out); the doctor's building
with its furnished room; and waking at the doctor's, where `_patch_up()` simply ties off
everything and seals the lung. Nobody treats anyone else yet, and the doctor does nothing on
screen.

### Part 1: field first aid (3.1c, after the body lab's baseline)

The player on himself and on others, and NPCs on themselves and each other.

| Treatment | What it does | Its cost |
| --- | --- | --- |
| Direct pressure | Slows a bleed while held | Both hands busy: no shooting, reloading or riding |
| Tourniquet (belt, bandana and stick, rope) | Tight stops an arterial bleed; loose only slows it, and can make it worse | Seconds to apply; hours on and the limb may be lost |
| Packing a wound | Stops a bleed a tourniquet can't reach (groin, armpit, neck) | Slower; needs cloth (the shirt gets shorter); dirty cloth raises infection later |
| Sealing a sucking chest wound | A hand over it at once, then anything airtight (oilcloth, leather, waxed paper) | Must be watched: a seal that traps air makes his breathing worse until it's lifted |
| Splint | A broken leg or arm can be moved without more damage | A rifle, a board off the rubble, a fence rail |
| Whiskey | Pain down, for a while | Cleans a wound badly; a drunk patient |
| Moving him | Drag to cover, carry, throw over a horse | Slow, exposed, and it reopens bleeds |

- **On someone else:** you kneel by him and choose what to do; his wounds show you where. A man
  you're treating may still be holding a gun.
- **NPCs do it too,** by who they are: a loyal friend drags a partner behind cover and cinches a
  belt on his leg (two men not shooting); a lone wounded man stops to tie off his own arm; hired
  guns leave each other; townsfolk who like you press a rag on your wound.
- **Scenarios:** each wound from the body lab (thigh, neck, upper arm, chest, belly), treated by the
  player, by a partner, by himself, and untreated; in the open, under fire, and after the fight.
- **Measured:** time to stop each bleed; blood lost before and after; who lives against the
  untreated baseline; how often an NPC treats instead of fighting, and whether that opens a chance
  (closing in, calling for surrender); a seal that traps air, caught and lifted or not.

### Part 2: the doctor (with roadmap 5.4 and 5.6)

The doctor as a person with tools and limits, treating anyone brought in: the player, the
sheriff, a prisoner, a wounded outlaw.

| Procedure | 1882 as it was |
| --- | --- |
| Finding and removing a ball | Probes and forceps, by feel; a ball left in is often safer than digging |
| Cleaning | Carbolic acid if he follows Lister; plenty of doctors still didn't. Dirty probing infects |
| Anaesthesia | Chloroform or ether; whiskey and laudanum when there's none |
| Amputation | A shattered limb or one left too long under a tourniquet, done fast; ligatures on the arteries |
| Chest and belly | A shot through the gut usually kills slowly whatever he does; he can ease it, not fix it |
| Infection | Shows days later as fever and smell; can kill a man who survived the shooting |

- **It takes time and costs money:** a man brought in is out of the story for hours or days; the
  doctor charges, talks, and remembers who paid.
- **What he finds is evidence:** the ball he digs out (5.6: the sheriff's) matches a gun.
- **Scenarios:** each body-lab wound brought in at once, after an hour, and after a bad field
  dressing; an amputation (a crushed leg, a tourniquet left on too long); a fever a week later.
- **Measured:** survival with and without him, time out of action, what each case leaves behind
  (a limp, a stump, a scar), cost, and frame time with the room full.

**One body, one physiology (both parts):** the doctor has no healing system of his own. He works
on the same `Physiology` and `Anatomy` as the shooting, the player and the field dressings, so a
wound he treats is the same wound, and what he can't change, he can't change.

**Getting him there:** a man shot in the leg is conscious but can't walk; a friend tries to help,
or the player carries him to the doctor's. The lab measures whether a patient survives the
journey (moving reopens bleeds), whether each treatment changes the outcome against leaving him,
whether the doctor's choices are clinically sensible for 1882, and whether recovery and lasting
harm (a limp, a stump, a weak arm) are believable.

**Not in this lab:** what wounds look like (the painted wound atlas, roadmap 2.3) and stump
meshes (the body lab).

## People and systems labs (Sean, 2026-10-21)

The labs above test physical simulation. These test the other half of an immersive sim: what
people perceive and how they react, what the player can do with the world, and whether the
systems work together **with no scripted outcomes**. That rule holds for every one of them: a
result that needs a special case to come out right is a failure the lab reports, not a fix.

Several build on what exists: `Senses` (sight, light, hearing through walls, last-known
positions), deeds and the escalation ladder (`player_deeds.gd`, `deed_watch.gd`, `relations.gd`),
the gang's brains and `Crew` (callouts, rescue), `Waypoints`, and the dev bridge and playtest
agent.

| Lab | What it tests | Measured | Where it fits |
| --- | --- | --- | --- |
| **Confrontation and escalation** (first) | Before a shot: a drunk's insult, ignoring, threatening, shoving, drawing, backing down, surrender, sudden violence; bystanders react by what they see and who they are; yes and no answered with a nod or a shake (DESIGN.md §9, "Answering with a nod") | How often it escalates; whether each choice is believable; how many different outcomes come without scripting; nods: false answers while looking around, missed nods, time for a blind player to find it | Phase 3, beside 3.4 (shoves), before 3.5 (acts) and the missions |
| **Perception and information** (second) | Sight lines, light, smoke, cover, hearing and knowing a sound, last-known positions, passing news on (a shot inside the saloon: who hears, who knows it's a gun, who saw, how a deputy learns) | False detections; reaction delays; how news spreads; any NPC acting on what he couldn't know | Phase 3, now: the gunfight lab's fairness rests on it, and Phase 5's people build on it |
| **Physical interaction** (third) | Pick up, carry, place, throw, push, pull, open, drag: a bottle thrown at a man, a chair knocked over, a wounded man dragged from a fire, a broken door shoved open | Response time; hand placement; collision faults; things settling stably; how it feels in first person | Phase 3, with 3.3 (furniture) and 3.4 (shoves); 4.7 (hands on the world) finishes it |
| Combat decisions and morale | Why each gunman does what he does: courage, aggression, skill, loyalty, flanking, leaving a friend, breaking when a mate falls, adapting when cover is shot away | Tactical variety; surrender and flight rates; the same man deciding the same way; variety without repetition | Inside the gunfight lab, after its baseline |
| Weapon handling and feel | The guns without the AI: cocking, finding the sights, recovering from recoil, loading one round at a time, handling a gun wounded or rushed | Draw to first shot; reload time; practical accuracy; sight recovery; input response; hard but not awkward | Inside 3.2 (guns agreed), on `tests/test_gun_feel.gd` and the feel ranges |
| Navigation and avoidance | Routes through a world that changes: broken furniture, blocked doors, spreading fire, a body in a doorway; a fleeing drinker finding another way out, the doctor reaching a patient | Stuck people; failed routes; rerouting time; CPU with a full saloon | Phase 3 before 3.6 (missions), again before 5.7 (a day for everyone) |
| Law, witnesses and consequences | Self-defence, intimidation, assault, theft and murder told apart by evidence and witnesses: a man who drew first, an unarmed man shot, a crime nobody saw | Witness accuracy; time to report; false accusations; how the law answers; the same day and the next | Phase 5, with 5.3 and 5.8 |
| World persistence and recovery | What happens while the player is away: broken windows stay broken, a business shuts for repairs, the wounded recover, routines come back | States kept; recovery over days; save and load; repairs scheduled; consequences seen on return | Phase 5, with 5.5 and 5.9 |
| Systems interaction | One event through every system: a shot lantern falls, breaks, lights the floor, smokes, hides men, drives people out, blocks a door, and is remembered | Whether the whole chain runs with no special cases; which system fails first; the combined frame time | The Systems Playground (below), from Phase 3 on, growing each phase |

### The Systems Playground

One permanent place: a stretch of the street and a working saloon, three or four people, and
every approved system switched on. A feature proves itself in its own lab first, then has to
show it makes the playground better without breaking anything else. It's where the
systems-interaction scenarios run (the lantern chain; a shoved drunk through a table, his friend
reaching for a gun, the barman ducking, a deputy outside hearing it), where the playtest agent
plays a known setup every build, and the gate before a system goes into a mission.

It starts from the gunfight lab's street once its baseline is in, in `experiments/playground/`.

## Other labs

Two already exist; three more come later, each when its phase needs it.

| Lab | Status | When |
| --- | --- | --- |
| Ragdoll lab: how a man falls | Built, `experiments/physics_lab/` | In use for 3.1 now |
| Performance bench: every system against its frame budget | Built, `tools/perf_bench.gd` | Every merge |
| Fire lab: spread speed against fire-science figures, smoke filling, the look | New | Phase 4, after Gate C |
| Movement lab: walking, running and mocap on the skeleton | Started, `experiments/mocap_walk/` | Step 4.6, when you record |
| People lab: town life, memory, what people do the next morning | New; the memory store isn't built yet | Phase 5 |

Sound stays inside the gunfight lab for now (steps, cocking, shouts you can place). It gets its own lab only if that gap outgrows it.

## Order and cost

1. **Gunfight lab first.** It's step 3.0, the first step of Phase 3, and whether the game is fun is decided in its fights.
2. **Body lab beside 3.1,** reusing the ragdoll lab's harness, since falls and wounds meet there.
3. **Breakage lab before 3.3,** so furniture is built against numbers from the start.

All three are the gameplay lane's files, so they run one after another in that lane. Running them side by side would mean a separate lab lane, past the roadmap's two-lanes-at-a-time rule; only you can change that.

No paid calls: it's all simulation run headless. The cost is sessions out of the shared weekly usage, about one per lab to build the bench and its baseline before any fixing starts.

### Sources

Salt Creek repo, main at PR #154: `docs/ROADMAP.md` (Phases 2–3), `docs/briefs/three-gunmen.md`, `experiments/physics_lab/README.md`, `docs/LAYOUT.md` (structures, bodies, blast), `docs/prompts/STATUS.md`, `CLAUDE.md`.

## Since (Sean, 2026-10-21)

- Phase 1 is parked (the look is good enough to test with; Gate A is signed off before Phase 4),
  and ▶ Now is Phases 2 and 3 together, with **up to four sessions at once** in this phase, so
  the labs no longer have to wait for each other: each is its own folder and branch.
- In `docs/ROADMAP.md`: the gunfight lab is 3.0's arena, the body lab is 3.1b (beside 3.1) and
  the breakage lab 3.3a (before 3.3). Folders: `experiments/gunfight_lab/`,
  `experiments/body_lab/`, `experiments/breakage_lab/`.
- **Each lab's bridge commands live in its own folder:** `experiments/<lab>/bridge.gd`, extending
  `BridgeLab` (`src/debug/bridge_lab.gd`), names its commands in a `HELP` constant and answers them
  in `_cmd_<name>` methods. The dev bridge loads every lab's file when it starts, lists them in
  `help`, and refuses a name it or an earlier lab already has. A lab never edits
  `src/debug/dev_bridge.gd`, so labs running side by side don't collide.
