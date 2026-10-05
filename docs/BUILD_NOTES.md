## Salt Creek — M2: bodies

There's a man at the range now. Under his clothes is a hidden anatomy (bones, arteries, organs,
fingers three bones each) and a body that bleeds, goes into shock, feels pain late because of the
adrenaline, and loses his nerve. No hit points. Shoot at him and he shoots back, and you have the
same body.


### Fixed: walls now really break in your build

- **The Windows build had been missing the part that carves walls** since the destruction work
  (it shipped beside the game but was left out of the zip), so a shotgun into a wall only drew
  holes. It's in now, and the build checks it's there before it's released.
- **Try:** press **2** for the shotgun and fire into the general store's front from close up: the
  boards should tear open in ragged holes you can see through, with chips flying. Press **F3**:
  the line "native plugin" should show a version, not "not loaded".

### New: the Kid has his own body

- **A first test, getting closer: the gang's Kid is the man from your picture**, built by
  Tripo from it, fitted to our skeleton, his head painted in the pixel style. His hat is its own
  piece, so it can be shot off. Brody and Lyle are still the old bodies; they come next, one
  picture each.
- **Try:** press **U** to bring the gang in and look at the Kid at the bar, then **H** to draw
  and put your gun on him until he puts his hands up (his nerve is low), and shoot his hat off.
  From the side, with his hands up, his shirt has a flat patch under each arm where it was joined
  to his arm in the model: tell me if it catches your eye.

### New: F12 saves a bug report

