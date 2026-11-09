# The Saloon Table (`saloon-table`)

Other names: "the prologue" (DESIGN.md §5 "Story shape"), "the card cheat" (showcase moments), "A
Quiet Drink" (`docs/briefs/three-gunmen.md` §10, possibly the same). Sources: DESIGN.md §5 (Sean,
2026-10-15); `docs/briefs/showcase-moments.md` (Sean, 2026-10-21); ROADMAP 3.6;
`docs/briefs/three-gunmen.md` (Sean's brief, 2026-10-17).

- PROPOSED (DESIGN.md "Story shape", Sean 2026-10-15: "nothing set in stone, just a rough idea, all
  may change"): "**It opens at the saloon table** ... the evening before day 1, the concept painting's
  shot."
- PROPOSED (ROADMAP 3.6): one of the three rough missions: "**the saloon table** (the stranger talks, a
  shooting at the bar)".

## Sean's idea, 2026-11-09 (under review)

- PROPOSED (Sean, 2026-11-09): "the mission no law is at the start of the game the first night in the
  saloon after bringing in the sheriff - it's more of a cut scene than anything - but maybe red shirt
  can be the one that comes into the saloon and kicks out the chair and murders the card cheat"
- OPEN: whether "No Law" is this mission's name (it reads as the saloon night).
- OPEN: the order. DESIGN.md (2026-10-15) has the saloon table the evening *before* the sheriff;
  Sean's idea has it the first night *after* Harlan brings the sheriff in.
- OPEN: "more of a cut scene" vs DESIGN.md "Little acts in the world, not cutscenes" (Sean,
  2026-10-15: acts "that hand back to the systems the moment you interfere").
- OPEN: whether the stranger (too curious about the sheriff and the spring) stays in the scene.


- PROPOSED: it is where the game starts; no lead needed.

## The situation

- PROPOSED (DESIGN.md, 2026-10-15): "The stranger sits down across from you and talks (friendly, too
  curious about the sheriff and your spring); a shooting breaks out at the bar and plays out however
  you handle it."
- PROPOSED (showcase, Sean 2026-10-21), the card cheat: "A man at the saloon table playing cards; he
  cheated someone the day before. The victim walks in angry, kicks the back legs out of his chair and
  he goes over backwards; the victim draws, shouts, and puts the gun in his mouth. You have seconds."
  "**Fits:** Phase 3's 'saloon table' mission and the story's saloon-table prologue".
- PROPOSED (showcase): "Some days the victim was cheated; some days he's lying."

## The ways to do it

- PROPOSED (showcase): "shoot the victim (a ball through him may hit the man on the floor); shout or
  draw so he turns on you; shove him; throw a bottle; shoot his gun hand so the gun drops; answer his
  'Tell me I'm wrong' with a nod or a shake; or let it happen."
- PROPOSED (DESIGN.md "Little acts in the world", Sean 2026-10-15): "the table scene ... written as
  acts ... that the systems carry out and that hand back to the systems the moment you interfere."

## The big choice and its cost

- PROPOSED (showcase): "the cheater owes you his life, or the victim's friends want you, or a witness
  tells the deputy you shot a man defending his money."

## What happens after, in the world

- PROPOSED (showcase, Sean): "whatever happens, dead man on the floor or not, the barman's first words
  are about his furniture: 'Jesus, Cody, my chair!' Make it a rule, not a line for this scene: **owners
  care about their own things first.**"
- PROPOSED (DESIGN.md): at dawn the sheriff; "the ball the doctor digs out may match the stranger's
  gun, or clear him" (`the-sheriff`).

## Where on the map

- PROPOSED: the saloon in `town`; `vp_saloon_balcony` (20, -8.9). The valley's saloon lot (north side
  x 7.6..24.0).

## Which threads it moves

_PROPOSED: this session's mapping from the sources (threads in `MAP.md`); lines without a status word are that mapping._

- The sheriff (the stranger as a suspect); the town's opinion of you from the first night.

## Which systems it needs

_PROPOSED: this session's reading of what the ways above need. Each line ends with its state on main, 2026-11-09: exists, partly, being built, decided (not built) or new._

- The kit chair that tips, the fall backwards (`sit_back`, `kick`): exists (#204).
- Confrontation and escalation, the nod: partly (the nod not built).
- Shove (#479), dropped guns, ballistics through a man: exists.
- Owners naming who broke their things: new (ownership, DESIGN §10).
- Acts (roadmap 3.5): new.
- The stranger's talk (written, voiced lines; the AI only reads): partly.

## Where the sources disagree

- OPEN: "A Quiet Drink" (Sean's brief, 2026-10-17: "A saloon confrontation that tests conversation,
  escalation, intimidation, close-range combat, furniture destruction, and civilian reactions";
  "provisional concepts, not finalized story missions") may be this mission or a separate one.
- OPEN: the prologue is the evening "before day 1" of a ten-day shape that #546 (Sean, 2026-11-01)
  replaces with no day count; #546 proposes "The demo is unchanged: the prologue and day 1."

## Sources

DESIGN.md §5 "Story shape"; `docs/briefs/showcase-moments.md`; `docs/ROADMAP.md` 3.6;
`docs/briefs/three-gunmen.md` §10; #546.
