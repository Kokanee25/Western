# Playtest: ten gunfights in the new saloon, build "D+", second round (2026-11-03)

Blind playtest. Every fight used `fixes=all+pain_fight+floor_fight+odds+flinch`, one fight a game,
and the game was stopped and started between fights. Played headless through the dev bridge.

A caveat first: the game runs in real time and I take about 5 to 10 seconds to read and decide
between commands. So I react like a slow player. A burst of commands I send together is quick,
but each new decision costs seconds. Aiming with `look NAME` points at the middle of the man,
so if a post or stud is in that line I hit the post.

## The ten fights

1. **spec_hall, seed 1.** I was slow and they drew first at the 6 s mark. Brody fired first from
   the bar at 14 s and hit my right arm. My two shots hit a post. Brody shot me in the neck at
   24 s. Down. About 16 s from their draw. No one on their side hurt.
2. **spec_hall, seed 2.** I shot first and hit Brody in the chest, then ran out of the door to
   the west end of the porch and crouched. Reloaded there. Lyle called "Cover me, I'll get round
   him!" and he and Brody came to the front window and door, 3 to 5 m from me. My three shots
   through the glass missed. I stepped east along the porch; the Kid hit me in the chest from
   15 m, then Lyle in the forearm. Down at 50 s. Brody one wound, still fighting.
3. **spec_stair, seed 1.** I waited for them to draw. The Kid, on the stair, hit me in the chest
   about a second after he spotted me, then again 3 s later. My three shots hit framing. Brody hit
   me in the chest and arm as I tried to leave. Down at 18 s, about 10 s after their draw.
4. **spec_stair, seed 2.** I shot first at Lyle, 6.5 m away and clear in my sights. Two misses.
   Brody shot me in the head 2 s after my first shot. Down at 10 s.
5. **spec_gallery, seed 1 (the best fight).** Before the count ran out I walked out of the front
   door to the east end of the porch and crouched, gun out. They saw me through the windows. The
   Kid and Brody shot at me; Brody worked forward. I hit Brody twice through the glass (each ball
   went through an arm and into his belly). He came out onto the porch steps behind a post. I
   shouted "Drop it!" twice. He went back to the doorway, and I dropped him there, out cold
   with five wounds, at 60 s. The Kid then tried to reach him for nearly two minutes. Lyle lost
   me and went calm. I went up the stair and along the back gallery, and hit Lyle in the belly
   and the chest. "Drop it!" at Lyle got "You'll have to kill me!" and a ball in my chest.
   Down at 182 s.
6. **spec_gallery, seed 2.** I shot first at Brody, 7 m, in my sights, aim held. Three misses. I
   ran under the front gallery; hit in the forearm and the chest on the way. Down at 23 s. No one
   on their side hurt.
7. **spec_back, seed 1.** Brody started 2.7 m from me. I shot first and hit him in the chest
   through the boards, and hit Lyle once. Two balls broke my right upper arm. After that my gun
   was "put away" and I could not draw it again. I hid by the back room. They searched ("Where'd
   he go?", "...Gone.") but kept watch. I ran for the street, and Lyle shot me in the back on the
   front steps at 58 s.
8. **spec_back, seed 2.** I moved to the kitchen end before the count ran out. When they drew, I
   shot Lyle's hat off ("Close. Real damn close."). My other shots hit studs. Brody hit me in the
   belly and the pelvis. Down at 26 s.
9. **spec_front, seed 1.** I was in the street, they were on the porch and the balcony. I shot
   first three times and hit the batwings and the siding. They all went inside and shot me from
   the doors and windows while I reloaded in the open. Down at 23 s. My mistake, but they were
   very fast.
10. **spec_front, seed 2.** I shouted "Drop it!" at Lyle before anyone had fired. That started the
    fight. The Kid hit me twice in the chest and Brody took a finger off. I ran 11 m back
    into the street, crouched and pressed on my wounds. The bright bleeding slowed. Then a long
    exchange at 19 m: Lyle shot from the doorway over the batwings and came within 0.1 to 1.6 m
    of me again and again, while my shots at him hit the batwings and a porch post. I blacked out
    from my own wounds at 73 s while reloading. No one on their side hurt.

Result: they won all ten. Brody was knocked out once (fight 5). I hit them about ten times with
about 45 shots.

## Did they fight?

Yes, hard. They shot back at once, used the bar, the windows, the doorway and the galleries,
and called to each other ("Cover me, I'll get round him!", "Covering!", "I'm empty! Cover me!",
"He's hit! Go, go!"). The flank calls were followed by real moves: in fights 2 and 5 a man came
to the window or door right next to me. They kept watch on where I'd gone ("I know you're there",
"Come on out!"). The Kid tried to rescue Brody when he went down. Nobody folded.

They are very accurate. Hits in the chest from 15 m within a second or two of seeing me were
common. Near misses at 0.0 to 0.3 m were common too.

## Who quit, and was it earned?

Nobody quit or ran in any fight. No one gave up to "Drop it!".

- Brody took two balls through his arm into his belly ("Oh God, not the belly..." came later).
  He still came forward to the porch and kept fighting until a fifth wound knocked him out. A
  man with three belly wounds might give up, or at least stay down.
- Lyle took a ball in the belly and one in the chest, and answered "Drop it!" with "You'll have
  to kill me!" and a shot that dropped me. That felt in character for one man, but it was
  the same every time.
