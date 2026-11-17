# Changes for gameplay: where the scripts now differ from the game (#1056)

Written by the story session of 2026-11-17. The scripts lead; `config/moments/` is gameplay's data and was **not** changed.
Nothing here is done until Sean taps Script OK on the three pages. Then a gameplay session makes these changes,
with their tests (several tests check a line's words).

## 1. Lines in the game that the scripts re-word

| File | Key | Script line | The game says | The script says |
|---|---|---|---|---|
| `config/moments/funeral.json` | `lines.baron_you.any.0` | no_law.json `funeral.baron_you` | Mr. Harlan. A sad day for the county. | Mr. Harlan. A sad day for the county, and I'd not have chosen it to make your acquaintance. |
| `config/moments/funeral.json` | `lines.refuse.any.0` | no_law.json `funeral.refuse` | Not today. Not any day. | He's not covered over yet. |
| `config/moments/funeral.json` | `lines.town_2.any.0` | no_law.json `funeral.town` | He'd come in Saturdays. One drink. Never two. | (cut) |
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
| `config/moments/no_justice_camp.json` | `lines.disguise.any.0` | no_justice.json `ride.disguise` | If they see a Ute, they go to the camp after. If they see a cowboy, they come to me. | If a Ute did this, they'd burn the camp. So a cowboy did it. |
| `config/moments/no_justice_camp.json` | `lines.no.any.0` | no_justice.json `doctor.no` | No. I did not think so. | No. ... All right. |
| `config/moments/no_justice_camp.json` | `lines.nobody.any.0` | no_justice.json `ride.nobody` | A hat and a rag at my neck, and I am nobody's Indian. Only one more man who shot at them. | I won this hat at monte, from a man out of Texas. He said it was a good hat. He said the same of his cards. |
| `config/moments/no_justice_camp.json` | `lines.shirt.any.0` | no_justice.json `camp.shirt` | The one who did it to her wore a red shirt. Faded. That is all they saw of him. It is enough. | The one who did it to her wore a red shirt. Old. The red gone out of it. Nobody saw his face. |
| `config/moments/no_justice_camp.json` | `lines.trail.any.0` | no_justice.json `ride.trail` | (add beside the built wording) | They watered here. Took their time. / Fresh. Close now. |
| `config/moments/no_justice_camp.json` | `lines.way.any.0` | no_justice.json `camp.way` | They went toward the hills. That way. | They rode for the hills. That way. |
| `config/moments/no_justice_camp.json` | `lines.what.any.0` | no_justice.json `camp.what` | Six of them. Seven, one says. They came in the night. We were four days gone, hunting. Four days. | Six men. One says seven. They shot the dogs first. We were four days out, after elk. Four days. |
| `config/moments/no_justice_camp.json` | `lines.who.any.0` | no_justice.json `doctor.who` | This is Joe. The night Earl was shot, his people's camp was raided while the men were out hunting. His wife was killed. I'll not tell the rest. He can, if he chooses. | Harlan. This is Joe. The night Earl was shot, riders came through his people's camp. The men were off hunting. His wife is dead. The rest is his to tell. |
| `config/moments/no_justice_camp.json` | `lines.yes.any.0` | no_justice.json `doctor.yes` | Then we go now. | Good. Get your horse. |
| `config/moments/no_justice_camp.json` | `lines.you_knew.any.0` | no_justice.json `camp.you_knew` | You knew that already. | You knew. |
| `config/moments/no_justice_hideout.json` | `lines.alarm.any.0` | no_justice.json `fight.crew_alarm` | We got company! | Somebody's out there! |
| `config/moments/no_justice_hideout.json` | `lines.call_two.any.0` | no_justice.json `fight.crew_call` | (add beside the built wording) | Behind the woodpile! |
| `config/moments/no_justice_hideout.json` | `lines.joe_runs.any.0` | no_justice.json `fight.joe_call` | The red shirt. He runs. | Left. By the wagon. / Two. Behind the logs. / Red shirt's running! The shack! |
| `config/moments/no_justice_hideout.json` | `lines.warn.any.0` | no_justice.json `ride.warn` | When I find him, you will not like what I do. Better you know it now. | When we have him, you may want to look somewhere else. |
| `config/moments/sheriff_dies.json` | `lines.acting.any.0` | sheriff_road.json `day2.acting` | I'm the coroner, Harlan, so until the county sends a man I'm what law there is. And you're my deputy. Keep the badge on. | I'm the coroner, Harlan. By the statute that makes me sheriff until the county sends a man. So you're my deputy now. Keep the badge on. |
| `config/moments/sheriff_dies.json` | `lines.ditch.clear.0` | sheriff_road.json `day2.ditch.clear` | He's wanted my ditch since the day I cut it. Now he'll go at her. Look to them. | That ditch. He's wanted it since the day I cut it. He'll go at my wife for it now. Look to her and the boys. |
| `config/moments/sheriff_dies.json` | `lines.last.clear.0` | sheriff_road.json `day2.last.clear` | Sun's up. Ain't that something. | You'll want to see to that bread. |
| `config/moments/sheriff_dies.json` | `lines.nod.clear.0` | sheriff_road.json `day2.nod.clear` | Good. You're my deputy. Doc, you heard him. | Doc, you saw that. He's sworn. |
| `config/moments/sheriff_dies.json` | `lines.oath.clear.0` | sheriff_road.json `day2.oath.clear` | Doc. My badge. ... Raise your hand, Harlan. You'll keep the peace of this county, best you're able. Nod, then. | Doc. My badge. ... Raise your hand, Harlan. You swear to keep the peace of this county and serve its papers. There's more to it. I disremember the rest. Nod. |
| `config/moments/sheriff_dies.json` | `lines.shot_by.clear.0` | sheriff_road.json `day2.shot_by.clear` | Bald-faced sorrel. Called me friend. I'd know him again. You find him, Harlan. | Bald-faced sorrel. Soft-spoken man. Called me friend. ... You find him, Harlan. |
| `config/moments/sheriff_dies.json` | `lines.shot_by.fading.0` | sheriff_road.json `day2.shot_by.fading` | ...sorrel... said friend... | Sorrel... white face. Said friend. He said friend. |
| `config/moments/sheriff_dies.json` | `lines.where.left.0` | sheriff_road.json `day2.where` | Hold him. No... yes, like that. You've done this before. Where? ... No. Keep it. | Hold him. No... yes, like that. You've held a man down before. Where? ... Well. It's your affair. |
| `config/moments/sheriff_dies.json` | `lines.where.poor.0` | sheriff_road.json `day2.where` | Hold him. No... yes, like that. You've done this before. Where? ... No. Keep it. | Hold him. No... yes, like that. You've held a man down before. Where? ... Well. It's your affair. |
| `config/moments/the_sheriff.json` | `lines.ask_again.clear.0` | sheriff_road.json `road.ask_again.clear` | (add beside the built wording) | Yes or no, Harlan. / You deaf, man? Help me or get on. |
| `config/moments/the_sheriff.json` | `lines.ask_again.weak.0` | sheriff_road.json `road.ask_again.weak` | (add beside the built wording) | Harlan... please. |
| `config/moments/the_sheriff.json` | `lines.doctor.out.0` | sheriff_road.json `town.doctor.out` | He's out cold. Help me with him. Now. | He's insensible. Help me with him. Now. |
| `config/moments/the_sheriff.json` | `lines.idle.clear.0` | sheriff_road.json `road.idle.clear` | (add beside the built wording) | Fourteen years on this road. I know every rut in it. / Winchester's right there on my saddle. Never put a hand to it. / My wife's got bread rising. She'll think I stopped at the saloon. |
| `config/moments/the_sheriff.json` | `lines.idle.weak.0` | sheriff_road.json `road.idle.weak` | (add beside the built wording) | Stay where I can see you. |
| `config/moments/the_sheriff.json` | `lines.nod.clear.0` | sheriff_road.json `road.nod.clear` | Thank God. Press on it. Hard. It won't quit bleeding. | Thank God. It won't quit bleeding. Press on it. Hard. |
| `config/moments/the_sheriff.json` | `lines.nod.weak.0` | sheriff_road.json `road.nod.weak` | Press on it... hard. | Press on it. Hard, damn it. |
| `config/moments/the_sheriff.json` | `lines.press.weak.0` | sheriff_road.json `road.press.weak` | ...that's it. | There. Hold it there. |
| `config/moments/the_sheriff.json` | `lines.shake.clear.0` | sheriff_road.json `road.shake.clear` | (add beside the built wording) | Go on, then. Go on home. |
| `config/moments/the_sheriff.json` | `lines.shot_by.clear.0` | sheriff_road.json `road.shot_by.clear` | Stranger on a bald-faced sorrel. Rode up easy, like he wanted directions. Called me friend. Then he shot me. | Stranger on a bald-faced sorrel. Rode up easy, like a man asking his road. Called me friend. Then he shot me. |
| `config/moments/the_sheriff.json` | `lines.shot_by.fading.0` | sheriff_road.json `road.shot_by.fading` | ...friend... | Friend. He said friend. |
| `config/moments/the_sheriff.json` | `lines.shot_by.weak.0` | sheriff_road.json `road.shot_by.weak` | Bald-faced sorrel. Rode up like a friend. | Sorrel horse. White face. Called me friend. |

## 2. New lines

Each waits on its fact (`when`). A line whose fact isn't in the game yet waits on section 3.

| Script line | Speaker | When | Words |
|---|---|---|---|
| sheriff_road.json `day2.door.table` | doctor | nolaw.seen_from = table or yard (you saw Earl shot) | And Harlan. Last night, at the saloon. He's not been told. |
| sheriff_road.json `day2.heard` | sheriff | clear (care good) | I can hear you, Doc. Send him in. |
| sheriff_road.json `day2.shake.twice` | sheriff | clear, and sheriff.shook (you shook your head at him on the road, then helped him anyway) | You shook your head at me on the road, too. Then you packed it. ... That's not the way this works, son. Doc. Pin it on him. |
| sheriff_road.json `day2.not_enough` | doctor | nolaw.seen_from = table (you sat with the stranger), or nolaw.drew_on_stranger | A sorrel horse and one word. I can't hang a man on that, Harlan. |
| no_law.json `town.you_packed` | townsman | sheriff.care = good (you packed the wound) | Doc says that wound was packed proper. Says you done it. |
| no_law.json `table.asks_left` | stranger | sheriff.care = left | You're from up the creek, I believe. You'd have come down that road this morning. ... See anything of it? |
| no_law.json `table.asks_nod` | stranger | nolaw.told_stranger = yes | Did he. ... Well. A man'll say most anything with a ball in him. |
| no_law.json `table.asks_shake` | stranger | nolaw.told_stranger = no | No. I'd not think he could. |
| no_law.json `table.asks_none` | stranger | nolaw.told_stranger = none | No matter. Play your cards. |
| no_law.json `morning.followed` | townsman | nolaw.followed (you went out after Cody) | Somebody saw you go out after him. On foot. After a man on a horse. |
| no_law.json `funeral.town_2` | barkeep | any | Never once took a drink on the house. I'd pour it. He'd leave the dime. |
| no_law.json `funeral.baron_pardon` | baron | any | Forgive me, ma'am. It was ill-timed, and I am sorry for it. We will speak another day. |
| no_law.json `funeral.baron_you_care` | baron | nolaw.funeral = attended and sheriff.care = good | Mr. Harlan. They tell me he had a night with his wife on your account. That was well done. |
| no_law.json `funeral.baron_spring` | baron | nolaw.funeral = attended | You have the spring above the creek, I'm told, and the only sweet water for some miles. I have admired it from the road. |
| no_law.json `funeral.foreman` | stranger | nolaw.seen_from = table and nolaw.deputy | Morning, Deputy. |
| no_law.json `funeral.you_came_shake` | widow | nolaw.funeral = attended and nolaw.accepted = shake | He told me you shook your head at him. It tickled him. |
| no_law.json `funeral.you_came_left` | widow | nolaw.funeral = attended and sheriff.care = left | Mr. Harlan. |
| no_justice.json `doctor.cowboy_table` | cowboy | nolaw.seen_from = table (you sat at Earl's table) | That's the one sat at Earl's table. Never spilled his drink. |
| no_justice.json `ride.carried` | joe | sheriff.care = good (you packed the sheriff's wound) | The doctor says you know wounds. Good. One of us will want that. |
| no_justice.json `ride.left` | joe | sheriff.care = left | They say the sheriff called a name from the road, and the man kept walking. ... Don't do that to me. |
| no_justice.json `cabin.bargain_table` | kett | nolaw.seen_from = table (you sat with the stranger) | I know you. You're the one he sat with. I can tell you who he is, Deputy. Him at your table. His whole business. |
| no_justice.json `cabin.shake` | joe | nojustice.answer = shake | Go outside, Harlan. |
| no_justice.json `release.doctor` | doctor | nojustice.ending = arrest, after the release | Two days they kept him. |

## 3. StoryState facts the callbacks need that the game doesn't set yet

| Fact | Values | To set where | Used by |
|---|---|---|---|
| `sheriff.shook` | true if you ever shook your head at him on the road, whatever you did after | gameplay to add: sheriff.answer keeps only the last answer | day2.shake.twice |
| `nolaw.told_stranger` | yes / no / none: your nod or shake when he asks if the sheriff could talk | gameplay to add, with the question (table.asks is not built) | table.asks_nod, table.asks_shake, table.asks_none |
| `nolaw.drew_on_stranger` | true if you pointed a gun at him | gameplay to add (the aimed lines are built; nothing is recorded) | sheriff_road day2.not_enough; the widow's lane, later |
| `nolaw.helped_earl` | true if you knelt by Earl | gameplay to add (after.help is not built) | after.help; the barkeep's word for you later |
| `nolaw.sent_by` | doctor / stranger / nobody | gameplay to add (s26) | town.send_doc, town.send_stranger |
| `nojustice.kett_saw_joe` | true: Joe took the hat off at the cabin and Kett lived | gameplay to add, with the hat coming off at cabin.knife | street.kett; whether the kin go to the camp (S12) |

Every other fact the scripts' `when` fields name is set by the game now (`sheriff.care`, `nolaw.seen_from`, `nolaw.followed`,
`nolaw.accepted`, `nolaw.funeral`, `nolaw.deputy`, `nojustice.ending`, `nojustice.answer`, `nojustice.joe`).

## 4. Things, not lines

- **The hat comes off** (`no_justice.json` `cabin.knife`): Joe drops the cowboy's hat before "Look at me.", and `nojustice.kett_saw_joe` is set if Kett lives.
- **The stranger's question** (`no_law.json` `table.asks`, `table.asks_left` and the three answers): a nod-or-shake wait at the table before Cody comes; sets `nolaw.told_stranger`.
- **The funeral's second town line** is the barkeep's (`funeral.town_2`), as `funeral.json`'s `speakers` already has it.
- **Still art's:** the stranger's bald-faced sorrel at the saloon's rail, the Baron's buggy and the widow's gate (#906); the rifle on the sheriff's saddle (S14).

## 5. Flagged by the blind reader and kept (Sean's lines, or fixed in the game)

| Script | Line | Words | Why it stays, and what Sean could change |
|---|---|---|---|
| sheriff_road | `day2.shake.*` | That's not the way this works, son. | Sean's line (2026-11-09). The blind reader heard it as a present-day phrase. A period way, if Sean wants one: 'That ain't how it's done, son.' |
| sheriff_road | `road.hail.clear` | Keep your hands where I can see 'em. | Built; it never plays (the hail is said once). The reader heard a film lawman. Drop it when the line is next touched. |
| sheriff_road | `road.ask_again.weak, road.shake.weak` | Please. / Don't... don't leave me here. | Built, and Sean picked takes for them. The reader says a man who gives orders wouldn't plead; that he does, once he's weak, is the point of the three bands. |
| no_law | `murder.gloat` | Ain't no law left in this valley to save you now, Earl. | Sean's beat, built, and S2's plant. The reader heard a killer speaking the title; that is what it is for. |
| no_law | `table.warn, after.word, after.aimed, murder.fetch` | the stranger's and the barkeep's built lines | Built and fixed (VOICES.md); 'Don't move, friend' is S40. The reader heard film stock in 'You didn't see a thing tonight' and 'I ain't the one you want'. For Sean: say if the stranger's lines should be re-made in his new voice. |
| no_law | `murder.accuse` | Earl, you cheating son of a bitch! | Sean's redo of 2026-11-12, as he worded it. |
| no_justice | `cabin.ask, cabin.unclear, fight.mine` | Are you going to stop me? / Is that a yes? / That was mine to take. | Sean's lines (2026-11-09), word for word. The blind reader heard 'Is that a yes?' as present-day. A period way, if Sean wants one: 'Is that yes?' |
| no_justice | `fight.crew_*` | I'm hit! / There's only two of 'em! | Barks in a gunfight: plain on purpose. |
