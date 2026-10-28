# 2026-10-28: muscle tone that fades (issue #442; waiting on Sean)

Sean (2026-10-27, after the saloon shootout): "Okay how do we make it closer to euphoria style
physics - I don't want people flying around but I don't want every death to be a drop dead rag
doll." **Off in the game** (`HumanBody.tone_style` is `""`): nothing changes until he says.

## The change (`src/bodies/human_body.gd`, behind `HumanBody.tone_style`)

Today (`""`): as he goes limp every joint is held toward the pose he went in, all of him at once,
fading away over 0.35 s (0.6 awake, 0.15 killed outright).

**`fade` (step 1):** the same springs and stiffness (no more force), but a region at a time:
- His **legs** hold 0.02-0.08 s and go over 0.3-0.5 s, his **trunk** 0.15-0.3 then 0.6-1.0, his
  **neck** 0.2-0.35 then 0.7-1.1, his **arms** 0.3-0.5 then 0.9-1.4 (`TONE_REGIONS`). Each fades
  smoothly to nothing, and its spring is gone once it has (the joint costs nothing after).
- **One leg goes first** (the other 0.15-0.35 s later, `TONE_LEG_LAG`), and that leg **buckles**:
  its knee and hip pulled into a bend as it lets go (`TONE_BUCKLE`, the other 0.35 of it). Without
  the buckle he stood like a post for half a second and then sank into an even squat (the faint's
  old fault, `results/2026-10-21_faint`), as today does.
- **Each man his own way**, drawn from his own seed (`_tone_regions`): the times, his stiffness
  ±15%, which leg, and one man in five folding at the waist before his legs go. The same man goes
  the same way every time; nothing else's draws move.
- Killed outright, every time ×0.45; awake, ×1.3. After a stumble his legs go at once.

**`dying` (step 3):** the fade, and what he still does as he goes (`_start_dying`, `_step_dying`):
- The hand he was **holding a wound** with stays on it (and keeps pressing it); hit in the belly,
  chest or neck as he goes, a free hand **finds the hole** after 0.2 s. Never one in his back.
- Awake, a free hand goes out to the **nearest rail, table, bar or wall** within 0.75 m of his
  shoulder (one shape query as he goes), and lets go once he's fallen past arm's reach.
