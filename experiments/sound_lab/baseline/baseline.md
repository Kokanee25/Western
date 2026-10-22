# The sound lab's baseline (2026-10-22, main at fd7fe08)

The game's sound as it is, measured by the bench (`../README.md`), seed 1, 45 scenarios. Full table
`table.md`, every number `measures.json`, clips `clips/*.mp3` (what came out of the Master bus,
stereo, 48 kHz; the WAVs in `build/sound_lab/base/`). Nothing in the game was changed.

## Inventory: every sound

All made in code by `src/audio/synth_sounds.gd` (mono, 16-bit, 22,050 Hz, so nothing above 11 kHz;
a 45 Hz high-pass on each), played by `AudioStreamPlayer3D` nodes on the **Master bus**, the only
bus (its effects: the player's ear low-pass, a 40 Hz high-pass, a hard limiter at −1.5 dB). No
reverb, no Area3D audio, no buses per space, no occlusion, no Doppler, no `max_distance`, no voice
limit, and no delay for distance: every 3D sound is Godot's inverse-distance model (gain =
unit_size / distance, capped at max_db), with its default low-pass (5 kHz, up to −24 dB as the gain
falls under 1).

| Sound | Played by | When | unit_size / max_db / volume |
|---|---|---|---|
| `gunshot` | `RevolverViewmodel` (on the gun at your eye); `OutlawBrain._fire_at` (on his body) | a revolver goes off | 25 / +6 / 0 |
| `shotgun` | `ShotgunViewmodel` | your coach gun goes off (no one else has one) | 25 / +6 / 0 |
| `cock`, `dry_fire`, `gate`, `ratchet`, `insert`, `eject` | the revolver in hand | the hammer, a click, loading | 2 / 0 / −6 |
| `cock`, `dry_fire`, `break_open`, `close`, `insert`, `eject` | the coach gun in hand | the same | 2 / 0 / −6 |
| `match`, `fuse` | `DynamiteViewmodel`; `fuse` also `DynamiteStick` in the world | striking, the fuse burning (loops) | 2 / 0 / −6; fuse 2–3 / +3 / −8…−10 |
| `dynamite` | `BlastEffects.spawn` | a charge goes off | 40 / +6 / 0 |
| `ringing` | `PlayerWounds._update_ears` (a 2D player, not placed) | after a blast near you, with the ear low-pass on Master; **it is used** (5 m: −10.6 dB, fading over 4 s) | – |
| `crack` / `zip` | `ImpactEffects._on_near_miss`, **your** near misses only | a ball flying true / a tumbling one passes within 2.5 m | 2 / +3 / 2 − 4 × miss m |
| `ricochet` | `ImpactEffects._on_hit` | a ball glances off anything (every pellet too) | 8 / +3 / 0 |
| `flesh` | `ImpactEffects._on_hit` | a ball strikes a person | 6 / +3 / −2 |
| `glass` | `StructureMember` (a pane breaks), `OilLamp` (a lamp breaks) | | 6 / +3 / 0; lamp 5 |
| `timber_crack` | `Structure` | a member breaks (two places) | 10 / +3 / 0 |
| `timber_crash` | `Structure` | a piece of rubble lands | 10 / +3 / 0 |
| `fire` | `FireSystem` (one per fire light, loops) | timber burning | 6 / +3 / 0.3–1.6 by size |
| `steam` | `FireFX` | water on hot timber | 4 / +3 / by members |
| `splash`, `fill` | `BucketViewmodel` | throwing, filling | 2 / 0 / −6 |

