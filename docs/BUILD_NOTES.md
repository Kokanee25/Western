## Salt Creek — M0: the test street

The project skeleton: the pixel look, a first-person body, one false-front store built plank by
plank, and a 45-minute day.

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
| Move | WASD | Left stick |
| Look | Mouse | Right stick |
| Run | Hold Shift | Click left stick (runs until you stop) |
| Crouch | Hold Ctrl, or C to toggle | B or click right stick (toggle) |
| Jump | Space | A |
| Speed up time (1× → 30× → 180×) | T | Y |
| Debug readout (clock, speed, fps) | F3 | View / Back |
| Change pixel size | F2 | |
| Jump to next place (street, store, saloon door, inside saloon) | F5 | D-pad up |
| Controls help | F1 | |
| Free the mouse | Esc (click to grab it again) | |

On a phone: left thumb moves, right thumb looks, buttons bottom-right.

### What to try

1. **The look.** You start at 17:00 on the street, sun low in the west. Everything is rendered at
   640×360 and scaled up with hard pixels. Press **F2** to cycle 480×270, 320×180, 960×540 and
   1280×720 and pick what feels right.
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

- Does the pixel size and the lighting feel like the concept art? Too sharp, too soft, too dark?
- Walk / run speed, mouse and stick feel, head bob: too much, too little?
- Anything broken, stuck or ugly.
