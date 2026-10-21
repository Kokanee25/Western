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
- **The punchline (Sean):** whatever happens, dead man on the floor or not, the barman's first
  words are about his furniture: "Jesus, Cody, my chair!" Make it a rule, not a line for this
  scene: **owners care about their own things first.** When something a person owns breaks, he
  reacts to the damage and names whoever did it (the barman's chair, the storekeeper's window,
  the doctor's lamp), at the right moment (once it's safe to talk), and remembers who owes him.
  It's the same joke every time it's earned, and it comes from ownership (DESIGN.md §10), which
  every prop and member can carry.
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

### The piano player (Sean)

A man plays the saloon's piano, and the music is the room's mood. When trouble breaks out, it stops
dead: a sour chord, a hand slammed on the keys, and silence. Driven by what he sees and hears, not
a script:

- **The room's tension plays through him:** the escalation ladder rising (raised voices, a man
  standing up too fast) and he plays quieter and slower, watching; a gun drawn or a shot and he
  stops mid-note and ducks behind the piano. A plain fist fight and he might play on, faster.
  When it's over and safe, he starts again, a little shaky.
- **The music comes from the piano:** a sound placed at the instrument, louder near it, muffled
  outside, so it stops exactly when he does, and the street hears the saloon go quiet.
- **The piano is a prop** (the prop lab): a ball through it plinks and leaves a sour key, a broken
  string twangs, a man thrown into it crashes a chord; he complains about it, as owners do.
- **The music itself:** period tunes whose compositions are public domain (Stephen Foster's
  songs, for instance), played from note data on a piano sound under a licence that allows
  redistribution and credited in `CREDITS.md`, cut into phrases so he can stop anywhere and pick
  up again. No commercial recordings.
- **Favourites and hated songs (Sean):** each tune is known in town, and people have opinions:
  the room's favourite gets them singing along and banging the table; the one they all hate gets
  boos, a thrown peanut, "Not that one again, Earl!". Opinions are per person, as everything else
  is: one old man loves the song the rest boo. The player can request a song (and tip him), pay him
  to stop, or pick the hated one on purpose to start trouble. Played often, a favourite wears thin.
- **How he looks like he's playing:** the body from mocap (someone sitting and miming: the sway,
  shoulders, leaning into a phrase, glancing at the room; iPhone capture is fine for this, not for
  fingers); **the hands from the same note data as the music.** Each note maps to its real key on
  a piano built at real size (standard key widths); the left hand takes the bass, the right the
  melody; the hand moves to the key just before the note (IK), a finger presses on the beat, simple
  fingering rules choose which; each key on the piano dips when played. Sound and hands come from
  one source, so they can't drift apart, and when trouble starts his hands freeze on the chord the
  music cut off on. **Fingers** need finger bones, which the Studio's men don't have yet (their
  hands are in the skin): until then the hands and wrists reach and strike in time, which reads
  right from across the room.
- **Needs:** perception (what he notices), the escalation ladder, sound placed in the room, the
  piano as a prop, a seated man who can duck (the furniture work).

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
| The water tower | Shoot out the tower's legs in a fight below; it comes down and floods the yard, or falls on the jail's back wall and frees whoever's inside | The water tower as members (to build), the support graph, water (to build) |
| Burning the gang out | The gang holes up in the livery; you light the hay loft and wait at the doors: smoke and men come out | Fire and smoke (in the game), the livery's loft, the gang's brains fleeing fire; horses later |
| The loft drop | You shoot the beam a man on the hay loft stands over; he and the hay come down together | Members and the support graph (in the game), falls |
| The next morning | Yesterday's fight left the store's front shot through and the barber's burnt out; people walk round the rubble, the storekeeper boards up the holes | Persistent rubble, world persistence and recovery lab (Phase 5) |
| Shot through the door | He hides behind a closed door; you fire through the panels, hear him fall, open it and find him alive, holding his leg | Ballistics through doors (in the game), wounds, his words following his blood loss |
| The amputation | A crushed leg after a collapse; the doctor needs you to hold the man down | The doctor (treatment lab part 2) |
| Bleeding out mid-fight | You're hit in the thigh: tie it off now, both hands busy and exposed, or finish the fight first | Field first aid (treatment lab part 1), the player's wounds |
| The bluff | Three men, one bullet left; you cock the hammer loud anyway; whether they back down depends on their nerve and what they've seen you do | Confrontation and escalation, nerve, deeds |
| Hide and search | You hide under the boardwalk after a robbery; men search with lanterns, light sweeping the gaps between the planks, one standing on the plank over your face | Perception with light and last-known positions, the boardwalk |
| The rumour | You help the doctor's wife in the morning; by evening the barman has heard, and your drink is on the house (or the opposite) | Memory and news spreading (perception lab, Phase 5) |
| Recognition | You robbed the stage in a bandana yesterday; today the driver is in the saloon, staring at your coat | Recognition and disguise (DESIGN.md §10) |
| A round on me | You buy the room a drink; faces change, someone tells you what they wouldn't have, the man who hated you is outnumbered | "A round on me" (DESIGN.md §10), money (5.1) |
| The spilled lamp | A drunk knocks a lamp off a table and the room scrambles to stamp it out before it takes | Fittings, fire, people reacting to fire (in the game) |
| The bucket line | The livery's alight; the town forms a line from the trough on its own; you join it, lead it, or rob the empty store | Bucket line (in the game), town life, deeds |
| Target practice | Tin cans behind the livery at dusk; the gun feels heavy, the cans jump, your skill grows by using it | The guns (3.2), skills by doing (DESIGN.md §6) |

New ideas go here first; a session that builds the parts for one says so in its row.
