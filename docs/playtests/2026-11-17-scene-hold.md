# Playtest 2026-11-17: the card game in the saloon yard (No Law murder)

Played headless in the valley, so no screenshots: judged by `read people`, `events` and `moment_result`.

## The question

**The scene in the saloon: did it look staged, and what happened when you fired?**

Watching it, yes, parts look staged. The talk is good, but people around the table don't react
as people. The drifter sits through a man being kicked to the floor and shot in the head beside
him, and never gets up, though the log says "drifter leaves". The fiddler, 6 m away, stays calm
and never moves. Afterwards the rancher and the barkeep walk back to their old spots by the table,
next to the body.

When I fired, the scene stopped at once and everyone reacted for themselves. Cody did not shoot
Earl. But then it froze the other way: Cody stood calm over Earl for 40 seconds, gun on him, doing
nothing. Earl lay "down" without a word. The drifter was "running" but didn't move.

## What I did

1. **Watch only.** Set the clock to 21:30 and stood at about 4 m from the table. Earl and the
   drifter were already playing (the clock didn't move on its own, so I started the scene). The
   stranger walked in and sat down in 3.5 s. Cody came in, kicked Earl's chair out from under him,
   shot him in the head on the floor, and walked out.
   ```
   stranger: "Evening. Mind if I sit in a while?"
   cody: "Earl, you cheating son of a bitch!"
   stranger: "Don't move, friend. Whatever happens next, you sit still."
   earl: "Now, Cody, I never..."
   13 pieces of timber broke / earl went down
   cody fired / earl hit in the head / earl died (brain)
   cody: "Ain't no law left in this valley to save you now, Earl."
   barkeep: "Jesus, Cody, my chair!"
   stranger: "You didn't see a thing tonight. Nobody did. Remember that."
   barkeep: "Somebody ought to fetch the... hell. Ain't nobody left to fetch."
   rancher: "Lord. Lord, lord."
   ```
2. **Interfere.** Restarted, same set-up. Cody walked right past me (1.4 m). He kicked the chair;
   as Earl went down I drew my revolver and fired once into the air.
   ```
   stranger: "Easy, friend. I ain't the one you want."
   you fired
   drifter: "Lord almighty!"
   cody: "Help you?"
   barkeep: "Get down! Everybody down!"
   no_law_murder: broken
   ```
   The scene says it broke the moment I drew ("the hold's broken (draw)"), before the shot.
   Earl lived with a broken bone. I watched 40 more seconds.

## What broke

- **The drifter is stuck.** Run 1: "drifter leaves" is logged, but he sat in the same spot for
  over a minute, calm. Run 2: he's "running" (flee) for 40 s and moved 30 cm.
- **The fleeing crowd piles into one spot.** In both runs the barkeep, miner, rancher, pianist and
  fiddler all ran to the saloon door and stood within half a metre of each other, for a minute.
- **Earl's wounds read 0** in `read people` while the scene says "Bone broken."
- The night clock stayed at 21:30 for a minute of waiting, so the scene never started by itself.

## What was flat or confusing

- **The drifter and fiddler don't react to the murder.** Both stay calm after a head shot at
  2 m and 6 m.
- **People go back to the table.** Run 1: the rancher and the barkeep return to their old places
  beside Earl's body and stand there "calm, shaken".
- **Cody after the shot (run 2):** "Help you?" and then nothing. Calm, armed, standing over Earl
  for 40 s. He doesn't finish Earl, doesn't leave, doesn't turn on me, doesn't threaten.
- **Earl on the floor says nothing** for 40 s: no groan, no plea, no crawling.
- **The stranger cowers in his chair** after telling me to sit still; he never acts again.
- **The stranger's "Don't move" line** came while I was standing, not sitting, and nothing held
  me ("you're held: false"). It reads as said to the table.
- Run 1: Cody walked out to the street and stood calm 11 m away for over a minute.

## What was fun

- The lines are good: "Jesus, Cody, my chair!", "Ain't no law left in this valley", "Ain't nobody
  left to fetch."
- The chair kick is physical: 13 pieces of timber broke and Earl fell for real.
- Interfering really changes things: drawing alone ended the scene and Earl lived.
- The crowd fleeing at the first shot, and the barkeep shouting "Get down!", felt right.

## The top three things to fix

1. **Bystanders who don't react:** the drifter and fiddler sitting calm through a murder, and
   people walking back to the table beside the body.
2. **The broken scene goes dead:** after my shot, Cody, Earl and the stranger freeze for 40 s.
   Cody should do something (leave, finish it, or face me); Earl should crawl or call out.
3. **Fleeing people stuck or heaped:** the drifter can't get away, and five people pile up in
   one spot at the saloon door.
