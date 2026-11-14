# How the gang moves (`moves.py`)

Runs and stays a man a fight are of men who fought. Dropped: left his cover within 2 s (0.5 s) of getting there, "you can see him there now".

| Run | Opening | Fights | Runs a man | Run m (med) | Running s a man | Got there | Switched | Given up | Stays a man | Stay s (med) | Dropped 2 s / 0.5 s of arrivals |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 100 | 2.9 | 3.2 | 5.3 | 89% | 0% | 11% | 2.5 | 5.9 | 123 / 69 of 760 |
| base | you | 100 | 2.7 | 2.6 | 4.7 | 86% | 0% | 14% | 2.3 | 4.7 | 93 / 45 of 672 |
| step2 | they | 100 | 3.1 | 3.3 | 5.8 | 86% | 0% | 14% | 2.6 | 5.8 | 126 / 66 of 786 |
| step2 | you | 100 | 2.5 | 2.6 | 4.0 | 86% | 0% | 14% | 2.1 | 4.9 | 85 / 45 of 625 |

| Run | Opening | Runs to a post | Stays at a post | Post s a man | Hits taken / given there | Climbs | Stays up | Up s a man | Hits on you from up | Shooting s (med) | 45-90 s | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 247 | 197 | 8.3 | 14 / 52 | 0 | 171 | 4.3 | 36 | 42.5 | 29% | 2.6 | 68% |
| base | you | 199 | 159 | 6.0 | 22 / 35 | 0 | 145 | 3.3 | 36 | 39.2 | 26% | 2.0 | 49% |
| step2 | they | 267 | 206 | 8.1 | 21 / 56 | 0 | 162 | 4.3 | 37 | 45.6 | 32% | 2.7 | 68% |
| step2 | you | 180 | 150 | 5.2 | 17 / 47 | 0 | 146 | 3.2 | 37 | 38.0 | 30% | 2.0 | 52% |

Runs given up, by why:

- base, they: give that cover up 34, run for cover 18, go for you 18, come at you 7, fight from the floor 6, go round on you 3, drag Brody to cover 2, drag Kid to cover 2, fight it out 1, back off 1, drag Lyle to cover 1
- base, you: give that cover up 58, run for cover 18, tend his wound 9, drag Lyle to cover 5, fight from the floor 4, go for you 4, drag Kid to cover 4, go round on you 3, drag Brody to cover 3, come at you 2
- step2, they: give that cover up 62, go for you 17, run for cover 15, drag Lyle to cover 9, drag Kid to cover 6, fight from the floor 4, come at you 4, drag Brody to cover 4, go round on you 4, fight it out 1
- step2, you: give that cover up 46, run for cover 18, tend his wound 9, go round on you 6, fight from the floor 4, go for you 4, drag Kid to cover 4, drag Lyle to cover 3, come at you 2, drag Brody to cover 2, back off 1

