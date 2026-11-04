# Playtest: ten gunfights in the new saloon, build "D+", fourth round (2026-11-04)

A blind playtest through the dev bridge, with the game run headless. Every fight was
`gf_play SETUP seed=N fixes=all+pain_fight+floor_fight+odds+flinch`, in a fresh game each time.
I did not read the code or earlier reports.

**Result: won 1, lost 9, other 0.** One of the losses was a duel I called and lost (fight 9).
I also played one extra test fight to check hip and aimed shots from a crouch. It is not in the
tally.

**The machine was busy.** For the first 5 to 10 seconds of every fight the game ran at 1 to 2
frames a second, then 50 to 145. In those opening seconds a "look" and the shot after it were
often 1 to 4 seconds of game time apart. That matters, because most fights were decided in the
opening seconds.

## The ten fights

1. **Hall, seed 1.** I waited (the slow start meant they drew before I did). I stood in the
   hall, was hit in the arm, and wasted five shots on Lyle as he went up to the gallery. I backed
   out to the west end of the porch to reload. Brody shot through the front window and I took glass
   in the thigh and forearm and a ball in the chest. I blacked out at about 60 s. Nobody else hit.
   **Lost.**
2. **Hall, seed 2.** I shot first, sights up, at Lyle at 5 m with all of him clear. Both shots
   missed as he went for cover. Then I was hit in the hip ("Your hip's broken", which dropped me to
   a crouch), the shin and the gut inside 3 seconds. Out cold at 18 s. **Lost.**
3. **Stair, seed 1.** I ran out to the east end of the porch and crouched. Through a broken window
   I shot the Kid in the chest. Brody, then Lyle, tried to drag him clear. A shot I aimed at Lyle hit
   the Kid again, and he later died ("suffocation"). I hit Brody through the wall. Lyle flanked round
   to the front door and I put a ball in his chest there. He fell off the porch and lay "fighting",
   but never fired again. Brody went calm and walked out to the front steps, then fought on when I
   shot at him. I missed him five times at 5 to 7 m. Out cold at about 184 s (hip, then chest).
   **Lost**, after the longest fight of the ten.
4. **Stair, seed 2.** I shot first from the hip and hit Lyle at 7 m. My second shot went into a
   table. Then the Kid hit me in the neck and Brody in the hip. Out cold at about 13 s. **Lost.**
5. **Gallery, seed 1.** I backed out to the street and was gut-shot on the way. They lost me
   ("Where'd he go?"). From the street, through the windows, I hit Brody in the right forearm and
   he gave up. I hit the Kid in the chest and he ran. Lyle fought on alone from the balcony, with
   only his head showing over the rail. Five head shots: one took his hat off. I blacked out at
   about 140 s with no new hit (a holed lung and the gut). **Lost.**
6. **Gallery, seed 2.** I shot first, sights up. Brody was hit in the chest, fell and gave up, and
   the unhurt Kid gave up at the same instant. Lyle hid in the rooms over the bar. I climbed the
   stair, crouched at the top and fired twice through the boards. Both shots hit him (chest and
   both forearms). Brody died of blood loss. Lyle said "Easy... easy... I'm going" and then
   dropped out cold. **Won**, unhurt, about 96 s.
7. **Back, seed 1.** I crouched, drew and cocked. Brody was 2.7 m away. The slow start put 4 s
   between my look and my shot, which missed. Then I took five hits in 8 seconds (arm, hand with two
   fingers gone, a lung, the gut, the hip). Out cold at 20 s. **Lost.**
8. **Back, seed 2.** I walked into the back room, crouched and aimed at the door. Lyle, 12 m away
   on the other side of walls, hit me in the hip and the forearm: "Your forearm's broken... You
   can't hold the gun: a broken forearm." After that I could not draw, fire or reload. I tended the
   wound. They kept shooting at me, though I couldn't hold a gun, and I was out at 43 s.
   **Lost.**
