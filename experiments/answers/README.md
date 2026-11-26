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
