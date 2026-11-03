# The widow's farmhouse: two rescues, and her sons (brief)

Source: Sean's design lock of 2026-11-03 ("Salt Creek — November 3 Design Lock & Claude Handoff").
It supersedes the farmhouse mission's story identity (the Mexican rancher as hostage, #520) and
extends the mission; the mission's systems (#520, #537, #565) are kept. Status words as in the lock:
**DECIDED** (Sean's, not reopened without asking), **PROPOSED** (an option, not canon), **OPEN**
(needs Sean's call before canon or costly work). Nothing here invents names, dialogue or places.

Read with: `src/missions/` (LAYOUT.md "src/missions (the farmhouse)"), `experiments/farmhouse/`
README, `docs/briefs/valley.md` (where the homestead is), `docs/briefs/town-economy.md`.

## 1. Story and place (DECIDED)

- The widow's homestead **is** the farmhouse of the hostage rescue, not a second farm.
- She lives there with **two young sons**. They are portrayed with Sean's own boys' likenesses and,
  where practical, their own motion-capture performances (§5).
- **The widow is the first hostage**, replacing the Mexican rancher of the current prototype. Keep
  the mission's systems; change who it's about.
- **The Baron wants her land for its water rights.** His gunmen occupy the property to pressure her
  into giving it up.
- **An earlier, peaceful visit** about the land dispute shows Harlan the widow, the boys and the
  property (back entrance, kitchen, yard, outbuildings) before the mission, so knowing it helps.
- Where it is, the eastern wagon road and the small overpass: `docs/briefs/valley.md`.

## 2. The mission: two linked phases (DECIDED)

**Phase A, the house.** Baron-associated armed men hold the house with the widow inside. Harlan
watches and picks his way: the front (dangerous), the back door and stealth, other openings, or a
dynamite breach once demolition has been taught elsewhere. Reuse the house, its layout and the
squad's coordination. Enemy awareness comes only from evidence (sight, sound, a report); stealth
never fails just because the mission moves on.

**Phase B, the yard.** Freed, the widow tells Harlan her boys are held elsewhere on the property.
The mission isn't over. Harlan crosses the yard and outbuildings and defeats, slips past or
otherwise gets by a second group of armed men: an exterior fight of fences, wagons, woodpiles,
sheds and ground, readable and different from the house's close quarters. He reaches the sons and
brings them back to their mother. **The reunion completes the mission.**

Immersive-sim rules (DECIDED):
- A careful player can reach the house unseen and surprise the first defenders.
- The boys' guards are **on the property from the start**, placed and accounted for, never spawned
  because the widow was freed. They react to what they perceive or are told: a quiet rescue can
  leave them unaware for Phase B; a loud fight can alert them.
- Several routes, destructible structures, the player's own plan; no cutscene solution.
- No child-damage countdowns, and no moments implying either boy can be killed.

OPEN: the widow's lines; how many men in Phase B and where they stand before it; which outbuilding
holds the boys; the boys' names and personalities; whether Joe comes along.

## 3. The boys are protected actors (DECIDED, an absolute gameplay requirement)

Both sons are **protected, non-damageable NPCs by construction**: not hostages or townsfolk with
huge health or a temporary invulnerability flag.

- No health, wounds, bleeding, pain, death, dismemberment or ragdoll; no injury animations, blood
  decals or hurt voice lines.
- Never a target: no enemy targeting, threat or hostage-execution logic can name them.
- Bullets, explosions, fire, breakage, debris, collisions and physics produce no injury or death
  state in them, and they can't be used as damageable props or physics casualties.
- The rescue is about getting through the men, not keeping a health bar up.
- **No softlocks:** if debris blocks the way or navigation fails, the rescue and reunion still
  complete safely (e.g. the reunion happens once Harlan reaches them or the area is clear). The
  simulation never traps or endangers them.
- **A dedicated protected-child actor class** with no hooks into the damage, medical or anatomy
  pipelines, plus automated regression tests for projectile, explosion, fire, environment and
  AI-targeting immunity and for correct mission completion.
- No graphic threats or child injuries staged for tension. No system may treat them as combatants.

Realism: source code can always be edited. The goal is that normal play, scene composition, AI,
combat, physics and mission scripting **cannot** damage them, and tests catch any regression.

### How the code makes that true (PROPOSED engineering, to review before building)

What the review of the current code found (2026-11-03):
- Every damage path finds people by the `people` group and/or `is HumanBody`: `Ballistics`
  (`ballistics.gd`), `Blast.gather` (`blast.gd`), `FireSystem` (`fire_system.gd`), `GlassCuts`,
  `FloorMarks`, the train (`train.gd`), `PlayerShove`/`HumanBody.take_push`, `BodyImpacts`.
- Bullets use `Layers.BULLETS` (everything but PEOPLE and WALK: the parts' own layer is hit);
  debris and dynamite use `Layers.DEBRIS_MASK`.
- `OutlawBrain` only targets `Player` or `HumanBody`; the guard's threat is `menace` / `hold.spare`
  on a HumanBody; `Senses` reports `spotted` for players and HumanBodies.

So the boys are **not HumanBodies**:
1. `ProtectedChild` (`src/people/protected_child.gd`, `extends Node3D`): a skinned mesh, an
   AnimationPlayer for captured clips, a route follower over `Waypoints`, look-at. No `Anatomy`,
   `Physiology`, `PlayerWounds`, wound signs, blood or ragdoll; no `hit`/`died` signals; never in the
   `people` group (its own group, `protected`).
2. **Its own collision layer** `Layers.PROTECTED` (new bit), outside `BULLETS`, `DEBRIS_MASK` and
   every blast/fire/sight query. It stands on the ground by a down ray and moves kinematically; no
   rigid or soft body, so nothing can push, crush or throw him.
3. **A guard in HumanBody:** `HumanBody._ready` refuses (push_error, test failure) a `person_id` in
   `ProtectedChild.IDS`, so a scene or config can't build a boy as an ordinary person by mistake.
4. **Mission side:** the boys are never in `brains`, `hold.spare`, `menace` or any target list; the
   end rules don't read their state, only where Harlan and the widow are.
5. **Softlock fallback:** each boy's route to his mother is checked (`Waypoints.route` plus a clear
   capsule sweep against the PROTECTED-standing mask); blocked, stuck for N s, or unreachable, the
   reunion stages where he is (mother comes to him, or a short fade), never waiting on physics.
6. **What a bullet does near him** (OPEN, small): passes through (cheapest, may read oddly), or
   strikes a cosmetic, damage-free stop. Either way no wound, blood or reaction of hurt.

Tests (`tests/test_protected_child.gd`), run with the rest:
- the class: not a HumanBody, not in `people`, no damage methods/signals, layer outside `BULLETS`,
  `DEBRIS_MASK`; a source check that it never references Anatomy/Physiology/wound/blood code;
- a revolver and a shotgun fired through him (Ballistics): no hit on him, nothing drawn on him;
- dynamite at 0.5, 2 and 5 m (Blast): nothing; fire on (`FireSystem.in_play`) beside him: nothing;
- rubble dropped on him and a wall collapsed over his route: nothing, and the reunion completes;
- an OutlawBrain with him in plain sight: never a target, threat or spare; `Senses.spotted` silent;
- HumanBody with a protected `person_id` fails;
- the mission: widow freed → Phase B → boys reached → reunion → WON, quiet and loud, and with the
  route blocked.

## 4. Implementation plan (PROPOSED: smallest change set, in order)

Reuse first (PARTS.md): `FarmhouseMission`, `HouseDefence`, `OutlawBrain.hold`, the rovers' beats,
`HostageBrain`, the farm's places, the farm bot and `run.py`. No second mission system.

| Step | What | Done when |
|---|---|---|
| A1 | **ProtectedChild** + layer + HumanBody guard + its tests (§3). A grey stand-in child mesh (§5: not a scaled man). | All immunity tests green; nothing else changed. |
| A2 | **The widow as hostage:** the hostage's identity as data in `config/farmhouse.tres` (id, model, lines) not code; `widow_s6_talking` (on main) in the chair; the mission's lines retitled (placeholders, marked, until Sean writes them). The town's rancher no longer taken from the livery. | Every existing farmhouse test and the scripted runs unchanged but for names. |
| A3 | **Phases in the mission:** `State.ON` gets a phase (HOUSE, YARD, REUNION). Widow clear of the house no longer wins: it starts YARD. WON only at the reunion. Lost stays: Harlan down, or the widow dead. | A test walks HOUSE → YARD → REUNION → WON. |
| A4 | **The second group:** men from a new `tuning.yard_men` list, placed at `begin()` round the outbuilding (posts and beats, as the rovers), with their own `HouseDefence`-style group. **The alarm becomes per group** (today `_alarm` provokes every man and tells them where you are: fine inside one small house, omniscient across a yard): the yard group learns only by its own Senses or a report (a man from the house who saw you running to them, or a shout within earshot). | Scripted runs: a quiet Phase A leaves the yard group unaware ≥ 6 of 8; a loud one alerts them by hearing, not by the mission. |
| A5 | **The boys at the outbuilding and the reunion:** two ProtectedChild at the hold spot (cower/sit clips, no harm states); reached and the yard clear (or Harlan beside them), they go to their mother by the checked route or the fallback. | Reunion tests incl. blocked route; no mission path reads a boy's state. |
| A6 | **The peaceful visit:** the farm outside the mission: the widow and boys at everyday routines (`CivilianBrain.chores` at the farm's use points; the boys' idle clips), the land-dispute talk as the mission's offer (instead of the blacksmith). | You can walk round the property and meet them with no mission running. |
| A7 | **Measure:** the farm bot's runs over both phases (wins, which way, the yard's awareness at the switch, time); a blind playtest; Sean's play. | Report in `experiments/farmhouse/results/`. |

A1 before anything else; A2-A3 one session; A4-A5 one; A6 after the valley outline places the
farm (#467). The outbuilding itself waits on Sean (OPEN): until then a grey box at a PROPOSED spot.

## 5. The boys' likeness and capture

DECIDED: the boys are part of Salt Creek, with recurring everyday behaviour at the homestead before
and after the mission, and they contribute motion capture if practical.

PROPOSED capture route (after one short test): iPhone on a tripod, full body, good light; each boy
on his own doing short, natural, age-appropriate moves (walk, jog, wave, sit on the porch, play,
point, pick up a small thing, greet Harlan, run to his mother); one ~10 s clip through Rokoko Vision
3 first; cleaned and retargeted in Blender onto a **child-proportioned rig**; a whole reunion taken
as reference, separate takes aligned and contacts fixed by hand.

**Privacy rules (DECIDED in the lock; how they meet this repo):**
- This repo is **public**. The usual mocap path (`assets/mocap/raw/`, CLAUDE.md) is **not** for the
  boys: their raw footage, reference photos and raw captures never go in this repo or a build.
  Keep them off the repo entirely, or in the private Studio repo only if Sean says so.
- Only processed, approved game assets (retargeted clips, the finished model) come here, and only
  once Sean approves each one.
- Any third-party upload (Rokoko's cloud, Rodin, Tripo) needs the parents' consent first.

OPEN: the likeness approach and character designs, names, voices, the capture software after the
test, the clip list. A man's model scaled down won't read as a child; the rig and model need child
proportions from the start.

## 6. Conflicts with what's built (for Sean)

- DESIGN.md §5 and docs/TOWN.md had the widow "alone": updated to the lock.
- The occupiers: the code's are the Colter gang (Brody, Lyle, Dutch, the Kid, Hollis) held out of
  town by `TownLife.take_riders`; the lock says the Baron's gunmen. DESIGN.md has the Colters
  "hired to scare homesteaders off". OPEN: the Colters on the Baron's pay, or the Baron's own men.
- The intro line ("You're the one with the spring claim?") and the blacksmith start are from the
  prototype; A6 replaces the start.
- DESIGN.md §5's story flow still has "the gang burns out the widow on day 9". OPEN: does it stay
  as another thread, or does the occupation replace it (and #546's open-ended story)?
- The mission's lost conditions in Phase B: the widow could die there under the current rules
  (she follows Harlan, crouched). OPEN: does she follow, stay hidden, or wait at a safe spot; and
  is her death in Phase B a loss.
- `#573` (is the farmhouse the right kind of hard) is still waiting: A2-A5 change the mission's
  length; the house's dials should be settled first or kept as they are.
