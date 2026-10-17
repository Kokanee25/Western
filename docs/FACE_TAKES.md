# Face takes: what Sean records for the talking faces

Live Link Face on the iPhone, **ARKit mode** (a .csv of ARKit's 52 face values at 60 fps plus a
.mov with the voice). Claude plays them on a talking man (`tools/faces/arkit_take.py`,
`take_video.sh`; brief `docs/briefs/face-rig.md`). Takes hold Sean's face and voice: they are sent
to the session, never committed (the repo is public).

## Before each take

- **Calibrate** in the app if you can find it (a neutral, relaxed face held for its countdown); the
  take's `take.json` then says `"calibrated": true`. If not, no matter: hold a relaxed face for a
  second before speaking and the script takes that as your rest.
- Phone at face height, about 30 cm away, straight on (not below looking up); even light on the face.
- One take per block below; a fluffed line can just be said again in the same take.

## Take 1: range of motion (no talking)

About a second each, rest between: jaw wide open, then shut; a big "ee" grin; an "oo" pucker;
lips pressed tight; bite the lower lip (the F shape); bare the teeth; brows up; brows down; scowl;
blink; wink left; wink right; look left, right, up, down; half smile left; half smile right.

## Take 2: one sound per line (a normal pace)

- "Bobby picked a pretty pebble." (p, b, m)
- "Five fine fellows fought for a fiver." (f, v)
- "We see three sheep eating weeds." (ee)
- "Who knew the moon would loom so soon?" (oo)
- "Father's car is far, far off." (ah)
- "Oh no, don't go home alone." (oh)
- "Thin things thrive in the heat." (th)
- "Sally sells six silver saddles." (s)
- "Lazy Larry likes little lemons." (l)
- "Really, Ray? Red rope ripped?" (r)
- "Judge Jack's cheap shirt." (j, ch, sh)
- "Go get the gun, Kid." (k, g)

## Take 3: in character (each line once, the moods spread across them)

1. Calm: "You'd best put that iron away before somebody gets hurt."
2. Angry: "I ain't asking twice."
3. Whispered: "Well, I'll be damned. The stage is early."
4. Shouted: "Mister, that's my whiskey."

## What's done with them

Take 1 sets each expression's gain against Sean's own range; take 2 checks each sound's mouth
against his (MediaPipe on his .mov, measured against the man's mouth in the render: a sync score
per sound, and any delay between voice and face); take 3 is the test a player would see.
