# The Farmhouse Rescue (`farmhouse-rescue`)

Other names: "the farmhouse hostage rescue" (#520), "the widow's farmhouse" (PR #621), "Farmhouse
hostage rescue (Phase A house, Phase B yard to the boys)" (`config/valley.json`). Sources: #520,
#537, #565, #573, #622, #689, #728, #540, #731; PR #621 (`docs/briefs/widow-farmhouse.md`, not
merged); `experiments/farmhouse/README.md`; `docs/briefs/valley-plan.md` §6.

- DECIDED, built: the prototype with the rancher as hostage (#520, PRs #521, #525; build 2875), the
  surprise assault (#537, PR #554), harder (#565, PR #568, build 2974). The first mission in the game.
- DECIDED (Sean's design lock of 2026-11-03, as PR #621 records it; the PR is open, not merged): the
  widow's farmhouse, Phase A the house, Phase B the yard to her boys. `config/valley.json`: "DECIDED
  (PR #621 widow-farmhouse.md)".

## In Sean's inventory (2026-11-09)

From `sources/inventory_2026-11-09.md` (Sean's "tentative mission layout").

- DECIDED (inventory, "Approved · Prototype developed"): "Bandits take the widow hostage at her
  homestead east of Salt Creek." "The property sits beside the creek, north of the railway."
  "Approximately four or five enemies occupy the farmhouse." "The front approach is dangerous and
  heavily covered." "The player can assault the front or circle around the property." "A preferred
  creative solution is placing dynamite against the rear wall, blowing a hole in the building and
  entering through it." "A stealth approach remains possible if the gang hasn't spotted Harlan." "The
  player must defeat the captors and rescue the widow." "The environment should react to the damage
  rather than relying on a single scripted breach."
- OPEN (inventory): "The widow's children may also feature, alongside Blue, the family animal, but the
  precise family setup remains unresolved." And (continuity): "We established that the widow is the
  murdered sheriff's wife and that his murder is connected to her. We subsequently considered making
  her and the children Harlan's own family instead. That potential change must be resolved".
- DECIDED (Sean, 2026-11-09, in chat on No Law, the same day): "Yes the children are the sheriffs /
  widows kids". (Answers the inventory's question unless Sean says otherwise.)
- OPEN: "Bandits" (inventory) / the Colters / the Baron's own gunmen (the lock, #622 item 7).
- OPEN: Phase B (the boys held in the yard, the lock) isn't in the inventory's version.
- PROPOSED (inventory, Part 4): Act II, after Buried Alive and the Demolition Mentor.

## The story's spine: Sean's picks (Sean, 2026-11-09)

From the story judge (`judged/2026-11-09_story.md` §2), Sean: "Yes I like the ticks". Its frame: the
Baron wins if Salt Creek looks lawless enough that soldiers are sent to restore order; Rourke is the
officer he pays to bring them. (OPEN: Sean took the three changes below; the frame sentence itself he
hasn't confirmed in words.)

- DECIDED (Sean, 2026-11-09: "I like the baron offering to buy"): **the Baron at the sheriff's funeral**, quietly
  offering to buy the widow's claim. He gets a face in Act I, and the farmhouse becomes his answer to
  her refusal.

## Version 2: Sean's pick (2026-11-09)

Sean, 2026-11-09: "Sounds good but make sure our ideas are actually implementable". Version 2 is
`proposals/farmhouse-rescue_v2.md` (judged 26/35, from 19), with its build check. DECIDED (Sean,
2026-11-09) as below, in build order; the judge's three ticks were not picked (PROPOSED at the end).

**Build now, on the built mission** (about 2 medium, 4 small):
- The hostage is the widow (the lock); the Colters on the Baron's pay hold the house, the Kid on the
  porch.
- The Baron's foreman walks up the lane at a set time to have her sign her water right over (the
  Baron's answer to her refusal at the funeral). In 1882 Colorado the first to use water owns it
  (*Coffin v. Left Hand Ditch Co.*, 1882): the sheriff's family dug first, so the Baron needs her name.
  The paper is a deed, signed before an officer and recorded (not a "bill of sale").
- The ways: the front, the back, the wall (built); stop the foreman on the lane; walk him in at
  gunpoint (the men hold fire while he's near you); let her sign (the foreman reaches her table, the gang
  leaves, nobody hurt, the Baron has the water).
- How you hear: she isn't at the store on her day (the storekeeper says so); a rover drinks in town and
  talks; the men's own talk about the foreman can be overheard on site.
- Fight now and her life is at risk (the guard's clock); let her sign and everyone lives.
- No phase machinery: the yard men are placed from the start; it ends when the family is together and
  no captor stands.

**Later, when the game can carry it:**
- The Kid talked down with a nod (needs the nod and a deed); prisoners to the jail as witnesses (needs
  the jail); the blown wall staying, her memory of how you came, the town hearing it, the paper's later
  effects (need saves and story state); the boys held in the yard (need child bodies and
  `ProtectedChild`); Blue (needs animals); the train crew seeing it (needs G6 and news passing).

**Changed by the build check:** "sells" is "tells" (no money in the game); "the door opens" is "they
hold fire" (doors have no leaves); Blue as a way to hear of it is cut (Blue stays in the design, #728).

PROPOSED (the judge's ideas, not picked): a notary riding with the foreman (medium; his witness needs
saves); the foreman's errand visible in town (small); the deed travelling to the county seat by train
(large, after G6 and train step 7).

## How you hear of it

- DECIDED, built: walk up to the blacksmith by the livery before the gang rides in (#520).
- DECIDED (lock, 2026-11-03): she is "not met as a widow before the opening. Order: the peaceful
  visit, then the hostage crisis." "Her lines follow the help-or-leave deed from the opening."
- PROPOSED (PR #621, step A6): "the peaceful visit with `CivilianBrain.chores`; the offer replaces the
  blacksmith start."
- PROPOSED (#546, 2026-11-01): "Arrivals by rail" and nudges can bring a thread's beat.

## The situation

- DECIDED (lock, 2026-11-03): the widow is "the murdered sheriff's wife; refuses to sell the family's
  claim; she lives on it with their **two young sons**". "The Baron wants her land for its water
  rights, and his gunmen occupy it to make her give it up."
- DECIDED (Sean, #700, as `valley.json` records it): "her water right is the valuable one and the
  reason for the murder".
- DECIDED (lock): "**The widow replaces the Mexican rancher as the first hostage**" ("Keep the
  mission's systems; change who it's about").
- DECIDED, built: five men hold the house (Brody the guard held to the bedroom, Lyle and Dutch at the
  front windows, the Kid on the porch, Hollis in the kitchen) and two rovers on the yard (Pike, Wes;
  #565).
- DECIDED (#540, Sean 2026-11-01): the house should look like "a family has lived in for 14 years".
- DECIDED (Sean, 2026-11-09, #728, as recorded): Blue, the widow's dog: "**He can never be hurt or
  killed**"; "He barks at strangers, follows the boys, and reacts in the farmhouse rescue (#537): he
  gives the gang's position away, or the player's."

## The ways to do it

- DECIDED, built: the front door ("they warn you off first if your gun is away"); the back door,
  quietly round the north; dynamite planted on a wall (#506).
- DECIDED (Sean, 2026-11-01, as #537 relays it): "the dynamite way is a surprise assault. You set the
  stick on a back wall without them knowing. You get to a hiding spot, and the wall going up is the
  first they know of you."
- DECIDED (lock): Phase A: front (dangerous), back door and stealth, other openings, or a dynamite
  breach "once demolition has been taught elsewhere". The peaceful visit "shows the property's ways in
  first: the back entrance, kitchen, yard and outbuildings".
- DECIDED (lock): Phase B: "Once freed, the widow says her boys are held elsewhere on the property."
  "The fight is outdoors: fences, wagons, woodpiles, sheds." "A second group of men is on the property
  from the start, never spawned, and is alerted only by evidence." "Harlan brings the boys back. **The
  reunion completes the mission.**" "No child-damage countdowns."
- PROPOSED (#563, idea, Sean 2026-11-01): silent takedowns; first test on "round the back, quiet".

## The big choice and its cost

- DECIDED, built: the guard puts his gun on the hostage after two men are down, and kills her "once
  you're in the house and 20 s have passed since the alarm, or when he's the last man", after a 5 s
  warning. Speed against care.
- OPEN: no moral choice is named (e.g. sparing or killing the men who surrender, the Kid among them).

## What happens after, in the world

- DECIDED (lock): the boys are protected: "never hurt, never a target, by how they're built".
- PROPOSED (PR #621): "Lost if Harlan is down or the widow is killed (open for Phase B); the boys never
  enter the lost conditions."
- OPEN: the widow's view of Harlan afterwards, the Baron's reaction, the gang's men taken or dead.

## Where on the map

- DECIDED place / PROPOSED exact: `widow_homestead` (1712, -560), pad 34 × 30 at y -10, "east of town,
  north of the railway, near Salt Creek with creek frontage, on the eastern wagon road past the
  overpass". Reached by `widow_lane` off the East Road, over Bridge A then the overpass.
- PROPOSED (valley-plan §6): ways in "the front from the lane; the rear up from the creek and canyon
  mouth; the side from the overpass road; and from above, the rail bench and overpass look down on the
  yard"; the outbuildings and Phase B's hold north-east toward the creek.
- DECIDED, built: today in the old town on its knoll east (`config/town.json` `Farmhouse`); G6 (#731)
  moves it to the widow's pad.

## Which threads it moves

_PROPOSED: this session's mapping from the sources (threads in `MAP.md`); lines without a status word are that mapping._

- The widow and her water; the Baron; the sheriff (his family); the gang (the men who hold it).

## Which systems it needs

_PROPOSED: this session's reading of what the ways above need. Each line ends with its state on main, 2026-11-09: exists, partly, being built, decided (not built) or new._

- `Farmhouse`, `FarmhouseMission`, `HouseDefence`, `HostageBrain`, `OutlawBrain.hold`, glass that
  sees and shoots through, planted dynamite: exists.
- `ProtectedChild` (PR #621 A1): new.
- Phases (HOUSE / YARD / REUNION), yard men with their own alarm: new (A3, A4).
- The peaceful visit (chores, an offer): new (A6).
- Blue the dog, protected: new (#728).
- Lived-in props (#540): new.

## Where the sources disagree

- OPEN (#622 item 7): who holds the farm: "the Colter gang on the Baron's pay (today's code) or the
  Baron's own hands" (the lock says the Baron's gunmen; DESIGN.md has the Colters "hired to scare
  homesteaders off").
- OPEN: the hostage: the rancher (code) / the widow (lock, not built).
- OPEN: the start: the blacksmith (code) / the peaceful visit and offer (A6).
- OPEN: breach timing: from the start (code) / "once demolition has been taught elsewhere" (lock).
- OPEN (#622 item 9): DESIGN.md §5's "the gang burns out the widow on day 9" (story flow, decided
  2026-10-01) / the occupation.
- OPEN: "no corral at the farm" (#565) / fences, corral (#540, Phase B).
- OPEN (#573, waiting on Sean): is it the right kind of hard (A keep, B no floor fight, C less nerve,
  D one rover)?
- OPEN (#622): where the boys are held; whether Joe comes; Phase B's men; the widow in Phase B; a ball
  at a boy.
- OPEN (#689): men taken away at the mission's start while you watch.

## Sources

#520, #537, #565, #573, #622, #689, #728, #540, #731; PR #621; `experiments/farmhouse/README.md`;
`docs/LAYOUT.md` "src/missions"; `config/valley.json`; `docs/briefs/valley-plan.md` §6, §10.
