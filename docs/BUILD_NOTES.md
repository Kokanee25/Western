## Salt Creek — M1: the revolver

A single-action Colt in your hand, built in code, firing real bullets that go through boards and
leave holes you can see daylight through. On top of the M0 test street: the pixel look, a
first-person body, member-built store and saloon, and a 45-minute day.

### Download

- **Windows:** `SaltCreek-windows.zip` → unzip → run `SaltCreek.exe`. SmartScreen may warn about
  an unknown publisher: *More info → Run anyway*.
- **Mac:** `SaltCreek-macos.zip` → unzip → right-click `Salt Creek.app` → *Open* → *Open*. (It's
  not notarised yet, so a plain double-click is refused the first time.)
- **Linux:** `SaltCreek-linux.tar.gz` → extract → run `./SaltCreek.x86_64`.
- **Phone / browser:** the web build is on the project's GitHub Pages site. It uses the simpler web
  renderer, so no volumetric light shafts, softer lighting overall. It's for quick looks; judge the
  look on PC.

### Controls

| | Keyboard + mouse | Controller |
|---|---|---|
| **Cock the hammer** | Q or mouse wheel down | RB |
| **Fire** (squeeze the trigger) | Left mouse | RT |
| **Aim down the sights** | Right mouse (hold) | LT |
| **Reload** (open gate, work round the cylinder) | R — hold to keep going, press again to close | X |
| **Holster / draw** | H | LB |
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

**The revolver (new in M1)**

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

- Does the gun feel good? Cock/fire rhythm, recoil, sound, smoke — too much, too little?
- Is cocking on a separate button right, or should there be an "auto-cock" option?
- Can you see the bullet holes well enough?
- Does the pixel size and the lighting feel like the concept art? Too sharp, too soft, too dark?
- Walk / run speed, mouse and stick feel, head bob: too much, too little?
- Anything broken, stuck or ugly.
