# The answers bench (#1272)

DESIGN §2 pillar 6, "Everything you do gets an answer": the person a verb is done to and the people who
saw it each react at once, in words that match what they saw; it leaves a mark (regard moves, the news
carries it, someone brings it up later). This bench measures that in the valley's saloon (saloon B's
bar room) on an ordinary evening, one verb on a fresh game each.

```sh
python3 experiments/answers/run.py [--only=shove,shot] [--out=DIR]   # ~6 min a verb, headless
python3 experiments/answers/run.py --retable DIR                     # the table again from DIR's JSON
```

Per verb: a fresh game (`tools/bridge.py start --headless --game-args=--world=valley`), the clock to
20:30, 25 s to settle, the player set up by the bar (by the rancher), `ans_snap` (this lab's bridge
command: each man in play, whether his Senses see you, his Reaction, mood, look, regard), the verb,
`ans_watch 3` (each man's first answer within 3 s: a line, a Reaction stage, a look, a mood), `ans_snap`
again; then "later": 60 s in the room, a walk past six of the men, the clock at 24x for 120 s (about a
game day; No Law's murder night comes on its own in it) and every line said after the 3 s. A line counts as
a mention when it speaks of the verb (each verb's `words` in `run.py`).

The columns: **in the room** (men within 10 m), **saw it** (his Senses saw you at the moment, plus the
man it was done to: strict, so men with their backs to you at the bar don't count), **reacted in 3 s**
(of those who saw it, and how), **regard moved** (anyone in the room whose four numbers moved),
**mentioned later**.

## Baseline (main at 68d9ebda, 2026-11-26): `results/baseline/`

| verb | in the room (10 m) | saw it | reacted in 3 s | regard moved | mentioned later |
|---|---|---|---|---|---|
| draw | 10 | 4 | 4 (barkeep gun:look, earl look, fiddler gun:look, saloon_girl gun:look) | 10 | no |
| holster | 9 | 7 | 3 (barkeep mood, rancher said, saloon_girl mood) | 0 | no |
| shove | 10 | 4 | 4 (barkeep look, earl look, rancher look, saloon_girl look) | 5 | no |
| shot | 9 | 7 | 6 (barkeep shot_seen:act, earl shot_seen:act, fiddler said, rancher said, saloon_girl said, storekeeper shot_seen:act) | 7 | yes: barkeep: "Somebody take that iron off him."; liveryman: "There was shooting right here. One shot. Never saw who." |
| sit | 11 | 0 | 0 | 0 | no |
| win_pot | 9 | 0 | 0 | 6 | no |
| knock | - | - | - | - | not measured: saloon B is an open house, its door takes no knock (`at_door` empty) |
| crowd (0.6 m, 20 s) | 10 | 4 | 0 | 0 | no |

("news records 1" in the raw rows is Earl down at 01:47, No Law's night, not the verb.)

What it showed, for the step's two verbs:
- **The shove:** the rancher, shoved from behind, said nothing (CivilianBrain dropped a deed done behind
  a man's back, even one done to him); those who saw it only gave the room's hush look, no words; regard
  moved (the rancher's twice) but every band stayed "wary", so nothing showed as you passed; TownNews made
  no record of a shove, so nobody ever brought it up.
- **The shot:** answered well already: six of seven who saw it reacted, all moved to afraid or cold, and
  it was told on ("The new man fired, right here..."). Its fault was words: "Get in. Get in and shut it."
  from the saloon girl, already inside the saloon. Also seen: the barkeep's "Don't shoot! I got a family!"
  six times while the bench walked past him gun in hand (a gun on him each time: not the shot's; left).
- Not this step: sitting and the won pot get looks from the table at most and no words; standing 0.6 m from
  a man for 20 s gets nothing (the crowd deed moves no regard and has no reaction); the holster's answers
  are the draw's settling.

## After step B (the shove and the shot fixed): `results/after/`

| verb | in the room (10 m) | saw it | reacted in 3 s | regard moved | mentioned later |
|---|---|---|---|---|---|
| shove | 10 | 5 | 5 (all looked; the rancher said "Please, I don't want any trouble."; the barkeep "Not in my place. You want to push folks about, do it outside."; the saloon girl "Leave him be, mister.") | 5, all cold (were wary) | yes, from half a minute on: "The new man put hands on me, right here. No call for it." (the rancher); "You put hands on me, right here. I don't forget a thing like that." (to your face); told on: "...That's what the rancher says, anyhow." |
| shot | 9 | 7 | 7 (all looked or ducked; the fiddler "Lord almighty!", the rancher "Get down! Everybody down!"; no "Get in" from inside) | 7: afraid 4, cold 3 | yes: "Somebody take that iron off him."; to your face, "That was you, firing right here. One shot. I saw you." |

What changed (step B):
- The man shoved knows it, shoved from behind or not: he turns to see who and speaks up (`CivilianBrain._on_deed`).
- Everyone who saw a shove looks at Harlan; the first two to come to it, by distance, say so (`_saw_shove`,
  TownBarks `react.shove`, `.woman`, `.bar`).
- One shove seen turns a man cold (data `regard.deeds.shove`; the man shoved minds it half again more), so the
  room turns a shoulder as you pass.
- A shove is TownNews news (`rough`): each who saw it and the man shoved hold it, tell it on, say it to your face;
  not in the same breath (`ROUGH_TELL_S`, 30 s: at first five men told it at once, 0.7 s after).
- The shot's words: "Get in. Get in and shut it." only out of doors (bark ctx `indoors`).
- The bench: `ans_watch` counts a look already on at its start (it began in the verb's own frame) and the
  lines said in that frame come from the bridge's log (the after rows use this; the baseline's shove row
  under it would read the same looks, without the words).

## Step 2, the card table (#1279): `results/baseline_table/`, `results/after_table*/`

The table's verbs: you sat at the south chair (`sit s`) on an ordinary evening; `ans_turn [any|bet|weak|strong]`
waits for your turn (a bet open to you, a hand under or over `call_at`); a nod calls, a shake folds, fire raises
(nothing before #1279), `ans_pot`/`ans_lose` play hands till you win or lose one, G (`press shout`) facing Earl
calls a cheat, `stand` gets up, `watch` stands 1.6 m from Earl for 20 s. "Saw it" adds the table's men (it's done
to their faces). The "reacted" column at the table counts the game's own talk too ("Bet.", "Mister?"), so the
answer lines are quoted below from each run's JSON.

Baseline (main at a68e7b1e, before the step):

| verb | in the room (10 m) | saw it | reacted in 3 s | regard moved | mentioned later |
|---|---|---|---|---|---|
| sit | 11 | 2 | 2 (looks; Earl's greeting) | 0 | no |
| call | 9 | 6 | 0 | 0 | no |
| fold | 9 | 6 | 0 | 0 | no |
| raise | - | - | - | - | no verb: fire did nothing at the table |
| bluff | - | - | - | - | no verb (a raise on a weak hand) |
| win_pot | 9 | 2 | 2 (the table's own "you_win") | 5 | no |
| lose_pot | 9 | 2 | 2 (the game's talk; its long wait ran into No Law's murder: Cody at Earl) | 8 | no |
| cheat | 9 | 6 | 1 (the drifter's "Mister?", the game's own; G said "You! Step out here and face me!", a call-out) | 0 | no (Cody's own line, No Law) |
| stand | 9 | 6 | 0 | 0 | no |
| watch | 10 | 2 | 2 looks, no invitation | 0 | no |

After (`after_table`, raise from `after_table3`, call `after_table3`):

| verb | saw it | answered at once (the words) | regard moved | mentioned later |
|---|---|---|---|---|
| sit | 2 | Earl's greeting, the table's looks | 2 | news only for the pot, cheat, bluff |
| raise | 6 | Earl: "Big bet for a quiet man." | 6 | not news (small) |
| bluff | 6 | Earl: "Big bet for a quiet man." (they can't know yet; shown down it's `bluff_called`, the test) | 6 | told when shown up (test) |
| call | - | not met on the bench: its runs are the same deal every time, and no man bet into you in 400 s (twice); `test_card_answers::test_a_call_on_a_bet_is_answered` holds it (a nod on a bet: "He's in." / "Stays in. All right." / "Brave.") | (test: each table man keeps it) | no (small) |
| fold | 6 | the drifter: "Can't win 'em all, mister." | 6 | no (small) |
| win_pot | 2 | the table's "you_win" | 6 | yes: to your face, "Saw you clean up at cards, right here. Lucky hand."; told on, "The new man took a pot at cards, right here. Cleaned the table out." |
| lose_pot | 2 | the winner at you ("you_lose") | 8 | (the pot you'd won before it, told) |
| cheat (false) | 6 | Earl: "You calling me a cheat? In front of God and the drifter?"; the drifter: "Easy, now. It's a clean game." | 6 | yes: Earl, "You called me a cheat, right here. Never proved a thing."; told on by the liveryman |
| stand | 6 | Earl: "Mind how you go." | 6 | no (small) |
| watch | 2 | Earl: "You going to stand there all night? Chair's free." at 5.8 s | 0 | - |

A cheat called true (Earl dealt from the bottom this hand or the last; 30% of his deals) wasn't met on the bench's
run: tests/test_card_answers.gd holds it (Earl "caught", the drifter "cheat_seen", Earl's own `caught_him`, news
`cheat_true`), as it holds the bluff shown down and the needle after a big pot.
