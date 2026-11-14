# Playtest: ten gunfights in the new saloon, build "D+", fourth round (2026-11-04)

Blind playtest. Ten fights: each setup twice, seeds 1 and 2, every one with
`fixes=all+pain_fight+floor_fight+odds+flinch`. One fight per game, the game restarted between.

**Result: lost 10 of 10. Won 0, no other endings.** I put down two men for a moment (they got up
or were never counted down) and killed nobody. I landed 6 hits in about 27 shots.

**A warning about the machine.** It was busy (load ~9 on 4 cores). The game often ran at 1-2
frames a second. A single command could take 3-10 s of game time: `look` took 7 s once,
`press crouch_toggle` took 7 s, and once a `shoot` fired 2.4 s after the `look` before it. The men
moved in that gap, so several of my misses are the lag, not the game. In fight 4 I was out cold
before my first shot went off. Read the hit rates with that in mind.

## The ten fights

1. **spec_hall, seed 1** (waited for them; ~23 s). They drew while I was still holstered. I hit
   Brody in the chest; he cried "My leg!" and "went down", but the result still calls him "standing".
   The Kid shot Lyle's hat off and hit him in the head. Lyle shouted "Watch where you're shooting!"
   and kept fighting. I hit Lyle in the foot (I aimed at his chest) and ran dry. I crouched to reload.
   The Kid walked up to 4 m and shot me three times in 3 s: thigh (femoral, bone broken), gut, pelvis.
   I blacked out.
2. **spec_hall, seed 2** (shot first; ~43 s). I missed Lyle twice at 5 m and Brody once. I was
   gut-shot, then hit in the thigh. I ran out to the west end of the porch and reloaded to six. All
   three called flanks and covers. The Kid came out of the door alone. He hit me twice in the hip at
   4 m before my shot left, and I blacked out.
3. **spec_stair, seed 1** (shot first, crouched; ~9 s). From a crouch I hit the Kid on the stair
   in the belly, and he went down. Brody went to drag him. Lyle hit me in the pelvis and the upper arm,
   and Brody hit me in the chest. I hit Lyle in the belly and he "went down". I blacked out 1 s later.
4. **spec_stair, seed 2** (waited, crouching; ~5 s). The lag ate this one. The Kid hit me in the
   heart at 9.6 s, then the gut, then Brody hit my thigh. Out cold at 13.8 s without one shot fired.