- **When something goes wrong, press F12** (controller: hold Back, press Y). It saves one file
  with a screenshot, the last stretch of play as a recording I can replay exactly, the log, the
  build and where you were. The message on screen says where it went (on Windows,
  `%APPDATA%\Godot\app_userdata\Salt Creek\bug_reports\`). Send me the file. Setting fire to
  what you look at is **L** only now.

### New: a tour of every build on your phone

- **https://kokanee25.github.io/Western/tour/** plays a 30-second camera tour of the latest
  build: down the street at golden hour, into the saloon, the card table and the bar as night
  falls, and out into the street under the moon. The builds before it are listed under it. It's
  rendered on GitHub's machines without a graphics card, so it's a little softer than the game on
  your PC (rendered at 854x480, no haze in the air or soft corner shading). Each tour turns up
  about 20 minutes after the build.

### New: the look panel (N)

- **Press N** (controller: hold **Back** and press **Start**) and a panel of sliders opens on the
  left: every setting that changes how the game looks, in groups (Sun & sky, Night & moon, Lamps,
  Fog & haze, Glow, Grade, Ground, People's paint, Squares), with **Time of day** at the top. The
  mouse is free while it's open; changes show at once as you drag. Hover over a slider for a line
  on what it does. Greyed rows aren't in this scene.
- **When you like it, press Export**: the look is copied to the clipboard as text. Paste it into
  the chat and the art session renders the two painting shots with exactly those numbers and bakes
  them into the defaults. **Save** keeps it on your PC under the name in the box (Load brings a
  saved one back); **Reset** puts everything back as the game started. N or Esc closes it.
- **Try:** the saloon at night (F5 to jump there, the slider to 23:40) and the street at golden
  hour (17:36). Start with Grade and Lamps.
- **Fixed: the shotgun's second barrel.** After the right barrel fired, Q cocked the spent right
  hammer again, so the trigger only clicked and you had to cock twice to fire the left barrel. Q now
  cocks the hammer over the loaded barrel.

### A playtester played it first

- Before this build reached you, an agent that hadn't seen the code played it for about 70
  minutes and wrote up what it found: `docs/playtests/2026-10-04.md` (with screenshots). The short
  of it: the look and the gang's talk and teamwork are the best of it; fights are over in a second
  or two and blacking out heals you completely; Brody and Lyle can get stuck in the saloon's door
  frame; townsfolk don't run from fire. **Tell me which of its top three to fix first.**

### The native plugin: step 1 of the destruction plan

- **A native plugin is in the build** (`addons/saltcreek_native`, Rust, built for Windows, Mac and
  Linux by CI). It does nothing in play yet: it's the foundation for voxel destruction and for
  moving the heavy simulation off the one core (docs/DESTRUCTION_BRIEF.md). **Press F3** and look
  for the line `native plugin: saltcreek_native 0.1.0, N threads`. If it says `not loaded`, tell
  me which build and which platform. N is how many threads the plugin can use on Shadow.
- Also send the F3 frame split (the `ms a frame` line and the fps) standing in the street with
  the gang in (U), so the next steps are measured against your machine.

### Destruction step 2: a wall that takes a shotgun

- **Walls are carved now, not painted.** Every board, stud and post is cut into small cubes (about
  1.6 cm) the first time something hits it, and shots really cut it: buckshot punches a cluster of
  ragged holes with pale torn wood round each, a charge with the muzzle against the boards blows a
  bite about 7 cm across, split along the grain, and the pellets carry on through to whatever's
  behind (the storekeeper, if he's behind his counter). You can see daylight through the holes from
  inside, bullets go through the gaps, chips of fresh wood fly and lie where they land. A stud shot
  through enough is weaker, and if what's left can't carry the wall it gives way, as before.
- **Try it on Shadow:** stand in the street outside the general store (DRY GOODS), press **F3**
  and note the fps and the `frame` line. Press **2** for the shotgun, **H** to draw it, walk to
  the store's front wall and fire both barrels at the siding from 3–4 m (LMB, LMB, **R** to
  reload), then again from a step away, then with the muzzle right on the boards. Go inside and
  look back at the wall. Keep going for a dozen charges, then send me **the F3 photo while
  firing and after**: the fps, the `frame` line and the `ms a frame` line (look for `ballistics`
  and `voxels`). That decides whether Godot carries this (docs/DESTRUCTION_BRIEF.md, step 2's
  gate).
- **Tell me:** do the holes read? Too small, too big, too clean? (Pictures of the same three
  charges at three cube sizes, and the old painted holes, are in `docs/destruction/step2/`.) Any
  hitch when the shot lands?
- **You can shoot a man's hat off.** Aim just over his head: the hat flies off and lands, he
  ducks and says something about it, and he's frightened (and angry). A townsman gets down.
- **No more hitch when someone's first hit.** The first time anyone's chest or belly was opened by
  a wound the game froze for a tenth of a second (painting the insides on the spot); now it's
  painted while the town loads.
- Known: a carved board that snaps in two falls as two plain halves (the holes aren't kept on
  the pieces); dynamite doesn't carve yet (step 3); the web build keeps the old painted holes.

### New look: the painting's mosaic on the whole frame

- **The frame is in blocks now, like the concept painting**: 3–4 pixels on a man across a table,
  2 far off, each one colour, the light in steps. Silhouettes go stepped, as the painting's are.
  It's a setting (**mosaic**, on; **O** turns it off and on, F3 lists it) and the old "finish"
  softening is off under it. Build 340 drew a black screen with it on a real GPU (its pass was
  drawn before the frame existed); fixed in this build. If anything's ever black, press O.
  Not on the web build (that renderer has no depth to size the blocks by).
- **A second look to try: "quantise once" (I).** Nothing is cut into squares before the mosaic:
  the paintings go on the walls smooth, the man's paint is smooth, and only the screen mosaic
  makes the blocks (averaged, soft-edged, 4 px under a roof and 6 px in the open). The scene
  reloads when you press I (a few seconds; you start at the spawn). Off by default. Compare the
  saloon at night and the street at golden hour both ways and tell me which is the painting's
  style; that decides whether it becomes the default. `docs/screenshots/quantise_once/compare.png`
  is the same comparison rendered here.
- **The man at the card table is the image-to-3D man now** (Tripo, fitted to our skeleton), with
  his head painted in the style. Walk into the saloon and look at him from the front, the side
  and three-quarters: tell me if he reads as the painting's style, and where he doesn't.

### Faster: fire (performance pass, part 1)

- **A burning town costs a third less.** Measured with the new bench (`tools/perf_bench.gd`: the
  street with everyone in, then two sticks of dynamite and three buildings alight) on the cloud
  workspace's 2.1 GHz core, simulation only: the frame after the fire took hold went from **17.4 ms
  on average (p99 307 ms) to 11.5 ms (p99 163 ms)**. The fire behaves exactly as before (checked
  member by member over a minute of burning).
- The fire was heating boards that were already alight (about 9 in 10 of the work in a burning
  building) and measuring every burning board against every person, every tick. Also fixed: a script
  error printed for every board that burnt away near someone.
- **The hitch while a building burns is mostly gone.** The fire's work used to land on one frame
  four times a second (worst frames 300–500 ms here); it's now spread over the frames in between,
  and each burning building checks its loads on a frame of its own. Worst frames here: **p99 163 →
  73 ms, max 390 → 100 ms**. What's left of them is a building working out its loads (next).
- **A burning building works out its loads half again as fast** (same answers, checked member by
  member). Worst frames here: **p99 73 → 53 ms, max 100 → 70 ms**; average 11.6 → 10.8 ms.
- **People take a quarter of the draw calls they did.** Each person's skin and clothes were drawn a
  body part at a time (about 55 pieces each); now each garment is one piece until he's opened up
  or loses a limb. He looks exactly the same (checked pixel by pixel). The calm street went from
  **8,186 draw calls to 6,129**.
- **The street's props and furniture are drawn together** (the saloon's chairs, tables, bottles,
  the barrels, crates, horses...: 1,767 parts in 180 batches). They look exactly the same (checked
  pixel by pixel on the Windows renderer); the computer has 2,400 fewer things to sort and shadow
  each frame. Draw calls in the calm street, Windows renderer: **4,047 → 3,695**, objects in frame
  **7,810 → 5,413**. (The web build is left as it was: its renderer lights batches differently.)
- **The flicker is fixed.** Whole sections of the screen (the inside of a building, the saloon's
  mirror, the street's walls) were flipping between two brightnesses every frame. The sky was
  being re-lit 60 times a second as the clock ran, and everything lit by the sky (most of the
  town, and the parts of every interior near its walls and roof) flickered with it. Now the sky
  is re-lit only when the sun or its colours have visibly moved on. Measured here with the clock
  running and the camera still: the store's interior **11.5% → 0.003%** of pixels changing a frame,
  the saloon at night **0.28% → 0.001%**, the golden-hour street **43% → 0.1%**.
- **Please try:** walk into the store and the saloon (day and night), look at the walls, the
  ceiling and the mirrors behind the bar, and stand in the street. Tell me if anything still
  flickers while you stand still, and separately what happens while you turn and walk (some
  shimmer of thin things while moving is the pixel look; the new screen mosaic adds a little).
- **A whole town on fire no longer freezes.** Left to spread, the fire takes every building
  within a minute (2,600 boards alight). Before: **29 ms a frame on average, freezes of up to 1.6
  seconds** when a big building came down (its loads worked out again for every beam that broke,
  all in one frame). Now: **17.7 ms average, worst 68 ms** (this machine, simulation only). A big
  collapse now unfolds over a second or so instead of stopping the game.
- **Less flicker in a big fire.** Only 40 boards show flames at a time; which 40 used to be
  reshuffled every half second, so flames popped on and off all over town. Now a board keeps its
  flames while it burns, and new ones go to the fires nearest you. The fire's lights stay with
  their own fires instead of jumping across town when one burns out.
- **Standing up is cheap again.** Every person asked "can my legs hold me?" every tick by searching
  all 115 structures of their anatomy for leg muscles; now each body knows its muscles. Calm
  street **5.4 → 3.8 ms** a frame here (the people's bodies 2.0 → 1.2 ms, your own 0.7 → 0.2),
  burning **7.8 → 6.8 ms**. Nothing plays differently.
- **F3 now shows where each frame goes**, so you can tell me what your PC is doing:
  `frame 16.7 ms: process …, physics …, render cpu …, gpu …` (scripts, physics, the renderer's
  CPU and GPU time), `draws … objects … tris … nodes … bodies awake …`, and `ms a frame:` the
  game's systems that cost most (people_body = the people's bodies and pain, senses, outlaw_brain,
  fire, player...). **Please try:** start the build, press **U** (the gang rides in), stand where
  you start looking down the street, press **F3**, wait five seconds and send me a photo of the
  readout. Then throw a stick of dynamite at the store (3, Q, release), press **L** on a wall to
  set it alight, wait till it's going well, and send the readout again.
- Try: F5 to the street, **F3**, throw a stick at the store (3, Q, release) and set it going with
  **L** on a wall. Tell me the fps before you light it and while it burns.

### New: full sim: the real loads, and air that behaves like air

- **The guns fire what they'd have fired in 1882.** The Colt (a 7½" Cavalry model) shoots the
  .45 service load, 40 grains of black powder behind a 255-grain bullet: about 900 ft/s, so the
  ball now leaves at **274 m/s** (it was 240) and hits a quarter harder. The coach gun's black-powder
  shell throws nine 00 balls at about **1,200 ft/s** (365 m/s; it was 400).
- **Drag changes with speed, as it really does.** A round ball's drag nearly doubles as it nears
  the speed of sound, so buckshot (just over it) sheds speed fast: two thirds of its punch is left
  at 25 m. The revolver's bullet follows the standard drag curve for its blunt shape and keeps
  about nine tenths of its speed over 100 m.
- **The air is a setting**: height and temperature set how thick it is and the speed of sound. It's
  sea level and 15 °C until we decide where Salt Creek is (a mile up on a hot day the balls carry
  flatter).
- What it means: the revolver's flatter now. Against your sights it's on at 25 yards, **7 cm low
  at 50 m, 24 cm at 75 m, half a metre at 100 m**, and a ball reaches 100 m in 0.39 s. A .45 in the
  chest is more likely to put a man down at once, and that includes you. Buckshot at 20 m drops a
  man a little less often than before.

### New: real bullet drop, and targets at 50 and 100 metres

- **Every ball falls and slows from the moment it leaves the barrel** (it always did; now the gun
  is set up the way a real one is). The revolver's sights are regulated for **25 yards**: the ball
  rises a hair above your line of sight, crosses it at 25 yards, and falls away beyond (figures
  above, with the real load). At 100 m it takes the best part of half a second to get there (lead
  them if they're moving).
- The revolver's bullet now slows like the blunt conical bullet it is (it keeps about nine tenths of
  its speed over 100 m); buckshot pellets, round and light, shed speed much faster. The shotgun's
  bead is regulated for 40 yards.
- **The outlaws know their guns**: at range they hold over by how far they judge you to be, and
  they misjudge it a little.
- **Two new boards down the range**, past the first: one at 50 m (left) and one at 100 m (right),
  so you can see it and learn your holdover.
- Try: F5 to the range. Shoot the near board, then the 50 m board with the sights on the black
  square and see where the holes land, then the 100 m board (hold half a metre over it).
  F8 shows each ball's flight.

### New: ricochets

- **A ball that strikes something at a shallow angle glances off it.** Lead is soft, so it skips
  off the hard-packed street and off stone at a fair angle, but only glances off wood at a graze
  (steeper, it digs in and leaves its mark). Near the limit it's a toss-up.
- It comes off flatter than it went in, a little to one side, slower, flattened and tumbling, and
  **it can still hurt someone**: a ball skipped off the street can take a man in the legs.
- **You hear it**: the spang and whine of it glancing off (sparks off stone and iron), and if it
  comes past you it **whizzes** instead of snapping.
- Try: at the range, shoot at the ground a few paces in front of the target board and watch where
  they go (F8 shows the bullet traces). Lie low in the street while the gang shoots at you and
  listen for the whiz of the ones that skip.

### New: steady hands, and being shot at

- **Your gun doesn't hold still.** It drifts, rises and falls as you breathe, and has a fine
  shake, and the shot goes where the barrel points, not where you're looking: watch the sights
  and squeeze when they're on. It's worst from the hip, settles about a second after you raise the
  sights and hold still (each shot unsettles it again), is steadier crouched, and worse while
  moving. The shotgun, shouldered, is steadier than the revolver held out.
- **Run and you're winded**: after a few seconds of running the sights heave with your breathing
  for a good while.
- **Being shot at gets to you.** A ball past your ear (or into the post by your head) makes you
  flinch: the view jolts, the gun jerks off line and a shot fired that instant goes wide, for about
  a second. Keep taking fire and you're **rattled**: the gun won't keep still until it's been quiet
  a few seconds. That's what the gang's covering fire is for now.
- **You hear them go by**: every ball that comes close **snaps** past, from the side it went by
  (a ricochet whizzes).
- **F3** shows your hands: flinch, rattled, winded, and how far the gun is off line.
- Try: at the range (F5), aim at the target board from 20 m and fire as the sights settle, then
  run up and down the street for ten seconds and try again. Then press **U**, start a fight with
  the gang and try to shoot back while their rounds come in. Tell me if it's too hard, too easy,
  or too much camera jolt (all the numbers are in `config/player_tuning.tres`).

### New: the gang fights together

- **They shout to each other**, and you hear it (subtitles): "There he is!" when they spot you
  or you've moved (the others then know where you are, even if they can't see you), "Reloading!
  Cover me!", "I'm hit!", "Brody's down!". It works only within shouting distance (less through a
  wall): a man out of earshot doesn't know his friend's empty. Listen for "Reloading!": it's your
  moment, but his friends know it too.
- **Covering fire.** When one of them reloads, is hit, goes round on you or goes to help a friend,
  the others come up from cover and keep you busy ("Go! I got him!"), firing where you were even
  if they can't see you. Expect rounds into whatever you're hiding behind.
- **One keeps you busy while another goes round.** After a while behind cover, one calls "Keep
  him busy, I'm going round!" and runs for a spot at a new angle on you while the rest shoot. Only
  one goes round at a time.
- **They get a friend out.** A man whose legs are gone shouts for help, and the nearest friend
  runs to him, takes him by the collar and drags him, walking backwards, behind the nearest thing
  that hides a man lying down. They'll do it for a friend who's out cold, too. While he's dragging
  he can't shoot.
- **When one goes down, it goes through the rest.** Seeing a friend shot down, quit or killed
  frightens them (more if it's Brody, who leads). Lyle, the hothead, goes into a rage ("You'll pay
  for that!") and comes out from cover straight at you for a few seconds; the Kid's nerve is
  likely to go. Once half of them are out of it, the rest know it's going badly.
- **"Fall back!"** A man who runs shouts it, and anyone who's had enough goes with him (it takes
  less when Brody says it). **Brody giving up** ("That's it, boys. Throw 'em down.") makes the
  shaky ones give up with him; Lyle may curse a friend who quits.
- **Friends aren't enemies by accident.** A friend's stray round gets "Watch where you're
  shooting!", not a gunfight, and they won't fire through a friend standing in the way.
- Try: press **U** to bring the gang in and let them reach the bar. Then, from the saloon door,
  shoot one of them in the leg (aim low) and get behind something. Listen to them, watch who
  comes to drag him away, and count the shots while one reloads. Then try: shoot the Kid first and
  watch Lyle; hit Brody hard and keep firing until he runs or gives up, and see who goes with him.
  Tell me if the shouting is too much or too little, and whether the dragging reads.

### New: tiles on everything (P)

- **The painting's "pixels" are tiles on the surfaces**, not on the screen: each a fixed real size,
  big up close and tiny far away, and each lit as one flat colour. Everything now works that way:
  the buildings, boardwalks, blockouts and ground, the props, and the people (every texel of their
  clothes and face). Sunlight, lamplight, shadows and fog are worked out once per tile, so shadow
  edges step tile by tile instead of cutting smoothly across them. One key does all of it: **P**
  switches tiles square (the default) / ragged (uneven edges, like dabs of paint) / off (smooth
  light). It's saved, like F2/F6/F7, and F3 shows it.
- **Full resolution:** press **F2** until the corner says **native**: the game renders at your
  screen's size, so the tiles are the only pixels, like the painting. 1280×720 is the default.
- **His hat fits his head** and his face is at the painting's tile size, about 20 tiles across.
- Try: stand by the hitching rail in front of the store around 17:00 (T speeds time up), look down
  at the rail's shadow on the street and press P to compare; then press F7 until it says 16 per
  metre and look at the awning's shadow on the store front. Then F5 to the range and look at the
  outlaw up close, pressing P. Tell me which tiles you like (square or ragged) and the frame rate
  (F3) at 1280×720 and at native.

### New: the painting's pixel style

- **The game now draws at 1280×720 by default** (it was 640×360), and every texture is in squares
  of a set size on the surface (64 a metre on wood, finer on faces and hands), each a slightly
  different shade, like the concept painting's mosaic. Squares stay crisp, and near things have big
  squares and far things small ones. If it runs slowly, **F2** steps down to 960×540 or 640×360.
  Your old saved settings move to the new look once; F2 and F7 still change it after that.
- Try: walk into the saloon at night and look at the tables and walls up close, then press F2
  and F7 to compare with the old look. Tell me the frame rate (F3) at 1280×720 on your PC.
- **The painted man's face is cleaner**: his eyes (with whites), brows and moustache now sit where
  his head has them, his eyes are drawn finer than the squares round them, and his face is lit
  evenly, as the painting lights it. Try: go to the range (F5) and look the outlaw in the face up
  close, by day and by lamplight.
- **His shirt front is the painting's**: a narrow V of shirt under the vest, the collar turned down
  either side of the knot, and the tie hanging straight down into the vest (it used to splay like
  a bow). No goatee any more.
- **The men are built like the painting's man**: broader, in a fuller coat, freshly painted for
  it. Try: press F5 until you're at the outlaw on the range and walk round him; press U to bring
  the gang in and look at them at the bar. (The painting's seated man, with his mug, is only in the
  comparison pictures for now.)

### New: real people, and the painting's shot

- **The men have real bodies now.** Their skin and head come from MakeHuman's base human (free to
  use, CC0), built by a script in Blender and fitted to the game's skeleton, so they have
  cheekbones, brows, a jaw, collarbones and knees instead of the mannequin. Wounds, holes you can
  see into, severed limbs, the ragdoll and the X-ray (F10) all work on them as before.
- **Real clothes**: a shirt with a collar, a vest open at the neck, a string tie, and (on men who
  wear one) a heavy coat with lapels whose skirt was draped by a cloth simulation, each with its
  folds and shadows baked into a small pixel texture. The face is shaded by its own shape now.
- **The painting's shot is in the saloon**: the back card table at night, a man sat at it on his
  forearms with a tin cup, the lamp between you. It's for judging the look against the concept
  painting; for now it's a screenshot view (`shot_match_saloon`), not a place you can sit.
- Try: shoot the outlaw at the range and look at the wounds and the X-ray (F10) on his new body.

### New: a day in town

- **The store and the saloon have people now.** The storekeeper stands behind his counter, the
  barkeep behind his bar. Neither has a gun.
- **About 45 seconds in, three riders come in from the west** (press **U** to bring them now):
  **Brody**, a cool hand who leads; **Lyle**, a hothead; and **the Kid**, green and jumpy. They walk
  into the saloon and drink. They aren't your enemies. They don't know you.
- **Then they start trouble on their own.** Lyle and the Kid walk over to the store and lean on
  the storekeeper: taunts, a shove, and then Lyle draws on him ("Open the drawer. Slow."). The
  storekeeper's hands go up and he begs. If you do nothing, they finish, go back for another drink,
  and ride out west. (The whole day takes about four minutes.)
- **If you step in, it's the ladder** from before: draw near them and they get wary; point your
  gun and they draw and cover you. What happens next depends on the man:
  - **The Kid backs down** if you hold your gun on him ("Alright. Alright. It ain't worth it."):
    he holsters, drops the robbery and goes back to the bar.
  - **Lyle** is likelier to shoot first. His friends join in if you shoot one of them.
  - **Shout "Drop it!" (G)** with your gun on a man instead and he gives up.
- **A proud man doesn't forget.** Faced down, Lyle (or Brody) drinks on it for a minute, then comes
  out into the street and **calls you out** ("You! Step out into the street!"). Come out where he
  can see you and it's a **duel**: he stands square with his hand by his holster, and he draws
  after a few seconds, or the moment you go for yours. He won't run for cover: it's a stand-up
  fight. Don't come out and he calls you a coward in front of the whole town and leaves.
- **You can call a man out yourself**: face an armed man with your gun **holstered** and press
  **G** ("You! Step out here and face me!"). A hothead or a man with a grudge accepts; a cooler one
  says "Not today."
- **The storekeeper remembers who helped.** Run them off and, once it's quiet, he thanks you.
  Gunfire nearby and the townsfolk cower with their arms over their heads.
- Try: let the day play out once without doing anything. Then stop the hold-up by holding your
  gun on the Kid. Then face Lyle down and wait for him to call you out. Then call Lyle out yourself
  at the bar (gun holstered, G).

### Nobody's your enemy until someone makes it so

- **You start with your gun holstered.** Press **H** to draw it. Walking about with a gun in your
  hand is something people notice.
- **The outlaw minds his own business.** Walk up to him with your gun away and he'll look at you,
  and that's all.
- **He has eyes and ears.** He sees where he's facing, not behind him, not through walls, less far
  at night, and a man crouched and still takes him longer to pick out. He hears gunshots from
  across town, running feet close by (not creeping), shouts and talk, all muffled through walls.
  He remembers where he last saw you.
- **A ladder, not a switch.** Draw near him and he gets **wary**: squares up, hand by his holster
  ("Easy, friend."). Keep at it and he **warns** you ("Keep that iron where it is."). Point your gun
  at him and he **draws and covers you**, but doesn't fire. **Holster** and he steps back down, and
  in the end puts his own gun away. Keep it on him long enough and he'll shoot first.
- **He can only react to what he sees.** A gun at his back that he doesn't know about is nothing to
  him. A shot, though, he hears, and he knows roughly where it came from.
- **Tempers differ.** A hothead minds you standing too close or staring him out; a cool hand
  doesn't. (The test outlaw is middling.)
- **Fights are between particular people.** If someone else shoots at him, he fights *them*, not
  you. Shoot him and it's you, and he doesn't forget it.
- **Lose him and he looks for you:** where he last saw you, then a look round ("Where'd he go?").
  In the end he gives it up, and stays wary of you.
- Try: walk up to him with your gun away; draw it pointed off to the side; point it at him and then
  holster; point it at him and wait; circle behind him with it drawn; shoot, then hide behind the
  store and wait.

### New: the outlaw fights like a man who wants to live

- **Cover.** Shoot at him (or near him) and he runs for something solid: the new woodpile,
  barrels, stacked crates and stretch of fence round his corner of the range, or the trough and
  the boardwalk's edge in the street. He picks somewhere close that hides him from you and that
  he can shoot back from. He'll go round a thing to get behind it.
- **Head down.** Behind low cover he crouches or ducks; behind something really low he lies
  flat. Rounds cracking past keep his head down longer. He won't shoot back while you're keeping
  him pinned.
- **Up and shooting.** Every so often he rises over it (or leans out past a wall), fires a shot
  or two and ducks back. He reloads behind it. Now and then he moves to a new spot for a fresh
  angle on you, and if you walk round his cover he'll find another.
- **Breaking.** When his nerve goes and his legs are good, and you're not right on top of him,
  he may **run for it** instead of giving up. He keeps his gun. Once he's far enough off he stops
  to see to his wounds. Walk up on him and he'll give up.
- **Tending himself.** Hurt and bleeding, with nobody shooting at him for a few seconds, he
  presses on the wound, then cinches a belt round a pumping arm or leg, just like you can.
- **Legs gone.** A broken leg no longer turns him into a rag doll: he goes down on his belly,
  still conscious, and fights on from the ground, crawling.
- **Limping.** A torn thigh muscle and he limps, slower.
- Knees and elbows on the rag doll now only bend the right way.
- It's all posed in code for now (a stiff, puppet-like walk and crouch) until real motion capture
  replaces it; the behaviour stays.
- Try: from the range line, shoot near him and watch where he goes. Keep firing over his cover.
  Circle round it. Hit him in the thigh and stop shooting for a bit. Scare him badly from 15 m.

### New: dynamite

Six sticks in your coat. A stick of 40% dynamite with a five-second fuse.

- **3** takes a stick out (wheel up / Y cycles revolver → shotgun → dynamite).
- **Q** strikes a match and lights the fuse (it hisses and spits; you can see it burn down).
- **Hold left click and let go** to throw: the longer you wind up, the further it goes. **Right
  click** sets it down just in front of you (up against a wall, say).
- **Don't hold it lit too long.** It goes off in your hand.
- What it does, by the physics of a blast (pressure and kick falling off with distance):
  - Against a wall it blows the boards in and throws them, with splinters flying like shot. The
    heavy framing mostly stands. Windows crack much further out (about 10 m).
  - Now and then it sets dry wood alight.
  - People: at a few metres, ringing ears; at a couple of metres, burst eardrums; within a metre,
    thrown down, lungs torn, knocked senseless; right at a man's feet or hand, it takes the foot or
    the hand at the joint, and the stump bleeds hard. A wall between you and it takes most of it.
  - You: the world goes muffled under a high whine for a while after a close one (for good, muffled,
    if an eardrum went).
  - A bullet through a stick lying on the ground sets it off about one time in four. One blast sets
    off another stick lying close by.
- **Fixed after the first try** ("it doesn't destroy the buildings or hurt the bad guy"): a
  stick lying on a board counted as if it were half a metre off it, and a thrown stick rolled
  away like a pencil. Now the blast is reckoned over each board's whole face (so what's right
  under it takes the most), boards break right where they're hit, the stick skids to a stop,
  and on the ground it throws gravel and grit that wound anyone within a few metres. A stick is
  also a bit stronger (0.2 kg of TNT, not 0.15) and knocks a man down from further off. Thrown at
  the store it now breaks about a dozen pieces where it lands; on the floor it blows through the
  boards; a metre and a half from the outlaw it knocks him flat and puts gravel in him.
- Try: set one at the store's wall and stand back; throw one at the outlaw from across the range;
  set one down, walk off and shoot it.

### New: the shotgun

A double-barrelled coach gun (12-bore, 20" barrels, two hammers, brass shells of 00 buckshot).
Every shell is nine pellets, and each pellet is flown on its own: across a room they spread into a
hand's width of separate small wounds; at arm's length they arrive as one mass with the wad and the
blast behind them and tear one big hole: ribs smashed and thrown out, lung or heart showing.

- **2** takes out the shotgun (the revolver goes back in the holster), **1** the revolver; **mouse
  wheel up** or **Y** on a controller swaps. (Time speed is **T** only now; Y was it before.)
- **Q** thumbs back a hammer (right barrel first, then the left); **left click** fires the next
  cocked barrel. Cock both and you can fire twice quickly.
- **R** breaks it open, pulls the empties (they fly over your shoulder), thumbs in fresh shells.
  Hold R to do it all; press R again or Q to close it. You carry 12 shells.
- **Right click** shoulders it: look along the rib, bead on the target.
- Try him from across the street, from a few steps, and with the barrels almost on him. **F4**
  reduced gore still closes it up.
- He's more frightened looking down a shotgun when you shout "Drop it!" (G).
- **Tuned after the first try:** it was felling men in one shot across the street. The pattern is
  wider now (well over a metre at 25 m, so only 3–5 pellets find a man at 20 m), pellets slow in the
  air (so do bullets, a little), and each pellet counts for a share of the knockdown and fright. At
  20 m a charge put him down 14 times in 16 before, about 5 in 16 now. Up close is unchanged.
- **Monitor blanking:** the loudest, deepest moments (the shotgun, timber coming down) were
  hitting full volume with bass too deep for any small speaker, which can make a monitor's
  built-in speakers drop out and take the screen with them. The game's sound now goes through a
  limiter and a deep-bass cut.
### New: the outlaw has a real body

He's no longer sausages and a box head. One continuous skin that bends at the joints, a proper
head with a painted pixel face (eyes, brows, nose, walrus moustache, stubble, hair), and clothes
over it: shirt, open vest, trousers tucked into boots, a cartridge belt with a holster, a
bandana and a creased hat. Everything underneath (hitboxes, wounds, ragdoll, X-ray) works as before,
and the skin follows him when he falls.

- Walk right up to him and look at his face, then back off to 10 m and see how he reads.
- Shoot him down and watch the body fold with the ragdoll.
- F10 (X-ray) still shows the anatomy through the new skin.

### Fixed: reloading pushed you around; the gun went through walls

- **Reloading no longer shoves you sideways or back.** The spent cases dropped out of the gate
  were spawning inside your own body and pushing you out of the way (almost half a metre over a
  full reload). Brass, glass shards, tin cans and dropped guns are now "debris": they land on the
  ground and each other and bullets still hit them, but you walk through them.
- **Walk up to a wall with the gun out**: it now pulls back to your chest, muzzle up, instead of
  poking through. Back off and it comes up again. If you fire while tucked, the shot hits the wall
  in front of you (before, the bullet could start on the far side of the wall and fly on).

### New: buildings that stand or fall (M3, first part)

Every board, stud, joist, rafter and beam now has weight and strength (by wood and size), and the
game works out how the building's weight comes down through it to the ground. Take away what holds
something up and it breaks or falls: overloaded members snap where they're weakest, anything
left hanging falls, pieces still nailed together fall together and break up when they land, and
falling timber breaks what it lands on. The rubble stays.

- **K** (or F11 on the desktop build) breaks the member you're looking at (think axe or charge; dynamite comes later).
- Try a **porch post** on the store: the awning can't hang off one post, so it comes down onto
  the boardwalk. The store stands.
- Try a **stud** in a wall: nothing happens. A wall shrugs off one stud.
- Bullets make holes that weaken timber, but a revolver won't shoot a building down. Big timbers
  laugh at it; a thin plank carrying weight will give after enough holes.
- The shooting range's backstop timbers, the boardwalk, the hitching rail all obey the same rules.

### New: bad wounds show what's inside

People have insides now: a flesh wall, ribs, spine, lungs, heart, liver, gut, skull and brain,
built from the same anatomy the bullets travel through. A bad wound tears the skin and clothes open
and you see into it; a single revolver hit at range barely opens, hits close together add up, and
a shot with the muzzle right on him opens him up. The openings stay.

- **J** tears a big wound open in whoever you're looking at (a stand-in for point-blank buckshot and
  dynamite, which come next).
- **F4** is the **reduced gore** setting (saved): bad wounds stay closed and show as a dark soaked
  patch instead.

### New: grazes, glass cuts, and being hit by something heavy

- **Grazes:** a ball that only skims him (the outside of an arm or leg) leaves a bloody furrow,
  not a hole. It stings and bleeds a little, and the ball flies on. Try the edge of his sleeve.
- **Glass:** shoot a window with someone near it (or yourself close to it) and the flying shards
  cut: a few shallow slices, mostly face and hands, sometimes with a shard left in the wound.
- **Falling timber hurts.** Break a porch post (K) with the outlaw or yourself under the awning:
  bruises, broken bones, a knock on the head that puts you out for a while, and a blow to the belly
  can burst the spleen or liver: he goes pale and weak with no wound to see (F3 shows it).

### New: fire

Every member of every building has a temperature now. Burning timber heats what it touches and
what's near it, most of all what's above it (flames climb), and across the gap to the next building.
Thin dry boards catch in seconds, heavy timbers take a lot of heating, stone never burns (it gets
hot), and window glass cracks and falls out. Burning timber chars: it loses weight and strength as it
goes, so a burning building's own loads bring it down, the same way as breaking it. Boards burn away
to nothing; fallen timber keeps burning where it lands. Char stays on what survives.

- **L** (or F12 on the desktop build) sets fire to whatever you're looking at. In a browser F11
  and F12 belong to the browser, so use the letters.
- **Shoot a lit oil lamp**: it smashes and the burning oil lands on whatever's under it. Press **T**
  to get to night (lamps are lit 18:00–07:00), go into the store, and shoot the lamp on the counter.
  Or the porch lantern, onto the boardwalk.
- Stand in it and you get burnt: pain, and it can kill you. The outlaw doesn't like it either.
- A whole store takes about two minutes for the roof to come in. Night is the time to watch it:
  the firelight fills the street.

### Download

- **Windows:** `SaltCreek-windows.zip` → unzip → run `SaltCreek.exe`. SmartScreen may warn about
  an unknown publisher: *More info → Run anyway*.
- **Mac:** `SaltCreek-macos.zip` → unzip → right-click `Salt Creek.app` → *Open* → *Open*. (It's
  not notarised yet, so a plain double-click is refused the first time.)
- **Linux:** `SaltCreek-linux.tar.gz` → extract → run `./SaltCreek.x86_64`.
- **Phone / browser:** the web build is on the project's GitHub Pages site. It uses the simpler web
  renderer, so no volumetric light shafts, softer lighting overall, and wounds and blood don't
  show on bodies (the web renderer has no decals). It's for quick looks; judge the
  look on PC.

### Controls

| | Keyboard + mouse | Controller |
|---|---|---|
| **Cock the hammer** | Q or mouse wheel down | RB |
| **Fire** (squeeze the trigger) | Left mouse | RT |
| **Aim down the sights** | Right mouse (hold) | LT |
| **Reload** (open gate, work round the cylinder) | R — hold to keep going, press again to close | X |
| **Holster / draw** | H | LB |
| **Shout "Drop it!"** | G | D-pad left |
| **Press on your wounds** (hold; keep holding for a belt round a bleeding limb) | B | D-pad down |
| New outlaw (debug) | F9 | D-pad right |
| X-ray: see the anatomy through him (debug) | F10 | |
| Bullet paths (debug) | F8 | |
| Move | WASD | Left stick |
| Look | Mouse | Right stick |
| Run | Hold Shift | Click left stick (runs until you stop) |
| Crouch | Hold Ctrl, or C to toggle | B or click right stick (toggle) |
| Jump | Space | A |
| Speed up time (1× → 30× → 180×) | T | Y |
| Debug readout (clock, speed, fps) | F3 | View / Back |
| Change pixel size (render resolution) | F2 | |
| Pixel shading on/off (banded colour + dither) | F6 | |
| Texel size (64 → 40 → 24 → 16 per metre) | F7 | |
| Tiles: square → ragged → off (light worked out once per texel) | P | |
| Jump to next place (street, store, saloon door, inside saloon) | F5 | D-pad up |
| Controls help | F1 | |
| Free the mouse | Esc (click to grab it again) | |

On a phone: left thumb moves, right thumb looks, buttons bottom-right.

### What to try

**The outlaw (new in M2)**

1. Press **F5** until you're at **the outlaw** (east end of the street, a man in a vest and hat
   ~10 m away, facing you). **F3** shows his state and wounds, and yours.
2. He stands easy until you shoot **at** him. A ball cracking past his head counts. Then he says so,
   turns, raises his gun and fires back: five shots, then a slow reload. That's your chance.
3. **Where you hit matters**:
   - **Thigh, inside front** (femoral artery): he keeps fighting, bleeding hard, and goes grey and
     down in about three minutes. Watch the blood spread through his trousers.
   - **Thigh bone**: he drops at once, still awake.
   - **Upper arm**: the gun falls out of his hand.
   - **Belly**: he'll live for game hours (press **T** to speed time), conscious and in pain.
   - **Heart** or **head**: over quickly.
   - **His gun hand**: fingers come off and fall in the dirt. Lose the trigger finger and he shoots
     with the middle one (worse).
   A ball through his forearm carries on into whatever's behind.
4. **Nerve**: near misses, hits, pain, blood loss and losing his gun all frighten him. When fear
   passes his nerve he drops his gun and puts his hands up. Wound him, keep your gun **on** him
   and press **G** ("Drop it!") a few times, and he may quit without another shot.
5. **Your own wounds**: when he hits you the screen flashes red and you're told where. A broken leg
   puts you on the ground, crawling. A holed lung means no running. A broken gun arm takes your gun.
   Blood loss greys the edges of the screen. **Hold B** to press on the wound (gun away), and keep
   holding: a belt goes round a bleeding leg or arm. If you pass out you come round on the store
   floor. (The doctor comes in M5.)
6. **F9** brings a fresh outlaw; the old one, his gun, any fingers and the blood are cleared away.
7. **Blood**: a cut artery spurts in time with his heartbeat, harder at first, weaker as his
   pressure falls. Veins pour dark and steady; flesh wounds drip. It lands where it lands, on the
   dirt, on the wall behind him if the ball went through, and it stays. Try the **side of his
   neck**. Wounded, you leave a trail of your own.
8. **X-ray (F10)**: see through him to what's inside: bones (white), arteries (red), veins (blue),
   organs (pink), muscles (faint), nerves and spinal cord (yellow). Anything hit turns orange, and
   each ball's path is a yellow line. Shoot him, then look.
9. **More detail inside**: separate forearm and shin bones, kneecaps, shoulder blades, jaw, eyes,
   windpipe, spinal cord, the big veins, muscles and nerves. A broken vertebra hurts, but only a
   cut cord takes his legs. A windpipe shot takes his voice (and your "Drop it!" if it's yours). A ball
   through the thigh muscle makes him limp without breaking anything. The nerve in the upper arm
   takes his grip. His heart races as he bleeds, and the bleeding slows as the pressure goes.

**Gunfight tuning (latest)**: a good hit to the body now ends the fight about half the time, and
two nearly always (it used to take two or three). Heavy hits in the trunk can knock him off his
feet. Every hit staggers him so he can't fire back for a moment. Adrenaline hides less of the pain,
and when the pain gets past him he doubles over instead of shooting. Bad wounds scare him more than
grazes, and so does seeing his own blood. Liver, lung, spleen and kidney wounds bleed faster. Arm
and leg hits still leave him fighting: he's a hired gun.

**The revolver (M1)**

1. Press **F5** until you're at **the range** (east end of the street, facing a target board and a
   rail of tin cans).
2. **Squeeze the trigger first**: nothing happens. It's single action. **Cock** (Q / wheel / RB),
   watch the hammer come back and the cylinder turn, then **fire**. Black-powder smoke fills the air
   and hangs there; the shot echoes off the hills.
3. Five shots, then a *click*: it's carried with the hammer down on an empty chamber, as they did.
4. **Reload** (R / X): the gun rolls over, the gate opens, spent cases fall out — and stay on the
   ground — and fresh rounds go in one at a time. Hold R to keep going; press once more to close.
5. **Aim** (right mouse / LT) to raise the sights: tighter shots. From the hip, and moving, they
   wander.
6. **Holes:** shoot the target board, then walk up to it. Holes go right through the boards (look
   through them) and stop in the heavy timbers behind. Shoot the store's front wall, go inside, and
   look back at it — daylight through the holes. Shoot a stud and the bullet stops in it.
7. **Tin cans:** knock them off the rail. **Windows** shatter: the pane breaks into shards that fall
   and stay, and the bullet carries on into the room.
8. **Smoke:** outside it drifts off on the breeze and rises; indoors it hangs. Fire a few shots in
   the saloon at night (F5, T to night): the smoke hangs under the roof and glows in the lamplight.
   If the game stutters or slows when you shoot, press **F3** and tell me the fps before and after.
9. **F8** shows where every bullet went.
10. Rare misfires: once in a while the hammer falls and nothing happens. Cock and try the next one.

**The world (M0)**

1. **The look.** You start at 17:00 on the street, sun low in the west. Every board, beam and the
   ground now has chunky pixel-art texture (made in code), under the same modern lighting. Everything
   is rendered at 1280×720 and scaled up with hard pixels, so each texture square is several screen
   pixels, crisp, as in the concept painting. That's the default look. You can switch it on the fly;
   each key flashes the current settings at the bottom of the screen, and they're saved:
   - **F2** render resolution (1280×720 → 960×540 → 640×360 → 480×270 → 320×180 → native),
   - **F7** texel size (smaller numbers = chunkier texture pixels, no smoothing in the distance),
   - **F6** pixel shading (light and fog break into bands and dither patterns).
2. **Time.** Press **T** twice (180×) and watch a whole day go by in 15 seconds: long shadows down the
   street at sunset, a purple dusk, blue moonlight and stars, lamps coming on at 18:00 and going out
   at 7:00. Press **F3** to see the clock.
3. **Your body.** Look straight down: shirt, vest, gun belt, holster, legs and boots. Walk and run
   and watch the legs; crouch and they fold. Your shadow on the street has a hat.
4. **Movement.** Walk, run, crouch, jump.
   Walk from the road up onto the boardwalk (there's a ramp edge; real steps come later).
5. **The store.** Go in through the open door. Inside: the counter, shelves, a lamp. Look at the
   walls in daylight — there are gaps between the rough boards and sunlight comes through them.
   Everything is built from separate members (sills, joists, floor boards, studs, headers, plates,
   rafters, roof boards, siding, trim): that's what the structure system will break and burn in M3.
6. **Controller.** Plug one in and play the whole thing with it.
7. **The saloon (art test room).** Across the street from the store. Press **F5** three times to jump
   inside, then **T** until it's night. The grey and coloured boxes are placeholder props (tables,
   chairs, piano, bottles, stag head...) at their real sizes, waiting for Meshy models. Compare it with
   the saloon concept art: the lamps, the moonlit street through the door, the bar.

### Tell me

- **Does the gunfight feel good?** He's the first draft: does he shoot too well or too badly? Does
  he give up too soon or too late? Is it clear where you hit him and what it did?
- Is the blood too much, too little, too bright?
- Does the gun feel good? Cock/fire rhythm, recoil, sound, smoke — too much, too little?
- Is cocking on a separate button right, or should there be an "auto-cock" option?
- Can you see the bullet holes well enough?
- Does the pixel size and the lighting feel like the concept art? Too sharp, too soft, too dark?
- Walk / run speed, mouse and stick feel, head bob: too much, too little?
- Anything broken, stuck or ugly.
