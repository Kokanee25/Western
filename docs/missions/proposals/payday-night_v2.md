# Payday Night: the Floor Gives Way (a proposal) (`payday-night`)

**A design for Payday Night by the planning session (2026-11-09), at Sean's ask: "make me a 30/35
mission".** Everything here is PROPOSED unless marked DECIDED with Sean's words. Payday Night is DECIDED
as the middle's hinge but has no design yet (`../payday-inquest.md`).

- DECIDED (Sean, 2026-11-09): "Yes to payday night": the middle's turning point; the attack on the
  payroll brings Rourke in on the train, offering "order"; the Kid is the informant who knows who pays
  the gang.
- PROPOSED (inventory, 2026-11-09): "After the payroll train incident, Salt Creek celebrates. Harlan
  drinks with townspeople. A serious event interrupts the evening, potentially Rourke's arrival or a
  shooting."
- DECIDED (DESIGN.md §6, proposed backstory): Harlan was an army **hospital steward**. This mission is
  where that past is the whole game.

**In one line:** payday's crowd packs the Railroad Saloon's upstairs dance floor; the floor was built
for half of them; when it goes, Harlan, a hospital steward, has the night to decide who he can save
before the doctor runs out of hands, and Rourke steps off the night train offering an army surgeon at a
price.

## How you hear of it

- **Payday is the town's night.** The payroll's day is on the town's calendar; by dusk every miner,
  hand and teamster with wages is in the two saloons, and the Railroad Saloon's upstairs has a fiddler
  and a dance. Harlan is there or near, like everyone.
- **The building warns.** The upstairs gallery sags (the town's buildings already sag with age,
  `BuildingAge`); the floor creaks and bows under the stamping as the crowd thickens. A player who
  watches the ceiling below sees it move.
- **The crash.** When it goes, the whole town hears it (sound carries); the church bell rings; men run
  for the deputy and the doctor.
- **The doctor sends for the steward.** He knows Harlan's past (from the sheriff's last hours on day 1).
  Even if the doctor is dead, the wounded lie in the street under the lamps for anyone to see.

## The situation

