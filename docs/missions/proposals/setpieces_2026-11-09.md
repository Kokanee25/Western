# Two new set pieces: a proposal (2026-11-09)

**Proposed by the planning session at Sean's ask: "Can you think of any other big set pieces? That would be
a couple more fives, something that's never been done before, and it would meet the criteria for a
five."** Everything here is PROPOSED. Each is written to the rubric's §8: systemic, player-authored,
readable, varies (partial results), leaves a mark, and inside the frame budget.

---

## 1. The Water Tower (for `hold-him`, Hold the Jail)

Sean's showcase moment (2026-10-21): "Shoot out the tower's legs in a fight below; it comes down and floods
the yard, or falls on the jail's back wall and frees whoever's inside." This makes it a set piece whose
fall is decided by **how much water is in it**, and **the player's bullets drain it**.

**The place.** The town's water tower stands on four timber legs beside the jail's yard: a tank of about
40,000 litres (40 tonnes when full) on a frame 10 m up. Its frame is members on the support graph; the
water's weight sits on them as load. The jail's back wall is stone (DECIDED, #676).

**The situation.** The night Harlan holds a Colter in the cell (Hold the Jail), the gang comes for him. Their
plan, which the place shows (axes left at the tower's legs, a man seen measuring the drop): cut two legs on
the jail's side so 40 tonnes come down on the cell wing's back wall and open it.

**What the player can do, and what the systems decide:**
- **Drain it.** Bullet holes in the tank leak by the depth of water over them (Torricelli's rule, as the
  game's barrels already leak). Holes high on the tank drain a little; holes low drain it fast. A lighter
  tank is a lighter load: the legs may then carry it even with one cut, or it falls without the weight to
  break the wall. Every hole the player puts in it changes the fight's outcome, and the water runs into
  the yard.
- **Choose where it falls.** Which legs are cut decides the way it goes (the support graph tips it toward
  the cut side). Cut the far legs first and it falls away from the jail, onto the yard where the gang
  waits, or across the street they ride in by.
- **Let it come.** Full and on the jail: the stone wall breaks where the tank hits (the masonry rules); the
  cell may open, or the prisoner may be crushed.
- **A partial:** one leg cut, the tower leans and groans and holds, until a second cut, the wind, or a
  man climbing it to finish the job. A half-drained tank falls short and only cracks the wall.

**Readable:** the tank's level shows as the water jets from each hole and the jets weaken as it drains; the
tower leans and creaks by its load; the axes and the measuring man show the plan.
**Leaves a mark:** the wrecked tower, the broken wall or the crushed shed, the yard turned to mud, and no
water for the town (or the train) until it's rebuilt.
**Why it's new:** a structure whose collapse depends on a weight the player removes, round by round, with
the water's own flow; the same tower gives a different fall every time.

**Systems:** members and the support graph (exists); the water's weight as load on members (the trestle's
and Payday's pattern); leaking by depth (`PropContents`, exists for barrels: scale it to a tank);
the masonry wall's breach (being built, #663 step 8); water pouring as an effect (exists for barrels).

---

## 2. The Sap (for `barons-house`, the raid on the Baron's house)

DECIDED (Sean, 2026-11-04): the finale's raid on the Baron's barricaded masonry house: "blows open a wall,
and arrests him"; "The Baron must survive the breach". This gives that breach a set piece no game has: the
**sap**, the old siege way, dug under the wall by hand.

**Why Harlan knows it.** He was in the army in the war: at Petersburg in 1864 Union coal miners dug a gallery
under the Confederate line and fired a mine (the Crater). A hospital steward saw what came after. The miner
from Buried Alive (DECIDED: he teaches dynamite) knows how to dig and shore a gallery.

**The place.** The Baron's stone house on its rise west of town; barricaded, guns at every window, the
doors braced. In front, open ground under their rifles. Below the house, the creek bend and its bank, out of
their sight.

**What the player can do, and what the systems decide:**
- **Dig.** From the creek bank, a gallery toward the house's footings: earth taken out as the ground's
  height field (digging exists), slow, at night, by Harlan and whoever he brings (the miner, Joe).
- **Listen.** Sound carries through the ground and walls (sound placed through walls exists): the men in
  the house can hear digging if it's loud or close, and dig a counter-gallery or roll a powder keg down to
  it; the player can hear them too.
- **Undermine without a charge.** Take the ground from under a footing and the support graph decides: a
  corner settles, a wall cracks along its mortar (the masonry rules), a window frame jams. The house
  leans; the barricades inside shift.
- **Fire a mine.** A charge in the gallery's end: its size and how far under the wall it sits decide what
  happens: a crack, a settled corner, a wall fallen outward into a ramp, or the room above coming down.
  **The Baron must survive** (DECIDED): the player learns where he is (his voice, his light at a window)
  and chooses the wall and the charge so he does. Too much, under the wrong room, and the arrest becomes a
  burial.
- **Or not at all:** the open ground, a wall blown the ordinary way, a door. The sap is the way that costs
  nights instead of men.

**Readable:** the footings and the ground show where the house sits on earth and where on rock; the cracks
open
in the plaster as it settles; the defenders' counter-digging is heard.
**Varies:** every sap ends differently: how far you dug, where, how much powder, whether they heard.
**Leaves a mark:** the crater, the settled, cracked house, the gallery left in the bank; the town sees the
Baron's house leaning on its rise for the rest of the game.
**Why it's new:** undermining a building by digging, with the building's own support deciding how it
settles, and a charge sized against a man who must live: not in any game we know.

**Systems:** the ground's height field and digging (exists, `Ground.take`, 15–24 ms an edit in GDScript today;
a native step is planned); members and footings resting on the ground; masonry walls cracking and falling
(being built, #663, the Baron's house is its last test piece); dynamite and bundles (exists); sound through
earth and walls (exists for walls).

---

## Not chosen (other set pieces considered)

- **The ore bins at the Ore Works**: tonnes of ore held in timber bins over the siding, released by blowing
  the gates, sliding as loose earth onto the track and the men below (loose earth slides exist).
- **The powder magazine**: tonnes of dynamite in a stone magazine during a fight; likely beyond the frame
  budget (three bundles already fail it).
- **Lamps out**: a night fight where shooting out the street lamps one by one blinds the gang (sight by
  light exists): strong, but not a physical set piece.

---

## The set-piece judge (2026-11-09)

| Set piece | Score | Nearest |
|---|---|---|
| The Water Tower | **4 (high, close to 5)** | between the Shipment (4) and Payday (5) |
| The Sap | **4 (low)**: "the design is a 5, the build risk pulls it down" | above the Bridge on design, Buried Alive's risk |

**The Water Tower.** Systemic, player-authored, readable, varies, leaves a mark: all good. **But the core
lever fails the physics:** a .45 hole (~1 cm²) under 3 m of water leaks ~0.5 L/s; ten holes take ~2.5 h to
empty 40,000 L. *Raise:* 1. Honest draining: bullets are the slow cue; the real levers are the outlet valve
and spout pipe (a 15 cm pipe empties it in ~8 min) and **the iron hoops** (a stave tank is held by its
hoops: shoot or cut one and the staves spring, the tank empties in seconds, the surge knocks men down). 2.
The axes on a clock: two men take minutes a 12x12 leg, their strokes carry; a half-cut leg groans. *Cut:*
the wind as a trigger. *1882:* railroad water tanks were standard (timber frame, stave tank, iron hoops, a
spout); a town's own tower was rare: **make it the railroad's tank by the depot**, and "no water for the
train" is the true consequence. *New:* collapse isn't new (Red Faction Guerrilla, Just Cause,
Battlefield); removing the load that decides the collapse, the judge knows in no game.

**The Sap.** The strongest player-authoring and the best mark of any set piece; varies excellently (the
charge a moral dial). **Readable is weak** (underground; cracks only once the damage is done). **Build
risk very high:** `Ground` is a height field and can't hold a tunnel; sound through earth isn't built;
counter-gallery AI; a masonry corner collapse likely breaks the frame. Time: two or three men dig 2–3 m a
night, so the creek bank must be ~15 m from the footings. *Raise:* 1. A real sap, then a short mine: a
covered trench (the height field can dig that, behind a sap-roller), then only the last ~10 m a timbered
gallery from Buried Alive's sets and the railway's `TunnelPortal`. 2. Tamping and listening: an untamped
charge vents back down the gallery, a tamped one lifts; the defenders keep a bowl of water on the floor
(the siege listener), the player sees it ripple through a window, and his miner hears their picks. *Cut:*
the counter-gallery: they hear the digging and sally to the creek bank. *1882:* Petersburg (the 48th
Pennsylvania's miners, 30 July 1864) and Vicksburg's 3rd Louisiana Redan (1863) are true; a posse sapping a
house is a stretch a veteran makes believable. *New:* undermining exists in sandbox games (Stronghold,
Dwarf Fortress, 7 Days to Die); first-person and narrative, with a charge sized so a named man survives,
the judge knows none.

---

## The build check (2026-11-09)

- **Both rest on masonry that doesn't exist yet** (masonry lab step 3, S3–S6, isn't built; the jail is
  step 8; the Baron's house comes after the jail, bank, magazine and pier).
- **The Water Tower:** a tower as members is small (`Windpump` already builds four legs, girts and a
  platform); the water's weight as load on the platform is small (`extra_load`, updated on a level step, as
  the trestle does). **Bullet holes can't drain it in a fight** (by `PropContents`' own law ~0.5 L/s a hole:
  hours); **a stave broken out drains it in ~30 s** (the slot law). The support graph never tips a
  structure: the fall's direction must be a model (the trestle's `_topple`, aimed by the cut legs). No lean
  state (a creak by load, yes); no wind; no NPC climbing; no flood (water soaks into dirt: a burst and a wet
  decal). A falling tank breaking **timber** works today (rubble hits by energy); breaking **stone** needs a
  masonry impact rule. The gang chopping a leg: a scripted moment (N swings, then `break_member`, unless
  he's shot).
- **The Sap:** **no tunnel** ("a height field, which can't have a hole", `tunnel_portal.gd`); digging stops at
  2 m; **an open trench roofed with planks** is the historical sap and works. Ground taken from under a
  footing lets the stones over it fall (all or nothing per stone); settling and leaning aren't possible;
  cracks need the spec's §8 (medium); arching needs S3. No dig action for the player yet (medium; a hitch
  per stroke until the native step); the creek is ~175 m from the house pad, too far: dig only the last
  10–20 m in play. A `dig` noise the house can hear: small. Counter-mining AI: large. A tamped charge
  isn't modelled.