9. **Front, seed 1.** With my gun holstered I called the Kid out ("You! Step out here and face
   me!"). He said "Alright. Right here, then. Whenever you're ready." The other two stayed calm. About
   5 s later he said "I see him!", drew, and shot me in the head. **Lost** (the duel), 11 s.
10. **Front, seed 2.** I shot first, sights up, at Lyle (only his belly and hips clear) and hit a
    window. I crouched in the street. I was hit in the hand (four fingers gone), the thigh, the chest
    and the gut. Out cold at about 15 s. **Lost.**

*Extra test (hall, seed 1, not counted):* I crouched at the bar end. The left forearm was broken
("Your forearm's broken") and I could still shoot. A shot to the jaw then put me out at 15 s.

## Did they fight?

Yes, hard. They shot back at once, called out to each other ("Covering!", "Cover me, I'll get round
him!", "He's loading! Get him!"), and pressed me when I reloaded. Lyle went up the stair in fight
1 and round through the front door in fight 3. Two men went to drag the wounded Kid in fight 3. They
lost me when I left the building and searched for me ("Where'd he go?", "Come on out!", "I know
you're there.").

They also shot through walls and windows very well. In fight 8, Lyle hit me twice from 12 m through
the back room's walls. In fights 1, 3 and 5 Brody hit me through the front windows from behind
the bar.

Nobody folded early except the Kid in fight 6 (below).

## Who quit, and was it earned?

- **Fight 5, Brody** gave up after a ball in his right forearm (his gun arm). Earned. Lyle called
  him a yellow dog for it, which was great.
- **Fight 5, the Kid** ran after a ball in the chest, and was later seen tending himself. Earned.
- **Fight 6, Brody** gave up after a chest hit that knocked him down. Earned.
- **Fight 6, the Kid** gave up **unhurt**, at the very instant Brody fell, with Lyle unhurt and still
  fighting. Not earned. Lyle shouted "Kid! Pick up that gun!", which was right.
- **Fight 6, Lyle** said "I'm going" after two chest hits, with one friend dead and the other
  surrendered. Earned.
- **Fight 3, Brody** went calm and walked out onto the front steps after the Kid died and Lyle
  fell. When I shot at him he said "That's how it is? Fine!" and fought on. I couldn't tell whether
  he was leaving or hunting me.

## What broke

- **One broken forearm stops the gun, another doesn't, and the screen doesn't say which.** Fight 8:
  "Your forearm's broken... You can't hold the gun: a broken forearm." In the extra test the screen
  said exactly the same "Your forearm's broken" and I could still shoot. The player can't tell which
  arm went, so can't tell why.
- **The hit line and the screen named different wounds.** Fight 8: the hit line said only
  "pelvis", but the screen said "forearm and the pelvis". The forearm was the one that mattered.
- **A broken bone I was never told about.** In fight 1 my status said "bone broken", but no message
  ever named a broken bone (I was told "Hit in the upper arm" and "A lung's holed").
- **Blacking out with no warning.** In fight 5 I went out cold with no new hit and nothing on
  screen first. The status line said "short of breath, bubbling cough", and I had 4.4 of 5 litres of
  blood. In fights 1 and 2 I went out within a second or two of a gut or chest hit.
- **`look` contradicted itself, and the shot.** In fight 3 the same framing post was "stops a ball:
  10 cm of it" in one look and "a ball goes through its 8 cm" in the next. A shot I aimed at Lyle
  went through that post and hit the Kid in the chest. Another look said "a ball goes through its
  0 cm".
- **`look` said "Hitbox at 5.8 m"** as what was in the way (fight 8): an internal word, not a thing
  in the room.
- **`look` came back blank.** In fight 5, at Brody, it gave nothing clear, nothing in the way and no
  barrel line. That says nothing to the player.
- **Clear shots missed.** In fights 2 and 3 I fired seven aimed shots at men 5 to 7 m away whom
  `look` showed fully clear a moment before. All seven missed. Each time the men were moving, and the
  shot left about a second after the look. With the hammer cocked first the gap was shorter, but I
  still missed. Hip and aimed shots from a crouch gave the same `look` answers every time I compared
  them (fights 3, 6 and the extra test). Two aimed shots through thin boards from the stair head
  (fight 6) both hit.
- **The look right after `hold aim` still said "from the hip".** The sights take a moment to come
  up. That's fine, but the answer looks wrong if you don't know it.
- **Disarmed but still shot.** In fight 8 I couldn't hold a gun, it was put away, and I was tending
  a wound. All three kept shooting, and nobody told me to give up.
- **The result said "fled" for a man lying out cold.** In fight 6 the result listed Lyle as "fled".
  He had said "I'm going", then went down out cold on the gallery and stayed there.
- **Small things.** After I tended a wound the gun was put away "hammer cocked". While I was out
  cold, `look` still turned me and reported clear lines. The first `press cock` while out cold gave
  no reason, and the next one did.
- **Messages that worked well.** "It's empty: reload" came up as the last round left. `press
  reload` with the gun put away said "your gun's put away". A held fire with a broken forearm said
  "you can't hold the gun: a broken forearm". Glass wounds were named ("Glass cut your thigh, and a
  shard's still in it").
- **No one was hurt by their own shot or by glass** as far as I saw. Friends' shots came close:
  "Hey! Mind where you're aiming!" came up in four fights. In fight 3, Lyle fired and the Kid was hit
  in the foot in the same tick, which looks like Lyle hit him.

## What they said that didn't fit

- **"Over there!", "There he is!", "I see him!"** came from men I was standing in front of, in the
  open at 5 m, who had been talking to me a second before ("Help you?", "Put it down, or I put you
  down."). The same happened in the duel: the Kid said "I see him!" while facing me in the street.
- **A whole fight in one breath (fight 6, all at 7.2 s):** "That's how it is? Fine!", "Your funeral,
  friend.", "Brody's down!", "I'm hit! I'm hit!", "Go on, I got you!", "Enough! We're done. Drop
  'em.", "Enough! It's yours!", "Kid! Pick up that gun!". The Kid said both "Go on, I got you!" and
  "Enough! It's yours!" in the same instant.
- **An opening line in the middle of a fight.** In fight 3, two minutes in, with the Kid dead,
  Brody answered my shot with "That's how it is? Fine!"
- **Asking for cover from nobody.** In fight 5, after Brody had surrendered and the Kid had run,
  Lyle said "Cover me, I'll get round him!" and "I'm empty! Cover me!".
- **"...Gone."** In fight 6 Lyle said "...Gone." when nobody had died or left: both his friends were
  alive and had surrendered in the open. (In fight 3 Brody said it 16 s after the Kid died, which
  fitted.)
- **"Walk on, mister."** Lyle said it to me while I lay out cold (the extra test).

## Moving

`walk` to places and to points worked every time, including up the stair. Crouch worked. A hip
hit put me in a crouch by itself. The first `walk ... run` of a fight covered only about 1 m a
second of game time, but that was during the slow start, so it may be the machine.

The men moved well. Lyle went up to the gallery, came round through the front door, and took to the
balcony. Brody came out to the steps. Two men dragged the wounded Kid. Lyle backed away when beaten.

## What was fun

- Shooting Lyle through the gallery boards from the top of the stair, and hearing "Son of a—!".
- Brody giving up with his gun arm hit, and Lyle calling him a yellow dog.
- Men dragging a hurt friend under fire, then losing me and searching ("Come on out!", "I know
  you're there.").
- Calling a man out to a duel. He answered properly and the others stood back.
- Lyle's "Still here, mister!" and then "Easy... easy... I'm going."

## What was flat

- The first seconds decided almost every fight. Six of the ten ended with me out cold within 11 to
  20 seconds, often hit three or four times in two seconds by all three men at once.
- Being shot accurately through walls from rooms away (fight 8), with no way to tell where it came
  from.
- Missing men who were clear in `look`, because they had moved by the time the shot left.
- A disarmed, wounded man being shot at like an armed one.
- Fight 3's tail end: Lyle lay "fighting" off the porch for a long time and did nothing.

## The top three things to fix

1. **The opening is over before the player can act.** In six of ten fights I was out cold within
   11 to 20 seconds, hit several times in a second or two by all three men, sometimes through walls
   or windows I didn't know they could see through. The one win came after a lucky first shot made
   two men give up at once.
2. **Wound messages don't tell you the wound that matters.** "Your forearm's broken" doesn't say
   which arm, yet one stops the gun and the other doesn't. The hit line can name one part while the
   screen names two. My status said "bone broken" when no message had named a broken bone. I
   blacked out with no warning on screen.
3. **`look` and where the balls go don't always agree.** The same post was "stops a ball" in one
   look and "a ball goes through" in the next, and my ball went through it and hit the wrong man.
   One answer said "Hitbox". One came back blank. Men shown fully clear were missed seven times in a
   row at 5 to 7 m, because they had moved by the time the shot left.
