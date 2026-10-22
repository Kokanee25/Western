# The gun lab's baseline (2026-10-22, main at fd7fe08)

Today's guns, measured and drawn, nothing changed (`README.md` for how). Sheets in `sheets/`:
`fp_revolver.jpg`/`_close.jpg` and `fp_shotgun.jpg`/`_close.jpg` (first person, a frame a state),
`men_<body>.jpg` (each Studio man's gun: rows the states, columns close, 1, 5, 10 m and, holstered,
an x-ray with his body hidden). Numbers in `handling.json` and `men_*.json`. Afternoon (16:00),
the sun behind the player; Main Street at (-6, 0, -8.4).

## Handling

| Handling | Revolver | Coach gun | A man (OutlawBrain) |
| --- | --- | --- | --- |
| Draw to first shot (s) | 0.62 | 0.85 | 0.5, then his first shot (no hammer) |
| Cocking (s) | 0.23 | 0.28 | none: his hammer never moves |
| Fastest shot to shot (s) | 0.45 | 0.42 | 1.4 x 0.75-1.3 |
| Reload one (s) | 1.67 | 1.77 | - |
| Full reload (s) | 6.9 (six spent) | 2.7 (two) | 12.0 for 5 rounds, a timer: nothing moves |
| Sight recovery after an aimed shot: settled (s) / worst (deg) / climb left to pull down (deg) | 0.55 / 15.1 / 0.95 | 0.60 / 13.6 / 1.54 | - |

| Accuracy at 10 m: R50 (cm) / share in a 45x75 cm torso | Revolver | Coach gun (the charge's centre) |
| --- | --- | --- |
| Steady (2 s on the sights) | 5.7 / 1.00 | 4.9 / 1.00 |
| Rushed (fired 0.25 s after raising the sights) | 8.0 / 1.00 | 4.7 / 1.00 |
| From the hip, standing | 25.0 / 0.69 | 29.6 / 0.56 |
| From the hip, walking | 35.6 / 0.44 | 40.0 / 0.31 |
| Wounded: a ball through the left upper arm, 3 s after (pain 1.5, felt 1.1 under adrenaline 0.6; +1.65 deg) | 26.3 / 0.83 | - |
| The same, 45 s after (felt 1.3; +2.1 deg) | 16.5 / 0.82 | - |
| And a ball through the gun forearm | can't hold it: the gun goes back in the holster | - |

The outlaw's calm spread is a 2.4 deg cone (its edge 42 cm at 10 m), widened by pain, shock, fear,
the arm, the eye and a moving target; none of it comes from a sway like yours.

Where these sit against the real guns (rough figures for a practised man with an 1870s single
action, to be agreed; none is a feel range yet): a draw to a first aimed shot about 0.7-1.2 s
(the fastest fast-draw men 0.3-0.5 s, cocking as they draw); finding the sights about 0.3-0.5 s
after raising them; a Single Action Army loaded one chamber at a time through the gate, about
1.5-2 s a chamber, 10-15 s for six; a coach gun's two shells about 3-5 s.

## A man's gun (the four Studio men)

| | bold_cowboy_s0 | old_rancher_s1 | young_drifter_s1 | sean_s2 |
| --- | --- | --- | --- | --- |
| Grip against his hand: nearest (mm) / his hand's points inside the gun | 0 / 2.6 % | 0 / 2.1 % | 0 / 1.7 % | 0 / 1.5 % |
| Palm's middle to the grip's (mm) | 33 | 20 | 35 | 26 |
| Holstered: the frame's middle inside the outside of his hip (mm; the frame is 13 mm a side) | -7 | 22 (hidden) | -10 | 4 |
| Dropped, 2 s: lowest point against the ground (mm) | -7, at rest | -7, at rest | -7, at rest | -7, at rest |

The grip never floats off a man's hand (it can't: it's fixed to his hand's part, the same in every
pose), but nothing closes round it.

## What's wrong (the list the fixes work from)

**In first person**

1. **The coach gun from the hip floats**: only its barrels are in view, no hand, no stock; the
   hands only show shouldered. (`fp_shotgun.jpg` rest, walk, run, cocked.)
