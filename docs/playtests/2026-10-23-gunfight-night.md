# Playtest: ten gunfights in the new saloon (2026-10-23, night)

Played headless through the dev bridge, without reading the code. Each fight was a fresh game:
`gf_play <setup> seed=1|2`, then the ordinary commands. Times are game seconds from when the
shooting started.

A caveat on fairness: every bridge command lets 1–5 s of game time pass, and a `shoot 2` often took
3–9 s (once 15 s). A player at the keys would be quicker than I was. Even so, the gap between me
and the gang was large.

## The ten fights

1. **Hall, seed 1.** I was slow, so they drew first at 6 s. Brody shot from behind a bar post;
   Lyle and the Kid fell back to about 12 m. I hit Lyle twice (shin, pelvis). He said "He got me!"
   and kept fighting. I crouched and reloaded. They called "He's empty! Get him!" and covered each
   other. I was hit in the head (jaw smashed), the thigh and then the chest, and blacked out.
   **About 56 s.** Nobody quit.
2. **Hall, seed 2.** I drew early and Lyle warned me ("Don't you do it"). I crouched and waited.
   At 6 s they all went for cover at 8–12 m. My two shots at Lyle missed. Brody hit me in the belly
   and the upper arm, and I blacked out. **About 11 s.**
3. **Stair, seed 1.** I shot first at Lyle and hit him once. The Kid, on the stair landing, hit me
   four times in five seconds (arm, chest, head). **Dead at about 6 s.**
4. **Stair, seed 2.** I ran to the front door before it started, crouched and turned. The Kid on
   the stair hit me three times (pelvis, thigh, arm) while my three shots missed. **Down at about
   12 s.**
5. **Gallery, seed 1.** I shot first, with aim, at Lyle and the Kid up on the gallery. All three
   shots missed. I tried to run out the front door, but the walk got nowhere: I was hit twice in the
   right upper arm and blacked out. **About 9 s.**
6. **Gallery, seed 2.** I crouched behind the barrels by the tables. One aimed shot killed Brody.
   Lyle: "Oh God, Brody... You'll pay for that!" The Kid: "I can't get my head up!", then a second
   later "That all you got?" Lyle hit me in the chest. My gun showed as put away and wouldn't come
   out again. Then a pelvis hit and I blacked out. **About 12 s.**
7. **Back, seed 1.** Brody started 2.7 m behind me. My first shot dropped him (out cold; he bled
   to death later). The Kid went to drag him ("Hold on, I got you!"), and Lyle covered and then
   flanked ("Keep him busy, I'm going round!"). Lyle hit me twice in the chest. **Down at about
   10 s.**
