# Mission ideas, the full record: %s

Part of `docs/story/MISSIONS.md` (read that first). Gathered 2026-11-17 by a reader sub-agent from every source: the mission cards on PR #743's branch, Sean's own files in `docs/missions/sources/`, the proposals, the story bible, DESIGN.md and what is built. **Nothing here is a decision unless it is marked D with Sean's date.** Not yet checked line by line by the story session; where it disagrees with `OUTLINE.md` or `CONTRADICTIONS.md`, say so in a note rather than fix it silently.


Reader 1 of 5. Nothing here is new: every line is from a source, named in brackets. Status words: **D** decided by
Sean, **P** proposed (whose is said), **P·bible** proposed by the story bible, **O** open, **Superseded**.

Short names for sources:
- `draft` = `docs/missions/sources/no-law_draft_2026-11-09.md` (Sean's No Law draft, as he sent it)
- `sean-card` = `docs/missions/sources/no-justice_sean_2026-11-09.md` (Sean's No Justice card)
- `inventory` = `docs/missions/sources/inventory_2026-11-09.md` (sent by Sean as "the tentative mission layout")
- `chatgpt` = `docs/missions/sources/chatgpt-cards_2026-11-09.md` (everything in it only PROPOSED)
- `card:<slug>` = `docs/missions/<slug>.md` on `origin/claude/planning-missions-cards-mwdo42`
- `OUTLINE`, `SETUPS`, `VOICES`, `CONTRA` = `docs/story/*.md` · `DESIGN` = `DESIGN.md`
- `script:road`, `script:nolaw`, `script:nj` = `docs/scripts/sheriff_road.json`, `no_law.json`, `no_justice.json`
- `built:<file>` = `config/moments/<file>.json` (`_doc`) and its `src/missions/*.gd`
- `this session` = Sean's six decisions of 2026-11-17 as given in this job's the reading brief
- `judged` = `docs/missions/judged/2026-11-09.md`; `judged-story` = `judged/2026-11-09_story.md`

A warning that applies to all three: the scripts (`docs/scripts/*.json`) were rewritten 2026-11-17 and are
"waiting on Sean's Script OK". So every script line marked "new" is **P** (a session's), even where it carries
out a decision of Sean's. The game's own lines (`config/moments/`) have not been changed to match
(`docs/scripts/CHANGES.md`).

---

### The Sheriff on the Road (`the-sheriff`)

**Where it sits:** Act I, first thing in the game, day 1 at dawn. Nothing comes first. **Built, rough**
(`config/moments/the_sheriff.json`, `src/missions/sheriff_on_road.gd`, `story_state.gd`, `head_gesture.gd`; issue
#746). The built mission ends at the doctor's lot, or at the freighter's card if you leave him. The script's
scenes 3 to 5 (if you left him; that evening at the doctor's; day 2) are "not built yet" as the sheriff's script
tells it [script:road notes]; day 2 is built separately as `sheriff_dies` (see No Law).

**In one line:** At dawn Harlan finds the county sheriff gut-shot on the East Road; a nod helps him, a shake leaves
him; how well he is cared for sets his last words next day.

**Harlan walks in with:**
- Gun: none. "the story's Harlan is unarmed till now" (till the revolver on day 2) [built:sheriff_dies]; D, Sean
  2026-11-17 [this session, item 2].
- Badge: none.
- Horse: not settled. DESIGN: "you ride into town at dawn" (D, 2026-10-01). Sean's maybe, 2026-11-09: "Harlan has
  no horse at the start" (P, Sean) [card:the-sheriff]. Built: he walks the ford path down from his homestead
  [built:the_sheriff].
- Dynamite: none ("dynamite is introduced in Buried Alive, not the opening") [inventory].
- Companion: none. Wounds: not stated.
- What he knows: nothing of the shooting. He is a homesteader with a spring on his claim and a former army
  hospital steward (P, DESIGN §6; "the hospital-steward past pays off in minute one", D, DESIGN §5). The sheriff
  knows him: "Harlan. You're Harlan, from up the creek." [built line].

**How he hears of it:** He doesn't; he finds him. "You find the sheriff (decided): you ride in at dawn and he's on
the road." [D, DESIGN §5, 2026-10-01]. Inventory: "Thomas Harlan wakes at his homestead. He discovers the sheriff
has been shot." [inventory, "Established story direction"].

**Beats, in order:**
1. Dawn at Harlan's homestead. [built:the_sheriff; inventory]
2. He walks the ford path down to the East Road (about 350 m). [built; P valley-plan §6; Sean's "no horse" maybe]
3. The sheriff lies gut-shot at `opening_site` (530, 128), conscious, frightened; his horse stands off the road with
   its reins down. [built; D that he's gut-shot and conscious, DESIGN §5; the horse being there was P, a session's,
   "not picked" on the card, and is now built]
4. Within 25 m the sheriff hails first: "Hold it! Who's that?" [built]
5. Within 3.5 m he asks: "...You going to help me or not?" The player answers by nodding or shaking his head.
   [built; D that it's by "head-shake controls", inventory]
6. No answer: every 14 s he asks again ("Well? Nod or don't, but don't just stand there."). [built]
7. Nod: he tells Harlan to press on the wound. Holding E presses; 6 s of it and the wound is packed and bound.
   [built]
8. Four seconds after the nod he says who shot him. The game's line now: a stranger on a bald-faced sorrel who
   called him "friend". [built, re-worded #908; D that the marks are a sorrel and "friend", Sean 2026-11-13, #906,
   C16 a; the wording P·bible]
9. Packed: "My horse is yonder. Get me up on him." E by the horse takes him in. [built]
10. The walk into town is a typed card (leading a horse isn't built); his body keeps bleeding through it. [built]
11. The doctor meets them at his lot; his first words follow the sheriff's state, then Harlan's care: "Somebody
    packed that wound, and packed it right. That's bought him some hours. Come back tonight." [built]
12. Shake, or walk 45 m off: Harlan has left him ("Harlan! HARLAN!"). A card: a freighter finds him later and hauls
    him in. [built]
13. The mission sets `sheriff.care` = good (packed, and his blood loss at the doctor's under a limit) / poor (taken
    in otherwise) / left, plus `sheriff.blood_loss`. [built]
14. That evening at the doctor's: the doctor says the sheriff will die; his wife is with him; "Go on. He'll ask for
    you in the morning." [P, script:road scene `evening`, not built; that the doctor tells him the sheriff will die
    is from inventory, "A New Sheriff"]
15. The sheriff's horse is put up at the livery ("That's the sheriff's bay... Rifle and all."). [P, script:road
    `town.livery`; no livery man and no rifle on the saddle in the game]

**Choices, and what each sets:**
- Nod (help) or shake (leave): `sheriff.care`. [built; D]
- How well: pack the wound or not, how fast: good / poor. [built; D, Sean's pick 2026-11-09, card:no-law]
- Shook his head, then helped anyway: a fact `sheriff.shook` (not in the game; "gameplay to add"). [P, script:road]

**Endings, and what it leaves in the world:**
- He dies on day 2 whatever Harlan does. "He dies whatever you do: you can get him to the doctor, but he doesn't
  survive" [D, Sean's lock 2026-11-03, PR #621 (not merged), via card:the-sheriff; VOICES: "Dies at B3 whatever
  Harlan does (D, 2026-11-03)"].
- `sheriff.care` is read on day 2 (his last words), by the widow, the doctor, the townsfolk, the stranger, the Baron
  and Joe (see No Law and No Justice). [D for the last words and the widow; the rest P, scripts and SETUPS part E]
- If left: the freighter's story ("a name. Harlan, or near it") can reach the widow later. [D that the truth can
  reach her, VOICES; wording P]
- The sheriff's horse stands at the livery. [P, card; script]

**Who is in it:** Harlan. The sheriff: the county sheriff, no name (roles only), in his fifties, fourteen years on
his claim east of town, a wife and two boys [VOICES; D C12 a, C14 c, the lock]. The doctor. The sheriff's horse.
The freighter (a card now). The livery man (P). His wife, that evening (P).

**Sean's own words:**
- "Ya!" to all the signature features, 2026-10-01, which include: "1–3 together are the game's spine: you find the
  sheriff, how well you treat him decides whether he lives, his last words depend on his blood loss, the ball in
  him is the evidence, and it all comes out at a trial" (DESIGN §11's text; Sean's word is the "Ya!").
- 2026-11-09 (chat, on card:the-sheriff): "you haven't been appointed to anything yet the first night - it's not
  until the second day".
- 2026-11-09: "we're still keeping as deputy. I don't know if we become sheriff ever in the game."
- 2026-11-09: "Yeah I'm not sold on the whole evidence and trial stuff yet - that's a maybe".
- 2026-11-09 (on No Law's saloon): "we aren't pulling bullets out to examine that idea isn't happening".
- 2026-11-09: "Yeah the name works" (the player is Thomas Harlan).
- 2026-11-09, with the inventory: "And this is the tentative mission layout".
- 2026-11-09 (BUILD_ORDER): "The opening is built in our new map and town just so we don't need to" (the quote is
  cut off in the file where I read it).
- 2026-11-13 (#830, CONTRA C16): "did we make a change to who shot the sheriff and kills joes wife? Because we
  figured that it can't be the same man as he would never be released for the murder of joes wife if he also shot
  the sheriff".
- 2026-11-13 (#906): "Yeah let's go with the stranger."
- 2026-11-17 [this session, item 5; VOICES]: the stranger is "cocky and arrogant … but also a coward - that's why the
  sheriff was only shot in the gut and not finished off"; "probably a mid game reveal although I'm sure people will
  be guessing it right away".
- Sean's notes on the script page, 2026-11-13 (voice direction, kept in script:road): "The who gets dragged on too
  long / and it's too quiet."; "All too whisper-like."; "Too much whisper."; "It needs more exasperation; it comes
  off read as one line."; "Switch the end where he says bleeding: his voice goes up, it should be matter of fact.";
  "It needs to be a forceful direction, almost mad."; "None of these worked."; "Sounds like just a whisper.";
  "Nothing here"; "The delivery sounds happy."

**Lines of dialogue anyone gave:** (built = in the game; new = the 2026-11-17 script, P)
- Sheriff, hail: "Hold it! Who's that?" / "Keep your hands where I can see 'em." (built; the second never plays) ·
  weak: "Who's there? Don't... don't come closer." · fading: "Who... who is that?" (built)
- Sheriff, ask: "Harlan. You're Harlan, from up the creek. I'm gut-shot. I need the doc. You going to help me or
  not?" · "I'm shot. In the belly. Get me to the doc... will you?" · "Doc... get me to the doc." (built)
- Ask again: "Well? Nod or don't, but don't just stand there." (built) · "Yes or no, Harlan." / "You deaf, man?
  Help me or get on." (new) · "Please." (built) · "Harlan... please." (new)
- Nod: built "Thank God. Press on it. Hard. It won't quit bleeding." → new "Thank God. It won't quit bleeding. Press
  on it. Hard." · built "Press on it... hard." → new "Press on it. Hard, damn it." · "...hurts." (built)
- Who shot him: first built "Man in a faded red shirt. Rode up easy, like he wanted directions. Then he shot me."
  (Superseded 2026-11-13) → in the game since #908 "Stranger on a bald-faced sorrel. Rode up easy, like he wanted
  directions. Called me friend. Then he shot me." → script new "Stranger on a bald-faced sorrel. Rode up easy.
  Called me friend and shot me." · weak: "Red shirt. Faded red. Rode up like a friend." (Superseded) → "Bald-faced
  sorrel. Rode up like a friend." → new "Sorrel horse. White face. Called me friend." · fading: "...red..."
  (Superseded) → "...friend..." → new "Friend. He said friend."
- Shake: "You'd leave a man in the road? Then go on. Damn you." (built) / "Go on, then. Go on home." (new) ·
  "Don't... don't leave me here." (built)
- Press: "Christ! That's it. Keep on it." (built) · "...that's it." (built) → "There. Hold it there." (new)
- Packed: "That'll hold. My horse is yonder. Get me up on him." · "My horse..." (built)
- Idle: "Damn, it burns." / "Sun's coming up. Ain't that something." / "Don't you let me lie here." / "I'm cold." /
  "Don't let me lie here." (built) · "I know every rut in this road." / "Winchester's right there on my saddle.
  Never put a hand to it." / "My wife's got bread rising." / "Stay where I can see you." (new)
- Walked off: "Harlan! HARLAN!" · "Harlan..." (built)
- Doctor at his lot: "Gut-shot. Help me get him up the steps." · "He's bled a fair bit. Up the steps with him,
  quick now." · "Lord. He's near bled white. Get him inside." · "He's out cold. Help me with him. Now." (built) →
  "He's insensible. Help me with him. Now." (new)
- Doctor after: "Somebody packed that wound, and packed it right. That's bought him some hours. Come back tonight."
  · "He's lost more than he can spare. I'll do what I can. It may not be much." (built) · "You've packed a wound
  before. Where? ..." (new) · VOICES' version: "You've done this before. Where? ... No. Keep it." (P·bible)
- Livery (new): "That's the sheriff's bay. ... There's blood on this saddle." / "I'll put him up. Rifle and all." /
  "He's fed here, whoever pays."
- Freighter (new): "He was just lying in the road. I near drove over him. I thought it was a sack." / "He kept on
  about a sorrel horse. A sorrel, and 'friend', over and over. And a name. Harlan, or near it." (was: "...Talked
  about a red shirt the whole way in." / "Red shirt, he kept saying. Red shirt, and a name. Harlan, or near it.",
  Superseded)
- Doctor, if left (new): "A freighter brought him in at ten. He'd lain out there three hours, by the blood. He's
  going."
- Doctor, that evening (new): "The ball's in the bowel. I can't get at it, and it would make no difference if I
  could. He'll not see another night." · "He's sinking. I've given him morphia. Tomorrow, I'd say." · "One ball,
  and low. Fired from a horse, by the line of it. Whoever it was didn't get down to make sure." · "His wife's with
  him. There's nothing here for you tonight." / "Go on. He'll ask for you in the morning."
- The foreman, at the shooting, heard by nobody alive but him (P·bible, VOICES): "Morning, Sheriff. Am I right for
  the ford, friend?"

**Pays off from earlier / plants for later:**
- Plants S40, "friend" and the bald-faced sorrel: paid on night one at the saloon's rail and "Don't move, friend."
  [D that the stranger is the shooter; marks and places P·bible, SETUPS S40]
- Plants S5, Harlan is a steward (the packed wound; the doctor's line): paid in Hell on Wheels, Payday Night.
  [D, SETUPS S5]
- Plants S13 the sheriff's horse and S14 his rifle on it: the horse goes home in `widows-place`; the widow gives
  the rifle; the rifle cuts Joe's rope. [S13 D; the rifle on the saddle on day 1 is P]
- Plants S38, Harlan served under Rourke (the doctor's "Where?"). [D that it's real and planted early, C15 a; the
  place P·bible]
- Plants S42 "My wife's got bread rising." (pays at the widow's kitchen) and S18 "the place on the road". [P·bible]
- Plants S51, "he didn't get down": the doctor's "One ball, and low...". [D that he's a coward and held back; the
  plant P·bible]
- `sheriff.care` feeds day 2's last words (D), `farmhouse-rescue` and `dig-him-up` [card DECISIONS.md].

**Every other idea found:**
- "He might tell you, pin his badge on you, be saved by the doctor, or die while you're elsewhere — and the town
  goes looking for someone to blame." [DESIGN §5 premise; "be saved" Superseded by the lock: he dies]
- "how well you treat him decides whether he lives" [D 2026-10-01, DESIGN §11; Superseded by the lock 2026-11-03,
  though the card still lists it O]
- "He's conscious, knows who shot him, is frightened and unsure who to trust." [D, DESIGN §5; "knows who shot him"
  now reads: he knows a horse and a word, not a name, CONTRA f17, P·bible]
- "The ball in him is the evidence"; "the ball the doctor digs out may match the stranger's gun, or clear him."
  [DESIGN §11 D 2026-10-01; DESIGN "Story shape" P, Sean 2026-10-15; Superseded/maybe: "we aren't pulling bullets
  out", Sean 2026-11-09]
- "The doctor's table: You carry the sheriff in; the doctor probes for the ball while you hold the lamp; the ball
  matches a gun you've seen." [P, showcase-moments]
- "The gut shot who talks: Dying slowly: get him to the doctor, or let him say where the money is first." [P,
  showcase-moments]
- "The doctor — knows more about the sheriff's wound than he says." [DESIGN cast; since C12 a he is the coroner and
  what he keeps back is O, s19]
- "He was murdered over his family's land and its water rights, and he dies of it; Harlan gets his revolver." [D,
  the lock 2026-11-03]
- "Whatever happens, by day 3 the town has no law, the Colters are in town, and everyone wants to know what you
  saw." [D, DESIGN §5 2026-10-01; out of date, CONTRA f17]
- "Saving him teaches first aid under pressure." [D, DESIGN §5]
- "he can bring him to the doctor", about 480 m. [`config/valley.json`, via card]
- Treat him on the road (what he can say) or carry him to the doctor (time). [P, card]
- "The player decides whether to help transport him to the doctor or leave him, using head-shake controls."
  "Introduces the player to Salt Creek, its people and the consequences of decisions." [inventory]
- The sheriff's horse carries him in, led, "a man led on a horse, not dragged"; the saddle and rifle still on it;
  Harlan rides it out to the widow later and she gives it to him with the rifle. [P, a session, card; "maybe the
  horse" is Sean's maybe]
- Why Harlan has no horse: sold for the claim, lame, or new to the valley. [O, card]
- The dying sheriff's last word "...boot", if day 1 went badly; pays in `dig-him-up`; what's in the boot is O (an
  earlier session: the Baron's written offer with the sheriff's note on it). [P, not picked, SETUPS S33; s9]
- Why the stranger was sent: new to the valley this season, the one face the sheriff didn't know. [P·bible, C16 a]
- Other answers to "who shot him" that were offered and not picked: Cody (C16 b); the Kid (C16 c). [CONTRA C16]
- The red shirt (Kett) shot the sheriff. [D 2026-11-09, picked from the story judge; Superseded, Sean 2026-11-13]
- "a well-tended sheriff's clear last words can name him, or name the water" [P, judged-story idea 1]
- The demo is "the prologue and day 1". [P, ROADMAP via card]
- "These first three are currently story beats. They could become one larger opening mission rather than three
  separate missions." [inventory]
- "The game says a beat's wordings in order and repeats the last: once there are takes, the idle and ask-again
  lines should cycle instead." [script:road notes]
- Stand-ins in the build: the Studio's `sean_s3` as the sheriff, `doctor_s2`, typed lines, no rifle on the saddle.
  [sheriff_on_road.gd]

**Where the sources disagree:**
- Does Harlan ride or walk? DESIGN (2026-10-01): "you ride into town at dawn". Valley plan: his dawn ride by the
  ford. Sean's maybe (2026-11-09): no horse, on foot. Built: on foot. Latest word favours on foot, but it is still
  only Sean's "maybe". Unsettled.
- Can he live? DESIGN spine: care "decides whether he lives". The lock (2026-11-03): he dies whatever you do. Every
  later source and the build have him die on day 2. Latest favours: he dies.
- Who shot him: the red shirt (D 2026-11-09) → not Kett (D 2026-11-13) → the stranger at the table, the Baron's
  foreman (D 2026-11-13, #906). Latest: the foreman.
- Does the sheriff know who shot him? DESIGN: "knows who shot him". Bible: a stranger he took for a traveller; he
  knows a horse and a word. Latest favours the bible (it follows from Sean's pick).
- Is the ball evidence? DESIGN: yes. Sean 2026-11-09: no bullets pulled, and evidence/trial "a maybe". Bible
  (2026-11-11): evidence is a system, but "not a ball". Latest: no ball.
- Is he the town's sheriff? Sources say "sheriff" loosely; D C12 a: the county sheriff, the seat down the line.

**Open questions:**
- Horse or no horse at the start, and why. [O]
- The rifle on his saddle on day 1 (S14's first plant). [P]
- Whether "...boot" is kept. [P, not picked]
- Whether the evening visit to the doctor is a real beat, and whether the doctor then sends him to the saloon. [P]
- `sheriff.shook` fact. [P]
- What the doctor keeps back about the wound. [O, s19]

---

### No Law (`no-law`)

Other names: "the saloon table" (DESIGN §5 prologue), "the card cheat" (showcase moments), "The Saloon Shooting"
and "A New Sheriff" (inventory), "A Quiet Drink" (Sean's brief 2026-10-17, provisional; O whether the same).

**Where it sits:** Act I. After the sheriff on the road: night 1 (the saloon, the carry), the morning after, day 2
at the doctor's (the death, the badge, the revolver), then the funeral. Built in part:
- The murder: `config/moments/no_law_murder.json`, `src/moments/no_law_murder.gd` (#773), with `ValleyFolk`,
  `PlayerSeat`, `CardGame`.
- Day 2: `config/moments/sheriff_dies.json`, `src/missions/sheriff_dies.gd` (#796).
- The funeral: `config/moments/funeral.json`, `src/missions/funeral.gd` (#868).
- **Not built:** the stranger's invitation, the drink and the minute's talk; his question; Earl surviving the shot;
  the carry to the doctor's (#1057); the body in the doctor's front room; the town's evening and morning talk as
  the script has it; "deputy only for now" in the sheriff's mouth. [script:nolaw; CHANGES.md]

**In one line:** With the sheriff dying and no law in town, an unarmed Harlan sits with a stranger while Cody
murders a card player; next day the sheriff swears Harlan in as deputy, gives him his revolver and dies; then the
funeral, where the Baron offers to buy the widow's claim.

**Harlan walks in with:**
- Gun: **none on night one.** D, Sean 2026-11-17: he gets the sheriff's revolver on day 2, and "that is what
  prevents a shoot-out in the saloon" [this session, item 2]. Also Sean 2026-11-09: "has no gun yet so he can't do
  anything at all"; draft: "Harlan, still unarmed".
- Badge: none on night one. "you haven't been appointed to anything yet the first night" (D, Sean 2026-11-09).
  Pinned on day 2.
- Horse: not stated (see the sheriff's card; the sheriff's horse is at the livery, P).
- Dynamite: none. Companion: none.
- Wounds: none stated. After the carry: Earl's blood on his coat (D that it's there next morning, Sean 2026-11-17,
  via script notes; the lines about it P).
- What he knows: what the sheriff said on the road (the sorrel, "friend"), if he helped him; that the sheriff is
  dying (if he went back that evening, P).

**How he hears of it:**
- Draft: "Harlan arrives in Salt Creek and can explore the main street... He encounters a stranger in the saloon
  and begins talking with him." [P, draft]
- D, Sean 2026-11-09: "You're told to go to the saloon by someone or you're met by the stranger who brings you
  there so I don't think you can miss it unless player deliberately doesn't go then just hears about it".
- D, Sean 2026-11-17: the stranger is sat in the saloon and asks Harlan to sit with him [this session, item 1].
- P (script): the doctor sends him: "Go and get a drink, Harlan. I would, if I could leave him." Who sends him is
  O (s26); the script's reading is "the doctor may send him... and whoever walks into the saloon's yard is asked
  to sit".
- Day 2: a young man the doctor sent finds him: "Harlan! Doc's asking for you." [built] Draft: "through the doctor
  or someone sent to find Harlan".
- The funeral: "announced by townspeople, the church or the sheriff's family" [P, draft]. Built: nobody tells you
  to go.

**Beats, in order:**

*Night 1: the town*
1. Evening of day 1. The sheriff is at the doctor's. Townspeople talk about it; "Some are worried. Others behave
   more boldly because the sheriff is incapacitated." Harlan can explore, talk, or go straight to the saloon.
   [P, draft Beat 1; the town's lines P, script, not built]
2. A drunk by the saloon jokes "Ain't no sheriff tonight, boys!" [P·bible, S43]
3. Townsfolk know who brought the sheriff in, or that a freighter did. [P, script]

*Night 1: the table*
4. The stranger is sat in the saloon. He asks Harlan to sit with him and talk. [D, Sean 2026-11-17, this session
   item 1. The game still has the stranger come and sit down by Harlan: "Evening. Mind if I sit in a while?",
   built]
5. He buys Harlan a drink. [D, Sean 2026-11-17]
6. They talk about the sheriff for at most a minute: about Harlan bringing him in, if he did; the stranger calls
   him "a good man" who "didn't deserve it". [D, Sean 2026-11-17; the words P, script]
7. The stranger asks whether the sheriff could talk; Harlan can nod, shake (and so lie) or not answer. Sets
   `nolaw.told_stranger`. [P·bible / script; not built]
8. Nobody says who the stranger is. He is the Baron's foreman [D, Sean 2026-11-11, #830, C10 b] and the man who
   shot the sheriff that morning [D, Sean 2026-11-13, #906]. His sorrel is at the saloon's rail [P·bible, S40;
   needs a horse coat].
9. The saloon is "operating normally, with drinking, conversation and a card game". [P, draft Beat 2; the card
   game is built]

*Night 1: the murder*
10. Cody comes into the yard already shouting at Earl ("as he comes in, not when he reaches the table"). [D, Sean
    2026-11-12, built]
11. The stranger's hand is on Harlan's arm: "Don't move, friend. Whatever happens next, you sit still." Harlan is
    held in his seat. [D, Sean 2026-11-09: "the stranger sits there and tells the character not to do anything";
    built]
12. Cody kicks Earl's chair out from under him. [P, draft "Keep these details" 1; built]
13. Cody draws and shoots him where he lies. [draft; built]
14. Cody: "Ain't no law left in this valley to save you now, Earl." [built; the remark is the draft's]
15. The room goes quiet. Nobody challenges him. [draft; built]
16. The barman's first words: "Jesus, Cody, my chair!" [D, Sean's pick 2026-11-09; built]
17. Cody walks out. [draft; built] He rides for the foothills. [D, Sean's pick 2026-11-09]
18. A player who runs out after him can't catch him but sees which way he rode. Sets `nolaw.followed`. [D, Sean's
    pick 2026-11-09; the fact is in the game]
19. The stranger: "You didn't see a thing tonight. Nobody did. Remember that." He goes. [built]
20. The drifter and the miner leave the table. [built]

*Night 1: the carry*
21. Earl isn't dead at once. [D, Sean 2026-11-17, this session, item 3. The game still kills him with a head shot]
22. The barkeep tells Harlan to take him to the doctor's: "He's breathing. Harlan. You. Get him up to Doc's."
    [P, script; "who tells Harlan to take him to Doc's" is quoted in the script as Sean's question, 2026-11-17]
23. Harlan carries Earl up the street. [D, Sean 2026-11-17; #1057, not built]
24. Earl says a few small things on the way if he can talk. [P, script; the script quotes Sean: "what Earl says on
    the way if he can talk"]
25. Harlan bangs on the doctor's door. The doctor is up with the gut-shot sheriff and slow to come. [D, Sean
    2026-11-17]
26. The doctor looks once and says, in effect, "He needs a grave, not a doctor". [D, Sean 2026-11-17; the script's
    wording "This man wants burying, Harlan, not doctoring." is P]
27. Earl is laid in the doctor's front room. [D that his body is laid out there next morning, Sean 2026-11-17; "on
    the table, under a sheet" P, script]
28. If Harlan doesn't carry him: he dies where he lies and the saloon's men bring him up in the morning. [P,
    script, "proposed, #1057"]

*The same night, unseen*
29. Kett's crew raids Joe's camp; Joe's wife is raped, murdered and scalped. [D, Sean 2026-11-09: "Yeah joes wife
    is killed after the murder of the cheat"; 2026-11-11 two men]

*The morning after*
30. The town tells the night wrong, four ways. [P, script; draft: "Townspeople recount inconsistent versions"]
31. Earl lies under a sheet in the doctor's front room; the undertaker measures him there. [D the body's place,
    Sean 2026-11-17; the undertaker's lines P. The game today sends Earl "to the undertaker's"]
32. Nobody arrests Cody. [draft: "The murderer is not immediately arrested."]
33. The doctor's runner finds Harlan: "Harlan! Doc's asking for you." [built]

*Day 2: the doctor's*
34. The doctor waits at his door and leads Harlan to the sick room. The sheriff is on the cot; his wife sits by
    him. [built]
35. The doctor keeps Earl from the sheriff: "The sheriff's not been told about Earl. Button your coat." [P·bible,
    S50]
36. The widow: "Were you with him?" [D, Sean's beat 2026-11-09; built]
37. The sheriff's words follow day 1's care: clear if he was well cared for, fading if not. [D, Sean's pick
    2026-11-09; built]
38. He says what he saw of the man who shot him. [built wording #908; new wording P]
39. He speaks of his ditch and asks Harlan to look to his family. [built; that the Baron is named here is P,
    script]
40. He asks whether Harlan will take the badge. The player nods yes or shakes no. [D, Sean 2026-11-17, brief item
    4; draft Beat 5: "Respond through the nod when the sheriff asks Harlan to accept responsibility"; built]
41. A no gets "that's not the way this works", and he is deputized anyway. No answer counts as a shake. [D, Sean
    2026-11-09; built: "That's not the way this works, son."]
42. The sheriff says it's deputy only for now, until the county decides. [D, Sean 2026-11-17, brief item 4; the
    line P, script; not built in his mouth]
43. He gives Harlan his revolver. [D, the lock and Sean's draft; built: `Player.give`]
44. He dies. [D; built]
45. The doctor, as coroner the acting sheriff, keeps Harlan on as deputy. [D, Sean 2026-11-11, #830, C12 a; built]
46. The widow: "I'll sit with him now. Go on, the both of you." [built]

*The funeral*
47. The day after he dies, from ten, at the cemetery on the hill up Church Lane. [built; the script says "Day 2 or
    3"]
48. The town gathers: the widow and the doctor by the grave, the preacher at its foot, hats off. [built; draft
    Beat 6]
49. The Baron and his foreman stand apart. [built; the foreman behind the Baron is P·bible, S39]
50. The preacher reads the burial words; the box is lowered. [built]
51. Two of the town say a small true thing. [built]
52. The Baron goes to the widow and offers to buy her claim; she refuses without looking up. [D, Sean 2026-11-09:
    "I like the baron offering to buy"; built]
53. He leaves, with a word for Harlan if he came. [built]
54. The widow thanks Harlan if he came. [built]
55. The town walks back to work. [draft; built]
56. It plays whether Harlan is there or not. Sets `nolaw.funeral` = attended / distance / missed. [D, Sean
    2026-11-09: "Yeah you can choose to attend the funeral"; built]

**Choices, and what each sets:**
- Go to the saloon or not: `nolaw.seen_from` = table / yard / heard / away. [built]
- What he tells the stranger: `nolaw.told_stranger` = yes / no / none. [P; not in the game]
- Follow Cody out: `nolaw.followed`. [D; built]
- Carry Earl or not: `nolaw.carried_earl`; `nolaw.earl` = doctor's / saloon (today the game sets "undertaker").
  [D that he carries him; the "not" branch P; not in the game]
- Nod or shake at the oath: `nolaw.accepted` = nod / shake / none; either way `nolaw.deputy`, `nolaw.revolver`.
  [D; built]
- Attend the funeral, watch from a distance, or miss it: `nolaw.funeral`; also `nolaw.offer_heard`, `baron.met`,
  `nolaw.funeral_broken` (a shot nearby breaks it up). [built]
- Draft's cost of the nod: "Accepting draws Harlan into the town's problems; refusing leaves those problems
  unresolved and risks losing people's trust." "the family and doctor remember his refusal." [P, draft]

**Endings, and what it leaves in the world:**
- Earl dead; "a recorded death, burial or obituary instead of disappearing from the world" [P, draft]. A pine box,
  charged to the county [P, script].
- Cody free, known by name to the barman and seen by the whole room. [D]
- The broken chair kept. [D, Sean's pick: "Saloon keeps the evidence"]
- The sheriff dead; his grave "a persistent world location" [P, draft]. Built: the grave is filled once the
  mourners have gone and the player is off the hill.
- Harlan a deputy, for now, with the sheriff's revolver. [D]
- The widow has refused the Baron. [D]
- "The mission can finish without a formal completion screen, as normal town life resumes." [P, draft]

**Who is in it:** Harlan. The stranger (the Baron's foreman; no name). Cody ("some rough asshole", one of the
Baron's hired guns, rides with Kett's gang). Earl (the card player). The barkeep (the saloon's owner). A drifter
and a miner at the table. Townsfolk: a townsman, a townswoman, a loudmouth. The doctor. The doctor's runner. The
sheriff. His wife (the widow). Their children (P in the draft; D that they are the sheriff's and widow's kids;
not in the built day 2). The undertaker (P). The preacher. The Baron. Not in it: Kett (D 2026-11-11), the bold
cowboy as the killer (D 2026-11-11), Joe ("Joe is not yet Harlan's companion", draft).

**Sean's own words:**
- 2026-10-15 (DESIGN "Story shape"): "nothing set in stone, just a rough idea, all may change".
- 2026-11-09, with the draft: "And also when the sheriff is dying of the player shakes head no the sheriff says
  something like "that's not the way this works" or something so you get it either way and maybe a kinda humour
  moment".
- 2026-11-09: "the mission no law"; "at the start of the game the first night in the saloon after bringing in the
  sheriff".
- 2026-11-09: "you haven't been appointed to anything yet the first night - it's not until the second day so you
  aren't any law when this murder happens - that's why there's no law around to do anything about the cold blooded
  murder".
- 2026-11-09: "it's played in game while player is sitting at a table and has no gun yet so he can't do anything
  at all". "the stranger sits there and tells the character not to do anything".
- 2026-11-09: "You're told to go to the saloon by someone or you're met by the stranger who brings you there so I
  don't think you can miss it unless player deliberately doesn't go then just hears about it".
- 2026-11-09: "He can maybe try to help but card cheat shot in the head".
- 2026-11-09: "Maybe try and follow but I'd say if we have horses working the murderer takes off and you can't stop
  him in time".
- 2026-11-09: "There's no talking about the red shirt by Harlan".
- 2026-11-09: "Saloon keeps the evidence but we aren't pulling bullets out to examine that idea isn't happening".
- 2026-11-09: "Yeah you can choose to attend the funeral".
- 2026-11-09: "Yes you are deputized".
- 2026-11-09: "Yeah joes wife is killed after the murder of the cheat".
- 2026-11-09: "maybe day 2 the murder of the woman occurs that night after then murder of the cheat".
- 2026-11-09: "Hmmm yeah I dunno about Joe yet that's gotta be flagged".
- 2026-11-09: "Yeah the name works". "Yes the children are the sheriffs / widows kids".
- 2026-11-09: "1, 3 and 4 yes, put them on the card" (the last words by care; the barman's chair; following him).
- 2026-11-09: "Yes I like the ticks". "I like the baron offering to buy".
- 2026-11-09: "we're still keeping as deputy. I don't know if we become sheriff ever in the game."
- 2026-11-09: by day 2 Harlan is "temporarily appointed by the dead sheriff" ("at this point you've been
  temporarily appointed by the dead sheriff").
- Sean's rule and punchline (showcase moments): "Jesus, Cody, my chair!"; "owners care about their own things
  first".
- 2026-11-11: "I just realized the guy in the red shirt can't be the one to shoot the card cheat and be the one to
  murder Joe's wife - then if he gets away with the wife's murder he could still be held for the card cheats
  murder".
- 2026-11-11: "The bold cowboy is not the murderer - I'll find something else for him - the murderer just has to be
  some rough asshole".
- 2026-11-11: "He can keep the name Cody and yes he can ride with the gang and be in the jail". "I like Silas
  kett". "Set it".
- 2026-11-11 (#830, C10): "The stranger at the table is the Baron's foreman." (given in CONTRA as his pick)
- 2026-11-11 (#830, C12): "He was the county sheriff, the county seat down the line. When he dies the coroner acts
  as sheriff, and the coroner is the doctor, who keeps Harlan on until the county names a man." (given in CONTRA as
  his pick; the words are the option's)
- 2026-11-12: Cody shouts "as he comes in, not when he reaches the table"; his redo of the accusation: "Earl, you
  cheating son of a bitch!"
- 2026-11-13 (#906): "Yeah let's go with the stranger."
- 2026-11-17 [this session]: the stranger is sat in the saloon and asks Harlan to sit with him and talk; he buys
  the drink; they talk about the sheriff for at most a minute ("a good man", who "didn't deserve it") before Cody
  comes in. As quoted in the script notes: "he'll ask you to sit with him and talk"; "he buys you a drink"; "calls
  the sheriff a good man and didn't deserve it".
- 2026-11-17: Harlan has no gun on night one; he gets the sheriff's on day 2; that is what prevents a shoot-out in
  the saloon. (No verbatim quote in the sources I read; the brief and the bible give it in these words.)
- 2026-11-17 (#1056, SETUPS S50): "Harlan has to carry Earl … to the doctor's and bang on the door"; the doctor
  "says, more or less, that this man needs a grave, not a doctor". Brief: "He needs a grave, not a doctor".
- 2026-11-17 (script notes, as quoted there): "who tells Harlan to take him to Doc's"; "what Earl says on the way
  if he can talk"; "the doctor who didn't open, or opened too late"; "the blood on Harlan's coat in the morning";
  "the whole head nod yes or no if we're taking the badge when he asks".
- 2026-11-17: "that's not the way this works" for a no; the sheriff says it's deputy only for now, until the county
  decides [this session, item 4].
- 2026-11-17: "cocky and arrogant … but also a coward - that's why the sheriff was only shot in the gut and not
  finished off"; "probably a mid game reveal although I'm sure people will be guessing it right away".
- 2026-11-17: "I want call backs and remember what's going on: it's a story to tell, not a bunch of disjointed
  missions."
- From the master chat, not in the repo, "to confirm": Sean wanted the stranger's voice "more educated" [VOICES].
- Sean's whole draft is his words too: `draft` (not repeated here; its parts are quoted through this section).

**Lines of dialogue anyone gave:** (built = in the game; new = the 2026-11-17 script, P)
- Town, night 1 (new): "Sheriff's shot. He's at Doc's, and Doc ain't saying." / "I'm barring my door tonight." /
  "Road agents, somebody said, or Utes." · "And her out there with two boys and the stock to see to." / "Somebody
  ought to ride out to her. It won't be any of these men." · "Ain't no sheriff tonight, boys!" / "Who's going to
  fine me? Doc?" (was "No sheriff tonight, boys. Drink where you please.") · "You're the one brought him in. From
  up the creek." · "Doc says that wound was packed proper. Says you done it." · "Freighter found him in the road.
  Three hours he'd lain there. Somebody must've gone right by him." · Doctor: "Go and get a drink, Harlan. I would,
  if I could leave him."
- Stranger: "Evening. Mind if I sit in a while?" (built) → "Evening. Harlan, isn't it? Sit with me a while, if
  you've no objection." (new) · "What'll you take? ... No, put your money up. I asked you." (new) · "They tell me
  it was you brought the sheriff in. Carried him the best part of four miles. That's a deal of trouble to go to."
  (new) · if he left him: "You'll have heard about the sheriff. Shot on the East Road this morning, not four miles
  from where we sit." (new) · "I only met him the once. He seemed a good man. He didn't deserve that." (new) · "He
  able to talk any, when you got him in?" (new; bible's earlier: "Heard it was you brought the sheriff in. He say
  who it was?") · "You'd have come down that road yourself this morning. ... See anything of it?" (new) · answers:
  "Did he." / "No. I'd not think he could." / "No matter." (new) · "Don't move, friend. Whatever happens next, you
  sit still." (built) · "You didn't see a thing tonight. Nobody did. Remember that." (built) · to a gun pointed at
  him: "Easy, friend. I ain't the one you want." / "Put it up. You'll only get yourself killed." / "Walk away.
  That's my advice." (built; can't be reached on night one now) · VOICES: "Might I stand you a drink?" (P·bible)
- Cody: "Earl. You been dealing off the bottom of that deck." (first built; Superseded) → "Earl, you cheating son
  of a bitch!" (Sean's, 2026-11-12, built) · "Ain't no law left in this valley to save you now, Earl." (built) ·
  to a player who follows: "Go on back to your cards, nester." → "Go on back to your cards, farmer." (new)
- Earl: "Now, Cody, I never..." (built) · on the carry (new): "Mind my arm." / "I left my hat." / "Tell Cody I'll
  make it good. You tell him." / "It was only a dollar." · the card game's own talk: "Ante.", "Call.", "Lady's been
  kind tonight" (built, `config/card_game.json`)
- Barkeep: "Jesus, Cody, my chair!" (Sean's; built) · "Somebody ought to fetch the... hell. Ain't nobody left to
  fetch." (built) · "He's breathing. Harlan. You. Get him up to Doc's." / "Go on! He can't lie there." (new) · "He
  owes me four dollars." (new)
- Drifter: "I'm out." (built) · Miner: "He were cheating, my son, a dollar at a time, same as ever he did." (new)
- A woman in a doorway (new): "Is that Earl? ... Lord. Doc's got his lamp lit. Go on."
- Doctor at his door, night (new): "Who is it? I've a man dying in here." / "I hear you! I've only the two hands."
  · "This man wants burying, Harlan, not doctoring." · "That's two you've carried to this door today." · "This one
  you carried." · "Lay him in the front room. On the table. There's a sheet on the chair." / "Then go home. I've
  the sheriff to sit with."
- Morning (new): "Cody said there weren't no law to stop him, or some such." / "Earl went for a knife, the way I
  heard it." / "Two of them done it. One held him." / "Cody give him a fair chance. That's what Cody's friends
  say." · "A dozen men sat and watched it done." · "They say you sat at that very table. Sat right through it." ·
  "They say you carried him clear up the street. ... That his blood on you?" · "Cold water, Mr. Harlan, not hot.
  Hot sets it." · "Somebody saw you go out after him. On foot. After a man on a horse." · "I said who's going to
  fine me. Hell. I was only funning." / "He'll be back. Why wouldn't he?" · Undertaker: "Earl. Nobody can give me
  his other name. Shot by one Cody, before witnesses. Pine box, charged to the county." / "He had on him a deck of
  cards, a pocket knife and sixty cents." / "The saloon wants four dollars and a chair set down against that." ·
  Doctor by the body: "He was dead when you knocked. I'd not have you think it was the door." · Runner: "Harlan!
  Doc's asking for you. Says the sheriff's sinking." (built: "Harlan! Doc's asking for you.")
- Day 2, doctor at the door: "He's asking for you. He's clear this morning. It won't last." (built) → without the
  last sentence (new) · "He's asking for you. He comes and goes. Be quick." (built) · "He's been asking for you
  since the freighter brought him. I couldn't tell you why." (built) → without the last sentence (new) · "The
  sheriff's not been told about Earl. Don't you tell him." / "...Button your coat." (new)
- Sheriff, day 2: "I can hear you, Doc. Send him in." (new) · "Whose blood is that on you? ... That ain't mine."
  (new) with the doctor's "A man cut himself at the saloon. Lie back." (new) · who shot him: "Faded red shirt. I'd
  know him again. You find him, Harlan." (Superseded) → "Bald-faced sorrel. Called me friend. I'd know him again.
  You find him, Harlan." (in the game) → "Bald-faced sorrel. Soft-spoken man. Called me friend. Shot me from the
  saddle and never got down." (new) · fading: "...red shirt... rode up easy..." (Superseded) → "...sorrel... said
  friend..." → "Sorrel... white face. Said friend. He said friend." (new) · the ditch: "He's wanted my ditch since
  the day I cut it. Now he'll go at her. Look to them." (built) → "The Baron's wanted that ditch since the day I cut
  it. He'll go at my wife for it now. Look to her and the boys." (new) · "...the ditch... look to them..." (built)
- The oath: "Doc. My badge. ... Raise your hand, Harlan. You'll keep the peace of this county, best you're able.
  Nod, then." (built) → "Doc. My badge. ... Harlan. I want this on you. Keep the peace of this county and serve its
  papers. There's more to the oath. I disremember it. Will you take it?" (new) · fading: "Badge... Doc. Pin it on
  him." (built) → "Badge... Harlan. Take it. ... Will you?" (new)
- Nod: "Good. You're my deputy. Doc, you heard him." (built) → "Doc, you saw that. He's sworn." (new) · "...good."
  (built)
- Shake: "That's not the way this works, son. ... Doc. Pin it on him." (Sean's beat; this wording #796's; built) ·
  "Second time you've shook your head at me. ... That's not the way this works, son. Doc. Pin it on him." (new) ·
  "...not how it works... son." (built) · a period wording offered to Sean: "That ain't how it's done, son." (P)
- For now (new): "It's only for now. The county commissioners name the next man. Till they do, Doc's coroner, so
  he's sheriff, and you're his deputy." · "Only till the county... names a man. Doc... tell him."
- The pistol: "Take my pistol. She pulls a hair to the left." · "...pistol... take it." (built)
- Last words: "Sun's up. Ain't that something." (built) → "Go home to the boys." (new) · "...boot." (built; S33 P,
  not picked)
- Doctor, day 2: "Hold him. No... yes, like that. You've done this before. Where? ... No. Keep it." (built) →
  "...You've held a man down before." (new) · "He's gone." (built) → "He's gone, ma'am." · "I'm the coroner, Harlan,
  so until the county sends a man I'm what law there is. And you're my deputy. Keep the badge on." (built) → "He had
  it right. I'm the coroner, so I'm sheriff until the commissioners name one. Keep the badge on." (new) · "A sorrel
  horse and one word. I can't hang a man on that, Harlan." (new; bible: "Not enough to hang a man on, Harlan. Not
  yet.") · VOICES: "Until the county sends a man, you're what we have. Keep the badge on." (P·bible)
- Widow, day 2: "Were you with him?" (Sean's beat; built) · "He said it was you that brought him. I'm obliged to
  you, Mr. Harlan." · "A freighter brought him, they tell me." · "I'll sit with him now. Go on, the both of you."
  (built)
- Funeral: preacher: "Man that is born of a woman hath but a short time to live, and is full of misery. He cometh
  up, and is cut down, like a flower." (built; the 1662 burial service) · town: "He'd come in Saturdays. One drink.
  Never two." (built) → "He fined me twice, and I'll own I had it coming both times." (new) · barkeep: "Never once
  took a drink on the house. I'd pour it and he'd leave the dime." (new) · Baron: "A hard day, ma'am. When that
  place grows too much for you, come to me first. You'll not find a fairer figure." (built; "the offer is Sean's,
  the words aren't") → "It is a hard day, ma'am, and I'd not trouble you on it, only to say that when that place
  grows too much for you, as it may, I hope you will come to me before another. You'll not find a fairer figure."
  (new) · widow: "Not today. Not any day." (built) → "He's not covered over yet." (new) · Baron: "Forgive me, ma'am;
  it was ill-timed of me, and we will speak of it another day." (new) · to Harlan: "Mr. Harlan. A sad day for the
  county." (built) → "...and I'd not have chosen it to make your acquaintance." (new) · "Mr. Harlan, they tell me he
  had a night with his wife that he'd not have had but for you, and I call that well done." (new) · "You have the
  spring above the creek, I'm told, and the only sweet water for some miles. I have admired it from the road."
  (new) · the foreman: "Good morning to you, Deputy." (new) · widow: "You came, Mr. Harlan. He'd have noticed
  that." (built) · "He told me you shook your head at him. It tickled him." (new) · "Mr. Harlan." (new)
- Harlan doesn't speak. [script notes]

**Pays off from earlier / plants for later:**
- Pays off the road: `sheriff.care` in the last words; the sorrel and "friend" joined at the table (S40); "two
  you've carried to this door"; the Baron's "well done" at the grave. [mix of D and P·bible, above]
- Plants S2: "Ain't no law left..." → Cody in Harlan's cell with his own side coming (the jail night); the three
  titles "are one sentence": No Law, No Justice, I Am the Law. [plant built; payoff P·bible]
- Plants S4, Cody the witness: he can say who shot the sheriff and who paid. [D, 2026-11-11]
- Plants S10, which way he rode → the camp's "They rode for the hills", and Joe's "You saw them ride out." [D]
- Plants S34/S44, the chair and the four dollars → the undertaker's book; the barkeep and his floor on Payday
  Night. [chair D; rest P·bible]
- Plants S3, the Baron's offer → the farmhouse (the foreman with a deed: "his answer to her refusal"). [D]
- Plants S39, the foreman's face → the widow's lane; the men who pulled the rail; the raid. [D that he's the
  foreman; places P·bible]
- Plants S15, "That's not the way this works, son." → the widow, when he tries to refuse the rifle. [plant D,
  payoff P·bible]
- Plants S41 "She pulls a hair to the left." → the widow's place; Cody's arrest. [P·bible]
- Plants S46, the stranger asks leave → the lane, deed in hand. [P·bible]
- Plants S49, the Baron admires Harlan's spring → no card yet. [P·bible; s14 O]
- Plants S50, Earl at the doctor's door, the count, the coat → Payday Night's triage is "the answer to it". [D the
  carry; rest P·bible]
- Plants S51, he didn't get down (the coward) → a mid-game reveal, likely the widow's lane, or the raid. [D that
  he is and that it's held; plants and payoff P·bible]
- Plants S32, graves: the sheriff's, Earl's → the last walk; `dig-him-up`. [D/P]
- Plants S37, the town already saying "Utes" on night one. [P·bible]
- Leads to: Cody walks back into the saloon after the funeral and Harlan arrests him there, his first arrest. [D,
  Sean 2026-11-11, #830, C6 b] Then the jail night (the Water Tower). [D, C7 c]
- The widow met before the farmhouse. [draft; the lock's order]

**Every other idea found:**
- DESIGN "Story shape" (P, Sean 2026-10-15): "It opens at the saloon table: the evening before day 1, the concept
  painting's shot. The stranger sits down across from you and talks (friendly, too curious about the sheriff and
  your spring); a shooting breaks out at the bar and plays out however you handle it." [Superseded: now night 1,
  after the sheriff, unarmed]
- The card cheat showcase moment (Sean): the victim "kicks the back legs out of his chair and he goes over
  backwards; the victim draws, shouts, and puts the gun in his mouth. You have seconds." Ways: shoot him, shout or
  draw so he turns, shove, throw a bottle, shoot his gun hand, answer his "Tell me I'm wrong" with a nod or shake,
  or let it happen. "Some days the victim was cheated; some days he's lying." [P, showcase-moments; Superseded for
  the story's night one; the moment itself is built as `card_cheat.json`]
- "A Quiet Drink: a saloon confrontation that tests conversation, escalation, intimidation, close-range combat,
  furniture destruction, and civilian reactions." [Sean's brief 2026-10-17, "provisional"; inventory Part 3:
  "Saloon poker dispute with multiple ways to intervene", "not current approved"]
- Inventory "The Saloon Shooting": "A bold cowboy accuses another man of cheating at cards. He kicks a chair aside
  and creates a confrontation. He declares that there is no law in Salt Creek and shoots the accused cheater.
  Introduces... our environmental combat systems." [Superseded: not the bold cowboy, Sean 2026-11-11; no combat,
  Sean 2026-11-09]
- The red shirt kills the cheat (draft, and D 2026-11-09). [Superseded, Sean 2026-11-11: two men; Cody]
- "The red-shirted murderer is also responsible for the rape and murder of Joe's wife. Harlan does not yet know
  this." "The player recognizes him from the saloon." [draft; Superseded: Kett isn't in the saloon]
- Draft choices at the murder: "Attempt to intervene physically, at significant risk"; "Take cover or retreat";
  "Try to assist the victim afterward". "Do not create an artificial invulnerable murderer or disable all player
  action." [P, draft; the first Superseded by Sean 2026-11-09 (held, unarmed)]
- "If Harlan manages to kill the red-shirted man, this becomes a substantial alternate story branch, not an
  immediate game over." "If the card player escapes or survives, the incident still becomes a violent threat."
  "If the stranger dies, Harlan loses that relationship, but the story continues." [P, draft; the card says these
  "no longer apply"]
- "If the player is injured attempting to intervene, the doctor can treat him." [P, draft]
- The player can watch "from the bar, another table or near the entrance. The upper floor, if accessible". [P,
  draft]
- "If ignored: The player can avoid the saloon. The shooting still happens and becomes town news." [P, draft; the
  game has `seen_from` = heard / away]
- "Missing the sheriff's death means learning about it afterward, with the gun transferred through the doctor or
  family." [P, draft; built: a runner fetches him]
- Does the sheriff hand over the gun himself, or the doctor afterward? [O in the draft; built and scripted: the
  sheriff himself]
- "Patrons react differently: some leave, some attend to the victim and others act as though nothing unusual
  happened." [P, draft]
- "The stranger reacts to what Harlan witnessed." "The stranger may comment on what Harlan did or failed to do."
  [P, draft]
- "The red-shirted man may recognize Harlan later." "Witnesses remember his courage or recklessness." [P, draft]
- Factions: "Baron: His men may consider the town easier to influence; no direct involvement is established."
  "Outlaws: The absence of a sheriff may embolden them." "Mine and Ore Works: Workers discuss the loss of law
  enforcement". "Railroad: No immediate gameplay change." [P, draft]
- "Townspeople begin looking to him for protection." [P, draft]
- "PROPOSED: Their children are also present, allowing Harlan to meet them early." "a child standing beside a
  parent" at the funeral. "Are they based on the user's two sons?" [P/O, draft]
- Funeral details: "residents arriving, removing hats... and the town slowly returning to work". "Avoid turning
  the funeral into another gunfight." "The service is quiet rather than a major cinematic spectacle." [P, draft]
- "PROPOSED: Cemetery slightly elevated above town, with a view toward the valley." [draft; the valley has it:
  `cemetery` (-95, -195), "higher ground north-west", D #700]
- "possibly an undertaker". "Does the murdered card player receive his own burial?" [P/O, draft]
- "Should the red-shirted man's arrival be the first clearly witnessed murder in the game?" [O, draft]
- "Was the card player actually cheating?" [O, draft. The script's miner says he was: "a dollar at a time", P]
- "Does the red-shirted murderer know Harlan witnessed the killing?" [O, draft. Bible: Cody "doesn't see him" at
  B2, P·bible]
- "Missing the funeral affects how certain residents perceive Harlan." "Relationships remain repairable through
  later actions." [P, draft]
- "Length: 20–30 minutes of active play, spread over the opening days." [P, draft]
- "A sheriff's death would not automatically grant his office to whoever inherited his gun. The legal process for
  a replacement needs research". [draft; answered by C12 a and the 1877 Colorado coroner law, "to check"]
- "The response to a murder should reflect the settlement's actual legal arrangements, not assume all Western
  towns lacked functioning law." [P, draft]
- Judge run 1 ideas: (1) the anatomy decides if the card player dies or bleeds, so first aid on the saloon floor
  is a real result; a living witness. Sean took it "in part" ("card cheat shot in the head") — and on 2026-11-17
  Earl now lives a while. (2) talking about the red shirt as a choice: not taken. (3) the saloon holds the murder
  physically (chair, blood, the ball in the floor, the burial paid or left to the town): taken "without the ball".
  The cut (take the funeral out): not taken. [judged]
- Judge run 2 ideas, none picked: who can describe the killer depends on where they sat and the lamplight; the
  dead man's stake and belongings (take, hand to the barman toward his burial, or leave); the nod matters through
  who vouches for him to the county (the doctor and widow as witnesses; "a rival put forward"). Cut: drop
  "remembered attendance" as a new system. [P, judged]
- "Idea 2, the town's gun law that nobody enforces." [P, a session; not picked by Sean, 2026-11-09]
- The town or the county confirms Harlan later, "which is what 'temporarily' means". [P, a session] Now: "until
  the county names a man" (D); who, when, and whether inside the game: O (s27); "whom the Baron will try to
  choose": P·bible.
- "What stops the follow if horses aren't working yet." [O, card]
- A player who follows Cody sees him join riders past the last house, one in a faded red shirt in the lantern
  light. [P·bible, S1]
- Cody "doesn't see" Harlan at the table; later calls him "nester" (the word "to check"), then "Deputy". [P·bible]
- The stranger knew Cody would kill that night. [VOICES, from the built lines]
- Why the stranger sits with Harlan: the whole town knows Harlan brought the sheriff in, and he wants to know what
  the sheriff said. "His cowardice is the reason the table scene exists." [P·bible]
- "On night one he must still seem the most dangerous man in the room: amused, condescending, and never tested".
  "Nobody ever says the word." [VOICES; D core, detail P·bible]
- "The Baron knows it, and despises him for the botched job (one cold line from the Baron, later)." [P·bible]
- If Harlan drew on the stranger: a flag, and the lane's line "You should have sat still". [P·bible; **dropped**,
  Sean 2026-11-17: no gun]
- The lane's line for a player who sat with him: "We've met, Deputy. You sat very still." [P·bible]
- The stranger was once proposed as the Baron himself (C10 a), or nobody's man, "a drummer or a railroad
  detective" who "comes back later as help" (C10 c). [not picked]
- The stranger's voice: educated (built lines, Sean's "more educated", to confirm) or a cowman's. Script's
  reading: "soft-spoken and mannerly; a man who asks leave for what he means to do anyway"; "ain't" when it suits
  him. [O s21; P until Script OK]
- The doctor lies to the dying sheriff about the blood: "the only lie he tells in the game". [P, script]
- The sheriff "never hears of Earl... Dies thinking his town is quiet". [P·bible, OUTLINE]
- The sheriff names the Baron once, on day 2, "so the player knows who 'he' is before the funeral". [P, script]
- The sorrel at the Baron's buggy at the funeral. [P·bible; art]
- Built stand-ins and gaps: the box, grave and headboards are plain blocks; "there's no sexton yet"; the badge on
  the dying sheriff and the wife's hands are open playtest notes; No Law's set "is still in the yard" of the saloon
  (no switch built to move it inside). [funeral.gd; docs/lanes/gameplay.md]
- The murder starts at a set hour on the first night, or sooner once the player has played a number of hands at
  the card table; `-- --no-murder` runs the valley's nights without it. [built:no_law_murder]
- The wires: the morning after, the depot agent mentions the Baron's man wiring east about "Indian trouble",
  before anyone in town has heard of the raid. [P·bible, S37]
- The roadmap's 3.6 "the saloon table" rough mission becomes the opening in story order. [P, BUILD_ORDER]
- "Acts (scenes as data)", "Cards (poker, faro, cheats)", "Owners care about their things" as shared systems. [MAP]

**Where the sources disagree:**
- **Who sits down with whom.** Built: the stranger comes and sits by Harlan ("Mind if I sit in a while?"), with
  Harlan at the card table (the murder can start "once you've played `after_hands` hands at the table"). Sean
  2026-11-09: "told to go to the saloon by someone or you're met by the stranger who brings you there". Sean
  2026-11-17: the stranger is already sat and asks Harlan to sit with him. The script puts them at "the stranger's
  table, beside the card game", yet other script lines still say Harlan "sat at Earl's table" ("That's the one sat
  at Earl's table"). Latest favours: the stranger's own table, his invitation. Whether Harlan can also play cards
  with Earl first: unsettled.
- **Is Earl dead at once?** Sean 2026-11-09: "card cheat shot in the head"; built: shot in the head, dead.
  Sean 2026-11-17: not dead at once; carried to the doctor's. Latest favours the carry. Unsettled inside it: the
  script's murder scene still says "shoots him in the head where he lies" while its `after` scene says "his wound
  by the body system"; and whether he dies on the way (script: "however fast you are, he is past help") or at the
  door.
- **Where Earl's body is next morning.** Built: the undertaker's. Sean 2026-11-17: the doctor's front room.
- **Can Harlan act at the murder?** Draft: he can try to intervene physically. Sean 2026-11-09: "he can't do
  anything at all". Sean 2026-11-17: no gun at all. Built: held in his seat, but with three lines for a gun pointed
  at the stranger. Latest: he cannot; those three lines are to move or drop.
- **Who kills the card player.** Inventory: "a bold cowboy". Draft and 2026-11-09: the red shirt. Sean 2026-11-11:
  Cody, "some rough asshole". Latest: Cody.
- **When the saloon scene is.** DESIGN (2026-10-15): the evening before day 1. Sean 2026-11-09: the first night,
  after bringing in the sheriff. Latest: night 1.
- **What Harlan becomes.** Inventory: "becomes the town's new lawman". Draft: the transfer of legal authority "is
  a separate historical and story question". Sean 2026-11-09: deputized, "temporarily appointed", "still keeping
  as deputy". Sean 2026-11-11: the doctor as coroner keeps him on. Sean 2026-11-17: the sheriff himself says it's
  deputy only for now. Latest: deputy, for now.
- **The children at the bedside.** Draft: proposed present. Built day 2: the wife only. Script: the sheriff sends
  his wife "home to the boys". Unsettled whether the boys are seen before the funeral or the widow's place.
- **When the funeral is, against No Justice.** OUTLINE and DECISIONS: the funeral, then No Justice. Built funeral:
  the day after he dies, at ten. Built No Justice: starts "the day the sheriff died, late morning". Script:nj:
  "After Harlan's sworn". s3's first reading: "the day after the funeral". Unsettled.
- **The oath's wording.** Built has the sheriff tell him to nod ("Nod, then."); Sean 2026-11-17 wants a real
  question ("if we're taking the badge when he asks"). Latest favours the question.
- **The Baron's lines.** Built in short sentences; the script re-words them long because "both readers said the
  Baron spoke in short sentences against his brief". Not Sean's call yet.
- **Was Earl cheating?** O in the draft. The card cheat moment: "some days... some days he's lying". The script's
  miner says he was. Unsettled.

**Open questions:**
- Who sends Harlan to the saloon (s26): the doctor, the stranger's own invitation once he walks in, or both.
- The stranger's voice (s21), and whether his built lines are re-made in the new voice ("For Sean").
- Whether the stranger's question (and `nolaw.told_stranger`) is wanted.
- What Earl's wound is, when exactly he dies, and what happens if Harlan doesn't carry him (#1057).
- Who tells Harlan to carry him (the script says the barkeep).
- The children: at the doctor's, at the funeral, or not until the widow's place.
- Where and when Harlan meets Joe (s3), and so whether Joe is anywhere on day 2.
- Whether Harlan is ever sheriff; who the county names, and when (s27).
- Whether the card player was cheating; whether Cody knows Harlan saw; Earl's burial.
- A third plant for the Baron's want for players who skip the funeral and the widow (SETUPS S3 gap).
- Whether "...boot" stays.
- Sean's Script OK on the No Law page (#835, #1056).

---

### No Justice (`no-justice`)

Other names: "The camp" (DESIGN §5 story mission 1, which this replaces). Earlier versions: "The Hunters" and
"The Law of Men" ("earlier versions of the Indigenous revenge storyline that evolved into No Justice. They should
not be counted as separate missions." [inventory]).

**Where it sits:** Act I, after Harlan is sworn (day 2). Whether it is before or after the funeral is not settled
(see "disagree"). **Built to its four endings** (#966): `config/moments/no_justice_camp.json`,
`no_justice_hideout.json`, `no_justice_cabin.json`; `src/missions/no_justice_camp.gd`, `no_justice_hideout.gd`,
`no_justice_cabin.gd`; Joe's fight lines in `config/companion_joe.json`. Rides are typed cards (riding isn't
built, #478). **Not built:** the jail's inside, Kett's days in the cell, the release on the platform, Kett on
Main Street afterwards, the bodies being found, the kin [script:nj: "the jail and the release are not built"].
Everything in the script is "PROPOSED" until Sean's Script OK.

**In one line:** Harlan rides with Joe, a Southern Ute widower, to the men who raped, murdered and scalped his
wife; the man in the faded red shirt gives himself up in a cabin, and Joe, knife out, asks "Are you going to stop
me?"

**Harlan walks in with:**
- Gun: the sheriff's revolver, given on day 2 [D]. Rifle: not stated here; the sheriff's Winchester comes from the
  widow at `widows-place`, whose place "after No Justice" is P [OUTLINE; BUILD_ORDER].
- Badge: yes, as deputy. Joe: "You wear the sheriff's badge. Does it do anything?" [built]. Sean 2026-11-09: "at
  this point you've been temporarily appointed by the dead sheriff".
- Horse: not stated. The rides are cards. The script has Joe say "Good. Get your horse." (P); Sean's maybe is that
  Harlan has no horse at the start and gets the sheriff's from the widow (P).
- Dynamite: none. D, Sean 2026-11-09: "no dynamite yet that comes in a later mission".
- Companion: Joe, from the doctor's office on.
- Wounds: not stated. Earl's blood may still be on his coat [P, script: "Still got him on his coat."].
- What he knows: if he followed Cody on night one, which way the riders went [D]. If he sat with the stranger, the
  stranger's face [P callbacks]. He does not know the raid was the Baron's provocation.

**How he hears of it:** "Harlan meets Joe at the doctor's office in Salt Creek. There's no quest marker: it's a
man in grief in a room you walk into." [D, sean-card]. **Flagged O by Sean** the same day: "Hmmm yeah I dunno about
Joe yet that's gotta be flagged". Built as a stand-in: Joe in the doctor's front office, late morning, the day the
sheriff died [built:no_justice_camp].

**Beats, in order:**

*1. The doctor's office*
1. Harlan walks in. Joe is there, with the doctor by his desk and the bold cowboy in the corner. [D, sean-card;
   built]
2. The doctor speaks first: who Joe is, and that his people's camp was raided "the night Earl was shot" with the
   men off hunting. [built; sean-card: "murdered and scalped in a raid on their camp while the men were away
   hunting"]
3. Joe: "I want the men who did it." He looks at the badge: "Does it do anything?" [built]
4. The doctor warns that even if the killers are arrested they are unlikely to be punished. [D, sean-card; built]
5. The bold cowboy agrees: "the law won't give justice for an Indigenous woman". [D, sean-card; built; his part is
   O, s4]
6. Joe asks once whether Harlan will come. The player nods or shakes. [built; sean-card says only "Harlan agrees to
   ride with Joe"]
7. Nod: they go. Shake or no answer: Joe goes out alone; follow him out and you've come anyway; stay and he rides
   alone. Sets `nojustice.met` = nod / followed / declined. [built; the card had no "no" path]

*2. Joe's camp*
8. They ride to the camp (a card). [sean-card; built]
9. The raid's damage is still there: burned belongings, bullet holes. [D, sean-card; built with stand-in props]
10. Joe: "Wait here." He goes to the survivors. Their talk is in Ute and isn't written ("a Southern Ute speaker or
    not at all"); no survivor is shown until the Studio has them, "made with care". [built]
11. Joe comes back and tells it: six men, maybe seven; the one who did it wore a faded red shirt; they rode for the
    hills. [D that they name him "by one thing: a faded red shirt" and know the way, sean-card; built]
12. If Harlan followed Cody on night one, Joe sees he already knows the way. [D, Sean's pick 2026-11-09; built]
13. Joe puts on a cowboy's hat and neckerchief and says why: so the gang's friends won't take revenge on his
    people. [D, sean-card; "Keep the costume", Sean 2026-11-11; built]

*3. The ride*
14. Joe leads, reading the trail through the foothills. They talk a little, about his wife and his want for
    revenge, "without long stops". [D, sean-card; built as a card plus a few lines]
15. Near the hideout Joe warns Harlan about what he means to do. [built]

*4. The hideout*
16. They come in the back way onto the slope above the gang's line shack. Joe counts them in a whisper: five or
    six, the red shirt by the fire. [D "five or six armed bandits", sean-card; built: five men and Kett]
17. Joe asks how Harlan wants it. The player chooses by doing: creep in, or open fire. [D, sean-card; built]
18. Joe fights beside Harlan, taking cover and shooting. Wooden cover, barrels and furniture break. [D, sean-card;
    built]
19. At the alarm the man in the red shirt runs for the cabin and bars himself in. It happens in the world, no
    cutscene, the shirt plain to see. One of his own yells after him. [D, sean-card: "a coward"; built: Kett has
    no gun on him at all]
20. The rest are beaten: dead, down, given up or run off. [D; built; a man who gets away sets `nojustice.seen`]
21. If the player kills the red shirt outside: Joe is furious, "That was mine to take." No nod moment; Joe goes to
    the body and the scalping happens there; Joe's trust drops but he still respects that Harlan came. [D,
    sean-card; built as the `outside` ending]
22. If Joe is hit: he goes down wounded, not dead; he can be helped up; the wound stays with him. [D, sean-card;
    built in CompanionBrain]
23. If the player flees or abandons Joe: "Joe finishes it alone or dies trying." What follows is O. [D + O,
    sean-card]

*5. The cabin*
24. At the barred door Kett bluffs that he has a gun. [built; P wording]
25. The player forces the door: kicks that add up (about three), a ball through the bar, or a way in through the
    wall's members. No dynamite. [D no dynamite, Sean 2026-11-09; the structure way in is the judge's idea 3, which
    a session read Sean as taking, "he hasn't said so in words"; built]
26. Inside, Kett is cornered, frightened and unarmed, hands up. He surrenders and begs to be taken in. [D,
    sean-card; built]
27. Joe comes in behind, draws his knife and walks to him. [D, sean-card; built: knife in hand, gun holstered]
28. Kett bargains: he'll say who sent him. [P, script; built line]
29. Joe turns to Harlan: "Are you going to stop me?" The player must look Joe in the eye and answer with his head.
    [D, sean-card; built]
30. **Nod = yes, I'll stop you.** Joe puts the knife away. Harlan arrests Kett. [D, sean-card; built]
31. **Shake = no, I won't.** Joe kills and scalps him, on the wound system; the camera never moves in; the player
    can stay or walk away. [D, sean-card; built]
32. A small, slow nod reads as a reluctant yes; an unclear one gets "Is that a yes?" [D, sean-card; built]
33. Acting answers too: stepping between them, drawing on Joe or on Kett, shoving Joe, or binding Kett is a nod;
    walking out is a shake; saying nothing for a while and Joe does it. [D "stepping between them, drawing on the
    man, or walking out", sean-card; the rest built]
34. The player can still shoot the surrendered man. It is murder; if Joe saw it: "He had his hands up." [D,
    sean-card; built]
35. No menu, no morality meter, nothing on screen saying which answer is right. [D, sean-card]

*6. After*
36. Revenge: Joe finishes it; they ride back together; Joe is quieter; the bodies are left at the hideout. [D,
    sean-card; built to the bodies left]
37. Arrest: the ride to town is a card; Kett walks bound behind Harlan to the jail's door; Joe comes along,
    "plainly unhappy". Inside to the cells is a card. [D, sean-card; built]
38. Kett sits "a couple days" in Harlan's jail. [Sean 2026-11-11: "Whatever makes sense so maybe takes a couple
    days for someone to come and release him"; the rest of C8 a is P, a session's, until Sean nods on #830; not
    built]
39. The prisoner leaves on the train under escort and is released; the player can be on the platform, see who
    lets him go, and act then. [D, Sean 2026-11-09: "release to the train"]
40. The man on the platform who lets him go is Rourke or his officer. [D, Sean 2026-11-09, picked from the story
    judge. C8 a (P): Rourke's officer comes on the train with a paper, a crime against a Ute woman on the
    reservation being the United States' matter, and turns him loose there "for want of a witness the court will
    hear"]
41. Kett comes back and walks free through Salt Creek; Harlan can run into him. "No new mission is needed, just a
    man on the street." [D, sean-card]
42. Joe learns of the release when the town does. [D, sean-card; VOICES]

**Choices, and what each sets:**
- Come with Joe or not: `nojustice.met` (nod / followed / declined). [built]
- Creep in or open fire: `nojustice.started`. [D; built]
- Kill Kett outside: ending `outside`. [D; built]
- The answer at the cabin: `nojustice.answer` (nod, shake, between, drew_on_joe, drew_on_kett, walked_out, none);
  `nojustice.ending` = arrest / revenge / murder / outside. [built]
- Shooting the surrendered man: `nojustice.joe_saw`. [built]
- Whether a man got away: `nojustice.seen`. Whether Joe went down: `nojustice.joe` (up / down). [built]
- Joe's disguise held or not: "if a bandit escapes, or someone sees Joe's face in the fight, the kin go to the Ute
  camp rather than to Joe". [D, Sean 2026-11-09: "Disguise matters, yes"]. Script adds `nojustice.kett_saw_joe`
  (Joe takes the hat off at the cabin and Kett lives). [P; not in the game]
- Also set: `nojustice.camp`, `nojustice.knew_the_way`, `nojustice.costume`, `nojustice.trail`,
  `nojustice.hideout`, `nojustice.kett`, `nojustice.crew`, `nojustice.joe_trust`, `nojustice.camp_trust`,
  `nojustice.bodies`. [built]

**Endings, and what it leaves in the world:**
- **Arrest (nod).** Kett in the jail, sent off on the train, released "without real punishment", back on Main
  Street. "The doctor's and the cowboy's warnings come true. That's the mission's title." The camp's trust in
  Harlan cools. Leads to the rope: "the released murderer is in town. Joe kills him there, in front of witnesses,
  and the town tries to hang Joe." [D, sean-card]
- **Revenge (shake).** "It doesn't stay a secret: the gang's bodies are found, and whoever finds them carries the
  story to town." "The town splits: some say good riddance, some say a white man rode with Indians against white
  men." "The camp trusts Harlan." "The bandits' kin or friends hear and come looking", and try to lynch Joe. [D,
  sean-card]
- **Murder (Harlan shoots the surrendered man).** "it's murder. Joe saw it. Who else learns of it, and the law's
  response, run through the witness and rumour systems." [D, sean-card]. What then causes the rope: O (s1).
- **Outside (killed in the fight).** No question is asked; Joe is furious; the scalping happens at the body. [D]
- Either way: "Joe respects Harlan for helping when the law wouldn't." "Joe becomes Harlan's main companion for
  the rest of the game, and later the man with plans (#738, PROPOSED). How Joe treats Harlan reflects the choice,
  but the main story isn't changed at its root." [D, sean-card; "the man with plans" P]
- Both main endings lead to the same moment: "Someone tries to hang Joe, and Harlan shoots the rope with the
  Winchester". [D, sean-card; see `joe-on-the-rope`]
- The cabin finished Kett's crew, so the Baron hires the Colters for the widow's farm. [D, Sean 2026-11-11, #830,
  C5 b: "B it is"]
- Rourke is met whatever the ending. [D, Sean 2026-11-09]; how in the revenge ending is O.

**Who is in it:** Harlan. Joe (his own name O). The doctor. The bold cowboy (who he is: O). The camp's survivors
(not shown, not written). Silas Kett, the red shirt (his crew call him "Red"; the town knows him only as "the red
shirt" until someone names him; who names him O). Five men of his crew. Rourke's officer on the platform (P). Not
in it: Cody (the script's reading: "he rode on to the Baron's after the raid"; s24, P until Script OK). Dropped
from DESIGN's version: the war leader, the elder, the trackers, the husband as a separate man.

**Sean's own words:**
- His whole card, `sean-card`, is his (status line: "DECIDED by Sean, 2026-11-09 (his mission write-up plus the
  master chat's changes, which he accepted that day)"). The parts not already quoted above:
  - "Replaces: DESIGN.md story mission 1, "The camp". Its third ending (take the man past the town to a marshal or
    circuit judge) is dropped on purpose: two endings, not three."
  - "Estimated length: 25–35 minutes."
  - "Harlan rides with Joe, a Southern Ute widower, to hunt down the gang that raped, murdered and scalped his
    wife. The mission ends in a choice: let Joe take his revenge, or enforce a law that almost certainly won't
    punish the murderer."
  - "Joe's camp: the Southern Ute community, north-west of town".
  - "The bandits' hideout: a secluded wooded spot in the foothills, with a main cabin on rising ground and a
    hillside above it to watch from. It's one of the places with height (#736)."
  - "Joe changes into ordinary cowboy clothes (a hat and a neckerchief) so no one can tell he's from the camp. He
    says why: he doesn't want the gang's friends taking revenge on his people."
  - "The man in the red shirt is a coward. At the first shots (or as the fight turns) he runs for the main cabin
    and barricades himself in. It happens in the world, with no cutscene, and the red shirt must be plain to see
    as he runs."
  - "The player kills the man in the red shirt outside. Joe is furious ("that was mine to take")... There's no nod
    moment: the player took the choice away by shooting."
  - "OPEN: whether Joe can truly die here, which would mean his later role needs a fallback (#738 rule 2)."
  - "The player can still shoot him. Nothing stops it. But killing a man with his hands up is murder: Joe sees it,
    and the world can learn of it".
  - "Joe turns to Harlan and asks if he's going to stop him." "The answer is given with the nod... the player has
    to look Joe in the eye."
  - "A small, slow nod reads as a reluctant yes. An unclear one gets "Is that a yes?""
  - "Joe is quieter. Revenge hasn't magically mended his grief."
  - "The released man comes back... (Sean's open question, now decided: yes)."
  - "Keep these three details": "The red shirt: plain to see in the gunfight, so the final prisoner's identity is
    never in doubt." "Joe's cowboy disguise: it gives him personality and shows he's protecting his surviving
    people, not only chasing revenge." "The prisoner's release: it makes the arrest ending true to the warnings and
    gives the mission its name."
  - "Linear until the cabin, on purpose. No detective work, no several hideouts, no subplots. The strength is the
    moral choice, not the manhunt. (A judge should score "choices" knowing this was chosen.)"
  - "History, handled with care... Scalping is shown as the act it was, never as spectacle."
  - "Still open": "Whether Joe can die in the gunfight, and his fallback if so." "What happens if Harlan abandons
    Joe." "Joe's past: why he knows timber and trains, if he becomes the man with plans (#738)... work on the
    Denver & Rio Grande line crews is a candidate to research."
- 2026-10-06 (DESIGN, "The camp (Sean's)"): the husband "scalps him, and only him"; "The bandits are scalp
  hunters".
- 2026-11-09: "Disguise matters, yes". "release to the train". "at this point you've been temporarily appointed by
  the dead sheriff". "no dynamite yet that comes in a later mission".
- 2026-11-09: "Yeah joes wife is killed after the murder of the cheat". "Hmmm yeah I dunno about Joe yet that's
  gotta be flagged".
- 2026-11-09: "we need rourke to come no matter what because if Joe kills him we should still meet him".
- 2026-11-09: "Yes I like the ticks".
- 2026-11-11: "I just realized the guy in the red shirt can't be the one to shoot the card cheat and be the one to
  murder Joe's wife - then if he gets away with the wife's murder he could still be held for the card cheats
  murder".
- 2026-11-11: "He can keep the name Cody and yes he can ride with the gang and be in the jail". "I like Silas
  kett". "Set it" (the town knows him only as "the red shirt" until someone names him).
- 2026-11-11 (#744): the red shirt's gang "raid Joe's camp, hold the farm and do his dirty work" ("hold the farm"
  replaced by C5 b).
- 2026-11-11 (#830, C4): "A - toss the costume if you don't like the idea"; then "Keep the costume".
- 2026-11-11 (#830, C5): "B it is".
- 2026-11-11 (#830, C8): "Whatever makes sense so maybe takes a couple days for someone to come and release him".
- 2026-11-13 (#830): "it can't be the same man as he would never be released for the murder of joes wife if he
  also shot the sheriff".
- 2026-11-17: "it's a story to tell, not a bunch of disjointed missions."

**Lines of dialogue anyone gave:** (built = in the game; new = the 2026-11-17 script, P)
- Sean's, word for word, built: Joe: "Are you going to stop me?" · "Is that a yes?" · "That was mine to take."
- Doctor: "This is Joe. The night Earl was shot, his people's camp was raided while the men were out hunting. His
  wife was killed. I'll not tell the rest. He can, if he chooses." (built) → "Harlan. This is Joe. Riders came
  through his people's camp the night Earl was shot, with the men off hunting. His wife... she's dead." (new) ·
  "Bring them in if you like. I never yet saw a white man hang on an Indian's word." (built; VOICES has "Bring him
  in...")
- The bold cowboy: "Doc's right. No jury in Colorado'll hang a white man for a Ute woman. I've seen 'em try."
  (built) → "A jury? They'd stand him a drink." (new) · "That's the one sat at Earl's table. Sat right there."
  (new) · "He's the one carried Earl up here. Still got him on his coat." (new)
- Joe at the doctor's: "I want the men who did it." · "You wear the sheriff's badge. Does it do anything?" (built)
  · "I ride today. Will you come?" (built) → "I'm going today. You coming?" (new) · "Then we go now." (built) →
  "Good. Get your horse." (new) · "No. I did not think so." (built) → "No. ... All right." (new)
- Joe at the camp: "Wait here." (built) · "Six of them. Seven, one says. They came in the night. We were four days
  gone, hunting. Four days." (built) → "Six men. One says seven. They shot the dogs first. We were four days out,
  after elk." (new) · "The one who did it to her wore a red shirt. Faded. That is all they saw of him. It is
  enough." (built) → "The one who did it to her wore a red shirt. Old. The red gone out of it. Nobody saw his
  face." (new) · "They went toward the hills. That way." (built) → "They rode for the hills. That way." (new) ·
  "You knew that already." (built) → "You saw them ride out." (new)
- Joe on the ride: "If they see a Ute, they go to the camp after. If they see a cowboy, they come to me." (built)
  → "A Ute kills a white man, the whites burn the camp. So today I'm a cowboy." (new) · "A hat and a rag at my
  neck, and I am nobody's Indian. Only one more man who shot at them." (built; bible) → "I won this hat at monte,
  from a Texas man. He said it was a good hat. He lied about the cards, too." (new) · "Six horses. One throws his
  right fore." (built) / "They watered here. Took their time." / "These are fresh. An hour." (new) · "Fresh. We
  are close." (built, per the hideout's `_doc`) · "She shot better than I do. She told everybody." (new) · "The
  doctor says you know wounds. One of us will want that." (new) · "They say the sheriff called a name from the
  road, and the man kept walking. ... Don't walk off from me." (new) · "When I find him, you will not like what I
  do. Better you know it now." (built) → "When we have him, don't watch." (new) · "Five. Six. There. By the fire.
  The red shirt." (built) · "How do you want it? Quiet, or now?" (built) → "How do you want it? Creep in, or shoot
  from here?" (new)
- The crew: "Riders! On the hill!" (built) · "We got company!" (built) → "Somebody's out there!" (new) · "There's
  only two of 'em!" / "By the wagon! Get him!" (built) / "Behind the woodpile!" (new) · "I'm hit! God damn it!" /
  "My leg! Jesus!" (built) · "Red! Where you going? Red, you yellow son of a bitch!" (built) · "I'm done! Don't
  shoot!" (built) → "I quit! Don't shoot!" (new)
- Joe in the fight: "The red shirt. He runs." (built) → "Left. By the wagon." / "Two. Behind the logs." / "Red
  shirt's running! The shack!" (new) · "I am hit. The leg. Go on." → "My leg. Go on. Go on!" (new) · "Enough. I
  can walk." → "It's all right. I can walk." (new)
- Kett: "Stay out! I got a gun! I'll use it!" (built) · "First man through that door gets it!" (built) → "I'll
  shoot through the door! I will!" (new) · "I'm done! I ain't heeled! You're law, ain't you? Then take me in!"
  (built) · "It weren't only me. Ask them. It weren't only me." (built) → "It weren't only me. Ask them. Ask any of
  them. Hell, they're dead, ain't they. It weren't only me." (new) · "You'll want to hear who sent me, Deputy,
  before that Indian opens my throat." (built) · "I know you. You're the one he sat with. I can tell you who he
  is, Deputy. Him at your table. His whole business." (new) · "Bless you, Deputy. You're a fair man. I'll come
  quiet." (built) → "Bless you, Deputy. Bless you. I always did say a town wants law. I'll come quiet as a lamb."
  (new)
- Joe in the cabin: "You know me. You were at my camp." (built) → "Look at me. You were at my camp." (new) · "Then
  take him. Take him to your law. We will see what it does." (built) → "Take him. Go on. See what your badge
  does." (new) · "Go outside, Harlan." (new) · "It is done." (built) → "Get the horses." (new) · "He had his hands
  up." (built)
- The ride back: Joe: "Her mother'll ask me is it finished. I'll tell her it is." (new) · Kett: "They'll not keep
  me, Deputy. You know that, don't you?" / "Fine country. Be a shame to leave it." (built) / "Who learned you to
  tie a man like this? The Army?" / "I've rode in worse company. Not a deal worse." (new) · Joe: "He talks a great
  deal for a man with his hands tied." (built) → "I can gag him." (new)
- The jail and release (all new, not built): Kett: "Couple of days, Deputy. That's all this is." / "Somebody'll
  come. They always do send somebody." / "What's supper? ... I ate better in Cañon City." · Officer: "Deputy, I
  have an order for your prisoner: a crime on the reservation is a matter for the United States and not for the
  county." · "There is no witness a court will hear. The man is at liberty." · Joe: "Doc told us. In his office." ·
  Kett on Main Street: "Morning, Deputy. Fine day to be at liberty." (bible) / "Still here, Deputy?" / "Say good
  morning to your Indian for me."
- Gone from the script on purpose: "It is done" and "It did not give her back" ("He never says what he feels").

**Pays off from earlier / plants for later:**
- Pays S1, the faded red shirt: named at the camp, plain to see as he runs. [D]
- Pays S10, which way he rode. [D]
- Pays S45, "Does it do anything?" → "See what your badge does." → the platform, "where it does nothing". [P·bible]
- Pays night one: the cowboy knows Harlan sat at the table or carried Earl; Kett offers to sell who the stranger
  is; Joe has heard whether Harlan carried the sheriff or walked past him. [P, script callbacks]
- Plants S11, the doctor's warning → the release ("Doc told us."). [D]
- Plants S12, Joe's disguise → who the kin come for; and I Am the Law, where being seen feeds the Baron's story.
  [D; last step P·bible]
- Plants S19, the released man → Joe kills him on Main Street; the rope. [D]
- Plants S6, Rourke: the platform is his side's first sighting (arrest ending only). Hole: a player who took
  revenge never sees the platform; a second plant is "needed". [D + P·bible]
- Plants S37, the outbreak that wasn't: the costume makes the revenge "a white man's quarrel". [D that the raid
  was provocation; plants P·bible]
- Plants S38, Harlan's past: Kett on his knots, "The Army?" [P·bible]
- Plants S47, the hat comes off before Joe speaks to Kett; S48, Cañon City (Cody in the same cell later expects to
  walk too). [P·bible]
- Plants K4, who sent them: Kett offers it and never says it. [P, script]
- After it: the rope (`joe-on-the-rope`), once Harlan has the rifle [D, 2026-11-04]; Cody's arrest in the saloon
  [D, C6 b]; the Colters hired for the farm [D, C5 b].

**Every other idea found:**
- DESIGN "The camp" (P, Sean 2026-10-06; replaced): "bandits killed and violated women at a camp of a real
  nation"; the people "not of one mind: a war leader wants every bandit dead, an elder fears the army will come
  down on the camp if white men die, a husband wants only the man who did it"; "They send trackers"; "The town's
  leaders want an arrest and quietly let you know nothing will come of it." [Superseded by sean-card]
- DESIGN's three ways out: kill them all; arrest them ("The leaders fine them and run them out of town: no
  justice"; "a standoff on the way" with the warriors); take them past the town to the circuit judge or a US
  Marshal ("the hardest-won ending in the game"). [Superseded: the third "dropped on purpose"]
- "The women described one man by a hat nobody else wears". [Superseded by the red shirt]
- "a bandit surrenders with his hands up and a young warrior moves first; one of the bandits wasn't there that
  night; the man in the hat may be the one who surrenders." [P, DESIGN; not in sean-card]
- The scalp hunters' trade: scalps drying on a line, "Mexican as well as Native, to be sold south for the bounty
  as 'Apache'"; the women's scalps among them, brought home for burial; evidence "any court or marshal can't wave
  away"; a tie to the Mexican rancher's people. [P, Sean 2026-10-06, DESIGN; O on the card: "Kept, or dropped with
  the third ending?"; not picked as the raid's reason, C4 c]
- "maybe the army or the agent comes asking." [P, DESIGN]
- "The camp" as "the big one, a day and a half", on days 4–6 of a ten-day shape. [P, DESIGN, Sean 2026-10-15;
  the day count is gone]
- How you hear of it, older: "Word reaches town" [DESIGN]; "sent to Joe's camp" [#738]. [Superseded by the
  doctor's office, itself flagged]
- #546's reading of the nod (the other way round). [Superseded by sean-card: nod = stop Joe]
- Why the raid: (b) "Kett off the leash": the Baron ordered only the sheriff shot and the crew did the camp on
  their own. [not picked, C4 b]
- The red shirt as the Baron's hired gun who also shot the sheriff. [D 2026-11-09; the second half Superseded
  2026-11-13]
- "the man in the red shirt is first seen on the first night in the saloon". [D 2026-11-09; Superseded
  2026-11-11]
- Cody "among the six at the cabin"; taken alive there (C6 a). [P, a session; the script's reading says no]
- The saloon killer "is the prisoner waiting for the morning train on the Water Tower night". [P → D as C7 c]
- "The town gets its hanging and Joe gets nothing: No Justice in one picture." [P, a session, card]
- Judge run 1: cut the bold cowboy from the doctor's office (not picked). Idea 3's rest: "His flight is his nerve
  breaking rather than a scripted run: if the cabin is cut off he goes for a horse, and an escaped red shirt
  becomes a man on the road." (taken or not: O). "His memory of Harlan sets how he behaves when they meet in
  town." [judged]
- Judge run 2, none picked: the arrest gains something revenge throws away (Kett offers what he knows; "Joe's
  knife ends that lead for good"); more than one approach (from the creek, from above, after dark); the news of
  the raid reaches Harlan more than one way (a rider from the camp, the saloon owner's rumour); "a county court or
  grand jury that declines to indict"; cut "Joe dies trying": he finishes it alone, comes back wounded, "and
  remembers who left". [P, judged]
- Judged-story's order: `store-robbery` before No Justice; `hold-him` "as the arrest ending's night" with the red
  shirt as the prisoner. [P; Superseded by Cody]
- The release, other ways: the county lets him go and Rourke only stands by (C8 b); he slips his escort (C8 c).
  [not picked] "to check: United States v. McBratney, 1881"; an Army escort from Fort Lewis to the U.S.
  commissioner. [P]
- "Rourke, or his officer" on the platform. [D 2026-11-09] vs "Rourke's officer". [C8 a, P]
- Who names Kett: "the Kid, or Rourke on the platform". [O]
- Kett "can sell the foreman, and never gets to". [P·bible, OUTLINE]
- Kett has been in the state prison at Cañon City. [P, script]
- One slur is allowed to Kett "at a moment that matters" (C13 b, D); the script marks `cabin.bargain` and writes
  it without the word: "Sean decides whether it gets one". [O]
- Joe: English is his third language after Ute and Spanish; "not broken, not grand". "Not stately". [P·bible,
  VOICES/WORDS]
- Joe's wife: "She shot better than I do." Her mother is alive. They "shot the dogs first". The men were "four
  days out, after elk". [P, script]
- Joe "doesn't know that's what the raid was for". [P·bible]
- "Joe's leg, dressed by the same hands". [P·bible, SETUPS E]
- "a companion who keeps quiet with you", and "the bandits' tracks on the ground": neither on Sean's list. [P, a
  session]
- The hideout as built: on valley.json's `hideout` pad (-450, 2020), a line shack 4.2 by 5.0 m, a fire, props,
  horses; the red shirt is "a stand-in shirt colour". [built]
- A candidate place once: `abandoned_homestead` (-860, 330). [P, MAP]
- In the built cabin a small or slow nod is asked about only on "the loose reading". [built]
- Systems list from sean-card with what exists: surrender partly; the knife new (PR #167 has a start); the jail
  and transfer new; "a news item later" new. [card]
- "the camp's own witnesses might not be heard in court" (1882). [sean-card]
- Length "25–35 minutes"; judge scores 22/35 then 24/35. [sean-card; judged]
- ChatGPT's Hanging card on Joe: "recognizable cowboy disguise and worn hat"; "No Justice is the finished example
  and is not rewritten in this package". [P, chatgpt]
- If the red shirt had died in No Law, "Joe's storyline needs an alternate route involving the surviving
  attackers". [P, draft; no longer applies]

**Where the sources disagree:**
- **Where and when Harlan meets Joe.** Sean's card: the doctor's office. Sean the same day: "gotta be flagged". No
  Law's day 2 has no Joe. s3's readings: Joe brings a wounded survivor in the day after the funeral / Harlan is
  sent to the camp (#738). Built: the doctor's front office, late morning the day the sheriff died, as "a
  stand-in". Unsettled.
- **Before or after the funeral.** OUTLINE and DECISIONS put the funeral first. The build starts No Justice the
  day the sheriff died; the funeral is the day after. Unsettled.
- **Two endings or four.** Sean's card: "two endings, not three" (arrest, revenge), with the murder and the kill
  outside as ways it bends. The build and the bible count four endings. Same content, different counting.
- **Who the red shirt is.** 2026-11-09: he kills the cheat, shot the sheriff and killed Joe's wife. 2026-11-11:
  not the cheat's killer. 2026-11-13: not the sheriff's. Latest: Silas Kett, the camp raider only.
- **Where Joe's camp is.** Sean's card: "north-west of town". `valley.json` (`ute_community`, -1350, 1230; the
  lock and #700): the sheltered south-west. The build uses the map's. s10's reading: "The map's". Not Sean's word.
- **The hideout.** Sean's card: "a secluded wooded spot in the foothills, with a main cabin on rising ground". The
  lock: the valley is "not a forest". Built: a line shack on the `hideout` pad in the south, which the card says is
  the Colters' box canyon. Unsettled whether Kett's crew and the Colters share a place.
- **"If a bandit escapes"** (D 2026-11-09, the disguise) vs "the cabin finishes Kett's crew" (D 2026-11-11, C5 b).
  The bible's fix (f19, P·bible): the man who gets away is the one who tells the kin.
- **Is Cody at the cabin?** Cards (P): one of the six. C6 b (D): arrested in the saloon after the funeral. Script
  (P): not at the cabin. Unsettled until Script OK (s24).
- **Kett's gun.** Sean's card: "cornered, frightened and unarmed" in the cabin. Built: he has no gun at all, even
  outside, and bluffs through the door that he has.
- **The bold cowboy.** Sean's card has him agree with the doctor. Inventory had "a bold cowboy" as the saloon
  killer. Sean 2026-11-11: "not the murderer - I'll find something else for him". His model plays Brody Colter in
  the farmhouse. The judge's cut of him was not picked. Unsettled (s4, M8).
- **Who lets Kett go.** Sean's card: "handed on to the proper authorities". Sean 2026-11-09: Rourke or his
  officer, on the platform. C8 a: a federal paper, P until Sean nods. Unsettled in detail.
- **Rourke for a revenge player.** Sean: "we need rourke to come no matter what". No source says how. O.
- **Joe's death.** Sean's card: down, not dead, in the fight; whether he "can truly die here" O. Abandoned: "dies
  trying" (card) vs the judge's cut (not picked).
- **Joe's first answer line.** Built "Then we go now." vs script "Good. Get your horse." The second assumes Harlan
  has a horse, which no source settles.
- **The joe-on-the-rope card has the nod the wrong way round** (f1) and has the released killer leading the
  lynching though Joe has killed him (f2). [CONTRA Part D]

**Open questions:**
- Where and when Harlan meets Joe (s3).
- The bold cowboy: who he is, and whether he stays (s4).
- Whether Joe can die in the fight; what follows if Harlan abandons him.
- The rope's cause if Harlan murdered Kett (s1); the rope if the disguise is broken in the revenge ending (s2).
- C8 a: Sean's nod on who releases Kett and by what right; the law to check.
- How Rourke is met in the revenge ending.
- Who names Kett.
- Whether Kett gets a slur at the cabin.
- Whether the rest of the judge's idea 3 (his nerve, a horse if the cabin is cut off) is taken.
- The scalp hunters' trade: kept or dropped.
- Where the hideout is, and its woods.
- Joe's own name; a Southern Ute speaker for the camp; Joe's past (timber and trains).
- Whether Harlan has a horse by now.
- The jail, the cell days, the platform and Kett on Main Street: all still to build.
- Sean's Script OK on the No Justice page.

---

## Ideas with no mission

From the sources read for these three; each belongs to no card in this reader's list.

- Cody's arrest: after the funeral he walks back into the saloon, "bold as before", and Harlan, now with the
  sheriff's revolver, arrests him: "the answer to night one". It has no card of its own. [D, Sean 2026-11-11,
  #830, C6 b; OUTLINE] A third way offered: on a coroner's warrant, "a small mission of its own" (C6 c, not
  picked).
- The stranger's built gun lines ("Easy, friend. I ain't the one you want." and two more) wait for "the first time
  you meet him with the sheriff's revolver in your hand". No scene is named for it. [script:nolaw; CHANGES.md]
- The foreman needs a `foreman.fate` fact every later card reads. [P·bible, CONTRA f6]
- A third plant for the Baron's want, for a player who skips the funeral and the widow. [O, SETUPS S3]
- Harlan's spring: the Baron admires it at the grave; "nobody ever asks for it" on any card. [P·bible S49; s14, M6]
- A second plant for Rourke for players who took revenge: the Baron's coach meeting an officer off the train, or
  the barkeep selling "the Baron had a soldier to supper". [P·bible, SETUPS S6]
- The depot agent and the Baron's wires east about "Indian trouble". [P·bible, S37]
- Whether Harlan is ever sheriff. [O, Sean 2026-11-09: "I don't know if we become sheriff ever in the game."]
- Who the county names as the next sheriff, and whether the Baron tries to choose him. [O s27; P·bible]
- The evidence and the trial: "a maybe" (Sean 2026-11-09); then evidence "is a system" and no courtroom
  (2026-11-11, OUTLINE). The ball is not evidence.
- "The Inquest / sheriff murder storyline: the circumstances surrounding the sheriff's shooting remain available
  for later investigation." [P, draft]
- The opening as "one larger opening mission rather than three separate missions". [inventory]
- "Early train encounter: Harlan travels under the small railway overpass during one or two early missions,
  establishing the landmark before the payroll train sequence." [inventory, "Other proposed set pieces"]
- Harlan has no horse at the start; the widow gives him the sheriff's horse with the rifle. [P, Sean's maybe]
- Harlan's rare spoken lines: "Now what the hell is going on here?" (Sean's example, 2026-11-07, for the train);
  "There's law in Salt Creek. You're looking at it." ("only if Sean wants him to say it"). [VOICES]
- "One of them 'knows' the player": a Colter says "I know you." No card uses it. [DESIGN §5, §6; M9]
- The railroad land agent ("Vale", forged deeds): in DESIGN's cast, on no card; the bible reads him as dropped.
  [s18]
- The drama manager; the journal in Harlan's own words; "Many endings, none written in full" (marry the widow,
  ride with the Colters, sell the spring). [DESIGN §5; the widow romance is ruled out, D 2026-11-03]
- "Owners care about their own things first" as a rule for every owner (the storekeeper's window, the doctor's
  lamp). [Sean, showcase-moments]
- "Idea 2, the town's gun law that nobody enforces." [P, a session; not picked]
- The barkeep "sells what he saw"; whether he knows the stranger for the Baron's foreman is "the script's". [VOICES]
- Dead Man's Crossing, The Missing Ranch Hand, Blood on Main Street (the other three "potential demo missions"
  beside A Quiet Drink), and the inventory's Part 3 names (The Last Telegraph, Mill of Teeth, Runaway Coach, The
  Night Salt Creek Burned, Stolen Creek, High Wire, The Hanging, The Railroad Men, The Fever, The Cattle War, The
  Missing Stagecoach, The Bank Is Empty, The Long Winter, The Man Who Wasn't There, The Election, The Siege of Salt
  Creek): "not current approved missions". [inventory; three-gunmen brief]
- The inventory's worry: "My biggest concern is the middle of the game... not enough connecting story". And its
  flag: "We subsequently considered making her and the children Harlan's own family instead." (Since answered:
  "Yes the children are the sheriffs / widows kids", Sean 2026-11-09.) [inventory]
- ChatGPT's cards hold no card for these three missions. Its Hanging card starts "from either No Justice outcome"
  and belongs to `joe-on-the-rope`. [chatgpt]
- Script housekeeping that touches story: "howdy" is sparing, "Hello" allowed as a hail (s28); the scripts lead
  and the game's lines follow (s29). [CONTRA Part D]
