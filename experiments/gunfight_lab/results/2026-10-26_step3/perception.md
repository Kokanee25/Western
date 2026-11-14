# The perception lab, before (main) and after

`python3 experiments/perception_lab/run.py --out=...` in each tree.

before: {"cases": 76, "judged": 117, "as_expected": 88, "missed": 13, "false": 8, "slow": 8, "leaks": 6}

after:  {"cases": 76, "judged": 117, "as_expected": 88, "missed": 13, "false": 8, "slow": 8, "leaks": 6}

The score and every verdict the same; three search cases' times differ (the gunman's cover search, see the README):

```
113,114c113,114
< | lost_round_corner_still | 8.00 | 8.02 | 0.02 | 0.4 | 4.2 | 5.7 | 11 | didn't | 1 | goes to where he last knew him (within 2 m): MISSED, knows he's lost him within 1.5 s: ok |
< | lost_round_corner_moving | 8.00 | 8.02 | 0.02 | 0.4 | 3.3 | 5.7 | 12 | didn't | 1 | goes to where he last knew him (within 2 m): MISSED, knows he's lost him within 1.5 s: ok |
---
> | lost_round_corner_still | 8.25 | 8.28 | 0.03 | 0.4 | 8.1 | 10.7 | 13 | didn't | 1 | goes to where he last knew him (within 2 m): MISSED, knows he's lost him within 1.5 s: ok |
> | lost_round_corner_moving | 8.25 | 8.28 | 0.03 | 0.4 | 8.1 | 10.7 | 13 | didn't | 1 | goes to where he last knew him (within 2 m): MISSED, knows he's lost him within 1.5 s: ok |
116c116
< | lost_at_night | -1.00 | -1.00 | -1.00 | -1.0 | 11.1 | 11.1 | 25 | didn't | 1 | goes to where he last knew him (within 2 m): MISSED, sees him at all before he hides: ok |
---
> | lost_at_night | -1.00 | -1.00 | -1.00 | -1.0 | 9.2 | 9.2 | 18 | didn't | 1 | goes to where he last knew him (within 2 m): MISSED, sees him at all before he hides: ok |
```