8. **Back, seed 2.** I ran out the front door before it started (10 m in 2 s) and crouched outside
   beside it. Then about a minute of stalemate. Brody and the Kid stood "searching" in the same
   spots. Lyle stood at the back of the bar and kept firing through the front at me: eight or more
   shots, with a pelvis hit and a gut hit. I hit Lyle in the belly through the batwing door ("Oh
   God, not the belly..."). Brody called that he'd drag him but never moved him. Then the saloon
   caught fire (105 timbers burning; nothing in the log said what lit it). The Kid: "Out! Get
   out!" Brody: "Place is going up!" Brody and the Kid walked out past me, calm, and left Lyle.
   **Ended "broke off" at about 100 s.** This was the longest fight and the best one.
9. **Front, seed 1.** I started in the street behind a barrel, crouched, and waited. At 6 s they
   all pulled back into the saloon. The Kid hit me in the chest while listed as "hidden". My two
   shots at Brody on the balcony hit the balcony's ledger. A forearm hit, my blood ran down, and I
   blacked out. **About 17 s.**
10. **Front, seed 2.** I shot first at the Kid in the doorway. He was hit once and went to
    "surrendered" while still holding his gun, without saying a word. Lyle and Brody hit me three
    times (arm, belly, chest) and I blacked out. Afterwards the Kid said "My leg... damn you...",
    went down and bled to death within about 7 s. **About 5 s.**

**Tally:** I went down in 9 of 10 fights. The tenth ended when the gang left the burning saloon.
I killed Brody twice, wounded Lyle twice, and the Kid gave up once. I never beat all three.

## Did they fight?

Yes, hard. Nobody folded early. They shot back from the first second, found cover (the bar, the
stair, the back rooms, inside the saloon when I was in the street) and peeked out to shoot. They
called out "Reloading! Cover me!", "He's empty! Get him!" and "I'm going round!", covered each
other, flanked and tried to drag the wounded. The words are good, and they matched what the men
did.

They did not **come at me**. When I backed out of the door (fight 8), they stayed where they were
for a minute and kept shooting through the wall rather than pushing or searching.

Their shooting is very strong. They hit me at 8–14 m within 1–3 s of the start, roughly every
second or third shot. They hit me through walls and doors, and while listed as "hidden". The man on
the stair or the gallery is especially deadly. I landed about 7 hits from roughly 30 shots.

## Who quit, and was it earned?

- **The Kid (fight 10)** surrendered after one leg wound, in the first seconds, with both friends
  unhurt. It was half earned: the wound turned out to be fatal. But he kept his gun and said
  nothing, so I couldn't tell he'd given up. Read side by side, "surrendered" while "armed" looks
  like a mistake.
- **Brody and the Kid (fight 8)** broke off when the saloon caught fire. That was earned and it
  felt right. But they walked out calmly, close past the man they'd been shooting at, and left the
  gut-shot Lyle behind after calling that they'd drag him.
- **Nobody quit from losing.** Lyle took two hits in fight 1 and fought on, which was fine. In
  fight 6 the Kid was shaken when Brody died and got over it within a second.

## What broke

- **My gun went away after a hit.** After a chest hit in fight 6, my revolver showed "put away"
  and `weapon revolver` failed. It looked the same after every blackout.
- **Reloads that click.** After `press reload 3` with some rounds already in the gun, the next
  `shoot 2` clicked twice and fired nothing, even though it showed 3–4 loaded. This happened in
  fights 1 and 8.
- **One hit ends the fight.** A single upper-arm hit blacked me out (fight 2). Two arm hits gave
  "can't feel his legs" (fight 5), and so did an arm and a belly hit (fight 10). Blood went from
  5000 to about 3800 in a few seconds from a chest and a forearm hit.
- **"you_dead", then "you came round".** In fight 3 gf_result said dead, but the log said I came
  round.
- **I wake up somewhere else.** After every blackout I "came round" at the same spot by the
  doctor's, about 45 m away. The gang then greeted me like a stranger: "Something I can do for
  you?", "Help you?", "Easy, friend."
- **Stale results.** After the end, gf_result still listed Brody as "down" when he was dead, and
  the Kid as "surrendered" when he was dead.
- **The log doubles hits.** Every hit on me is also logged as a near miss from the same shot.
- **The fire had no cause in the log.** The saloon was alight in fight 8 with nothing logged
  before it except a broken mirror.
- **Friendly fire calls.** Two or three times a fight, a man said "Hey! That was me!" when a
  friend's shot passed near him. It's funny, but it's frequent.
- **"I know you're there."** All three said it at once, over and over, when they couldn't see me.

## What was fun

- The callouts. Reading the log felt like a real fight: "He's empty! Get him!", "Oh God,
  Brody...", "Oh God, not the belly...", "Place is going up!"
- Fight 8: the long stalemate, a shot through the batwing, the fire, and the gang clearing out.
  It was the one fight with a story.
- Dropping Brody with one good shot and hearing the others react.

## What was flat

- Most fights were over in 5–17 s, before anything could develop. The gang barely needs tactics,
  because their aim settles it.
- When I wasn't in sight, they stood still and shot at where I'd been. Nobody came looking.
- Waking at the doctor's to a friendly hello from the men who'd just shot me.

## The top three things to fix

1. **The gang's aim is too good, too soon, and goes through cover.** They hit at 8–14 m within
   1–3 s, about every second shot, through walls and while hidden. Fights last 5–20 s, and I lost
   9 of 10.
2. **One or two hits finish the player, and the gun goes away.** An arm hit blacks you out, arm
   hits numb the legs, the revolver ends up put away and won't draw again, and after a reload the
   first pulls click.
3. **Giving up and pressing need work.** The Kid surrendered silently, still armed, after one hit.
   The shaken state lasts a second. A "drag" never moves the man. Nobody pushes or searches when
   the player breaks contact; they freeze and fire through the wall for a minute. After it's over,
   they treat you like a stranger.
