# Playtest: ten gunfights in the new saloon (2026-10-23)

> **Note (the gameplay session):** most of these fights ran on a tree with main merged in but not yet
> imported (two new `class_name` scripts the kit props use), so the saloon's fixtures and furniture
> didn't build as they should. The falling west gallery (8 of 10 fights) didn't happen again in three
> played tries and ten lab fights after the import. Round 2 (`2026-10-23-gunfight.md`) is the clean run.

A playtester who hasn't read the code, playing headless through the dev bridge, following
`experiments/gunfight_lab/PLAYTEST_AGENT.md`. Times are game seconds from the start of each fight.
The bridge is slow (each command takes a second or more), so my reactions were slower than a
player's on a keyboard.

I restarted the game before each fight after fight 2. Your wounds carry from one `gf_play` to the
next (see "What broke"), and in my first go at fight 2 my broken right forearm from fight 1 meant
I couldn't draw at all. I went down without firing a shot. I replayed it from a fresh start.

## The ten fights

1. **Hall, seed 1.** I was slow, so they drew first. I fired four shots at Lyle and Brody, then
   one more. One aimed at Lyle hit the Kid in the pelvis because they were in line. They split up,
   called "flank" and "covering", and the Kid and Lyle shouted at each other for shooting close.
   Brody hit me in the chest, then the forearm. I blacked out at ~50 s. Nobody quit. A real
   fight, and the best one.
2. **Hall, seed 2.** I waited with my gun out. The Kid's first shot broke a gallery joist, and
   then about 775 pieces of timber came down. Falling timber hit me in the head twice and I
   blacked out at ~14 s. The same fall knocked Brody out cold. I fired nothing. Over in ~6 s of
   fighting.
3. **Stair, seed 1.** I shot first. At ~7 s, before any of their shots, about 760 pieces of
   timber broke and Brody was knocked out cold. The Kid tried to drag Brody clear, which was nice
   to see. The Kid gave up after one chest hit and then fell. Lyle kept shooting and hit me
   twice. A fall knocked Lyle out cold, and I put three more rounds in him. I won at ~30 s, but
   the building did most of it.
4. **Stair, seed 2.** I crouched and waited. All three fired within 0.3 s of each other when the
   count ran out, and three hits put me out cold in about 2 s. The gallery came down again
   (joist 011, then 134 pieces). Over at ~12 s.
5. **Gallery, seed 1.** I shot first and hit Brody's arm. At ~7–8 s the gallery came down
   (about 760 pieces). The Kid fell off it and gave up straight away, and Brody was knocked out
   cold under it. Lyle, still up top, fought on alone and hit me twice. Then he went down from
   hits I didn't fire. I won at ~22 s.
6. **Gallery, seed 2.** I tried to back out the front door, but my walk stopped at the doorway
   and wouldn't go further. I stood there and didn't fire for 25 s. The Kid fell, then Brody
   took a long run of "hits" (pelvis, head, neck, both arms...) with no shots fired, and gave up
   ("That's it, boys. Throw 'em down"). The Kid gave up too. Lyle went down to my first two
   shots. Over at ~30 s. The gang lost to the saloon, not to me.
7. **Back, seed 1.** I shot Brody in the chest at 2.7 m. He kept fighting, which felt fair. The
   gallery came down 0.2 s later (joist 011 again). Brody and the Kid then hit me four times in
   2 s, and I blacked out at ~14 s. Nobody quit.
8. **Back, seed 2.** I shouted "Drop it!" before the fight. Nothing happened: no line of mine in
   the events, no reaction from them. They drew at ~8 s and the gallery came down. The Kid fell,
   and Brody dragged him clear, then went down on his leg and gave up. Lyle kept fighting alone,
   then took a run of hits I didn't fire, went down and gave up at ~38 s ("I ain't dying for
   this!"). I killed the Kid with a head shot while he lay there. Over at ~50 s.
9. **Front, seed 1.** I was in the street, the Kid in the doorway, Lyle on the porch and Brody
   on the balcony. My first shot dropped the Kid (pelvis), and 0.2 s later the gallery joist broke
   and 775 pieces came down. Lyle shot me in the head at ~14 s. The result said **"you_dead"**,
   but I "came round" in the street, unhurt.
