# Townsfolk: the town behaving like a town, on the slice's ground

Issue #850, a design session, 2026-11-12. **Docs only: nothing here is built and nothing in the game
changed.** Lane: gameplay (people), with sound (#807, #810, #799) and a little from characters and props.

**Status words.** **DECIDED** = Sean's words, with where he said them. **PROPOSED** = this brief's;
everything not marked DECIDED is PROPOSED, including every number, name, hour and line. Sean's picks
are asked for in #851 (the `waiting on Sean` issue for this brief).

## On one screen (for the phone)

- **The aim (DECIDED, Sean 2026-11-12):** after the first three missions the slice is polished, and part
  of that is "having the npcs start behaving realistically".
- **The ground:** the valley's town only: the saloon, the doctor's, the jail, the store, the livery,
  Main Street and the roads the missions use. The people: about 16 townsfolk plus the story's cast.
- **Six pieces, cheapest first:**
  1. **A day for each person** (home, work, meals, the saloon, sleep) as data. Someone asleep or indoors
     behind a front costs nothing: he's "on the book", shown by a lit window and chimney smoke.
  2. **Things to do where they stand** (lean, sit, sweep, mind a counter), so nobody stands like a post.
  3. **Reactions in stages** (start, look, decide, come back), by each person's nerve, nosiness and
     sense of duty. One runs for the doctor. A ring of gawkers forms round a body.
  4. **News that travels** from mouth to mouth, visibly, a little wrong each time, and is all over
     town by morning.
  5. **How the town treats Harlan** after each mission, from the story's facts: who greets him, who
     goes quiet, what they say (about 60 short lines for #807's pipeline).
  6. **The saloon as a room** (#810): every laugh, toast and argument from a man you can see doing it;
     trouble hushes the room and stops the piano.
- **Cost:** 12 people near you and 12 farther off fit the 4 ms people budget at Sean's by today's
  numbers (about 3.4 ms). The first build step measures that before anything is added.
- **Judged by:** a blind 10-minute walk with no mission ("did the town carry on without Harlan?"),
  plus counts in the labs (who's where each hour, who knows what and how, no laugh without a laugher,
  nobody appearing in view, the frame).
- **The build plan** is 11 one-session steps at the end. It starts when Sean says (after the first
  three missions, by his words); steps 1 and 2 could go sooner because No Law's morning after (#796)
  wants a town to walk through.
- **Sean's picks (#851):** how many townsfolk and whose faces; how the town treats the deputy after
  Kett is turned loose; after Joe's revenge; the saloon the night the sheriff dies; far-off sounds
  without animals.

## 1. What exists, and what's missing

Read for this brief (the next session can skip them): DESIGN.md §5 "A day in Salt Creek", §9, §10's
opening; LAYOUT "src/people"; `config/valley_folk.json`; `experiments/perception_lab/README.md` and
`baseline/baseline.md`; #276 and its six comments; #810; #807; `docs/story/OUTLINE.md` Act I,
`VOICES.md` "Smaller voices" and "Who knows what", `WORDS.md`; the three scripts' town lines
(`docs/scripts/*.json`); `config/valley.json` `town` and `places`; `docs/briefs/more-cores.md` step 4b.

**Use, never rebuild** (all in the game today):

| Need | What's there |
|---|---|
| Who's in town when | `ValleyFolk` + `config/valley_folk.json`: `hours`, a `from` place, one `post`; walks in and out by the town's ways (~560 places); prebuilt bodies kept out of the tree |
| A townsman's mind | `CivilianBrain`: a post, hands up, cower, thanks, `gun_out` unease, the line gaps (`SAY_GAP`, `CRY_SPREAD`, `hush`), chores |
| Things to do | chores `WipeBar`, `MopFloor`, `SitChore` (+ `Seating`), `CardGame`; `BucketLine`; `FaceLife.attend_to`; `MotionClip`/`play_clip` |
| Eyes and ears | `Senses`, `SightLight`, `Events.noise`, `Events.deed`, `DeedWatch`, `PlayerDeeds`, `Relations` (the ladder, per person) |
| The story's facts | `StoryState` (`set_fact`, stamped with the clock): `sheriff.care`, `nolaw.murder`, `nolaw.seen_from`, `coach.*` |
| Cheap far people | `PeopleTick` bands (every 2nd tick past 25 m, every 4th past 60 m; never slowed when in trouble) |
| Sound placed | `GameAudio` (delay by distance, walls, rooms); the scripts and listening board (#807); the fiddler (#799) |
| Scenes from data | Acts and moments (`src/moments`), `HeadGesture` |

**Missing** (what this brief designs):

1. **A day.** A man has one window of hours and one post. No home, no meals, no second place.
2. **Nothing to do** at a post but the barkeep's chores and the card game.
3. **One-step reactions.** A shot gives hands up or cowering at once; nobody looks first, runs for
   help, peeks, gathers or comes back in stages.
4. **News can't pass.** The perception lab's baseline: the deputy never learns of a shooting next door
   ("there is no way for news to pass"). Nothing spreads and nothing is misremembered.
5. **The town has no view of Harlan.** `Relations` is per pair and for fights; no line or greeting
   reads the story's facts.
6. **The saloon is a set**, not a room: no crowd, no laughter with a source, no music yet.

**Two faults to settle first** (the perception baseline's, 2026-10-22; step 1 re-measures what later
fixes changed): a shot named its shooter to everyone who heard it, and men acted on what they couldn't
know. Reactions and news built on top of leaks would look wrong however good the rest is.

## 2. Who lives here (the slice's roster)

**DECIDED:** roles only, no names, until a script needs one (Sean, #830, C14 c). Named already: Earl,
Cody, Joe, Silas Kett. **DECIDED:** no animals but horses (Sean, #276).

Sixteen townsfolk (pick 1 in #851 is the number). Dials are 0 to 1: **nerve** (stays when frightened),
**nosy** (comes to look), **duty** (helps, fetches, tells).

| # | Who | Works | Sleeps | Nerve / nosy / duty | Face today |
|---|---|---|---|---|---|
| 1 | Barkeep (owns the saloon) | saloon | over the saloon | .7 / .4 / .6 | `barkeep_s2` |
| 2 | Doctor (the coroner; acting sheriff from day 2, DECIDED C12 a) | doctor's | behind the dispensary | .9 / .3 / 1 | `doctor_s2` |
| 3 | Storekeeper | general store | over the store | .3 / .6 / .5 | `storekeeper_s1` |
| 4 | Storekeeper's wife | store, the house | over the store | .5 / .9 / .7 | none |
| 5 | Livery man | livery | the livery's loft | .6 / .5 / .6 | none |
| 6 | Blacksmith | smithy (west end) | behind it | .8 / .2 / .5 | `blacksmith_s1` |
| 7 | Undertaker (the carpenter too) | his shop (east end) | there | .8 / .7 / .4 | none |
| 8 | Hotel's landlady | hotel | hotel | .6 / .8 / .6 | none |
| 9 | Preacher | church (north-west) | by it | .5 / .4 / .9 | none |
| 10 | Piano player | saloon, nights | hotel | .2 / .5 / .2 | none |
| 11 | Fiddler (#799) | saloon, nights | hotel | .4 / .5 / .2 | none |
| 12 | Miner (off shift) | the mine (off the ground) | hotel | .6 / .5 / .4 | `miner_s4` |
| 13 | Rancher | his place (off the ground) | out of town | .7 / .3 / .5 | `mexican_rancher_s1` |
| 14 | Drifter | odd jobs, the livery | the livery's loft, on credit | .4 / .6 / .2 | `young_drifter_s3` |
| 15 | Loudmouth | freight, when sober | a shack on the rear lane | .5 / .8 / .1 | none |
| 16 | Saloon woman | saloon, nights | over the saloon | .6 / .6 / .4 | `working_girl_s3` |

- **The cast, placed by the story, not by a day:** the sheriff (the doctor's bed, then his grave), his
  wife (her homestead; in town day 2 and at the funeral), Earl (the card table until night 1; then the
  undertaker's), the stranger (the Baron's foreman), Cody, the Baron (the funeral), Joe (the doctor's,
  No Justice), Kett (the jail, arrest ending), a freighter (day 1 if Harlan left the sheriff).
- **Faces:** 14 talking models exist, and 8 of the 16 above have one of their own. The other 8 need a
  face (pick 1). A second man wearing a principal's face is noticed up close, so doubles are only for
  men who stay far or have their backs to you.
- **Off the ground:** the mine's shift, the depot, the Railroad Saloon, the houses' insides. Their
  people come and go by the roads and are heard (the whistle, the cars), not simulated.

## 3. Each person's day

**DECIDED:** a 45-minute day (DESIGN §3), so a clock hour is under two minutes: nothing in a schedule
is shorter than half an hour or the player never sees it. **DECIDED in outline** (DESIGN §5): dawn,
morning errands, noon when the street empties, afternoon work, evening when the saloon fills, night.
**DECIDED** (Sean, #276, 2026-10-22): the town runs on a calendar (daily rounds, freight, the stage,
payday), which the story uses; it isn't a list of events placed in the story.

### The data

`config/valley_folk.json` grows from `hours` + `post` to a **day**: an ordered list of blocks. A block
is `{from, at, do}`: an hour, a **spot** (below) and what he does there. The last block runs to the
first. A person may carry more than one day, picked by the town's **day kind**:

| Day kind | When | What changes |
|---|---|---|
| `ordinary` | default | as the table below |
| `mourning` | from the sheriff's death to the evening after his funeral | no music; store and saloon shut for the funeral's two hours; quieter talk; black armbands (a prop, later) |
| `uneasy` | the day after any killing in town | fewer on the street after dark, doors barred an hour early, some men heeled |
| `payday` | **not in the slice** (DECIDED rowdier, Sean #276 2026-11-01; it belongs to Payday Night) | the room director's dials only; the data shape allows it |

The day kind is one value the town keeps, set from `StoryState` facts and the town's news (section 5),
never by a mission script calling people about.

### Three ways of being present

**DECIDED in principle** (Sean, #276, 2026-11-03, the Living World plan): far away, schedule and place
only; nearby, ambient motion; close and involved, the full man. A few rich characters, quality over
headcount; nothing spawns in view. Here that is:

1. **On the book.** Not in the tree, no body, no cost: a row saying where he is and what he's doing
   (asleep over the store; at supper in the hotel). The building shows it: a lamp lit or dark in his
   window, chimney smoke at breakfast and supper (#276's 34). Anyone inside a building that is only a
   front (no interior yet) is on the book.
2. **Out and far:** a body under `PeopleTick`'s bands, at a spot or walking a way.
3. **Out and near:** every tick, face and all.

**Onto and off the book happens at a door**, and only when the player can't see the last step (the
door shut behind him, or the door out of sight). If the player is watching the door of a front, the
man goes in and the door shuts: gone behind it. This is #689's "gone only out of sight" for 1A-3A; if
Sean picks B there, fronts' doors still hide it. A man the player follows into a real interior (the
saloon, doctor's, jail, store, livery) stays a body.

### Spots: something to do where you stand

A **spot** is a named place with a facing and an activity (the idea of The Witcher 3's activity
spots, named in #276's plan; our own code). Spots belong to a building's or the street's data, not to
a person, so anyone sent there fits. The slice needs nine kinds, each a `CivilianBrain` chore like
`WipeBar` (it has him while he's calm, stops the moment he isn't):

| Kind | What you see | Reuses | New motion needed |
|---|---|---|---|
| `stand` | weight shifts, looks about, hitches his belt, hat pushed back in the heat (#276's 9) | idles, `FaceLife` | 3-4 fidget clips |
| `lean` | a shoulder or a boot on a post or rail | `reach_to` | 1 pose and its in and out |
| `sit` | bench, chair, step | `SitChore`, `Seating` | none |
| `counter` | behind a counter or bar: writes in the book, weighs, faces a customer | `WipeBar`'s customer rule | 2 clips |
| `sweep` | the boardwalk each morning (#276's 17) | `MopFloor`'s stroke | a broom (prop lab) |
| `carry` | a sack, crate or bucket from A to B and set down (one carry serves the porter, the bottles, the firewood: Sean, #276) | the bucket's carry | 1 lift, 1 set-down |
| `talk` | two or three face each other, hands move, mouths move, low walla (#810) | `FaceSpeech`, `attend_to` | talk gestures (#810's mocap) |
| `drink` | at the bar or a table: glass up, down, a look round | cups, `reach_to` | 1 clip |
| `play` | the piano, the fiddle (#799) | the music system | #799's |

Transitions carry it (Sean, #276: "hammer, pause, inspect, rub a shoulder, hammer again"): every
activity is a loop with two or three small breaks, picked by seed, never one clip on repeat.

### The ordinary day, and what the street shows

| Hour | From the street | Who's out (bodies) | On the book |
|---|---|---|---|
| 5-6 | first grey; the smithy's glow and the livery's lamp; two chimneys start | blacksmith, livery man | everyone else, asleep |
| 6-7 | the storekeeper sweeps his walk; the landlady shakes a rug off the porch rail; hammer on iron | + storekeeper, landlady, drifter (forking hay) | 11 |
| 7-12 | the store open, a wagon at its dock; the doctor crosses to a call and back; two on the store's bench; the undertaker planing at his door | + doctor, wife (store, then the walk), undertaker, loudmouth (carrying freight), preacher (one walk down Main Street) | barkeep, piano player, fiddler, saloon woman asleep; miner and rancher away |
| 12-13 | dinner: the street nearly empties; men in the shade of the awnings (#276's 41) | 2-3: the bench, the livery's door | most, at table |
| 13-17 | work again; the rancher's horse at the store's rail; the barkeep rolls a keg in by the lane | + rancher (store, livery), barkeep (16 on) | |
| 17-19 | lamps lit (the saloon's at 17, as built); supper smoke; the store shuts at 18; the first drinkers go in | barkeep, saloon woman, piano player; storekeeper locks up | families, at supper |
| 19-23 | the saloon loud from down the street (#810); two on the hotel's porch; lit windows over the store | saloon: section 6 | wife, landlady, preacher, undertaker (home; the undertaker takes one drink at 20) |
| 23-3 | thinning; a drunk goes home singing (#276's 43); the livery's lamp is the last out but the saloon's | barkeep, the last three | the rest |
| 3-5 | dark and still; one lamp at the doctor's if he has a patient | nobody | all |

- The mine's whistle at shift change and the cars at the depot are **sounds only** on this ground, at
  their calendar hours.
- **Church** in the slice is the funeral's bell and the walk up Church Lane. A Sunday waits for the
  calendar past the slice.
- **Harlan's badge changes nobody's day.** It changes how they meet him (sections 4 and 5).

### Who must be where for the story

A mission **asks** the town for people (the way No Law's act `take`s Cody) and gives them back; it
never moves them itself. What the slice's beats need, checked against OUTLINE Act I and the scripts:

| Beat | Needs | From the day or asked for |
|---|---|---|
| Day 1 morning, the sheriff brought in | the doctor at his door; the livery man for the bay; 2-4 on the street to see it | the day (7-12 has them); the doctor is asked to his door |
| Day 1, if Harlan left him | the freighter brings him in; the same watchers | asked (the freighter isn't a townsman) |
| Day 1 evening | townsfolk at evening spots with the day's news (script `no_law` "town") | the day + news (section 5) |
| Night 1, No Law | barkeep, Earl, drifter, miner, rancher at their places; the stranger and Cody | the day; the act takes the two |
| Night 1, after | the room empties; the barkeep stays; nobody runs for the law (**built line, DECIDED:** "Ain't nobody left to fetch") | reactions (section 4): the runner has only the doctor to run to |
| Day 2 morning | the undertaker with Earl; the versions on the street; someone sent to find Harlan (`morning.sent_for`) | news + a runner with a message: the same runner as section 4 |
| Day 2, the sheriff dies | the doctor, the sheriff's wife | asked |
| The funeral | everyone but the blacksmith and the barkeep (who shuts for it and comes late) walks up Church Lane behind the box; hats off; the Baron and his foreman | a day kind's block (`mourning`: 2 hours at the cemetery's spots), not an act; the Baron and foreman asked |
| No Justice, the doctor's | Joe; the doctor | asked |
| After the arrest | Kett in the cell; his meal carried over from the hotel (#276's 36) | asked + one `carry` |
| After the revenge | the bodies brought in on a wagon; the undertaker measures (#276's 20) | news + `carry` |

## 4. Reactions that read as real

**DECIDED** (DESIGN §9): nobody is an enemy by default; deeds are judged the same for everyone, by
what each person saw or heard; every step of the ladder is readable and reversible. **DECIDED** (§10):
sound travels; people investigate, flee or fetch the law. **DECIDED** (Sean, #276): bystanders gawk
after a fight, at a distance; not every event wants a response, sometimes you just witness it.

**The rule under all of it:** a person acts only on what he sensed or was told, after the time it took
to reach him. Sound already arrives late with distance (`GameAudio`); the reaction waits for the same
delay, so a street reacts as a wave moving out from the shot, never all on one frame.

### Four stages (one small state machine in `CivilianBrain`, the same for every stimulus)

1. **Start** (0.15-0.5 s after it reaches him, by nerve): a flinch, the head snaps round, hands stop.
   A seated man half rises. Nobody speaks yet.
2. **Look** (0.5-2 s): he turns to where he *thinks* it came from (his own guess, wrong through
   walls), and reads it: can he see a gun, a man down, flame, who?
3. **Decide**, from his dials and what he read (table below): **flee**, **hide**, **freeze**,
   **watch**, **help**, or **carry on**.
4. **Come back** (when he's sensed nothing new for a calm time of 20-90 s, longer with low nerve):
   a look round the door or over the bar first, then out, then back to his spot, then his chore. He
   stays **shaken** for an hour or so of the clock: a hand not quite steady, looks toward where it
   happened, starts at the next noise sooner.

The choice is a score, no script: `fear` (from the stimulus, nearer and seen is more, a friend hurt
is more) against `nerve`; then `nosy` and `duty` split the brave.

| What he's sensed | Reach | Low nerve | Nosy | Dutiful | Everyone |
|---|---|---|---|---|---|
| A shot heard, unseen | the town | indoors or behind something solid | to a door or window, looks toward the guess | goes toward it slowly, stops at a corner | work stops for a breath |
| A shot seen, or a man hit | sight | flee away from the gun, along the ways, to a door | watch from 15 m or more, from cover | if the shooter has gone: to the man down | hands off anything like a weapon |
| A gun drawn, not fired (built: `gun_out`, 9 m) | 9 m seen | backs away, finds a reason to leave | stays, watches the hand | says a line, or steps between only if duty and nerve are both high | talk drops |
| A fist fight | 12 m seen | steps back | **gathers**: a ring at 3-4 m, takes a side by liking | the barkeep or the biggest man parts them after a few blows | chairs pulled clear |
| A body lying | 20 m seen | stops, turns away, crosses the street | **the gawk ring**: 5-8 m back, hat off, points, talks (#276's 19) | kneels, feels for life, calls for the doctor | nobody walks through it |
| A blast | the town | flat, then runs from it | comes after a full minute | toward it, calling names | horses pull at the rail (built) |
| Fire seen (built: 30 m, `BucketLine`) | 30 m seen | away, shouting "Fire!" | watches from across the street | the bucket line | the store's owner carries his book out first |
| Harlan's badge, from day 2 | 6 m seen | a step aside, eyes down | watches what the deputy does | comes **to him** with what they know | a drawn gun near him is put away sooner |

### Who runs, and to whom

- **One runner an event.** The calm person with the most duty who has seen a man down runs for the
  **doctor** (to wherever the doctor's day has him), and says it on arrival; the doctor takes his bag
  and comes at a fast walk. If two start, the second sees the first go and stays.
- **For the law:** on day 1 there is nobody to run to, and the barkeep's built line says so. From day
  2 the runner for the law runs to **Harlan** if anyone knows where he is (seen within the hour), and
  to the doctor (the acting sheriff) if not. "Deputy! Down at the livery, quick!" is the same runner
  with a different door.
- **The runner really carries it:** he knows only what he sensed, tells it on arrival (a news event
  handed over, section 5), and it takes the time the ground takes. A player can stop him, follow him
  or get there first.

### What makes it read

- **Heads before feet.** The cheapest true thing: everyone who heard it looks, at their own delay.
- **Not everybody the same.** With 16 people and three dials no two do the same thing at the same
  moment. The blacksmith keeps hammering through a shout; the piano player is under the piano.
- **Doors.** People flee *to* somewhere on their ways: their own door, the store, the saloon. A door
  shuts and a face shows at the window.
- **The slow return** is what shows it mattered.
- **It costs the player something:** shoot in the street at noon and the street is empty for an hour;
  the store is shut and the storekeeper won't serve a man he watched do it.

## 5. Memory and talk

**DECIDED** (DESIGN §9, memory): events as small records; a town event stored once, each person
storing *how* he knows it (saw it, heard it from the barber); rumours can be wrong versions; opinions
as numbers driving everyday behaviour with no AI. **DECIDED** (Sean, #276, 2026-10-22): "the morning
after a shooting, men at the bar retell it, getting it a bit wrong." **DECIDED** (Sean, #807, and
DESIGN §9): people speak written, recorded lines keyed to the moment, the most specific that fits;
nothing is voiced before Sean's Script OK.

### The town's news (a new small part: `TownNews`)

- **One record an event:** what (a killing, a shot, a fight, an arrest, a death, a burial, a fire),
  who did it, to whom, where, when, how big (0-1).
- **Each person holds a version of it**, and how he got it: `saw`, `heard it happen`, or `told by X`.
  A version is the record's slots as *he* has them: **who, whom, why, how** (shots, drawn first).
  A slot he didn't sense is empty. `Senses` fills them at the event and nothing else may: this is
  where the perception lab's leaks are shut out.
- **Telling:** two calm people at spots within 3 m of each other, one holding news the other lacks,
  pass the biggest piece: they turn to each other (`talk`), it takes 6-10 s, and the hearer's version
  is the teller's with, by seed, one chance in three that one slot is dropped or swapped for a likely
  wrong one (Earl "drew first"; "three shots, or two"). The script's `morning.versions` lines are
  exactly these versions spoken.
- **Where it moves:** wherever the day puts two people together: the store's counter, the bench, the
  bar, the livery's door. The storekeeper's wife (nosy .9) is the town's telegraph by her dials alone.
- **Overnight:** at the day's turn, anything of size 0.5 or more reaches everyone in town as `told by`
  (K5 in VOICES: the town knows Cody killed Earl by the morning). Small things fade.
- **Harlan can watch it move, and be in it:** what the player did where nobody saw stays unknown; what
  one person saw is all over town by morning; a version that's wrong about him is one he can meet.
- **Secrets hold:** a line that gives away one of VOICES's K1-K13 before its beat is wrong. The news
  can only carry what a townsman sensed, so K2-K4 can't leak: nobody in town saw them.

### How the town treats Harlan

Each person keeps the opinions DESIGN already gives him (trust, fear, liking, respect), nudged by
news events about Harlan as *that person's version* has them. The town's **regard** is the plain
average, used for the room's mood and the paper later. Regard changes what you see before anyone
speaks:

| Regard | What you see |
|---|---|
| Warm | a nod or a touched hat as you pass; the barkeep sets a glass down unasked; talk goes on when you come in |
| Wary | looks that slide off; talk drops and picks up; the storekeeper serves you last |
| Cold | a turned shoulder; the store's blind comes down; a woman crosses the street |
| Afraid | the walk clears ahead of you; nobody meets your eye; doors shut |

**The slice's facts, and what each does** (facts as `StoryState` holds or will hold them; the regard
shifts are in section 5's dials, the lines in the table after):

| Fact | Who knows, and how | The town after |
|---|---|---|
| `sheriff.care` good or poor | whoever was on the street as he came in (saw); the doctor (knows which) | curious about the man from up the creek; the doctor's respect if good |
| `sheriff.care` left | the freighter tells it; the sheriff said a name "Harlan, or near it" (script) | wary to cold; warms if he's sworn in and does the work |
| `nolaw.seen_from` table | the room saw him sit and not move | split: "what could he do, unarmed" and "he never moved" (script `morning.you_were_there`) |
| Sworn by nod, or after the shake | the doctor, the sheriff's wife; the town by noon | "Deputy" from most; a few test it |
| The funeral: stood at the grave, watched from off, or stayed away | everyone there | attended: the widow's word carries; stayed away: noted, said once |
| No Justice, **arrest** (Kett in the cell) | he rode in with a bound man: the street saw | respect up: the first thing the law has done since the sheriff. Fear of who Kett rides with |
| ...then **Kett turned loose** on the platform (C8 a, PROPOSED until Sean nods on #830) | the depot's people saw; all over town by dark | pick 2 in #851 |
| No Justice, **revenge** (Joe killed and scalped him) | nobody saw; the bodies come in on a wagon; the town guesses | pick 3 in #851. **DECIDED** (Sean, 2026-11-09): "the town splits" |
| Harlan **shot the surrendered man** | Joe saw; the town has only the body and Harlan's word | cold from those who work it out; this is the one the paper remembers |
| Kett **killed in the fight** | the bodies | plain respect and some fear: "the deputy went up there and came back" |

### What they say

The lines go through #807's pipeline unchanged: a script `docs/scripts/town.json` in the same shape as
the three there (id, speaker, trigger, when, condition, delivery, 2-3 wordings), Sean's Script OK, then
takes. **Pools, not people:** townsman, townswoman, loudmouth, barkeep, storekeeper, livery, undertaker
(DESIGN §9: townsfolk share pools by type). **Rules:** the most specific line that fits wins; a person
says a given line once a day; nobody repeats a line another said in the last minute; never more than
one bark at Harlan as he passes a group; a bark needs the speaker to *hold* the news it speaks of.
WORDS.md's rules apply (short, understated, titles, no slurs from the town). **No line here says
Harlan's name:** "Deputy", "mister", or nothing (DESIGN §9), except the lines already written.

The slice's set, about 60 lines. The existing scripts already hold the day-1 evening, morning-after
and funeral lines (`no_law` "town", "morning", "funeral"): they stay where they are and aren't
repeated. New, all PROPOSED, a first wording each:

| Id | Pool | Said when | Words |
|---|---|---|---|
| `day.morning` | townsman | you pass, regard warm, before 10 | "Morning." |
| `day.heat` | townsman | at a `lean` spot, noon | "Hot enough to curl a board." |
| `day.store_last` | storekeeper | regard wary, you at his counter | "Directly. There's others before you." |
| `day.shut` | storekeeper | regard cold | "We're shut." |
| `day.freight` | loudmouth | carrying, anyone within 4 m | "Mind your feet. This ain't feathers." |
| `react.shot_far` | townsman | heard a shot, unseen, stage 2 | "That was a shot." · "Up the street. Was that up the street?" |
| `react.inside` | townswoman | heard a shot, fleeing | "Get in. Get in and shut it." |
| `react.who` | townsman | at the gawk ring, doesn't know who | "Who is it? Can you see who it is?" |
| `react.knows` | townsman | at the ring, his version has `whom` | (the fact as a separate take: "It's Earl." · "It's one of the freight men.") |
| `react.doc` | townsman | duty, sees a man down | "Somebody fetch Doc!" · "I'll go. Don't move him." |
| `react.runner` | townsman | the runner, reaching the doctor | "Doc! Man shot, front of the livery. He's breathing." |
| `react.runner_you` | townsman | the runner, reaching Harlan (day 2 on) | "Deputy! You'd best come. There's trouble at the saloon." |
| `react.gun` | barkeep | a gun drawn in his room | "Not in here. Take it in the street." |
| `react.gun_you` | townsman | Harlan draws near him, regard warm | "Easy now, Deputy." |
| `react.fight` | loudmouth | the ring round a fist fight | "Let 'em have it out!" |
| `react.fight_stop` | barkeep | parting them | "That'll do. That'll do, I said." |
| `react.back` | townsman | stage 4, coming out | "Is it done?" · "Is he gone?" |
| `react.shaken` | townswoman | shaken, within the hour | "My hands won't quit." |
| `react.body_child` | townswoman | at the ring | "Come away. That's nothing to look at." |
| `news.tell` | any | telling (mostly walla; one clear opener) | "You hear about last night?" · "You hear? Down at the saloon." |
| `news.wrong` | townsman | his version has a swapped slot | "Two of 'em, I was told. One held him." |
| `news.dont_know` | townsman | you ask, his slot is empty | "I only heard it. I never saw a thing." |
| `sheriff.sinking` | townswoman | day 1 evening to his death | "He's poorly. Doc's not left him." |
| `sheriff.gone` | townsman | `mourning`, first hour | "He's gone. This morning." |
| `sheriff.gone_care` | townswoman | `mourning`, `sheriff.care` good | "You gave him a night with his wife, mister. That's something." |
| `sheriff.gone_left` | townsman | `mourning`, `sheriff.care` left | "Some rode right by him, I hear." (not to Harlan's face: said as he passes) |
| `deputy.first` | townsman | first sight of the badge | "Deputy, is it. Well." |
| `deputy.for` | townswoman | badge, regard warm | "I'm glad somebody's wearing it." |
| `deputy.against` | loudmouth | badge, drunk | "A nester with a tin star. Lord help us." |
| `deputy.cody` | barkeep | badge, Cody not yet taken | "He'll walk back in here, you know. Bold as before." |
| `uneasy.bar` | storekeeper | `uneasy`, shutting at 17 | "I'm barring the door tonight. You'd do the same." |
| `uneasy.heeled` | townsman | `uneasy`, wearing a pistol | "Never wore it in town before. I'm wearing it now." |
| `kett.cell` | townsman | arrest, Kett in the cell | "You brought him in alive. I'd not have troubled." |
| `kett.cell_woman` | townswoman | arrest | "Is that him? He don't look like much, behind a door." |
| `kett.meal` | landlady | carrying his tray | "He eats what the house eats. He'll not thank me." |
| `kett.fear` | storekeeper | arrest | "And when his friends come for him? Who stands at that door, you and Doc?" |
| `kett.loose.*` | by pick 2 | Kett turned loose | (three sets written to Sean's pick: blames the Army; split; turns on Harlan) |
| `kett.street` | townsman | Kett walking Main Street | "That's him. Walking about like a man with a receipt." |
| `revenge.wagon` | undertaker | the bodies in | "Five. And one of them wants a closed box." |
| `revenge.for` | townsman | revenge, his liking of Harlan high | "Whoever did it saved the county a rope." |
| `revenge.against` | townswoman | revenge | "Cut like that. And the deputy rode with the man who did it." |
| `revenge.ask` | loudmouth | revenge, drunk | "You were up there, Deputy. Who took his hair?" |
| `fight.back` | townsman | killed in the fight | "Went up there with one man and came back. I'll say that for him." |
| `surrendered.doubt` | undertaker | Harlan shot him; the undertaker has seen the body | "Powder on his shirt front. He was shot close, Deputy. Mighty close." |

(`surrendered.doubt` is evidence spoken by the one man who'd see it: the forensics of DESIGN §10 in a
line. The remaining ~15 lines are second wordings and the saloon's, section 6.)

## 6. The saloon at night as a living room

**DECIDED** (Sean, #810, 2026-11-11): the first time in is night, on foot down Main Street; the fiddle
and piano and laughing build through the walls as you come; the door opens and it's loud and all
round you. The murmur is a bed. **Every distinct sound comes from a person, and he does it.** People
who talk look like they're talking. What drives it: each man's mood, his drink, payday, who he's with
and what just happened; when trouble starts the laughter stops and men turn to look, the same rule as
the piano player's. **DECIDED** (Sean, #276): the saloon first, working for 15 minutes on its own; the
piano player stops when trouble starts, ducks, and starts again shakily.

### Who's where (the slice's ordinary night, 12 in the room at its fullest)

| Place | Who | From-to |
|---|---|---|
| Behind the bar | barkeep (`WipeBar`, `MopFloor`, pours) | 17-3 |
| At the bar, standing | miner, rancher, loudmouth; the undertaker for one drink | 19-1.5; 19.3-1; 18-2; 20-20.5 |
| The card table | Earl (night 1 only), drifter, two free chairs (the player's, the stranger's) | 19.5-2 |
| A second table | two talkers: the livery man and the storekeeper (till 21), then whoever's left | 19-23 |
| The piano | piano player | 19-1 |
| By the piano, standing | fiddler (#799) | 20-24 |
| Moving | saloon woman: bar to tables, sits with a winner | 19-2 |
| The door and the walk | a man coming, a man going; one on the porch with a cigarette | all night |

Seats and standing places are the room's **spots** (section 3); who takes which is their day's data.

### The room's mood, and the bits

- **Mood** is one number the room keeps (0 hushed to 1 roaring), from what's really there: how many
  are in, how much each has drunk (the composure system's drink), whether there's music, the day
  kind, and the minutes since trouble. The music's tension reads the same number.
- **A bit** is a small thing one man does that others answer, picked by a **room director** (the
  "event director" of Sean's plan, #276: conditions, frequency, cooldowns, already-seen) from the men
  in the room, **never played from the air**:

| Bit | Source | Others | Needs |
|---|---|---|---|
| A laugh | one man: head back, shoulders, mouth open, eyes creased | his table grins; a second man laughs a beat late | laugh clips per voice (#807's board), the face rig's laugh, a body clip |
| A toast | stands, glass up, a short line | the bar lifts glasses | 1 clip, 3 lines |
| "Hey, Earl!" (a hail) | a man at the bar, to one coming in | the one hailed lifts a hand | lines by name for the named, "Hey, you old thief!" for the rest |
| A round bought | pays, the barkeep pours along the bar (**DECIDED**, DESIGN §10 "a round on me", when the player does it) | thanks, glasses up | the pour |
| An argument | two at a table: voices up, a chair scraped back, a hand flat on the table | the room's mood dips; the barkeep looks | 4 lines, the ladder's low rungs (it can go on up by the real rules, or die) |
| A song called for | "Play 'Soldier's Joy'!" | the fiddler changes tune (#799's note data) | 2 lines |
| A man leaving | drains it, hat on, "Night, all" | one answers | 1 clip |
| A cough, a spit, a chair tipped back | one man | nobody | small clips |
| A card dispute (built: `CardGame`'s lines) | the table | the nearest drinker turns | none |

- **Rate:** a bit every 8-20 s at mood 0.7, every 40-60 s at 0.3, none at 0. The same bit from the same
  man not twice in five minutes. Talk between bits is the `talk` spot: mouths and hands and walla from
  that table's own place.
- **The hush:** trouble (a gun seen, a shout in anger, a blow, a shot) sets mood to 0 **as each man
  senses it**: the table beside it first, the far end of the bar half a second later, the piano player
  two wrong notes after that. Laughter stops in mid-laugh. Heads turn. This is section 4's stage 1 and
  2 in a full room; nothing extra is scripted. Mood climbs back over two or three minutes if nothing
  follows; the piano starts again thin and a little fast.
- **From the street** (#810's build-up): the bed and the music through the wall, by `GameAudio`'s
  walls and rooms; each bit's laugh is still placed at its man, so through the open door you hear the
  room has a shape.

### The slice's three nights

| Night | The room | Why |
|---|---|---|
| Night 1, No Law | an ordinary night, a little bold ("No sheriff tonight, boys": script `town.bold`), mood 0.7 at the door. Then the murder: the hush, the room emptying by each man's nerve, the barkeep and the miner left with Earl | The contrast is the mission. **DECIDED:** it's the game's first wow (#810) |
| Night 2, the sheriff dead | pick 4 in #851 | `mourning` |
| Any later night in the slice | by regard and the day kind: the hail as Harlan comes in ("Deputy"), or the talk dropping | the town's answer to what he did, in one doorway |

**Waits on:** the saloon on its valley lot (#755; today the bar and table are in the yard, where the
whole design works the same but for the walls' sound), the fiddler (#799), laugh and walla takes
(#807's board), the face rig's laugh and the talking gestures (#810: characters' and mocap).

## 7. Alive at low cost

**Cheapest believable things first** (each is small, each is noticed):

1. Heads turn to a noise, a door, a newcomer, at each person's own delay (`attend_to`; no new motion).
2. Nobody stands square at a post: `lean`, `sit`, idle breaks.
3. Lit windows, chimney smoke and shut doors that follow the book. A town of 16 looks like a town of
   60 at night for the price of some lamps.
4. A greeting or a turned shoulder as you pass, by regard.
5. The wave: reactions delayed by distance.
6. Two people talking, facing each other, hands moving.
7. The slow return after trouble.
8. One runner.
9. The gawk ring.
10. Laughter with a face.

**What it costs.** Today (more-cores step 4b, measured on this workspace and scaled by 0.65 to
Sean's): a near man about 0.21 ms, a far man about 0.07 ms, the calm street's people 1.8 ms of the
4.0 budget. So:

| | People | At Sean's (estimate) |
|---|---|---|
| Near (within 25 m, every tick) | 12 | 2.5 ms |
| Far (bands) | 12 | 0.85 ms |
| On the book | the rest | 0 |
| The new minds (news, room director, day clock; a few times a second, never per tick) | | 0.1 ms budgeted |
| **Total** | **24 bodies** | **about 3.45 of 4.0** |

- The saloon at its fullest is the worst case: 12 in the room, all near. That's why the roster is 16
  and the room 12. More townsfolk (pick 1) means more on the book and on the far street, not more in
  one room.
- **A new band to measure, not assume:** a man seated or leaning, calm, not speaking and not in the
  middle of the view could tick every 2nd tick even when near (today near is always every tick). If
  it holds without visible stepping, the room carries 16.
- **Never per tick:** the day clock (every 0.5 s, as `ValleyFolk` does), tellings (checked once a
  second for a pair at spots), the room director (once a second), regard (on a news event).
- **Render** is its own budget (4 ms): 12 talking faces in lamplight is art's and characters' to
  measure with the saloon B work, and may be the real limit before the people tick is.
- **Unknowns step 1 measures first:** what a talking face (`FaceLife`, `FaceSpeech`) adds per near
  man; the valley's saloon spot with 12 in; `Sight` asked by 12 men in one room.

## 8. How each piece is judged

**The gate (DECIDED in shape, Sean, #276, 2026-11-03):** the no-mission test. Start, walk the town,
sit in the saloon, start no mission, fire no shot; pass if the player saw ordinary life, heard
believable talk and sound, noticed something change, and met at least one unscripted moment worth
remembering. Judged by whether it felt natural, not by how many events fired; run several times to
show loops. "Did Salt Creek carry on living without Harlan?" For the slice it's **10 minutes, four
runs at different hours** (7, 12, 17.5, 21), by the blind playtest agent (`tools/playtest.md`).

**The blind playtest's questions** (answered without having read any of this):

1. Name three people and say what each does for a living. How did you know?
2. Did anyone do something you didn't expect? What?
3. Did you see anyone do exactly the same thing twice? Who, what?
4. Did anyone appear or vanish while you watched?
5. Did anyone react to something they couldn't have known about?
6. In the saloon: pick one laugh you heard. Who laughed?
7. After the shot (run 5: one shot in the air at noon): describe what the street did, in order. How
   long until it looked ordinary again?
8. The morning after a killing: what does the town think happened? Is it what happened?
9. How does the town feel about you? What told you?
10. Was there a moment worth telling someone about?

**Counts in the labs** (each a test or a lab case, run headless):

| Piece | Measure | Pass |
|---|---|---|
| The day | every person at his data's spot at every clock hour, bands on and off (`test_valley_folk`, as `test_town_day` did) | all, both ways |
| The book | bodies in the tree by hour; lit windows match who's home | never more than 24; all match |
| Nothing in view | a probe logs every body added or freed with the player's line of sight to it | 0 seen |
| Spots | the longest any body holds one pose without a break, watched for 10 min | under 20 s |
| Reactions | per stimulus: each person's delay against distance; what he did against his dials (the perception lab's way: expectations written by hand first) | delays rise with distance; no two the same frame |
| Leaks | the perception lab's leak monitor on every reaction and news case | 0 |
| The runner | time from the shot to the doctor leaving his door, against the walk's length | within 20 % of the walk |
| News | the perception lab's `news` group extended: who holds what, and how, at 1, 5, 30, 90 s, an hour, next morning | nobody holds a slot he didn't sense or wasn't told; all hold the big events by morning; 20-40 % of versions differ from the truth in a slot |
| Barks | a 10-minute walk logged: lines by id | no id twice from one person; none from a person who doesn't hold its news; no secret before its beat (VOICES K1-K13) |
| The saloon | every non-bed sound logged with its source body, his clip, and whether the camera could see him | 100 % have a source doing it |
| The hush | time from trouble to each man's turn, by his distance | 0.15-1.2 s, rising with distance; laughter cut within its man's delay |
| The frame | `valley_bench` spots: the saloon at 21 with 12 in, the street at noon, the street after a shot | people at or under 4.0 ms at Sean's; no frame over 16.6 ms from the people |
| Repetition | the four gate runs' logs laid side by side | no bit, bark or path in the same order twice |

Sean judges by playing and by ear (the sound lane's rule); the counts only say it's ready for him.

## 9. The build plan

Eleven steps, one session each, in order. Each stops at its green merge. Every part is promoted with
its `docs/PARTS.md` row. Nothing here reorders `docs/ROADMAP.md`: Sean places it.

| # | Step | Model line | Reuses | Done when (measured) |
|---|---|---|---|---|
| 1 | **Measure, and shut the leaks.** `valley_bench` with 12 near + 12 far and talking faces; the perception lab's baseline re-run on main; fix what's left of "a shot names its shooter" and "acting on what he couldn't know" for townsfolk | `Model: Opus 5.5, effort medium: perception faults whose present state isn't known` | perception lab, `perf_bench --folk`, `valley_bench` | section 7's table filled with measured numbers; leaks 0 in `news` and `leaks` for `CivilianBrain` |
| 2 | **The day and the book.** `valley_folk.json`'s `day` blocks, day kinds, on and off the book at doors, lit windows and smoke from the book. The five built folk moved onto it, nothing else changed | `Model: Opus 5.5, effort medium: a new system under ValleyFolk` | `ValleyFolk`, `OilLamp`, the ways | the day's and the book's and nothing-in-view's rows pass; No Law still plays (its tests) |
| 3 | **The roster as data.** The 16 people's days, homes, dials; the street's and buildings' spots (positions only, `stand` for all) | `Model: Sonnet 5.5, effort medium: data to a written table` | step 2's shape; stand-in faces by pick 1 | every person at every hour; a film of the street at 7, 12, 17.5, 21 |
| 4 | **Spots.** The chore kinds `lean`, `sit`, `counter`, `sweep`, `carry`, `talk`, `drink` with their breaks | `Model: Opus 5.5, effort medium: new behaviour` | `SitChore`, `WipeBar`, `MopFloor`, the bucket's carry, `FaceSpeech`; the prop lab's broom and sack; the motion library | the spots row passes; blind playtest questions 1-3 |
| 5 | **Reactions in stages.** Start, look, decide, come back in `CivilianBrain`; the dials; the wave; shaken; the gawk ring | `Model: Fable 5.5, effort medium: behaviour that has to read as real, not only work (Sean, 2026-11-12: Fable while its weekly limit is free; Opus if it isn't)` | `Senses`, `Events.noise`/`deed`, `GameAudio`'s delay, the built `gun_out`, cower, hands up | the reactions and leaks rows; playtest question 7 |
| 6 | **The runner.** For the doctor, then for the law; the doctor comes with his bag | `Model: Opus 5.5, effort medium: new behaviour` | step 5; the ways; the doctor's bag (prop, #823) | the runner's row; the built line "Ain't nobody left to fetch" still true on night 1 |
| 7 | **The town's news.** `TownNews`: the record, versions, telling, overnight, the day kind from it; the perception lab's `news` cases extended | `Model: Fable 5.5, effort medium: news that travels and changes believably (Sean, 2026-11-12: Fable while its weekly limit is free; Opus if it isn't)` | DESIGN §9's memory, `StoryState`, `talk` spots | the news row; playtest question 8 |
| 8 | **The town's script.** `docs/scripts/town.json` from section 5's table and Sean's picks 2-4; its page; Sean's Script OK (text only, free) | `Model: Sonnet 5.5, effort medium: lines to a written table, #807's recipe` | `docs/scripts/README.md`, WORDS.md, VOICES.md | Sean's Script OK |
| 9 | **Regard and the barks.** Opinions from news versions; greetings and turned shoulders; the line picker (most specific wins, the limits) | `Model: Opus 5.5, effort medium: a new system` | `Relations`' numbers, `CivilianBrain`'s line gaps, steps 7 and 8 | the barks row; playtest question 9 |
| 10 | **The saloon as a room.** Room mood, the room director, the bits with their sources, the hush; nights 1 and 2 | `Model: Fable 5.5, effort medium: a living room that reads as real; needs the saloon on its lot, #799's music and #807's laugh takes (Sean, 2026-11-12: Fable while its weekly limit is free; Opus if it isn't)` | steps 4, 5, 9; `CardGame`; the music system | the saloon's and hush's rows; playtest question 6; the frame at 12 in |
| 11 | **The gate.** Four blind 10-minute no-mission runs and the shot run; the report; the fixes that are small; the build to Sean | `Model: Sonnet 5.5, effort medium: a playtest by its recipe` | `tools/playtest.md`, the bridge | `docs/playtests/<date>-town.md` with the ten answers; the repetition row |

- **Not in this plan** (waits, by #276): the lamplighter, sweeping up glass, boarding windows, scrubbing
  blood, the spittoon, stock running down, the stage and freight day as events, private moments through
  windows, payday. The day, spots, news and room director are what each of those will sit on.
- **Others' work it leans on:** characters (faces by pick 1; the face rig's laugh; talking gestures),
  sound (#799, #807's takes, the walla bed), the prop lab (a broom, a sack, a tray, armbands), art
  (lit windows and chimney smoke on fronts; 12 faces in lamplight inside the render budget).
- **Beside #796** (No Law step 4, running): it builds the morning's and the funeral's story beats.
  Steps 2 and 3 give it a town to walk through; until they exist it places its own people, and step 3
  takes them over.

## 10. Sean's picks (#851)

1. How many townsfolk on the slice's ground, and whose faces.
2. How the town treats the deputy after Kett is turned loose.
3. How the town takes Joe's revenge.
4. The saloon on the night the sheriff dies.
5. Far-off sounds with no animals in the game.
