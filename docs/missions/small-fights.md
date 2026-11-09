# Small Fights Out in the Valley (`small-fights`)

A family of small, repeatable encounters, carded together. Other names: "fights that have nothing to
do with the story" (#736), "fight sites out in the valley" (#463). Sources: #736 (Sean, 2026-11-09);
#463 comment (Sean, 2026-10-28); DESIGN.md §5 "Reasons to fight" (Sean, 2026-10-01).

- DECIDED (Sean, 2026-11-09, #736): "we need more to do and go - more small fights - maybe a few more
  abandoned houses on hills and stuff - fights that have nothing to do with the story - places of
  elevation where you can shoot someone and watch them fall from height through roofs".
- DECIDED (#736, "Sean, decided"): the order: "**B (the places) first** ... **Then D** (falls through
  roofs in the building lab). **Then C** (the fights)", "after the greybox G-steps".

## How you hear of it

- PROPOSED (#736 C): "Fights that happen out in the world and refill over days, with a few fixed spots
  and a few roaming". You ride into them, or hear of them (no source says how in detail).
- DECIDED (DESIGN.md "Reasons to fight"): "bounties from the wanted posters".

## The situation

- PROPOSED (#736 C), the list:
  - "**Road agents** holding up a wagon or a rider on the road."
  - "**Claim jumpers** at the prospector's diggings."
  - "**Rustlers** driving the Baron's cattle. You pick a side, or none."
  - "**A wanted man holed up** in an abandoned house on a hill." (carded: `the-bounty`)
  - "**Horse thieves at night.**"
  - "**A feud** between two homesteads."
  - "**A drunk who goes for his gun** outside a saloon."
  - "**Outlaws camped** at the hideout and in the wilderness spots."
- PROPOSED (#463 comment, Sean 2026-10-28): outlaw camps and hideouts; abandoned buildings (a mining
  office, a burned homestead, a ruined stage station); rustlers at a line camp, a whiskey trader's
  cabin, a gang's powder store; road ambushes.
- DECIDED (DESIGN.md "Reasons to fight"): "The street: call-outs and duels (built), drunks who draw, bar
  fights that escalate, men you wronged coming back, bounty hunters after you if you're wanted."
- DECIDED (DESIGN.md): "claim jumpers", "night riders at your own spring", "clearing the gang's
  hideout or the mine".

## The ways to do it

- DECIDED (#736 C): "Choosing not to fight is always allowed. Talking, paying, sneaking past or walking
  away are all real choices (immersive sim)."
- DECIDED (#736 B): "Each one gives a shooter above and a target below, or the reverse." "**enemies use
  high ground.** A man on a roof or a ridge has the advantage until you flank him."

## The big choice and its cost

- PROPOSED (#736 C): rustlers: "You pick a side, or none."
- DECIDED (DESIGN.md "Reasons to fight"): "most standoffs should have a way out that isn't shooting."

## What happens after, in the world

- DECIDED (#736 C): "The people involved belong to the living world (#695/#663): they're remembered,
  there are witnesses and the law hears about it, and the dead stay dead."
- PROPOSED (#463, Sean 2026-10-28): "The town remembers, the land doesn't." (The fights refill.)

## Where on the map

- PROPOSED (#736 B, "about 12–15 to start"): abandoned houses on hills (two or three), a line shack on a
  ridge above the Baron's range, a rock outcrop above the wagon road, a bluff over the creek, the depot
  water tower, the mine headframe and ore chute, a windmill, the church bell tower, a ruined adobe
  mission or stage station, a sheer drop into the canyon near the trestle.
- DECIDED (#736 A, "approved with the map"): a landmark butte; the rough southern rimrock trail; a
  spring or stock tank in the west ("the Baron wants it"); the west half filled.
- PROPOSED (`valley.json`): `hideout` (-450, 2020, y 86, DECIDED place), `abandoned_homestead`,
  `prospect_shack` (-1560, -1150, y 109.6), `rock_camp`, `mesa_overlook`.

## Which threads it moves

_PROPOSED: this session's mapping from the sources (threads in `MAP.md`); lines without a status word are that mapping._

- PROPOSED (#736): "fights that have nothing to do with the story". Rustlers touch the Baron.

## Which systems it needs

_PROPOSED: this session's reading of what the ways above need. Each line ends with its state on main, 2026-11-09: exists, partly, being built, decided (not built) or new._

- Falls from height that hurt and kill by height; a ragdoll that breaks roofs it lands on (#736 D):
  new.
- Enemies who climb and hold high ground, flank a man on a roof: partly (`climb` in D).
- Encounters that refill over days, roaming groups: new (Prompt 18's event framework).
- Bodies that stay (#562): exists.
- Witnesses and the law hearing of it: partly.
- Cattle (#728: cows "may be made", OPEN): new.

## Where the sources disagree

- OPEN: the headframe (#736, #463) vs "a hoist-less adit mine (no head frame needed)" (`valley.json`).
- OPEN: rustlers drive "the Baron's cattle" (#736); cattle are not yet in the game (#728, #700: OPEN).

## Sources

#736; #463 comment 2026-10-28; DESIGN.md §5 "Reasons to fight"; `config/valley.json`.