- Lyle went calm in the middle of fight 5, with Brody down a few metres away. He said "Damn it.
  Lost him." and then "Walk on, mister." When I showed myself again he started from the warning
  lines again ("Don't you do it.", "Your funeral, friend."). That felt wrong for a man whose
  friend I had just shot.

## What broke

- **The Kid's rescue loop (fight 5).** After Brody went down on the ground floor, the Kid called
  "Hold on, I got you!" (drag Brody) at least five times over about 100 seconds. He stayed on
  the front gallery above Brody and never got down to him.
- **Disarmed with no word (fight 7).** After two hits broke my right upper arm, the gun read
  "revolver put away". `weapon revolver` answered `ok: false`, and shoot and reload did nothing,
  with no message. The rule may be fair, but the player is never told.
- **Dead, then up again (fight 4).** After Brody's head shot, `read all` said `alive: false`,
  "Dead (brain)". Four seconds later "you came round" at the doctor's, alive. (In every fight,
  being knocked out moves you about 45 m away to the doctor's front. I took that to be how the
  lab ends a fight.)
- **Their lines when you're down.** When I blacked out (or died), they said "That's better.",
  "Smart.", "Go on, then.", "Easy, friend.", "Help you?". These are lines for a man who backs
  down, said over a man who is out cold.
- **"Hey! That was me!"** The Kid and Lyle say it when a friend's shot passes near them (fights
  1 and 3, three times). It reads as if he is claiming the shot. "Watch where you're shooting!"
  (fights 4 and 7) reads right.
- **One-sided cover.** Often my sights on a man's middle were on a stud, post, joist, batwing or
  balcony board, while they kept hitting me or nearly hitting me from the same spot (fights 8 and
  10 most clearly). I can't tell if that's fair cover I don't know how to use. It felt one-sided.
- **Drift after a run.** Two or three times, after a run ended with "arrived", I kept sliding on
  another 1.1 to 1.4 m while standing still or crouching.
- **A run stands you up.** I was crouched, ran somewhere, and was standing when I got there.
  That may be on purpose, but it isn't said.
- The blacksmith calls "You there! A word, mister. Over here." at the start of every fight, from
  far outside the saloon.

## What was fun

- Fight 5: the whole three minutes. The flank calls, a man stepping up to the window next to me,
  dropping Brody in the doorway, the Kid trying to reach him, climbing to the gallery.
- Their talk. The warning ladder before a fight ("Something I can do for you?", "Keep that iron
  where it is.", "One more move..."), the calls in the fight, the hurt lines ("He's got me
  pinned!", "Lord, get me out of this one.").
- Shooting Lyle's hat off: "Close. Real damn close."
- Wounds that matter: a broken arm takes your gun, a lung shot shows ("short of breath, bubbling
  cough"), and pressing on the wounds slowed "blood pumping out bright" to "bleeding steady".

## What was flat

- Most fights were over in 10 to 25 seconds after the first shot, always with me down. Six of
  ten ended within about 25 s of their draw.
- I never felt I had an answer. Shooting first, waiting, crouching, going outside, going upstairs
  and backing off all ended the same way.
- No one ever gave up or ran, so every fight ends one way.

## Reload, walk and Drop it!

- **Reload mid-fight: worked.** `press reload 3` adds about a round a second (3 to 5, 0 to 3,
  1 to 5 in 4 s). It never went above 5. Afterwards the hammer is at half cock and the next shot
  fires normally. With a broken gun arm, or while the gun is put away after pressing on wounds,
  reload does nothing and says nothing. Reloading in the open got me killed (fight 9), which
  felt fair.
- **Walk by name: worked** (`spec_walk_w`, `spec_walk_e`, `spec_landing`, `spec_door`,
  `spec_hall`, `spec_tables`, `spec_stair_foot`, `spec_stair_head`, `spec_gallery_back_w`,
  `spec_kitchen_east`, `spec_back_room_hall`; up the stair fine). **Walk by coordinates: worked**
  (five times, arriving within about 0.5 m). Knocked out mid-walk, it said
  `arrived: false, knocked_out: true`, which is clear. Odd: the 1 m drift after some runs, and a
  run stands you up from a crouch.
- **Drop it!: got answers, never a surrender.** Four tries:
  - Brody, four wounds, behind a post (not in my sights): first nothing; then closer, "Lord, get
    me out of this one." and "He's got me pinned!" (shaken). He went back inside and kept
    fighting.
  - Lyle, two wounds (belly and chest), in my sights: "You'll have to kill me!", and he shot me.
  - Lyle, unhurt, before any shot: it started the fight ("Your funeral, friend."). That seemed
    right.

  I expected the four-wound Brody to give up or at least drop to the floor. He didn't.

## The top three things to fix

1. **The fight can't be won, and the cover feels one-sided.** All ten fights lost, half within
   about 20 seconds; chest hits from 15 m a second or two after they see you; my aimed shots
   stopped by posts, studs and batwings while theirs got through to me. Even a slow player needs
   a way to win some fights.
2. **The Kid stuck "rescuing" Brody** for nearly two minutes on the gallery above him, saying
   "Hold on, I got you!" again and again without getting down to him.
3. **Losing your gun with no word.** A broken gun arm puts the gun away for good, and draw,
   shoot and reload do nothing silently. Tell the player. Along with it: a head shot reads
   "Dead (brain)" and then you come round alive, and the gang talks to a downed man as if he'd
   backed down.
