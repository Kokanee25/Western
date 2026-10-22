# 2026-10-22: a man who loses his footing awake throws out his arms (`HumanBody.brace`)

Sean (2026-10-22): "a man who loses his seat catches himself". The chair's blind critic: "his arms
show no surprise ... a man taken by surprise would flail, grab the seat, tuck his chin".

## What it does

Going down awake with nothing hurting him, his arms and neck get new targets for the muscle tone
he still has. It's the tone `_hunch` already rewrites for a wound, not a scripted animation:

- **Falling backwards:** the arms go forward and out (to counterbalance), the chin tucks, and the
  trunk curls a little.
- **Pitched forward:** the arms reach ahead to take the ground, and the head comes up.

He reads which way he's going from his chest's speed against his facing, 0.05 s or more after he
goes. Those joints hold 2.5 times harder and fade over 0.9 s (the rest of him over 0.6). A braced
arm is a pure swing from hanging down: two Euler angles together twisted the left arm past its
40 degrees (`twist_past_limit` in 7 of 19 falls, now none).

He braces when his chair goes from under him (`KitProp._unseat`, the prop lab's file, three lines)
and when a shove puts him down (`take_blow`). He doesn't brace when shot (the wound's `_hunch`
leads), blasted, or killed.

## Proof

- **Group U and Q, 4 runs each with `--jitter`** (`jitter_spread.txt`): flags 20 a run against
  main's 22; creeping after stopping 2 of 40 against 3. The chair falls land where they did. One
  change: shoved face-first into the walkway's rail, he often catches himself on it with his
  reaching arms. He drops a median 2.05 m (main 3.30 m: over every time).
- **A blind pairwise judge** (`judge.md`, key `key_blind.json`): **the brace 9, main 0, even 1**
  over the ten falls. Main's faults: "his arms hang limp at his sides the whole way, like a sack";
  "hands stay clasped in his lap until he's flat, like a doll". Faults left in both: off the
  railing he drops near vertical onto his head; his head lolls for a beat as if out cold.
- **Tests** (`tests/test_seated_falls.gd`): awake, an arm goes out past 45 degrees as his chair goes
  (20 degrees without the brace); dead in his chair, his hands stay in his lap.
