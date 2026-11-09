# Missions: the cards

One card a mission, every card the same shape, so missions can be compared, mapped (`MAP.md`)
and judged (`JUDGE.md`, results in `judged/`). Planning only: nothing here changes the game.
Started 2026-11-09 for issue #739.

## The rules for every card

- **Every line carries its status:**
  - **DECIDED**: Sean's call, quoted (or as a session recorded it) with its date and source.
  - **PROPOSED**: written down by Sean or a session as an idea, never confirmed. The line says whose.
  - **OPEN**: no source says, or the sources disagree. Where they disagree, every version is listed.
- **Never upgrade a line.** PROPOSED stays PROPOSED until Sean says otherwise, in his words, with
  the date. A session's "DECIDED" in another file (e.g. `config/valley.json`'s `status`) is quoted
  as that file says it, not taken as Sean's word.
- **Sean's words are copied, not rewritten.** Most of them reach us through session-written issue
  text ("Sean, 2026-11-04: …"). A card quotes them as written there and names the issue. Only text
  inside quotation marks in the source is treated as his own wording.
- **Nothing from the judge goes on a card** until Sean picks it. An idea he accepts goes on as his,
  with the date: "**DECIDED** (Sean, YYYY-MM-DD, picked from judged/<date>.md)".
- A card describes the design. It does not say how to build it (that's a brief's job), beyond
  naming the systems it needs.

## The template

Copy this for a new card (`docs/missions/<id>.md`; the id is lower-case with hyphens):

```markdown
# <Name> (`<id>`)

Other names: <names other sources use>. Sources: <issues, files>.
Status of the mission as a whole: DECIDED | PROPOSED | OPEN, with the quote.

## How you hear of it
(A rumour, a rider, a gunshot, a letter, Joe, a nudge. Never a quest marker.)

## The situation
(Who, where, what's at stake.)

## The ways to do it
(At least two that really differ.)

## The big choice and its cost

## What happens after, in the world
(Opinions, rumours, factions, people remembering, what stays broken.)

## Where on the map
(`config/valley.json` places and their heights; #736's places with height.)

## Which threads it moves
(The threads in `MAP.md`.)

## Which systems it needs
(Each: exists, being built, or new. The systems table in `MAP.md` is built from these.)

## Where the sources disagree
(Every version, marked OPEN.)

## Sources
```

