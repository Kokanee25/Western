# Brief: tools for faster review

Sean (2026-10-04), after reading how another Claude-built engine is run: a live control panel,
Claude driving the running game, a camera tour he can watch on his phone, a playtest agent, a
frame budget. Sean reviews in short sessions between shifts, from his phone or a cloud PC; these
tools let him direct the look himself and see each build without sitting down to play it.

Goal: Sean tunes the look with sliders and pastes the result; every build has a video he can
watch on his phone; sessions can drive the running game to test and render; new gameplay is
played by an agent before it reaches him.

## Gameplay session (owns controls, debug tools, CI). After the performance pass; one merge each, in this order

1. **Live look panel** (in game, for Sean)
   - A key (one that's free; controller: a free button combo) opens an overlay with sliders for
     every look setting, grouped: Sun & sky, Night & moon, Lamps, Fog & haze, Glow, Grade (exposure,
     contrast, saturation), Ground, People's paint, Squares (`min_square_px`, texel density). The art
     session supplies the list and the ranges (its item 1 below).
   - Changes apply live. "Save preset" writes `user://looks/<name>.json`; "Export" copies it to the
     clipboard as text so Sean can paste it into chat; "Load", "Reset to default".
   - A time-of-day slider, to tune golden hour and night without waiting.
   - `--look=FILE` (or `tools/apply_look.gd`) applies a preset in headless renders, so a session can
     render exactly what Sean tuned and bake it into the defaults.

2. **Dev bridge** (so Claude sessions can drive the running game)
   - A small command interface, off in release builds (`--dev-bridge` flag): a local TCP or HTTP
     server, or a commands file read each frame. Commands: screenshot (path, size), camera
     goto/look (position, target, fov), set time, set look value, apply preset, spawn a person or
     the gang, start a fight, place dynamite, ignite a member, wait N seconds, read values (fps,
     frame times, counts), quit.
   - `tools/bridge.py` client, plus a script format (one command per line) so a session can run a
     sequence under xvfb in the workspace and collect the screenshots.
   - Documented in CLAUDE.md (Commands) with an example. Use it in the perf benchmark if useful.

3. **Camera tour video** (Sean watches each build on his phone)
   - A fixed tour, about 30 s, smooth path, no input: the street at golden hour, west past the
     store, turn to the saloon, in, the card table, the bar, back out at night under the lamps.
   - Rendered with `--write-movie` (or frames + ffmpeg) to MP4, 1280×720, 30 fps.
   - A GitHub Actions workflow (manual, plus every push to main if it fits in about 20 minutes on a
     CPU runner) that publishes it next to the web build on Pages (`/tour/latest.mp4`,
     `/tour/<build>.mp4`) with a simple page for his phone. Software rendering is slow: lower
     settings for the tour are fine; say what they are.

4. **Playtest agent**
   - `tools/playtest.md` (its instructions) and a script that runs the game under xvfb with the
     dev bridge and lets a fresh sub-agent that has NOT read the code play: walk the street, go into
     the saloon, provoke someone, draw, fight the gang, use dynamite, set a fire, try to talk a man
     down (when that exists).
   - It reports in plain English: what broke, what was flat or confusing, what was fun, with
     screenshots, saved to `docs/playtests/<date>.md`. Run it before handing Sean a build with new
     gameplay (CLAUDE.md rule).

5. **Frame budget**
   - Fill in the budget table in CLAUDE.md from the performance benchmark (what each system costs,
     what it may cost). The benchmark reports against it; CI warns, then fails, when a system goes
     over.

## Art session. Start with its next merge

1. **The panel's settings:** give the gameplay session the list of every setting that matters for
   the look (current value, sensible range, one line on what it does). When Sean sends a preset,
   render with it, judge it, and bake his values into the defaults.
   **Done 2026-10-04:** `docs/briefs/look_settings.md` (nine groups, where each lives, how to set
   it). The art session keeps it current when a default moves.
2. **Blind critic** after every art merge (CLAUDE.md rule): a fresh sub-agent with only the two
   paintings and the new renders (and the tour's frames once they exist) lists the five biggest
   differences a viewer would notice, with crops; saved as `critic.md` in the judge round, its top
   three in the status entry. Use it with judge v2 to choose what's next.
   **Done 2026-10-05:** `tools/critic.py`; first round `docs/screenshots/judge/2026-10-05_r1/critic/`.
3. **Golden images** for every fixed view (CLAUDE.md rule), with the gameplay session wiring the
   check into CI.
4. **A brief per big job** in `docs/briefs/` (CLAUDE.md rule).

## Done when

- Sean can open the panel on the cloud PC, drag sliders, export a preset and paste it, and the art
  session bakes it in.
- After each build, `/tour/latest.mp4` plays on his phone.
- A session can render any view through the bridge without editing code.
- A playtest report comes with each gameplay build.
- The budget table is filled in and checked.

## Not now

- Letting players plug their own AI into the game (a security risk; maybe never).
