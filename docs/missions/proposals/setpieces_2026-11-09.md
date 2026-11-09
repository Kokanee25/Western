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