**No sound at all:** a ball into wood, dirt, a prop or metal it doesn't glance off; every footstep
(yours and everyone's, boards or dirt); a body falling; a man's voice (speech is text only) and his
shouts; the gang's hammers and reloads; a hat shot off; dynamite thrown and landing; chips and
splinters; debris landing after a blast (but timber rubble); horses (the gang rides out silent);
doors; and any ambience: between shots the street is digital silence.

## What it measured

LUFS is the loudest 400 ms (BS.1770); the listener faces the source.

| | 0 m (yours) | 2 m | 7 m | 20 m | 80 m |
|---|---|---|---|---|---|
| Revolver, street | −18.0 | −18.2 | −18.4 | −22.7 | −35.4 |
| Revolver, saloon (20, 80 m out in the street) | −18.6 | −18.6 | door −18.6, wall −18.6 | −22.7 | −35.4 |
| Coach gun, street (with its pellets' ricochets) | −9.1 | −9.8 | −12.5 | −19.1 | −32.1 |
| Heard after the flash (s) | 0.02 | 0.02 | 0.02 | 0.02 (sound: 0.06) | 0.02 (sound: 0.23) |

- **Falloff:** the revolver −3.2 dB a doubling in the street (−3.0 from the saloon), the coach gun
  −4.2, dynamite −3.5 outside (−13.7 / −18.0 / −29.1 LUFS at 5 / 30 / 100 m). Spreading alone is
  −6 dB a doubling, and the air takes the highs on top. Up to 12.5 m Godot's gain is capped (+6 dB)
  and the limiter flattens the rest: 0, 2 and 7 m are the same loudness.
- **Delay:** none at any distance (every onset 0.01–0.02 s after the event: the frame).
- **Inside against out** (revolver, 2 m): decay to −20 dB 0.27 against 0.30 s, C50 −1.6 against
  −1.8 dB, the same 2.0 s tail. The saloon is not a room.
- **Walls:** at 7 m, the street / the saloon's open door / its wall: −18.4 / −18.6 / −18.6 LUFS,
  centroid 417 / 318 / 318 Hz. Nothing between you and a gun changes it.
- **Passes** (a .45 ball at 274 m/s from 30 m): `crack` at 0.3 m and at 1.0 m is the same level
  (peak −15.2 dBFS; capped at +3 dB), at 2.0 m −26.7. The tumbling one's `zip` is far louder
  (−2.5 dBFS) than any true pass.
- **Ricochets:** stone, iron and dirt the same (−17.8 / −18.0 / −18.2 LUFS, centroid 2,266 Hz).
- **Impacts at 5 m:** flesh −28.2 LUFS (0.24 s, centroid 75 Hz), glass −17.9 (1.1 s); **wood and dirt
  silent**.
- **Fire** (the store well alight): −18.1 LUFS at 5 m, −26.2 across the street (15 m).
- **Steps:** silent on boards, dirt, running.
- **Voices at once:** the gang's fight (12 shots in 30 s) at most 6 (mean 1.2); one stick in the
  saloon 38; three against the store's front 108 (`timber_crack`, `timber_crash`, `glass`, one
  player each).
- **Cost:** 0 / 8 / 32 / 64 looping voices: 27.2 / 28.2 / 29.4 / 29.8 ms median frame here (Movie
  Maker mixes inside the frame): ~0.04 ms a voice on this 2.1 GHz core, ~0.026 at Sean's. The
  fight's 6 is ~0.15 ms; the wall's 108 is ~2.8 ms here, ~1.8 at Sean's (over the 1.0 ms
  "everything else" budget for a moment). (In the game the mix runs on Godot's audio thread; the
  per-voice share on the main thread is the panning update.)

## The ten that sound most fake, flat, quiet or wrong for 1882

1. **No closeness in a gunshot.** Your own shot, a man's at 2 m and at 7 m are the same loudness
   (−18.0 / −18.2 / −18.4 LUFS) and the same sound; only past ~12 m does it drop, and slowly
   (−3 dB a doubling). A shot beside you should be a slam, one across the street a pop. (unit_size
   25 with max_db +6, then the limiter.)
2. **Sound is as fast as light.** At 80 m the bang comes with the flash (0.02 s; sound takes 0.23 s),
   dynamite at 100 m with its flash (0.29 s). The gap is what tells you it's far.
3. **Every place sounds the same.** A shot in the saloon is a shot in the street: no room (same
   0.27 s decay, same C50); no slap off the fronts across the street; the same baked "hills" echo
   (0.42 / 0.95 / 1.5 s) whether you're in the saloon or 80 m down the street.
4. **Walls don't exist.** A shot through the saloon's wall is the same as through its open door and
   as one in the open (−18.6 / −18.6 / −18.4 LUFS at 7 m).
5. **A .45 Colt ball that cracks.** Black-powder .45 Colt loads are quoted at 850–1,050 ft/s
   (260–320 m/s; the game's 274 m/s): below sound, so no snap; a passing ball buzzes or hums.
   Buckshot at ~1,200 ft/s (the game's 365 m/s) is barely supersonic and only near the muzzle.
   Today every true pass snaps, and at 0.3 m and 1 m it's the same snap (capped). (Sean's earlier
   call, "a near miss is a snap; a whiz is usually a ricochet", came from modern rounds: his call.)
6. **Balls hit wood and dirt in silence.** No thunk in a board, no thud and spit of dirt; metal only
   if it glances. Most shots in a fight hit wood or dirt.
7. **One ricochet for everything.** Stone, iron and dirt give the identical spang and whine, and
   every one of a charge's nine pellets that glances plays its own: the coach gun into the street
   is the shot plus nine spangs.
8. **A dead world.** No footsteps (boards or dirt), no ambience at all (−120 dB between shots), no
   voices, horses, falls; a shot has no world to stand against and a quiet moment isn't tense, just
   empty.
9. **Breaking turns to mush.** A wall coming down is 108 sounds at once (every member its own crack
   and crash, every pane its own glass), all the same two samples; also ~1.8 ms of mix at Sean's.
   One stick in the saloon is 38.
10. **Dynamite is a louder gunshot.** The same synthesis shape, capped at 5 m like point blank,
    −3.5 dB a doubling (13.7 → 29.1 LUFS from 5 to 100 m), no delay, no thump you feel and roll
    you hear from far, and no debris coming down after it (only timber rubble, if any falls).

Also flat: everything is 22 kHz mono, so cracks, glass and the hammer lose their top octave; the
coach gun is the revolver's sound pitched down; the fire is one 3-second loop per light (its
crackles repeat) turned up by size, with no roar.

## What's next (one at a time, each against this)

Gunshots first: black powder's weight, closeness, the delay and air at distance, the slap and the
hills' echo by where you stand, walls and rooms. Then passes (supersonic or not: Sean's call),
ricochets and impacts by material, dynamite near and far with debris, breaking, fire by size,
steps, a voice limit.