5. **spec_gallery, seed 1** (backed out the front door before it started; ~41 s). I crouched on the
   east porch, behind the wall. For 25 s they peeked and searched ("Where'd he go?", "I know you're
   there."). Then Brody came to the doorway, 6 m off. `look` said only his right upper arm showed,
   then nothing (a stud in the way). He hit me four times out of four: arm, hip, gut, forearm. My one
   shot went into the stud. The forearm broke and I couldn't hold the gun. Out cold.
6. **spec_gallery, seed 2** (shot first; ~20 s). I hit Lyle on the gallery in the chest from the
   hip, though `look` had said the barrel's line met a baluster that "stops a ball". Brody, behind a
   post, broke my ribs, then my right forearm ("can't hold the gun: a broken forearm"), then gut-shot
   me. Out cold.
7. **spec_back, seed 1** (drew and shouted "Drop it!" at Brody from 2.7 m; ~10 s). Nobody answered
   the shout. Brody only went to "notice". Lyle opened fire 3 s later. Neck, chest (a lung), left
   forearm: out cold before my first shot went off.
8. **spec_back, seed 2** (shot first, then fell back; ~50 s, the longest). Brody was hit in the
   chest at 2.7 m and backed into the back room. I ran to the hall's east side, crouched and
   reloaded. Three shots at the Kid on the gallery went into the balusters. I emptied two at
   Brody as he went up the stair, and both missed. Lyle hit me in the chest ("Your back's broken")
   and then the head ("Your nose is shot off"). Out cold.
9. **spec_front, seed 1** (shot first from the street; ~28 s). I missed Lyle twice at 9.5 m while
   he stood still on the porch. They went inside, and I ran to the porch's west end and reloaded to
   six. Lyle went out the front and round into the street behind me. He took two of my fingers,
   then shot me in the heart.
10. **spec_front, seed 2** (went to the street's east corner and crouched before it started;
    ~30 s). The Kid shot through the closed door from 9 m and hit me three times out of four: hip,
    thigh, chest. The chest hit's message said "You can't hold the gun: a broken collarbone", a
    wound I'd never been told of. I could do nothing for ~18 s. Then Brody and Lyle finished me.

## Did they fight?

Yes, hard. Every fight they shot back within a second or two. They called covers, reloads and
flanks to each other ("Keep him busy, I'm going round!", "I'm empty! Cover me!"), and the calls
were real: Lyle in fight 9 did go round. They took cover, peeked, searched when they lost me
("Come on out!", "I know you're there."), came through doors, and climbed the stair. Nobody folded.
Wounded men kept going: Brody chest-shot in fight 8 went upstairs and kept shooting, and Lyle
chest-shot in fight 6 stayed in it. Their shooting is deadly. Most fights they hit me 3-4 times in
5 s, often through doors, glass or a doorway I couldn't see them in.

## Who quit, and was it earned?

Nobody quit, ran or surrendered in ten fights. That fits what happened: I never hurt any of them
badly enough, and they were never alone. "Drop it!" at 2.7 m (fight 7), before any shooting,
got no answer at all, not even words.

## What broke

- **Told about one wound, disarmed by another.** Fight 10: "Hit in the chest. It's pumping. A lung's
  holed. / You can't hold the gun: a broken collarbone." No collarbone was ever named. Then
  "You can't hold the gun: a broken collarbone" repeated on the screen four times. The forearm cases
  (fights 5 and 6) did match: forearm hit, "Your forearm's broken", can't hold the gun.
- **"Pressing on the wound..." while out cold.** Fights 6 and 10: I pressed tend wounds after I'd
  blacked out and the screen said I was pressing on the wound.
- **`press fire` and `shoot` with an empty gun say nothing.** Fights 1 and 8, 0 loaded: `press fire`
  gave no `why`, and `shoot 1` answered "clicked 1, fired 0" with no reason. The "you're out cold" and
  "broken forearm" reasons did come through.
- **Men "went down" but count as standing.** Brody (fight 1) and Lyle (fight 3) each "went down" in
  events. The result lists both as plain "standing", while the Kid shows "standing, then down".
  A second later Lyle was "calm", 4.8 m away, with a ball in his belly.
- **`look` and where the ball went didn't always agree.** Fight 6: `look lyle` said the barrel's
  own line met an oak baluster that "stops a ball: 6 cm of it", yet my hip shot hit him in the chest.
  Fight 10: `look lyle` listed "clear_to: head, neck, chest..." and in the same answer said the ball
  goes through a red wall board and a framing board. "Clear" can't mean "as your eyes would see" if
  there's a wall between.
- **Aimed shots couldn't be tested.** `press aim 1` lets go of the sights before the next command,
  and nothing (`read player`, `look`, the weapon line) shows whether the sights are up. I couldn't
  shoot with the sights raised or check that it moves the barrel's line to my eye.
- **Fight 5 felt unfair.** Brody at a doorway 6 m away hit me 4 for 4, while `look` told me
  nothing of him was clear and my ball stopped in a stud. Maybe he had a line I didn't, but from
  my side he was shooting from inside the wall.
- **A blackout is a switch.** In nearly every fight I went out cold within 0.1-1 s of the third or
  fourth hit, still with 4.3-4.9 litres of blood. In fight 4 I stayed up 4 s after "It's your heart".
  Then I blacked out at once from a thigh hit.
- A dropped gun reads "revolver put away ... hammer cocked" (fight 6).

## What they said that didn't fit

- **Chest hit, "My leg!"** Fight 1: "brody hit in the chest", then Brody: "My leg! Get me out of here!"
- **Neck hit, "You're gut-shot."** Fight 7: "Hit in the neck. It's pumping. You're gut-shot." I was
  never hit in the belly. The status line kept saying "gut-shot" until the end.
- **Fingers miscounted.** Fight 9: the screen said my little and ring fingers were gone, and the status
  line then said "4 fingers gone". Only one hand hit.
- **"He's hit! Go, go!" before I was hit.** Fight 1, 29.3 s: the Kid called it with me unhurt (I was hit
  0.6 s later). Fight 9: "He's empty! Get him!" when I had two rounds left (I'd just begun to reload).
- **The status line calls me "his".** "blood in his throat", "his nose shot off".
- **A bystander's "...They gone?"** Fight 6: far_man_a said it with shots still flying, a second
  after his "Lord almighty!".
- **Gut shots are named unevenly.** A belly hit in fight 8 said only "Hit in the abdomen." and
  "Bleeding a little". Other belly hits said "You're gut-shot" at once.
- "Your back's broken" from a hit in the chest and upper arm from the front (fight 8). It may be
  right (the ball going through), but nothing else told me so.

## Moving

`walk PLACE run` worked every time (6-9 m runs, even with a thigh wound). Leaving by the front
door before the shooting (fight 5) bought 25 s of stand-off, the longest I stayed unhurt. Falling
back to reload (fights 2, 8, 9) worked once each, but they always found me: through a door, or by
going round outside. Crouching made no difference I could see. I was hit as often crouched as
standing.

## What was fun

- Their talk. The covers, reload calls and flanks read as a gang working together, and Lyle's flank
  in fight 9 really happened.
- Friendly fire: the Kid shooting Lyle's hat off, and "Watch where you're shooting!"
- The stand-off in fight 5: "Where'd he go?", "I know you're there.", then Brody easing up to the door.
- Brody dragging the downed Kid in fight 3 ("Hold on, I got you!").
- The wound messages, when they're right, are vivid ("Your nose is shot off.").

## What was flat

- Losing all ten, mostly in under 10 s once I was first hit. Three or four hits came in 3-5 s,
  then out cold. I never had a moment to react to a wound (tie it off, crawl, fight from the floor).
- My shots. Six hits in ~27 and no kills. Clear-line misses on standing men at 5-9 m. Some of it is the
  lag, but even a still, calm Lyle at 9.5 m (fight 9) took two misses.
- Nobody ever quit or surrendered, and "Drop it!" did nothing.
- After I was down, all three went straight to "calm". Nobody came to look or finish it.

## The top three things to fix

1. **Say the wound that disarms you.** If the gun drops for "a broken collarbone", the hit message
   must name the collarbone (fight 10). The other wound messages need the same care: a neck hit
   shouldn't say "gut-shot", two lost fingers shouldn't become four, and a chest-shot man shouldn't
   cry "My leg!"
2. **Give the player time between the first hit and out cold.** Three or four hits land in 3-5 s and
   the blackout follows at once, with most of the blood still in. Every fight ended that way, so
   the gang's deadliness leaves nothing to play after the first hit. Their shots through doors and
   from doorways I couldn't see into (fights 5 and 10) made it feel worse.
3. **Make the tools tell the truth.** `look`'s "clear_to" lists parts behind a wall board. Its
   barrel line said "stops a ball" and the ball hit him anyway. `press fire`/`shoot` on an empty gun
   give no reason. "Went down" men count as standing. "Pressing on the wound..." shows while I'm out
   cold. And there's no way to hold the sights up while shooting, or to see whether they're up.
