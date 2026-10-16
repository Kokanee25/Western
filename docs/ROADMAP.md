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
  main.
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

| Phase | What it proves | Lanes | Gate |
|---|---|---|---|
| 0. Clean slate | the build is trustworthy | gameplay | main green 3 nights |
| 1. The look | it looks like the paintings | art, characters | A: Sean's yes on the shots |
| 2. The place | a block of town worth standing in | art, characters | B: the block at four hours |
| 3. The feel | a fight in the saloon is physically real | gameplay (+ art for fixes) | C: five ways the fight can go |
| 4. Consequence | what you do changes how people treat you | gameplay | D: the slice, played blind |
| 5. The story's door | the opening of the real game | gameplay, characters | E: content complete |
| 6. The demo | a stranger can play it | all, in turn | F: the demo ships |

---

## Phase 0: Clean slate

Lane: gameplay. Art and characters finish what they have open and stop.

| # | Step | Done when | Who |
|---|---|---|---|
| 0.1 | **Green and quiet** | Main green, and the nightly soak and visual checks green three nights running. Any flaky test fixed, or quarantined with a note saying why. | gameplay |
| 0.2 | **Sean's open list cleared** | Every "Waiting on Sean" in CLAUDE.md's Current state answered or moved to the backlog. | Sean |

## Phase 1: The look

Lanes: art and characters. Gameplay parked. **Gate A: the look is locked.**

The approach is settled (the paintings' squares on the surfaces, smooth light, faces by
`tools/characters/RECIPE.md`). This phase makes it right in the game's own light, not a new style.

| # | Step | Done when | Who |
|---|---|---|---|
| 1.1 ✅ 2026-10-15 | **The targets locked** | One folder, `docs/concept/targets/`, holds the pictures the game is judged against: a man close at a table, the saloon at night, the street at golden hour, a wall and a post up close, a prop. Each has its three biggest gaps written beside it, from a render made today. One session. | art |
| 1.2 | **Faces in the game's light** | A portrait man in the saloon at night and on the street at golden hour: no burnt orange, eyes readable under the brim, skin matching his portrait's lit and shadow cheeks. Measured with `tools/face_light.py`, judged on a sheet. | art (light), characters (paint) |
| 1.3 | **The man complete** | The bold cowboy whole: the portrait's hat (brown, dented crown, studded band) as its own piece that can be shot off, his hair edges, coat, vest, shirt, tie and hands as separate pieces, through the pose check (stand, sit, hands up, crouch, back) with no tears. | characters |
| 1.4 | **Surfaces to the man** | Wood, end grain, posts, planks and the road at the same square size and finish as his face and coat: they look like one picture, close and far. | art |
| 1.5 | **Gate A** | Two fixed shots, the man at the saloon table and the street at golden hour, side by side with their targets. Sean says yes. Then: goldens re-approved, the look's settings frozen, and later changes only to close a gap Sean names. | Sean |

## Phase 2: The place

Lanes: art and characters. **Gate B: the block at four hours.**

A small block finished to the look, not the whole town: the saloon, the store, the telegraph,
the jail and the livery, and the street between them.

| # | Step | Done when | Who |
|---|---|---|---|
| 2.1 | **The cast by recipe** | Brody, Lyle and the storekeeper made by `RECIPE.md`, each within ~2 h of session and ~$2, each passing the pose check and the art session's look. The recipe's real test: a fresh session makes the third man from the recipe alone. | characters |
| 2.2 | **Townsfolk** | Eight background people, cheaper than principals (shared bodies and wardrobe, their own faces), different enough that the street isn't brothers. | characters |
| 2.3 | **The saloon finished** | Outside and in, to its set-direction card (`docs/briefs/set-direction.md`): lit, dressed, the critic's top three closed. | art |
| 2.4 | **The block finished** | The store, telegraph, jail and livery to their cards: fronts, signs, what's seen through the doors, the street's dressing. | art |
| 2.5 | **Light across the day** | Dawn, noon, golden hour, night, and inside, each a fixed view with a golden image. None of them breaks the look. | art |
| 2.6 | **Gate B** | A walk down the block at each of the four hours (the tour video), a blind critic's report, and Sean's yes: "it looks like the game". | Sean |

## Phase 3: The feel

Lane: gameplay. Art only to fix what this phase breaks. **Gate C: five ways the fight can go.**

The scene: the saloon, the gang at the bar, you at a table. Everything in it should behave as
it would.

