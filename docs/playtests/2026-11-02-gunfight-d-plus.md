# Playtest: ten gunfights in the new saloon, build "D+" (2026-11-02)

Blind playtest through the dev bridge, headless. Every fight was
`gf_play SETUP seed=N fixes=all+pain_fight+floor_fight+odds+flinch`, one fight a game.
Plus two extra careful fights at the end, to see more of their cover.

A note on me as a player: each round of commands takes me 1 to 5 seconds of game time.
I am a slow player. In fight 1 their six seconds ran out before my first command.

## The ten fights

1. **spec_hall, seed 1** (stood, then crouched in the open by the door). They drew first. Brody
   went behind the bar, then called "Keep him busy, I'm going round!" and came round to 5 m.
   Lyle covered and reloaded. The Kid peeked from the back. I fired seven rounds and hit nobody.
   Hit in the arm, then the pelvis. I blacked out at once. About 45 s. They were untouched.
2. **spec_hall, seed 2** (careful: I tried for the back of the bar's south end). My walk stopped
   on a post after 3.6 m. I was hit in the head and chest while running. Brody was already behind
   the bar, and he called a flank. I fired once and blacked out. About 13 s.
3. **spec_stair, seed 1** (shot first). Two shots, at Brody and at Lyle. Both missed. Lyle came
   straight at me, to 3 m. The Kid on the stair hit me in the chest, then the head. I was down
   7 s after my first shot.
4. **spec_stair, seed 2** (careful: out the front door, crouched on the porch beside it). The
   Kid on the stair shot me four times through the open doorway from 12 m (twice in the belly,
   once in the shin). I never fired. Down at 17 s.
5. **spec_gallery, seed 1** (shot first, stood, then crouched in mid-hall). My third shot dropped
   Lyle on the gallery. He fought on from the floor. The Kid went to drag him. Then Brody and Lyle
   got stuck "reloading" for about 80 s. They never fired, and they shouted "Reloading! Cover me!"
   dozens of times a second. Brody stood at the bar front, in the open, for the whole two minutes.
   I walked up and shot him. With five wounds he said "Enough! We're done. Drop 'em." and gave up.
   The Kid searched upstairs, then walked out the front door ("...Gone."). I won. About 185 s.
6. **spec_gallery, seed 2** (careful: crouched by the tables, but I found nothing solid there).
   Brody went behind the bar the moment I fired. About 8 s later he left it to flank, to 5 m.
   Lyle and the Kid peeked and shot from the gallery. One chest hit gave me "going pale with no
   wound to show for it", and I blacked out 19 s later. About 26 s.
7. **spec_back, seed 1** (shot first). I hit Brody in the chest at 3 m. He stepped into the back
   hall and kept shooting. Lyle, behind the bar, hit me in the neck. Brody hit me twice more.
   Down at 18 s, about 10 s of fighting.
8. **spec_back, seed 2** (careful: crouched behind a framing post at the back tables). The post
   screened me from Lyle at the bar. I hit Brody twice. He hid, then called a flank and came out
   saying "He's empty! Get him!" just after I had reloaded. Three more hits and he was out cold
   (dead later). Lyle came round the front of the hall and reloaded in the open. One hit and he
   went down. The Kid said "I'm gone!" and fled to the outside balcony. Then Lyle stood on the
   porch steps "reloading" for about 80 s. He never fired, didn't answer "Drop it!", and spammed
   the log. When hit again he shouted "You'll have to kill me!" / "Come on, then!" about 40 times
   in half a second, then gave up. I won. About 135 s.
9. **spec_front, seed 1** (shot first from the street, then backed off). Three shots at the Kid,
   Lyle and Brody. All missed. They ducked inside. I ran 7 m west to reload. The Kid and Brody hit
   my arm and pelvis. I blacked out. About 14 s.
10. **spec_front, seed 2** (careful: I tried to run round the saloon's west corner). Brody on the
    balcony shot me in the chest. Then my nose was shot off and I was gut-shot, all while I ran.
    I was knocked out before I reached the corner. I never fired. About 11 s after they drew.

**Extra A, spec_back, seed 1** (careful, the same post as fight 8). I hit Brody in the belly. He
hid and tended himself. This time Lyle had a line past my post. Chest hit, down at 16 s.

**Extra B, spec_hall, seed 1** (careful: out the door, caught on the porch, crouched). All three
took cover inside straight away (bar, back-room door). Brody hit me through the front window.
After about 15 s, Brody and the Kid moved up to the back gallery and called flanks, but stayed
hidden. Then they lost me ("Where'd he go?", "Come on out!"). Lyle, in the back-room door 16 m
off, gut-shot me. Down at 50 s, about 42 s of fighting.

Score: two wins (5 and 8), eight times down. In my eight losses I hit two men, once each.

## Did they fight?

Yes, hard. Nobody folded early. They shot back at once and took cover within a second or two.
They called to each other ("Go on, I got you!", "Keep him busy, I'm going round!", "He's empty!
Get him!"). One flanked while the others covered. They dragged wounded friends, and a man on the
floor kept shooting. They hit me through open doorways and windows from 12 to 16 m. Against a
slow player they are deadly. In most losses I was down 10 to 20 s after the draw.

## Who quit, and was it earned?

- Brody gave up in fight 5 after five wounds, with Lyle down. Earned.
- The Kid walked out in fight 5 with Lyle down and Brody given up. Earned.
- The Kid fled in fight 8 the moment Lyle fell (Brody was already out cold). Earned, though
  he only got as far as the outside balcony and sat there.
- Lyle gave up in fight 8 after four wounds, alone. Earned.
- Nobody quit too early. Nobody quit at all in the fights I lost.

## What broke

- **Stuck "reloading".** In fights 5 and 8, men stood "reloading" for over a minute and never
  fired. They flooded the log with "Reloading! Cover me!" / "I'm empty! Cover me!", up to 50 lines
  in a few seconds. Fight 5 had Brody and Lyle (and later the Kid) stuck like this. In fight 8 it
  was Lyle on the porch steps. The frame rate reading dropped to 5–22 fps while it went on.
- **Shout spam.** In fight 8, Lyle said "You'll have to kill me!" / "Come on, then! Come on!" /
  "Not like this. Not to you." about 40 times in half a second.
- **The gun clicks after a reload.** Every time I reloaded three rounds (`press reload 3`), the
  next three `shoot`s only clicked, though it said "3 loaded". The fourth fired. This happened
  every time, in fights 5 and 8. After any reload the hammer reads "half cock".
- **`walk X Z` stops on furniture and posts**, often after 0 m (fights 2, 5, 8, Extra B).
  Walking to a named place (`walk spec_hall`, `walk spec_door`) worked.
- "Drop it!" (`press shout`) did nothing to the stuck men, at 2 m and at 8 m.
- Small mismatches: at the end of fight 8, `read all` called the Kid "surrendered" while
  `gf_result` said "fled". In fight 5, Brody showed as "surrendered" while out cold.
- In fight 5 Brody never moved from the bar front in two minutes, and he stayed "open" (no cover).
- Several of my shots with a man named in the sights hit the door frame or the bar instead.

## What was fun

- The talk. "They got Lyle!", "Hey! That was me!" when a friend's shot went close, "He's empty!
  Get him!", the Kid's "Lord, get me out of this one." and "I'm gone!".
- Brody's flank in fight 8: he waited, then came out the moment he thought I was empty.
- Wounds: "going pale with no wound to show for it", "blood in his throat, rattling breath".
- Brody's surrender, and the Kid quietly walking out of the saloon.
- Being lost: "Where'd he go?" and "Come on out!" when I hid on the porch.

## What was flat

- Most fights ended with me out cold in 10–20 s, often from the first or second hit (a pelvis
  hit blacked me out at once, twice). There was little time to use cover.
- Getting to cover was the hard part. In fights 2, 4 and 10 I was hit while moving there.
  Doorways and windows gave no protection from 12–16 m.
- The two long fights were long only because the men got stuck, not because the fight was good.

## Their cover

- **They take it fast.** Within a second or two of the first shot, Brody is behind the bar
  (fights 1, 2, 6, Extra B), and Lyle and the Kid are at the back-room door or the gallery rail.
- **They fight from it.** They mostly peek and shoot from where they stopped. They didn't leave it
  at once. Each held it for about 8 to 15 s.
- **Then one leaves on purpose.** After that, one man (usually Brody) calls a flank and comes
  round while the others cover: fights 1, 2, 6 and 8. It looked deliberate, not like a man
  wandering off.
- **When I was crouched behind my own cover** (the post in fight 8, the porch in Extra B), they
  stayed in theirs longer. They peeked and fired, said "Come on out!" and "Where'd he go?", and
  moved up to the gallery. They didn't rush me. In fight 8 Brody left cover only when he believed
  I was empty.
- **Wounded men** went into cover and stayed there, tending (Brody in Extra A and fight 8).
- **The exception:** in fight 5 Brody never took cover at all. He stood at the bar front for two
  minutes (while stuck "reloading").

## Top three things to fix

1. **Men stuck "reloading" for a minute or more**, never firing, flooding the log with callouts
   (and the frame rate dropping with it). The same goes for the 40-in-half-a-second shouting. It
   turned both of my wins into a turkey shoot.
2. **The three clicks after every reload.** The gun says "3 loaded", but it clicks three times
   before it fires. In a fight that is deadly, and it reads as a bug.
3. **Too little time to reach or use cover.** One or two hits blacked me out within seconds,
   often while I ran to cover. They hit through doorways and windows from 12–16 m. A careful
   player in the saloon still lost five of six careful fights. (Also: `walk` stopping on chairs
   and posts made moving to cover harder.)
