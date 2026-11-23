# Mission ideas, the full record: %s

Part of `docs/story/MISSIONS.md` (read that first). Gathered 2026-11-17 by a reader sub-agent from every source: the mission cards on PR #743's branch, Sean's own files in `docs/missions/sources/`, the proposals, the story bible, DESIGN.md and what is built. **Nothing here is a decision unless it is marked D with Sean's date.** Not yet checked line by line by the story session; where it disagrees with `OUTLINE.md` or `CONTRADICTIONS.md`, say so in a note rather than fix it silently.


Reader 4 of 5, 2026-11-17. Nothing here is new: every line is from a source, named in brackets.

**Short source names used below**
- `card` = `docs/missions/<slug>.md` on `origin/claude/planning-missions-cards-mwdo42` (PR #743's branch).
- `v2`…`v6` = `docs/missions/proposals/<slug>_vN.md`; `prop` = `proposals/i-am-the-law.md`.
- `inventory` = `sources/inventory_2026-11-09.md`; `chatgpt` = `sources/chatgpt-cards_2026-11-09.md` (all P).
- `judged` = `judged/2026-11-09.md`; `judged_story` = `judged/2026-11-09_story.md`; `judged_set` = `judged/2026-11-09_setpieces.md`.
- `OUTLINE`, `SETUPS`, `VOICES`, `CONTRA` (= CONTRADICTIONS.md), `WORDS`, `DIALOGUE`, `bible README` = `docs/story/`.
- `#NNN` = the GitHub issue's body or comments (read with `gh`), where Sean's words were recorded by a session.
- Status words: **D** decided by Sean · **P** proposed (whose is said) · **P·bible** · **O** open · **Superseded**.

**A caution on the picks of 2026-11-11 (#830).** The #830 comment says the picks were "answered in the session, one
at a time, a letter each unless his words are quoted". So for C1, C2, C3, C9, C11, C15 Sean picked a **letter**; the
sentence after the letter is the option's wording (the bible's), not Sean's own words. They are still D.

**The Act's order.** "Fixed, in this order (D): Hell on Wheels, then Payday Night that same night, then I Am the Law
the next day" [OUTLINE Act III]. Before it: Act II (Buried Alive → Demolition Mentor → the Farmhouse) [DECISIONS.md
flowchart; inventory Part 4, "a working sequence, not a locked mission order"]. After it: the Baron's Shipment
[DECISIONS.md flowchart].

---

### Hell on Wheels (`hell-on-wheels`)

**Where it sits:** Act III, first [D as the Act's fixed order, OUTLINE; inventory Part 4 had it as "7. Runaway Payroll
Train", P]. Must come first: none stated as a gate; the stick-up man and "Thursday's train" are plants, not gates
[v2; SETUPS S20, S21]. Dynamite arrives in Act II, but "the mission should not require Harlan to possess dynamite"
[P, chatgpt §15]. **Not built as a mission.** What exists: the train, steps 1–5 (`src/train/*.gd`: `TrainSim` 1D
train with couplers and slack, `TrainCars` walkable cars, `Ladder`, `TrainTimetable`, `TrainEngineer`,
`TrainLookout`, `TrackChunk.tear_loose`/`track_state.gd` breakable track, `TrainWreck` derail, `TrackRepair` crew,
`TrainSound`) [docs/LAYOUT.md "src/train"; v2 build check]. Train step 7 ("the runaway": fighting on moving cars, cab
controls) is not built [#542 status table: "7 (the runaway) | After the trestle lab"; docs/lanes/gameplay.md line 74:
"train (#542 step 7; waiting #553, #557, #601)"]. `config/valley.json` has the mission as a row: `runaway_payroll`,
"DECIDED (board by the overpass, fight back to front, stop before the broken track)", places `bridge_b`, `bridge_c`,
`depot`. No `src/missions/` file, no moment, no script.

**In one line:** The mine's payroll is on Thursday's train; one gang is aboard to rob it, two of the Baron's foreman's
men have pulled a rail to wreck it, and Harlan has to stop it before the break, by physics [D v2 2026-11-09; OUTLINE].

**Harlan walks in with:**
- Gun: not stated on the card. From elsewhere: the sheriff's revolver from day 2 [D, Sean 2026-11-17, this session, item 2];
  the sheriff's Winchester from the widow at `widows-place` [D, Sean 2026-11-09, DECISIONS.md gap 2; built #795 per
  CONTRA s5], if he did that mission.
- Badge: deputy [D, Sean 2026-11-09: "we're still keeping as deputy", payday-night card; C12 a].
- Horse: not stated. The inventory has "horseback boarding as an alternative" [D inventory] but the horse "only idles
  and is tied" and the chase on horseback "can't be played" [v2 build check, 2026-11-09].
- Dynamite: Buried Alive and the Mentor come before in the order [OUTLINE], but not needed here [P, chatgpt].
- Companion: "Joe: possible companion" [P, chatgpt §11]; "Joe can be downed/revived if present; if Joe died during The
  Hanging, use a solo version" [P, chatgpt §8]. Our cards say nothing of Joe here.
- Wounds: not stated.
- What he knows: depends on how he hears (below). He is a hospital steward [D as "proposed backstory", DESIGN.md §6;
  kept by C15 a].