| # | Step | Done when | Who |
|---|---|---|---|
| 3.1 | **Motion** | Sean records the shot list in `docs/MOCAP.md` (walk, run, turn, idle, sit, stand up, draw); it's retargeted and the people move by it, with procedural breathing, aim and flinches on top. *Needs Sean's recording time: book it at the start of the phase.* | Sean, gameplay |
| 3.2 | **Falls and hits** | Prompt 09: the ragdoll lab's faults fixed against its baseline (no folding straight down, no limbs through the body, joints in their limits), and hit reactions short of a fall. | gameplay |
| 3.3 | **Hands on the world** | Pick up, carry, drop, throw, open, close: doors, bottles, chairs, a hat off the floor. It feels natural with mouse and controller. | gameplay |
| 3.4 | **Guns agreed** | Revolver and shotgun against the feel ranges, every range `proposed` agreed or changed by Sean after he plays. | gameplay, Sean |
| 3.5 | **Furniture** | Tables tip, chairs break, doors give way, by how they're built, and men use them as cover. | gameplay |
| 3.6 | **Shoves** (Sean 2026-10-15) | You can shove a man (a key, a short reach), and people shove each other with the same physics. He staggers, catches himself, or goes down by how hard, how braced and how hurt he is, and into whatever's there: through a chair, onto a table that breaks, down the stairs, off the boardwalk into the street, leaving his print in the dust where he lands (the dust decal is art's). It's a deed, as now: the room sees it and it moves the escalation ladder. Needs 3.2 (falls) and 3.5 (furniture). | gameplay, art (the print) |
| 3.7 | **Inside the budget** | The fight with a fire in the room fits the frame budget on Sean's PC (his F3 readout, not this workspace's guess). | gameplay |
| 3.8 | **Gate C** | The saloon fight played five ways (they back down; you shoot first; they surrender; one flees; the room catches fire), and a man shoved into a table, by the playtest agent, then Sean. All five hold up. | Sean |

## Phase 4: Consequence

Lane: gameplay; characters for voices. **Gate D: the slice.**

The first complete scenario: the gang leaning on the storekeeper. It's the closest to built.

| # | Step | Done when | Who |
|---|---|---|---|
| 4.1 | **Money** | M4 step 5: a purse of coins, the barkeep's prices and tabs, "a round on me". | gameplay |
| 4.2 | **Acts, and the first: the saloon table** | A way to write little acts as data (who goes where, says what, beat by beat, and what hands back to the systems when you interfere: DESIGN.md §5 "Story shape"), and the prologue written in it: you at the card table, the stranger sits down and talks, a shooting at the bar that plays out however you handle it. Sitting at a table, for you and for people, comes with it. | gameplay |
| 4.3 | **Talking** | M4 steps 7 and 9 for the prologue: written lines for its cast, voiced (ElevenLabs, budget stated first); what you type or say read into a deed. | gameplay, characters (voices) |
| 4.4 | **Witnesses and memory** | M4 step 8: who saw what, who heard about it, and it changes how they treat you. | gameplay |
| 4.5 | **The jail and the doctor** | An arrested man stays jailed; the wounded are treated; you sleep in a bed and wake at the doctor's if you went down. | gameplay |
| 4.6 | **Saving** | The outcome survives sleeping, quitting and loading. | gameplay |
| 4.7 | **Gate D** | The prologue and on into the next morning, 20–30 minutes, played blind by the playtest agent (report in `docs/playtests/`), then by Sean. | Sean |

## Phase 5: The story's door

Lanes: gameplay, characters. **Gate E: content complete.**

| # | Step | Done when | Who |
|---|---|---|---|
| 5.1 | **The sheriff opening** | M5: you find him on the road at dawn, treat him, his words follow his blood loss, the ball the doctor digs out is evidence. | gameplay, characters |
| 5.2 | **A day for everyone** | The block's dozen people work, eat, drink and sleep on routines, and break off from them when something happens. | gameplay |
| 5.3 | **The law answers** | The sheriff (or his deputy), the gang and the town respond to what they witnessed, the same day and the next. | gameplay |
| 5.4 | **A second act** | The store robbery (Brody's gang and the storekeeper, every way out working: pay, talk, threaten, fight, arrest), or whichever act day 2 needs. | gameplay |
| 5.5 | **The next morning holds** | Three different playthroughs, each followed into the next day: what changed makes sense every time. | gameplay |
| 5.6 | **Gate E** | Every scenario and ending the demo has is in and playable start to finish. | Sean |

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

- **Phase 0, step 0.1** (gameplay): green and quiet.
- **Then Phase 1:** 1.1 ✅ (art, 2026-10-15: `docs/concept/targets/`). **1.2**: the painted cowboy
  in the game (#124); the street's light fixed 2026-10-16 (the sun's own ceiling, face 0.61 -> 0.92,
  the saloon 1.03 as before; `docs/screenshots/painted_light/in_game_sun_limit.jpg`); waits on
  Sean's eye. **1.4** (art): the road to Sean's target (#130, build 1280), the woods smooth again
  (painted illustration), the painted sky and a slight haze (`docs/screenshots/sky/`); waits on
  Sean's word. **1.3** (characters) beside it.

## Decisions Sean can change

- The look is painted illustration (Sean, 2026-10-16; DESIGN.md §4): smooth painted surfaces,
  the squares retired surface by surface (road and wood done, the men's clothes in 1.3). Gate A
  (1.5) is judged on it, its street target brought into line.

- The story's shape is a rough idea (DESIGN.md §5 "Story shape", 2026-10-15): ten days of about
  an hour, opening at the saloon table, then the sheriff on day 1. The demo is the prologue and
  day 1; the store robbery is the second act (5.4). All of it may change.
- The block is five buildings. Anything more waits until after Gate B.
- No new systems before Gate D unless a step needs one. DESIGN.md §11's backlog and
  `docs/prompts/` stay frozen until a step names one.