10. **Front, seed 2.** I crouched and walked off to one side of the street, 13–15 m out. They
   drew, then hid in the doorway. Lyle and the Kid stood 0.3 m apart and kept saying "Hey! That
   was me!" to each other. Brody stayed upstairs "searching" and **never fired in 165 s**. Twice
   he went back to his opening lines ("Keep that iron where it is", "Your funeral, friend")
   in the middle of the fight, right after Lyle died. The Kid called "I'm going round!" twice
   and never moved. I killed Lyle with a head shot at ~75 s, walked in, and dropped the Kid at
   2.9 m as he reloaded. He gave up after a second chest hit, and I'm afraid I put two more in
   him. Then I blacked out from my own bleeding, and the result was "broke_off" for Brody.
   Over at ~170 s. The gallery stayed up in this one.

## Did they fight?

Yes, when they got the chance. They shoot fast and well at close range: when I waited, all three
fired together and put me down in 2–6 s. They call out ("I see him!", "Covering!",
"Keep him busy, I'm going round!"), drag a downed friend, and say what they feel. Most fights
were short, though, and the saloon decided them more than the men did. At range (fight 10) they
went passive: they hid, peeked, and rarely fired. Their "flank" calls never turned into a man
actually going round me.

## Who quit, and was it earned?

- **The Kid** quit in 5 of 10 fights. Mostly he gave up right after falling off the collapsed
  gallery (fights 3, 5, 6). That reads as cowardice when really the floor dropped him. In fight
  10 he quit after a second chest hit, which was earned.
- **Brody** quit twice (fights 6 and 8), both times after hits from falling timber or a fall,
  not from me. It looked earned (hurt, Kid down), but the player didn't do it.
- **Lyle** quit once (fight 8), alone with Brody and the Kid down and hit several times. Earned.
- Lyle's "Get up, you yellow dog!" whenever someone quits is good.

## What broke

- **The gallery collapses in almost every fight.** In 8 of 10 fights, 700–775 pieces of timber
  broke at 7–12 s, usually starting with `west_gallery/joist/011`, at about the moment the
  shooting starts. Sometimes it followed a shot (theirs or mine) and once it came before anyone
  fired. Men on it fell off. Men under it were knocked out cold or took long strings of "hits"
  with no shot fired (dozens in fights 6 and 8). It hit me in the head too. It decides most
  fights.
- **Your wounds and ammo carry over between `gf_play` fights.** The next fight starts with your
  broken arm, blood loss and part-empty gun. In fight 2's first go I couldn't draw at all
  (`weapon revolver` returned not ok).
- **Seeds 1 and 2 start identically.** Same positions and the same opening lines.
- **"you_dead" but you come round** (fight 9). After every blackout I woke up in the street at
  (-23.9, 6.2), 40 m away. The gang greet you there with "Help you?" and "Easy, friend." as if
  nothing happened.
- **Brody forgot the fight** (fight 10). He went back to calm and his warnings ("Keep that iron
  where it is") in the middle of a gunfight, and said "...Gone." / "Where'd he go?" while I stood
  crouched in the open 15 m away.
- **"Flank" calls that never move.** The Kid announced flanking several times and never left the
  doorway.
- **Every hit on you is also logged as a near miss** ("you hit in the chest" plus "a round passed
  0.2 m from you").
- **A man's `wounds` count stays 0** after many "hit" events from falls or timber (Brody and the
  Kid in fights 6 and 8).
- **Walking out the front door stopped at the doorway** (fight 6: `walk` stopped, `arrived false`,
  0 m on the second try). In fight 10 I could walk in through the same door from outside.
- **Shouting "Drop it!"** before the fight did nothing visible.
- **Lyle and the Kid stand on top of each other** in the doorway and shoot past each other's ears
  (fight 10).

## What was fun

- Fight 1: three men splitting up, covering each other, a stray round of mine hitting the Kid
  because he was in line with Lyle.
- Their voices: the warnings before the draw, "Oh God, Lyle...", "Kid! Stay in it, you hear?",
  "I ain't dying for this!", "I'm empty! Cover me!".
- A man dragging a downed friend clear under fire.
- Walking up on a man while he's reloading.

## What was flat

- Waiting for them is death in 2 seconds. There's no tension before the draw, just a countdown.
- At range, nothing happens for long stretches. They hide and say "I know you're there."
- Too many endings come from the building or a blackout, not from a decision by you or them.

## The top three things to fix

1. **The gallery coming down at the start of most fights.** It takes men out and decides the
   fight before anyone's skill counts.
2. **A fresh fight should start fresh.** Reset the player's wounds and ammo, and make the seeds
   actually differ. "you_dead" should not wake you up in the street.
3. **The gang at range.** Brody drifts back to calm and repeats his warnings mid-fight, and
   "flank" calls never become movement. When the player isn't in their faces, they should press
   him, not wait.
