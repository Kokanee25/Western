# The Widow's Place (`widows-place`)

Other names: "the peaceful visit" (the farmhouse lock, PR #621 step A6). The name is this session's
(PROPOSED); Sean called it "the quiet mission". Sources: Sean in chat, 2026-11-09; the farmhouse lock
(2026-11-03, PR #621); #728 (Blue); #700 (her water right); `config/valley.json`.

- DECIDED (Sean, 2026-11-09): "Oh we forgot the quiet mission of riding out to the widows property where
  you meet her for some reason - this is when we meet blue and the kids playing".
- DECIDED (lock, 2026-11-03, as the farmhouse card records it): "Order: the peaceful visit, then the
  hostage crisis." "Her lines follow the help-or-leave deed from the opening." The visit "shows the
  property's ways in first: the back entrance, kitchen, yard and outbuildings".
- This card is that visit, as its own mission. The farmhouse card's A6 line points here.

## How you hear of it

- OPEN: no source says.
- PROPOSED (this session, not picked): **the sheriff's horse.** It has stood at the livery since day 1;
  the livery man says it eats his oats and someone should take it home to her. Anyone in town can say it,
  so it isn't missed; a player who never goes hears it again (the horse is still there).

## The situation

- DECIDED (lock): the widow is the murdered sheriff's wife; she lives on the claim with their **two young
  sons**; she refuses to sell. DECIDED (Sean, #700): her creek water right is the valuable one and the
  reason for the murder.
- DECIDED (Sean, 2026-11-09): you meet **Blue** and **the boys playing** here, for the first time.
- DECIDED (#728): Blue "can never be hurt or killed"; "He barks at strangers, follows the boys".
- DECIDED (no-law, Sean 2026-11-09): the Baron offered to buy her claim at the funeral.
- OPEN: **why Harlan rides out** ("for some reason"). This session's candidates, none picked:
  - **A. Bringing the sheriff home:** his horse, his saddle, and the rifle in its scabbard. She gives
    Harlan the rifle ("he'd want it used", or she can't stand to look at it). That's the **Winchester**,
    which `joe-on-the-rope` needs and nobody gives yet (`DECISIONS.md` gap 2).
  - **B. She sent for the law:** stakes driven at her ditch heading, a man watering stock at her creek,
    the Baron's man back twice since the funeral. She wants the new deputy to see it. It shows the water,
    the motive, and the threat the farmhouse turns into.
  - **C. Both** (recommended): the horse is the errand, and what she shows him is the stakes.
- PROPOSED (this session, not picked): **the boys at play,** around the woodpile and the wagon, playing
  sheriff and outlaws with sticks for guns, Blue in the middle of it. They "hold up" the rider coming up
  the lane. Funny on its face; underneath, it's their father's game.
- PROPOSED (this session, not picked): **the ride out passes the place** where Harlan found the sheriff
  on day 1 (`valley.json`: the opening's site is on the East Road, his way home). Nothing marks it but
  what's left on the ground.

## The ways to do it

Quiet: no fight. PROPOSED (this session, all):

- Ride out (or lead the sheriff's horse on foot: it's about 2 km), hand him over, and ride back.
- Stay: coffee in her kitchen (he sees the back door), a chore she's behind on since the funeral (split
  the wood, mend the gate, water the stock: `CivilianBrain.chores`), the boys and Blue around him.
- Walk the property with her: the yard, the outbuildings, the ditch and the stakes (if B). This is where
  he learns the ways in that the farmhouse rescue uses (the lock).
- Be short with her and go. That's a way too, and it's remembered.

## The big choice and its cost

- PROPOSED (this session, not picked): **what he tells her about the end.** She asks, "Were you with him?"
  or "Did he suffer?", and Harlan answers with the nod or the shake. Her lines already follow
  `sheriff.care` (lock). If he left him and lies, the truth can reach her later through the witnesses
  and the rumour system; the kind lie costs more when it's found out.
- PROPOSED: the rifle (if A): take it or leave it with her.

## What happens after, in the world

PROPOSED (this session, all):

- **Blue knows him.** Met and made friends with, Blue doesn't bark at Harlan at the farmhouse rescue;
  he barks at the gang and gives *them* away (#728: "he gives the gang's position away, or the
  player's"). Never met, he barks at Harlan too.
- **The boys know him.** In the farmhouse's Phase B, the boys come to a voice they know and follow him
  out; a stranger, they hide.
- **He knows the house.** The back door, the kitchen, the yard (the lock).
- **Her trust** carries her lines from here on: `sheriff.care`, `funeral.attended`, this visit, the chore,
  the answer about the end.
- Not going is remembered too: at the farmhouse he's a stranger to all three.

## Where on the map

- DECIDED (`config/valley.json`): `widow_homestead` (1712, -560), pad y -10, on the widow's lane off the
  East Road, past Bridges A and B; the farmhouse on its knoll (G6, #731, built); her fields on the
  bottomland down to the creek 130 m north; her ditch heading in the canyon mouth.

## Which threads it moves

_PROPOSED: this session's mapping from the sources (threads in `MAP.md`); lines without a status word are that mapping._

- T4 the Baron and the water (the stakes, the offer refused); T1 the sheriff's murder (his things, how he
  died); the widow's family (first met).

## Which systems it needs

_PROPOSED: this session's reading of what the ways above need. Each line ends with its state on main, 2026-11-09: exists, partly, being built, decided (not built) or new._

- Riding a horse, and leading a second one on a rein: new (horse lab P2, #478). The first long ride in
  the game, with nothing at stake: a good place to learn it.
- The two boys (child bodies, `ProtectedChild`): new (characters; PR #621 A1).
- Blue (a dog, never hurt; barks at strangers, follows the boys, learns a man): new (#728).
- The boys' play (a small brain: running, play-acting, reacting to a rider): new.
- Chores with a helper: partly (`CivilianBrain.chores`).
- Talk and the nod: decided, not built (Step 0 of `BUILD_ORDER.md`).
- Memory that lasts (the widow, Blue, the boys): new (Step 0).
- The Winchester (if A): next in the arsenal (#734).
- Story state: new (Step 0).

## Where the sources disagree

- None yet. Note: the lock has her "not met as a widow before the opening"; the funeral (`no-law`) may
  show her at a distance; this is the first time Harlan talks with her.

## Sources

Sean in chat, 2026-11-09; the farmhouse lock (PR #621, 2026-11-03); #728; #700; `config/valley.json`.
