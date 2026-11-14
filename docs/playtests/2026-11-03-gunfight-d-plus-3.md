# Playtest: ten gunfights in the new saloon, build "D+", third round (2026-11-03)

A blind playtest. I had not read the game's code. I played through the dev bridge, headless, with
`gf_play SETUP seed=N fixes=all+pain_fight+floor_fight+odds+flinch`. I restarted the game before
every fight.

**Result: won 1, lost 8, and 1 ended in a "lull" with me still on my feet.**

A note on the test itself: the machine was busy. The game ran at anything from 1 to 130 frames a
second, and my commands often landed 2 to 8 seconds of game time after I sent them. In a real game
I'd have drawn and fired sooner. Fights 1 and 7 were lost partly to that.

## The ten fights

1. **Hall, seed 1.** I never drew (I was slow). They drew on the timer. Brody put five shots at me
   from 7 m. One hit my upper arm, then one hit my neck and I blacked out. Lost, about 16 s after
   they drew. Nobody was hurt but me.
2. **Hall, seed 2.** I drew at once and they warned me off ("Keep that iron where it is"). I fired
   three at Lyle and missed: he'd gone behind a post. Then I crouched where I stood. A gut shot,
   then a forearm hit, then I blacked out. Brody called a flank and the other two covered him. I
   died of blood loss. Lost, about 15 s after the first shot.
3. **Stair, seed 1.** I fired first at Lyle and missed. One ball hit my chest and I was told I
   couldn't hold the gun because of "a broken upper arm". A head shot killed me 6 s later. Lost,
   about 10 s.
4. **Stair, seed 2.** I crouched and fired first. My first shot hit the Kid in the chest on the
   stair. He backed up to the gallery and later called "That's it, we're done here! Run!" and ran
   off. I wasted shots into wood and reloaded in the open. Brody called "Now! Rush him!" and Lyle
   flanked while Brody covered. I took eight hits in 30 s and blacked out. My two clear shots at
   Brody from 4 m both missed. Lost, about 55 s. The Kid fled.
5. **Gallery, seed 1.** I let them draw, then ran out the front door to the west end of the
   porch and crouched there. They called "Where'd he go?" and "Come on out!" but none of them came
   out. From 18 m I hit the Kid twice (thigh, then a head graze). I took one pelvis hit. They lost
   me ("Damn it. Lost him."). I bound the wound, walked back in, and the fight was declared over
   as a "lull". Brody and Lyle had quietly left: Lyle was 40 m away in the street. The Kid, hurt
   twice, was still in the room, and he fired again after the fight had "ended". About 165 s, and
   I survived.
6. **Gallery, seed 2.** I fired twice at Lyle on the gallery (missed), ran behind the bar and
   crouched. I spent many shots at Brody and hit nothing (see "What broke"). Then I hit Lyle through
   the gallery floor above me: shin, thigh, foot, arm. He gave up ("Enough! It's yours!") and passed
   out. Brody shouted "Get up, you yellow dog!". I stood up behind the bar and hit Brody in the hand
   and neck. He went down ("Can't... get up..."). The Kid gave up unhurt. Then I ran out of
   cartridges, without a word from the game. I shouted "Drop it!" at Brody with an empty gun and he
   quit 5 s later. **Won**, all three surrendered, about 225 s.
7. **Back, seed 1.** I waited for them to draw, then drew. Lyle hit me in the chest from 9 m on
   his first shot, then in the head. Lost, about 6 s.
8. **Back, seed 2.** I fired first: Brody was hit in the chest at 2.7 m. I ran into the back room
   and crouched. Brody stayed on his feet, came after me and hit my arm twice. I blacked out. Lost,
   about 13 s. Only Brody was hurt.
