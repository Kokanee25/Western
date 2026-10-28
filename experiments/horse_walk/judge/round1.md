# Blind judge, round 1 (2026-10-28)

A fresh agent that had seen neither the code nor the reasoning, given only the eight matched pairs
(`compare/pair_*.jpg` as they were then: our first walk) and told to ignore background, paint, tack,
framing and polygon count. Its report, condensed:

1. **Head and neck held high, stiff, never nodding (large; all pairs).** The real horse carries its
   neck near level, poll about wither height, nose forward and down, and nods. Ours: upright like a
   show horse, face near vertical, the same height every frame.
2. **The fore steps too high and snaps at the knee (large).** Real: the swinging fore stays low, the
   knee bends moderately, the hoof skims a few centimetres up. Ours: the forearm lifts near level,
   the knee folds sharply, the hoof hangs toe-down and flicks back: "Hackney-like, prancing".
3. **Hind legs stiff, little reach forward (clear).** Real: the hind swings well under the belly,
   stifle and hock flex smoothly, the croup tips and rolls. Ours: a shorter arc, posts from hip to
   hock, the far hind's hock jerking up high.
4. **The hoof leaves too early and folds too far (clear).** At lift-off the real hoof is still rolling
   over its toe; ours is already in the air with its sole showing.
5. **Body level, no swing or bounce (small to clear);** the tail hangs dead, then flicks stiffly.

Kept: a correct four-beat footfall order; the fore reaching forward and landing straight; stance
times plausible.

Mismatched events: the front-leg events look late in the footage against ours (its LF lands ~0.37 of
the stride after its LH; ours 0.25).

## What was done about it

1. The walk's own carriage over the model's standing pose: the neck lowered 16 degrees, the nose put
   forward 12; the nod from 3.2 to 5 degrees (the head's rise and fall about 8 cm).
2. The knee's fold in swing 75 -> 50 degrees (the clip ~45), the elbow held near its rest
   (preference weight 0.05 -> 0.8: the forearm no longer lifts level), the fore's toe lift 8.5 -> 7 cm,
   the hoof's flip in swing 90 -> 65 degrees.
3. The hock's fold 45 -> 35 (no jerk). The reach is the hind leg's length: reported, not fixed
   (README, "What's left").
4. Breakover over the stance's last third (was a quarter), the flip spread over the swing's first 35%.
5. The trunk's rise and fall 1.2 -> 2 cm each way; the tail's sway smaller and lagging bone to bone.

The front-leg events: the clip's lateral phase is 0.33 (measured), ours the published 0.25 (the
issue: the published gait wins where they disagree): reported, not changed.
