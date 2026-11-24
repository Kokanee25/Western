# Payday Night, version 3: the Floor Gives Way (a proposal) (`payday-night`)

**The planning session's design for Payday Night (2026-11-09), revised for Sean's "make me a 30/35
mission".** Everything is PROPOSED unless marked DECIDED. Version 2 (`payday-night_v2.md`) scored 27/35;
this version answers its judge (a clean best answer, every way the same kind, authored beats, a two-way
branch, overlaps, history) and its build check (the spec saloon, about twelve upstairs, falls that hurt,
no lever or axe, no night train).

- DECIDED (Sean, 2026-11-09): "Yes to payday night": the middle's turning point; the attack on the payroll
  brings Rourke in on the train, offering "order"; the Kid is the informant who knows who pays the gang.
- DECIDED (DESIGN.md §6, proposed backstory): Harlan was an army hospital steward.

**In one line:** the Baron wants an outrage on payday, so his men have sawn the dance floor's joists
half through; it holds until the crowd is thick. Harlan can find the cut and clear the floor, and the
outrage comes another way; or the floor goes, and the steward has a night of wounded, two killers in the
dark street hunting the Kid, and Rourke at his elbow offering an army surgeon for a signature.

## How you hear of it

- **Payday is the town's night.** The payroll came on the noon train (and Rourke with it, DECIDED); by
  dusk every man with wages is in the saloons. The deputy is expected on Main Street on payday: the
  barkeep says so.
- **The building warns, from the place itself.** As the dance thickens the upstairs floor creaks and
  bows, harder as the load climbs (the creak and the visible bend come from the floor's own load). From
  the bar below, a fresh saw cut shows pale in one joist where no carpenter would cut.
- **The crash** is heard across town; townsfolk run to it; the doctor shouts for anyone who knows wounds.
- **If Harlan is out in the valley**, the night still happens and lasts: the wounded are laid in the
  street and the bleeding inside goes on for hours, so he rides into the middle of it.

## The situation

- The spec saloon's upstairs room (built from data, its joists light for a dance hall, one sawn half
  through), about **twelve** dancers and a fiddler upstairs, the bar full below. **The floor's load paths
  decide**: each man's weight on the member under his feet, more while they dance.
- **The Baron's men** cut the joist in the afternoon: an outrage on payday is what Rourke needs (the
  spine). Two of them are in the crowd to see it happen.
- **The Kid** (DECIDED: the informant) drinks at the bar, under the floor. The Baron's men want him dead
  tonight: he's been talking.
- **Rourke** is at the hotel with an army post surgeon and two orderlies. He comes out at the crash.
- One doctor, at his table.

## The ways to do it

Ways of different kinds, and each one costs something.
1. **Prevent it.** Find the cut, then clear the floor: a drunk payday crowd doesn't like being told (the
   escalation ladder). Cleared, nobody falls, and the Baron's men turn to their other way: a shooting in
   the packed street, meant to look like a riot, with Harlan in the middle of the crowd.
2. **Expose it.** Show the sawn joist to the barkeep or the crowd before or after (the cut is in the
   member, seen in the place): the town learns this was done to it. The Baron's men see you looking.
3. **Triage** (the showpiece, if it falls): from body to body, a tourniquet, packing, a splint; leave the
   man who can wait; find the one who's quiet. Two hands; every minute on one is off another; **the
   physiology decides who lives**, and the wounds come from the fall and the timbers, never placed.
4. **Make others help.** Shout a townsman to a casualty and he holds pressure or drags him to the
   doctor's; enough men together lift the joist off the pinned man.
5. **Fight in the dark.** While everyone tends the wounded, the Baron's two men go against the flow,
   toward the Kid. Stop treating and stop them, or keep treating and lose him.

## The big choice and its cost

No clean answer, and the windows close as men bleed.
- **Rourke's surgeon, for a signature.** He offers the surgeon if Harlan signs a request for Army aid.
  Sign and men live tonight who'd have died, and Rourke holds a paper that says Salt Creek's law asked the
  Army in: the captain who comes tomorrow (`i-am-the-law`) reads it, and the Baron uses it. Refuse and the
  town keeps its law, and some of tonight's dead would have lived.