- Pitching forward, chest facing down and 0.9 m from the ground, his **arms come up in front of
  him** (`BRACE_FRONT`'s arms, held again for 0.15 s).
- All of it his own pull: the hand drawn toward its place (at most 20 N) with the same pull back
  on him, as strong as that arm's tone still is. Dead, none of it; out cold, only the arms.

The lab: `--tone=off|fade|dying` (or a scenario's `tone` field); `tone.py` (time to the ground,
planked landings, head and chest speed as they land); the segments' new `world_contacts` column
(contacts with anything but his own parts).

## Numbers (headless, 74 falls: groups A, F, G, K, L, M, P, S; `tally.txt`, `tone_each.txt`)

| | today | fade | dying |
|---|---|---|---|
| time to the ground (s, mean) | 1.58 | 1.24 | 1.18 |
| planked (knees straight as his trunk lands) | 1 | 1 | 1 |
| planked, the rail/table/blast groups T, Q, Y, N (26 falls) | 6 | 0 | 0 |
| head lands at (m/s, mean) | 0.93 | 1.12 | 1.20 |
| never settled | 11 | 4 | 5 |
| kneeling at the end / kneeling s in all | 2 / 14.9 | 1 / 11.3 | 2 / 11.6 |
| flags | 41 | 49 | 64 |

- He goes down sooner because he no longer stands like a post for half a second: the knees give at
  once. That also lands his head a little faster.
- The new flags, fade: 13 `lingering_motion` in one scenario (five men in a pile, a forearm
  creeping), `joint_pulled_apart` 7 -> 12 (the run-and-walk stumbles of group L, peaks 0.041 ->
  0.046 m on a 0.03 threshold). Dying adds `sunk_into_world` 4 -> 9 (a hand 3.0-3.4 cm into the
  floor as he lands: Jolt's slop is 2 cm, and the lab's README counts 3-7 cm at impact an artefact)
  and 3 `discontinuity` (a hand whipping 45° in a tick as it lands, baseline fault 4's kind).
  `flags_off_vs_dying.txt` lists them by scenario. Tried and dropped: only the first leg buckling
  (the judge's "one knee first") took the flags to 65; knee and elbow springs held to the hinge's
  axis changed nothing.

## The blind judges (fresh sub-agents, sheets shuffled, `blind.py`; keys `blind*_key.json`)

11 falls, today against the tone, three cameras, 0-2.9 s:
- **Round 1** (the first `dying`): tone 6, today 4, even 1. The tone's faults: arms held up stiff
  like a mannequin after the reach and the brace, an even squat. Fixed: softer pulls, the reach lets
  go past arm's reach, a weaker brace.
- **Round 2** (as committed): **tone 5, today 5, even 1.** The tone won the blackout ("buckles at the
  knees from 0.25 s, a steady crumple"), the gut shot ("stays folded round it, hands to his belly,
  curls onto his side"), the blast, the top of the stairs ("crumples by 0.5 s and settles curled")
  and the table ("knees go, his arms come out in front and he lands face-down"). Today won the
  front shot (tone: "sits on an invisible chair, then slams onto his back"), the chest shot (tone:
  "drops into a squat almost at once, sits, and falls back flat"), the walking belly shot, the bar
  (tone: "pitches away fast with that arm trailing stiff") and the balcony (today "slumps onto the
  rail, arms on it").
- The judge's biggest fault left: forward falls still put his face down first; the arms rarely get
  out in time. Running deaths (both) are a stiff plank pivoting on planted feet.

Sheets (`sheets/`, today above, `dying` below) and videos (side by side, game speed then ×3 slow;
on the claude.ai page, not in git): the stairs, the balcony rail, the table, the front shot, the
gut shot, the blast, the blackout.

## Cost (`perf.txt`; `run.py --perf`, two runs each, headless, this 2.1 GHz core; ×0.65 for Sean's)

Mean frame ms over the 3 s after 1, 5 and 10 men go limp on one tick:

| men | today | fade | dying |
|---|---|---|---|
| 1 | 0.49 / 0.54 | 0.51 / 0.61 | 0.47 / 0.55 |
| 5 | 1.33 / 1.36 | 1.43 / 1.29 | 1.55 / 1.31 |
| 10 | 2.08 / 2.08 | 2.28 / 2.28 | 2.61 / 2.36 |

- Ten men at once: about +0.2 ms here (fade) and +0.3-0.5 (dying), +0.13-0.35 at Sean's, about the
  run-to-run noise (the standing frames, the same code in all three, vary by 0.3). They all sleep
  about a second later (by 4 s, not 3).
- The go_limp tick (building the ragdoll) is unchanged: 22-33 ms for ten here, as before.
- **The cap:** the numbers don't need one. If Sean wants a guard anyway: the tone for the 8 men
  nearest the player, everyone else as today. Not built.
- The saloon's ~2 fps isn't this: it's the people's standing cost (`docs/briefs/more-cores.md`).

## Step 2, a hit that doesn't drop him: not built (needs the standing rig)

The issue's step 2 (the hit region's strength dips and recovers, so the ball shoves him and he
fights back up) needs a physical standing body. A standing man's parts are AnimatableBody3Ds moved
by the pose script each tick: nothing can shove them, so there is nothing for his muscles to fight.
What it would take, and what it's worth:
- **The ball alone barely moves a man.** A .45 ball is 4.5 N·s; an 80 kg man takes 0.06 m/s from
  it. Euphoria's hit reactions are the body's own (a startle, a stagger, a grab), authored as
  controller behaviours on a powered rig, not the bullet's push. Sean's note of 2026-10-18 stands
  today: no flinch or wince for a ball that doesn't drop him; the wound's consequence comes on as
  a hurt would (`_favour_step`).
- **A procedural shove** on the pose (a spring on the hit joints) is what the old flinch was, and
  Sean turned it down twice ("too quickly pushed back", "a super fast backwards jerk").
- **The real thing is the powered rig** (the issue's "later"): every standing man's parts
  RigidBodies driven toward the animation by these same springs, with balance and corrective steps.
  This lab says the springs are cheap (~0.03 ms a man while they act, at Sean's), but a standing man
  holds them every tick, not for 2 s, plus the balance and the extra bodies awake: roughly 17
  bodies and 16 joints a man for every man in view. A brief first.

## Sean's calls (the `waiting on Sean` issue)

1. Does the tone read as Euphoria-ish, or rubbery? (The judges: a split; better crumples, worse
   sit-downs.)
2. Fade times: longer or shorter (`TONE_REGIONS`)?
3. Which: `fade` alone, `dying`, or neither; and a cap (proposed: none, or 8 nearest).
4. On in the game, or more work in the lab first (the forward falls' arms, the sit-down on a front
   shot)?
