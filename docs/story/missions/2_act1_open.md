# Mission ideas, the full record: %s

Part of `docs/story/MISSIONS.md` (read that first). Gathered 2026-11-17 by a reader sub-agent from every source: the mission cards on PR #743's branch, Sean's own files in `docs/missions/sources/`, the proposals, the story bible, DESIGN.md and what is built. **Nothing here is a decision unless it is marked D with Sean's date.** Not yet checked line by line by the story session; where it disagrees with `OUTLINE.md` or `CONTRADICTIONS.md`, say so in a note rather than fix it silently.


Short paths used below. Cards are on `origin/claude/planning-missions-cards-mwdo42` under `docs/missions/`
(`card` = the mission's own card; `sources/…`, `proposals/…`, `judged/…`, `DECISIONS`, `BUILD_ORDER`, `MAP`,
`STORY`, `README` are in that folder). The bible is `docs/story/` (`OUTLINE`, `SETUPS` S-numbers, `VOICES`,
`CONTRADICTIONS` C/s/f-numbers, `WORDS`). `scripts/` is `docs/scripts/`. `BRIEF` = Sean's six decisions of
2026-11-17 as given in this job's brief.

A caution that applies to every section: the cards quote GitHub issues (#546, #733, #734, #736, #738, #463,
#676, #728). I did not read the issues themselves; quotes from them are as the cards give them, and the
cards do not always say whether the words are Sean's own or a session's text he said yes to.

---

### The Widow's Place (`widows-place`)

**Where it sits:** Act I, open part. Needs the badge (day 2 and the funeral done). Its place "after No
Justice" is P (`BUILD_ORDER` step 2b; `DECISIONS` gap 7; `OUTLINE` Act I table). Must come before
`joe-on-the-rope` (it gives the rifle, D) and is meant to come before `farmhouse-rescue` (the lock,
2026-11-03: "Order: the peaceful visit, then the hostage crisis."). **Not built as a mission.** Built pieces
it would use: the farmhouse on its knoll (`src/missions/farmhouse.gd`, `config/valley.json`
`widow_homestead`), the Winchester 1873 (#792, `src/weapons/winchester73_*.gd`, "Waiting on Sean's play",
`docs/lanes/gameplay.md`), the funeral with the Baron's offer (`src/missions/funeral.gd`,
`config/moments/funeral.json`), the sheriff's horse put up at the livery's front ("built; no livery man
yet", `scripts/sheriff_road.json` `town.livery`). Not built: the rifle on the sheriff's saddle
(`scripts/sheriff_road.json` setup S14: "P: no rifle on his saddle in the game yet"), riding, the boys, Blue.

**In one line:** Harlan rides the dead sheriff's horse home to his widow; he meets her boys at play and the
dog Blue, she shows him the Baron's stakes at her ditch, asks about her husband's end, and gives him the
sheriff's Winchester.

**Harlan walks in with:**
- Badge: yes, a deputy "only for now, until the county decides" (D, Sean 2026-11-17, this session).
- Gun: the sheriff's revolver, given on day 2 (D, Sean 2026-11-17, this session). No rifle yet: this is where he gets it.
- Horse: he is riding the sheriff's horse (D, Sean 2026-11-09, card). Whether he owns a horse of his own:
  "Harlan has no horse at the start" is P (Sean's "maybe", 2026-11-09, `the-sheriff` card).
- The rifle is on that horse: "in its scabbard on that horse from day 1 (P)" (`SETUPS` S14). Not built.
- Dynamite: not stated (dynamite arrives in Buried Alive, D, inventory 2026-11-09).
- Companion: not stated.
- Wounds: not stated. Earl's blood may still be on his coat (S50, P·bible, `SETUPS`).
- What he knows: the sheriff's last words if he heard them (the sorrel, "friend", the ditch: `OUTLINE`
  knows-table, P·bible); the Baron's offer at the grave if he went to the funeral (D).

**How he hears of it:** The sheriff's horse has stood at the livery since day 1; the livery man says it
eats his oats and someone should take it home to her; anyone in town can say it; a player who never goes
hears it again [D, Sean 2026-11-09: "you ride the sheriffs horse out and she gives you his rifle"; the livery
man's part is the card's wording under that D].

**Beats, in order:**
1. In town, the livery man grumbles about the sheriff's horse and says someone should take it home to her. [D as the way in, card; the line is P·bible, `VOICES`]
2. Harlan rides the sheriff's horse out by the East Road, about 2 km. [D, Sean 2026-11-09, card]
3. The ride passes the place where he found the sheriff on day 1; nothing marks it but what's left on the ground. [D, Sean 2026-11-09 "Yes I like all the ideas about what happens when you're there", card]
4. Coming up her lane, the two boys are playing sheriff and outlaws with sticks round the woodpile and the wagon, Blue in the middle; they "hold up" the rider. [D, same answer, card]
5. He hands the horse over to her. [D, card]
6. He can stay: coffee in her kitchen, where he sees the back door. [D, same answer, card]
7. He can do a chore she's behind on since the funeral (split wood, mend the gate, water the stock). [D, same answer, card]
8. He can walk the property with her: the yard, the outbuildings, the ditch and the Baron's stakes. This is where he learns the ways in. [D, Sean 2026-11-09 "Yes I like both"; the lock 2026-11-03]
9. She asks about the end: "Were you with him?" or "Did he suffer?"; he answers with a nod or a shake. [D, Sean 2026-11-09 "Yes I like the answering question"; the wording of her question is under dispute, see f4 below]
10. She gives him the sheriff's rifle, the Winchester. [D, Sean 2026-11-09]
11. She may give him the horse too, so he rides it back and it is his from then on. [P, Sean's "maybe" 2026-11-09]
12. Or he can be short with her and go; that is remembered too. [D, same "what happens when you're there" answer, card]

**Choices, and what each sets:**
- What he tells her about the end: `widow.told_end` = the truth / a kind lie / not asked [D that the question is asked; a lie found out later costing her trust is P, `DECISIONS`].
- Stay or go, do the chore or not: feeds "her trust" [D, "Yes the after effects too"].
- Make friends with Blue and the boys or not: `blue.knows_harlan`, `boys.know_harlan` [D, `DECISIONS`].
- Take the rifle (and horse) or leave them with her [P, card].
- Not going at all: `widow.visited = no` [D].
- Facts set (`BUILD_ORDER` 2b): `widow.visited`, `blue.knows_harlan`, `boys.know_harlan`, `widow.told_end`, `harlan.has_winchester`, `harlan.has_sheriffs_horse`.

**Endings, and what it leaves in the world:** (all D, Sean 2026-11-09: "Yes the after effects too", card)
- Blue knows him: at the farmhouse rescue Blue doesn't bark at Harlan, he barks at the gang and gives them away. Never met, he barks at Harlan too.
- The boys know him: in the farmhouse's Phase B they come to a voice they know and follow him out; a stranger, they hide.
- He knows the house: the back door, the kitchen, the yard.
- Her trust carries her lines from here on: `sheriff.care`, `funeral.attended`, this visit, the chore, the answer.
- Not going is remembered: at the farmhouse he is a stranger to all three.
- He has the Winchester [D]; maybe the sheriff's horse, which the town knows as the sheriff's [P, Sean's maybe; `SETUPS` S13].

**Who is in it:** Harlan; the widow (no name: "ma'am", "Mrs.", C14 c); her two young sons (names "Sean's",
`VOICES`); Blue the dog ("can never be hurt or killed", #728 as the card quotes it); the livery man; the
sheriff's horse. "The Baron's man back twice since the funeral" is named on the card but not present [card
candidate B].

**Sean's own words:**
- "Oh we forgot the quiet mission of riding out to the widows property where you meet her for some reason - this is when we meet blue and the kids playing" (2026-11-09, chat, quoted on the card).
- "Yes I like both, you ride the sheriffs horse out and she gives you his rifle" (2026-11-09, card).
- "you ride the sheriffs horse out and she gives you his rifle" (2026-11-09, card, the same sentence quoted short).
- "Yes I like all the ideas about what happens when you're there" (2026-11-09, card).
- "Yes I like the answering question" (2026-11-09, card).
- "Yes the after effects too" (2026-11-09, card).
- "the quiet mission" (his name for it, card) / "the quiet mission of riding out to the widows property" (`README`).
- The lock, 2026-11-03, PR #621, as the farmhouse card records it (the card does not say these are Sean's typed words): "Order: the peaceful visit, then the hostage crisis." "Her lines follow the help-or-leave deed from the opening." The visit "shows the property's ways in first: the back entrance, kitchen, yard and outbuildings".
- #728 as quoted on the card (whose words not stated): Blue "can never be hurt or killed"; "He barks at strangers, follows the boys"; "he gives the gang's position away, or the player's".
- On the horse (2026-11-09, a "maybe", card and `the-sheriff` card): no verbatim words given; recorded only as "PROPOSED (Sean, 2026-11-09, a 'maybe')".

**Lines of dialogue anyone gave:**
- Widow: "Were you with him?" (bible lists it as "Sean's beat, 2026-11-09"; the words first appear on the card as a session's candidate, `VOICES`).
- Widow: "Did he suffer?" (card) / "Did he suffer? Don't dress it up for me." (bible, `VOICES`).
- Widow: "He'd want it used." (the rifle; "an earlier session's line", `VOICES`; card has "he'd want it used").
- Widow: "My husband cut that ditch with a spade and a borrowed mule. That man can offer till he's hoarse." (bible, `VOICES`).
- Widow: "They know your voice now. Call them, and they'll come." (bible, `VOICES`).
- The boys: "Hands up, mister! This is a hold-up!" · "That's Pa's horse." (bible, `VOICES`).
- Livery man: "That horse is eating my oats, and the man that owned him's in the ground. Somebody ought to take him home to her." (bible, `VOICES`).
- Livery man, day 1: "That's the sheriff's bay. ... There's blood on this saddle." / "I'll put him up. Rifle and all." / "He's fed here, whoever pays." (script, `scripts/sheriff_road.json` `town.livery`).
- Sheriff on the road: "Winchester's right there on my saddle. Never put a hand to it." / "My wife's got bread rising." (script, `road.idle.clear`; "needs: the rifle on his saddle (not built)").
- Sheriff, day 2: "Take my pistol. She pulls a hair to the left." (script, built, `day2.pistol.clear`).
- Foreman on the widow's lane, later: "We've met, Deputy. You sat very still." (bible, `SETUPS` part E; belongs to the farmhouse, listed because it is "the widow's lane").

**Pays off from earlier / plants for later:**
- Pays off: the sheriff's horse led in on day 1 (S13, D); the rifle on its saddle (S14, plant P); the Baron's offer at the grave (S3, D: a player who skipped the funeral hears of it from her here and sees the stakes); day 1's care (`sheriff.care`: her lines follow it, D lock).
- Pays off (P·bible): "That's not the way this works, son." said back by the widow when he tries to refuse the rifle, "and the first time she smiles" (S15); "She pulls a hair to the left.": "it doesn't pull left; he did, and he told everybody it was the pistol" (S41); the bread rising, "what she thought that morning" (S42); the freighter's story has reached her if he left the sheriff ("a name. Harlan, or near it", `SETUPS` part E); she "knows the horse when it comes to her gate" (`OUTLINE` knows-table).
- Plants: the rope shot ("The dead sheriff's rifle saves Joe", S14, D); the boys' game and Blue for the farmhouse (S16, D); the ways in (S17, D; the last walk reads them); "First to use it owns it": the stakes at her ditch, her husband dug it first, why the Baron needs her signature (S35, D v2); the widow on the final walk (`OUTLINE` "What the walk reads").

**Every other idea found:**
- The name "The Widow's Place" is a session's [P, card]; other name "the peaceful visit" (lock, PR #621 step A6).
- Candidate A, "Bringing the sheriff home": his horse, saddle, rifle in its scabbard; she gives the rifle because "he'd want it used", or she can't stand to look at it [folded into C, D].
- Candidate B, "She sent for the law": stakes at her ditch heading, a man watering stock at her creek, the Baron's man back twice since the funeral; she wants the new deputy to see it [folded into C, D]. Whether the watering man and "back twice" survive is not separately confirmed.
- With "no horse at the start", this is the first time he rides; the opening has him lead the horse in with the sheriff across it [P, Sean's maybe + session, card and `the-sheriff`].
- Why Harlan has no horse: sold for the claim, lame, or new to the valley [O, `the-sheriff`].
- The horse is "a horse he didn't buy, that people in town know as the sheriff's" [P, card]; "After that the town knows whose horse he's on" [S13].
- The first long ride in the game, with nothing at stake: a good place to learn riding [P, card]; the cheap place to tune the boys and Blue before the farmhouse [P, `BUILD_ORDER`].
- The chore uses `CivilianBrain.chores` [P, card].
- "If he left him and lies, the truth can reach her later through the witnesses and the rumour system; the kind lie costs more when it's found out." [P, card]
- Whether she still gives the rifle and horse if he left the sheriff to die and she knows it; if not, where the Winchester comes from [O, card; `DECISIONS` gap 2].
- The boys' play needs "a small brain: running, play-acting, reacting to a rider" [P, card].
- "Funny on its face; underneath, it's their father's game." [card, under Sean's D]
- The widow's lines: "Calls Harlan 'Mr. Harlan', always. To the boys: 'the deputy'." [P·bible, `VOICES`]
- "She never knows more than 'a red shirt' about the killer unless Harlan's deeds tell her." [`VOICES`; reads stale since C16]
- "From B6, the stakes at her ditch and the Baron's man watching." [`VOICES`]
- Later (P·bible, S50): the widow sees whether his coat is clean of Earl's blood.
- The Baron wants the widow's water: known to "the sheriff and his wife, for years (P·bible)"; Harlan learns it "at the grave, or at her ditch" [`VOICES` K6].
- No romance with Harlan, ever [D, 2026-11-03, `VOICES`]. Older: "marry the widow and hold the valley" as an ending; "marrying the widow is a real, binding thing with property consequences" [Superseded, `DESIGN.md` §5].
- Older: "The widow — refuses to sell her claim, alone" [`DESIGN.md` §5 cast; superseded by the lock: two sons]; "the gang burns out the widow on day 9 if she still holds her claim and nobody's guarding it", "the widow's burn-out night" as a hand-built moment [Superseded: no day count (D 2026-11-01), fire out of play (#458), the farmhouse rescue instead].
- Family question, unsettled in the older sources: "Are the widow's children the dead sheriff's children? Are they based on the user's two sons?" (`sources/no-law_draft`, open questions); "We subsequently considered making her and the children Harlan's own family instead. That potential change must be resolved" (`sources/inventory`); "The widow's children may also feature, alongside Blue, the family animal, but the precise family setup remains unresolved" (`sources/inventory`). The lock and the card treat them as the sheriff's sons [D lock].
- No-law draft's purposes for the funeral that this visit carries on: "Establish the widow and her family before later threats against them"; "Harlan meets the sheriff's widow before she later becomes a hostage"; "The family is familiar to the player rather than introduced only when threatened" [P, `sources/no-law_draft`].
- Systems: riding and leading a second horse (horse lab P2, #478), child bodies `ProtectedChild`, Blue, talk and the nod, memory that lasts, story state [P, card].
- Map: `widow_homestead` (1712, -560), her lane off the East Road past Bridges A and B, her fields down to the creek 130 m north, her ditch heading in the canyon mouth [D, `config/valley.json` via card].
- Story judge: the quiet missions "exist only as unscheduled cards; the funeral is the only quiet beat in the order" [`judged/2026-11-09_story`, written before this card].
- "Still art's: … the widow's gate (#906); the rifle on the sheriff's saddle (S14)" [`scripts/CHANGES.md`].

**Where the sources disagree:**
- **Her question.** Card: "Were you with him?" / "Did he suffer?", a lie possible [D that a question is asked]. Bible f4 [P·bible, 2026-11-17]: she already asked "Were you with him?" at the bedside on day 2 and watched him die, and the town knows who brought him in; so "She asks about the road: what he said, how long he lay there." Unsettled (f4 is not Sean's).
- **"First time."** Card: "the first time Harlan talks with her"; the boys met "for the first time". Bible f5: she spoke to him at the bedside and at the grave; make it "The first time at her home" [P·bible]. Sean's "this is when we meet blue and the kids playing" stands for the boys and Blue.
- **"The Baron's man back twice since the funeral."** Card candidate B. Bible f3: if that's the foreman on his sorrel, the widow knows the horse before the farmhouse and S40's payoff is spent; "Another hand comes those two times" [P·bible]. Unsettled.
- **Where the rifle is.** Card: she "gives him the sheriff's rifle" [D]. Scripts: the rifle is on the saddle at the livery ("Rifle and all.") and so in Harlan's hands on the ride out before she gives it [P]. Not contradictory, but nobody says whether Harlan may draw it before she gives it.
- **Place in the order.** `BUILD_ORDER`: after No Justice [P]. `OUTLINE` flowchart: straight from day 2 (dotted), "any order". `DECISIONS` flow: released → widow → rope. Unsettled; only "before the rope" is D.
- **Does the widow know of the killer?** `VOICES`: she knows only "a red shirt". `OUTLINE` knows-table (2026-11-17): she heard the last words (the sorrel, "friend", the ditch). The later table follows C16.

**Open questions:**
- Does she give the rifle (and horse) if Harlan left the sheriff and she knows? If not, where does the Winchester come from? (`DECISIONS` gap 2)
- Does he keep the horse? (Sean's maybe) Does he have his own horse at the start? (Sean's maybe)
- What exactly she asks, now that she was at the bedside (f4).
- Its place relative to No Justice.
- The boys' names (Sean's).
- A third plant for the Baron's want, for a player who skips both the funeral and the visit (S3 gap, O).

---

### Joe on the Rope (`joe-on-the-rope`)

**Where it sits:** Act I, open part. After `no-justice` **and** after the rifle [D, Sean 2026-11-04, #546:
"Joe on the rope happens after Harlan has been given the rifle."]. The story judge's suggested order put it
in Act II as "Joe's Act II beat" [P, `judged/2026-11-09_story`]; the bible says Act II needs one Joe beat and
"the rope is it, if the player hasn't done it yet" [P·bible, `OUTLINE`]. **Mission not built.** Built pieces:
the Winchester 1873 (#792; key 6); `Rope` (`src/structures/rope.gd`: a hemp line a ball cuts strand by
strand, "#734: the rope shot; later Joe's hanging", a sack as stand-in load); the gun lab's rope range
(`win73/rope_range.gd`, F5's last stop; `docs/LAYOUT.md`); Joe as companion (`src/people/companion_brain.gd`:
"The rope turns `spared` off"). Not built: a hanging body, the mob, the place.

**In one line:** Men string Joe up; Harlan has a few chances to shoot the rope with the sheriff's Winchester
or get in close and cut him down, and if he fails Joe is dead for good.

**Harlan walks in with:**
- Gun: the Winchester 1873, the sheriff's, from the widow [D, Sean 2026-11-09]; the sheriff's revolver [D, this session].
- Badge: yes.
- Horse: not stated (the card's "ride under Joe and lift him" assumes one; the set-piece judge cut it).
- Knife: "cut it with a knife" is a proposed way [P, #546]; where the knife comes from is not stated.
- Dynamite, companion, wounds: not stated. Joe is the companion and is the one on the rope.
- What he knows: how No Justice ended, since that is the cause.

**How he hears of it:** "whoever warns Harlan says where they're taking Joe, and the route brings him to the
overlook as the mob gathers. A nudge, not a marker." [P, #546]. "The overlook is suggested by the route, not
a marker." [D, Sean 2026-11-04, #546 "yes to the rifle plan"]. Who warns him: O. ChatGPT: "A frightened
townsman runs to Harlan; a crowd is shouting near the hanging place; the commotion carries through the
street. No quest marker." and "The crowd gathers when Harlan next returns to the town centre after the
relevant No Justice consequence, not at an arbitrary real-time deadline." [P, ChatGPT].

**Beats, in order:**
1. The cause, arrest ending: Kett, released, walks Main Street; Joe kills him there in front of witnesses; the town tries to hang Joe. [D, Sean 2026-11-09, `sources/no-justice_sean` §7]
2. The cause, revenge ending: the bodies at the cabin are found; the bandits' kin or friends learn who rode with Harlan, come for Joe and try to lynch him. [D, Sean 2026-11-09, same]
3. If Joe's disguise did not hold (revenge ending), the kin go to the Ute camp rather than to Joe. [D, Sean 2026-11-09 "Disguise matters, yes", `no-justice` card; where the rope is then: O, s2]
4. Someone warns Harlan and says where they are taking Joe. [P, #546; who: O]
5. The route brings him to a high place as the mob gathers. [D, Sean 2026-11-04, #546]
6. Joe is hauled up choking, not dropped. [D, Sean 2026-11-11, per `OUTLINE`; his words not in the sources read]
7. Harlan has three or four chances at the rope from distance. [D, Sean 2026-11-11, per `OUTLINE`]
8. Or he closes in and cuts Joe down. [D, Sean 2026-11-11, per `OUTLINE`]
9. Other ways "stay open but slower": shoot the man holding the rope's end, ride under Joe and lift him, cut it with a knife, or scatter the mob. [D that they stay open (Sean 2026-11-04); the list is P, #546]
10. If Harlan can't save him, Joe dies; no rescue by someone else, no fail-and-retry. [D, Sean 2026-11-04, #546]
11. Saved, Joe is down and hurt and has to be helped and cut loose; the mob's men remember who did what. [P, #546]

**Choices, and what each sets:**
- Save him or lose him: `joe.alive` yes / no [D]. "The choice is in the doing: shoot the rope, shoot a man, ride in, or hesitate." [card]
- Whether killing mob members has a cost weighed against the clock: O [card]. The mob's men are townsfolk [P reading, card].
- ChatGPT's big choice: "Protect Joe in public and risk alienating townspeople or starting bloodshed; uphold a questionable mob's demand and permanently abandon Joe." [P, ChatGPT]

**Endings, and what it leaves in the world:**
- Joe alive: he is Harlan's main companion and later "the man with plans" [P, #738]. On the final walk he is beside Harlan [D, `OUTLINE`].
- Joe dead: for good. "The rest of the game has to carry on without him: his community's reaction, his burial (#259, the coffins), the threads that used him (the disguise, later missions, the finale) playing out with Harlan alone or someone else. Each Joe-dependent thread needs a without-Joe path." [P, #546]. A grave at the camp on the final walk [D, `OUTLINE`]. "Joe's death is persistent and remembered by the town and his people." [P, #546]
- The later missions have paths without him [D, Sean 2026-11-11, `CONTRADICTIONS` Part A 5]. `DECISIONS` "Without Joe" table: Shipment partly covered, Payday covered, I Am the Law a gap (s7), the Bridge open, farmhouse covered.
- "The same faces, hats on, at the rope" as stood at the grave [P·bible, `SETUPS` part E].
- Payday Night: Joe on the outside stair "only if the rope's outcome lets him" [P·bible, f9].

**Who is in it:** Joe; Harlan; the mob (townsfolk in the arrest ending; the bandits' kin or friends in the
revenge ending); "the loudest man at the rope" (P·bible, `VOICES`); whoever warns Harlan (O). ChatGPT: a
"Mob leader: PROPOSED NEW NPC with distinctive work coat and rope or noose", "No Justice victim's kin:
PROPOSED NEW NPCs, or existing outlaws reused; identities OPEN".

**Sean's own words:** (the #546 lines are as the card quotes them under "DECIDED (Sean, 2026-11-04, #546)")
- "**If Harlan can't save Joe on the rope, Joe dies.** It's a real immersive-sim moment: no rescue by someone else, no fail-and-retry built in" (2026-11-04, #546, card).
- "Joe on the rope happens after Harlan has been given the rifle." (2026-11-04, #546, card).
- "men decide to **hang Joe**, because he's been helping Harlan. Harlan has to **shoot the rope** while Joe hangs to save him." (2026-11-04, #546, card).
- "The overlook is suggested by the route, not a marker." (2026-11-04, #546 "yes to the rifle plan", card).
- "About 100–150 m" (2026-11-04, #546, card).
- "The other ways stay open but slower." (2026-11-04, #546, card).
- "yes to the rifle plan" (2026-11-04, #546, card). The plan said: "**The rifle is a Sharps 1874 single-shot** (accurate and powerful, one shot then a reload), and a period telescopic sight is optional."
- "Yup those are perfect" (2026-11-09, #733, card), to a plan in which the Winchester 1873 is "**given before the Joe hanging** (shoot the rope from an elevated spot)" and the Sharps is "The far shot; slow and rare (one find or one mission)", built "Later".
- His No Justice card, 2026-11-09 (`sources/no-justice_sean` §7, "his mission write-up plus the master chat's changes, which he accepted that day"): "Both main endings lead to the same big moment, for different reasons. **Someone tries to hang Joe, and Harlan shoots the rope with the Winchester** (#734, #738)"; "**The arrest ending:** the released murderer is in town. Joe kills him there, in front of witnesses, and the town tries to hang Joe."; "**The revenge ending:** the bandits' kin learn who rode with Harlan, come for Joe, and try to lynch him."; "**The bandits' kin or friends hear and come looking.** That's the trigger for the hanging (below)."
- "Disguise matters, yes" (2026-11-09, `no-justice` card).
- 2026-11-11 (hauled up, three or four chances, or close in; "it isn't hard to save him"): **no verbatim words found.** Only the bible's paraphrases: "Joe is hauled up choking, not dropped: 3–4 chances at the rope from distance, or close in and cut him down (D, 2026-11-11)" (`OUTLINE`); "he can die, it isn't hard to save him, and the later missions have paths without him" (`CONTRADICTIONS` Part A 5).

**Lines of dialogue anyone gave:**
- The loudest man at the rope: "He killed a white man on this street in daylight. Every one of us saw it. What's left to try?" (bible, `VOICES`; "Righteous, not a villain; one of the few allowed a slur (C13 b), once, where it matters").
- Kett on Main Street, before Joe kills him: "Morning, Deputy. Fine day to be at liberty." / "Still here, Deputy?" / "Say good morning to your Indian for me." (script, `scripts/no_justice.json` `street.kett`; the third only if he saw Joe's face at the cabin: "it is a threat").
- Joe at the release: "Doc told us. In his office." (script, `release.joe`).
- Period words for it: "string him up", "stretch his neck", "a necktie sociable" (`WORDS`).
- No line found for the warning, for Joe on or after the rope, or for the kin.

**Pays off from earlier / plants for later:**
- Pays off: No Justice's choice (both endings, D); the sheriff's rifle (S14, D); Joe's disguise (S12: whether the kin come for Joe or go to the camp; `nojustice.kett_saw_joe`, P·bible "add"); day 1's steward hands: "Joe's leg, dressed by the same hands (the rope's card: 'the wound stays')" (P·bible, `SETUPS` part E; the card itself says only "Joe is down and hurt"); "Joe's leg bleeds on the same coat" (S50, P·bible); T7 "the mob (the rope)".
- Plants: `joe.alive` for every later mission; the walk; whether Joe may come to Payday Night (f9, P·bible).

**Every other idea found:**
- Other names: "the Joe hanging", "the rope shot" (#734, #738); ChatGPT's "The Hanging".
- A reason tied to No Justice: "if Harlan shook his head and the killer was released, **that man leads the lynching**; if Harlan nodded and Joe killed him, **the killer's friends** come for Joe." [P, #546; superseded by Sean's 2026-11-09 causes; and the nod is the wrong way round, f1; "a dead man leads nothing", f2]
- "the bandits' kin or the town's anger at how that mission ended" [P, #738 comment].
- "**Handle it seriously,** as No Justice is: a lynching of a Ute man is real history and racism, not spectacle. It's about Harlan's loyalty and the town showing what it is." [P, #546]
- "Joe's own physiology sets the clock: a short-drop strangulation, roughly tens of seconds until he's unconscious and minutes until he dies, so there's a real but short window." [P, #546; the drop is Superseded by "hauled up", 2026-11-11]
- "The window must be fair: readable, achievable and the same every time for the same actions." [P, #546]
- "This is the one exception to 'Joe can't die in routine combat'." [P, #546]
- "**no idea depends on him alone.**" [P, #738 rule 2]
- Where: "a ridge, a loft or a rooftop above the hanging tree" [P, #546]; "Not placed: reserved as OPEN. The creek's cottonwoods below the Baron's rise, or the canyon rims, give that distance." [O, `docs/briefs/valley-plan.md` §10]; "hangings from the livery's hay-hoist beam when the law won't act" [P, `DESIGN.md` §11 period details, Sean 2026-10-06 "ideas only", not tied to Joe]; ChatGPT: "Existing Salt Creek main street and an adjoining yard or square", high spot "hotel balcony, upper saloon room, or stable loft" [P, ChatGPT].
- A period telescopic sight, optional [P, #546 rifle plan].
- "A rope at 30–60 m must be hittable for a steady player, and hard but fair under pressure." [#734, card]
- Set-piece judge, score 3: "a 2 cm rope at 100–150 m is under a pixel at 1280×720, so the 30–60 m range (#734) is the buildable one"; raise: "Degrees, not a switch: a graze cuts strands and the rope parts under his weight seconds later, or not; cut down, Joe falls with his hands tied"; "The mob answers the first shot: heard late by distance, some scatter, the man on the rope's end hauls or runs; the first shot changes the second"; cut "ride under Joe and lift him" [P, `judged/2026-11-09_setpieces`]. The built `Rope` already cuts by strands.
- The mob reuses the crowd from Payday's floor lab (#745) [P, `BUILD_ORDER`]. A rope lab "to open" [P, `BUILD_ORDER`].
- Cutting a man loose (hold E) and dragging by the collar exist (`HostageBrain`) [card].
- ChatGPT's beats [all P]: the crowd, Joe restrained (choices: climb, move through the crowd, try to break it up, leave); the high position ("pressure the ringleader from the roof"); "A missed rope shot means Joe dies, as specified; do not secretly correct the bullet"; the street afterward (arrest the ringleader, let the mob scatter, pursue someone fleeing, tend to Joe).
- ChatGPT's ways [P]: Precision; Confrontation ("Enter the crowd and attempt arrest, intimidation or a close intervention"); Abandonment.
- ChatGPT [P]: "A nod to the ringleader may be used if a close conversation happens"; "Even a successful rescue may kill or injure bystanders if Harlan fires recklessly."
- ChatGPT [P]: "If the mob leader dies first, other mob members may flee, fight or continue"; "A wound can make his rescue more urgent; if he survives, he needs treatment"; "Player flees or gives up: Joe is hanged; witnesses remember Harlan leaving"; "Unthinkable: Harlan shoots Joe, helps the mob, or kills surrendered townspeople. The town responds as it would to a public killing".
- ChatGPT's afters [P]: Joe saved, mob restrained ("some townspeople call him brave, others say he protects a murderer. Joe remains companion, but his legal trouble may persist. The ringleader can face custody or later retaliation"); Joe saved, bystanders harmed ("Newspaper or rumours focus on collateral deaths"); Joe dies ("Harlan rides without him. This is not a generic game-over screen"); Harlan sides with mob ("The deed can surface again at an inquest or final reckoning").
- ChatGPT [P]: "cutting a loaded rope with a rifle is highly improbable and must feel extremely difficult, not like a routine trick shot"; county jurisdiction and "how a sheriff would respond to a lynch mob need research"; "Whether Joe can be arrested rather than hanged if Harlan intervenes early" [O]; "Whether close-range intervention can save Joe once the drop begins" [O; answered by Sean 2026-11-11: yes, close in and cut him down]; "whether the town newspaper exists" [O in ChatGPT; the paper is D since 2026-11-11].
- ChatGPT [P]: "The public shooting can feed The Inquest if that concept is later approved."
- Inventory Part 3, older concept: "The Hanging | Execution-related moral confrontation" [not canon, `sources/inventory`]. `DESIGN.md` §11 backlog 4: "**The hanging:** the whole town turns out; tension in the crowd, a rescue attempt or a lynch mob" [P, older; `README` maps it to `the-trial`].
- Story judge: the rope "is missing from the order"; "STRENGTHENS"; contradiction 5 "Joe can die on the rope, but Act IV is written with him … or Sean narrows the rope's permadeath" [`judged/2026-11-09_story`]. No Justice's judge: "both endings end at the same rope" (caps choices at 3) [`judged/2026-11-09`].
- "In No Justice's arrest ending … Kett walks Main Street" and Harlan "can run into him. No new mission is needed, just a man on the street" [D, Sean 2026-11-09].
- `OUTLINE` "Where Act I leaves things": "The sheriff's killer is dead in every branch but one that is still O (Harlan murdered him: the rope's cause is unsettled)": this sentence is from before C16 (the man is Kett, who did not shoot the sheriff).

**Where the sources disagree:**
- **The rifle.** Sharps 1874 (#546, Sean 2026-11-04 "yes to the rifle plan") vs Winchester 1873 (#733 Sean 2026-11-09 "Yup those are perfect"; #734; Sean's own No Justice card: "shoots the rope with the Winchester"; the widow's rifle, D 2026-11-09; built #792). Latest word: the Winchester; the Sharps later as the far shot [s5, bible's reading; card says "neither says the other is replaced"].
- **The range.** "About 100–150 m" (#546) vs 30–60 m (#734; the judge: the buildable one). s17: "The build's". Unsettled by Sean.
- **Dropped or hauled.** Card and #546: a short drop, a window of tens of seconds; ChatGPT: "once the drop begins". Sean 2026-11-11 (per `OUTLINE`): hauled up choking, 3–4 chances, or close in. Latest favours hauled.
- **One miss or several.** ChatGPT: "A missed rope shot means Joe dies"; "Explicit one-way fatality on missed rope shot". `DECISIONS`: "Joe dies for good if the rope shot misses (DECIDED, 2026-11-04)". Sean 2026-11-04: dies "If Harlan can't save Joe". Sean 2026-11-11: 3–4 chances and "it isn't hard to save him". Latest favours several chances.
- **Who hangs him, arrest ending.** #546 (P): the released killer leads the lynching. Sean 2026-11-09: Joe kills the released man on Main Street and the town hangs Joe. Latest favours Sean's card (f2).
- **Why.** #546 (Sean 2026-11-04): "because he's been helping Harlan". Sean 2026-11-09: because of how No Justice ended (two causes). Later word favours the two causes.
- **The nod.** Card (#546 text): shook his head = released, nodded = Joe killed him. Built and D: a nod stops Joe (arrest). f1: "Swap them".
- **Where.** An overlook over a hanging tree out of town (#546, valley-plan) vs Main Street / the town (Sean's arrest ending has the killing on Main Street; ChatGPT; the loudest man's line "on this street"). Unsettled; for the revenge ending the place is not stated anywhere.
- **Which act.** Bible: Act I open part. Story judge: Act II. Unsettled.

**Open questions:**
- Who warns Harlan.
- Where the rope is (both branches).
- The cause if Harlan **murdered** the surrendered Kett: neither decided cause applies (s1; `DECISIONS` gap 1; `BUILD_ORDER` "Calls first").
- The cause if Kett was killed outside in the fight ("no question is asked; Joe is furious", D): no source gives the rope's cause on that branch.
- Revenge ending with the disguise broken: the kin go to the camp; where is the rope then (s2).
- The range (s17).
- Whether killing townsmen in the mob has a stated cost.
- What happens to the mob's men afterwards (arrests?), and whether Joe is still wanted for killing Kett on Main Street after being cut down (ChatGPT: "his legal trouble may persist").
- Sean's exact words of 2026-11-11 on "hauled up" (not in the files read).

---

### Cody's arrest in the saloon (no card; C6 b)

**Where it sits:** Act I, open part. After the funeral (so Harlan has the badge and the sheriff's revolver)
[D, Sean 2026-11-11, #830, C6 b]. "Harlan's first arrest in town (… in No Justice's arrest ending Kett's
comes before it)" [`OUTLINE`]. It must come before the jail night. **Not built.** Built around it: Cody and
the murder (`config/moments/no_law_murder.json`, `NoLawMurder`; Cody's stand-in is the blacksmith's model);
"the story's Harlan is unarmed till" the sheriff dies (`docs/lanes/gameplay.md`); arrest by the shout key
(#128, partly). No card, no script scene.

**In one line:** After the funeral Cody walks back into the same saloon, bold as before; this time Harlan
has the sheriff's revolver, and he arrests him: the answer to night one.

**Harlan walks in with:**
- Gun: the sheriff's revolver [D, Sean 2026-11-11 C6 b; given day 2, this session]. On night one he had no gun, which is what prevented a shoot-out then [D, Sean 2026-11-17, this session].
- Badge: yes, deputy [D].
- Rifle, horse, dynamite, companion, wounds: not stated.
- What he knows: Cody killed Earl (he saw it, or heard it retold: K5); if he followed Cody out, which way he rode (S10).

**How he hears of it:** Not stated. Cody simply "walks back into the saloon"; no source says who tells Harlan or whether Harlan is already there. [O]

**Beats, in order:**
1. After the funeral, Cody walks back into the saloon, bold as before. [D, Sean 2026-11-11, #830, C6 b]
2. Same room, same barman; Harlan now has the sheriff's revolver. [D, C6 b]
3. Harlan arrests him there. [D, C6 b]
4. Cody goes to the cell for Earl's murder. [D, Sean 2026-11-11: "be in the jail"]
5. No other beat is written anywhere: who speaks first, whether Cody's friends are there, whether he resists, what the player is asked. [none found]

**Choices, and what each sets:** None written. The evidence table gives the outcomes that matter: the
witness is lost if Cody is "Killed in the cell, freed, or never taken" [D that he is a witness; `OUTLINE`
"All the endings"]. Old row `cody.fate` = in the jail / killed / got away [`DECISIONS`, marked out of date].

**Endings, and what it leaves in the world:** Cody in Harlan's cell → the jail night (below). "The answer
to night one, in the same room." [`OUTLINE`]. T7: "the first arrest, in the same saloon".

**Who is in it:** Cody; Harlan; the barkeep ("He's there for Cody's arrest in his own saloon", `VOICES`);
nobody else named.

**Sean's own words:**
- "He can keep the name Cody and yes he can ride with the gang and be in the jail" (2026-11-11, `no-law` and `no-justice` cards).
- "The bold cowboy is not the murderer - I'll find something else for him - the murderer just has to be some rough asshole" (2026-11-11, `no-law` card).
- Arrested "at some point after Harlan becomes deputy" (2026-11-11, quoted in `CONTRADICTIONS` C6 as D; "how and when" was O).
- "if he dies, Harlan loses the witness" (2026-11-11, quoted in `SETUPS` S4 as D).
- C6: "Sean's pick (2026-11-11): b." (#830). The option's text is the bible's, not his: "Cody walks in again, as bold as before, after the funeral. Same room, same barman, but Harlan has the sheriff's revolver now. Harlan's first arrest, and the answer to night one."
- 2026-11-17 (this session): Harlan has no gun on night one; he gets the sheriff's revolver on day 2; "That is what prevents a shoot-out in the saloon" (the brief's wording of his decision).

**Lines of dialogue anyone gave:**
- None for the arrest itself.
- Cody, night one (built): "Earl. You been dealing off the bottom of that deck." / "Ain't no law left in this valley to save you now, Earl."
- Barkeep (built): "Jesus, Cody, my chair!"; (script) "He owes me four dollars."
- Barkeep, later lines the bible wrote (P·bible, `VOICES`): "I see a deal less than folks think, Deputy. It's cost me, too."
- Undertaker (script, new): "Earl. Nobody can give me his other name. Shot by one Cody, before witnesses. Pine box, charged to the county."
- Cody calls Harlan "nester" (to check), then "Deputy" when he needs him (P·bible, `VOICES`).

**Pays off from earlier / plants for later:**
- Pays off: night one (S2, S4: a whole room saw him kill and the barman knows him by name); the pistol: "She pulls a hair to the left." pays off "at Cody's arrest, the first time Harlan draws it in that saloon" (S41, P·bible); "Went out after Cody" (`nolaw.followed`): "Cody at his arrest: he knows who ran after him" (P·bible); "Carried Earl": "The barkeep's word for him at Cody's arrest" (P·bible); "Sat with the stranger": "the barkeep at Cody's arrest" (P·bible); the chair, kept broken, and the barman as "the witness who'll swear to Cody" (S34, D).
- Plants: the jail night; Cody the witness for the ending (S4); K4, K12, K14 (what Cody can tell after B8: the Baron's men did both, the raid was provocation, the stranger shot the sheriff).
- Cody "Walks back into the saloon bold, because nothing happened to him, or to Kett" (`OUTLINE` knows-table, P·bible).

**Every other idea found:**
- C6 a (not picked): arrested at the cabin in No Justice, "taken alive if the player takes him alive"; "A player who kills everyone at the cabin has no witness." [Superseded by C6 b]
- C6 c (not picked): "On a warrant: the coroner's inquest on Earl names him, and bringing him in is a small mission of its own (the Bounty's shape)." [Superseded by C6 b]
- The bible: "Leans b for the picture; a is cheapest. They can both be true (b if he wasn't at the cabin)." [P·bible]
- Earlier session's proposal: Cody "rides with the red shirt: a player who follows him out of the saloon still learns the raiders' way, and he's among the six at the cabin" [P, `no-law` card; "among the six" now settled no for the scripts, s24].
- s24, settled for the scripts (P until Sean's Script OK): "No. The built hideout has five men and Kett, none of them Cody. He rode on to the Baron's after the raid, which is why he's alive to walk back into the saloon."
- "the man the whole saloon saw kill is the one the law can hold … the man who killed a Ute woman, seen only by her people, is the one let go. The town gets its hanging and Joe gets nothing: No Justice in one picture." [P, session, `no-law` card]
- `cody.fate` set in `no-justice` (in the jail / killed / got away) [Superseded: `DECISIONS` marked out of date].
- Cody "already knows the sheriff is down for good, which is his boast"; knows "That the sheriff was to be shot, and by whom" [P·bible, `VOICES`, `OUTLINE`].
- Cody is "One of the few men allowed a slur (C13 b)" [`VOICES`].
- S48 (P·bible): "Cody in the same cell, later: he knows they let Kett walk, and expects the same."
- Sean's No Law draft had "The same red-shirted murderer" as the saloon killer, "The player recognizes him from the saloon" [Superseded, Sean 2026-11-11: two men].

**Where the sources disagree:**
- **Where he is arrested.** Cards (`no-law`, `no-justice`, `DECISIONS` `cody.fate`): at or through No Justice, "among the six at the cabin". Sean 2026-11-11 C6 b: back in the saloon after the funeral. Latest favours the saloon.
- **Order against No Justice.** C6 b says only "after the funeral". If No Justice's arrest ending comes first, Kett is Harlan's first prisoner and Cody's is the "first arrest in town" (`OUTLINE`); C6's text says plainly "Harlan's first arrest". Unsettled which wording holds.
- **Is Cody at the cabin.** Cards: yes (P). Scripts' reading: no (P until Script OK). Unsettled by Sean.

**Open questions:**
- Everything about the scene itself: how Harlan learns Cody is back, who is with Cody, whether he draws, whether it can end in a killing, what the room does, whether the stranger/foreman is there.
- What happens if the player never arrests him ("never taken": the witness is lost; nothing else written).
- Whether the saloon comes before or after No Justice (s24's second option).

---

### Hold Him Till the Marshal Comes: the jail night, now the Water Tower (`hold-him`)

**Where it sits:** Act I, open part, once "Cody is in the cell for Earl's murder (D)" [`OUTLINE`]. So it needs
Cody's arrest first. `BUILD_ORDER` lists it outside the main line ("when Sean places it"). **Not built.**
What exists: the railroad water tank as a place (`config/valley.json` `water_tank` at (81, -66), a 7×7×11 m
block, D; `water_tower` with a ladder, P, #736 B); the stone jail (art lane: "the jail done, #811");
`valley.json` mission entry `jailbreak` ("DECIDED (the jail is stone; a rubble jail wall takes about three
sticks, #676)"); `Windpump` (four legs, girts, a platform), `PropContents` (barrels leak), the trestle's
`_topple` [`proposals/setpieces`, build check].

**In one line:** Cody waits in the depot's timber freight room for the morning train to the county seat;
the Baron's men come to drop the railroad's water tank on the room, and neither Harlan nor Cody can tell
whether that is meant to free him or crush him.

**Harlan walks in with:**
- Gun: the sheriff's revolver [D]. Winchester only if he has been to the widow's [D that she gives it].
- Badge: yes. Prisoner: Cody.
- Horse, dynamite, companion, wounds: not stated.
- Men sworn in: "whoever you can swear in" is the old DESIGN idea [P, 2026-10-06; not carried into the Water Tower].
- What he knows: not stated. The bible has Cody tell him: "They're coming tonight. Thing is, I can't tell you what for." [P·bible]

**How he hears of it:** O. The card: "no source says; it follows from having a Colter in a cell". The Water
Tower version: Harlan himself walks Cody down to the depot the night before the train [P, card]. Their plan
"shows": axes at the legs, each stroke carries across the yard [P, `proposals/setpieces` v2].

**Beats, in order:**
1. Cody is held in the town's stone jail for Earl's murder. [D, Sean 2026-11-11 "be in the jail"]
2. A murder is tried at the county seat's court, so he goes there by the morning train. [P, card (Sean's question 2026-11-11, the session's "yes"); the county seat down the line is D, C12 a]
3. The night before, Harlan walks him down to the depot and holds him in the timber freight room ("stout, locked, used for the express") to put him straight on the train. [P, card]
4. The railroad's water tank stands over the room: a timber frame on four legs, a stave tank held by iron hoops, a spout, an outlet valve. [D as the set piece, Sean 2026-11-09 "yes add yours"; detail from `proposals/setpieces` v2]
5. The Baron's men come. They mean to drop the tank on the freight room. [D, Sean 2026-11-11, #830, C7 c]
6. The player can't tell whether that frees Cody or crushes him. [D, C7 c; Sean 2026-11-11: "the player doesn't know which until it happens"]
7. Axemen set to the legs; each stroke carries; it takes minutes a leg; a half-cut leg groans by its load: the axes are the clock. [P, `proposals/setpieces` v2; under Sean's "yes add yours" to v3, which keeps v2]
8. The player's levers: the valve and spout (it drains in minutes), a hoop's lug knocked off by a use action (the staves spring, it empties in ~30 s), stopping axemen, or cutting the far legs himself to drop it on the yard. Bullet holes only show the level. [P detail of the D pick; v3; how these read with one side instead of two is not rewritten anywhere]
9. Graded results: one leg cut, it holds; half-drained, it stoves in the far wall; full, it crushes the room; or it lands in the yard. [P detail of the D pick; card]
10. Cody ends freed, dead, or still held for the train. [D pick 2026-11-09 as recorded in `DECISIONS` `prisoner.fate`; `OUTLINE`: "In the county's hands and talking, dead in his cell, or gone"]

**Choices, and what each sets:**
- `prisoner.fate`: freed / dead / still held for the train. `depot.tank`: standing / wrecked [`DECISIONS`, "DECIDED pick"].
- Alive and safe, Cody is "the witness": "the first man who can tie the Baron to the sheriff's murder and the raid" [D that he is the witness, 2026-11-11; `OUTLINE`].
- Old choices (DESIGN.md 2026-10-06, P): hold the jail, give him to the mob, take the brother's money, or let him go to buy peace [Superseded in setting by the Water Tower and C7 c; nobody says whether the bribe or letting him go survive].

**Endings, and what it leaves in the world:**
- The wrecked tower and freight room stay; the yard is wet; the daily train can't take water at Salt Creek until the tank is rebuilt [D pick, card; `OUTLINE` walk: "the depot's tank" among what stays broken].
- Cody: "In the county's hands and talking, dead in his cell, or gone" [`OUTLINE` walk table]. Dead: "the Baron's loose end tied" [`DECISIONS`].
- The witness is the second kind of evidence for the ending: lost if "Killed in the cell, freed, or never taken" [D system, 2026-11-11].
- "Read after: what fell, how full, and on whom says plainly whose plan won." [P, v3; written for two groups]

**Who is in it:** Cody; Harlan; the Baron's men (axemen; C7 b named "Cody's own partners" and "the foreman's
men", not picked); the depot agent is nearby by place (not named in any source for this night). Superseded
cast: a Colter in the cell, his brother with money, the gang, a town mob with a rope, a U.S. Marshal, the
red shirt's friends.

**Sean's own words:**
- "yes add yours" (2026-11-09, picking the Water Tower version 3, card).
- "Can you think of any other big set pieces? That would be a couple more fives, something that's never been done before, and it would meet the criteria for a five." (2026-11-09, `proposals/setpieces`).
- Showcase moment (2026-10-21, quoted in `proposals/setpieces` as "Sean's showcase moment"; `docs/briefs/showcase-moments.md`): "Shoot out the tower's legs in a fight below; it comes down and floods the yard, or falls on the jail's back wall and frees whoever's inside."
- "is Cody being brought to the train to go to a bigger jail?" (2026-11-11, card).
- "He can keep the name Cody and yes he can ride with the gang and be in the jail" / "be in the jail" (2026-11-11, cards).
- The Baron's men come "either to break him out or to kill him so he never talks, and the player doesn't know which until it happens" (2026-11-11, quoted in `CONTRADICTIONS` C7 as D).
- "the jailbreak is a mission or set piece (the jail, #765...)" (2026-11-11, quoted in C7 as D).
- "if he dies, Harlan loses the witness" (2026-11-11, quoted in `SETUPS` S4).
- C7: "Sean's pick (2026-11-11): c." (#830). The option's text is the bible's: "The Water Tower, one side: they mean to drop the tank on the room, and whether that frees him or crushes him is what the player can't tell."
- #676 (2026-11-05, "as recorded" on the card): "A rubble jail wall takes a bundle (about 3 sticks); one stick only cracks and spalls the near face."
- `DESIGN.md` §5 story mission 2 ("**proposed**, Sean 2026-10-06; features are frozen"): "You have one of the Colters in a cell and the Marshal's wire says two days. The gang wants him out; the town wants him hanged now (a mob with a rope); his brother offers you money. Hold the jail with whoever you can swear in, give him to the mob, take the money, or let him go to buy peace. Uses the jail, leading men (signature 6), fire (they'll try burning you out) and dynamite (the back wall)."
- Inventory 2026-11-09, Part 2 ("Brainstorm"): "17. Hold the Jail: Harlan must defend the jail against people attempting to free or kill a prisoner."

**Lines of dialogue anyone gave:**
- Cody: "They're coming tonight. Thing is, I can't tell you what for." (bible, `VOICES`).
- Cody in the cell: "sullen, then frightened, then bargaining" (bible, a direction, not a line).
- S2's payoff (P·bible): Cody, who said "Ain't no law left in this valley to save you now", is held under the tank and "the only thing that can save him now is the law: Harlan. He says so." (no wording given).
- Kett in the same cell earlier (script, `jail.kett`): "Couple of days, Deputy. That's all this is." / "Somebody'll come. They always do send somebody." / "What's supper? ... I ate better in Cañon City."
- Section foreman (bible, another mission): "Spikes drawn, two rail lengths, west of the tank."

**Pays off from earlier / plants for later:**
- Pays off: "Ain't no law left in this valley to save you now." (S2: "the three titles are one sentence. No Law, No Justice, I Am the Law", P·bible payoff); Cody the witness (S4); Cañon City (S48, P·bible); T7 "the law holding a man his own side wants dead".
- Plants: the witness for the Baron's fate (the ending, D); what Cody tells (K4, K12, K14; S37: "Cody in the cell, bargaining, can say what the raid was for"); the wrecked tank on the final walk (S31-type "what stays broken"); "the witness under the tank (C7 c), who can name him" (T1).

**Every other idea found:**
- Other names: "the jail night" (`DESIGN.md` §5), "the jailbreak" (backlog 5; `valley.json`), "the jail break" (#678), "Hold the Jail" (inventory).
- `DESIGN.md` §11 backlog 5: "**The jailbreak:** the gang comes for their man at night." [P, 2026-10-06]
- `DESIGN.md` ten-day shape (P, Sean 2026-10-15 "nothing set in stone"): "Days 7–8 | Things come to a head | Hold him till the Marshal comes; the lynching at the railhead; the dust storm" [Superseded: no day count].
- `DESIGN.md` §8 rope: "**pull a wall down** with a horse (the member-built frame fails where it's weakest — the jailbreak)" [P]. §8 dynamite: "open the jail's back wall" [P].
- `STORY` one-liner: "a Colter in your jail two nights; the gang, the mob, his brother's money" [Superseded].
- Water Tower v1 [P, superseded by v2/v3]: the town's own tower beside the jail's yard, 40,000 L (40 tonnes) on a frame 10 m up; a Colter in the cell; the gang cuts two legs on the jail's side to open the cell wing's stone back wall; "axes left at the tower's legs, a man seen measuring the drop"; bullets drain it (Torricelli); cut the far legs and it falls on the yard or "across the street they ride in by"; "the cell may open, or the prisoner may be crushed"; one leg cut, it leans and holds "until a second cut, the wind, or a man climbing it"; "no water for the town (or the train) until it's rebuilt".
- Judge on v1 (score 4): "the core lever fails the physics: a .45 hole (~1 cm²) under 3 m of water leaks ~0.5 L/s; ten holes take ~2.5 h"; real levers are the valve and spout ("a 15 cm pipe empties it in ~8 min") and the hoops; "make it the railroad's tank by the depot"; cut the wind. "removing the load that decides the collapse, the judge knows in no game."
- v2 [P]: the depot tank; the prisoner in the timber freight room for the morning train ("No Justice's arrest ending sends him off by train"; "the story judge put Hold the Jail on that night"); "The kin or the gang come to free him"; "shoot or cut an iron hoop and the staves spring, the tank bursts in seconds, and the surge knocks men off their feet"; the train "stands at the depot or runs short until the tank is rebuilt"; cut: the wind, the man climbing it, the flood.
- Judge on v2 (4): "the motive doesn't hold (the men who came to free him would kill him with a full tank)"; split the aims between two groups; cut the surge and "shoot a hoop" ("a pistol ball won't part a wrought-iron band: strike off the hoop's lug").
- v3 [Sean's pick 2026-11-09; its two groups Superseded by C7 c 2026-11-11]: the red shirt's friends want him freed (tank half-drained, aimed at the far end; they open the valve and set to the far legs); the Baron's men want him dead before the train ("he's the Baron's hired gun, DECIDED, and he knows who paid him"; full and on the room; the near legs); "Both groups are in the yard the same night; each can see what the other is doing."
- Judge on v3 (5, low): "the fall's direction is a model (tune it so a poor cut can tip it the wrong way…)"; "the axe cuts are canned (make them strokes against the leg's section, so a wounded axeman cuts slower)"; "what the two groups do when they meet is unsaid (it could become a three-way gunfight with no rules)". [O on the card]
- C7 a (not picked): one side, the stone jail; "The Water Tower is dropped or kept for someone else." C7 b (not picked): the Water Tower, both groups the Baron's ("Cody's own partners come to get him out, and the foreman's men come to shut his mouth").
- The card's reason both groups want him before the county gets him: "the gang to free their man, the Baron's men to kill him before he can talk about who pays the gang" [P, card].
- "the wire is from the county, not a U.S. Marshal (a town murder was the county's and the state's to try in Colorado by 1882; federal marshals handled federal crimes). The card's name could stay as the town says it." [P, session]
- "this card's setting moves from the town jail to the depot's freight room for this night (the town jail stays for other prisoners)"; the fire ("burning you out") isn't needed [card, "Settles"].
- Build check [P]: bullet holes can't drain it in a fight; "a stave broken out drains it in ~30 s"; the support graph never tips a structure, the fall's direction must be a model; no lean state, no wind, no NPC climbing, no flood ("a burst and a wet decal"); a falling tank breaking timber works today, stone needs a masonry impact rule; the gang chopping a leg is "a scripted moment (N swings, then `break_member`, unless he's shot)".
- Needs [P]: a `WaterTower` from Windpump's build; the tank's kg as load; `PropContents` scaled to a stave tank; the modelled topple; the axemen as a moment; the timetable holding the train (medium); a use action on a hoop's lug.
- Story judge: "STRENGTHENS | The most sheriff-like mission. As the night the arrested red shirt waits for the train: the kin come to free him, the town wants a rope, the Baron's money on offer. Drop 'burn you out' while fire is out of play." Suggested order: "`hold-him` as the arrest ending's night" [P; the prisoner is now Cody].
- Other missions that say their prisoners "fill the jail (`hold-him`)": `hell-on-wheels` (Gang A taken alive), `i-am-the-law` ("the Baron wants them out before the next train"), farmhouse v2 ("prisoners the gang will come for"), `DECISIONS` `farm.prisoners`, `gang_a.fate`; `MAP`: store-robbery and the-bounty "-.an arrest.-> hold" [all P; f12: "`hold-him` is Cody's night at the depot, not the jail … Point at the jail"].
- `MAP` T6: `store-robbery`, `bank-robbery`, `stage-held-up` → `hold-him` [P].
- Systems the old card wanted: leading people by talking (signature 6), the telegraph (signature 5), a mob with a rope, bribes and money, fire against a building (out of play, #458) [P].
- Map of the old version: the jail (stone), south side of Main Street x +7.6..+38.4, opposite the saloon; the cell wing's back wall faces the rear lane [`valley.json`].
- #736 B: "the depot water tower" as one of the places with height; "A man on the ta[nk]…" [P].
- ChatGPT (Arresting the Baron): "Jail interior should remain in play for prisoner custody, transfer and release." [P]

**Where the sources disagree:**
- **Who is in the cell.** DESIGN.md: a Colter. Setpieces v2/v3: the red shirt (No Justice's arrest ending). Sean 2026-11-11: Cody. Latest: Cody.
- **One side or two.** v3 (Sean's pick 2026-11-09): two groups with opposite aims. Sean 2026-11-11 (C7 c): one side, the Baron's men, aim unknowable. Latest: one side. Nobody has rewritten the levers for one side (the valve "helps the friends" no longer means anything).
- **Jail or depot.** Sean 2026-11-11 words: "the jailbreak is a mission or set piece (the jail, #765...)". Sean's pick C7 c the same day: the depot's freight room. Latest: the depot (C7 c). The stone jail's dynamite back wall (#676, `valley.json` `jailbreak`) then has no mission.
- **Free or kill.** Sean 2026-11-11: "either to break him out or to kill him … the player doesn't know which until it happens". What they actually intend is not written anywhere (v2's judge: a full tank kills him).
- **Who Cody can name.** `OUTLINE` evidence table: "he can say who shot the sheriff (D) and who paid". Hold-him card: "before he can talk about who pays the gang". Same direction; the first is later.
- **The train's hour.** Card: "The train comes through before dawn". Payday: "the noon train". f15: one daily train, "One hour for it, said once" [P·bible]. Unsettled.
- **`prisoner.fate` "Freed".** `DECISIONS`: "back on the street, as the arrest ending's released man". f13: that's Kett, not Cody; two rows needed.
- **Marshal or county.** DESIGN.md: "the Marshal's wire says two days". Session + C12 a: the county seat. Latest: the county (C12 a is D); the card's title still says Marshal.
- **Fire.** DESIGN.md: "they'll try burning you out". Fire out of play since #458 (Sean, 2026-10-31). Latest: no fire.
- **The mob.** DESIGN.md and the story judge: the town wants him hanged. Not in the Water Tower or C7 c. Unsettled whether a town mob has any part.

**Open questions:**
- What the Baron's men actually mean to do, and whether the game ever tells.
- What the player's levers are with one side (which outcome is "good").
- Whether Harlan has help (sworn men, Joe, the depot agent).
- Whether Cody's partners or the Colters appear at all.
- What Cody says, and when, if he lives (the script for it is not written).
- The train's hour (f15).
- If Kett is also Harlan's prisoner (arrest ending) at the same time: do the two share the jail; S48 assumes Kett first.
- Whether the old choices (take money, let him go) survive.
- The judge's three open points (a poor cut tipping it wrong; real axe strokes; what the groups do on meeting: moot with one side).

---

### The Store Robbery (`store-robbery`)

**Where it sits:** Act I, open part, "Law work … Any time (P)" [`OUTLINE`]. ROADMAP 3.6: one of "Three rough
missions" [P]. Story judge's suggested order: second, right after the opening, "the first small law job,
introducing the Colters" [P]. `BUILD_ORDER` proposes it becomes a side mission later. **Not built as a
mission.** Exists in part: the escalation ladder, deeds, opinions, witnesses, `OutlawBrain`, arrest (#128);
the general store lot in `config/valley.json`.

**In one line:** The gang leans on the storekeeper for money, goods or a favour, and Harlan can pay, talk,
threaten, fight or arrest.

**Harlan walks in with:** not stated in any source. By its place (once he has the badge): the badge and the
sheriff's revolver [D for those two generally]. Everything else: not stated.

**How he hears of it:** "During regular town life ... Player may arrive early, midway or after." [P, Prompt 12, via card]

**Beats, in order:**
1. During ordinary town life, a gang member or small gang presses the storekeeper for money, goods or a favour. [P, Prompt 12]
2. The player may arrive early, midway or after. [P, Prompt 12]
3. He can pay, talk, threaten, fight or arrest. [P, ROADMAP 3.6]
4. No further beats written. [none found]

**Choices, and what each sets:** "Player choices produce outcomes affecting service, inventory/finances
where available, relationships, law/witness reports and gang plans." [P, Prompt 12]

**Endings, and what it leaves in the world:**
- "**A — peaceful de-escalation** with no gunshot; **B — violent intervention** with injury and surviving witnesses; **C — nonintervention/escape** with theft or intimidation completed. Add a fourth outcome where player aids robbery if systems already support it." [P, Prompt 12]
- "Surviving gang members may remember what happened". "Success: a player can tell a story about what happened without the game imposing one canonical outcome." [P, Prompt 12]
- An arrest feeds the jail [P, `MAP`].

**Who is in it:** the storekeeper; a gang member or small gang (the Colters by `MAP` T6 and the story
judge; P); Harlan.

**Sean's own words:** none found. (The sources are ROADMAP 3.6 and the frozen prompt library; the card does
not attribute any words to Sean.)

**Lines of dialogue anyone gave:** none for this mission. The storekeeper's only line is for Payday Night:
"One handsaw, to a man I never saw before. It's in the book. Everything's in the book." (bible, `VOICES`).

**Pays off from earlier / plants for later:**
- Plants (P): "The Colters met as a separate outfit" [`OUTLINE`]; "introducing the Colters" [story judge]. The Colters are later hired for the widow's farm (C5 b, D).
- The storekeeper's day-book (S-plant for Payday Night, shown to Sean and not changed) makes the storekeeper a known face first, if this comes first [my note of the link; no source states it].

**Every other idea found:**
- "Store robbery from Prompt 12, now driven by a gang goal rather than a special mission trigger." "LATER — only after a complete vertical slice" [P, Prompt 18].
- "NPCs have plausible independent motives and know only what they perceive." [P, Prompt 12]
- "Each has more than one way through." [P, ROADMAP 3.6]
- "owners care about their things first (the storekeeper's window)" [P, showcase].
- `DESIGN.md` §9: "The gang starts trouble on its own (pushing the storekeeper around, a robbery, burning someone…" [older, D-era design text].
- `DESIGN.md` town-as-life-support: "Burn the store and there's no ammunition, oil, rope or food" [older].
- Needs: gang brains that threaten, bargain, steal, flee, surrender (partly); money and the store's stock (stock new); gang plans as data (new) [P, card].
- Story judge: "STRENGTHENS | Cheap early law work that introduces the Colters." Also: "The law work exists as cards (`hold-him`, `the-bounty`, `store-robbery`, `railhead-lynching`) but none is in the working order. After No Justice Harlan is a rescuer and an action hero, not a lawman".
- `BUILD_ORDER` question to Sean: ROADMAP 3.6's three rough missions (the saloon table, the store robbery, a bounty) → the opening in story order, "with the store robbery and the bounty as side missions later. Keep 3.6 as written, or…" [O].
- `README`: not in Sean's inventory at all: "Kept, or dropped?" [O].
- The prompt library is frozen "until Sean names one" (`CLAUDE.md`).

**Where the sources disagree:** None found on the mission itself. Who "the gang" is: `MAP` and the story
judge say the Colters; since 2026-11-11 the Colters are "a separate outlaw family who sometimes cross the
Baron and sometimes work for him" (D), and the Baron's own hired guns are Kett's crew. No source says which
outfit robs the store.

**Open questions:** Kept or dropped (`README`). Which gang. When (the Colters are hired for the farm after
the cabin, C5 b: does the store come before that). Whether the player can aid the robbery.

---

### The Bounty (`the-bounty`)

**Where it sits:** Act I, open part, "Law work … Any time (P)". Repeatable [`README`]. ROADMAP 3.6 [P].
**Not built as a mission.** Exists: a man holed up (`HouseDefence`, posts, climbing), falls from height
(#759, `Falls`, done), surrender and arrest (partly), `abandoned_homestead` / `burned_homestead` as places
[P, `valley.json`]. Wanted posters: not built.

**In one line:** A wanted man from the posters is camped or holed up outside town; bring him in alive for
more money, or dead.

**Harlan walks in with:** not stated. By its place: badge, the sheriff's revolver. A horse is assumed for
"bringing him in (on a horse)" [P, card]. Everything else: not stated.

**How he hears of it:** "the wanted posters" [D, `DESIGN.md` "Reasons to fight", Sean 2026-10-01].

**Beats, in order:**
1. Harlan sees a wanted poster. [D, `DESIGN.md`]
2. The wanted man is "camped outside town" [P, ROADMAP 3.6] or "holed up in an abandoned house on a hill" [P, #736 C].
3. Harlan takes him dead or alive; alive pays more. [D, `DESIGN.md`]
4. "Choosing not to fight is always allowed. Talking, paying, sneaking past or walking away are all real choices". [P on this card; D on `small-fights`, #736 C]
5. No further beats written. [none found]

**Choices, and what each sets:** alive (harder, pays more) or dead [D]. Nothing else named.

**Endings, and what it leaves in the world:** "they're remembered, there are witnesses and the law hears
about it, and the dead stay dead." [P, #736]. An arrest feeds the jail [P, `MAP`]. Money for the bounty [partly].

**Who is in it:** a wanted man; Harlan. Candidates for who he is: Gang A's men if they ran with the payroll
(`hell-on-wheels` v2: "on wanted posters (`the-bounty`)", D v2 per `DECISIONS` `gang_a.fate`); "an escaped
Hell on Wheels robber" (story judge, P).

**Sean's own words:**
- `DESIGN.md` "Reasons to fight" (Sean 2026-10-01, D): "bounties from the wanted posters (alive pays more, so arrests are rewarded over killing)".
- `DESIGN.md` §10 (the law): "(Sean's policing background is a design advantage here — clean arrests and use of force should be rewarded over a body count.)" (design text, not a quote).
- Inventory 2026-11-09, Part 2 ("Brainstorm"): "18. Bring Him In Breathing: A law-enforcement mission focused on capturing a dangerous suspect alive rather than killing him."
- #736 (2026-11-09) is titled "(Sean, decided)" but item C's wording is "a session's list": "**A wanted man holed up** in an abandoned house on a hill. Take the bounty dead or alive."

**Lines of dialogue anyone gave:** none found.

**Pays off from earlier / plants for later:** Pays off `gang_a.fate = fled with the money` (wanted posters)
[P/D v2]. Plants prisoners for the jail [P]. C6 c (not picked) gave Cody's arrest "the Bounty's shape".

**Every other idea found:**
- Other name: "A wanted man holed up" (#736 C); "Bring Him In Breathing" (inventory).
- Where: `abandoned_homestead` (-860, 330) [P]; #736 B's abandoned houses on hills, not placed [P].
- "Falls from height through roofs (#736 D)" as part of the fight [P; falls built since, #759].
- Wanted posters "with a likeness good enough to be recognised" (`DESIGN.md` §10); "wanted posters that describe a man (scar, horse, hat) with no photograph" (period details, Sean 2026-10-06, "ideas only"); "scars and missing fingers go on wanted posters as identifying features" (§7); the photographer's "wanted poster with your actual face" (§11) [P/older].
- "bounty hunters after you if you're wanted"; "bounty hunters arrive on the stage" [`DESIGN.md`, older: the player as the wanted man].
- "Hired gun — bounties, guarding shipments…" as a way of life [`DESIGN.md` §6].
- "10–15 base outlaws for camps and bounties outside town" [`DESIGN.md` §11 cast].
- Story judge: "EXTENDS | Repeatable law work; strengthens only if the wanted man is an escaped Hell on Wheels robber."
- `MAP`: threads "OPEN: none named (the badge, money)".
- Farmhouse judge: the farmhouse "Overlaps with the Baron's house, the Bounty, the Night Meeting".

**Where the sources disagree:** camped outside town (ROADMAP) vs holed up in a house on a hill (#736). Unsettled.

**Open questions:** Who the wanted man is. Who pays, and how much. Where. Whether it is one mission or a
repeating kind. Whether it is kept (`BUILD_ORDER`'s question on 3.6).

---

### Small Fights Out in the Valley (`small-fights`)

**Where it sits:** Any time; repeatable; "by design 'nothing to do with the story'" [story judge]. #736's
order: places first (B), then falls through roofs (D), then the fights (C), "after the greybox G-steps"
[D, #736 "Sean, decided", card]. **The fights are not built.** Built: falls from height (#759, `Falls`,
`config/falls.tres`); the hideout as No Justice's (`no_justice_hideout.gd`); `HouseDefence`; bodies that
stay (#562). #736's places are in `config/valley.json` as PROPOSED.

**In one line:** A family of small, repeatable fights out in the valley (road agents, claim jumpers,
rustlers, horse thieves, a feud, a drunk who draws, outlaw camps) at places with height, with no tie to the story.

**Harlan walks in with:** not stated.

**How he hears of it:** "Fights that happen out in the world and refill over days, with a few fixed spots
and a few roaming" [P, #736 C]. He rides into them or hears of them; "no source says how in detail" [card].

**Beats, in order:** none written as beats. The list of situations [P, #736 C]:
1. "**Road agents** holding up a wagon or a rider on the road."
2. "**Claim jumpers** at the prospector's diggings."
3. "**Rustlers** driving the Baron's cattle. You pick a side, or none."
4. "**A wanted man holed up** in an abandoned house on a hill." (carded as `the-bounty`)
5. "**Horse thieves at night.**"
6. "**A feud** between two homesteads."
7. "**A drunk who goes for his gun** outside a saloon."
8. "**Outlaws camped** at the hideout and in the wilderness spots."

**Choices, and what each sets:** "Choosing not to fight is always allowed. Talking, paying, sneaking past
or walking away are all real choices (immersive sim)." [D, #736 C per card]. Rustlers: "You pick a side, or
none." [P]. "most standoffs should have a way out that isn't shooting." [D, `DESIGN.md`]

**Endings, and what it leaves in the world:** "The people involved belong to the living world (#695/#663):
they're remembered, there are witnesses and the law hears about it, and the dead stay dead." [D, #736 C per
card]. "The town remembers, the land doesn't." (the fights refill) [P, #463, Sean 2026-10-28].

**Who is in it:** road agents, claim jumpers, rustlers, horse thieves, two feuding homesteads, a drunk,
camped outlaws [P]. `MAP`: "Outlaws of the valley"; also lists the Colter gang against `small-fights`.

**Sean's own words:**
- "we need more to do and go - more small fights - maybe a few more abandoned houses on hills and stuff - fights that have nothing to do with the story - places of elevation where you can shoot someone and watch them fall from height through roofs" (2026-11-09, #736, card).
- "The town remembers, the land doesn't." (2026-10-28, #463 comment, as the card attributes it).
- `DESIGN.md` "Reasons to fight" (Sean 2026-10-01): "The street: call-outs and duels (built), drunks who draw, bar fights that escalate, men you wronged coming back, bounty hunters after you if you're wanted."; "claim jumpers", "night riders at your own spring", "clearing the gang's hideout or the mine"; "most standoffs should have a way out that isn't shooting."; "Every fight should come out of the story or the world".
- `DESIGN.md`: "No shooting animals (Sean: "I hate games where you shoot animals")".
- #736 as quoted on the card under "Sean, decided" (whose wording not stated): "**B (the places) first** ... **Then D** (falls through roofs in the building lab). **Then C** (the fights)", "after the greybox G-steps"; "Each one gives a shooter above and a target below, or the reverse." "**enemies use high ground.** A man on a roof or a ridge has the advantage until you flank him."; "approved with the map".

**Lines of dialogue anyone gave:** none found.

**Pays off from earlier / plants for later:** none stated ("nothing to do with the story"). Rustlers touch
the Baron [card]. A spring or stock tank in the west "the Baron wants it" [#736 A].

**Every other idea found:**
- #463 (Sean 2026-10-28, per card): outlaw camps and hideouts; abandoned buildings (a mining office, a burned homestead, a ruined stage station); rustlers at a line camp, a whiskey trader's cabin, a gang's powder store; road ambushes [P].
- #736 B places, "about 12–15 to start" [P]: abandoned houses on hills (two or three), a line shack on a ridge above the Baron's range, a rock outcrop above the wagon road, a bluff over the creek, the depot water tower, the mine headframe and ore chute, a windmill, the church bell tower, a ruined adobe mission or stage station, a sheer drop into the canyon near the trestle.
- #736 A ("approved with the map", D per card): a landmark butte; the rough southern rimrock trail; a spring or stock tank in the west; the west half filled.
- `valley.json` places: `hideout` (-450, 2020), `abandoned_homestead`, `prospect_shack` (-1560, -1150), `rock_camp`, `mesa_overlook` [P/D as marked there].
- Needs: a ragdoll that breaks roofs it lands on (new); enemies who climb, hold high ground and flank (partly); encounters that refill over days, roaming groups (new, Prompt 18); cattle (#728: cows "may be made", O) [card].
- Story judge: "EXTENDS | By design 'nothing to do with the story'; useful filler." Hell on Wheels' judge: Gang B's opening fight "repeats the small fights".
- The hideout is now No Justice's ("the end of Kett's crew", C5 b): whether "outlaws camped at the hideout" still refills there is not stated.
- Inventory Part 3 older names possibly of this family: "The Missing Ranch Hand", "Dead Man's Crossing", "Blood on Main Street", "The Cattle War" [not canon].

**Where the sources disagree:**
- The mine headframe (#736, #463) vs "a hoist-less adit mine (no head frame needed)" (`valley.json`). Unsettled.
- Rustlers drive "the Baron's cattle" (#736) vs cattle not in the game (#728, #700: O). Unsettled.
- Sean 2026-10-01: "Every fight should come out of the story or the world" vs Sean 2026-11-09: "fights that have nothing to do with the story". Later word: fights from the world are wanted; they need no story tie.
- Sean 2026-11-17 (this session): "it's a story to tell, not a bunch of disjointed missions": said of the story missions; whether it narrows these is not said.

**Open questions:** How the player hears of each. Which are fixed and which roam. What refills and how fast.
Whether cattle exist. Whether any of these men are the Colters.

---

### The Stage Held Up (`stage-held-up`)

**Where it sits:** Any time; repeatable [`README`; `OUTLINE` "Law work"]. **Not built as a mission.** Built
nearby: the coach for the Baron's Shipment (`src/missions/coach_drive.gd`, `coach_fight.gd`, `coach_cut.gd`),
which the card says it would share ("A stagecoach and team as moving rigid bodies: new (shared with
`barons-shipment`'s coach)"). No stage, no stage road.

**In one line:** The stage is robbed on the road; Harlan can be aboard riding shotgun, ride after the
robbers, rob it himself, or only see it limp into town.

**Harlan walks in with:** not stated.

**How he hears of it:** "the town's reaction when it limps in" (the news comes with the stage) [P, backlog 6];
or he is aboard, "riding shotgun on the stage" [P, `DESIGN.md` "Honest work"].

**Beats, in order:** none written. What exists:
1. The stage is robbed on the road. [D as a reason to fight, Sean 2026-10-01]
2. It limps into town and the town reacts. [P, backlog 6, 2026-10-06]

**Choices, and what each sets:** defend it (riding shotgun), rob it yourself, or ride after the robbers
[P, card]. Robbing it in a disguise that may not hold [P, showcase "Recognition"].

**Endings, and what it leaves in the world:** "the town's reaction when it limps in" [P]. "Witnesses store
a description, not an identity flag" [P, `DESIGN.md` §10].

**Who is in it:** the driver; robbers (none named; `MAP` T6 lists it under the Colters' jobs, P); passengers
not stated.

**Sean's own words:**
- `DESIGN.md` "Reasons to fight" (Sean 2026-10-01, D): "the stage robbed on the road"; "guarding the stage or the money shipment".
- `DESIGN.md` backlog 6 (2026-10-06, P): "**The stage held up** on the road, and the town's reaction when it limps in."
- Three-gunmen brief (Sean 2026-10-17, "provisional", per card): "Mission 2 — Dead Man's Crossing: A roadside wagon ambush testing outdoor ballistics, destructible cover, positioning, flanking, and NPC survival behavior."
- #542 (Sean 2026-11-01, per card): "the payroll comes on the train".
- Inventory 2026-11-09 Part 3 (older, "not canon"): "Dead Man's Crossing | Wagon ambush showcasing tactical combat"; "Runaway Coach | Out-of-control horse-drawn coach"; early pitch "The Missing Stagecoach".

**Lines of dialogue anyone gave:** none. Showcase "Recognition" (a situation, not a line): "You robbed the
stage in a bandana yesterday; today the driver is in the saloon, staring at your coat".

**Pays off from earlier / plants for later:** none stated. `MAP` T6 → `hold-him` (an arrest) [P].

**Every other idea found:**
- "A payroll worth robbing on the road is a ready-made mission." [P, #276 comment, 2026-10-22]
- "Dead Man's Crossing" may be this mission or `small-fights`' road agents [O, card].
- Where: no stage road named in `valley.json`; the East Road to `east_exit` (2400, -680, toward Durango); #736 B's "rock outcrop above the wagon road" ("the ambush spot, which works both ways") [O/P, card].
- The stage on the town's calendar: "stage and mail day (strangers, letters, news)"; "letters go by stage over days"; "bounty hunters arrive on the stage"; the Kid got out on the stage (`kid-wants-out`); the circuit judge's arrival [`DESIGN.md`, `MAP`; partly, #276].
- Needs: horses that bolt, traces (new); disguise and recognition by description (new); outdoor ballistics, cover, flanking (exists) [card].
- Period word: the verb "to hold up" a stage is given as 1887 ("The term is new", Farmer 1889): say "stop the stage", "rob"; "a hold-up" (noun) is fine [`WORDS`]. So the title itself is out of period as speech.
- Shipment's judge: the coach hold-up "overlaps with The Stage Held Up and The Bank Break-in".
- Story judge: "EXTENDS | Repeatable."
- `README`: not in Sean's inventory: "Kept, or dropped?" [O].

**Where the sources disagree:**
- Whether the payroll comes by stage (#276, 2026-10-22) or by train (#542, Sean 2026-11-01). Later word: the train (Hell on Wheels). So the stage's cargo is unsettled.
- Whether Dead Man's Crossing is this mission. Unsettled.

**Open questions:** Who robs it. What it carries. Where. Whether Harlan as deputy can still rob it (the gang
path is older DESIGN §6). Kept or dropped.

---

### Dig Him Up (`dig-him-up`)

**Where it sits:** "Beside the main line"; not placed by Sean [`OUTLINE`]. It reads `sheriff.care`, so "any
time after Step 1" [P, `BUILD_ORDER`]; it must come after the funeral, since the grave is the sheriff's.
**Not built as a mission.** Built: the sheriff's last word in the fading branch, "...boot."
(`config/moments/sheriff_dies.json` `last.fading`; `scripts/…` `day2.boot`, "S33 is P, not picked: keep or
cut"); the funeral and the grave (`src/missions/funeral.gd`); digging earth (`Ground` take/put); the
cemetery place (`valley.json`).

**In one line:** At night, by stealth, Harlan digs up the sheriff's grave to find something hidden on the
body where nobody would have looked first, perhaps in his boot.

**Harlan walks in with:** not stated. (A shovel and a lantern are implied by the card's systems: "a lantern
you carry that gives you away". No source says where he gets them.)

**How he hears of it:** O on the card: "no source says". P (session, not picked; S33): the sheriff's last
word on day 2, "...boot", if day 1 went badly.

**Beats, in order:**
1. Something is hidden on the sheriff's body where no one would have looked first. [D, Sean 2026-11-09: "Yeah soemthing with the sheriff but it needs to be hidden where no one would have looked first? His boot?"]
2. It may be in his boot. [P, Sean's question, same words]
3. The lead: dying badly cared for, the sheriff says only "...boot." [P, session, not picked; built line]
4. Harlan goes to the cemetery at night and digs, unseen. [D, Sean 2026-11-09: "an interesting mission with sneaking"]
5. He finds it. What it is: O. [s9]
6. No further beats written. [none found]

**Choices, and what each sets:** none named. "Digging up a man in 1882 is a crime and a scandal; who finds
out is the cost." [card, O]

**Endings, and what it leaves in the world:** none named [O]. "The town learning a grave was opened
(witnesses, a disturbed grave as a trace): partly" [card, systems].

**Who is in it:** Harlan; the dead sheriff. Whoever watches the churchyard: "a sexton, the preacher, the
Baron's man" [P, card]. "who mustn't know (the widow, the preacher, the Baron's men, the town)" [O].

**Sean's own words:**
- "Let's keep dig him up - maybe there's something else we can find on him - i think it would just be an interesting mission with sneaking" (2026-11-09, card and `payday-inquest` card).
- "Yeah soemthing with the sheriff but it needs to be hidden where no one would have looked first? His boot?" (2026-11-09, card).
- "we aren't pulling bullets out to examine that idea isn't happening" (2026-11-09, on No Law, card).
- Inventory 2026-11-09, Part 2 ("Proposed"): "16. Dig Him Up: An exhumation reveals evidence that changes the understanding of a previous murder. Could connect to the inquest."
- Inventory: "I think Payday Night, The Inquest, The Wrong Ball and Dig Him Up are worth reviewing together because they may form a single connected story arc rather than four independent missions."
- Inventory, "Other proposed set pieces": "Grave digging: Recover a body or buried evidence."
- `DESIGN.md` §11, parked (Sean, 2026-10-05: "eventually"): "**a shovel that digs real dirt, and treasure to find.**" … "graves you can dig up, with the town's opinion of that."
- Sean, 2026-11-09 (quoted in `CONTRADICTIONS` Part A 1): "only the mission idea is decided, not what the papers are" (about the Baron's papers; bears on what a find could be).

**Lines of dialogue anyone gave:**
- Sheriff: "...boot." (built, `sheriff_dies.json`; script `day2.boot`: "A word that means something to him and nothing yet to you.").
- Undertaker (script, new; about Earl, not the sheriff): "He had on him a deck of cards, a pocket knife and sixty cents."; the bible's example of his exactness: "a deck of cards and one boot" (`DIALOGUE`).

**Pays off from earlier / plants for later:**
- Pays off: `sheriff.care` (the lead is plain or half-said, P, `DECISIONS`); S33 "The boot" (P, not picked); S32 "Graves" ("Also plants Dig Him Up").
- Plants: maybe evidence for the ending, "whether Dig Him Up's find counts (s9)" [O]. The doctor "heard the sheriff's marks … and whatever is in the boot" (`VOICES`, the doctor's sheet, P·bible).

**Every other idea found:**
- Why it's there: "the sheriff hid it when he knew he was in danger, so the red shirt, searching his coat and pockets on the road, missed it; the doctor and the undertaker buried him in his boots ('died with his boots on')." [P, session, not picked; the red-shirt part is out since C16 (D, Sean 2026-11-13): the red shirt did not shoot the sheriff]
- What it is, an example: "the Baron's written offer for his water right, with the sheriff's note of who brought it" [P, earlier session; s9].
- "well cared for, he can say it plainly; badly cared for, only '...boot'" [P, session, not picked]. f18 [P·bible]: said plainly, "His wife is in the room, and then the boot would come off before he's buried", so "The grave is only for the fading branch".
- Whose grave, older candidates (replaced by Sean's "soemthing with the sheriff"): the card cheat ("a recorded death, burial"), the red shirt if he died, a man killed in the Baron's service [Superseded].
- Other ways than sneaking: "asking the family's leave, the undertaker, a bribe" [O, card].
- Story judge: "DROP for now | Its only job is evidence." [Superseded by Sean's "Let's keep dig him up"]
- The Inquest and the Wrong Ball, its old companions: the story judge said park the Inquest with the trial's maybe, drop the Wrong Ball; "Sean hasn't answered them" [`payday-inquest` card]. No ball is examined [D, Sean 2026-11-09].
- Where: `cemetery` (-95, -195), pad y 10.5, "higher ground north-west" beside the `church` (-62, -135); viewpoint `vp_cemetery`; reached by Church Lane [D places, `valley.json`].
- Needs: a body kept in its grave over days and things on it (partly: #562, coffins #259); night, sight by light, a carried lantern (partly, `SightLight`); a watcher of the churchyard (new behaviour); "Carrying things … the boot's find" (new, `BUILD_ORDER` step 0.5; `MAP`).
- "The sheriff's grave becomes a persistent world location." "Persistent graves and obituary records." [P, `sources/no-law_draft`]
- `DESIGN.md`: "gravestones" in a readable world; "graves get…" over time [older].
- Evidence is now a real system (D, 2026-11-11), where the inventory and `STORY` had it "a maybe" [see below].

**Where the sources disagree:**
- **What it is for.** Inventory: evidence "that changes the understanding of a previous murder", tied to an inquest. Sean 2026-11-09: keep it as "an interesting mission with sneaking", "something else we can find on him". Since 2026-11-11 evidence is a real system, so whether the find counts is O (s9). Latest: a sneaking mission; the find unsettled.
- **Which care branch gives the lead.** Session: plainly if well cared for, "...boot" if badly. f18: only the fading branch can lead to a grave. Built: "...boot." is the fading branch's last word; the clear branch's is "Sun's up. Ain't that something." Unsettled (S33 itself is "P, not picked").
- **Who missed the boot.** Card: the red shirt, searching him on the road. C16: the shooter is the stranger/foreman, who "shot the sheriff once, from the saddle, and didn't get down to finish it" (D, Sean 2026-11-17, via `OUTLINE`): so nobody searched him on the road. The card's reason is out; nothing replaces it.

**Open questions:** What is in the boot (s9). Whether it is evidence. How Harlan hears, if the boot line is
cut or the sheriff was well cared for. Who guards the grave or mustn't know. What it costs if he's seen.
Whether the widow can be asked. Its place in the order.

---

## Ideas with no mission

- The stone jail's dynamite back wall ("a rubble jail wall takes about three sticks", #676; `valley.json` mission `jailbreak`, "DECIDED") has no mission now that the jail night is at the depot (C7 c). [`valley.json`; `CONTRADICTIONS` C7]
- "Pull a wall down with a horse … the jailbreak" (`DESIGN.md` §8 rope): no mission uses it now. [P]
- Kett sits "a couple of days" in Harlan's jail before the platform release (C8 a, P until Sean nods): a jail scene that belongs to No Justice, not to the jail night; no line when Kett's jailed is built (`docs/lanes/gameplay.md`: "no line when Kett's jailed (C8 a, Sean's)").
- Other missions' prisoners "fill the jail": Gang A, the men arrested on the captain's day, the farmhouse's captors. No card says what happens to them there. [f12, P·bible]
- Guns checked at the edge of town; "buffaloing" a drunk with a pistol barrel instead of shooting him; the undertaker's photographs of dead outlaws in his window; vigilance committees. [`DESIGN.md` §11 period details, Sean 2026-10-06: "ideas only … not all will be built"]
- Honest work: "deputy shifts, riding shotgun on the stage, freighting…" [`DESIGN.md` §11]. "A deputy's ordinary days." [`OUTLINE`, P]
- The story judge: "nothing says what 'temporarily' turns into" for Harlan's badge. Now: until the county names a man (D, 2026-11-17); who and when is O (s27).
- The land agent "Vale" with forged deeds, arriving by stage to settle the land claims: in `DESIGN.md`, on no card; bible: "Dropped; his deeds are the Baron's" (s18, P·bible).
- "I know you." (a Colter to Harlan, `DESIGN.md` §6): never used (M9).
- Harlan's own spring ("the best spring"): "night riders at your own spring" (`DESIGN.md`) and the Baron at the grave admiring it (S49, P·bible) have no mission (M6, s14).
- The Colters have no ending on any card (s20, M11); the store robbery and the stage are their only proposed "jobs" before the farm.
- Inventory, "Other proposed set pieces": "Water diversion", "Mine pumping", "Burning livery", "Early train encounter: Harlan travels under the small railway overpass during one or two early missions, establishing the landmark before the payroll train sequence." [`sources/inventory`]
- Inventory Part 3 names with no card here: A Quiet Drink, The Missing Ranch Hand, Blood on Main Street, The Last Telegraph, Mill of Teeth, Runaway Coach, The Night Salt Creek Burned, Stolen Creek, High Wire; early pitches The Railroad Men, The Fever, The Cattle War, The Missing Stagecoach, The Bank Is Empty, The Long Winter, The Man Who Wasn't There, The Election, The Siege of Salt Creek. "not current approved missions." [`sources/inventory`]
- Set pieces considered and not chosen: the ore bins at the Ore Works; the powder magazine; "Lamps out" (shooting out the street lamps one by one blinds the gang). [`proposals/setpieces`]
- No Law draft: "The murdered card player should receive a recorded death, burial or obituary instead of disappearing from the world." Earl's grave is one of the graves the walk reads (S32). [`sources/no-law_draft`]
- `OUTLINE` "Where Act I leaves things" still calls Kett "the sheriff's killer": stale since C16 (D, 2026-11-13).
- `STORY` and `MAP` still say Kett "shot the sheriff and killed Joe's wife": stale since C16.
- The period check on words: no "hoosegow"; "jail", "calaboose", "lock-up"; "hello" vs "howdy" is open (s28). [`WORDS`]
