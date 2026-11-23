# Mission ideas, the full record: %s

Part of `docs/story/MISSIONS.md` (read that first). Gathered 2026-11-17 by a reader sub-agent from every source: the mission cards on PR #743's branch, Sean's own files in `docs/missions/sources/`, the proposals, the story bible, DESIGN.md and what is built. **Nothing here is a decision unless it is marked D with Sean's date.** Not yet checked line by line by the story session; where it disagrees with `OUTLINE.md` or `CONTRADICTIONS.md`, say so in a note rather than fix it silently.


Reader 3 of 5, 2026-11-17. Missions: `buried-alive`, `demolition-mentor`, `farmhouse-rescue`, `vaqueros-horses`,
`dry-creek`, `kid-wants-out`, then **The Colters (T6)**, then **Ideas with no mission**.

Short source names used below:
- **card** = `docs/missions/<slug>.md` on branch `claude/planning-missions-cards-mwdo42`; **v2** =
  `docs/missions/proposals/farmhouse-rescue_v2.md`; **inventory** = `sources/inventory_2026-11-09.md` (sent by Sean:
  "And this is the tentative mission layout"); **ChatGPT** = `sources/chatgpt-cards_2026-11-09.md` (everything in it
  is only PROPOSED); **no-law draft** = `sources/no-law_draft_2026-11-09.md`; **judge** = `judged/2026-11-09.md`;
  **story judge** = `judged/2026-11-09_story.md`; **setpiece judge** = `judged/2026-11-09_setpieces.md`.