**How he hears of it:** four ways, "none needing the others" [D, Sean 2026-11-09 "Yes fold it in with all the ticks",
card "Version 2"]:
1. The saloon owner sells that the payroll's on Thursday's train, and the miners talk of it the night before.
2. The stick-up man seen practising alone (#276) is in Gang A: a face he knows on the train.
3. The section foreman runs into town: spikes pulled, a rail loosened out west, two riders seen there.
4. On the day the train blows through the depot at speed, whistle silent, the agent shouting.
- "Each way has a window: where and when Harlan hears decides what's left" [D, v2 judge's tick 1, taken by Sean].
- Older: "OPEN: how Harlan learns the track is out or the train taken" [card, superseded by v2].
- Sean's own example assumes he "dealt with the men who blew the track" first [P, Sean 2026-11-07, #546 P9].

**Beats, in order:** (the card is a situation, not a script; this is the order the sources give)
1. Before: at night, through a window, a man alone practises his hold-up; later he is in Gang A. `[P, Sean 2026-11-07, #276; SETUPS S20]`
2. Before: the barkeep sells "Payroll's on Thursday's train"; the miners talk of it. `[D v2; VOICES barkeep line 3 is P·bible]`
3. Gang A boards to rob the express car at a lonely stretch west of town. `[D v2]`
4. Gang B, two men paid by the Baron's foreman, pull spikes and loosen a rail west of the depot, to wreck the train, not stop it. Gang A doesn't know. `[D v2; K7 in VOICES: "Not Gang A (D)"]`
5. The section foreman runs into town with the news (the early window: time to reach the overpass ahead of the train). `[D v2]`
6. The fight at the break is small: two men, or the break found already done. `[D v2, from the judge's cut]`
7. Harlan "races east to catch the approaching train". `[D inventory; O how far, v2 "Where the sources disagree"]`
8. He boards by jumping from the small wagon-road overpass (`bridge_b`) onto the train roof; horseback is the alternative. `[D inventory; valley.json]`
9. Late window: the train blows through the depot, whistle silent; all that's left is the chase and the cars. `[D v2]` Build check: the late window is "board from the depot platform as it passes", at a speed the gang keeps low, until horses can be ridden. `[P, build check 2026-11-09]`
10. Aboard he finds it being robbed. `[P, Sean 2026-11-07, #546 P9]`
11. He fights rear to front through six walkable cars: coach, express car, boxcar (roof walk, ladders), two ore cars, tender, cab. `[D, Sean 2026-11-01 #542, #552; inventory]`
12. The express messenger is bleeding in the express car; each minute Harlan spends tending him is ground covered toward the break. `[D v2]`
13. Gang A holds the engineer off the levers (his lookout would otherwise stop the train at the break by itself). `[P, build check 2026-11-09]`
14. He stops it one of five (six) ways, below; "brake far enough before the break and it stops; too late and it derails for real." `[D, #542]`
15. The great trestle is crossed safely on the way. `[D inventory/valley.json]`

**Choices, and what each sets:** the ways to stop it [D v2 unless marked]:
1. Fight to the cab and brake.
2. The brake wheels: wind each car's hand brake down from the roof walk, under fire.
3. The air: Gang A has closed the angle cocks; opening them (or the messenger telling him they're shut) stops it from the brake model.
4. Pull the pin behind the express car: the coach drifts free; engine, payroll, messenger and Gang A run on to the break.
5. Tell them: show Gang A a spike, or shout the rail's out; "their nerve decides". Believed, they stop the train themselves and run with the money.
6. Free the engineer `[P, build check]`.
- The big choice: "no clean answer. The payroll, the passengers, the messenger, the robbers: every way saves some and spends others" [D v2].
- Facts it sets [DECISIONS.md, rows marked D v2; `payroll.fate` row now "out of date" per DECISIONS.md header]:
  `payroll.fate` saved / lost; `gang_a.fate` fled with the money / arrested / dead; `gang_b_man.taken` yes / no.

**Endings, and what it leaves in the world:**
- Stopped in time, or derailed for real [D #542].
- The wreck stays where it fell until the repair crew clears it; the line is out for days [D v2; step 5 built]. Build check: no save system, so "days" lasts one session [P, build check 2026-11-09].
- Gang A, if they ran with the money: wanted posters (`the-bounty`). Taken alive: the jail [D v2]. (The card says "`hold-him`"; bible f12 says `hold-him` is Cody's night at the depot, so "point at the jail" [P·bible].)
- Gang B's man, taken alive, names the foreman who paid him: "a lead to the Baron and the Kid, carried by a person" [D v2].
- The messenger, if he lives, owes Harlan [D v2]; "the express company's man in town remembers" [P, v2 text].
- Payday Night that night: whatever happened, the floor still falls (two barrels) [D, Sean 2026-11-11, #830 C1 a]. Pay saved: he is pulled into the dance to celebrate [D, Sean 2026-11-11 #809]. Pay lost or train wrecked: "a hungry, angry night in the same room… He's there as the deputy who failed" [D, pick C2 b].
- Older: "Rourke steps off the train either way" [D v2 2026-11-09] → now P: Rourke is posted nearby from the start [C8 a, P until Sean nods].

**Who is in it:** Harlan; Gang A (the stick-up man among them; who they are is O, P·bible: the Colters, CONTRA s6);
Gang B, two men; the Baron's foreman (off stage, paying; he is the stranger who shot the sheriff, C10 b, C16 a); the
section foreman; the depot agent; the express messenger; the engineer (and fireman, #620); passengers from the
town's own calendar [D v2]; the travelling band in the coach [P, Sean 2026-11-11; link P·bible S24]; conductor,
brakeman, miners [P, chatgpt]; Joe maybe [P, chatgpt]; the saloon owner; the miners.

**Sean's own words:**
- 2026-11-01, #542 "What Sean wants" (recorded by the session): "**A mission: the runaway, with the tracks out.** The player fights his way through the moving train to the cab and stops it before it derails. Physics decides, not a script: brake far enough before the break and it stops; too late and it derails for real."
- 2026-11-01, #542: "**The whole train is walkable, back to front** (Sean, 2026-11-01), moving or stopped: through the coach and express car by their end doors and platforms, over the boxcar's roof by its ladders and roof walk, across or along the ore cars, over the tender to the cab, and across every gap between cars." (session's record)
- 2026-11-01, #542: "**It brings in the money:** the **payroll comes on the train** (an express or payroll car)… A car worth robbing is a ready-made target and mission." (session's record)
- 2026-11-01, #542: "**It's the same train** that is blown up on the trestle". And: "we don't know exactly where the rail line will go".
- 2026-11-01, #552 (as the card records): the train is "engine and tender, two ore cars, a boxcar, an express car (payroll and guard), a coach".
- 2026-11-07, #546 P9, Sean's example line for Harlan: "*Now what the hell is going on here?*" (context, session's record: "you've dealt with the men who blew the track, you race to the train, climb aboard and find it being robbed").
- 2026-11-07, #276 (session's record): "**a man alone practising his stick-up** in front of a mirror. Later he's **in the train robbery** (the payroll train, #542), and the player can recognise him."
- 2026-11-09, #542: "the runaway train mission (step 7: tracks out, fight through the cars, stop it before it derails) is named \"Hell on Wheels\"."
- 2026-11-09, on v2 [card]: "Yes fold it in with all the ticks".
- 2026-11-09, on the story judge's three changes [card]: "Yes I like the ticks"; "Yes to payday night".
- 2026-11-09, inventory "9. Runaway Payroll Train · Approved · Version A selected · One of our most developed action missions.": "Two outlaw gangs are involved in an attempted payroll train robbery." "Gang B sabotages a stretch of track to the west." "Harlan fights the saboteurs, then races east to catch the approaching train." "Gang A has boarded the train and taken control." "The preferred boarding method is jumping from the small wagon-road overpass onto the train roof, with horseback boarding as an alternative." "The player fights through six walkable railcars, progressing from the rear toward the locomotive." "The player must reach the controls and stop the train before it reaches the destroyed track." "The mission makes use of moving-train physics, couplers, destructible objects and combat in confined spaces." "Important continuity: The small wooden overpass is the boarding location. It is not the large canyon trestle destroyed in the finale."
- 2026-11-09, inventory: "Early train encounter: Harlan travels under the small railway overpass during one or two early missions, establishing the landmark before the payroll train sequence."
- 2026-11-11, #809: "Is this not supposed to happen after you stop the train from being robbed and derailed".
- 2026-11-11, #744 (session's record, "OPEN (Sean unsure): the payroll"): "If the player saves it, does the outrage still happen? Options on the table: A, the Baron finds another way (the twist: he claims the deputy stole it); B, saving it really stops the outrage and he tries something else later."
- 2026-11-11, #830, pick **C1: a** (the option's wording): "Two barrels: the Baron planned the wreck and the floor for the same day. Saving the pay changes nothing for him."

**Lines of dialogue anyone gave:**
- Harlan: "Now what the hell is going on here?" [Sean, 2026-11-07, #546 P9; P as "Harlan's rare lines"].
- Barkeep: "Payroll's on Thursday's train. Now, wasn't that worth the price of a drink?" [bible, VOICES].
- Section foreman: "Spikes drawn, two rail lengths, west of the tank. And two riders I never saw before." [bible, VOICES]
- Express messenger: "They've shut the cocks. Part her and she'll run on. Open the cocks first." [bible, VOICES]
- Depot agent: "She's four minutes down by my clock. The town's clock don't signify." [bible, VOICES]
- The foreman to the men at the rail, overheard: "Two lengths and go home. Not a spike more." [bible, VOICES; "P·bible… wait on s21"]
- The shout: "the rail's out!" [session, v2].
- Built or scripted lines: none found.

**Pays off from earlier / plants for later:**
- Pays off: S5 the steward (the messenger) [D v2]; S8 the same train and the overpass met early on the widow's road [D/inventory]; S20 the stick-up man [P]; S21 Thursday's train [D v2]; S36 clocks: the windows "read off the depot clock" [P]; M12: the saloon owner sold the payroll's day to Gang A first [P·bible].
- Plants: the people saved at noon fall at night (the band, the coach's riders) [P·bible S24]; Gang B's man as one of the voices who name the paymaster (S30) and the foreman (K7, K11); the Shipment: he or the Kid says the foreman pays "out of the coach" [P·bible M4]; the telegrams: the Baron's man wires east "after the train" [P·bible S26]; "Makes the railway familiar" for the trestle finale [P, chatgpt]; `the-bounty` strengthens "only if the wanted man is an escaped Hell on Wheels robber" [P, judged_story].

**Every other idea found:**
- Other names: "the runaway" (#542 step 7); "Runaway Payroll Train" (valley.json, inventory) [card].
- ChatGPT's card for this plot is titled "THE BRIDGE IS OUT" by a provisional title swap; Sean's titles win (Hell on Wheels = runaway; The Bridge Is Out = trestle) [chatgpt §3, §"mapping is provisional"; D Sean 2026-11-09 #542, #466].
- Length "35–50 minutes" [P, chatgpt].
- "Track workers or a rider bring news of damage, or Harlan encounters armed men near the western line. The normal train's sound and passage establish that a train is still due." [P, chatgpt]
- No hidden countdown: the crisis starts "through observable player/world events" [P, chatgpt].
- Sabotage site "beyond the Ore Works" [P, chatgpt] vs "west of the depot, before the Ore Works" [D v2].
- At the break: "engage, scare off, arrest survivors, inspect damage or retreat" [P, chatgpt].
- "signal the crew" as a way [P, chatgpt]; "Lower-profile: … board from a quieter position, move through cars with fewer fights and protect civilians" [P, chatgpt]; "sneak past" [P, chatgpt].
- "A forgiving but missable leap from overpass to train roof" [P, chatgpt "Keep these details"].
- "Partial rescue: Stop only some cars or warn workers if full braking fails" [P, chatgpt].
- "Do nothing: The railway suffers a collision or wreck; the story continues with damage." [P, chatgpt]
- Big choice as speed vs helping people aboard, "made through physical route and rescue actions, not a presented menu" [P, chatgpt].
- "If the engineer or gang leader dies, train systems and other gang members continue; surviving crew may help" [P, chatgpt].
- Flee or give up: "The train wrecks or is stopped by somebody else at a cost" [P, chatgpt].
- The unthinkable: Harlan "shoots surrendered bandits or innocent crew, steals the money, destroys a car, or deliberately speeds the train toward the break" [P, chatgpt]; "Harlan: railway rescuer or opportunist" [P, chatgpt].
- After: "The mine thanks him, though the money's owner may still question missing funds"; "Harlan may profit but lose trust"; "the railroad may blame Harlan for not acting"; "Baron and mine interests exploit the disaster differently" [all P, chatgpt].
- Two gang leaders with "distinguishing hat/coat colours OPEN" [P, chatgpt].
- "Avoid one modern emergency lever stopping all cars instantly" [P, chatgpt].
- O (chatgpt): gold going out or pay coming in, "and who owns it"; passenger load and crew count; how service resumes. (v2: the mine's payroll, westbound for the Ore Works, in the express car's safe [D v2].)
- "A Payday Night celebration after rescue has been proposed but not locked" [P, chatgpt; later D, Sean 2026-11-11].
- Boarding numbers: 2.0 m drop to the coach roof, 2.4 m to the boxcar, 3.8 m into an ore car; 679 m overpass to trestle, "1:51 at 22 km/h"; full stop "54 m from 22 km/h, 109 m from 32 and 166 m from 40" [P, valley-plan §4 via card].
- Valley.json: `bridge_b` deck over rail 5.45, cut depth 6.5 [valley.json]; the card says "(1912, -229), deck 11.2, the rail cut under it at 5.7" [card].
- "Where the gang breaks the track is the mission's choice (the trestle's approach, or past it toward town)" [P, valley-plan §4; v2 puts it west of the depot].
- The siding: ride ahead, throw the switch to the rail yard, the train wrecks into the freight warehouse or stock pens; "The town takes the wreck instead of the passengers" [P v2 → **cut**, Sean's tick 2026-11-09].
- Pull the pin: judged_set says cut it ("its window can't be seen; the air cocks give the same 'part the train' choice more readably") [P, judged_set; not answered by Sean that I found]. Build check: 6.5 cm of slack is too brief, use "the coupler's force low for a moment"; `TrainSim` can't uncouple today [P].
- The freed coach rolls back east on the +1.8% grade unless its hand brake is wound [P, build check].
- Air on two cars (20% of the train) won't stop it under steam; the cocks matter once the regulator is shut or the train parted [P, build check].
- Raise 1: the break where it can be seen from the train, "a section man's red flag at the rail (period practice)" [P, judged_set].
- Raise 2: the derail grades with speed: slow, the engine ploughs off upright; fast, the cars jackknife [P, judged_set].
- Judge's hear-of-it ideas not all taken: "the daily train late and the depot restless"; "track being broken or shots heard from the wagon road"; "Gang A's horses tied at the overpass" [P, judged].
- Stick-up man: "arrest him and the gang is a man short; follow him to the gang's camp; or recognise him on the train" [P, #276]; #276 also: "the robbery is a man short or doesn't happen"; he mouths "his partner's name" [P, #276].
- "stick-up" is a 20th-century word: say "hold-up" [bible, WORDS].
- Adair, Iowa, 1873 (James–Younger) as the period's method [D v2 as a correction; "to check"].
- To check before building: what brakes the D&RG's narrow-gauge cars had in 1882 [D v2].
- "two gangs on one payroll reads like a film" [P, judged, as a criticism].
- Scores: card 17/35; v2 26/35; set piece 5 (low) [judged, judged_set].
- Build order: break found done, the warning, the blow-through; then brakes and cocks; step 7 at its narrowest (gang at posts, player moving); then the pin and "tell them"; the rest as flags and lines [P, build check].
- Size: "about 4 large…, 6 medium, 8 small, on top of train step 7" [P, build check].
- Systems named as new: per-car hand brakes and angle cocks in the 1D brake model; a third shout kind "rail's out!"; the payroll in a strongbox; gratitude in `Relations`; the faction plan (the foreman pays Gang B); the coach's riders from schedules [v2, build check].
- Train details on #542 that touch it: men can't climb ladders yet; wheels aren't solid; "a man thrown off at speed" is a step 7 film [#542].
- Tied to the Tracks was cut because it "repeats Hell on Wheels" [D, Sean 2026-11-09, README]; inventory said it "Builds on the railway mechanics established during the payroll train mission".
- `bank-robbery` "overlaps Hell on Wheels' robbery" [P, judged_story].
- Version B "the deputy stole it": the pay saved but short, the Baron's men say the deputy took it ("Sean's own twist"); not picked, "could still be added to A later" [P, Sean 2026-11-11 #744; OUTLINE].
- Version C "it really worked" (the bible leaned to it); not picked [P·bible, CONTRA C1].
- C2 a (not picked): a wreck with Harlan aboard kills him, he wakes at the doctor's and the day is replayed; C2 c (not picked): the wreck was the outrage, no dance [P·bible, CONTRA C2].
- If the foreman was taken or killed at the farmhouse, "another man pays Gang B" [P·bible, CONTRA f6].
- Train sim for the far train, dented metal: see "Ideas with no mission".

**Where the sources disagree:**
- **Does saving the pay matter?** v2 (D 2026-11-09): what he keeps alive "decides what Payday Night is". Sean 2026-11-11 (C1 a, C2 b): the floor falls either way; only the room's mood changes. Latest favours C1 a/C2 b.
- **The outrage that brings Rourke.** 2026-11-09 (D): "the attack on the payroll brings Rourke in on the train". C8 a (P until Sean nods): Rourke's side is posted nearby from the start. Unsettled until the nod; the bible writes to C8 a.
- **Is the robbery one mission with the runaway?** Card: O. Inventory (D): one mission, two gangs. Settled: one.
- **Where the break is.** Inventory: "to the west", then "races east"; valley-plan: the trestle's approach or past it; v2: west of the depot; chatgpt: beyond the Ore Works. v2 is the adopted one; the ride's length is O.
- **Who Gang A is.** O [card; CONTRA #3, s6]. P·bible: the Colters.
- **Prisoners "fill the jail (`hold-him`)"** [card] vs `hold-him` now being Cody's night at the depot's tank [C7 c; f12].
- **The pin:** adopted in v2 (D) vs the set-piece judge's cut (P). Unsettled.
- **Horseback boarding:** D in the inventory vs not playable today (build check). Unsettled; build-side.
- **One daily train's hour:** "the noon train" (payday card) vs "before dawn" (hold-him) [f15, O].
- **A wrecked train and the band on it:** how the band comes is O (s23).

**Open questions:**
- Who Gang A is, and who leads each gang.
- Whether Joe rides along (only chatgpt mentions him).
- How Harlan reaches the train from the break (distance; horses).
- What Harlan may carry aboard (no source says).
- The pin: keep or cut. The sixth way (free the engineer): Sean hasn't nodded.
- If the foreman is dead or jailed by now, who paid Gang B (f6).
- Whether the "deputy stole it" twist is added.
- History still "to check": the D&RG's brakes in 1882; Adair.

---

### Payday Night (`payday-night`)

**Where it sits:** Act III, second, "that same night" as Hell on Wheels [D, OUTLINE]. The middle's turning point
[D, Sean 2026-11-09]. **Not built as a mission.** Built around it:
- Saloon B (the Salt Creek saloon) with a dance hall over the bar, its floor real framing; `sabotage` in
  `config/buildings/saloon_b.json` names the girder (`beam/east/2`) and the kerf; `SpecBuilding.saw_girder()` cuts
  it and the panel (11 ft along the girder, 18 ft each side, 22 joists, 72 boards, a stretch of the well's rail) drops
  on the bar; tested in `tests/test_building_saloon_b.gd` [experiments/building_lab/saloon_b/README.md;
  src/structures/spec_building.gd:3042; docs/lanes/gameplay.md line 49]. "A girder only half sawn holds in the game
  as in the brief… the mission cuts it through at its moment" [saloon_b README].
- The outside stair in the yard ("Payday Night's two men and a saw; seen from Main Street across the yard's gate") and
  a place for "Payday Night's saw, in the store room till it's carried up the outside stair" [saloon_b.json].
- Props: `handsaw`, `fiddle`, `fiddle_bow` [assets/props/kit; PARTS.md, #879].
- The band: `src/audio/band.gd`, `config/band.json`: on the `payday` day kind all six parts play on saloon B's stage
  (16 x 8 ft, #902), the stage's own upright, curtain open; two tunes ("Payday Night", an original reel, and Turkey
  in the Straw); plays faster through a fist fight; a shot stops them; a killing ends the night [#938 done, PR #989].
- The calendar: `payday` every 14 days from day 13 [config/valley_folk.json, "PROPOSED"]; the townsfolk brief says
  payday is "not in the slice".
- The floor lab (#745, "experiments/payday_floor/") was opened by Sean 2026-11-09 but has no comments and no folder
  in the tree: not found. (Its spec still says "one joist sawn half through" in the old spec saloon; superseded by
  #772's girder in saloon B.)
- No `src/missions/` file, no moment, no script. Rourke, the surgeon, the letter, first aid on another man: not built.

**In one line:** That night the town's dance floor, whose girder the Baron's men have sawn, comes down under the
payday crowd whatever Harlan did on the train; then one doctor, too many wounded, and Rourke with an Army surgeon and
a letter already written for the deputy to sign [D: OUTLINE row 2; Sean 2026-11-11 #809, #830 C1 a, C2 b, C3 b; v6
for the letter].

**Harlan walks in with:**
- Gun: not stated. (The sheriff's revolver since day 2; the Winchester if he has it: as Hell on Wheels.)
- Badge: deputy [D, Sean 2026-11-09].
- Horse, dynamite: not stated.
- Companion: Joe as "a second pair of eyes" on the outside stair [D v6, 2026-11-09]; "Payday Night's watcher is optional" if Joe is dead [D, Sean 2026-11-11 #744]; the set-piece judge would cut him [P]; bible f9: he comes only if the rope's outcome lets him [P·bible].
- Wounds: whatever the train left; "can even be a victim but hopefully not die" in the fall [D, Sean 2026-11-11].
- What he knows: that he saved the pay (or failed) at noon. Of the cut: nothing, unless he found one of the "1 or 2 hard to find ways" [D that they exist, Sean; placing P·bible S23].
- A steward's hands [D, DESIGN §6 / C15 a].

**How he hears of it:**
- "the player should be pulled in there to celebrate saving the pay" [D, Sean 2026-11-11 #809]; the town "pulls him into the dance" [OUTLINE].
- If the pay was lost: he's there "as the deputy who failed" [D, pick C2 b]. How he comes to be in the room then: not stated.
- Older (v6, D 2026-11-09): "the barkeep wants the deputy on Main Street"; the crash "heard across town"; "If Harlan is away, the night still happens and the wounded are laid in the street… so he can ride into the middle of it." Not withdrawn in words; the being-away case sits oddly with "pulled in" [unsettled].
- Older (v2, P): the church bell rings; "The doctor sends for the steward"; men run for the deputy.

**Beats, in order:**
1. Before, on an ordinary payday: the saloons loud, the fiddler, the floor full, nothing wrong; "He's seen that floor hold." `[P·bible, S22; Sean 2026-11-01 only said payday makes the saloons rowdy]`
2. A travelling band gets down from the payroll's train with more instruments than the town has seen. `[P, Sean 2026-11-11 #809; "in the coach Harlan saved" is P·bible S24]`
3. The Baron's two men buy a handsaw that day; the storekeeper writes it in his day-book. `[D v6 for the day-book; "bought that morning, before anyone knew how the train would go" P·bible; when the girder is cut is O, s23]`
4. The two men go up the saloon's outside stair with the saw and cut the girder over the bar. `[D: the girder, Sean 2026-11-10 #772; the stair v4–v6 and saloon_b.json]`
5. Rourke and an Army surgeon (with a hospital steward and two privates) are at the hotel, the Baron's guests. `[D v6 2026-11-09; where Rourke comes from is now C8 a, P]`
6. Evening: Harlan is pulled into the dance to celebrate saving the pay. `[D, Sean 2026-11-11]` Or a hungry, angry night in the same room. `[D, C2 b]`
7. The band plays on the dance hall's stage. `[D that the full band plays there, Sean 2026-11-14 #938; built]`
8. The Kid drinks at the bar, under the cut. `[D v6; OUTLINE "D"; f7: only if he lived the farmhouse]`
9. The two men buy the fiddler drinks and call for stamping reels, and keep near the outside stair, not under the floor. `[D v6; the bible neither keeps nor strikes it]`
10. If Harlan has found out (the day-book, or the pale cut seen from below with a lamp), "he can only be ready: nobody believes the deputy on payday." Knowing "changes where he stands and what he has to hand, and nothing in the room." `[D, C3 b; the two tells P·bible S23]`
11. Last seconds, for everyone: the floor creaks and bows; dust sifts into the drinks at the bar. `[D v6; S23: "a warning to step back, not a way to find out"]`
12. The floor comes down on the bar. Harlan is "an observer to the event and can even be a victim but hopefully not die". `[D, Sean 2026-11-11]`
13. The wounded: wounds come from the fall and the timbers, never placed; "the physiology decides who lives". Triage: body to body, tourniquet, dressing, splint; leave the man who can wait, find the one who's quiet. `[D v6]`
14. He can shout a townsman to a casualty to hold pressure or drag him to the doctor's. `[D v6]`
15. When the wounded outnumber what the one doctor can take, Rourke comes with his surgeon and offers him for the deputy's signature on a letter: "that the town's law could not cope and asked the Army's help". `[D v6, "a rule, not a branch"]`
16. The overrun doctor is the one who asks the deputy to sign. `[D v6]`
17. The letter can be read before signing: the hotel's paper, "the ink long dry, dated that afternoon". `[D v6; S7]`
18. Rourke's first look at Harlan is "held a beat too long before he says 'Deputy'". `[P·bible, S38; that they have a past is D, C15 a]`
19. Sign or refuse (below). Witnesses remember which. `[D v6]`
20. After: the dead buried, the maimed marked, the rubble and the sawn girder stay. `[D v6; "girder" by #772]`

**Choices, and what each sets:**
- **Sign:** men live tonight who'd have died; Rourke holds a letter in the deputy's hand; no legal force, "political ammunition"; it goes to the governor; the captain reads it next day; the men the Army's surgeon saves "owe the Army, not Harlan" and some speak for the soldiers to the captain [D v6]. Sets `payday.letter = signed` [DECISIONS.md].
- **Refuse:** "the town keeps its law, and some of tonight's dead would have lived" [D v6]. `payday.letter = refused`. Callback: Rourke, when he won't sign, if Harlan shook his head at the oath on day 2 [P·bible, SETUPS callbacks table].
- **Never offered:** if the wounded don't outnumber the doctor's hands [D v6 rule]. Whether that can still happen now the floor always falls: not stated.
- **Prepare the doctor's** (lamps, water, tables, hands) before the crowd peaks: raises what he can take, "can deny Rourke his offer" [D v6]. Under C3 b this is the kind of "being ready" left to him; but C3 b's wording says knowing changes "nothing in the room" [unsettled whether the doctor's counts].
- **The Kid or the next man:** triage by need, or by what the living man knows [D v6].
- **Who he goes to first:** families remember [D v6].
- **Proof:** `payday.proof` = the cut found / the day-book / the witness / none; read by I Am the Law [DECISIONS.md, D v6].
- Superseded (v6's ways that prevent it): follow the traces and arrest the two men; break their routine (stop the fiddler or the men buying reels); thin it (the barkeep's free round); clear it; expose it [D 2026-11-09 → out, OUTLINE "Cards now out of date", C3 b]. `payday.floor = held` is out of date [DECISIONS.md header].

**Endings, and what it leaves in the world:**
- The floor falls: always [D, Sean 2026-11-11].
- People: the dead buried; the maimed marked for good; the saved owing Harlan (or the Army); families remembering who he went to first [D v6].
- The building: the broken floor and rubble stay, the sawn girder among them "for anyone to find" [D v6]; "What stays broken: the saloon's floor" on the last walk [OUTLINE]. The barkeep: "Lord God. My floor." [bible].
- The letter, if signed, exists: "Rourke has it, the captain counts it, the Baron uses it" [D v6].
- The proof fights the letter next day (the girder, the day-book, the witness) [D v6].
- "The soldiers camp at the depot" [D v6] → only a surgeon, a steward and two privates came: "Rourke's detail" [P·bible f10].
- The Kid: "alive, he talks, in his own time; dead, that thread loses its voice" [D v6].
- "the deputy is a steward; people bring him their wounds after this" [D v6; v5 judge: "has no system behind it"].
- The Balcony Ambush: "the men who sawed the girder, drinking on the hotel's gallery the night after" [D, pick C9 a]; which night and how he knows them is O (s22).
- "The same men stand at the grave, on the dance floor and at the rope" [P·bible, OUTLINE "who knows what" table, the town].

**Who is in it:** Harlan; the payday crowd (about twelve dancers upstairs, the bar full below [D v6; build limit]);
the band (six parts built; fiddler and piano player are named townsfolk in `valley_folk.json`); the band's leader
[P·bible]; the barkeep; the Baron's two men (one "with sawdust still on his coat" in v6); the Kid; the storekeeper;
the woman across the street (v6 witness; the bible drops her as a way to find out); one doctor; Rourke; the Army
surgeon; his hospital steward and two privates; the Baron (host at the hotel, off stage); Joe maybe; the people
Harlan saved on the train [P·bible].

**Sean's own words:**
- 2026-11-01, #276 (session's record): "**payday makes the saloons rowdy.**" "When the miners and the other local and area workers are paid, the saloons are **far rowdier**. Payday should be a night you notice."
- 2026-11-09, inventory: "13. Payday Night | After the payroll train incident, Salt Creek celebrates. Harlan drinks with townspeople. A serious event interrupts the evening, potentially Rourke's arrival or a shooting. | Direction discussed"
- 2026-11-09, inventory: "I think Payday Night, The Inquest, The Wrong Ball and Dig Him Up are worth reviewing together because they may form a single connected story arc rather than four independent missions."
- 2026-11-09 [card]: "Yes to payday night".
- 2026-11-09 [v2]: "make me a 30/35 mission".
- 2026-11-09 [card]: "Yeah, took it all".
- 2026-11-09 [card]: "we're still keeping as deputy. I don't know if we become sheriff ever in the game."
- 2026-11-09 [payday-inquest, MAP]: "we need rourke to come no matter what because if Joe kills him we should still meet him".
- 2026-11-09 [payday-inquest]: "Yeah I'm not sold on the whole evidence and trial stuff yet - that's a maybe" (later replaced: evidence is real, D 2026-11-11 #744).
- 2026-11-09, #745: "open the lab issue for the Payday Night floor".
- 2026-11-09, on the balcony [CONTRA C9]: "I could take out these bad guys by doing what they did to innocent people"; "We still have to find a reason for that."
- 2026-11-10, PR #772 [saloon-design.md]: "an open view from the upper floor down to the main floor so people can fall over the rail"; "give both a hall I guess". Recorded there as his decision: "The Baron's men saw the girder over the bar (a half-sawn joist would hold)."
- 2026-11-11, #809: "for the payday night what if it's a traveling band that comes on the train with more instruments?"
- 2026-11-11, #809: "I think we should just have the dance floor cut and there's maybe 1 or 2 hard to find ways to find out about it - I think it's an event that should happen".
- 2026-11-11, #809: "maybe have fable think it over - I think the player should be pulled in there to celebrate saving the pay and you're an observer to the event and can even be a victim but hopefully not die".
- 2026-11-11, #809: "Is this not supposed to happen after you stop the train from being robbed and derailed".
- 2026-11-11, #830, picks by letter (the options' wording): **C1 a** "Two barrels: the Baron planned the wreck and the floor for the same day. Saving the pay changes nothing for him." **C3 b** "If he finds out about the floor he can only be ready: nobody believes the deputy on payday." **C2 b** "If the pay is lost or the train wrecks: a hungry, angry night in the same room, and the floor still falls. He's there as the deputy who failed." **C9 a** "The Balcony Ambush: the men who sawed the girder, drinking on the hotel's gallery the night after."
- 2026-11-11, #744 (session's record): "Payday Night's watcher is optional" (among the paths without Joe).
- 2026-11-13, #902 [saloon_b.json]: 'put it where it fits best; 16 x 8 ft for now' (the stage).
- 2026-11-14, #938: "Yes" to: "**Payday Night:** the full band upstairs on the dance hall's stage… with a **second upright piano on the stage**…: the dance hall keeps its own piano, nobody hauls one upstairs." (the session's wording, his yes)

**Lines of dialogue anyone gave:**
- Rourke [bible, VOICES]: "My surgeon is at your service, Deputy. I ask only that the thing be done regularly." · "It is a small matter to write your name. Men are dying while you read." · "A town that cannot keep its own peace will have it kept."
- Rourke [session, v2]: "Let my men help, Deputy."
- The Army surgeon [bible]: "Lay him there. Not that one. He'll keep."
- The storekeeper [bible]: "One handsaw, to a man I never saw before. It's in the book. Everything's in the book."
- The band's leader [bible, P]: "We play till the floor quits, gentlemen!"
- The barkeep [bible]: "Lord God. My floor."
- The letter's sense [v6]: "that the town's law could not cope and asked the Army's help" (not a written text).
- Built or scripted lines: none found.

**Pays off from earlier / plants for later:**
- Pays off: Hell on Wheels (the pay; the people saved); S5 the steward; S22 the ordinary payday [P·bible]; S23 the two tells [P·bible]; S24 the band [P]; S6/S38 Rourke and his look; Earl, "the first man Harlan fails to save in front of the town" [P·bible, SETUPS]; the barkeep who counts cost ("four dollars and a chair") and "his floor" [P·bible]; packing the sheriff's wound → "Payday Night's triage; Rourke's hospital steward looking at his work" [P·bible]; the Kid from the farmhouse porch.
- Plants: S7 the letter's date (pays off with the captain and in "what people saw"); the sawn girder, the day-book and the witness as proof for the captain [D v6]; S29 the floor they dropped → the Balcony Ambush [D C9 a]; K8/K9 (the girder was sawn; Rourke is paid: "suspects at B12 (the letter's date)"); the saved who owe the Army speak to the captain; the telegram east "after" the night [P·bible S26]; the doctor's opinion of Harlan "and what the doctor does for him later" [D v6].

**Every other idea found:**
- v2 (P, 2026-11-09, 27/35): no sabotage; the floor "was built for half of them"; forty dancers; the upstairs gallery sags (`BuildingAge`); tell the owner; the owner "resents the lost night"; "nobody believes Harlan was right because nothing happened"; the church bell; the doctor sends for the steward ("he knows Harlan's past from the sheriff's last hours on day 1"); "Even if the doctor is dead, the wounded lie in the street"; a man pinned under a joist; "a woman bleeding from the thigh"; "a man who seems fine and isn't (a ruptured spleen)"; cuts from glass; lift the joist with men, lever it, or cut it free ("a cut in the wrong place drops more of the floor"); the doctor asks Harlan to hold a man down "while he takes the leg (the amputation moment), or to take one himself"; Rourke on **the night train** with a post surgeon and orderlies; accept → soldiers **billeted** in town and "his surgeon now knows who's who"; refuse → "he camps at the depot and waits"; the saloon "shut until it's rebuilt (over days, if at all)"; prototype in the old town's saloon. Superseded by v3–v6.
- v2's cuts by the judge/build check: the amputation (cut; `HumanBody.amputate` exists, nothing calls it); the lever and the axe (fallen pieces are rubble outside the support graph); the night train; forty dancers → about twelve, staggered; the old town saloon (its "balcony" is a stair landing).
- v3 (P, 27/35): first sawn joist; the Baron's men cut it "in the afternoon"; "Two of them are in the crowd to see it happen"; "The Baron's men want [the Kid] dead tonight: he's been talking"; two killers go against the flow toward the Kid ("Fight in the dark") → cut by v3's judge; if cleared, "a shooting in the packed street, meant to look like a riot" → cut in v6; Rourke "comes out at the crash"; the offer as "a request for Army aid"; "the floor that falls is the only proof of what the Baron did"; "more of them [soldiers] if the town asked".
- v3 judge (P): prop the joist; the saw seen going up; Rourke's offer as a rule; "put the Kid among the possible wounded instead".
- v4 (P, 29/35): a **bucksaw** → corrected to a **handsaw** (v4 judge); "Stop the fiddler (he stops for the deputy, or for a coin)"; arrest "quietly"; "enough men together lift the timber off the pinned man" → cut (v4 judge).
- v5 (P, 28/35): Rourke's "department sent him to look into the attack on the railroad, with a post surgeon for its wounded (the express messenger, the brakemen)" → dropped as untrue to 1882; **the railroad's company surgeon** at the depot "treats the railroad's men first" and "reports the night to the company that brought Rourke in" → cut (v5 judge: "his dilemma repeats Rourke's").
- v6 (D 2026-11-09 "took it all"; now partly out): nine ways; the woman across the street; sawdust on the landing and in the floor cracks; sawdust on one man's coat; the cut "pale in one joist" from the bar; plaster dust thicker where the cut is, "right where the Kid sits"; "If the floor holds, they leave town and the Baron's outrage waits for another night"; arresting them costs (nothing chargeable, friends push back, "they walk free in the morning"); stop the fiddler; the free round ("half the dancers come down"); clear it ("the two men ride out"); expose it ("the Baron's men learn you know, and act"); "the cleaner the night, the less anyone believes it was ever in danger"; Joe's place as a cost because of "a drunk payday crowd's hostility to a Ute man… (written with care)"; Rourke "on their way to their new post at Fort Lewis… stop over in Salt Creek for the night".
- v6 judges' two ideas that pulled against each other: Judge A cut the storekeeper's saw-sale; Judge B added the day-book. "the day-book was kept and the cut of the saw-sale clue wasn't; OPEN if Sean meant otherwise" [card].
- Bible's reading of v6's traces under C3 b: sawdust on a coat and the woman across the street "would make it easy to find, so they go, or become things people only say afterwards" [P·bible, CONTRA C3].
- C3 a (not picked; the bible leaned to it): "He can blunt it, not stop it… get some people off the floor, stand clear, send Joe to the stair, have the doctor's made ready. Fewer fall, Rourke's offer is smaller". C3 c (not picked): he can stop it and the outrage comes another way [CONTRA C3].
- "the band's piano is already up there" / "Six men carry their piano up the saloon's stair that afternoon"; "the piano is why a sawn girder that held the afternoon doesn't hold the dance" [P·bible S24, C3 a].
- Master chat's notes on the band [P, #809]: "the band on the payroll's train makes payday the town's night; a troupe of strangers is cover for the Baron's hired guns (one could be the plant) ahead of the Balcony Ambush; the band's noise masks shots and steps." Not placed by the bible.
- The stage has "a painted backdrop of Salt Creek as the Baron promises it" and a red draw curtain: "Payday Night's acts" [saloon_b README; spec_building.gd:3197].
- The band stops dead at a shot, plays faster through a fist fight, is "done for the night" at a killing within range [built, band.gd]. What it does when the floor goes: not stated.
- Shore it: "a timber wedged under the cut joist moves the load path; done badly it moves the break to the next joist" [P, judged_set]. The panic surge: "at the first crack the dancers rush the stairhead and load that end" [P, judged_set].
- Saloon B has an open well over the card tables "so people can fall over the rail" (13 ft) [D, Sean 2026-11-10]; "The dance floor stays closed over the bar, so Payday Night still drops it on the bar".
- Open joists under the dance hall: "the girder, the joists and the fresh cut are seen from the bar, dust sifts through the floorboards" [D, Sean 2026-11-10 #772]. So the "plaster dust" of v6 is dust through floorboards, no plaster ceiling.
- Engineering: a joist sawn half through "sags and cracks but doesn't fall"; a girder sawn half through fails at ~75 lb/sq ft; "Every collapse of the period found was a girder or a bearing (Richmond 1870, 62 dead)"; a dancing crowd 70 lb/ft² (Hatfield) [saloon-design.md; saloon_b.json].
- Props list: "sawdust on the landing (a `FloorMarks` kind, new)… the hanging lamps swaying, glasses on the bar for the dust to fall into" [saloon-design.md].
- Concept notes: the two men seen going up the stair "in full view of the butcher's across" (A) / "seen from Main Street across the yard's gate" (B, picked) [saloon-design.md].
- "A wounded killer in the loft over the bar is found by his blood dripping into a beer glass" (a film/game reference in saloon-design.md §, line 604; not ours).
- #745's lab spec: crowds of 4, 8, 12, 16 by seed; `stamp_factor`; a creak at ~0.7 utilisation; "a joist frozen by RubbleSleep on a man is accidentally a 'pin' (useful later)"; "seven men going limp on one tick made 140 ms at Sean's: stagger them"; the triage needs "a thigh bleeder, a pinned man, a quiet spleen" often enough "without placing them" [#745].
- Calendar: payday "every 14 from day 13" on a Saturday [valley_folk.json, PROPOSED] vs "Thursday's train" [D v2]. #276: monthly, weekly or fortnightly "Sean's call".
- #276 (older, P): the payroll comes on the stage with a shotgun guard; "the storekeeper's ledger of what everyone owes, settled on payday".
- #546 P3 (P, not accepted): the Baron "buys a round on payday".
- inventory's event: "potentially Rourke's arrival or a shooting" [P].
- Carded first in `payday-inquest` with the Inquest, the Wrong Ball, Dig Him Up; story judge: keep only Payday Night as the hinge [judged_story]. The Inquest / Wrong Ball are another reader's.
- 1882 notes [v6]: carbolic used unevenly; triage by need was Larrey's; Letterman's was ambulances; Hospital Corps 1887; RS §5297, §§5298–5299; no quartering in peacetime; Fort Lewis moved 1880 to the La Plata valley; "An Army officer would not be sent about a private railroad's payroll".
- Systems sized in v6: opinions crediting whoever treated a man; the day-book readable; the letter readable ("an object the player reads, not carries"); first aid on another man (roadmap 3.1c); Rourke "large (a new character)".
- Scores: v2 27, v3 27, v4 29, v5 28, v6 30 and 28; set piece 5 [proposals; judged_set].
- "One hour for [the train], said once" [P·bible f15]: the card's "noon train".
- `kid-wants-out` is "Open in Act III (P, unplaced)" around this night [OUTLINE].
- Balcony afterwards, how he knows the men: "the storekeeper's day-book (S23), Gang B's man, or the Kid" [options, none picked, s22].

**Where the sources disagree:**
- **Can it be prevented?** v6 (D 2026-11-09, "Yeah, took it all"): yes, several ways. Sean 2026-11-11: "an event that should happen"; C3 b: he can only be ready. **Latest: it always falls.**
- **Joists or girder.** v3–v6 and #745: a joist. Sean 2026-11-10 (#772): the girder. **Latest: girder** (and built).
- **Which saloon.** v6: the Railroad Saloon (`second_saloon`). #772: Sean put the dance hall in the Salt Creek saloon (B) and said "give both a hall I guess… Payday Night can play in either; its card says which". Bible s11 reads "#772's, the later word"; the band and the sabotage are built in saloon B. Sean hasn't said it in words: **leans saloon B, not stated outright.**
- **The piano.** Bible S24 (P·bible): six men carry the band's piano up the stair, and it is why the girder fails. Sean 2026-11-14 (#938, later): "the dance hall keeps its own piano, nobody hauls one upstairs". **Latest favours no hauled piano**; the bible's reason for "held the afternoon, not the dance" then needs another cause. Also saloon B's README: a half-sawn girder holds in the game; "the mission cuts it through at its moment" (build fact, against "the load paths decide").
- **Who plays.** v2–v6: "a fiddler". Sean 2026-11-11: a travelling band off the train (P). Built: a six-part band, two of them the town's own fiddler and pianist. Whether the band are strangers or locals: unsettled.
- **How easy the tells are.** v6: traces "all afternoon, for anyone". Sean: "1 or 2 hard to find". **Latest: one or two, hard.** Which two: P·bible (he "was shown them and didn't change them, which isn't a pick").
- **Lost pay.** Sean 2026-11-11 (#809) describes the night as following the pay being saved; v2/v6: "a celebration, a hungry night, or a funeral"; C2 b: a hungry, angry night, floor still falls. **Latest: C2 b.** "A funeral" (wreck with dead) has no separate treatment now.
- **Rourke's arrival.** Inventory: "potentially Rourke's arrival"; D 2026-11-09: he comes in on the train; v2: the night train; v5: sent by his department; v6: passing through to Fort Lewis; C8 a (P): posted nearby already, "comes from his post, not on his way to it" (s15). **Unsettled until Sean nods on C8.**
- **Soldiers.** v2: billeted in town; v3–v6: camp at the depot; bible f10: only four men came.
- **Is the offer on every path?** v6: only when the wounded outnumber the doctor (and preparing can deny it). OUTLINE writes it as what happens. Unsettled.
- **If Harlan is away.** v6: the night happens without him. Sean: he's pulled in, an observer. Unsettled (not withdrawn).
- **Joe on the stair.** v6 D; judged_set cut; #744 "optional"; f9 gate on the rope.
- **Why drop the floor after a wreck** (the outrage already landed): O, s23.
- **The two men's fate.** v6: ride out if the floor holds / stay. C9 a: drinking on the hotel's gallery "the night after", which is the captain's day (s22).

**Open questions:**
- When the girder is cut, and what makes it go at the dance and not before (s23; the piano is out).
- Which saloon, said by Sean in words.
- Which two tells; and what "being ready" lets him do (move people? ready the doctor's? where he stands only?).
- Whether Rourke's offer can be avoided at all.
- Where Rourke is posted and whether Sean nods C8 a.
- What Rourke calls Harlan in private, and whether he says anything of their past that night ("Rourke says it at B12 or the trestle (P)", K13).
- The band: strangers off the train or the town's men; what becomes of them in the fall; how they come if the train wrecked.
- The Kid and Brody's fate read from the farmhouse (f7).
- How often payday comes, and which weekday.
- Whether the "deputy stole it" twist is added.
- Whether he is ever sheriff ("I don't know if we become sheriff ever in the game").
- Does Harlan have his gun at the dance? Not stated anywhere.

---

### I Am the Law (`i-am-the-law`)

**Where it sits:** Act III, third, "the next day" after Payday Night [D, OUTLINE; card: "after Payday Night, before
the Shipment"]. A new mission, the planning session's own idea, adopted by Sean 2026-11-09. First called "Nothing to
Report". **Not built.** Works today per the build check: sight by light, sound through walls, "Drop it!" arrests in
the dark, deeds between NPCs (`Events.deed`, `Senses.heard`) [prop build check, 2026-11-09, "nothing run"]. No
`src/missions/` file, no moment, no script. The depot's telegraph is "PROPOSED" in valley.json.

**In one line:** An Army captain spends one day in Salt Creek to report whether the town is in revolt; the Baron's men
spend that day making sure he sees one; Harlan keeps the peace without the captain seeing a fight, and Joe is the man
the Baron's men want him to see [D, Sean 2026-11-09 "I like it, add all the ticks!", card].

**Harlan walks in with:**
- Gun, horse, dynamite: not stated.
- Badge: deputy; the captain's line asks "How long have you held that badge? And who swore you?" [bible].
- Companion: Joe, if alive (the target); if dead, someone else is goaded [D, Sean 2026-11-11 #744; who: O].
- Carried over: `payday.letter` (signed / refused / never offered) and `payday.proof` [DECISIONS.md]; his standing with the storekeeper, barkeep and doctor (they testify) [D]; Joe's trust from No Justice and the rope.
- What he knows: that a floor was sawn (if he saw the cut); possibly that the letter was written before the fall.

**How he hears of it:**
- "a captain gets down at the depot with a notebook and an orderly", the day after Payday Night [D card].
- "the depot agent has the wire and tells the deputy; the town knows by noon" [D card]. The wire's text in the proposal: the governor's office wants "a report on the state of order at Salt Creek" [P prop → corrected: sent by his department commander, D history correction].
- "Joe asks Harlan what it means for his people" [D card]. No line if Joe is dead (f11; P·bible: someone from the camp, in town to trade).
- The captain came because of the Baron's telegrams east after each bad night [P·bible, S26].
- Prototype: "the captain walks in from the west road" in the old town [D card, as a prototype note].

**Beats, in order:**
1. The captain steps off the train with a notebook and an orderly. `[D card]` ("Rourke stays aboard or rides on" `[P prop; out since C8 a]`)
2. The depot agent tells the deputy; the saloon knows by noon. `[D card]`
3. Joe asks Harlan what it means for his people. `[D card]`
4. The captain walks the town on his own errands: depot, store, saloon (at noon and at night `[P prop]`), jail, church, street. He sees by the light and hears through walls like anyone. `[D card]`
5. He asks the storekeeper, the barkeep and the doctor about the law here; their opinion of Harlan goes into his report. `[D, judge's idea 2]`
6. The Baron's men stage a revolt near him: a townsman shoved until guns are drawn, a shot at dusk, and Joe goaded. `[D card; no fist fights exist]`
7. Before he rides the East Road, they leave a stolen Ute saddle and a torn-down fence for him to find. `[D, judge's idea 3]`
8. The Baron's man courts the captain over supper at the hotel; he can be offered money or shown things. `[D, judge's idea 1]`
9. Harlan can walk him to the sawn girder or the rubble, the witness, or the day-book; what he sees weighs against Rourke's letter. `[D, Sean 2026-11-09, from Payday's judge]`
10. That evening he wires his report from the depot; Harlan can read it there. `[D card; S25]`
11. The wire is heard again at the finale. `[D card]`

**Choices, and what each sets:**
- **Head trouble off quietly:** overhear the plan through a wall, find the men first, arrest them out of his sight (in the dark between lamps, behind the livery) [D]. Cost: "their own kind of lie"; the men locked up "are a grievance" [prop].
- **Steer him:** walk with him and choose where he looks; "he goes to a shot" [D].
- **Let him see the truth:** put him where he watches the Baron's man start it; "his report says 'provocateurs', but it still counts" [D].
- **Deal with the plant:** find the saddle and fence first; move it, or show who put it there [D].
- **The proof fights the letter** [D].
- **Do nothing:** "the Baron's show goes in the report" [D].
- **Cut:** getting him drunk [Sean's tick 2026-11-09].
- **Joe:** ask him to ride out for the day (the nod) and he goes, "remembering that the deputy hid him the way the law hid his wife's killer"; keep him beside you and he's the target; let him choose and he stays, in plain sight [D]. Sets `law.joe` = rode out / stayed beside / stayed by his choice [DECISIONS.md].
- **The captain's price:** "what the Baron offers him, and whether Harlan can match it with anything but the truth" [D].
- Sets `law.tally` = quiet / mixed / violent [DECISIONS.md].

**Endings, and what it leaves in the world:**
- The wire is the verdict. Quiet: "SALT CREEK QUIET. CIVIL OFFICER PRESENT AND SUFFICIENT. SEE NO CAUSE FOR TROOPS." Violent: "DISORDER GENERAL. CIVIL AUTHORITY UNEQUAL TO IT. RECOMMEND TROOPS." [bible wording, VOICES; that there is a wire Harlan reads: D].
- What it changes: "the men on the last train are always the Baron's hired men; the captain's wire changes how many, how they're armed and what the paper calls them. Rourke and a few bought men are the only uniforms." [D, pick C11 a, 2026-11-11]
- **Superseded:** "a quiet day and Rourke's men come on the last train as hired guns with no orders; a violent day and they come as soldiers under orders" [D 2026-11-09 → replaced by C11 a].
- "What the paper says of him: the deputy who kept the peace, or the man who brought it down" (the last walk) [OUTLINE].
- "The camp's trust: trusts him, cooled, or remembers being hidden" [OUTLINE].
- Joe remembers how he was asked or protected; "it shows in how he plans the Shipment and the finale" [prop].
- The men arrested fill the jail; "the Baron wants them out before the next train" [prop; f12 on `hold-him`].
- "the town remembers who kept the peace: the barkeep his chairs, the storekeeper his window" [prop].
- "the captain's own eyes" count as evidence in the ending ("What people saw") [OUTLINE].

**Who is in it:** Harlan; the captain (no name, C14 c) and his orderly; the depot agent; the Baron's men (provocateurs:
"the Colters on his pay, or his own hands" [P prop]); "the Baron's man" at supper (who: not stated; the foreman is not
named for it); Joe, or "someone from the camp in town to trade / a Mexican hand" [options, s7, O]; a townsman who is
shoved; the storekeeper, the barkeep, the doctor (testify); the witness and the day-book from Payday; the men the Army's
surgeon saved, who "speak for the soldiers" [D v6]; Rourke (off stage: "The captain will report what he sees. I have
every confidence in what he will see." [bible]).

**Sean's own words:**
- 2026-11-09 [prop]: "come up with your own mission idea".
- 2026-11-09 [card]: "the last mission you proposed has to be called \"I am the law\"" (the card: "read as this one").
- 2026-11-09 [card]: "I like it, add all the ticks!"
- 2026-11-11, #744 (session's record, D): "**the Posse Comitatus fix.** The Posse Comitatus Act (1878) bars using the Army to police the town, so the Baron's plan is to **make Salt Creek look like it's in revolt**: staged attacks, telegrams claiming the town or the Ute camp has risen up, his men goading fights in front of the visiting Army captain (I Am the Law). His lie brings the soldiers; Harlan's job as deputy is to keep the peace and expose it."
- 2026-11-11, #744 (session's record, D): if Joe dies "the later missions already have paths without him (… I Am the Law's goading falls on someone else …)".
- 2026-11-11, #830, pick **C11 a** (the option's wording): "The men on the last train are always the Baron's hired men; the captain's wire changes how many, how they're armed and what the paper calls them. Rourke and a few bought men are the only uniforms."
- 2026-11-11, #830, pick **C4 a** (Sean's words quoted there): "A - toss the costume if you don't like the idea"; after: "Keep the costume". (The raid was the Baron's first try at a Ute "outbreak"; the saddle is the second.)
- 2026-11-17 [this session, item 6]: "it's a story to tell, not a bunch of disjointed missions".

**Lines of dialogue anyone gave:**
- The captain [bible, VOICES]: "I'm sent to see, Deputy. Not to be told." · "Who fired that?" · "How long have you held that badge? And who swore you?" · the two wires above.
- Rourke [bible]: "The captain will report what he sees. I have every confidence in what he will see."
- The depot agent [bible]: "He's sent another wire east, Deputy."
- The nod to Joe [session, prop]: "Will you ride out till he's gone?"
- The wire that brings him [session, prop]: "a report on the state of order at Salt Creek".
- The title "may be said by a character once" [bible, DIALOGUE]; Joe's "See what your badge does." (No Justice, scripted) is listed as its setup [SETUPS callbacks].
- Built or scripted lines: none found.

**Pays off from earlier / plants for later:**
- Pays off: the letter (S7); the sawn girder, day-book, witness (S23); the telegrams (S26); the raid as the first "outbreak" (S37; K12: "putting the wire beside the saddle"); how Harlan treated Joe at the cabin ("hid him the way the law hid his wife's killer"); the barkeep's word for him if he carried Earl ("on the captain's day") [P·bible]; the three titles as one sentence [bible README]; K10 the whole plan, "B13: the captain's errand, and what he overhears".
- Plants: the captain's wire (S25) → the last train's size and name; M3: how Harlan learns the last train is coming, "from the depot" [P·bible]; "what the paper says of him"; Joe's trust on the last walk.

**Every other idea found:**
- First name "Nothing to Report" [prop].
- Built on the story judge's gaps: "the sheriff's role is thin, Rourke appears too late, Joe has no beat in Acts II–III, and there are no quiet missions" [prop].
- "people behave for him, or perform for him" [P prop]. "The town talks" needs rumours, which don't exist [build check].
- "a brawl started in the saloon" → no fist fights: shoves and drawn guns [build check]. (Since then the band reacts to fist fights by deed kinds, #938: a later build fact.)
- "throw the first punch" → the Baron "will say his man was defending himself" [P prop].
- "offer to show him the church while the saloon boils over, keep him on the far side of the street" [P prop].
- Drunk captain: "sees less and remembers it wrong; if he works out what you did, that goes in the report too" [P prop → cut; "makes the captain comic in a mission whose weight is Joe"].
- The saloon's back room and balcony; the plan overheard there [P prop]; the old saloon has no back room; subtitles reach 45 m through walls today [build check].
- Judge: the captain as first written was "a camera with legs"; "nothing said if he's hurt or killed" [prop judge]. What happens if the captain is shot: not stated anywhere.
- "the Joe choice isn't stated as irreversible" [prop judge].
- The verdict is a "sentence the player sees the same day" [judge's idea 1].
- "their current opinion" on the day until story state exists [card].
- A new `ObserverBrain` (townsfolk cower at a shot within 25 m); each log entry has its actor ("who started it"); a provocateur's shot in the air [build check].
- "one armed townsman (Joe later) who can be goaded" in the cheapest version; townsfolk are unarmed [build check].
- Steering: "no way to talk to him: he could follow the deputy, a shot overriding it" [build check].
- 1882: Colorado a state from 1876; a governor calls the militia first; federal troops by request to the President through the War Department; "the 1881 removal was of the White River and Uncompahgre Utes; the Southern Utes stayed"; Lincoln County "a poor precedent"; Johnson County 1892 [prop; card].
- The plant "Handled with care: it's the Baron's lie about Joe's people, and the mission treats it as one" [D card].
- Soldiers' talk: "Sir." "The post." "The department." "A detail." "Citizens" for civilians; rank always said; never loud [bible, WORDS].
- "who the Baron's men goad" must be called before Step 5 is built [BUILD_ORDER].
- The Balcony Ambush "the night after" Payday lands on this day (s22): readings "the night after the captain leaves / whenever he has dynamite".
- The Shipment's witnesses "feed the Baron's revolt" (D), but the captain has already wired (s12): "they feed the paper… / the Shipment can come before the captain".
- C11 b, c (not picked): real soldiers and a dark ending; or the captain's own eyes turn the soldiers [CONTRA C11].
- chatgpt (P): "a military telegram seen or heard at the depot" as how the troop train is heard of.
- Overlap noted by Payday's judges: Payday Night "overlaps… I Am the Law".
- Score 26/35 [prop]. Size: "about 4 small and 3 medium, plus the large pieces every mission shares" [build check].

**Where the sources disagree:**
- **What the tally changes.** Card/DECISIONS (D 2026-11-09): hired guns vs soldiers under orders. C11 a (D 2026-11-11): always hired men; only numbers, arms and the paper's word change. **Latest: C11 a.**
- **Who sent him.** Proposal: the governor's office. Card (D correction): his department commander, after the governor has asked.
- **Is he Rourke's man?** Card: O ("the stronger story if independent and the Baron courts him"). VOICES: still O.
- **Does Rourke arrive with him?** Proposal: Rourke "stays aboard or rides on". Payday card: Rourke is already in town at the hotel. C8 a: posted nearby.
- **Without Joe.** Sean: "falls on someone else". Who: O (s7).
- **Is the Posse Comitatus frame Sean's?** 2026-11-09: P ("confirm it applies to the spine"). 2026-11-11: D (#744).
- **The removal.** Proposal: "after the Ute removal of 1881" frames Joe's people; corrected on the card.
- **"Soldiers"** in Payday's v6 ("speak for the soldiers to the captain") when only Rourke's detail of four is in town (f10).

**Open questions:**
- Who is goaded if Joe is dead; who asks "what it means for his people" then.
- Whether the captain is independent of Rourke; whether the two meet on screen.
- Who "the Baron's man" at supper is; what the Baron offers; what Harlan can offer.
- What happens if the captain is hurt or killed, or sees Harlan arrest in the dark.
- When the Balcony Ambush falls against this day (s22).
- What "mixed" means for the wire.
- Does the captain know Harlan's past, or the name Rourke gives him? Not stated.
- Whether Harlan has his guns in the open in front of him: not stated.

---

### Rourke (the character; no card)

Threads T5 (he is it) and T8. Everything found, by source.

**Decided by Sean**
- "A bought army officer and his men may be with them to make it look lawful" [Sean's idea 2026-10-28, #466 body; "may"].
- "Army officer Rourke": the Baron's shipment holds "payments to Army officer Rourke"; the conflict "with Army officer Rourke and the Baron culminates at the large canyon railway trestle" [D, inventory 2026-11-09]. Still open there: "the final confrontation with Rourke".
- "Rourke is the officer he pays to bring them" [the story judge's frame; Sean 2026-11-09: "Yes I like the ticks"; the card notes "the frame sentence itself he hasn't confirmed in words"; later D by the Posse Comitatus fix, 2026-11-11 #744].
- "we need rourke to come no matter what because if Joe kills him we should still meet him" [D, Sean 2026-11-09].
- In the arrest ending of No Justice "the man on the platform who lets the red shirt go is Rourke, or his officer" [D 2026-11-09, restated #744 2026-11-11].
- He arrives on Payday Night with an Army surgeon and a letter [D v6, 2026-11-09].
- "Harlan has a past with Rourke (his old commander, "Do your duty, Sergeant"): plant it early." [D, pick C15 a, 2026-11-11 #830; the option's wording]
- "Rourke and a few bought men are the only uniforms" on the last train; he "dies on the trestle with the train" [D, pick C11 a and "Rourke's fate: a", 2026-11-11 #830].
- Name kept: "Rourke" is one of the names already given [VOICES, Names]. Rank: O.

**Proposed**
- C8 a [session's pick on Sean's "Whatever makes sense so maybe takes a couple days for someone to come and release him"; P until he nods]: Rourke's side is posted nearby from the start (Fort Lewis is named in option a); his **officer** ("Lieutenant (rank O)… Late twenties, a regular officer, Eastern, correct and cold" [docs/scripts/no_justice.json cast]) comes on the train for Kett with a paper. So on the platform it is the officer, not Rourke.
- C8 b, c (not picked): Rourke "only stands on the platform beside him, shaking his hand"; or his officer "looks the other way" while Kett slips his escort.
- #546 P1 (P, never accepted): "Harlan's past obedience under Rourke"; "the soldiers on the train (orders built on lies)".
- #546 P2 (P, never accepted): Harlan's past found through play: "an old sergeant who recognises him, a survivor, Rourke knowing too much, a letter"; the player learns it "before Joe, and chooses with a nod or a shake whether to tell him".
- #546 P4 (P, never accepted): "Rourke as Harlan's mirror. The final confrontation opens with Rourke's words from the opening dream ("Do your duty, Sergeant"), offering the same bargain as before. Harlan's answer is the real climax. The trestle is its consequence. A real choice: blow the bridge, or use the Baron's evidence to turn the soldiers". (Turning the soldiers is out since C11 a; the line and the dream "stay P".)
- #546 P6: a final dream echoing the opening [P].
- #546 body: "Vale and Rourke's thread" (Vale, the railroad land agent, is dropped: s18).
- Where the past is planted [P·bible, S38]: Harlan's watch (#789), "What's on it, or in its case, is from the war"; the doctor's line; "Rourke's first sight of him… a look held a beat too long before he says 'Deputy'".
- A second plant for players who took revenge [P·bible, S6]: "the Baron's coach seen meeting an officer off the train on an ordinary day in Act II; or the barkeep selling it ("the Baron had a soldier to supper")".
- How he talks [P·bible, VOICES]: "parade-ground courtesy. Whole sentences. "Order", "regular", "duty". Speaks of the town as a thing to be put right. Never raises his voice; has other men for that." One of three allowed speeches (the Baron, Rourke, the preacher) [DIALOGUE].
- What he calls Harlan [VOICES]: "Deputy" in public; in private "Sergeant" (#546), "but a hospital steward was called "Steward", so which word is its own small call (O)".
- What he knows [VOICES]: "the whole plan. That the night would need a surgeon, before it did. Harlan, from the war, from his first look at him." Knows Kett's name (P, K3); the raid's purpose (K12); "knew a night was coming" (K8).
- When the player learns he's paid [VOICES K9]: "Suspects at B12 (the letter's date); knows at B14 (the papers)"; the town: "The paper, B17".
- K13: "Rourke says it [the past] at B12 or the trestle (P)"; the town never knows unless one of them says it.
- Callback [P·bible]: "Rourke, when he won't sign the letter", if Harlan shook his head at the oath.
- "Rourke's hospital steward looking at his [Harlan's] work" [P·bible].
- v2 (P): accepting his help means "his surgeon now knows who's who". v5 (dropped): sent by his department about the railroad attack. v6: on his way to a new post at Fort Lewis (changes under C8 a).
- I Am the Law proposal: "Rourke stays aboard or rides on: he needs a report, and this man writes it"; "T5 Rourke (on screen before the finale, through his captain)" [P prop].
- Shipment v2: "the bookkeeper… names the payments (to the gang, to Rourke)"; "the riflemen who saw Harlan report it to the Baron and Rourke" [P, barons-shipment_v2].
- chatgpt (all P): "the Baron has called in Army officer Rourke and his soldiers"; "If Rourke dies earlier, the soldiers still act through another commander or orders already issued"; "Does Rourke ride the train, lead ground forces, or remain elsewhere?"; "Whether Rourke's Army intervention continues after the Baron dies or is arrested"; the Baron's house "Could also reveal Rourke's involvement"; "uniforms and chain of command around southwestern Colorado" to research.
- Story judge: "Rourke first appears in an unapproved card (Payday Night) or as a name in the Shipment's ledgers" (escalation weak) [judged_story].

**Lines given him** [all bible, VOICES, unless marked]
1. "My surgeon is at your service, Deputy. I ask only that the thing be done regularly."
2. "It is a small matter to write your name. Men are dying while you read."
3. "A town that cannot keep its own peace will have it kept."
4. "The captain will report what he sees. I have every confidence in what he will see."
5. "Do your duty, Sergeant." [#546 P4, P]
6. "Let my men help, Deputy." [session, payday v2]
- His officer [docs/scripts/no_justice.json, "new", not built]: "Deputy, I have an order for your prisoner: a crime on the reservation is a matter for the United States and not for the county." · "There is no witness a court will hear. The man is at liberty."
- The doctor's plant line [script `day2.where`/`town.where`; CHANGES.md lists it for gameplay]: "Hold him. No... yes, like that. You've done this before. Where? ... No. Keep it." (replaces built "You've held a man down before.")

**Where the sources disagree about him**
- **Soldier or hired?** #466/#542/STORY: a train of "hired guns and soldiers"; 2026-11-09 spine: soldiers "sent to restore order"; 2026-11-11 #744: "His lie brings the soldiers"; C11 a (later the same day): no soldiers come, only the Baron's hired men, Rourke and "a few bought men". **Latest: C11 a.** So what Rourke's letter and the captain's wire are *for* (if the Army never comes) is not said plainly: the wire changes "what the paper calls them".
- **First sighting.** D 2026-11-09: Rourke or his officer on the platform. C8 a: the officer. Revenge-ending players: Payday Night is the first.
- **How he reaches Payday Night:** see Payday's disagreements.
- **Rank.** "Army officer" (inventory); a commander of a hospital steward in the war (C15 a); the captain is a captain and reports on a town Rourke is working: Rourke's rank is O.
- **"Sergeant" or "Steward".** O.
- **His end.** #546 (2026-11-04): "Rourke's fate and the soldiers' outcome stay open"; C11 a: dies on the trestle. If the trestle isn't blown under him: O (s25; options: the trestle is the only way / he dies wherever the train ends / taken with the Baron).
- **Vale.** #546 pairs him with Vale; Vale is on no card (s18).

**Open about him:** rank; where he's posted (Fort Lewis is the session's); what he and Harlan did in the war ("the same
bargain as before", "past obedience": never said what); whether the opening dream exists; whether he and Harlan speak
privately on Payday Night; whether the captain is his; whether he's at the Baron's supper; whether Sean nods C8 a.

---

## Ideas with no mission

- The Baron's telegrams east "after each bad night (after Earl and the raid, after the rope, after the train)"; the agent: "He's sent another wire east, Deputy." [P·bible, S26; that he sends telegrams is D 2026-11-11]
- The depot's clock on railroad time, the town's on its own; Harlan's watch (#789) [D that clocks exist; uses P, S36].
- "New characters can arrive by rail… strangers step down at the depot… An arrival can be a thread's beat or nudge" [Sean 2026-11-01, #542].
- "The coach can be entered… where passengers, or the soldiers and hired guns in the last act, sit and ride" [Sean 2026-11-01, #542].
- The train "stops at the mine to load (Sean: maybe a gold mine; the mine's kind is his call)" [#542]. Card/valley.json: silver ore.
- "a missed train changes the next day"; "a payroll arrives and payday follows" as step 6's proof [#542 plan].
- Dented metal: "I'd love to see that happen in game" (iron and steel visibly dented, the train first) [Sean 2026-11-03, #542].
- "After the ending, the town goes on (free roam): the train, payday and daily life keep running" [P, #546 body].
- Watching people through their windows at night [Sean 2026-11-07, #276] (the stick-up man is one case).
- Harlan speaks, rarely: "Short lines, in character, under his breath" [P, Sean 2026-11-07, #546 P9].
- "The Last Telegraph | Telegraph-related mission concept" [inventory Part 3, archive, not canon].
- "The Railroad Men" (an early pitch name only) [inventory Part 3].
- "The railroad arrives: celebration, speeches, a shooting match, and outsiders' trouble" [DESIGN.md backlog 7; "superseded?" since the line already runs, #552].
- Letters and the telegraph as a signature feature: "the US Marshal might come" [DESIGN.md §11 signature 5, decided, not built].
- A US Marshal or the newspaper as what the papers are for [P, judged_story §4.1].
- "Brody Colter: 'I know you.'" (DESIGN §6; never used; whether a Colter knows Harlan's past is O) [SETUPS M9].
- Harlan's spring, "the best spring" in the valley, wanted by nobody on any card [SETUPS M6; s14].
- If the widow signs at the farmhouse, what is the Baron still after in Act III? "Harlan's spring / the town itself" [options, s13].
- The Colters' thread has no ending on any card [s20; OUTLINE].
- The Water Tower (the depot's tank) as a set piece, "beside Hell on Wheels" in score [setpieces_2026-11-09; another reader's].
- Chinese railroad workers and a survey crew (the railhead lynching) clash with "the line already running" [judged_story].
- "High Wire | Aerial tramway or industrial transport set piece"; "Mill of Teeth"; "Runaway Coach" [inventory Part 3, archive].
- The story judge's suggested Act III order included `kid-wants-out` ("the Kid names the paymaster") after Payday Night [P, judged_story §5].
- "Southern Ute contacts may trust Harlan more" after the rope; "Supports… Hell on Wheels" lists [P, chatgpt, other cards].
- Saloon B's painted backdrop: "Salt Creek as the Baron promises it" [saloon_b README].
- First night's trio (piano, fiddle, banjo) downstairs "in the same room as the card table and the murder" [D, Sean 2026-11-14 #938: belongs to No Law's reader].