2. **The hands are boxes**: the revolver's hand is a stack of skin-coloured boxes, a big square
   block at the wrist; the coach gun's are worse (a slab for a palm, fingers as bars). Shouldered,
   the right hand fills the bottom left corner.
3. **The sleeves don't match your body**: the held sleeve is a brown coat with a cream cuff; the
   body you see when you look down wears a cream shirt and a dark vest, no coat. The skin is a
   different tone from the body's too (0.80/0.56/0.40 held, 0.72/0.53/0.40 the body's).
4. **The revolver's reload isn't readable**: the loading pose rolls the gun on its left side and
   points it up and left, so the gate (on the right) faces away from you; the gate, the ejector
   rod and each round going in can't be seen, and no frame differs from the next. No left hand
   holds the gun; no thumb turns the cylinder; nothing carries a round to the gate.
5. **The coach gun's reload has no hands at work**: the barrels drop, a shell rises out of the
   breech and hangs there upright (`pull shell`), and a fresh one is simply in the chamber; the
   left hand stays on the forend, the right on the wrist.
6. **Walking and running change nothing**: the gun sits exactly as at rest (the view bobs; the gun
   doesn't swing, dip or come down to a run).
7. **Finding the sights is too quick**: a shot 0.25 s after raising the sights is nearly as tight as
   one held 2 s (8.0 against 5.7 cm at 10 m; the coach gun no different at all).
8. **Put away, nothing's there**: looking down after holstering the revolver you see your boots
   and no grip in a holster (PlayerBody's grip is out of view); the coach gun simply vanishes (no
   sling, nothing on your back or in your hand).
9. The reload is quick against the real guns (6.9 s for six against 10-15 s); a feel call for Sean
   with the step-by-step reload, not changed alone.

**In a man's hands**

10. **No holster, no gun belt on the Studio men** (they're "whole": BodyMesh's belt and holster
    aren't drawn on them); the holstered revolver hangs upright in his trouser leg, barrel down,
    only its grip showing behind his arm (`men_*` holstered x-ray). The old rancher's is inside him.
11. **The draw is a jump**: `draw_gun` moves the gun from the hip to the hand in one frame; the arm
    then swings up from his side over a few tenths with the gun already in it.
12. **His hand doesn't hold the gun**: no finger bones (issue #222), so the hand stays open and flat
    beside the grip; the gun is fixed to the hand's part at an offset made for the old lofted body.
13. **His shots don't move the gun**: no hammer cocked, no cylinder turning, no kick in his wrist or
    arm, no spent case; only the smoke and flash.
14. **His reload is a 12 s timer, crouched, nothing moving**, and loads 5 from nowhere (no belt).
15. **Dropped, it lands standing on its end** and stays there (`men_*` dropped): its box shape is
    long in the gun's local z, the barrel and butt.
16. **It can't be shot out of his hand**: the gun has no collider (only a hit on his right hand or
    arm drops it); nobody picks a dropped gun up (the group `dropped_guns` is only cleared by the
    spawner).

**The look** (art judges; for the painting step)

17. The blued steel and case-hardened frame are code squares (`PixelArt.squares`), flat grey: no
    case colours, no bluing worn to bright at the edges; the brass is code metal
    (`PixelArt.metal`); only the walnut is the texture factory's painting (`walnut`). Against the men's painted clothes the gun
    reads as a flat dark silhouette at 5 and 10 m.
18. **The revolver's grip rakes the wrong way**: `RevolverModel`'s grip is turned +22 degrees about
    X, which swings its butt forward (3 cm ahead of the frame at the bottom); a Single Action
    Army's grip sweeps down and back. Found placing the new hand (`views.gd`'s detail views print
    the grip's corners: top front at z 0.1 cm, bottom front at z -3.1 cm). Every man's gun too.
19. The muzzle flash at a man's gun fills most of a 1 m view with a white disc (the flash's size
    isn't the gun's lab's, noted for the effects).

**For the sound lab** (its own lab; the README's list): a man's gun has only its shot: no draw, no
cock, no reload, no drop.