- **bible** = `docs/story/` (OUTLINE, SETUPS, VOICES, WORDS, CONTRADICTIONS, README). **P·bible** = proposed by the bible.
- **DESIGN** = `DESIGN.md`. **built** = `src/missions/*.gd`, `config/farmhouse.tres`, `docs/LAYOUT.md`.
- Issue numbers (#520, #546 ...) are quoted as the cards quote them; I did not open the issues.
- "The lock" = Sean's design lock of 2026-11-03 as PR #621 (`docs/briefs/widow-farmhouse.md`, unmerged) records it,
  quoted through the farmhouse card. I did not read PR #621 itself.

Status words: **D** decided by Sean, **P** proposed (whose), **O** open, **Superseded**.

---

### Buried Alive (`buried-alive`)

**Where it sits:** Act II, "learning the valley" [P, inventory Part 4: "a working sequence, not a locked mission order"].
After No Justice, before the Demolition Mentor and before any dynamite breach at the farmhouse [D, inventory +
the lock, as OUTLINE "Act II" reads them]. Otherwise no fixed order in Act II [bible, OUTLINE]. Not built: no file in
`src/missions/`, no moment in `config/moments/`. The place exists as data only (`config/valley.json`: `mine`,
`ore_works`, `powder_magazine`, mission `buried_alive` "DECIDED (the mine supports it)").

**In one line:** Men are trapped in the silver mine after a blast or collapse; Harlan goes in to get them out, and
learns dynamite from a miner while doing it.

**Harlan walks in with:**
- Gun: not stated by any source for this mission. By the story's order he has the sheriff's revolver from day 2
  [D, Sean 2026-11-17, this session, item 2] and the sheriff's Winchester only if he has ridden to the widow's [D, Sean
  2026-11-09, `widows-place` card].
- Badge: deputy since day 2 [D, Sean 2026-11-17, this session, item 4]. The miner calls him "Deputy" [P·bible, VOICES].
- Horse: not stated. (The sheriff's horse is Sean's "maybe" at `widows-place`.)
- Dynamite: none. "dynamite is introduced in Buried Alive, not the opening" [D, inventory, continuity constraints].
- Companion: not stated. Joe is "the only full companion" [D, inventory]; no source puts him in the mine.
- Wounds: not stated.
- What he knows: he is a former army hospital steward [D, DESIGN §6; STORY.md]; the mission "Uses structures,
  dynamite and first aid" [P, DESIGN §5 mission 6].

**How he hears of it:** O: "no source says" [card]. Candidates, none decided:
- The mine's whistle "blowing off its hour, heard across the valley" [P·bible, OUTLINE Act II; SETUPS M5].
- "the mine whistle across the valley, a dust plume over the bench seen from town, the doctor called away, miners'
  wives at the store" [P, judge, "Beef it up" 2].
- The town's calendar (#276) has a mine whistle, "a candidate the sources don't tie to it" [card].

**Beats, in order:** (no source gives a numbered beat list; these are the statements that exist, in the order they imply)
1. A collapse traps miners underground. [D, inventory "5. Buried Alive · Approved"]
2. It follows a blast: "Men are trapped in the mine after a blast." [P, Sean 2026-10-06, DESIGN §5 mission 6]
3. Harlan enters the mine to rescue survivors. [D, inventory]
4. Underground there are "failing supports, blocked passages and environmental danger". [D, inventory]
5. "Gas, timbers settling, the wrong charge brings the rest down." [P, DESIGN §5]
6. "A knowledgeable miner becomes important to the mission." [D, inventory]
7. The player is introduced to dynamite "through a practical rescue problem". [D, inventory]
8. Harlan can "Dig, shore, or blast a way in with what the miners teach you". [P, DESIGN §5]
9. Meanwhile "the mine's owner counts what it'll cost to stop work". [P, DESIGN §5]
10. The miner gives Harlan single sticks. [D, Sean 2026-11-04, #546 as the card quotes it: "Single sticks earlier
    (from the miner), bundles at the end."]

**Choices, and what each sets:**
- Dig, shore or blast [P, DESIGN]. The big choice is O: "no source names the choice beyond the rescue against the
  owner's cost" [card].
- Facts proposed: `dynamite.level` (none / single sticks / bundles) and `miner.alive` (yes / no) [P, planning
  session, `DECISIONS.md`]. `miner.alive = no` leaves "who teaches" O (`DECISIONS.md` gap 4; bible s8).

**Endings, and what it leaves in the world:**
- Dynamite is unlocked as single sticks [D, 2026-11-04, #546]. "teaches dynamite" [`valley.json`].
- "The miner becomes a source of sticks." [P, card]
- "Creates an opportunity to show the human cost of Salt Creek's mining industry." [D, inventory]
- Nothing else is stated. The judge: "this card carries only an unlock" [judge].

**Who is in it:** Harlan; trapped miners; "a knowledgeable miner" (no name: roles only, D, Sean 2026-11-11, C14 c);
the mine's owner [P, DESIGN]. Joe: not stated.

**Sean's own words:**
- Inventory, 2026-11-09 (sent by Sean; `sources/inventory_2026-11-09.md`), "5. Buried Alive · Approved":
  "A collapse traps miners underground." "Harlan enters the mine to rescue survivors." "Introduces an underground
  rescue sequence with failing supports, blocked passages and environmental danger." "A knowledgeable miner becomes
  important to the mission." "Introduces the player to dynamite through a practical rescue problem." "Creates an
  opportunity to show the human cost of Salt Creek's mining industry."
- Inventory, same: "Development note: Earlier proposals included the mine owner knowingly removing supports, but
  that particular conspiracy has not been approved."
- Inventory, continuity constraints: "dynamite is introduced in Buried Alive, not the opening".
- DESIGN §5 story mission 6 ("**proposed**, Sean 2026-10-06"): "**The cave-in.** Men are trapped in the mine after a
  blast. Gas, timbers settling, the wrong charge brings the rest down. Dig, shore, or blast a way in with what the
  miners teach you, while the mine's owner counts what it'll cost to stop work. Uses structures, dynamite and first aid."
- #546, Sean 2026-11-04 (as the cards quote it): "**charge sizes as progression.** Single sticks earlier (from the
  miner), bundles at the end. A bundle opens walls a single stick can't."
- #542, Sean 2026-11-01 (as the card quotes it): "Dynamite only comes later in the game (the miner, midgame)".
- #542, Sean 2026-11-01: "maybe a **gold** mine". #552, Sean 2026-11-04: "**Call 3 (the mine): B, silver.**"
- DESIGN §13 open questions: "**Mine:** what it's for (silver? a collapse? the gang's hideout?)."
- DESIGN §8 (Sean, 2026-10-28): dynamite "Lights nothing itself".

**Lines of dialogue anyone gave:** none built, none scripted. P·bible, VOICES "The miner":
1. "Powder don't forgive and it don't hurry. Nor should you."
2. "Half a stick for a door. A stick for a wall. A bundle when you want the hill to come too."
3. "Hear that? That's the timber talking. When it stops talking, you run."
4. "Cut your fuse long. A man's legs are shorter than he thinks."
5. "Fire in the hole!" (to check: `WORDS.md`)

**Pays off from earlier / plants for later:**
- Pays off: Harlan the hospital steward (crushed men, first aid) [P, card systems; judge].
- Plants S9 "Sticks, then bundles" [D]: the farmhouse breach, the balcony, the trestle, the Baron's wall [bible, SETUPS].
- Plants S28 "Timber sets" [the Sap is D, the link P·bible]: "The miner shows him how a set of timbers holds rock up,
  and what happens when one is knocked out. Payoff: the Sap. The Baron's wall stood on props, and Harlan pulls them."
- Plants the miner as a later voice: he "may propose the Baron's coach trap ('Someone (Joe, or the miner)')" [P, #546
  comment 2026-11-04]; he "knows how to dig and shore a gallery" for the Sap [P, `proposals/setpieces_2026-11-09.md`].
- T3 in one line: "the rescue → sticks → lessons → bundles → the trestle, and the Sap's props" [bible, OUTLINE].

**Every other idea found:**
- Other names: "The cave-in" (DESIGN), "the mine rescue" (#546 threads) [card].
- The mine is silver [D, Sean 2026-11-04, #552]. Gold [Superseded, Sean 2026-11-01 "maybe"; replaced by silver].
- The mine as "the gang's hideout" [P as a question, DESIGN §13; never taken up].
- The mine owner knowingly removed supports [P, "earlier proposals"; "has not been approved", inventory]. VOICES
  repeats: the miner knows "What the owner saves money on" but the sabotage "is **not** approved".
- Place: `mine` (-1720, -790), pad y 79, "a hoist-less adit mine (no head frame needed)", powder magazine "set apart
  up the gulch", a blacksmith shop, ore house, bunkhouse, waste-rock dumps [D place / P exact, `valley.json`].
  `ore_works` (-1530, -275); `powder_magazine` (-1800, -850) [P].
- "Room for the Buried Alive rescue: the adit, the slope over it, the dumps, the yard." [P, valley-plan §8, via card]
- An old discovery shaft kept as the air shaft, its 12 m headframe "the mine's one height" [P, #736 B, `valley.json`].
- The mine road crosses the arroyo on "a log-cribbed fill over a culvert (a flash flood can take it out)" [P, `valley.json`].
- The Ore Works ships "Silver ore by the carload to a smelter" [#552 call 3 B, `valley.json`].
- Cost for the player: "the quickest charge risks bringing down the working the mine's season (and the town's payday)
  depends on; shoring is safer for the ore but slow while the trapped men's tapping thins" [P, judge].
- "a crushed man who can only be got out by amputation in the dark (Harlan the steward)" [P, judge]; the card's
  systems line: "Crushed limbs, first aid, the amputation moment: partly (treatment lab)".
- "At the adit the magazine and the drilled face show the dynamite route plainly, even if the miner is dead." [P, judge]
- World keeps it: "the fall's rubble and any opened or sealed drift stay; the dead buried at the yard; the rescued and
  their families hold opinions of Harlan; the owner remembers what Harlan's choice cost him." [P, judge]
- "The sets talk: caps split and posts bow from their own load, so the player sees which set goes next and shores it
  before he blasts." [P, setpiece judge]
- "The single stick's believable partial: a crawl hole frees one man but not the one pinned under a cap; a second
  stick, or dig." [P, setpiece judge]
- Cut the gas [P, judge and setpiece judge: "a new system used only here, its truth in a silver adit unchecked"].
- Say "bad air" and "powder smoke", not gas [P·bible, s16; WORDS "Miners"].
- Miners say "giant powder", "giant", "powder", not "dynamite"; "caps and fuse", "a shot", "the face", "the drift",
  "the adit", "sets", "muck", "single jack"/"double jack" [P·bible, WORDS, with refs].
- The miner "Maybe Cornish (O)"; "Cousin Jacks"; "a 'my son' or two is enough" [P·bible, VOICES, WORDS].
- A miner sits at the No Law card table: "Fifties, a hard-rock man, slow and heavy, a little Cornish"; his line over
  Earl: "He were cheating, my son, a dollar at a time, same as ever he did." [script, `docs/scripts/no_law.json`
  `after.miner`, "new"]. No source says he is the miner of Buried Alive. A "miner" also stands at the funeral
  (`config/moments/funeral.json`, borrowed townsman).
- Teaching "as how the player learns (signature 8: dynamite unlocked by being taught, not a menu)" [P, `BUILD_ORDER.md`].
- An "underground lab" should start a step ahead: "the adit holding and failing by its sets, gas, digging under rock" [P, `BUILD_ORDER.md`].
- Scores: judge 19/35 (Discoverable 1, Cost 2); setpiece judge 3 (low), "Risk: high".
- Story judge: "The worst: Buried Alive's underground digging and gas, one mission's system that dynamite's
  introduction depends on."
- DESIGN §8 dynamite uses: "collapse a mine entrance"; DESIGN §10: "dynamite lives in the mine's powder magazine".
- DESIGN "Work that pays in lead": "clearing the gang's hideout or the mine" [D 2026-10-01 list; no card uses the mine part].
- DESIGN §8 rope: "rescues from the creek or a mine shaft".
- Inventory "other proposed set pieces": "Mine pumping: Use operating machinery and water systems during an emergency." [P, brainstorm]
- Old ten-day shape placed "the cave-in" on Days 4–6 [Superseded, DESIGN "Story shape", Sean 2026-10-15; the day
  count was replaced 2026-11-01: "The story doesn't advance until it should advance."].
- ChatGPT: "Buried Alive, demolition training ... need Sean's own mission notes before being promoted ... Do not
  invent their story and call it approved." ChatGPT wrote no card for it.
- "the miner notices his powder bought by someone else", as one way the town hears the last train is coming [P, judge on `the-bridge-is-out`].

**Where the sources disagree:**
- A collapse (inventory) vs "after a blast" (DESIGN). Not a hard conflict; unsettled which words stand.
- Gold (Sean 2026-11-01) vs silver (Sean 2026-11-04). Latest word: silver.
- "Gas" (DESIGN) vs cut it / "bad air" (judge, bible s16). Unsettled; Sean has not said.
- "no head frame needed" (`valley.json`) vs "the mine headframe" as a place with height (#736 B). Unsettled; the
  P reading is an old shaft's frame kept as the air shaft.
- The owner: "counts what it'll cost" (DESIGN, P) vs deliberate sabotage (not approved, inventory).

**Open questions:**
- How Harlan hears of it. What the big choice is. What it costs.
- Who the miner is, why he is "important", whether he can die, and who teaches if he does (gap 4, s8: "Another
  miner / his notes and the magazine", P·bible).
- Whether Joe comes. Where the owner is and what he does afterwards.
- Whether gas (or bad air) is in. Whether digging rock underground gets built.
- Whether the miner at the No Law table is this miner.

---

### The Demolition Mentor (`demolition-mentor`)

**Where it sits:** Act II, after Buried Alive [D, inventory "Approved progression"]. "This may be a series of optional
activities instead of a dedicated story mission." [P, inventory]. Not built as a mission. The tools it teaches are
built: single sticks, planted charges, bundles of four, the plunger box (#506, #647, #648, per the card). Half-sticks: not built.

**In one line:** After the rescue, an experienced miner teaches Harlan more: half-sticks, linked charges, bundles.

**Harlan walks in with:** single sticks from Buried Alive [D, #546]. Gun, badge, horse, companion, wounds: not
stated (as Buried Alive above). He knows the miner from the rescue [D, inventory: "Following Buried Alive"].

**How he hears of it:** "it follows Buried Alive; the miner from that mission teaches" [D, inventory, per card]. Why
he teaches (thanks, pay, his own reasons) and where: O [card].

**Beats, in order:**
1. "Following Buried Alive, an experienced miner teaches Harlan more sophisticated demolition methods." [D, inventory]
2. "Progression includes basic dynamite, half-sticks, linked charges and larger explosive bundles." [D, inventory]
3. Bundles come "at the end". [D, Sean 2026-11-04, #546]
4. No other beat exists in any source. What a lesson is: O ("blowing a stump, a rock face, an old shack?", card).

**Choices, and what each sets:** none named [card]. Sets `dynamite.level` [P, `DECISIONS.md`].

**Endings, and what it leaves in the world:**
- "More advanced techniques provide new options during later missions." "Relevant to the farmhouse rescue, balcony
  ambush and trestle finale." [D, inventory]
- "Training should expand the player's capabilities rather than artificially lock missions behind upgrades." [D, inventory]
- "A bundle opens walls a single stick can't." [D, Sean 2026-11-04, #546]

**Who is in it:** Harlan; the miner ("an experienced miner"). Nobody else named.

**Sean's own words:**
- Inventory, 2026-11-09, "6. Demolition Mentor / Explosives Training · Approved progression": "Following Buried
  Alive, an experienced miner teaches Harlan more sophisticated demolition methods." "Progression includes basic
  dynamite, half-sticks, linked charges and larger explosive bundles." "More advanced techniques provide new options
  during later missions." "Relevant to the farmhouse rescue, balcony ambush and trestle finale." "Training should
  expand the player's capabilities rather than artificially lock missions behind upgrades." "This may be a series of
  optional activities instead of a dedicated story mission."
- #546, Sean 2026-11-04: "**charge sizes as progression.** Single sticks earlier (from the miner), bundles at the
  end. A bundle opens walls a single stick can't."
- #542, Sean 2026-11-01: "Dynamite only comes later in the game (the miner, midgame)".
- DESIGN §11 signature 8 (D, Sean 2026-10-01, "Ya!" to all): "**Teaching people.** The skills you learn from people,
  turned round: teach the Kid to shoot or the widow to dress a wound; it saves your life later, or he uses it against you."

**Lines of dialogue anyone gave:** P·bible (VOICES, the miner), as under Buried Alive; the one that is a lesson:
"Half a stick for a door. A stick for a wall. A bundle when you want the hill to come too."

**Pays off from earlier / plants for later:**
- Pays off Buried Alive (the miner, single sticks).
- Plants: the farmhouse breach, the balcony ambush, the trestle, the Baron's wall [D, S9]; the Sap's props [P·bible, S28].

**Every other idea found:**
- Other name: "Explosives Training" [inventory].
- "`demolition-mentor`, spread out as real jobs" [P, story judge, suggested order]; "the Mentor risks being a tutorial
  unless its lessons are real jobs" [story judge].
- "the stick-under-the-posts version [of the Balcony Ambush] becomes one of the Demolition Mentor's lessons" [P, judge on the balcony].
- "Teaching dynamite overlaps strongly with the Demolition Mentor" [judge on Buried Alive].
- "What the player knows unlocked by being taught, not by an upgrade screen: new." [P, card systems]
- Half-sticks need "cutting a stick": new [card]. Linked charges exist: "the plunger box fires a tick apart, #648" [card].
- Place: the `mine`, its `powder_magazine`, the `ore_works` [P, card; O].
- Opens "After Buried Alive, if the miner lived (if he died: O)" [bible, OUTLINE].
- Setpiece judge on the farmhouse: "Cut: anything past one stick (a ring or a bundle breaks the frame and kills the
  person the mission is about)" [P]: a limit on what the Mentor's bundles are for at the farm.
- The card was "Checked against the story bible (2026-11-14): nothing here has changed."

**Where the sources disagree:**
- A mission, or "a series of optional activities" [both in the inventory]. Unsettled.
- Inventory's four steps (basic, half-sticks, linked, bundles) vs #546's two (sticks, then bundles): "not a conflict,
  more steps" [card].
- "expand ... rather than artificially lock" (inventory) vs the lock's breach only "once demolition has been taught
  elsewhere" (farmhouse) and `dynamite.level` gating [P]. Not flagged by any source as a conflict; noted here.

**Open questions:** what the lessons are; where; why he teaches; who teaches if the miner died; one mission or
scattered activities; whether half-sticks get built.

---

### The Farmhouse Rescue (`farmhouse-rescue`)

**Where it sits:** Act II [P, inventory Part 4: after Buried Alive and the Demolition Mentor]. The bible: "it can come
any time after day 2" because "The widow refused the Baron at the funeral" [bible, OUTLINE]; the dynamite breach only
after Buried Alive [D, the lock + inventory]. `widows-place` (the peaceful visit) comes before it [D, the lock: "Order:
the peaceful visit, then the hostage crisis"; D, Sean 2026-11-09, visit is its own mission].
**Built** (the first mission in the game): `src/missions/farmhouse.gd` (`Farmhouse`), `farmhouse_mission.gd`
(`FarmhouseMission`), `farmhouse_tuning.gd` + `config/farmhouse.tres`, `house_defence.gd` (`HouseDefence`),
`hostage_brain.gd` (`HostageBrain`), spec `config/buildings/farmhouse.json`. Built with **the rancher** as hostage,
started by **the blacksmith**; in the valley it stands on the widow's pad (G6, #731, PR #741, build 3574) and starts
when you come within 300 m. The widow as hostage, the foreman, the deed, the boys, Blue: **not built**.

**In one line:** The Colters, hired by the Baron, hold the sheriff's widow in her own house until she signs her water
right over; Harlan gets her out by the front, the back, a planted stick, by stopping the foreman, or lets her sign.

**Harlan walks in with:**
- Gun: not stated in any card. Built: "they warn you off first if your gun is away" (so he has one). By the story:
  the sheriff's revolver from day 2 [D, Sean 2026-11-17]; the Winchester if he visited the widow [D, Sean 2026-11-09].
- Badge: deputy [D]. Built idle line (the Kid): "You reckon they'll send the law?"
- Horse: not stated.
- Dynamite: only if Buried Alive is done: the breach "once demolition has been taught elsewhere" [D, the lock]. In
  the built mission dynamite is available from the start [built; card "breach timing"].
- Companion: O. "whether Joe comes" [O, #622]; `DECISIONS.md`: without Joe "Harlan alone · covered"; ChatGPT:
  "Joe: companion if alive and mission is after No Justice" [P].
- Wounds: not stated.
- What he knows: if he made the visit, the back door, the kitchen, the yard and outbuildings; Blue and the boys know
  him [D, Sean 2026-11-09 + the lock; S16, S17]. If he sat with the stranger on night one, he knows the foreman's face
  [D that it is one man, C10 b; S39]. If he listened to the sheriff, he knows "friend" and the bald-faced sorrel
  [D, C16 a; S40]. Not visited: "a stranger to all three" [D per `DECISIONS.md`/S16].

**How he hears of it:**
- Built: "walk up to the blacksmith by the livery before the gang rides in" [D built, #520]. In the valley: by coming near.
- She isn't at the store on her day; the storekeeper says so [D, Sean 2026-11-09, v2 "build now"].
- A rover drinks in town and talks ("tells", not "sells") [D, v2 "build now"].
- The men's own talk about the foreman can be overheard on site [D, v2 "build now"].
- Blue runs to town alone and barks [Superseded as a way to hear: cut by the build check; Blue stays in the design].
- The daily train's crew sees armed men in her yard; the depot agent hears it [P, v2; "later", needs G6 and news passing].
- "A child, neighbour or passing wagon driver reports men refusing to let anyone approach"; or Harlan rides past and
  sees guards [P, ChatGPT].
- "the peaceful visit ... the offer replaces the blacksmith start" [P, PR #621 step A6].
- The foreman "seen in town having the paper drawn up and asking the way (the saloon owner sells it)" [P, judge on v2, not picked].
- "From the overpass, pen and ink set on her table in the window and a saddled horse at the lane's foot" [P, judge on v2].

**Beats, in order:**
1. Earlier, at the funeral, the Baron quietly offers to buy the widow's claim; she refuses. [D, Sean 2026-11-09: "I
   like the baron offering to buy"; card]
2. Earlier (if played), Harlan rides the sheriff's horse to her place, meets Blue and the boys at play, sees the stakes
   at her ditch and the ways in, and is given the rifle. [D, Sean 2026-11-09, `widows-place`]
3. The cabin (No Justice) has finished Kett's crew, so the Baron hires the Colters to hold her farm. [D, Sean
   2026-11-11 "B it is", #830, C5 b]
4. Five men hold the house: Brody the guard, kept to the bedroom; Lyle and Dutch at the front windows; the Kid on
   the porch; Hollis in the kitchen. Two rovers, Pike and Wes, walk the yard. [D built, #520, #565]
5. The hostage is tied to a chair in the bedroom. [D built; the rancher in code, the widow by the lock and v2]
6. Before any alarm the men are bored and talk; it carries. [built, `IDLE` lines]
7. Seen with his gun put away beyond 14 m, Harlan is warned off; 8 s of coming on, drawing, or closer, is the alarm. [built, tuning]
8. The alarm is also: a man sees him; hears a shot, glass, timber, a scuffle, a fuse (3 m, never through a wall); a
   ball into one of them; a blast. [built, LAYOUT]
9. The Baron's foreman walks up the lane "at a set time" with a deed for her to sign. [D, Sean 2026-11-09, v2 "build
   now"; not built]
10. The foreman is the stranger from the No Law table, on a bald-faced sorrel; the widow, who heard her husband's
    last words, knows the horse at her gate. [D that he is that man (C10 b, C16 a); the places P·bible, S39, S40]
11. Way in, the front: a kill zone. [D built; inventory]
12. Way in, the back, quietly, round the north. [D built]
13. Way in, the wall: plant a stick on a back wall unheard, hide; "the wall going up is the first they know of you";
    the men are dazed about 4 s and don't know where he is until one sees him or he fires. [D, Sean 2026-11-01 via
    #537; built `caught_cold`]
14. Way in, stop the foreman on the lane before he reaches the house: no paper, no signing. [D, v2 "build now"; not built]
15. Way in, walk the foreman in at gunpoint: "the men hold fire while he's near you". [D, v2 as changed by the build
    check; not built]
16. Or let her sign: the foreman reaches her table, the gang leaves, nobody hurt, the Baron has the water. [D, v2; not built]
17. After two of the others are down, dead, given up or run, the guard puts his gun on the hostage and shouts. [built]
18. Once Harlan is in the house and 20 s have passed since the alarm, or the guard is the last man, he kills the
    hostage after a 5 s warning (two shots). [built, tuning]
19. Harlan holds E 1.6 s by the tied hostage to cut her loose; she follows crouched behind him; out cold, she can be
    dragged by the collar. [built]
20. Won: the hostage is out and safe (4 m from the walls with nobody fighting, or 40 m away) and nobody's still
    fighting. Lost: the hostage is dead, or Harlan is down; Enter tries again. [built]
21. "Then her boys": once freed, the widow says her boys are held elsewhere on the property; a second group, there
    from the start, alerted only by evidence; the fight is outdoors; "Harlan brings the boys back. **The reunion
    completes the mission.**" [D, the lock (Phase B); v2 moves it to "later": needs child bodies and `ProtectedChild`]
22. v2's ending rule in place of phases: "it ends when the family is together and no captor stands". [D, v2 "build now"]

**Choices, and what each sets:**
- Fight now (her life at risk, the guard's clock) or let her sign (everyone lives, the Baron has the water) [D, v2].
  Sets `widow.signed` [P, `DECISIONS.md`].
- How he comes in: front, back, wall, the foreman stopped, the foreman walked in [D]. Her memory of how he came:
  "her door kicked in, her wall blown out, men taken quietly, or him standing by while she signed" [P, v2; "later"].
- The men who give up: taken alive (a witness, "a prisoner the gang will come for") or killed ("clean now and leaves
  nothing to prove") [P, v2]. Sets `farm.prisoners` [P].
- The Kid: "talked down with a nod" [D as a "later" item in Sean's v2 pick; needs the nod and a deed], spared and
  turned, or shot on the porch. Sets `kid.state` (turned / dead / still with the gang) [P].
- The foreman: stopped, walked in, killed or jailed. No fact exists; bible f6 proposes `foreman.fate` [P·bible].
- What Harlan did at the No Law table changes the lane: "What he does on the lane follows what Harlan did at the
  table" [P·bible, OUTLINE "who knows what"; SETUPS E table].
- "side with the Baron", "negotiate, stall" [P, ChatGPT]; "keep or destroy coerced documents" [P, ChatGPT].

**Endings, and what it leaves in the world:**
- Built: won ("The rancher's out, and alive."), lost ("The rancher's dead." / "You went down. The rancher's still
  out there with them."). Nothing carries over: "no save writer, `GameReset` rebuilds the scene" [build check, 2026-11-09].
- v2's three endings in "the cheapest strong version": stopped, escorted, let her sign [P, build check; the ways are D].
- "The blown wall stays; she and the boys live with the hole." [P, v2; "later", needs saves]
- If she signed, "the Baron's men start his ditch from her creek frontage (`dry-creek`)"; if the paper burned or was
  taken, "he has to try something louder" [P, v2].
- Prisoners to the jail as witnesses [D as "later" in v2; needs the jail]. (v2's "(`hold-him`)" is out of date: bible f12.)
- "The town hears it from her at church or the store, in her words, by what she saw." [P, v2; "later"]
- The epilogue walk reads "The widow, her boys, her water ... Hers still, or signed away (then whose is it after the
  arrest? O)" [bible, OUTLINE].
- "Lost if Harlan is down or the widow is killed (open for Phase B); the boys never enter the lost conditions." [P, PR #621]
- ChatGPT's afters [P]: rescued, house intact (she and neighbours trust him; "captured men may name their
  employer"); rescued, house damaged (she "may resent Harlan's methods"); forced sale ("Harlan may later challenge
  the deed using evidence"); widow dies or disappears ("No reset to a safe household").

**Who is in it:**
- The widow (no name; "ma'am"): the murdered sheriff's wife, two young sons [D, the lock; D, Sean 2026-11-09 the
  children are the sheriff's]. Script brief: "About forty, a Midwestern farm wife with good schooling."
- Her two boys (names "Sean's to name"); protected: "never hurt, never a target, by how they're built" [D, the lock].
- Blue, her dog: "He can never be hurt or killed" [D, Sean 2026-11-09, #728].
- The Colters: Brody (guard, leads), Lyle, Dutch, the Kid (porch), Hollis (kitchen); rovers Pike and Wes (masked) [built].
- The Baron's foreman = the stranger [D]. The Baron (off-stage; it is "his answer to her refusal").
- Built only: the blacksmith (gives the mission); the rancher (hostage; "Señor", Spanish lines).
- Joe: O. A notary or justice of the peace riding with the foreman, "a townsman Harlan knows" [P, judge, not picked].

**Sean's own words:**
- 2026-11-09, on v2 (card): "Sounds good but make sure our ideas are actually implementable".
- 2026-11-09, in chat on No Law (card): "Yes the children are the sheriffs / widows kids".
- 2026-11-09 (card): "I like the baron offering to buy". And on the story judge's three changes: "Yes I like the ticks".
- 2026-11-09 (`widows-place` card): "this is when we meet blue and the kids playing"; "Yes I like both, you ride the
  sheriffs horse out and she gives you his rifle"; "Yes I like all the ideas about what happens when you're there".
- 2026-11-01, as #537 relays it (card): "the dynamite way is a surprise assault. You set the stick on a back wall
  without them knowing. You get to a hiding spot, and the wall going up is the first they know of you."
- #520 (in `house_defence.gd`): "make the AI know the house and paths fantastically".
- #565 (in `farmhouse_tuning.gd`): "the guards give up too easily"; "it needs roving guards outside".
- #540, 2026-11-01 (card): the house should look like "a family has lived in for 14 years".
- #728, 2026-11-09, as recorded (card): "**He can never be hurt or killed**"; "He barks at strangers, follows the
  boys, and reacts in the farmhouse rescue (#537): he gives the gang's position away, or the player's."
- The lock, 2026-11-03, as PR #621 records it (card): the widow is "the murdered sheriff's wife; refuses to sell the
  family's claim; she lives on it with their **two young sons**". "The Baron wants her land for its water rights, and
  his gunmen occupy it to make her give it up." "**The widow replaces the Mexican rancher as the first hostage**"
  ("Keep the mission's systems; change who it's about"). She is "not met as a widow before the opening. Order: the
  peaceful visit, then the hostage crisis." "Her lines follow the help-or-leave deed from the opening." The breach
  "once demolition has been taught elsewhere". The visit "shows the property's ways in first: the back entrance,
  kitchen, yard and outbuildings". "Once freed, the widow says her boys are held elsewhere on the property." "The
  fight is outdoors: fences, wagons, woodpiles, sheds." "A second group of men is on the property from the start,
  never spawned, and is alerted only by evidence." "Harlan brings the boys back. **The reunion completes the
  mission.**" "No child-damage countdowns." The boys: "never hurt, never a target, by how they're built".
- #700, 2026-11-08, as `valley.json` records it: "Harlan keeps a small spring for his homestead; the widow's creek
  right is the valuable one, the reason for the murder".
- Inventory, 2026-11-09, "7. Hostage at the Farmhouse · Approved · Prototype developed": "Bandits take the widow
  hostage at her homestead east of Salt Creek." "The property sits beside the creek, north of the railway."
  "Approximately four or five enemies occupy the farmhouse." "The front approach is dangerous and heavily covered."
  "The player can assault the front or circle around the property." "A preferred creative solution is placing dynamite
  against the rear wall, blowing a hole in the building and entering through it." "A stealth approach remains possible
  if the gang hasn't spotted Harlan." "The player must defeat the captors and rescue the widow." "The environment
  should react to the damage rather than relying on a single scripted breach." "The widow's children may also feature,
  alongside Blue, the family animal, but the precise family setup remains unresolved."
- Inventory, continuity: "We established that the widow is the murdered sheriff's wife and that his murder is
  connected to her. We subsequently considered making her and the children Harlan's own family instead. That potential
  change must be resolved before the Judge treats their relationships as settled."
- 2026-11-11 (C5; CONTRADICTIONS): "B it is" (the Colters hold the farm). Before it, #744, 2026-11-11: the red
  shirt's gang "raid Joe's camp, hold the farm and do his dirty work" [Superseded by "B it is"]; the Colters
  "sometimes cross the Baron and sometimes work for him".
- 2026-11-17 (this session; VOICES; S51), of the stranger/foreman: "cocky and arrogant … but also a coward - that's why the
  sheriff was only shot in the gut and not finished off"; "probably a mid game reveal although I'm sure people will be
  guessing it right away".
- 2026-11-17 (this session; CONTRADICTIONS Part D): "it's a story to tell, not a bunch of disjointed missions."
- No-law draft, 2026-11-09 (Sean's draft), "Where it leads · The Farmhouse": "Harlan meets the sheriff's widow before
  she later becomes a hostage." "The family is familiar to the player rather than introduced only when threatened."
  Funeral purpose: "Establish the widow and her family before later threats against them."
- DESIGN "Story flow" (D 2026-10-01): "the gang burns out the widow on day 9 *if* she still holds her claim and
  nobody's guarding it"; "Reasons to fight" (D, Sean 2026-10-01): "the gang burning out the widow (defend her at
  night, or arrive to the ashes)". DESIGN cast: "**The widow** — refuses to sell her claim, alone."

**Lines of dialogue anyone gave:**
- Built, blacksmith (`farmhouse_mission.gd`): "You there! A word, mister. Over here." / "You're the one with the
  spring claim? Listen. They've got the rancher out at his place, east along the road." / "Brody's bunch. Sheriff's in
  no shape to go. If you're going, go now, before they do for him."
- Built, the men idle: Brody: "Keep your eyes on that road." "Nobody comes in here. Nobody." "Quit your fidgeting,
  old man." Lyle: "How long we sitting here, Brody?" "I could use a drink." "Somebody's coming, I'd say. Somebody
  always comes." Dutch: "Quiet out there." "Wind's getting up." "Dust on the road. No, nothing." The Kid: "Hot as
  hell on this porch." "You reckon they'll send the law?" "Ain't nobody out there." Hollis: "Coffee's cold." "Smells
  like horse in here." "Back's clear." Pike: "Nothing out back." "Walking this yard all damn day." "Hills are quiet."
  Wes: "Road's empty." "Nobody's coming." "Spell me on this, somebody."
- Built, the warning: "That's far enough, mister! Turn around!" "Hold it right there! Walk away, friend!" "You're on
  private land. Keep walking!"
- Built, hearing things: "Heard something." "Hold on. Something out there." "You hear that?" The fuse: "What's that
  hissing?" "You hear that? Something's hissing." "Hey— what's that?" Rovers falling back: "Inside! Get inside!" "I'm
  coming in! Cover me!" "Back to the house!"
- Built, `HouseDefence` calls: "Out front! He's out front!" "Front! Watch the front!" "Round back! Watch the back
  door!" "He's at the back!" "He's round the side!" "Side of the house! By the bedroom!" "West side! Under the
  window!" "He's round the side, by the stove!" "He's inside! Front room!" "He's in! He's in the house!" "Kitchen!
  He's in the kitchen!" "He's come in the back!" "He's at the old man! Bedroom!" "Bedroom!" "He's up in the loft!"
  "Loft! He's up top!" "The wall! Watch the hole!" "He's blowing his way in!" "Back! Back to the old man!" "Fall back!
  Bedroom! Hold the door!"
- Built, the hostage (the rancher; `hostage_brain.gd`): "Help! In here! They've got me tied!" "Señor! In here! Help
  me!" "In the back room! Help!" "Quiet... the one by the door's watching." "Careful, señor. There's more of them."
  "Gracias. Get me out of here." "God bless you. Go, I'm behind you." "¡Dios!" "Ay—!" "Wait— wait for me!" "Don't
  leave me here!" "Thank God. Thank God." "I owe you my life, señor." "One in the kitchen!" "Careful, the kitchen!
  There's one there!" "In the front room! By the stove!" "There's one in the front room!" "Behind you, in here!" "The
  one in here—watch him!" "Up in the loft!" "One went up the ladder!" "One went outside!" "There's one out in the yard!"
- Built, on screen: "The gang's holding the rancher at his place, east along the road. … of them in the house, and …
  walking the yard. Get him out alive." "He's loose. Get him out of the house and well away from it." "Hold E to cut
  him loose" "Cutting the ropes..." "He's out cold. Hold E to drag him" "Dragging him..."
- P·bible, the foreman (VOICES; "written for the cowman voice before C10 b, so they wait on s21"): "She puts her name
  to it, we ride off, nobody's hurt. That's the whole of it, Deputy." "He don't ask twice. He just asks different."
  "We've met, Deputy. You sat very still." (the lane, to a player who was at the table). Dropped: "You should have sat
  still" [Superseded: Harlan is unarmed on night one, Sean 2026-11-17].
- P·bible, the Kid (VOICES): "I never fired a shot at that house, mister. I held the horses is all."
- P, v2: the nod to the Kid: "You with me?"
- P·bible, the boys (VOICES, at `widows-place`): "Hands up, mister! This is a hold-up!" · "That's Pa's horse."

**Pays off from earlier / plants for later:**
- Pays off S3 the Baron's offer at the grave ("his answer to her refusal") [D].
- Pays off S16 the boys' game and S17 the ways in, from `widows-place` [D].
- Pays off S35 "First to use it owns it": the stakes at her ditch; why the Baron needs her signature [D, v2].
- Pays off S39 the foreman's face (night one's table) and S40 "friend" and the sorrel [D facts; places P·bible].
- Pays off S46 "The stranger asks leave": on the lane, "with the deed in his hand, asking if he might come up to the
  house" [P·bible].
- Likely place for S51 "He didn't get down" to break: "The widow's lane, walked in at gunpoint ... is the likely
  place; the raid if not" [P·bible; the cowardice and the mid-game hold are D, Sean 2026-11-17].
- Pays off S9 sticks (the breach) [D].
- Plants: the Kid as one of "the three who can name the paymaster" (S30) [D that he's the informant, 2026-11-09];
  the prisoners; `widow.signed` for `dry-creek` and the ending; T4 "the offer at the grave → the stakes at the ditch →
  the deed at the farmhouse → the coach's papers → the raid → his fate" [bible].
- K11/K14 (VOICES): Harlan can learn at the lane that the stranger is the foreman, and that he shot the sheriff.

**Every other idea found:**
- Other names: "the farmhouse hostage rescue" (#520), "the widow's farmhouse" (PR #621), "Hostage at the Farmhouse"
  (inventory), "The Farmhouse" (ChatGPT), "Farmhouse hostage rescue (Phase A house, Phase B yard to the boys)" (`valley.json`).
- The hostage was the Mexican rancher [Superseded as hostage by the lock, 2026-11-03; still what is built]. He "lives
  at the livery's west end (#430)" [card, vaqueros].
- "the widow's burn-out night" as a hand-built moment; the gang burns her out on day 9 [Superseded?: D 2026-10-01 in
  DESIGN; the occupation replaced it in practice; "OPEN (#622 item 9)" on the card; fire is out of play (#458)].
- Who holds the farm: "Bandits" (inventory) / "the Baron's own gunmen" (the lock) / Kett's crew (Sean #744) [all
  Superseded by C5 b: the Colters, hired].
- C5 option a "The Baron has more guns than the cabin held" and c "Both: the foreman and two of his own in the house,
  the Colters hired for the yard" [P·bible, not picked].
- "The widow and children as Harlan's own family" [considered, inventory; Superseded by Sean 2026-11-09: the
  sheriff's children].
- Water law: "In 1882 Colorado the first to use water owns it (*Coffin v. Left Hand Ditch Co.*, 1882): the sheriff's
  family dug first, so the Baron needs her name." [D as part of v2; "to check"]. "The paper is a deed, signed before
  an officer and recorded (not a 'bill of sale')" [D, v2 after the judge]. "a bill of sale" [Superseded].
- The priority "would normally rest on a court decree under the 1879/1881 adjudication acts. Check both." [judge on v2]
- "A deed or conveyance signed under duress can be undone in court; whether that matters depends on the trial and
  evidence" [P, v2 "True to 1882 (to check)"].
- A notary riding with the foreman; stopping them "costs that man's opinion and leaves a witness"; "if the foreman is
  overdue, the house's own senses start the guard's clock" [P, judge on v2; not picked]. Build check: "the notary as a
  second walker with an overdue clock: medium".
- The deed travels to the county seat by the daily train or the stage; "whether it arrives, burns or is taken plays
  out on the train and the gang" [P, judge; not picked; large].
- "stopping the foreman on the lane looks like the clean best answer" / "the lane ambush is cost-free" [judge's
  complaint about v2].
- "Nothing says how the player learns the foreman is coming." [judge on v2; answered in part by "the men's own talk
  ... overheard on site"]
- "Time it to the foreman: while he walks up the lane the gang faces the front." [P, setpiece judge]
- "The plant is a read of the house: reflected pressure hurts whoever is behind that wall, so the bedroom wall can
  hurt the widow; look through the windows first." [P, setpiece judge]. ChatGPT: "blast damage can also injure the widow".
- The Kid "can be talked down with a nod ('You with me?'), let Harlan in the back, or turn on the others. If not, he's
  one of the guns." [P, v2, needs `kid-wants-out` met first]
- Silent takedowns, first test on "round the back, quiet" [P, Sean's idea 2026-11-01, #563; "an idea, not scheduled"].
- "PROPOSED accessible loft/roof for vertical entry or a fall through weakened boards" [P, ChatGPT]. (Built: the
  house has a loft, a ladder, `"loft"` calls.)
- "Talk/comply: Pretend to discuss terms, buy time, or allow a coerced sale and pursue evidence later." "A nod can
  answer a captor's proposal face-to-face; no dialogue wheel." [P, ChatGPT]
- "No invisible per-minute failure clock; pressure changes when Harlan leaves, returns or advances related threads."
  "If ignored ... the widow may have signed under coercion or the house may be occupied." [P, ChatGPT]
- "Unthinkable: Harlan sides with the men, kills a surrendered captor, deliberately burns the farmhouse, or damages
  the widow's home beyond recovery." Blue "can flee, hide or bark." [P, ChatGPT]
- "Joe can be downed/revived if available; Harlan must choose whether to tend to him while the hostage remains at
  risk." [P, ChatGPT]
- "PROPOSED distinctive coat/hat for speaking captor; reuse Baron's men where possible." [P, ChatGPT]
- "It must play fully without dynamite and still reward demolition once unlocked." "May happen before or after Buried
  Alive; dynamite must never be assumed available early." [P, ChatGPT]
- "repair what can be repaired" after [P, ChatGPT]. "The environment should react to the damage rather than relying on
  a single scripted breach." [D, inventory]
- "shallow wagon-road creek crossing near property; separate small timber railway overpass nearby"; "The small rail
  overpass is nearby, not the widow's creek crossing." [ChatGPT, calling it established]
- Place: `widow_homestead` (1712, -560), pad 34 × 30 at y -10; `widow_lane` off the East Road, over Bridge A then the
  overpass; her fields "on the bottomland down to the creek 130 m north; her ditch heading in the canyon mouth".
- Ways onto the property: "the front from the lane; the rear up from the creek and canyon mouth; the side from the
  overpass road; and from above, the rail bench and overpass look down on the yard"; Phase B's hold "north-east toward
  the creek" [P, valley-plan §6].
- The boys held in "the root cellar or the barn" [P, v2]; "a barn or cellar not in the spec" [build check].
- Blue at the rescue: he "barks at the gang, not him" if met [D per DECISIONS/S16]; "gives the gang's position away,
  or the player's" [D, #728].
- The house: built 1868, 14 years old (`AGE`), lean-to, porch, gable front, loft, bed/dresser/stove, about 1,340
  members, 17 kit props [built]. Lived-in props (#540): new.
- "no corral at the farm" (#565) vs "fences, corral (#540, Phase B)" [O, card].
- #573 "waiting on Sean": is it the right kind of hard ("A keep, B no floor fight, C less nerve, D one rover") [O, card].
- #622 open items: where the boys are held; whether Joe comes; Phase B's men; the widow in Phase B; "a ball at a boy" [O].
- #689: "men taken away at the mission's start while you watch" [O, card].
- Built tuning: house men have 0.25 more nerve and hold on when cornered (8 s, three times); shot down, they "fight
  on from the floor"; a rover falls back into the house if nearer its door; the gang would "ride into town at 45 s"
  unless held at the farm; `--farm-rovers=0`, `--farm-cornered=off` lab switches [built].
- Built models: Brody = `bold_cowboy_s3_talking`; Lyle = `hothead_lyle_s2_talking`; Dutch = `colter_rider_s1`; the
  Kid = `young_drifter_s3_talking`; Hollis = `old_rancher_s1`; Pike = `old_rancher_s3_talking`; Wes = `doctor_s2_talking`.
- "sells" became "tells" ("no money in the game"); "the door opens" became "they hold fire" ("doors have no leaves");
  "the paper as a flag on whoever carries it (the player can't pick things up)" [build check, 2026-11-09].
- v2 "build now" was sized "about 2 medium, 4 small" [build check].
- The HOUSE / YARD / REUNION phase machinery [Superseded: cut in v2, Sean's pick 2026-11-09; `valley.json` still names
  "Phase A house, Phase B yard to the boys"].
- f3 (bible): `widows-place` has "the Baron's man back twice since the funeral"; if that is the foreman on his sorrel
  the widow knows the horse too soon; fix "Another hand comes those two times; the sorrel is first at her gate with
  the deed" [P·bible].
- f6 (bible): the foreman "is the sheriff's killer now, and the card gives him no fate. Dead or jailed here, he can't
  pay the men who pull the rail, stand behind the Baron, or be taken in the raid"; fix "A `foreman.fate` fact ... if
  he's taken or killed here, another man pays Gang B and Cody's word still names him" [P·bible].
- f7 (bible): the farmhouse ends when "no captor stands", but later cards need the Kid and Brody alive [P·bible: both
  later cards read their fate].
- s13 (bible): "If the widow signs at the farmhouse, the Baron has the water before Act III. What is he still after?"
  Readings: "Harlan's spring / the town itself" [O].
- S3's gap: a player who skips the funeral and the visit "meets the Baron's want for the first time at the farmhouse" [O, bible].
- The foreman "comes up the widow's lane with the Colters' guns behind him" (he only acts when it's safe) [P·bible, VOICES].
- The foreman asks leave: "Might I stand you a drink?" habit carried to the lane [P·bible, S46].
- Scores: decided card 19/35 (Consequences 1); v2 26/35; setpiece judge 4 for the breach ("won 4–5 of 8").
- History: prototype #520 (PRs #521, #525, build 2875); surprise assault #537 (PR #554); harder #565 (PR #568, build 2974).
- Old ten-day shape: no farmhouse; the widow's burn-out was a faction step [Superseded].

**Where the sources disagree:**
- Hostage: the rancher (code) vs the widow (lock, v2, bible). Sean's latest: the widow. Code not changed.
- Who holds it: bandits / the Baron's gunmen / Kett's crew / the Colters. Sean's latest (2026-11-11, "B it is"): the
  Colters, hired by the Baron.
- The start: the blacksmith (code) vs her absence at the store, the rover's talk (v2, D) vs the visit's offer (PR #621 A6).
  Sean's latest picks v2's; the blacksmith start is still the code.
- The breach: from the start (code) vs "once demolition has been taught elsewhere" (lock). Sean's word: the lock.
  ChatGPT also has "may happen before or after Buried Alive".
- The boys: Phase B in the lock; absent from the inventory; "later" in v2; "Then her boys" in the bible. Latest: in the
  design, built later, without phase machinery.
- "No child-damage countdowns" (lock) and ChatGPT's "No invisible per-minute failure clock" vs the built 20 s guard's
  clock on the widow and v2's foreman "at a set time". Unsettled (the lock's rule is about the boys).
- Burn-out on day 9 (DESIGN 2026-10-01) vs the occupation. Unsettled on paper (#622 item 9); the occupation is what
  every later source uses.
- The foreman can be stopped or killed on the lane (v2, D) vs the foreman needed later (rail payment, the raid) (bible
  f6). Unsettled.
- Ends when "no captor stands" (v2) vs the Kid alive on Payday Night (D) (bible f7). Unsettled.
- The men "hold fire while he's near you" (build check) vs "the door opens for the foreman" (v2 text). Latest: hold fire.
- The foreman's voice: cowman's (old sheet, the P lines above) vs soft-spoken and mannerly (scripts' reading, s21).
  Latest: soft-spoken; the P lines "wait on s21".

**Open questions:**
- Does Joe come? Where are the boys held? What do the yard men do?
- What happens to the foreman if he's stopped, taken or shot here (he is the sheriff's killer and the mid-game reveal)?
- If she signs, what is the Baron still after (s13)? Can the deed be undone?
- What the widow thinks of Harlan after each way in; what the Baron does next.
- Is the built difficulty right (#573)? Men taken at the start while you watch (#689)?
- A third plant for the Baron's want, for a player who skipped the funeral and the visit.
- Does the surviving Colter crew (Brody above all) have any later beat?

---

### The Vaquero's Horses (`vaqueros-horses`)

**Where it sits:** A side mission, unplaced [P; bible OUTLINE: "`vaqueros-horses`, `dry-creek`, `kid-wants-out` · P,
unplaced"]. Story judge suggests Act II before the farmhouse, "the Baron's hand shown small" [P]. Not in Sean's
inventory ("Kept, or dropped?", README). Not built. `valley.json`: "PROPOSED mission (frozen)", place `baron_range`.

**In one line:** A Mexican rancher's horses turn up rebranded in the Baron's corral; he wants them back, by force if he must.

**Harlan walks in with:** not stated for any item (gun, badge, horse, dynamite, companion, wounds, knowledge).

**How he hears of it:** O: "no source says" [card].

**Beats, in order:**
1. "A Mexican rancher's horses turn up in the baron's corral with fresh brands over old ones." [P, Sean 2026-10-06, DESIGN §5 mission 4]
2. "The rancher wants them back and will take them by force if he has to; the baron says he bought them fair." [P, DESIGN]
3. Harlan can "Help the rancher take them at night, buy them back, bring the baron's foreman to account, or stay out
   of it and watch it turn into a range war." [P, DESIGN]

**Choices, and what each sets:** side with the rancher (against the Baron), pay, the law, or nothing (a range war)
[P, DESIGN via card]. No fact named.

**Endings, and what it leaves in the world:** "watch it turn into a range war" [P, DESIGN]. Nothing else stated.

**Who is in it:** the Mexican rancher (#430, characters); the Baron; "the baron's foreman" [P; see disagreement]; the
Baron's hands. The rancher's people.

**Sean's own words:**
- DESIGN §5 mission 4 ("**proposed**, Sean 2026-10-06"): "**The vaquero's horses.** A Mexican rancher's horses turn up
  in the baron's corral with fresh brands over old ones. The rancher wants them back and will take them by force if he
  has to; the baron says he bought them fair. Help the rancher take them at night, buy them back, bring the baron's
  foreman to account, or stay out of it and watch it turn into a range war."
- DESIGN §5 mission 1 (Sean 2026-10-06, the scalp hunters): the scalps "Mexican as well as Native ... ties in the
  Mexican rancher's people (mission 4): whoever learns of the Mexican scalps wants a say in what happens to the bandits."
- DESIGN "Reasons to fight" (Sean): "**No shooting animals** (Sean: 'I hate games where you shoot animals') ...
  Horses, dogs and stock are in the world as creatures, never as things to fight."
- The lock, 2026-11-03: "**The widow replaces the Mexican rancher as the first hostage**".
- #700 (in `valley.json`): "no off-map herds; cows may be made (OPEN)".

**Lines of dialogue anyone gave:** none found for this mission. (The built rancher's hostage lines, in Spanish and
English, are listed under the farmhouse.)

**Pays off from earlier / plants for later:**
- Pays off (P): No Justice's line of scalps, "Mexican as well as Native" [DESIGN; MAP: `nojustice -.the scalps.-> vaquero`].
  Sean's own No Justice card (2026-11-09) "doesn't mention it. Kept, or dropped with the third ending?" [O, no-justice card].
- Plants: the Baron's theft "at small scale" before the conspiracy is named [P, story judge; bible Act II].

**Every other idea found:**
- Story judge: "STRENGTHENS · A cheap Act II step showing the Baron's theft at small scale."
- Places: `baron_ranch` (1320, 1260; "horse corrals", "A draw to the west and a low ridge to the east give covert
  approaches"), `baron_range` (1750, 1250) [P, `valley.json`]. The rancher's own place: none in `valley.json` [O].
- Systems the card lists: horses led and driven (partly); "Brands as evidence read up close: new"; a night raid on a
  guarded ranch (partly); buying and money (partly); "A range war as the factions' escalating plan: new (Prompt 18)".
- DESIGN §11 backlog: "brands registered in a book and rustlers' running irons" [P].
- f8 (bible): "bring the baron's foreman to account" breaks the through-line, because "The foreman has a spine of his
  own now"; fix "A different Baron's man" [P·bible].
- Old ten-day shape put it on Days 2–3 [Superseded with the day count].
- DESIGN "History, handled with care": "Mexican ranchers and vaqueros ... as real people with their own lives and
  perspectives, written with research and care" [D section]. Bible C13 b (D, Sean 2026-11-11): "A few slurs, from the
  worst men only"; WORDS: "vaquero" is a period word for a man who works cattle.
- s7 (bible): without Joe, the men in I Am the Law goad "Someone from the camp in town to trade / a Mexican hand" [O].
- A rancher stands at the funeral (`config/moments/funeral.json`, borrowed).
- `small-fights` covers "rustlers, horse thieves" as repeatables [card STORY.md].
- The card was "Checked against the story bible (2026-11-14): nothing here has changed."

**Where the sources disagree:**
- "the baron's foreman" as the man to bring to account (DESIGN) vs the foreman as the stranger, the sheriff's killer,
  held to a mid-game reveal (Sean 2026-11-13, 2026-11-17). Latest favours a different Baron's man here (P·bible f8); unsettled.
- The rancher: the farmhouse's first hostage (#520, still in code) vs replaced by the widow (lock). He "lives at the
  livery's west end (#430)". Where his ranch is: O.
- The title says "vaquero", the text says "rancher". No source settles whether he is a hand or an owner.

**Open questions:** how Harlan hears; where the rancher's place is; whether it is in the game at all (not in the
inventory); which of the Baron's men is answerable; whether the scalps tie survives; what a "range war" does in a
game with no day count.

---

### Dry Creek (`dry-creek`)

**Where it sits:** A side mission, unplaced [P]. Inventory Part 2, "20. Dry Creek ... Brainstorm". Story judge
suggests Act II, before the farmhouse, as an alternative to `vaqueros-horses`. Not built.

**In one line:** "A water-related dispute or emergency that uses the valley's creek and water systems."

**Harlan walks in with:** not stated for any item.

**How he hears of it:** O: "no source says" [card].

**Beats, in order:** none in any source. What exists:
1. "A water-related dispute or emergency that uses the valley's creek and water systems." [P, inventory Part 2, brainstorm]
2. If the widow signed at the farmhouse, "the Baron's men start his ditch from her creek frontage (`dry-creek`)". [P, v2]

**Choices, and what each sets:** none named [O, card]. It reads `widow.signed` [P, `DECISIONS.md`].

**Endings, and what it leaves in the world:** none named [O].

**Who is in it:** not stated. By the threads: the Baron (T4).

**Sean's own words:**
- Inventory, 2026-11-09, Part 2: "20. Dry Creek | A water-related dispute or emergency that uses the valley's creek
  and water systems. | Brainstorm".
- Inventory, "Other proposed set pieces": "Water diversion: Manipulate a dam gate, creek, irrigation channel or
  mining sluice to change the environment." "Mine pumping: Use operating machinery and water systems during an emergency."
- Inventory, Part 3 (older concepts, "should not be treated as canon"): "Stolen Creek | Manipulation or theft of water resources".
- DESIGN §5 premise (D): "**Water is the stakes.**" Cast: the cattle baron "wants every drop of water in the valley,
  and is patient."
- #736 A, "approved with the map", Sean 2026-11-09 (card): "**Water in the west:** a spring or stock tank on the dry
  side. It matters for horses, and the Baron wants it."
- #700, Sean 2026-11-08 (`valley.json`): "Harlan keeps a small spring for his homestead; the widow's creek right is
  the valuable one, the reason for the murder".
- DESIGN §11 world-building (D, Sean 2026-10-01): "Cut: water levels and drought, movable claim stakes."

**Lines of dialogue anyone gave:** none found.

**Pays off from earlier / plants for later:**
- Pays off (P): the stakes at her ditch (S35), the deed at the farmhouse (`widow.signed`).
- Plants (P): the Shipment v2's log deck is "flume" timber "(the water he's taking, `dry-creek`)"; "logs used on the
  coach slow the Baron's flume (`dry-creek`)" [P, `proposals/barons-shipment_v2.md`].

**Every other idea found:**
- Story judge: "STRENGTHENS · Water is the stakes and no mission shows the Baron taking it before Act IV; uses the
  west of the map."
- Places proposed: Salt Creek along the south of town to the canyon; the west's spring or stock tank (#736 A.3, not
  placed); Harlan's spring (480, 420); the Ute community's spring (-1420, 1180); the mine [P, card].
- `valley.json` water facts: clean Salt Creek rises south-west, passes the Ute community, then the town; "the town's
  ditch takes water above town" to "a cistern behind the jail (the town's supply and the bucket line's source)"; the
  mine and Ore Works drain to a dry arroyo that joins the creek "below the widow's place"; the canyon is the creek's
  lower course; the Baron's ranch has "a windpump and water tanks".
- Systems: "Water that flows and can be diverted (a creek's level, a channel): new"; "Machinery (gates, pumps,
  sluices) as props the player works: new" [card].
- M6 / s14 (bible): Harlan's spring ("the best spring", DESIGN) "is never wanted by anyone on any card"; P·bible: "the
  Baron's first offer is for it"; where the offer is made is O. DESIGN: "night riders at your own spring".
- s13 (bible): if she signs, is the Baron then after "Harlan's spring / the town itself"? [O]
- The card was "Checked against the story bible (2026-11-14): nothing here has changed."

**Where the sources disagree:**
- Dry Creek needs water that changes; DESIGN §11 cut "water levels and drought". Unsettled.
- "the best spring" on Harlan's claim (DESIGN 2026-10-01) vs "a small spring ... the widow's creek right is the
  valuable one" (Sean 2026-11-08, #700). Latest: the widow's is the valuable one.

**Open questions:** everything: what happens, who is in it, how he hears, the choice, the after, the place, whether
water can move in the game, and whether it is one mission or the same thing as "Water diversion" / "Mine pumping" /
"Stolen Creek".

---

### The Kid Wants Out (`kid-wants-out`)

**Where it sits:** A side mission, unplaced [P]. The bible lists it both in Act II's open part and "Open in Act III"
[P]; the story judge puts it in Act III after Payday Night ("the Kid names the paymaster") [P]. Not in Sean's
inventory. Not built as a mission. The Kid himself is built: a gunman in the three-gunmen lab and the man on the
farmhouse porch (`config/farmhouse.tres`: nerve 0.3).

**In one line:** The Colters' youngest comes to Harlan quietly: he's done with the gang, and the gang doesn't let men leave.

**Harlan walks in with:** not stated for any item. What he may know: the Kid from the farmhouse porch (if the Kid
lived) and from under the cut on Payday Night [D facts; order O].

**How he hears of it:** "The Kid comes to you quietly" [P, Sean 2026-10-06, DESIGN §5 mission 5].

**Beats, in order:**
1. "The Kid comes to you quietly: he's done with the Colters." [P, DESIGN]
2. "The gang doesn't let men leave." [P, DESIGN]
3. Harlan can "Hide him, get him on the stage, teach him to stand up for himself (signature 8), or sell him back to
   Brody." [P, DESIGN]
4. "If he gets away, he may come back in act three, on either side." [P, DESIGN]
Around it, decided elsewhere:
5. The Kid is one of the Colters the Baron hires for the widow's farm, and is on the porch. [D, Sean 2026-11-11, C5 b; built]
6. The Kid is the informant who knows who pays the gang. [D, Sean 2026-11-09 "Yes to payday night", with "Yes I like the ticks"]
7. The Kid drinks at the bar under the cut on Payday Night; "If it goes, he may be under it." [D, v6, per OUTLINE and
   the `payday-night` card]

**Choices, and what each sets:**
- Protect him (the gang's anger) or sell him (his life) [P, DESIGN via card].
- Teach him: "it saves your life later, or he uses it against you" [D, signature 8, Sean 2026-10-01].
- `kid.state`: turned / dead / still with the gang, set at the farmhouse, read by `payday-night` and `kid-wants-out`
  [P, `DECISIONS.md`].

**Endings, and what it leaves in the world:**
- The gang a man short; the Kid may come back later "on either side" [P, DESIGN]. "No card brings him back." [bible M13]
- Alive, "he talks, in his own time"; dead, "that thread loses its voice" [P, `payday-night` card].
- OUTLINE's walk: "The Kid, the Colters · O: no card ends the Colters' thread".

**Who is in it:** the Kid ("the Colters' youngest, the timid one"); Brody (he can be sold "back to Brody"); the gang;
Lyle (in a P line). The stage and its driver are implied.

**Sean's own words:**
- DESIGN §5 mission 5 ("**proposed**, Sean 2026-10-06"): "**The Kid wants out.** The Kid comes to you quietly: he's
  done with the Colters. The gang doesn't let men leave. Hide him, get him on the stage, teach him to stand up for
  himself (signature 8), or sell him back to Brody. If he gets away, he may come back in act three, on either side."
- DESIGN §11 signature 8 (D, Sean 2026-10-01): "teach the Kid to shoot or the widow to dress a wound; it saves your
  life later, or he uses it against you."
- 2026-11-09 (card): "Yes to payday night". "Yes I like the ticks".
- 2026-11-11 (C5): "B it is".
- Three-gunmen brief (as the card quotes it): "Brody cool, Lyle a hothead, the Kid timid".

**Lines of dialogue anyone gave:**
- Built, on the porch: "Hot as hell on this porch." "You reckon they'll send the law?" "Ain't nobody out there."
- P·bible (VOICES, the Kid): 1. "I never fired a shot at that house, mister. I held the horses is all." 2. "It ain't
  Brody pays us. It's the man that pays Brody." 3. "They don't let you quit. Lyle said it laughing, but he said it."
  4. "If I tell you, I'm dead in this valley. You got to see that." 5. "Is it true you can sew a man up?"
- P, v2: Harlan's nod question to him: "You with me?"

**Pays off from earlier / plants for later:**
- Pays off: the porch at the farmhouse; the Kid's nerve; Harlan the steward ("Is it true you can sew a man up?").
- Plants: S30 "The three who can name the paymaster" (Gang B's man, the Kid, the bookkeeper; with Cody, four voices)
  [D/P]; the Kid may say the foreman pays "out of the coach", which is how Harlan learns of the Shipment [P·bible, M4];
  the Kid may name Kett ("the town knows him only as 'the red shirt' until someone names him (the Kid, or ...)",
  `no-justice` card); the Kid may tell Harlan which men sawed the girder [P·bible, s22].
- Knows: "who pays Brody. Which jobs were the Baron's." [P·bible, VOICES]. K4: Harlan can learn the Baron's men did
  both from "the Kid (B12 on)".

**Every other idea found:**
- Story judge: "STRENGTHENS · The informant on who pays the gang; can come back at the finale." MAP: `kid -.comes back.-> bridge`.
- The Kid "talked down with a nod" at the farmhouse; lets Harlan in the back or turns on the others [P, v2; "later"
  in Sean's pick: needs the nod and a deed].
- "two of the gang slip into the dark street" / "the Baron's two men on an agenda toward the Kid" / "The Baron's men
  want him dead" on Payday Night [Superseded: cut in v4–v6: "Cut: ... the two killers hunting the Kid"; "put the Kid
  among the possible wounded instead"].
- "The Kid or the next man: triage by need, or by what the living man knows." [P, `payday-night` card]
- C16 option c: "The Kid shot him [the sheriff], a Colter hired through the foreman for one job and sick of it since:
  it gives 'the Kid wants out' its reason and pays it off when he confesses; the sheriff's clue is a young man's voice
  and a horse." [P·bible, not picked: Sean picked a, the stranger]
- How he talks: "quick, half sentences, eyes on the door. Polite out of fear." Calls Harlan "mister"; "sir" when it's
  bad [P·bible].
- WORDS: "the Kid" is a cowhand nickname; "kid" for a grown man is otherwise out of period.
- Built model `young_drifter_s3_talking`; a nervous walk (`walk_nervous`, `config/moments/walks_lineup.json`).
- Places: none named; the stage, the town, the gang's `hideout` (-450, 2020), `east_exit` "as candidates no source names" [card; MAP].
- Systems the card lists: hiding a man and the gang searching (partly); the stage as a way out (new, #276);
  teaching (decided, not built); the Kid's opinion carried forward (partly); money (MAP).
- Old ten-day shape put it on Days 2–3 [Superseded with the day count]. "act three" belongs to the 30-day shape [card].
- f7 (bible): "The Kid and Brody may be dead" after the farmhouse; both later cards must read their fate [P·bible].

**Where the sources disagree:**
- The Kid "comes to you quietly" as a first meeting (DESIGN) vs first met as a gun on the porch (C5 b, D). Latest: the
  porch comes with the farmhouse; the order of the two is O.
- The farmhouse ends when "no captor stands" vs the Kid alive on Payday Night and in this mission (f7). Unsettled.
- "sell him back to Brody" needs Brody alive (f7). Unsettled.
- "act three" (30-day shape) vs no day count (Sean 2026-11-01). Latest: no day count; where he "comes back" is O.
- What the Kid can name: "who pays the gang" (Sean's pick: by then the foreman, on the Baron's word) vs the foreman
  held as a mid-game reveal (Sean 2026-11-17). Not flagged anywhere; unsettled how much the Kid says and when.

**Open questions:** when it opens (before or after the farmhouse, before or after Payday Night); what happens if he
died on the porch or under the floor; where he hides; what Brody does; whether he ever comes back; whether teaching
gets built.

---

## The Colters as a family (T6; no card)

**Status in one line:** "a separate outlaw family who sometimes cross the Baron and sometimes work for him" [D, Sean
2026-11-11, bible OUTLINE T6]. "Hired for the widow's farm once the cabin has finished Kett's crew (C5 b)" [D, Sean
2026-11-11: "B it is"]. "Their other beats are P and their ending is missing." [bible]

**Who they are (names given stay: VOICES "Names"):** Brody, Lyle, Dutch, Hollis, Pike, Wes, the Kid.
- **Brody:** leads; the guard held to the bedroom; "cool"; nerve 0.95, temper 0.2, proud [built]. Model
  `bold_cowboy_s3_talking` (the Studio's "bold cowboy"), swagger walk. "Cool; says little" [P·bible].
- **Lyle:** "a hothead"; temper 0.9; front window; proud [built]. "They don't let you quit. Lyle said it laughing" [P·bible].
- **Dutch:** front window; nerve 0.6 [built]. **Hollis:** the kitchen; nerve 0.65 [built]. **Pike, Wes:** rovers on
  the yard, masked [built, #565].
- **The Kid:** "timid"; the porch; nerve 0.3 [built]. See `kid-wants-out`.
- A "brother": in the old jail night, "his brother offers you money" [P, DESIGN §5 mission 2]: the only source that
  makes any of them brothers by name of relation. Which are kin: O.
- A man named "Colter" drinks at the trough in a built showcase moment (`config/moments/trough_scoop.json`, model
  `colter_rider_s2_talking`); Brody and the Kid walk in `library_walkers.json` and `walks_lineup.json` [built, lab pieces].

**Sean's own words about them:**
- DESIGN cast (2026-10-01 era): "**The Colter gang** — hired to scare homesteaders off, with plans of their own. One
  of them 'knows' the player (see §6)."
- DESIGN §6: "**An ambiguous past:** when the Colters ride in, one says 'I know you.' Rode with them once? Mistaken
  identity? A lie to rattle you? What you say in that first conversation decides it, and the townsfolk remember your answer."
- DESIGN §6 paths: "**The gang** — noticed if you're violent, broke or crooked; tested with small jobs first." "every
  faction (town, law, Colters, baron, railroad) keeps its own opinion of you"; "an **undercover path** (the badge while
  riding with the gang, or the judge's man inside)".
- DESIGN story flow (D 2026-10-01): "Whatever happens, by day 3 the town has no law, the Colters are in town, and
  everyone wants to know what you saw." "the gang runs jobs and leans on the town". "the gang burns out the widow on
  day 9 *if* she still holds her claim and nobody's guarding it". Endings include "ride with the Colters".
- DESIGN §5 mission 2 (Sean 2026-10-06): "You have one of the Colters in a cell and the Marshal's wire says two days.
  The gang wants him out; the town wants him hanged now (a mob with a rope); his brother offers you money."
- DESIGN §10: "the Colters rob in masks too, and the lawman path becomes an investigation of" who was behind them.
  §9: facts as recordings, "It was Brody", "It was Lyle"; "I saw Brody do it". §10 rounds: "the gang drinks your
  whiskey and still despises you".
- #744, 2026-11-11 (CONTRADICTIONS C5): the red shirt's gang "raid Joe's camp, hold the farm and do his dirty work";
  the Colters are separate; they "sometimes cross the Baron and sometimes work for him". Then "B it is".
- #520, built blacksmith line (not Sean's words, but the build he approved): "Brody's bunch."

**Every idea about them, with status:**
- Hired by the Baron for the widow's farm; the Kid on the porch [D, C5 b].
- "after it the Colters cross him" [P·bible; "not part of the pick"].
- They are Gang A on the payroll train, "robbing it on their own account and double-crossed by the Baron's rail"
  [P·bible, s6; who Gang A is: O].
- The stick-up man seen practising alone at night (#276) is in Gang A: "Arrest him early and the gang is a man short;
  follow him and find their camp; or just know his face." [P, Sean 2026-11-07, S20]
- "The Colters met as a separate outfit" through law work: `store-robbery`, `the-bounty`, `small-fights`,
  `stage-held-up` [P, OUTLINE]. Story judge: "`store-robbery` ... Cheap early law work that introduces the Colters."
- The store robbery: "the gang leans on the storekeeper" [P, ROADMAP 3.6 / Prompts 12, 18]. The bank robbery: "the
  gang's plan, the alarm, a posse" for the land money; the gang may ask Harlan in [P, DESIGN backlog].
- "a night ride on the stage road the gang watches" (the fever house) [P, DESIGN]. The dust storm: "the gang, the
  baron's men, the townsfolk, you" shut in the saloon [P, DESIGN]. The fire night: "the gang (a drama-manager plan, a
  grudge)" sets a building alight [P, DESIGN backlog; fire out of play].
- "clearing the gang's hideout" as paid work [D list, DESIGN]. The outlaw `hideout` (-450, 2020): "a line shack in a
  box canyon under the southern rimrock; a hard trail in front, an unseen way off the mesa top" [D, Sean #700]; "the
  Colters'" per the `no-justice` card. (No Justice's built hideout is Kett's; `valley.json` lists no mission for the place.)
- A Colter in the cell, his brother's money, the gang coming for him, the gang "burning you out" [Superseded: the
  prisoner is Cody, the Baron's man, and the night is the Water Tower with one side: D, Sean 2026-11-11, C6 b, C7 c].
- The gang cutting the water tower's legs to drop it on the jail to free a Colter [Superseded as above; the tank and
  the idea survive for Cody].
- "the gang to free their man, the Baron's men to kill him before he can talk about who pays the gang" (two groups)
  [Superseded by C7 c, one side].
- "The Baron's men (the Colters on his pay, or his own hands)" stage the revolt in I Am the Law [P, `proposals/i-am-the-law.md`].
- "a Colter who can name who ordered the sheriff's killing" on the balcony [P, judge on the Balcony Ambush].
- The Kid shot the sheriff, hired through the foreman [P·bible, C16 c, not picked].
- Is the bold cowboy at the doctor's (siding with Joe) Brody? "He is Brody: an outlaw telling the deputy the truth
  about the law / a townsman" [O, s4]. Sean: "I'll find something else for him".
- "I know you." said to Harlan by a Colter (VOICES gives it to Brody): never used on any card (M9); "C15 a made
  Harlan's past with Rourke real; whether a Colter knows him too is O".
- "who they answer to is open" (STORY.md) [Superseded by 2026-11-11: separate, sometimes hired].
- "hired to scare homesteaders off" (DESIGN) [partly Superseded: they are hired for one farm, after the cabin; bible f17
  strikes "by day 3 ... the Colters are in town": "the Colters are hired after the cabin"].
- If the town burns: "the gang moves into the ruins" [P, DESIGN §10 "Why you won't burn the town down"].
- Talk: cowhands' Texan with Spanish; "nicknames by place or look ('Dutch', 'the Kid', 'Tex')"; hard words for
  homesteaders ("nester", "granger"; the No Law script found "nester" not in the period dictionaries) [P·bible, WORDS].
- The foreman "comes up the widow's lane with the Colters' guns behind him" [P·bible].
- Prisoners from the farm are "a prisoner the gang will come for" [P, v2]; `farm.prisoners` [P].
- Their ending: none. "M11. The Colters. Met, hired, crossed (all P), and no end." "s20 · The Colters' thread has no
  ending on any card · Needs a card." README: "the picks gave the Colters and the Kid the farm, not an end."

**Where the sources disagree:**
- Hired "to scare homesteaders off" from the start (DESIGN) vs a separate family hired only after the cabin (Sean
  2026-11-11). Latest: the second.
- A family (brothers) vs a gang with nicknames: only "his brother" and the name "Colter" say family. Sean's word
  2026-11-11 is "family" as the bible records it. Who is kin: O.
- The farmhouse can kill all seven; later ideas need Brody and the Kid (f7); s6 needs enough Colters to rob a train.
  Unsettled.
- Brody's model is the "bold cowboy" who also stands with Joe at the doctor's (s4). Unsettled.

**Open questions:** how Harlan first meets them; whether they are in town before the farm; what they do after it;
whether they cross the Baron; whether they are Gang A; whether any of them knows Harlan; how their thread ends.

---

## Ideas with no mission

From the sources read for the missions above; one line each.
- **The stranger/foreman's cowardice is a mid-game reveal**; the widow's lane at gunpoint is the likely place it shows [D the trait and the hold, Sean 2026-11-17; the place P·bible, S51].
- **"The Baron's contempt for a job half done"**: one cold line from the Baron about the botched shooting, later [P·bible, VOICES/S51].
- **Harlan's spring**: "The player's claim holds the best spring" (DESIGN) and nobody ever asks for it (M6, s14); the blacksmith's built line calls him "the one with the spring claim"; "night riders at your own spring" [D list, DESIGN].
- **The railroad land agent "Vale"**, "buying claims with forged deeds" (DESIGN cast): on no card; "Dropped; his deeds are the Baron's" [P·bible, s18].
- **Teaching the widow to dress a wound** (signature 8) [D, Sean 2026-10-01; on no card].
- **Marrying the widow** as a path and an ending ("marry the widow and hold the valley"; marriage "with property consequences") [P, DESIGN romance 2026-10-01; on no card].
- **Hired gun path**: "muscle for the baron one week and the widow the next"; **rancher path**: "keep your head down and farm; the water war comes to you anyway" [DESIGN §6].
- **The Missing Ranch Hand**: "Investigate a missing worker and decide how to handle the rancher" [inventory Part 3, not canon].
- **The Cattle War**, **The Railroad Men**, **The Long Winter**, **The Election**, **The Siege of Salt Creek**, **The Man Who Wasn't There**, **The Bank Is Empty**, **The Missing Stagecoach**, **The Fever**: early pitch names only [inventory Part 3].
- **Mill of Teeth** ("Dangerous industrial machinery set piece") and **High Wire** ("Aerial tramway or industrial transport set piece"): mine/ore-works-shaped set pieces with no card [inventory Part 3, not canon].
- **Early train encounter**: "Harlan travels under the small railway overpass during one or two early missions" (the overpass is on the way to the widow's) [P, inventory set pieces].
- **Burning livery** [P, inventory set pieces; fire out of play].
- **The mine's whistle at the change of shift**, and town time vs railroad time [P, DESIGN backlog]; the mine's payroll rides Thursday's train and "the miners talk of it" [D, Hell on Wheels v2].
- **Mine and Ore Works as a faction**: "Workers discuss the loss of law enforcement; no mandatory faction change" after No Law [no-law draft, faction effects]. The miners unpaid and the saloon "turns ugly" if the payroll is lost [P/D, Hell on Wheels v2, C2 b].
- **A flash flood can take out the mine road's culvert fill** [P, `valley.json`].
- **The old shaft's headframe and the ore chute** as high places (a rifleman's or lookout's) [P, #736 B, `valley.json`].
- **Chinese workers "camped by the creek"** and the foreman "found dead" (the railhead lynching) clash with the foreman's new spine [P·bible f8].
- **Scalp hunters selling Mexican and Native scalps south as "Apache"** (the Glanton gang) [P, Sean 2026-10-06, DESIGN; not in Sean's 2026-11-09 No Justice card: O].
- **Brands in a registered book, running irons** [P, DESIGN backlog].
- **Rope rescues "from the creek or a mine shaft"** [DESIGN §8 rope, must have; on no card].
- **Roles, not names**: the sheriff, the widow, her boys, the doctor, the Baron, his foreman, the miner stay unnamed "until a script needs more" [D, Sean 2026-11-11, C14 c].
- **Nothing carries between missions yet**: "no save writer", no story flags for "met the Kid" or "the peaceful visit" (build check 2026-11-09); `StoryState` (`src/missions/story_state.gd`) is "static, in memory" [built, LAYOUT].