---

## Version 2 of both (2026-11-09)

### The Water Tower, version 2: the depot tank (for `hold-him`)

- **The railroad's tank at the depot** (`water_tank`, beside the depot and the freight warehouse; the
  judge: railroad tanks were standard by 1882, a town's own tower rare). A timber frame on four legs, a
  stave tank held by iron hoops, a spout swung over the tender, an outlet valve.
- **The night:** Harlan's prisoner waits for the morning train in the depot's freight room (No Justice's
  arrest ending sends him off by train, DECIDED pick; the story judge put Hold the Jail on that night). The
  kin or the gang come to free him. **The freight room is timber**, so the tank coming down on it breaks it
  by the rules that exist today, with no masonry needed.
- **Their plan shows:** two men with axes at the legs on the freight room's side, swinging; each stroke
  carries across the yard; a half-cut leg groans by its load. It takes them minutes a leg: **the axes are the
  clock**, and stopping the axemen is the timing skill.
- **Draining, honestly:** bullet holes are the slow tell (the jets show the level). The real levers: **the
  outlet valve and the spout** (open them and it drains in minutes, into the yard and the cut under the
  track), and **the hoops**: shoot or cut an iron hoop and the staves spring, the tank bursts in seconds,
  and the surge knocks men off their feet. A drained tank is a light load: the cut legs may hold it, or it
  falls without the weight to break the freight room.