9. **Front, seed 1.** With my gun holstered I called Brody out ("You! Step out here and face
   me!"). He said "Go on. Make your play." Then he drew 2.5 s later, before I'd drawn, and the Kid
   and Lyle joined in. Four hits in 5 s. Lost, about 14 s.
10. **Front, seed 2.** I crouched and fired first through the batwings. The Kid was hit in the
    chest, though `look` said the door was in the way. I ran east along the front. Lyle fired
    through the front window, and the events said his own round hit Lyle in the forearm, abdomen
    and upper arm. Two seconds later he killed me with one head shot. Lost, about 8 s.

## Did they fight?

Yes, hard. They shot back at once and called their moves: "Cover me, I'll get round him!", "Go on,
I got you!", "Reloading! Cover me!". When I was empty they knew it: "He's empty! Get him!". They
flanked, covered each other's reloads and rushed me when I was hurt. Nobody folded early.

They didn't come after me when I left the room. In fight 5 all three stayed inside, "searching",
for two minutes while I sat on the porch outside the door.

They are very deadly. Most fights were over 6 to 16 seconds after the first shot. Often one hit was
enough to take my gun or knock me out.

## Who quit, and was it earned?

- **The Kid ran (fight 4)** after one chest hit. He was alone up on the gallery. That felt earned.
- **Lyle gave up (fight 6)** after four or five hits. Earned.
- **The Kid gave up unhurt (fight 6)** once Lyle was out cold and Brody was down. Earned: he was
  alone.
- **Brody gave up (fight 6)** after four hits including the neck, with both friends out, at my
  "Drop it!". Earned, and a good moment.
- **Brody and Lyle broke off (fight 5)** unhurt, while the Kid (hurt twice) fought on. They said
  nothing and simply walked out into the street. That didn't feel earned, and I only found out
  from `read all`.

## What broke

- **"Your ear finger's gone."** On a head hit the screen said this, twice (fights 7 and 10).
- **Lyle's own shot wounded Lyle** (fight 10). "lyle fired", then "lyle hit in the forearm_r",
  "abdomen" and "upper_arm_l", and the front window broke. He kept fighting.
- **Wound messages don't tell me what really happened.**
  - Fight 3: "Hit in the chest. It's pumping." and then "You can't hold the gun: a broken upper
    arm". No arm hit was ever reported.
  - Fight 8: I was told "Hit in the forearm" and "Hit in the upper arm", and then I blacked out.
    My state said "gut-shot, bone broken" with five wounds. The gut shot was never announced.
  - Fight 2 and fight 5: "going pale with no wound to show for it".
  - Fight 5: "Hit in the pelvis. It's pumping." while my state read "Bleeding a little".
- **Every hit on me also came as a near miss** from the same round ("passed 0.0 m from you").
- **No word when I ran out of cartridges** (fight 6). `press reload` answered fine and left "0
  loaded", again and again.
- **`press reload` with the gun put away** (after binding a wound) also answered fine and did
  nothing.
- **From behind the bar my shots didn't go where my eyes could see** (fight 6). Crouched, `look
  brody` said I had a clear line to his chest and the sights were on him at 8 to 16 m. About a
  dozen shots hit nothing. One broke the bar's own frieze in front of me. Once I stood up, hits
  came.
- **What I aimed at and what I hit were far apart.** In fight 5 I aimed at the Kid's head (the only
  part I could see) and hit his thigh. Aiming at his upper arm hit his head. The game hadn't said my
  aim was hurt.
- **The batwings and the gallery floor didn't stop my balls.** The batwings were reported "in the
  way" but I hit the Kid's chest through them. Through the gallery floor I hit Lyle's shin and foot.
  If that's how it's meant to be, `look` shouldn't call the door "in the way".
- **The fight ended as a "lull" with the Kid still shooting** (fight 5). He fired 10 s after the
  end.
- **Brody went down and then said he'd flank** (fight 6). He had "Can't... get up..." and "went
  down", then "Keep him busy, I'm going round!" 3 s later. `gf_result` called him "standing"
  throughout.
- **Men who surrendered still showed as armed** (fight 6, all three).
- **Lyle "rescued" the Kid while the Kid was on his feet** (fight 5). "Easy, I got you. Come on!"
  came twice, 24 s apart. The Kid stood in the open, shooting and reloading the whole time.

## What they said that didn't fit

- **"You damn fool!" / "That's how it is? Fine!"** when the 6-second timer ran out and I'd done
  nothing (gun still holstered). This happened in fights 1, 3, 5, 7 and 9, and also after a duel
  challenge I hadn't acted on.
- **The Kid said "I'm gone!" and didn't go** (fight 6). He gave up there 14 s later.
- **The Kid said three things in one breath** (fight 10): "Lord, get me out of this one.", "He's
  got me pinned!" and "That all you got?".
- **"Hey! Mind where you're aiming!" / "Watch where you're shooting!"** came after nearly every
  friend's shot, including shots that hit me.
- **Lyle said "Walk on, mister."** as he shot me dead.
- **A townsman 50 m away asks "...They gone?"** a few seconds into every fight, while the shooting
  is still going on.
- **The duel wasn't a duel** (fight 9). I called Brody out and he drew first without waiting for
  me, and his two friends joined in.

## Moving

Walks and runs ended where I sent them, through doors and down the front steps. A crouched walk
stayed crouched. A run from a crouch left me standing, which seems fair, but nothing said so.
Commands sent while I was out cold or dead still answered "ok". A crouch toggled on my dead body.

## What was fun

- Fight 6: a long fight from behind the bar. I heard Lyle give up, Brody called him a yellow dog,
  the Kid cried "They got Lyle!", and Brody gave up to an empty gun and a shout.
- Their callouts. You can follow the fight by ear: flanking, covering, reloading, "He's empty!".
- Slipping out the front door and hearing them lose me ("Where'd he go?", "Damn it. Lost him.").
- Binding my own wound with a bandana mid-fight.

## What was flat

- Most fights end 6 to 16 s in, often on the first or second hit. That's too quick to use cover,
  moving or a plan.
- Shooting from cover felt pointless when the bar ate my shots.
- When a wound took my gun or my senses, I didn't know which wound had done it.
- Fight 5 just stopped: two of them left without a word and it was called over.

## The top three things to fix

1. **Tell the player what happened to him.** Name the wound that matters: the gut or chest shot
   that drops you, not only the arm. Give the right reason when the gun is lost. Fix "Your ear
   finger's gone." Say when you're out of cartridges. Don't report a hit as a near miss too.
2. **Make the balls obey one rule for everyone.** A gunman's own shot shouldn't wound him. A clear
   line from behind the bar shouldn't put your balls into the bar. If doors and floors don't stop
   a ball, `look` shouldn't call them "in the way".
3. **Make the gang's words and states match what's happening.** No "You damn fool!" when you've
   done nothing. No "I'm gone!" from a man who stays, or flanking talk from a man who's down. A
   duel should be one man. A fight shouldn't end while one of them is still shooting, and men who
   leave should say so.
