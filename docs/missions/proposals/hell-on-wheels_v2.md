# Hell on Wheels, version 2: a proposal (`hell-on-wheels`)

**A proposal by this planning session (2026-11-09), for Sean.** Everything here is PROPOSED unless it
is marked DECIDED with Sean's words. It keeps every decided part of the card (`../hell-on-wheels.md`):
Version A's two gangs, the overpass boarding, the walkable six cars, rear to front, stopping before the
broken track, physics deciding. It adds what the judge found missing (`../judged/2026-11-09.md`: 17/35;
weakest on choices, consequences, unique, discoverable) and ties it to the spine Sean picked.

- DECIDED (Sean, 2026-11-09, #542): the name, "Hell on Wheels"; "tracks out, fight through the cars,
  stop it before it derails".
- DECIDED (inventory, 2026-11-09, "Version A selected"): two gangs; one breaks the track, the other
  holds the train; board from the small overpass (horseback as the alternative); fight rear to front
  through six cars; stop before the broken track.
- DECIDED (Sean, 2026-11-09, the spine): Payday Night follows; the attack on the payroll brings Rourke
  in on the train; the Kid knows who pays the gang.

## How you hear of it

PROPOSED: four ways, none needing the others, all from what already runs.
- **Payday's on Thursday's train.** The saloon owner sells it; the miners talk of it in the saloon the
  night before. Anyone in town knows the payroll's coming.
- **The stick-up man** (#276, proposed 2026-11-07): a man seen practising his draw alone; he's in Gang A.
  A player who watched him knows a face on the train.
- **The section foreman** comes into town at a run: spikes pulled and a rail loosened out west, and two
  riders seen there.
- **The train itself.** On the day, it doesn't stop at the depot: it blows through at speed, whistle
  silent, the agent shouting. Anyone in town sees something's wrong.

## The situation

- PROPOSED: the mine's payroll rides in the express car's safe, with the **express messenger** who
  guards it, westbound for the Ore Works.
- PROPOSED: **two gangs, one double-cross.** Gang A boards to rob the express car at a lonely stretch
  west of town. Gang B, two men, is paid by the Baron's foreman to pull a rail west of the depot, not to
  stop the train but to **wreck** it: a wreck with dead passengers is a bigger outrage than a robbery,
  and an outrage is what brings soldiers (the spine). Gang A doesn't know. They're riding to their own
  deaths with everyone else.
- PROPOSED, the period's own method: pulling spikes and loosening a rail is how the James–Younger gang
  derailed a train at Adair, Iowa, in 1873.

## The ways to do it

PROPOSED. Each runs on the train systems and decides itself by physics, distance and nerve.
1. **Fight to the cab** (decided): board from the overpass, rear to front, and brake. The **express
   messenger** is bleeding in the express car: every minute Harlan (a hospital steward) spends on him is
   ground the train covers toward the break.
2. **The brake wheels.** Freight cars in 1882 were braked by hand: brakemen on the roofs turning brake
   wheels. Harlan can wind them down car by car from the roof walk, under fire, to slow it from the back
   while Gang A holds the cab. Slower and exposed, but it doesn't need the cab.
3. **Pull the pin.** Uncouple behind the express car and the coach, with its passengers, drifts to a
   stop on the grade; the engine, the payroll, the messenger and Gang A run on to the break and derail
   for real.
4. **Tell them.** Gang A are robbers, not fools. Show them a spike from the break, or shout "the rail's
   out!" and let their nerve decide. Believed, they stop the train themselves and run with the money:
   everyone lives and the payroll's gone.
5. **The siding.** Ride ahead of the train to the depot and throw the switch to the rail yard. The train
   leaves the main line before the break, but the siding is short: at speed it runs off its end into
   the freight warehouse or the stock pens. The town takes the wreck instead of the passengers.

## The big choice and its cost

PROPOSED: there's no clean answer, and the player usually finds out which one he chose by what he's
standing on when it ends.
- The payroll (the town's payday, the miners' wages), the passengers (people he has seen all game), the
  messenger, the robbers, the town's warehouse: every way saves some and spends others.
- What he keeps alive decides what Payday Night is: a celebration, a hungry night, or a funeral.

## What happens after, in the world

PROPOSED: all by existing systems (opinions, memory, persistence, the timetable), no written branches.
- **Payday Night** (DECIDED as the hinge) follows whatever happened: the payroll saved, the town drinks
  to Harlan; lost, the miners go unpaid and the saloon's night turns ugly. **Rourke steps off the
  train either way**, offering "order".
- **The wreck stays** where it fell until the repair crew clears it (train step 5); the line is out for
  days, felt at the depot and the store. A siding wreck stays in town.
- **Gang A**, if they ran with the money, are on wanted posters (`the-bounty`). Taken alive, they fill
  Harlan's jail (`hold-him`).
- **Gang B's man**, taken alive at the break, names the foreman who paid him: a lead toward the Baron
  and the Kid (`kid-wants-out`), carried by a person, not an evidence system.
- **The messenger**, if he lives, owes Harlan; the express company's man in town remembers.

## Where on the map

- DECIDED (`config/valley.json`, the inventory): the overpass `bridge_b` (1912, -229), deck 11.2, the
  boarding point; the westbound order overpass → trestle → depot → Ore Works; the great trestle is
  crossed safely here.
- PROPOSED: the break west of the depot, before the Ore Works; the siding is the `rail_yard` (22, -63)
  beside the depot, its end facing the `freight_warehouse` (104, -63) or the `stock_pens` (-29, -100)
  (the exact layout is the valley plan's).
- PROPOSED: the first fight at the break is small (two men, or the break found already done), as the
  judge suggested, so the race to the train starts fast.

## Which threads it moves

- T5 the train and Rourke (he arrives on Payday Night); T4 the Baron (his foreman paid for the wreck);
  T6 the gang (Gang A and the stick-up man; the Kid as informant).

## Which systems it needs

PROPOSED, with each one's state on main (2026-11-09):
- The train, couplers with a pin that can be pulled, walkable cars, ladders, roof walk, breakable
  track, the derail, `TrainWreck`, the timetable: exists (train steps 1–5).
- Fighting on moving cars, cab controls: new (train step 7, already planned).
- Hand brake wheels per car in the 1D brake model: new, small (the brake force summed by car).
- A switch and a siding with an end: new (`TrackLine` gains a branch).
- Robbers' nerve when told the rail is out: partly (nerve, surrender, "Drop it!" exist; reading "the
  rail's out" into a deed is the action-command layer, DESIGN §9).
- The express messenger bleeding, first aid on a moving car: partly (wounds, first aid).
- The faction plan (the Baron's foreman pays Gang B): new (Prompt 18's plans as data, shared).
- Payday Night's mood from the payroll's fate: new (shared with the town's calendar, #276).

## True to 1882 (to check)

- Adair, Iowa, 1873: the James–Younger gang loosened a rail and derailed a locomotive to rob it.
- Express companies' messengers rode with the safe in the express car.
- Hand brakes worked from car roofs were usual on freight cars until the 1890s; air brakes existed
  (from 1869) but weren't on every car. Check what the Denver & Rio Grande's narrow-gauge trains had in
  1882 before deciding how strong the cab's brake is against the cars'.
- Depot sidings and hand-thrown switches were standard.

## Where the sources disagree

- OPEN: the inventory has Harlan fight the saboteurs "then race east to catch the approaching train";
  with the break west of the depot that's a long ride. The valley plan's numbers decide where the break
  and the race can be.
- OPEN: valley-plan §4 allows the break at the trestle's approach; that clashes with the trestle being
  kept for the finale. This proposal puts it west of the depot.

## The judge on this proposal (2026-11-09): 26/35

A fresh judge, the same rubric and shelf, scored the proposal as if it were the card (the decided
card scored 17).

| Criterion | Score | Nearest reference | Why |
|---|---|---|---|
| Choices | 4 | about Liberty Island | Five ways that really differ and a real cost with no clean answer. Not 5: each way is a listed affordance; no window says when each closes. |
| Systems over scripts | 4 | about Lady Boyle | Placed as a situation, physics, distance and nerve deciding; the double-cross, Rourke arriving either way and the foreman's man naming his payer are authored. |
| Consequences | 4 | about A Crack in the Slab | The wreck stays, the line is out for days, robbers on posters or in jail, Payday's mood follows. Not 5: Payday's moods read as written states; the spine's course doesn't change. |
| Unique | 3 | above Leviticus Cornwall | The stock train robbery, turned by the wreck-for-outrage double-cross, pulling the pin, telling the robbers. Overlaps Tied to the Tracks. |
| True to 1882 | 4 | about Leviticus Cornwall | Adair's method, the express messenger, roof hand brakes, the section foreman, hand-thrown switches. |
| Discoverable | 4 | past the Showstopper | Four independent ways to hear; the overpass and the brake wheels show themselves. Not 5: nothing says how a player learns of the pin, the siding or telling the robbers. |
| Cost to build | 3 | about Lady Boyle | Steps 1–5 exist, step 7 planned; hand brakes, a siding, the faction plan, Payday's mood add up. |
| **Total** | **26/35** | | |

**What the references do that this doesn't:** A Crack in the Slab and the Clockwork Mansion make the
big choice one visible, irreversible moment with a stated window; the Showstopper's ways come out of
systems read in the place, where these five are a designer's list.

**Beef it up:** 1. Make the clock the second axis: where and when Harlan hears decides what's left (the
foreman early leaves the overpass and the siding; the train through the depot leaves only the chase).
2. The period's own brake as a system: with automatic air on the coach and express car, parting the
train or opening the hose sets every car's brakes; Gang A has closed the angle cocks; opening them (or
the messenger saying they're shut) stops the train from the brake model. 3. Fill the coach from the
town's calendar: who rides Thursday's train comes from people's schedules, so the cost lands on named
people.

**Cut or simplify:** cut the siding (a new track branch for one mission, a switch normally padlocked in
1882, and "the town takes the wreck" repeats the pin and the derail).

**Doubtful about 1882:** Adair, the messengers and roof hand brakes hold up. But pulling a link-and-pin
coupler's pin under pull is very hard; by 1882 most passenger cars had automatic air brakes, so a
parted train brakes both halves unless the angle cocks are closed; the coach drifting to a stop needs
an uphill grade. And soldiers "sent to restore order" in 1882 run into the Posse Comitatus Act (1878):
the spine's problem, not only this card's.

## The build check (2026-11-09)

A fresh agent checked the adopted version against main's code (read only, file:line cited). Its
findings, short; the full table is in the session's record and summarised here.

- **Works today:** the break itself (`TrackChunk.tear_loose`, `track_state.gd`); dead passengers thrown
  by physics (`TrainWreck`); the wreck staying and the repair crew (`TrackRepair`).
- **Small:** the hand brake wheels (each car already has its own brake in `train_sim.gd`; one lever drives
  them all today); cab controls (the lab's throttle, brake, reverser); tending the messenger (point the
  player's `_tend` at another man); the foreman arriving at a set hour; the train blowing through the
  depot; Gang B's two men posted; authored lines.
- **Medium:** pulling the pin (`TrainSim` can't uncouple today; everything assumes one train); "tell
  them" (only two shout kinds exist, `drop_it` and `call_out`; a third, "rail's out!", is the way); the
  payroll in a strongbox; the stick-up man; jail and posters; gratitude (`Relations` has threat, grudge
  and fear only).
- **Large:** fighting on moving cars (train step 7: NPCs don't walk or take cover on moving bodies);
  people in the valley at all (`valley_world.gd:12`: no townsfolk, gang or saloon yet); the coach filled
  from townspeople's schedules (no schedules exist); the faction plan and Payday Night's mood.
- **Not feasible now / should change:**
  - **The engineer's lookout stops the train at the break by itself** (`train_lookout.gd:53`). Gang A has
    to hold him off the levers, so **freeing the engineer is a sixth way**.
  - **Air on the coach and express car alone (20% of the train) won't stop it under steam.** The cocks
    matter once the regulator is shut or the train is parted.
  - **"Only on slack":** the couplers have 6.5 cm of play, so slack lasts instants. Use "the coupler's
    force low for a moment".
  - **The freed coach rolls back east** on the +1.8% grade west of the depot unless its hand brake is
    wound: a consequence, or another job for the player.
  - **The chase on horseback can't be played** (the horse only idles and is tied); the late window is
    "board from the depot platform as it passes", at a speed the gang keeps low.
  - **There is no save system** (nothing writes `user://`), so "the line out for days" lasts one session.
- **The cheapest strong version:** the break found done, the foreman's warning and the blow-through; the
  hand brakes and air cocks as one change to the 1D brake model, cab controls and tending the messenger;
  step 7 at its narrowest (the gang at posts on the cars, the player moving); then the pin and "tell
  them"; the rest as flags and written lines until the valley has people and saves exist.
- **Size:** about 4 large (step 7's fighting, people in the valley and their schedules, horse riding,
  the faction plan and Payday's mood), 6 medium, 8 small, on top of train step 7.