Each line inside a section starts with its status word. Two sections are this planning session's
own reading, and say so at their top: **Which threads it moves** (a mapping onto `MAP.md`'s threads)
and **Which systems it needs** (each line ends with the system's state on main: exists, partly,
being built, decided (not built), or new).

## Where the words come from (read before trusting a DECIDED)

- Nearly every issue is written by a Claude session on Sean's account. "Sean, 2026-11-04: …" there is
  a session's record of a chat, not always his exact words. The cards quote that record and name it.
- **PR #621 (the November 3 design lock) is open, not merged.** The widow, her sons, the sheriff dying
  whatever you do and romance removed all come from it. `config/valley.json` already treats them as
  DECIDED; DESIGN.md on main doesn't have them yet. The cards mark them DECIDED "(lock, 2026-11-03)"
  and list DESIGN.md's older text beside them as OPEN.
- **#546 (the story goes open-ended) is open.** Its threads, nudges and "the story doesn't advance
  until it should" are Sean's (2026-11-01); the DESIGN.md diff that carries them isn't written yet.
  DESIGN.md's 30-day clock, ten-day shape and "act three" are still on main, so cards that use them
  flag it.
- The "planning doc" #546 cites ("the planning doc's mission 9") is Sean's own claude.ai document and
  isn't in the repo. Its other numbered missions may hold more than these cards do.

## The index

27 cards. "Shape" is how the mission is made: **story** (a thread's beat), **side** (a situation that
can land any time), **set piece** (a town event built from systems), **repeatable** (fights or jobs
that come back). Status is the mission as a whole; each card has the details.

| Card | Name | Shape | Status as a whole | Where |
|---|---|---|---|---|
| [`saloon-table`](saloon-table.md) | The Saloon Table (prologue, the card cheat) | story | PROPOSED (2026-10-15; ROADMAP 3.6) | the saloon |
| [`the-sheriff`](the-sheriff.md) | The Sheriff on the Road (the opening) | story | DECIDED (2026-10-01); his survival OPEN | `opening_site`, the doctor's |
| [`no-justice`](no-justice.md) | No Justice (the camp) | story | DECIDED (Sean's card, 2026-11-09) | the doctor's, Joe's camp, the bandits' hideout (OPEN) |
| [`joe-on-the-rope`](joe-on-the-rope.md) | Joe on the Rope (the rope shot) | story | DECIDED (2026-11-04) | OPEN |
| [`farmhouse-rescue`](farmhouse-rescue.md) | The Farmhouse Rescue (the widow's) | story | built (rancher); widow version DECIDED in the lock (PR #621, unmerged) | `widow_homestead` |
| [`buried-alive`](buried-alive.md) | Buried Alive (the cave-in) | story | PROPOSED (2026-10-06); `valley.json` DECIDED | `mine`, `ore_works` |
| [`barons-shipment`](barons-shipment.md) | The Baron's Shipment (the iron coach) | story | DECIDED (2026-11-09) as an idea; the spot and the trap OPEN | a road off `baron_ranch`, OPEN |
| [`bank-break-in`](bank-break-in.md) | The Bank Break-in (the Baron's papers) | story | PROPOSED (2026-11-04) | the bank |
| [`hell-on-wheels`](hell-on-wheels.md) | Hell on Wheels (the runaway payroll train) | story | DECIDED (2026-11-01; name 2026-11-09) | `bridge_b`, the line |
| [`the-bridge-is-out`](the-bridge-is-out.md) | The Bridge Is Out (the trestle finale) | story | DECIDED (2026-11-03/04; name 2026-11-09) | `bridge_c` |
| [`barons-house`](barons-house.md) | The Raid on the Baron's House | story | DECIDED (2026-11-04) | which house OPEN |
| [`the-trial`](the-trial.md) | The Trial, the Hanging and the Inquest | story | trial DECIDED (2026-10-01); Inquest PROPOSED | saloon or church |
| [`hold-him`](hold-him.md) | Hold Him Till the Marshal Comes (the jail night, the jailbreak) | side | PROPOSED (2026-10-06); the stone jail DECIDED | the jail |
| [`railhead-lynching`](railhead-lynching.md) | The Lynching at the Railhead | side | PROPOSED (2026-10-06); premise OPEN | OPEN |
| [`vaqueros-horses`](vaqueros-horses.md) | The Vaquero's Horses | side | PROPOSED (2026-10-06) | `baron_ranch` |
| [`kid-wants-out`](kid-wants-out.md) | The Kid Wants Out | side | PROPOSED (2026-10-06) | OPEN |
| [`fever-house`](fever-house.md) | The Fever House | side | PROPOSED (2026-10-06) | OPEN |
| [`tied-to-the-tracks`](tied-to-the-tracks.md) | Tied to the Tracks | side | DECIDED as an idea (2026-11-01); PROPOSED step 8 | OPEN |
| [`night-meeting-trap`](night-meeting-trap.md) | The Night Meeting That's a Trap | side | PROPOSED (2026-10-21) | the feed store |
| [`store-robbery`](store-robbery.md) | The Store Robbery | side | PROPOSED (ROADMAP 3.6) | the store |
| [`bank-robbery`](bank-robbery.md) | The Bank Robbery (the land money) | set piece | DECIDED (2026-10-01) as a moment; PROPOSED backlog | the bank |
| [`fire-night`](fire-night.md) | The Fire Night (the bucket line) | set piece | PROPOSED (2026-10-06); fire out of play | any building |
| [`dust-storm`](dust-storm.md) | The Dust Storm | set piece | PROPOSED (2026-10-06) | the saloon |
| [`cattle-drive`](cattle-drive.md) | A Cattle Drive Hits Town | set piece | PROPOSED (2026-10-06); cattle OPEN | `stock_pens`, saloons |
| [`stage-held-up`](stage-held-up.md) | The Stage Held Up | repeatable | DECIDED (2026-10-01) as a reason to fight | OPEN |
| [`the-bounty`](the-bounty.md) | The Bounty | repeatable | DECIDED (2026-10-01); ROADMAP 3.6 | `abandoned_homestead`, OPEN |
| [`small-fights`](small-fights.md) | Small Fights Out in the Valley (a family) | repeatable | DECIDED (2026-11-09) as an ask | #736's places |

### Folded into a card (another source for the same mission)

- "The camp" → `no-justice`. "The card cheat", "A Quiet Drink" (OPEN) → `saloon-table`. "The gut shot
  who talks", "the doctor's table" → `the-sheriff`. "The jailbreak", the water tower on the jail →
  `hold-him`. "The hanging" (backlog 4), "the Inquest" (P5) → `the-trial`. "The robbery of the land
  money" → `bank-robbery`. "The widow's burn-out night" (DESIGN.md §5) → `farmhouse-rescue` (OPEN,
  #622 item 9). The surprise assault, harder, Blue → `farmhouse-rescue`. The train robbery, the
  stick-up man, "Now what the hell is going on here?" → `hell-on-wheels` (OPEN whether one mission).
  "Dead Man's Crossing" (OPEN), "riding shotgun", the payroll on the road → `stage-held-up`. "Blood on
  Main Street" (OPEN) → `bank-robbery`. "A wanted man holed up" → `the-bounty`. Road agents, claim
  jumpers, rustlers, horse thieves, the feud, the drunk, outlaws camped, clearing the hideout, night
  riders at your spring, #463's fight sites → `small-fights`.

### Not carded (seeds, activities, moments)

Named ideas too thin to judge as a mission yet, or not missions. Each gets a card when Sean adds to it.

- OPEN, seed: **"The Missing Ranch Hand"** (Sean's brief, 2026-10-17, `docs/briefs/three-gunmen.md`
  §10, provisional): "An investigation with opportunities for observation, dialogue, stealth, and
  nonviolent resolution." Nothing more anywhere.
- OPEN, seed: **a witness/suspect dispute** (`docs/prompts/18_Emergent_Missions.md` scenario 3; Prompt
  16's "test offence with two witnesses"): a test scenario for the law, not a story mission.
- OPEN, superseded?: **"The railroad arrives"** (DESIGN.md backlog 7: "celebration, speeches, a shooting
  match, and outsiders' trouble"). #552 (Sean, 2026-11-04): the line already runs.
- Activity: **a turkey shoot / Fourth of July match** (DESIGN.md "Reasons to fight", decided
  2026-10-01). Activity: **payday** (`valley.json` `payday`, "DECIDED (#542, #276)"): the town's
  calendar, not a mission; it sets up `hell-on-wheels` and the rowdy saloons.
- Activity: **work that pays** (DESIGN.md: deputy shifts, riding shotgun, freighting, a barn raising).
- Moments, not missions: the rest of `docs/briefs/showcase-moments.md` (the balcony, the piano player,
  the shot lantern, the bluff, hide and search…). They are what the missions are built from.
- Story beats, not missions (#546 P2–P9, all PROPOSED, none accepted): Harlan's past found through
  play, the Baron met early, Rourke's "Do your duty, Sergeant", the last dream, quiet scenes, Harlan's
  rare lines. They go on `MAP.md`'s threads.
