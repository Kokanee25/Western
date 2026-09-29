## Salt Creek — M2: bodies

There's a man at the range now. Under his clothes is a hidden anatomy (bones, arteries, organs,
fingers three bones each) and a body that bleeds, goes into shock, feels pain late because of the
adrenaline, and loses his nerve. No hit points. Shoot at him and he shoots back, and you have the
same body.

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
| Texel size (40 → 24 → 16 per metre) | F7 | |
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
   is rendered at 640×360 and scaled up with hard pixels. That's the default look. You can switch it
   on the fly; each key flashes the current settings at the bottom of the screen, and they're saved:
   - **F2** render resolution (640×360 → 480×270 → 320×180 → 960×540 → 1280×720),
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
