# Changes for gameplay: where the scripts now differ from the game (#1056)

Written by the story session of 2026-11-17. The scripts lead; `config/moments/` is gameplay's data and was **not** changed.
Nothing here is done until Sean taps Script OK on the three pages. Then a gameplay session makes these changes,
with their tests (several tests check a line's words).

## 1. Lines in the game that the scripts re-word

| File | Key | Script line | The game says | The script says |
|---|---|---|---|---|
| `config/moments/funeral.json` | `lines.baron_you.any.0` | no_law.json `funeral.baron_you` | Mr. Harlan. A sad day for the county. | Mr. Harlan. A sad day for the county, and I'd not have chosen it to make your acquaintance. |
| `config/moments/funeral.json` | `lines.offer.any.0` | no_law.json `funeral.offer` | A hard day, ma'am. When that place grows too much for you, come to me first. You'll not find a fairer figure. | It is a hard day, ma'am, and I'd not trouble you on it, only to say that when that place grows too much for you, as it may, I hope you will come to me before another. You'll not find a fairer figure. |
| `config/moments/funeral.json` | `lines.refuse.any.0` | no_law.json `funeral.refuse` | Not today. Not any day. | He's not covered over yet. |
| `config/moments/funeral.json` | `lines.town_2.any.0` | no_law.json `funeral.town` | He'd come in Saturdays. One drink. Never two. | He fined me twice, and I'll own I had it coming both times. |
| `config/moments/no_justice_cabin.json` | `lines.back_joe_kett.any.0` | no_justice.json `back.joe_kett` | He talks a great deal for a man with his hands tied. | I can gag him. |
| `config/moments/no_justice_cabin.json` | `lines.back_kett.any.0` | no_justice.json `back.kett` | (add beside the built wording) | Who learned you to tie a man like this? The Army? / I've rode in worse company. Not a deal worse. |
| `config/moments/no_justice_cabin.json` | `lines.barred.any.1` | no_justice.json `cabin.barred` | First man through that door gets it! | I'll shoot through the door! I will! |
| `config/moments/no_justice_cabin.json` | `lines.done.any.0` | no_justice.json `cabin.done` | It is done. | Get the horses. |
| `config/moments/no_justice_cabin.json` | `lines.knife.any.0` | no_justice.json `cabin.knife` | You know me. You were at my camp. | Look at me. You were at my camp. |
| `config/moments/no_justice_cabin.json` | `lines.nod.any.0` | no_justice.json `cabin.nod` | Then take him. Take him to your law. We will see what it does. | Take him. Go on. See what your badge does. |
| `config/moments/no_justice_cabin.json` | `lines.not_only.any.0` | no_justice.json `cabin.not_only` | It weren't only me. Ask them. It weren't only me. | It weren't only me. Ask them. Ask any of them. Hell, they're dead, ain't they. It weren't only me. |
| `config/moments/no_justice_cabin.json` | `lines.thanks.any.0` | no_justice.json `cabin.thanks` | Bless you, Deputy. You're a fair man. I'll come quiet. | Bless you, Deputy. Bless you. I always did say a town wants law. I'll come quiet as a lamb. |
| `config/moments/no_justice_camp.json` | `lines.ask.any.0` | no_justice.json `doctor.ask` | I ride today. Will you come? | I'm going today. You coming? |
| `config/moments/no_justice_camp.json` | `lines.cowboy.any.0` | no_justice.json `doctor.cowboy` | Doc's right. No jury in Colorado'll hang a white man for a Ute woman. I've seen 'em try. | A jury? They'd stand him a drink. |
| `config/moments/no_justice_camp.json` | `lines.disguise.any.0` | no_justice.json `ride.disguise` | If they see a Ute, they go to the camp after. If they see a cowboy, they come to me. | A Ute kills a white man, the whites burn the camp. So today I'm a cowboy. |
| `config/moments/no_justice_camp.json` | `lines.no.any.0` | no_justice.json `doctor.no` | No. I did not think so. | No. ... All right. |
| `config/moments/no_justice_camp.json` | `lines.nobody.any.0` | no_justice.json `ride.nobody` | A hat and a rag at my neck, and I am nobody's Indian. Only one more man who shot at them. | I won this hat at monte, from a Texas man. He said it was a good hat. He lied about the cards, too. |
| `config/moments/no_justice_camp.json` | `lines.shirt.any.0` | no_justice.json `camp.shirt` | The one who did it to her wore a red shirt. Faded. That is all they saw of him. It is enough. | The one who did it to her wore a red shirt. Old. The red gone out of it. Nobody saw his face. |
| `config/moments/no_justice_camp.json` | `lines.trail.any.0` | no_justice.json `ride.trail` | (add beside the built wording) | They watered here. Took their time. / These are fresh. An hour. |
| `config/moments/no_justice_camp.json` | `lines.way.any.0` | no_justice.json `camp.way` | They went toward the hills. That way. | They rode for the hills. That way. |
| `config/moments/no_justice_camp.json` | `lines.what.any.0` | no_justice.json `camp.what` | Six of them. Seven, one says. They came in the night. We were four days gone, hunting. Four days. | Six men. One says seven. They shot the dogs first. We were four days out, after elk. |
| `config/moments/no_justice_camp.json` | `lines.who.any.0` | no_justice.json `doctor.who` | This is Joe. The night Earl was shot, his people's camp was raided while the men were out hunting. His wife was killed. I'll not tell the rest. He can, if he chooses. | Harlan. This is Joe. Riders came through his people's camp the night Earl was shot, with the men off hunting. His wife... she's dead. |
| `config/moments/no_justice_camp.json` | `lines.yes.any.0` | no_justice.json `doctor.yes` | Then we go now. | Good. Get your horse. |
| `config/moments/no_justice_camp.json` | `lines.you_knew.any.0` | no_justice.json `camp.you_knew` | You knew that already. | You saw them ride out. |
| `config/moments/no_justice_hideout.json` | `lines.alarm.any.0` | no_justice.json `fight.crew_alarm` | We got company! | Somebody's out there! |
| `config/moments/no_justice_hideout.json` | `lines.call_two.any.0` | no_justice.json `fight.crew_call` | (add beside the built wording) | Behind the woodpile! |
| `config/moments/no_justice_hideout.json` | `lines.how.any.0` | no_justice.json `ride.watch` | How do you want it? Quiet, or now? | How do you want it? Creep in, or shoot from here? |
| `config/moments/no_justice_hideout.json` | `lines.joe_runs.any.0` | no_justice.json `fight.joe_call` | The red shirt. He runs. | Left. By the wagon. / Two. Behind the logs. / Red shirt's running! The shack! |
| `config/moments/no_justice_hideout.json` | `lines.quit.any.0` | no_justice.json `fight.crew_quit` | I'm done! Don't shoot! | I quit! Don't shoot! |
| `config/moments/no_justice_hideout.json` | `lines.warn.any.0` | no_justice.json `ride.warn` | When I find him, you will not like what I do. Better you know it now. | When we have him, don't watch. |
| `config/moments/no_law_murder.json` | `lines.stranger_sit.0` | no_law.json `table.sit` | Evening. Mind if I sit in a while? | Evening. Harlan, isn't it? Sit with me a while, if you've no objection. |
| `config/moments/sheriff_dies.json` | `lines.acting.any.0` | sheriff_road.json `day2.acting` | I'm the coroner, Harlan, so until the county sends a man I'm what law there is. And you're my deputy. Keep the badge on. | He had it right. I'm the coroner, so I'm sheriff until the commissioners name one. Keep the badge on. |
| `config/moments/sheriff_dies.json` | `lines.ditch.clear.0` | sheriff_road.json `day2.ditch.clear` | He's wanted my ditch since the day I cut it. Now he'll go at her. Look to them. | The Baron's wanted that ditch since the day I cut it. He'll go at my wife for it now. Look to her and the boys. |
| `config/moments/sheriff_dies.json` | `lines.door.good.0` | sheriff_road.json `day2.door.good` | He's asking for you. He's clear this morning. It won't last. | He's asking for you. He's clear this morning. |
| `config/moments/sheriff_dies.json` | `lines.door.left.0` | sheriff_road.json `day2.door.left` | He's been asking for you since the freighter brought him. I couldn't tell you why. | He's been asking for you since the freighter brought him. |
| `config/moments/sheriff_dies.json` | `lines.last.clear.0` | sheriff_road.json `day2.last.clear` | Sun's up. Ain't that something. | Go home to the boys. |
| `config/moments/sheriff_dies.json` | `lines.nod.clear.0` | sheriff_road.json `day2.nod.clear` | Good. You're my deputy. Doc, you heard him. | Doc, you saw that. He's sworn. |
| `config/moments/sheriff_dies.json` | `lines.oath.clear.0` | sheriff_road.json `day2.oath.clear` | Doc. My badge. ... Raise your hand, Harlan. You'll keep the peace of this county, best you're able. Nod, then. | Doc. My badge. ... Harlan. I want this on you. Keep the peace of this county and serve its papers. There's more to the oath. I disremember it. Will you take it? |
| `config/moments/sheriff_dies.json` | `lines.oath.fading.0` | sheriff_road.json `day2.oath.fading` | Badge... Doc. Pin it on him. | Badge... Harlan. Take it. ... Will you? |
| `config/moments/sheriff_dies.json` | `lines.shot_by.clear.0` | sheriff_road.json `day2.shot_by.clear` | Bald-faced sorrel. Called me friend. I'd know him again. You find him, Harlan. | Bald-faced sorrel. Soft-spoken man. Called me friend. Shot me from the saddle and never got down. |
| `config/moments/sheriff_dies.json` | `lines.shot_by.fading.0` | sheriff_road.json `day2.shot_by.fading` | ...sorrel... said friend... | Sorrel... white face. Said friend. He said friend. |
| `config/moments/sheriff_dies.json` | `lines.where.left.0` | sheriff_road.json `day2.where` | Hold him. No... yes, like that. You've done this before. Where? ... No. Keep it. | Hold him. No... yes, like that. You've held a man down before. |
| `config/moments/sheriff_dies.json` | `lines.where.poor.0` | sheriff_road.json `day2.where` | Hold him. No... yes, like that. You've done this before. Where? ... No. Keep it. | Hold him. No... yes, like that. You've held a man down before. |
| `config/moments/the_sheriff.json` | `lines.ask_again.clear.0` | sheriff_road.json `road.ask_again.clear` | (add beside the built wording) | Yes or no, Harlan. / You deaf, man? Help me or get on. |
| `config/moments/the_sheriff.json` | `lines.ask_again.weak.0` | sheriff_road.json `road.ask_again.weak` | (add beside the built wording) | Harlan... please. |
| `config/moments/the_sheriff.json` | `lines.doctor.out.0` | sheriff_road.json `town.doctor.out` | He's out cold. Help me with him. Now. | He's insensible. Help me with him. Now. |
| `config/moments/the_sheriff.json` | `lines.idle.clear.0` | sheriff_road.json `road.idle.clear` | (add beside the built wording) | I know every rut in this road. / Winchester's right there on my saddle. Never put a hand to it. / My wife's got bread rising. |
| `config/moments/the_sheriff.json` | `lines.idle.weak.0` | sheriff_road.json `road.idle.weak` | (add beside the built wording) | Stay where I can see you. |
| `config/moments/the_sheriff.json` | `lines.nod.clear.0` | sheriff_road.json `road.nod.clear` | Thank God. Press on it. Hard. It won't quit bleeding. | Thank God. It won't quit bleeding. Press on it. Hard. |
| `config/moments/the_sheriff.json` | `lines.nod.weak.0` | sheriff_road.json `road.nod.weak` | Press on it... hard. | Press on it. Hard, damn it. |
| `config/moments/the_sheriff.json` | `lines.press.weak.0` | sheriff_road.json `road.press.weak` | ...that's it. | There. Hold it there. |
| `config/moments/the_sheriff.json` | `lines.shake.clear.0` | sheriff_road.json `road.shake.clear` | (add beside the built wording) | Go on, then. Go on home. |
| `config/moments/the_sheriff.json` | `lines.shot_by.clear.0` | sheriff_road.json `road.shot_by.clear` | Stranger on a bald-faced sorrel. Rode up easy, like he wanted directions. Called me friend. Then he shot me. | Stranger on a bald-faced sorrel. Rode up easy. Called me friend and shot me. |
| `config/moments/the_sheriff.json` | `lines.shot_by.fading.0` | sheriff_road.json `road.shot_by.fading` | ...friend... | Friend. He said friend. |
| `config/moments/the_sheriff.json` | `lines.shot_by.weak.0` | sheriff_road.json `road.shot_by.weak` | Bald-faced sorrel. Rode up like a friend. | Sorrel horse. White face. Called me friend. |
| `config/moments/the_sheriff.json` | `lines.ask.clear.0` | sheriff_road.json `road.ask.clear` | Harlan. You're Harlan, from up the creek. I'm gut-shot. I need the doc. You going to help me or not? | Harlan. You're Harlan, from up the creek. I'm shot in the belly. I need the doc. You going to help me or not? (Sean, 2026-11-18; its take goes: a new one) |
| `config/moments/the_sheriff.json` | `lines.doctor.clear.0` | sheriff_road.json `town.doctor.clear` | Gut-shot. Help me get him up the steps. | Shot in the belly. Help me get him up the steps. (Sean, 2026-11-18; a new take) |
| `config/moments/sheriff_dies.json` | `lines.shake.clear.0` | sheriff_road.json `day2.shake.clear` | That's not the way this works, son. ... Doc. Pin it on him. | That ain't how it's done, son. ... Doc. Pin it on him. (Sean, 2026-11-18) |
| `config/moments/sheriff_dies.json` | `lines.shake.fading.0` | sheriff_road.json `day2.shake.fading` | ...not how it works... son. | ...ain't how it's done... son. (Sean, 2026-11-18) |
| `config/moments/no_law_murder.json` | `lines.stranger_word.0` | no_law.json `after.word` | You didn't see a thing tonight. Nobody did. Remember that. | I'll say good night, friend. Anybody asks, I'd take it kindly if you'd been looking into your glass. (Sean, 2026-11-18: re-made) |
| `config/moments/no_law_murder.json` | `lines.stranger_aimed` (all three) | no_law.json `after.aimed` | Easy, friend. I ain't the one you want. / Put it up. You'll only get yourself killed. / Walk away. That's my advice. | Why, Deputy. I'd sooner you pointed that some other way, if it's no trouble. / Best put that by, Deputy. These gentlemen might take it wrong. / Go on home, Deputy. I'll not hold it against you. (Sean, 2026-11-18: re-made; still for the first armed meeting, not night one, see part 4) |
| `config/moments/no_justice_cabin.json` | `lines.unclear.any.0` | no_justice.json `cabin.unclear` | Is that a yes? | Is that yes? (Sean, 2026-11-18) |

## 2. New lines

Each waits on its fact (`when`). A line whose fact isn't in the game yet waits on section 3.

| Script line | Speaker | When | Words |
|---|---|---|---|
| sheriff_road.json `evening.doctor.ball` | doctor | any | One ball, and low. Fired from a horse, by the line of it. Whoever it was didn't get down to make sure. |
| sheriff_road.json `day2.door.table` | doctor | nolaw.seen_from = table or yard, and you didn't carry Earl here (nolaw.carried_earl = no) | The sheriff's not been told about Earl. Don't you tell him. |
| sheriff_road.json `day2.door.coat` | doctor | nolaw.carried_earl = yes (Earl's blood is on your coat) | The sheriff's not been told about Earl. Button your coat. |
| sheriff_road.json `day2.heard` | sheriff | clear (care good) | I can hear you, Doc. Send him in. |
| sheriff_road.json `day2.blood` | sheriff | clear, and nolaw.carried_earl = yes | Whose blood is that on you? ... That ain't mine. |
| sheriff_road.json `day2.blood_doc` | doctor | clear, and nolaw.carried_earl = yes | A man cut himself at the saloon. Lie back. |
| sheriff_road.json `day2.shake.twice` | sheriff | clear, and sheriff.shook (you shook your head at him on the road, then helped him anyway) | Second time you've shook your head at me. ... That ain't how it's done, son. Doc. Pin it on him. |
| sheriff_road.json `day2.for_now.clear` | sheriff | clear | It's only for now. The county commissioners name the next man. Till they do, Doc's coroner, so he's sheriff, and you're his deputy. |
| sheriff_road.json `day2.for_now.fading` | sheriff | fading | Only till the county... names a man. Doc... tell him. |
| sheriff_road.json `day2.not_enough` | doctor | nolaw.seen_from = table (you sat with the stranger) | A sorrel horse and one word. I can't hang a man on that, Harlan. |
| no_law.json `town.you_packed` | townsman | sheriff.care = good (you packed the wound) | Doc says that wound was packed proper. Says you done it. |
| no_law.json `table.drink` | stranger | any | What'll you take? ... No, put your money up. I asked you. |
| no_law.json `table.talk` | stranger | sheriff.care = good or poor (you brought the sheriff in) | They tell me it was you brought the sheriff in. Carried him the best part of four miles. That's a deal of trouble to go to. |
| no_law.json `table.talk_left` | stranger | sheriff.care = left | You'll have heard about the sheriff. Shot on the East Road this morning, not four miles from where we sit. |
| no_law.json `table.good_man` | stranger | any | I only met him the once. He seemed a good man. He didn't deserve that. |
| no_law.json `table.asks_left` | stranger | sheriff.care = left | You'd have come down that road yourself this morning. ... See anything of it? |
| no_law.json `table.asks_nod` | stranger | nolaw.told_stranger = yes | Did he. |
| no_law.json `table.asks_shake` | stranger | nolaw.told_stranger = no | No. I'd not think he could. |
| no_law.json `table.asks_none` | stranger | nolaw.told_stranger = none | No matter. |
| no_law.json `after.lifted` | barkeep | nolaw.carried_earl = yes | He owes me four dollars. |
| no_law.json `carry.earl` | earl | nolaw.carried_earl = yes; while his blood loss lets him | Mind my arm. / I left my hat. / Tell Cody I'll make it good. You tell him. / It was only a dollar. / ... |
| no_law.json `carry.street` | townswoman | nolaw.carried_earl = yes | Is that Earl? ... Lord. Doc's got his lamp lit. Go on. |
| no_law.json `carry.door_wait` | doctor | any | Who is it? I've a man dying in here. / I hear you! I've only the two hands. |
| no_law.json `carry.door` | doctor | any | The man wants burying, not doctoring. (Sean's wording, 2026-11-18) |
| no_law.json `carry.two` | doctor | sheriff.care = good or poor (you brought the sheriff here this morning) | That's two you've carried to this door today. |
| no_law.json `carry.this_one` | doctor | sheriff.care = left (you left the sheriff on the road) | This one you carried. |
| no_law.json `carry.lay` | doctor | any | Lay him in the front room. On the table. There's a sheet on the chair. / Then go home. I've the sheriff to sit with. |
| no_law.json `morning.you_carried` | townsman | nolaw.carried_earl = yes | They say you carried him clear up the street. ... That his blood on you? |
| no_law.json `morning.coat` | townswoman | nolaw.carried_earl = yes | Cold water, Mr. Harlan, not hot. Hot sets it. |
| no_law.json `morning.followed` | townsman | nolaw.followed (you went out after Cody) | Somebody saw you go out after him. On foot. After a man on a horse. |
| no_law.json `morning.body` | doctor | nolaw.earl = doctor's (he lies here) | He was dead when you knocked. I'd not have you think it was the door. |
| no_law.json `funeral.town_2` | barkeep | any | Never once took a drink on the house. I'd pour it and he'd leave the dime. |
| no_law.json `funeral.baron_pardon` | baron | any | Forgive me, ma'am; it was ill-timed of me, and we will speak of it another day. |
| no_law.json `funeral.baron_you_care` | baron | nolaw.funeral = attended and sheriff.care = good | Mr. Harlan, they tell me he had a night with his wife that he'd not have had but for you, and I call that well done. |
| no_law.json `funeral.baron_spring` | baron | nolaw.funeral = attended | You have the spring above the creek, I'm told, and the only sweet water for some miles. I have admired it from the road. |
| no_law.json `funeral.foreman` | stranger | nolaw.seen_from = table and nolaw.deputy | Good morning to you, Deputy. |
| no_law.json `funeral.you_came_shake` | widow | nolaw.funeral = attended and nolaw.accepted = shake | He told me you shook your head at him. It tickled him. |
| no_law.json `funeral.you_came_left` | widow | nolaw.funeral = attended and sheriff.care = left | Mr. Harlan. |
| no_justice.json `doctor.cowboy_table` | cowboy | nolaw.seen_from = table (you sat at Earl's table) | That's the one sat at Earl's table. Sat right there. |
| no_justice.json `doctor.cowboy_carried` | cowboy | nolaw.carried_earl = yes | He's the one carried Earl up here. Still got him on his coat. |
| no_justice.json `ride.carried` | joe | sheriff.care = good (you packed the sheriff's wound) | The doctor says you know wounds. One of us will want that. |
| no_justice.json `ride.left` | joe | sheriff.care = left | They say the sheriff called a name from the road, and the man kept walking. ... Don't walk off from me. |
| no_justice.json `cabin.bargain_table` | kett | nolaw.seen_from = table (you sat with the stranger) | I know you. You're the one he sat with. I can tell you who he is, Deputy. Him at your table. His whole business. |
| no_justice.json `cabin.shake` | joe | nojustice.answer = shake | Go outside, Harlan. |

## 3. StoryState facts the callbacks need that the game doesn't set yet

| Fact | Values | To set where | Used by |
|---|---|---|---|
| `sheriff.shook` | true if you ever shook your head at him on the road, whatever you did after | gameplay to add: sheriff.answer keeps only the last answer | day2.shake.twice |
| `nolaw.carried_earl` | yes / no | gameplay to add with #1057 (carrying a man) | day2.door.table, day2.door.coat, day2.blood, day2.blood_doc |
| `nolaw.told_stranger` | yes / no / none: your nod or shake when he asks if the sheriff could talk | gameplay to add, with the question (table.asks is not built) | table.asks_nod, table.asks_shake, table.asks_none |
| `nolaw.sent_by` | doctor / nobody | gameplay to add (s26) | town.send_doc |
| `nojustice.kett_saw_joe` | true: Joe took the hat off at the cabin and Kett lived | gameplay to add, with the hat coming off at cabin.knife | street.kett; whether the kin go to the camp (S12) |

Every other fact the scripts' `when` fields name is set by the game now (`sheriff.care`, `nolaw.seen_from`, `nolaw.followed`,
`nolaw.accepted`, `nolaw.funeral`, `nolaw.deputy`, `nojustice.ending`, `nojustice.answer`, `nojustice.joe`).

## 4. Things, not lines

- **The hat comes off** (`no_justice.json` `cabin.knife`): Joe drops the cowboy's hat before "Look at me.", and `nojustice.kett_saw_joe` is set if Kett lives.
- **The stranger's question** (`no_law.json` `table.asks`, `table.asks_left` and the three answers): a nod-or-shake wait at the table before Cody comes; sets `nolaw.told_stranger`.
- **The funeral's second town line** is the barkeep's (`funeral.town_2`), as `funeral.json`'s `speakers` already has it.
- **Earl is carried to the doctor's (Sean, 2026-11-17; #1057):** the murder leaves Earl down and bleeding, not dead; the barkeep sends Harlan (`after.help`); scene `carry` (Earl on the way, the doctor through the door, at the door, the front room); the body under a sheet in the doctor's front room on day 2 (`morning.body`, `morning.undertaker` there); `nolaw.carried_earl`, and `nolaw.earl` = doctor's or saloon in place of undertaker. The blood on Harlan's coat is read by `sheriff_road.json` `day2.door.coat`, `day2.blood`, `day2.blood_doc`.
- **No gun on night one (Sean, 2026-11-17):** Harlan is unarmed until the sheriff gives him his revolver on day 2. `no_law_murder.json` `lines.stranger_aimed` (three lines for a gun pointed at the stranger) can't be reached that night: move them to the first armed meeting, or drop them. No fact for drawing on him.
- **Still art's:** the stranger's bald-faced sorrel at the saloon's rail, the Baron's buggy and the widow's gate (#906); the rifle on the sheriff's saddle (S14).

## 5. Flagged by the blind reader and kept (Sean's lines, or fixed in the game)

| Script | Line | Words | Why it stays, and what Sean could change |
|---|---|---|---|
| sheriff_road | `road.hail.clear` | Keep your hands where I can see 'em. | Built; it never plays (the hail is said once). The reader heard a film lawman. Drop it when the line is next touched. |
| sheriff_road | `road.ask_again.weak, road.shake.weak` | Please. / Don't... don't leave me here. | Built, and Sean picked takes for them. The reader says a man who gives orders wouldn't plead; that he does, once he's weak, is the point of the three bands. |
| sheriff_road | `road.idle.clear, town.doctor_after.good` | Sun's coming up. Ain't that something. / Somebody packed that wound, and packed it right. That's bought him some hours. | Built, and Sean picked takes of both. The second reader doubted 'Ain't that something' and 'bought him some hours' for 1882. Plainer, if Sean wants: 'Sun's coming up.' / 'That wound was packed right. It's given him some hours.' |
| no_law | `murder.gloat` | Ain't no law left in this valley to save you now, Earl. | Sean's beat, built, and S2's plant. The reader heard a killer speaking the title; that is what it is for. |
| no_law | `table.warn, murder.fetch` | the stranger's and the barkeep's built lines | Built and fixed (VOICES.md); 'Don't move, friend' is S40. The stranger's `after.word` and `after.aimed` were re-made on Sean's call of 2026-11-18 (#1059, #1288): part 1. |
| no_law | `murder.accuse` | Earl, you cheating son of a bitch! | Sean's redo of 2026-11-12, as he worded it. |
| no_law | `funeral.offer` | A hard day, ma'am. When that place grows too much for you, come to me first. You'll not find a fairer figure. | Not kept: re-worded as one long sentence, because both readers said the Baron spoke in short sentences against his brief. The old words are in the line's `was` if Sean prefers them. |
| no_justice | `cabin.ask, fight.mine` | Are you going to stop me? / That was mine to take. | Sean's lines (2026-11-09), word for word. `cabin.unclear` became 'Is that yes?' on his call of 2026-11-18 (part 1). |
| no_justice | `fight.crew_*` | I'm hit! / There's only two of 'em! | Barks in a gunfight: plain on purpose. |

## 6. Sean's five calls of 2026-11-18 (#1059), applied 2026-11-26 (#1288)

1. "That's not the way this works, son." -> "That ain't how it's done, son." (`day2.shake.clear`, `.twice`, `.fading`; No Law's copy of day2 too).
2. Joe's "Is that a yes?" -> "Is that yes?" (`cabin.unclear`).
3. The doctor at the door -> "The man wants burying, not doctoring." (`carry.door`, new, not built).
4. The stranger re-made in his own voice: `after.word` and all three `after.aimed` (part 1). The 2026-11-17 reader's third flagged
   line wasn't recorded by name, so all his gun lines were re-made. One blind read (DIALOGUE.md part 4), its picks taken.
5. "Gut-shot" -> "shot in the belly" (`road.ask.clear`, `town.doctor.clear`); both lose their takes on the sheriff's page.

Story docs that quote the old words (VOICES.md, SETUPS.md) were updated; the mission cards (`docs/story/missions/`) wait for #959.
