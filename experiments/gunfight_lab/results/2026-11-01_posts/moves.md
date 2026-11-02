# How the gang moves (`moves.py`)

Runs and stays a man a fight are of men who fought. Dropped: left his cover within 2 s (0.5 s) of getting there, "you can see him there now".

| Run | Opening | Fights | Runs a man | Run m (med) | Running s a man | Got there | Switched | Given up | Stays a man | Stay s (med) | Dropped 2 s / 0.5 s of arrivals |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 100 | 2.4 | 2.5 | 4.2 | 91% | 0% | 9% | 2.2 | 4.6 | 143 / 81 of 658 |
| base | you | 99 | 2.5 | 2.5 | 4.0 | 89% | 0% | 11% | 2.2 | 4.0 | 114 / 65 of 661 |
| posts_final | they | 100 | 2.9 | 3.2 | 5.3 | 89% | 0% | 11% | 2.5 | 6.0 | 120 / 67 of 756 |
| posts_final | you | 100 | 2.6 | 2.6 | 4.7 | 86% | 0% | 14% | 2.2 | 4.9 | 93 / 46 of 647 |

| Run | Opening | Runs to a post | Stays at a post | Post s a man | Hits taken / given there | Climbs | Stays up | Up s a man | Hits on you from up | Shooting s (med) | 45-90 s | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 25 | 24 | 0.5 | 2 / 11 | 0 | 163 | 3.9 | 20 | 32.6 | 32% | 2.2 | 63% |
| base | you | 35 | 34 | 0.9 | 10 / 14 | 0 | 182 | 4.2 | 42 | 40.5 | 28% | 2.1 | 53% |
| posts_final | they | 242 | 193 | 8.3 | 14 / 52 | 0 | 171 | 4.3 | 36 | 42.5 | 29% | 2.6 | 68% |
| posts_final | you | 187 | 148 | 5.6 | 20 / 33 | 0 | 143 | 3.3 | 36 | 38.4 | 26% | 2.0 | 50% |

Runs given up, by why:

- base, they: give that cover up 26, go for you 12, run for cover 8, fight from the floor 4, go round on you 3, come at you 3, drag Kid to cover 2, drag Brody to cover 2, drag Lyle to cover 2, run 1
- base, you: give that cover up 33, run for cover 13, tend his wound 7, drag Brody to cover 6, come at you 4, go round on you 3, drag Lyle to cover 3, go for you 3, drag Kid to cover 3, fight from the floor 2, run 1, lie low 1
- posts_final, they: give that cover up 34, run for cover 18, go for you 18, come at you 6, fight from the floor 6, go round on you 3, drag Brody to cover 2, drag Kid to cover 2, fight it out 1, back off 1, drag Lyle to cover 1
- posts_final, you: give that cover up 58, run for cover 18, tend his wound 9, fight from the floor 4, drag Lyle to cover 4, go for you 4, drag Kid to cover 4, go round on you 3, drag Brody to cover 3, come at you 2