- **The Kid or the next man.** Triage by need (the period's own rule) or by what the living man knows,
  with the killers coming.
- **Prevent it or let the proof happen.** Clearing the floor saves everyone from the fall and starts a
  shooting in a crowd; the floor that falls is the only proof of what the Baron did.

## What happens after, in the world

Carried by the systems (persistence, opinions, memory, wounds), not by written branches:
- **The people:** the dead buried, the maimed marked for good (DESIGN's permanent marks), the saved owing
  Harlan, the families remembering who he went to first.
- **The building:** the broken floor and its rubble stay; the sawn joist stays in the pile (anyone who
  looks can find it later).
- **The paper:** if signed, Rourke has it; the captain's tally counts it; the Baron shows it.
- **The soldiers:** Rourke's men camp at the depot (no quartering in houses in peacetime); seen on the
  street either way, more of them if the town asked.
- **The Kid:** alive, he talks, in his own time; dead, that thread loses its voice.
- **Harlan's name:** the town learns its deputy was a steward; people bring him their wounds after this.

## Where on the map

- The Railroad Saloon (`second_saloon`, the valley's town), upstairs and down; the street under the lamps;
  the doctor's; the hotel (Rourke). Prototype in the building lab's spec saloon (real upper floors).

## Which threads it moves

- T5 Rourke (his offer, his paper: the spine's hinge); T4 the Baron (the sawn joist); T6 the gang (the Kid,
  the killers); T1 the badge; T8 Harlan's past (the steward); and `i-am-the-law` the next day.

## Which systems it needs

From the build check of version 2, adjusted:
- The crowd's weight on the floor's members (the trestle's pattern, throttled to once a second): small.
- The creak and visible bend from each member's load: small.
- A member cut half through in data (the sawn joist), seen in the place: small (data).
- Men falling with the floor, the drops staggered a few a tick, about twelve upstairs; the fall itself
  hurting them (reuse the blast-thrown landing): small, plus a frame-cost lab against #492's gate.
- Wounds from the fall and the timbers (internal bleeding, fractures exist): works today; a lab measures
  the spread a collapse produces, so the night isn't ten bruises or ten dead.
- First aid on another man (point the player's `_tend` at him) and a splint: medium (roadmap 3.1c).
- Lifting the pinned piece with helpers; a shouted "help" chore (hold pressure, drag to the doctor's):
  medium.
- The doctor at his table taking the men laid there: a chore, medium (part of treatment lab part 2).
- The Baron's two men on an agenda toward the Kid: small (the gang's agendas).
- Rourke at the hotel, out at the crash, his offer and the paper (a deed and an object): large (shared
  with the spine; a new character).
- Persistence of the people, the paper and the marks: story state (shared, large).
- **Cut** from version 2: the amputation (the judge's cut), the lever, the axe, the night train.

## True to 1882 (to check)

- Hospital stewards' work: tourniquets, lint packing, splints; sorting the wounded by need was army
  surgeons' practice (Larrey's, carried into the Civil War).
- Army post surgeons often treated civilians in frontier towns.
- No soldiers quartered in houses in peacetime (the Third Amendment); after 1878 (Posse Comitatus) the
  Army keeps to its camp unless called; a deputy's written request is the kind of paper that matters.
- A dancing crowd loads a floor more than standing men (check a source for the factor); a joist sawn half
  through loses most of its strength: the collapse rests on the cut, not on a period case.

## The judge on version 3 (2026-11-09): 27/35

Choices 4 (the signature only comes up if the floor falls; prevent + expose is close to a clean best
answer); Systems 4 (the street shooting, Rourke's entrance and the street triage are authored beats);
Consequences 4 (the paper's links hand-written; story state large); Unique 4 (overlaps the Balcony Ambush:
an upper floor brought down with men on it); True to 1882 4 (the sabotage isn't from the record; the
paper's legal weight shaky); Discoverable 4 (the cut is one pale mark seen only by looking up; a creak is
ordinary); Cost 3. **27/35.**

**Beef it up:** 1. Prevention as a range of partial ways from the structure system: prop the joist, the
barkeep's free round downstairs to thin the dancers, stop the fiddler; each only partly works. 2. The
sabotage has witnesses: two men seen going up with a saw, sawdust on the stair, the store sold a saw. 3.
Rourke's offer as a rule: whenever the wounded outnumber the doctor's hands, from the floor or the street
shooting, so the signature is on every path, its size following the night. **Cut:** the two killers
hunting the Kid (put the Kid among the possible wounded instead). **1882:** a deputy's paper has no legal
force (troops come by the President's order on a governor's or legislature's request): it's political
ammunition; Union practice was Letterman's ambulance and field-hospital chain, sorting by need was
Larrey's (Napoleonic); lint was giving way to carbolic dressings in Army practice by 1882.
