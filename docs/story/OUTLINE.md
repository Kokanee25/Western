# The outline: the whole story, start to finish

The story bible, part 1 of 5 (#809). Planning only: nothing here changes the game. Built 2026-11-11
from the mission cards (`docs/missions/`, on PR #743's branch `claude/planning-missions-cards-mwdo42`
until that PR merges), `DESIGN.md` §5, and issues #738, #736, #744, #789, #809, #810. Where a card
and Sean's decisions of 2026-11-11 (#744, #809) differ, the decisions win and the card is listed at
the end as out of date.

**Every line carries its status**, the cards' way (`docs/missions/README.md`):
- **D** = DECIDED: Sean's call, with its date. Nothing here is upgraded to D.
- **P** = PROPOSED by Sean or an earlier session, never confirmed.
- **P·bible** = proposed by this bible to fill a hole. Sean hasn't seen it. Never build on one.
- **O** = OPEN. The numbered ones are in `CONTRADICTIONS.md`. Sean picked all of C1–C15 on
  2026-11-11 (#830); each pick is written "D (Sean, 2026-11-11, #830)" with its letter, or
  "(D, Sean 2026-11-11, #830, C*n x*)" inside a line. C8 is the session's pick on his say-so and
  stays **P** until he nods. What the picks opened is in Part C
  (s21–s27). **C16 (2026-11-13):** the sheriff's shooter is not Kett (D); who he is waits on
  Sean's pick, and his lean (the stranger at the table) is written in here as P.

The other parts: `SETUPS.md` (what's planted where), `VOICES.md` (who talks how, and who knows what
when), `WORDS.md` (1880s speech), `CONTRADICTIONS.md` (what doesn't fit). One-page summary: `README.md`.

## The story in one paragraph

Salt Creek, 1882. Water is the stakes. The cattle Baron wants every drop in the valley, and the law
won't let him use the Army to take a quiet town (the Posse Comitatus Act, 1878), so he sets out to
make Salt Creek **look like a town in revolt**: staged attacks, telegrams, fights in front of an
Army captain (D, 2026-11-11). His foreman shoots the sheriff over the family's water right (P,
Sean's lean, C16 a), his hired guns raid a
Southern Ute camp to start an "outbreak" for his telegrams, wreck a train and saw through a dance
floor. Thomas Harlan, a homesteader and
former army hospital steward, finds the sheriff dying on the road, is sworn in as his deputy, and
becomes the one thing standing between the Baron and his lie. With Joe, a Southern Ute widower, he
learns that the law fails (No Justice), holds it up anyway, takes the Baron's papers, blows the
trestle under the train that comes for the town, and arrests the Baron in his own house. What the
newspaper and the town say afterwards depends on the evidence he kept and the people he kept alive.

## How the order works

No day count: "the story doesn't advance until it should advance" (D, 2026-11-01). A mission opens
when its conditions are met; people nudge, nothing forces. The town's calendar (the daily train, the
stage, payday) runs whatever Harlan does. So each act below has a **fixed part** (it has to happen in
that order) and an **open part** (any order, or never).

```mermaid
flowchart TD
  A1[the-sheriff] --> A2[no-law] --> A3[day 2: deputized, the funeral] --> A4[no-justice]
  A3 -.the horse to take home.-> W[widows-place]
  W -->|the rifle| R[joe-on-the-rope]
  A4 --> R
  A3 -->|Cody walks back into the saloon: arrested| J[the jail night: the Water Tower]
  A3 --> F[farmhouse-rescue]
  B[buried-alive] --> M[demolition-mentor]
  B -.the breach.-> F
  H[hell-on-wheels] --> P[payday-night] --> L[i-am-the-law]
  P --> X[balcony-ambush]
  B --> X
  L --> T[the-bridge-is-out]
  S[barons-shipment] -.Sean's working order.-> T
  T --> Z[barons-house] --> E[the paper, then the walk]
  J -.the witness.-> E
  S -.the papers.-> E
```

Solid arrows are D; dotted are P or O, or what one mission hands another. How Harlan hears of Buried
Alive, the Shipment and the last train is mostly O (see `SETUPS.md`, "Missing").

---

## Act I: becoming the law

**Fixed, in this order** (D, 2026-11-09, the opening):

| # | Mission | What happens | What it reveals | Threads |
|---|---|---|---|---|
| 1 | [`the-sheriff`](../missions/the-sheriff.md), day 1, dawn | Harlan walks down from his homestead and finds the sheriff gut-shot on the East Road. Nod to help, shake to leave. Pack the wound, lead him in on his own horse, the doctor's. | The sheriff was shot by a man he didn't know, who "rode up easy, like he wanted directions" (built). **Not Kett** (D, Sean 2026-11-13, #830, C16). His marks, by Sean's lean (C16 a, P; the wording P·bible): a bald-faced sorrel, and the man called him "friend". The built line still says "a faded red shirt" (to change: C16's table). Harlan's hands know wounds. | T1 opens |
| 2 | [`no-law`](../missions/no-law.md), night 1 | The saloon. Harlan is seated and unarmed; a stranger's hand is on his arm. The stranger is **the Baron's foreman** (D, Sean 2026-11-11, #830, C10 b); nobody says so tonight. **Cody**, one of the Baron's hired guns, kicks Earl's chair out and shoots him over cards: "Ain't no law left in this valley to save you now." He rides for the foothills. Who sends Harlan to the saloon: O (s26). | Nobody will stop a murder. The stranger knew it was coming. **The stranger shot the sheriff that morning** (P, Sean's lean 2026-11-13, #905, C16 a): he sits with Harlan to learn what the sheriff said. A player who listened knows him by the sorrel at the rail and "Don't move, friend." (S40), and can do nothing about it tonight. A player who follows sees which way Cody rode. | T1, T7, T4 |
| – | The same night, unseen | Cody's crew, led by **Silas Kett** (the red shirt), raids Joe's camp while the men are hunting. Joe's wife is raped, murdered and scalped (D, 2026-11-09, 2026-11-11). The raid is **provocation**: the Baron wants a Ute "outbreak" for his telegrams (D, Sean 2026-11-11, #830, C4 a). | Nothing yet: Harlan hears of it in No Justice. | T2, T5 |
| 3 | Day 2 | The sheriff dies at the doctor's, his wife there. His last words follow day 1's care. He swears Harlan in and gives him his revolver; a shake gets "That's not the way this works, son." The funeral: attend or not. **The Baron offers the widow a price for her claim** at the graveside. | The Baron's face and what he wants. Harlan is a deputy, "temporarily": the sheriff was the **county** sheriff, the seat down the line; the coroner acts as sheriff, the coroner is the doctor, and he keeps Harlan on until the county names a man (D, Sean 2026-11-11, #830, C12 a; who and when: O, s27). | T1, T4 opens |
| 4 | [`no-justice`](../missions/no-justice.md) | Harlan meets Joe (the doctor's office on Sean's card; flagged O by Sean). The camp; the survivors name a faded red shirt (the camp's mark only: S1). Joe dresses as a cowboy (the costume stays: D, Sean 2026-11-11, #830, C4 a; it's what spoils the Baron's provocation). The hideout: five or six men, the end of Kett's crew (D, Sean 2026-11-11, #830, C5 b). Kett runs for the cabin and surrenders. Joe draws his knife: "Are you going to stop me?" Nod or shake. | Who killed Joe's wife. **He is not the man who shot the sheriff** (D, Sean 2026-11-13, #830: "he would never be released for the murder of joes wife if he also shot the sheriff"). The law will not punish a Ute woman's killer. | T2 opens, T7 |

**No Justice's endings** (all D, 2026-11-09):
- **Arrest (nod):** Kett goes to the jail, then off on the train to "the proper authorities", is
  released, and comes back the same way. The man on the platform who lets him go is Rourke or his
  officer. Kett walks Main Street. The camp's trust cools. **Who and by what right (C8 a, P until
  Sean nods on #830):** Kett sits in Harlan's jail a couple of days; the train brings Rourke's
  officer with a paper (a crime against a Ute woman on the reservation is the United States'
  matter, not the county's); Harlan hands him over on the platform, and the officer turns him loose
  for want of a witness the court will hear. (C16: the sheriff's killer would never be let go; a Ute
  woman's is, and that is the point.)
- **Revenge (shake):** Joe kills and scalps him in the cabin. The bodies are found; the town splits;
  the camp trusts Harlan; the gang's kin or friends come looking.
- **Harlan shoots the surrendered man:** murder, and Joe saw it. **Killed outside in the fight:** no
  question is asked; Joe is furious.

**Open, once he has the badge** (any order; each row says what it waits for):

| Mission | Opens when | What it reveals or gives | Threads |
|---|---|---|---|
| [`widows-place`](../missions/widows-place.md) | The livery man: the sheriff's horse "eats his oats"; someone should take it home (D). Its place after No Justice is P (`BUILD_ORDER.md`). | The stakes at her ditch (the water is the motive). The boys and Blue. The ways into her house. She gives him the sheriff's **Winchester** (D), maybe the horse (P, Sean's maybe). | T4, T1 |
| [`joe-on-the-rope`](../missions/joe-on-the-rope.md) | After No Justice **and** after the rifle (D, 2026-11-04). Arrest ending: Joe kills Kett on Main Street and the town strings him up. Revenge ending: the kin come for him. | Joe is hauled up choking, not dropped: 3–4 chances at the rope from distance, or close in and cut him down (D, 2026-11-11). Fail and he's dead for good. | T2, T7 |
| Cody's arrest | After the funeral, Cody walks back into the saloon, bold as before; this time Harlan has the sheriff's revolver. Harlan's first arrest (D, Sean 2026-11-11, #830, C6 b). Whether he's also at the cabin: O, s24. | The answer to night one, in the same room. | T7, T1 |
| The jail night ([`hold-him`](../missions/hold-him.md)) | Cody is in the cell for Earl's murder (D) | **The Water Tower, one side** (D, Sean 2026-11-11, #830, C7 c): Cody is held in the depot's freight room for the morning train to the county seat's court (the card's reason, P; the seat down the line is C12 a). The Baron's men mean to drop the tank on the room, and the player can't tell whether that frees him or crushes him (D, 2026-11-11). Alive and safe, Cody is the first man who can tie the Baron to the sheriff's murder and the raid. | T1, T7, T4 |
| Law work: `store-robbery`, `the-bounty`, `small-fights`, `stage-held-up` | Any time (P) | The Colters met as a separate outfit (P). A deputy's ordinary days. | T6, T7 |

**Where Act I leaves things:** Harlan has the badge, the revolver and (if he rode out) the rifle. The
sheriff's killer is dead in every branch but one that is still O (Harlan murdered him: the rope's
cause is unsettled), and the cabin has finished Kett's crew (C5 b). Who **ordered** it is the
question the rest of the game answers.

---

## Act II: learning the valley

No fixed order except **Buried Alive before the Mentor**, and no dynamite breach before Buried Alive
(D, inventory 2026-11-09; the lock, 2026-11-03).

| Mission | Opens when | What it reveals or gives | Threads |
|---|---|---|---|
| [`buried-alive`](../missions/buried-alive.md) | O: no source says how Harlan hears (P·bible: the mine's whistle blowing off its hour, heard across the valley) | Miners trapped after a blast. Dig, shore or blast in. **Single sticks** from the miner (D, 2026-11-04). The human cost of the mine. | T3 opens |
| [`demolition-mentor`](../missions/demolition-mentor.md) | After Buried Alive, if the miner lived (if he died: O) | Half-sticks, linked charges; **bundles at the end** (D). Maybe optional lessons (P). | T3 |
| [`farmhouse-rescue`](../missions/farmhouse-rescue.md) | The widow refused the Baron at the funeral, so it can come any time after day 2. She isn't at the store on her day; a rover talks in town (D, v2) | **The Colters**, hired by the Baron because the cabin finished Kett's crew, hold her house, the Kid on the porch; the built mission stands (D, Sean 2026-11-11, #830, C5 b). The Baron's foreman walks up the lane with a deed for her to sign: the stranger from the table (C10 b), so a player who sat with him knows the face. In 1882 Colorado the first to use water owns it, so the Baron needs her name. Front, back, a planted stick, stop the foreman, walk him in, or let her sign. Then her boys. | T4, T6 |
| `vaqueros-horses`, `dry-creek`, `kid-wants-out` | P, unplaced | The Baron taking in small ways; the Kid as a man who wants out. | T4, T6 |

**What Act II has to do for the story** (the story judge's complaint, 2026-11-09: the middle had no
reason): show the Baron's hand before the conspiracy is named. The farmhouse does it (his answer to
her refusal). Joe needs one beat here too: the rope is it, if the player hasn't done it yet.

---

## Act III: the conspiracy shows

**Fixed, in this order** (D): Hell on Wheels, then Payday Night that same night, then I Am the Law
the next day.

| # | Mission | What happens | What it reveals | Threads |
|---|---|---|---|---|
| 1 | [`hell-on-wheels`](../missions/hell-on-wheels.md) | The mine's payroll is on Thursday's train. Gang A boards to rob the express car. Gang B, two men paid by the Baron's foreman, pulls a rail west of the depot to **wreck** it with everyone aboard (D, v2, 2026-11-09). Five ways to stop it, a sixth proposed. | Two gangs, one double-cross. A wreck with dead passengers was one of the Baron's **two barrels**; the floor that night is the other (D, Sean 2026-11-11, #830, C1 a). Gang B's man, taken alive, names the foreman. | T5 opens wide, T4, T6 |
| 2 | [`payday-night`](../missions/payday-night.md) | Harlan stopped the train being robbed and derailed, and the town pulls him into the dance to celebrate saving the pay (D, 2026-11-11). If the pay was lost or the train wrecked: a hungry, angry night in the same room, and he's there as the deputy who failed (D, Sean 2026-11-11, #830, C2 b). A travelling band that came in on that train plays (P, Sean). **The dance floor's girder has been sawn, and the floor comes down: an event that happens**, not one the player can skip. If he finds out beforehand he can only be ready: nobody believes the deputy on payday (D, Sean 2026-11-11, #830, C3 b). He's an observer and can be hurt in the fall, but shouldn't normally die. Then the wounded, one doctor, and **Rourke** with an Army surgeon and a letter already written for the deputy to sign. | The Baron did this to the town. Rourke expected the night. Harlan is a steward, in front of everyone. | T5 (the hinge), T4, T8 |
| 3 | [`i-am-the-law`](../missions/i-am-the-law.md) | An Army captain has one day to report whether Salt Creek is in revolt. The Baron's men stage one: shoves until guns come out, a shot at dusk, a stolen Ute saddle left on the East Road, and Joe goaded (if Joe is dead, someone else: D, 2026-11-11; who: O). Keep the peace where the captain can't see the keeping. | The plan, in plain sight. The captain's wire is the verdict (D, 2026-11-11): quiet day or violent, the men on the last train are **always the Baron's hired men**; the wire changes how many, how they're armed and what the paper calls them, and Rourke and a few bought men are the only uniforms (D, Sean 2026-11-11, #830, C11 a; this replaces "soldiers under orders" on a violent day). | T5, T4, T2, T7 |

### The payroll: Sean's pick, two barrels (D, Sean 2026-11-11, #830, C1 a)

What's settled around it: Rourke comes no matter what (D, 2026-11-09). Payday Night follows the pay
being **saved**, and the floor falls whatever Harlan did on the train (D, 2026-11-11).

**Two barrels.** The Baron planned the wreck and the floor for the same day, so that one would land.
Saving the pay changes nothing for him (D, Sean 2026-11-11, #830, C1 a). The saw was bought that
morning, before anyone knew how the train would go (P·bible; when the girder is cut is O, s23), and
Harlan's win is what fills the dance floor: the people he saved at noon fall at night. Rourke's
letter, "dated that afternoon, the ink long dry" (D v6), fits: the night was planned before the
train ran.

**If the pay is lost or the train wrecked** (D, Sean 2026-11-11, #830, C2 b): a hungry, angry night
in the same room, and the floor still falls. He's there as the deputy who failed, not the guest of
honour. Why the Baron still drops the floor once the wreck has landed, and the band on a wrecked
train: O, s23.

**If he finds out** (D, Sean 2026-11-11, #830, C3 b): he can only be ready. Nobody believes the
deputy on payday. Knowing changes where he stands and what he has to hand, and nothing in the room.
The two hard-to-find ways stay as `SETUPS.md` S23 places them (P·bible).

The other two versions, kept as the record (Sean didn't pick them): **B. "The deputy stole it"** (the
pay saved but short, the Baron's men saying the deputy took it; Sean's twist, which could still be
added to A later) and **C. It really worked** (saving the pay beat him, and the floor was the Baron
trying something else in a hurry that afternoon, which would have made it leave traces).

**Open in Act III** (P, unplaced): `kid-wants-out` (the Kid, who knows who pays the gang, is drinking
under the cut on Payday Night: D), the jail night (`hold-him`) if Cody's night hasn't happened yet.

---

## Act IV: the Baron and Rourke

| Mission | Opens when | What it reveals or gives | Threads |
|---|---|---|---|
| [`balcony-ambush`](../missions/balcony-ambush.md) | **After Payday Night and after dynamite** (D, 2026-11-11). The men who sawed the girder, drinking on the hotel's gallery **the night after** (D, Sean 2026-11-11, #830, C9 a). The night after is the captain's day, the dynamite may not be his yet, and how he knows the men is unsaid: O, s22. | Harlan can bring a floor down on the Baron's men, as they did to the town (P, Sean: "do what they did to innocent people"). | T4, T3 |
| [`barons-shipment`](../missions/barons-shipment.md) | O: how Harlan learns the coach runs (P: he's seen it on the road; Joe pitches it; the miner or the place itself if Joe is dead) | The Baron's iron-plated coach and his papers. The log is a **ram on two ropes** swung into it (D, 2026-11-11; built, #814). Whoever sees the heist tells it as the town robbing the Baron, so doing it unseen matters (D). **The papers are the first kind of evidence** (D); what they are is still O. | T4, T5, T2 |
| `bank-break-in` | P: only if the papers were lost | A second road to the same evidence. | T4 |
| [`the-bridge-is-out`](../missions/the-bridge-is-out.md) | When the threads are ready (D, 2026-11-01); how Harlan hears the train is coming: O | **The climax** (D, 2026-11-11): the trestle blown under the train carrying the Baron's men, with bundles, by load paths, never scripted. Aboard: always the Baron's hired men, as many and as armed as the captain's wire made them; Rourke and a few bought men the only uniforms. **Rourke dies on the trestle with the train** (D, Sean 2026-11-11, #830, C11 a). Rourke if the trestle isn't blown under him: O, s25. | T5 ends, T3 ends, T8 ends |
| [`barons-house`](../missions/barons-house.md) | After the trestle (D) | **The finale** (D, 2026-11-11): the raid on his barricaded masonry house and his arrest, alive. One way in is the Sap (D pick, 2026-11-09). | T4 ends |

---

## All the endings

**Early ends** (D, DESIGN.md §5, 2026-10-01: "the game can end early"): dead where no doctor can wake
him, run off his claim, killed by the gang. (DESIGN's "hanged after a trial" hangs on the trial,
which is no longer the ending.) Each is told the way an ending is: the paper and the town, not a fail
screen.

**The ending proper** (D, 2026-11-11) has three parts, and no courtroom:

1. **The arrest.** The Baron is taken alive from his house.
2. **His fate, told by the newspaper and the town's talk.** It follows the **evidence** Harlan
   gathered, which the game tracks (D, 2026-11-11):

   | Evidence | Where it comes from | How it's lost |
   |---|---|---|
   | The papers | `barons-shipment` (or `bank-break-in`, P) | Burned, blown up, left, sold |
   | The witness | Cody, arrested for Earl's murder, alive and safe after the jail night: he can say who shot the sheriff (D) and who paid (by C16 a, P: the foreman, on the Baron's word) | Killed in the cell, freed, or never taken |
   | What people saw | Witnesses all game: the sheriff's last words (Harlan, the widow, the doctor heard them; C16 a's marks, P), the sawn girder, the storekeeper's day-book, the captain's own eyes, who saw Harlan do what | Nobody saw, or they saw Harlan do worse |

   A strong case convicts him. A thin one lets him walk or buy his way out.
3. **The quiet epilogue.** A few days later Harlan walks the town, and it shows what his choices made
   of it. No new system: the world as it stands.

**What the walk reads** (each a fact a mission set; `docs/missions/DECISIONS.md` has the full table):

| The walk shows | Set in | Values |
|---|---|---|
| Whether Joe is there | `joe-on-the-rope` | Beside him, or a grave at the camp (D) |
| The camp's trust | `no-justice`, `i-am-the-law` | Trusts him, cooled, or remembers being hidden |
| The widow, her boys, her water | `the-sheriff`, the funeral, `widows-place`, `farmhouse-rescue` | Hers still, or signed away (then whose is it after the arrest? O) |
| Who's buried | Every mission | The sheriff, Earl, Joe's wife; then by what Harlan did |
| What the paper says of him | Evidence, witnesses, the captain's wire | The deputy who kept the peace, or the man who brought it down |
| What stays broken | The saloon's floor, the depot's tank, the coach in the cut, the trestle, the Baron's wall | Rubble stays (DESIGN §8, must have) |
| Who came on the last train | `i-am-the-law` | Always the Baron's hired men (D, Sean 2026-11-11, #830, C11 a): how many, and what the paper calls them, by the captain's wire |
| Cody | The jail night | In the county's hands and talking, dead in his cell, or gone |
| The Kid, the Colters | `farmhouse-rescue`, `payday-night` | O: no card ends the Colters' thread |

**Not settled about the ending**: whether the train can be stopped another way (P, #546 P4, never
accepted; "turn the soldiers" has no soldiers to turn since C11 a, and Rourke off the trestle is
s25); whether the Baron can be killed (the cards: he "must survive the breach"); whether the game
goes on after the walk (P, #546). Rourke's fate is settled: he dies on the trestle (C11 a).

---

## Beside the main line

Side missions and set pieces, none placed by Sean yet (P unless marked): `dig-him-up` (D: kept, a
sneaking mission at the sheriff's grave; what's in his boot is O), `fever-house`, `dust-storm`,
`cattle-drive`, `fire-night` (fire is out of play), `night-meeting-trap`, `railhead-lynching`,
`bank-robbery`, `the-trial` (a "maybe elsewhere", D 2026-11-11). Cut: `tied-to-the-tracks` (D,
2026-11-09).

## How each thread runs, in one line

- **T1 the sheriff and the badge:** shot (day 1) → sworn (day 2), kept on by the doctor as acting
  sheriff (C12 a) → (by C16 a, P) the killer at Harlan's own table that night, known by "friend" and
  the sorrel → beside the Baron at the funeral → up the widow's lane with the deed → Cody arrested in
  the saloon (C6 b) → the witness under the tank (C7 c), who can name him → taken in the raid
  (P·bible) → who ordered it, in the paper. (Was "the killer named by his shirt (No Justice)": the
  shirt is Kett's, and Kett didn't shoot him, D 2026-11-13.)
- **T2 Joe:** the raid, the Baron's provocation (C4 a) → the question at the cabin, in the costume
  that spoils it → the rope → the man with plans (P, #738), or a grave → the walk.
- **T3 the mine:** the rescue → sticks → lessons → bundles → the trestle, and the Sap's props.
- **T4 the Baron and the water:** the offer at the grave → the stakes at the ditch → the deed at the
  farmhouse → the coach's papers → the raid → his fate.
- **T5 Rourke and the train:** the platform (arrest ending; his officer, C8 a, P) → two barrels, the
  wreck and the floor (C1 a) → the letter → the captain's wire → the last train, the Baron's hired
  men (C11 a) → the trestle, where Rourke dies (C11 a).
- **T6 the Colters:** a separate outlaw family who sometimes cross the Baron and sometimes work for
  him (D, 2026-11-11). Hired for the widow's farm once the cabin has finished Kett's crew (C5 b).
  Their other beats are P and their ending is missing.
- **T7 the town's law:** no law (Earl) → no justice (Kett) → the first arrest, in the same saloon
  (Cody, C6 b) → the mob (the rope) → the law holding a man his own side wants dead (Cody) → the law
  in front of the Army (the captain) → the paper.
- **T8 Harlan's past:** D (Sean, 2026-11-11, #830, C15 a): Rourke was his old commander, and it's
  planted early (where: `SETUPS.md` S38, P·bible). Rourke's first look at him → the letter he's
  asked to sign → the trestle. "Do your duty, Sergeant" and the dream stay P (#546 P2, P4) as lines.

## Cards that are now out of date (no call needed; fix when #743 is next touched)

| Card | Says | Sean has since said |
|---|---|---|
| `payday-night` (v6) | Nine ways, several of which prevent the collapse; "if the floor holds, they leave town"; traces all afternoon for anyone; the Railroad Saloon; joists; Rourke "on their way to their new post" | The floor comes down; one or two hard-to-find ways to know; he's there celebrating (2026-11-11). The girder is what's sawn (2026-11-10, #772). Two barrels (C1 a); a hungry night if the pay is lost (C2 b); if he knows he can only be ready (C3 b). Rourke's post is near from the start (C8 a, P until Sean nods). |
| `STORY.md`, `MAP.md` | Evidence and the trial "a maybe"; the finale O | Evidence is a system; trestle, raid, paper, walk (2026-11-11) |
| `no-justice` | "The man in the red shirt is first seen on the first night in the saloon"; who "the proper authorities" are: OPEN | Kett isn't in the saloon; Cody is (2026-11-11). The cabin finishes Kett's crew (C5 b); the raid was provocation and the costume stays (C4 a); the release: C8 a (P until Sean nods) |
| `the-sheriff`, `no-law`, `no-justice` | "The red shirt is the Baron's hired gun, and the man who shot the sheriff" (D, 2026-11-09) | Not the same man (D, Sean 2026-11-13, #830); the shooter is Sean's lean, the stranger at the table (C16 a, P) |
| `no-law`, `the-sheriff` | The stranger's identity and return OPEN; "temporarily" ends with the town or the county confirming him | The stranger is the Baron's foreman (C10 b); a county sheriff, the doctor acting as coroner keeps Harlan on until the county names a man (C12 a) |
| `farmhouse-rescue` | OPEN (#622 item 7): who holds the farm, the Colters or the Baron's own hands | The Colters, hired because the cabin finished Kett's crew; the built mission stands (C5 b). The foreman on the lane is the stranger from the table (C10 b) |
| `barons-shipment` | A rolling log; the driver as a way in (v2); "the log too late" | A ram on ropes; no driver; that way cut (2026-11-11) |
| `balcony-ambush` | Placement O (Act I in the inventory) | After Payday Night and dynamite (2026-11-11) |
| `joe-on-the-rope` | A drop and a short window | Hauled up, 3–4 shots, or close in (2026-11-11) |
| `hold-him` | A Colter in the cell; two groups with opposite aims; a U.S. Marshal's wire (DESIGN.md) | Cody, the Baron's man, arrested in the saloon (C6 b); the Water Tower with one side, the tank meant to drop on the freight room, free or crush unknown (C7 c); the county's seat down the line (C12 a) |
| `i-am-the-law` | A quiet day brings hired guns, a violent day soldiers under orders | Always the Baron's hired men; the wire changes how many and what the paper calls them (C11 a). The raid was the first try at an outbreak (C4 a) |
| `the-bridge-is-out` | Soldiers and hired guns aboard; "Rourke's fate and the soldiers' outcome stay open"; P4's "turn the soldiers with evidence" | The Baron's hired men, Rourke and a few bought men the only uniforms; Rourke dies on the trestle (C11 a); Harlan's past with Rourke is planted early (C15 a) |
| `the-trial`, `barons-house` | A trial after the arrest | No courtroom: the paper and the talk (2026-11-11) |
| `DECISIONS.md` | `cody.fate`, `payroll.fate`, `payday.floor` rows | Need the rows above, and the picks of 2026-11-11 (#830) |
| `DESIGN.md` §5, §9 | 30 days, ten days, three endings to the camp; "nobody says the player's name" | Open threads (2026-11-01); he's Thomas Harlan and the built sheriff says so |