- The upstairs of the Railroad Saloon holds the dance; downstairs, the bar. The joists were never meant
  for forty dancers. **The building's own load paths decide** whether and where it fails: the more
  people upstairs and the more they stamp, the more the floor carries (people's weight laid on the
  members as the train's is on the trestle).
- When it goes, the dancers fall through onto the drinkers below: crushed limbs, broken bones, a man
  pinned under a joist, cuts from glass, a woman bleeding from the thigh, a man who seems fine and isn't
  (a ruptured spleen bleeding inside). **The wound system makes each one**; nobody is placed hurt by
  hand.
- One doctor. Harlan. Whoever Harlan can make help.
- **The Kid** (DECIDED: the informant who knows who pays the gang) was drinking downstairs. He may be
  under the joist.
- **The night train is due.** Rourke is on it (DECIDED), with an army post surgeon and his orderlies.

## The ways to do it

**Before:**
1. **See it coming and clear the floor.** Notice the sag and the creak, tell the owner, get men down the
   stairs (the shout; the escalation ladder: a drunk crowd doesn't like being told). Cleared in time,
   nobody is hurt; the owner resents the lost night and says so, and nobody believes Harlan was right
   because nothing happened.
2. **Thin it.** Not everyone; enough. Whatever's left upstairs is what the floor decides about.

**After** (the showpiece): every wounded man has his own clock, and the systems keep them.
3. **Triage.** Go from body to body: a tourniquet on the thigh, packing a cut, a splint, leave the man
   who can wait, see the one who's quiet. Harlan's hands are two; every minute on one is a minute off
   another. The order is the player's; who lives is the physiology's.
4. **Make others help.** Shout men to carry, to hold pressure, to fetch lamps and doors for stretchers
   (leading people). Drunk men are slow and clumsy; frightened ones run.
5. **Lift the joist.** The man pinned under it: get men on it together, or lever it with a beam, or cut
   it free (the members break; a cut in the wrong place drops more of the floor).
6. **Work with the doctor.** He takes the worst cases inside; he'll ask Harlan to hold a man down while
   he takes the leg (the amputation moment), or to take one himself.

**When the train comes:**
7. **Rourke's offer.** He steps off with his surgeon and orderlies: "Let my men help, Deputy." Accept and
   more live tonight. Refuse and the town tends its own.

## The big choice and its cost

- **Rourke's surgeon.** Accept and lives are saved that would have been lost; and Rourke has his story
  (the Army had to restore order and tend the town's wounded), soldiers billeted in the town, and his
  surgeon now knows who's who. Refuse and the town keeps its pride and its independence, and some of
  those who die tonight would have lived. **There's no clean answer, and the window closes as the men
  bleed.**
- **The Kid or the next man.** The Kid under the joist is the one man who can name who pays the gang. A
  miner bleeding out beside him is a stranger. Triage by need (the period's own rule) or by what the
  living man knows.
- **Before or after.** Clearing the floor in time saves everyone and earns nothing: no one saw the
  danger but Harlan.

## What happens after, in the world

All carried by systems (persistence, opinions, memory, wounds), none by a written branch:
- **The people.** Who lived and who died are permanent: the dead are buried (the cemetery), the maimed
  walk the town with their marks for the rest of the game (DESIGN's permanent marks), the saved owe
  Harlan, the families of the dead remember who he went to first.
- **The building.** The broken floor and the rubble stay; the Railroad Saloon is shut until it's
  rebuilt (over days, if at all).
- **Rourke's foothold.** Accepted, soldiers are billeted in town and seen on the street; refused, he camps
  at the depot and waits. Either way the captain who comes the next day (`i-am-the-law`) sees the
  aftermath, and what he sees goes in his tally.
- **The Kid.** Alive, he talks, in his own time (the informant thread); dead, that thread loses its
  voice.
- **Harlan's name.** The town learns what he was before he came: the deputy is a steward. People come to
  him with wounds after this.

## Where on the map

- The Railroad Saloon (`second_saloon` (-42, -62), 12 x 9 m, the valley's town), upstairs and down, the
  street outside under the lamps, the doctor's, the depot (the night train). The old town's saloon, with
  its gallery and balcony, can carry the first prototype.

## Which threads it moves

- T5 Rourke (his arrival and his offer: the spine's hinge); T6 the gang (the Kid); T1 the badge (the
  deputy who saves people, not only arrests them); T8 Harlan's past (the steward, found through play);
  the town.

## Which systems it needs

PROPOSED, to be confirmed by the build check:
- People's weight on a structure's members (`StructureMember.extra_points`, as the trestle carries the
  train) and the support graph deciding the floor: exists in part (new: the crowd's load, stamping).
- People falling with a structure, hurt by the fall and the rubble (ragdoll, `BodyImpacts`,
  `_on_rubble_hit` → `take_blow`): exists; falls by height new (#736 D).
- Wounds, bleeding, internal bleeding, physiology on a clock: exists.
- First aid on another man (tourniquet, packing, splint): partly (the player's own first aid exists).
- Leading people (signature 6): decided, not built.
- The doctor working (treatment lab part 2) and the amputation: new.
- Rourke and his surgeon arriving on the night train: shared with the spine (passengers getting off).
- Permanent marks on the living, graves, a shut building: partly (persistence needs story state).

## True to 1882 (to check)

- Hospital stewards' work: tourniquets, lint packing, splints; triage by need from the Civil War (the
  Letterman system, after Larrey); Esmarch's first-aid kit (1870s); chloroform; carbolic only partly
  adopted.
- Army post surgeons often treated civilians in frontier towns.
- Upper floors of halls giving way under a crowd were a known hazard of the period's frame buildings;
  check a documented case before relying on it.
