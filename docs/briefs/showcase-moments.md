# Showcase moments (Sean, 2026-10-21)

Moments that show off what Salt Creek's systems do together. **Each is a situation, not a
cutscene:** it's set up by placing people, props and a reason, then the systems play it out, so it
goes differently every time and the player can break it. A moment that only works with a special
case is a failure to report, not a script to write (`docs/briefs/labs.md`).

Where they live: each becomes a standing scenario in **the Systems Playground** (tested every
build), and the best become **missions** (roadmap 3.6 and later). The "needs" column is the parts
and systems it depends on (`docs/PARTS.md`).

## Sean's favourites

### The card cheat (Sean)

A man at the saloon table playing cards; he cheated someone the day before. The victim walks in
angry, kicks the back legs out of his chair and he goes over backwards; the victim draws, shouts,
and puts the gun in his mouth. You have seconds.

- **What you can do:** shoot the victim (a ball through him may hit the man on the floor); shout or
  draw so he turns on you; shove him; throw a bottle; shoot his gun hand so the gun drops; answer
  his "Tell me I'm wrong" with a nod or a shake; or let it happen.
- **What stays:** the cheater owes you his life, or the victim's friends want you, or a witness
  tells the deputy you shot a man defending his money. Some days the victim was cheated; some days
  he's lying.
- **Fits:** Phase 3's "saloon table" mission and the story's saloon-table prologue (DESIGN.md §5).
- **Needs:** a chair that breaks or tips (prop lab), the fall (ragdoll lab), confrontation and
  escalation, the nod, perception and witnesses.

### Men on the balcony, and dynamite takes out the timbers (Sean)

Men on the saloon's balcony (or a porch roof) above a boardwalk; dynamite under it blows out the
posts, and the balcony comes down with them on it.

- **Needs:** the balcony as members (in the game), `Blast` breaking timbers by energy (on the
  breakage lab's branch), the support graph dropping what loses its posts, falls and injuries,
  debris and dust.

### The night meeting that's a trap (Sean)

"Be at the feed store between midnight and three." You go in; it's an ambush. A sharpshooter
across the street fires through the window, or someone throws lamp oil at the front and it goes
up. The front is burning and there's no way out, except the dynamite in the back room: blow a hole
in the back wall and get out.

- **Make "no way out" true, not scripted:** a building chosen for it (a store room with barred
  windows and no back door, as the bank's `window_bars` already are), the front burning from real
  fire spread. Other ways out stay possible if the player finds them (an axe through the boards,
  shooting out a weak wall, the roof), and that's fine.
- **The tension the systems give for free:** smoke filling from the ceiling down (crouch to
  breathe), the fire reaching the dynamite before you light it, a blast in a small room hurting you
  (overpressure and the player's own wounds: find cover inside first), the sharpshooter waiting at
  the hole you make.
- **Fits:** a mission once time windows and messages exist (Phase 5).
- **Needs:** fire spread and smoke (in the game), dynamite and blast (in the game), the player's
  blast wounds, a sharpshooter's perception at night (muzzle flash gives him away), the time of day.

## More

| Moment | What happens | Needs |
| --- | --- | --- |
| Pushed down the stairs | An argument on the balcony turns into a shove; he tumbles tread by tread toward you | The stair's walking ramp (ragdoll lab branch), shoves (3.4) |
| Through the balcony railing | He breaks through, lands on a table that gives under him, bottles shatter, the room scatters | Breakable railing (to be promoted), the prop lab's table, shattering |
| The shot lantern | In a standoff you shoot the lamp over him: burning oil drives him from cover, smoke hides you both, a bucket line forms | Fittings, fire, smoke, bucket line (in the game) |
| The bar brawl | A man thrown over the bar into the back shelf: bottles shatter, whiskey runs to a lamp, the barman grabs the shotgun | Shattering and spills (prop lab), fire, the barman's brain |
| Cover that isn't | He hides behind the store's siding and your balls come through; he moves behind the bank's brick and they don't | Ballistics through materials, voxel carving (in the game) |
| The partner who won't leave | One outlaw drops; his friend drags him behind the trough and ties a belt on his leg: two men not shooting | Crew rescue (in the game), field first aid (treatment lab) |
| The gut shot who talks | Dying slowly: get him to the doctor, or let him say where the money is first | Physiology (in the game), the doctor (treatment lab part 2) |
| The dropped gun | A ball through his gun arm and the revolver falls; he scrambles for it left-handed | Anatomy and dropped guns (in the game), his brain picking it up |
| The sign | You shoot the chains of a hanging sign; it drops on the man under it | Hung fittings (prop lab) |
| The witness | You shoot an unarmed man in the alley and don't notice the boy at the end of it; next morning the deputy's waiting | Perception, law and witnesses, memory (Phase 5) |
| The doctor's table | You carry the sheriff in; the doctor probes for the ball while you hold the lamp; the ball matches a gun you've seen | The doctor (treatment lab part 2), evidence (5.6) |

New ideas go here first; a session that builds the parts for one says so in its row.