- **Where it falls:** which legs are cut aims the fall (a modelled topple toward the cut side, as the
  trestle's bents fall): cut the far legs and it comes down on the yard where the men wait, or across the
  track.
- **Partial:** one leg cut, it groans and holds; a half-drained tank falls short and only stoves in the
  freight room's wall.
- **Leaves a mark:** the wrecked tower and the broken freight room stay; the yard is wet; **the daily train
  can't take water at Salt Creek**, so it stands at the depot or runs short until the tank is rebuilt (the
  timetable holding it: medium).
- **Cut:** the wind; the man climbing it; the flood (a burst and wet ground instead).
- **Needs:** a `WaterTower` from Windpump's build (small); the tank's kg as the platform's load on a level
  step (small); `PropContents` scaled to a stave tank with hoops and a valve (small–medium); the modelled
  topple (small, the trestle's); the axemen as a moment (small); the timetable holding the train (medium).

### The Sap, version 2: a covered trench and a short mine (for `barons-house`)

- **A sap, not a tunnel:** an open trench dug toward the house, roofed with planks and covered with earth
  as it goes (the period's sap: a covered trench), from a cut bank 15–20 m from the footings. The approach
  from the creek is done in the nights between (a time skip); only the last stretch is dug in play.
- **Reading the house:** from the rise you see where it stands on earth and where on rock (the west end
  sits on an outcrop: the sap must find earth). Through a window, **a bowl of water on the floor**: the
  defenders' siege listener; it ripples when you dig close. Plaster cracks open in the wall as the ground
  goes (the spec's crack warnings).
- **The defenders hear it** (a `dig` noise through earth and walls) and **sally out** to the trench: a fight
  at the sap's mouth, at night (no counter-mining).
- **Undermine:** take the ground from under the footing: the stones over the gap fall, a section of wall
  comes down into the trench, or (with the arch rule) an arched hole stays.
- **Or fire the mine:** a bundle at the sap's end, **tamped** (earth put back over it) or not: tamped, it
  lifts the wall; open, it blows back down the trench. **The Baron must survive** (DECIDED): find him first
  (his voice, his lamp at a window) and choose the wall and the charge.
- **Leaves a mark:** the trench and its crater stay; the house with its wall down stays on its rise.
- **Cut:** the counter-gallery; settling and leaning (stones hold or fall); the Petersburg-scale mine.
- **Needs:** a dig action for the player on `Ground.take` (medium; native editing planned); a plank roof
  over a trench (small, members); rock vs earth by area (small–medium); the `dig` noise (small); a tamped
  charge (small–medium on the blast); the masonry house with cracks and arches (masonry steps 3 and the
  Baron's house: the dependency).

**The judge on version 2:** the Water Tower **4 (close to 5)**: the best readability in the set and a low
build risk, but the motive doesn't hold (the men who came to free him would kill him with a full tank);
*raise:* split the aims between two groups; *cut:* the surge knocking men down (no flood system), and
"shoot a hoop" (a pistol ball won't part a wrought-iron band: strike off the hoop's lug). The Sap **4 (high
risk)**: the strongest player-authoring, readable (the rock and earth, the bowl, the cracks), but every
load-bearing piece is unbuilt; *raise:* shore the gallery under the footing with timber props so the wall's
weight sits on members, then pull or blow the props (the load path is timber; masonry only has to fall, S1/S2;
a badly propped gallery caves in on him); *cut:* the arched hole (needs S3); dig only the last 3–5 m in play.

---

## Version 3 of both (2026-11-09)

### The Water Tower, version 3: two aims for one tank

Everything in version 2, with these changes:
- **Two groups want the tank, for opposite ends.** The red shirt's friends come to **free** him: they need
  the freight room's far wall stoved in, so they want the tank **half-drained and aimed at the far end**, and
  they open the valve and set to the far legs. **The Baron's men** want him **dead** before he leaves on the
  morning train (he's the Baron's hired gun, DECIDED, and he knows who paid him): they want it **full and on
  the room**, and they set to the near legs. Both groups are in the yard the same night; each can see what
  the other is doing.
- **The player's levers now help one side and spoil the other:** open the valve and the spout (the friends'
  half-drained fall), close it or stop their man at the valve (the Baron's full fall), knock a hoop's lug off
  (a use action at the hoop: the staves spring and it empties in ~30 s, spoiling both), stop the near axemen,
  stop the far axemen, or cut the far legs himself and bring it down on the yard where both wait.
- **Read after:** what fell, how full, and on whom says plainly whose plan won.
- **Cut:** the surge knocking men down; shooting a hoop (a ball won't part a wrought-iron band).
- **Needs** (on version 2's): a use action on a hoop's lug (small, as E on a strongbox); two groups' agendas
  in one yard (the gang's agendas; small–medium).

### The Sap, version 3: the props are the load path

Everything in version 2, with these changes:
- **Shore the gallery.** The last stretch under the footing is dug out and the wall's weight is carried on
  **timber props** the player sets (members on the support graph, as Buried Alive's sets): the house now
  stands on them.
- **Then take them out:** pull a prop (a kick breaks a 10 cm prop; members break today), blow them with a
  stick, or burn them out (the old way; fire is out of play for now). The wall's stones drop when their
  support goes (masonry only has to fall: S1/S2, which exist); with fewer props pulled, a smaller section
  drops.
- **A badly propped gallery caves in** on whoever's in it: too few props, or one pulled too soon.
- **Partial:** each prop is a step: one out, the wall groans and holds; two, a section drops; all, the wall
  comes down into the trench. The Baron's room is where he is: the player sees it before he pulls.
- **Dig only the last 3–5 m in play** (the approach is the nights between).
- **Cut:** the arched hole (needs S3); the tamped mine as the main way (it stays as a choice).
- **Needs** (on version 2's): props as members the player places (medium: placing a member is new; the
  structure code builds members); the masonry house to sit on them (masonry S1/S2 exist; the Baron's house
  as a test piece is still the dependency).
