# How the gang moves (`moves.py`)

Runs and stays a man a fight are of men who fought. Dropped: left his cover within 2 s (0.5 s) of getting there, "you can see him there now".

| Run | Opening | Fights | Runs a man | Run m (med) | Running s a man | Got there | Switched | Given up | Stays a man | Stay s (med) | Dropped 2 s / 0.5 s of arrivals |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 100 | 3.3 | 3.2 | 6.0 | 90% | 0% | 10% | 2.9 | 8.1 | 86 / 35 of 879 |
| base | you | 100 | 2.7 | 3.0 | 5.8 | 82% | 0% | 18% | 2.2 | 7.5 | 31 / 16 of 521 |
| fix | they | 100 | 3.1 | 3.4 | 6.4 | 90% | 0% | 10% | 2.8 | 8.1 | 78 / 30 of 835 |
| fix | you | 100 | 2.7 | 2.7 | 5.4 | 86% | 0% | 14% | 2.3 | 7.7 | 27 / 15 of 554 |

| Run | Opening | Runs to a post | Stays at a post | Post s a man | Hits taken / given there | Climbs | Stays up | Up s a man | Hits on you from up | Shooting s (med) | 45-90 s | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 107 | 94 | 2.8 | 5 / 13 | 29 | 211 | 7.1 | 20 | 49.4 | 32% | 2.1 | 58% |
| base | you | 58 | 47 | 2.2 | 5 / 12 | 33 | 136 | 5.3 | 30 | 25.9 | 26% | 1.8 | 44% |
| fix | they | 99 | 89 | 2.9 | 7 / 19 | 32 | 210 | 7.0 | 19 | 50.0 | 38% | 2.0 | 60% |
| fix | you | 63 | 52 | 1.9 | 3 / 14 | 26 | 132 | 5.9 | 28 | 22.8 | 19% | 1.9 | 48% |

Runs given up, by why:

- base, they: give that cover up 58, run for cover 17, go for you 8, drag Lyle to cover 6, fight from the floor 5, come at you 2, go up for height 2, drag Brody to cover 1, get away 1, go round on you 1, drag Kid to cover 1, back off 1
- base, you: give that cover up 58, run for cover 20, tend his wound 11, go for you 7, drag Brody to cover 7, go up for height 5, drag Lyle to cover 4, go round on you 2, fight from the floor 1, come at you 1, drag Kid to cover 1
- fix, they: give that cover up 50, run for cover 16, go for you 9, drag Lyle to cover 5, drag Kid to cover 4, fight from the floor 3, come at you 3, go round on you 2, get away 1, drag Brody to cover 1, go up for height 1
- fix, you: give that cover up 36, run for cover 22, tend his wound 9, drag Lyle to cover 8, drag Brody to cover 7, go up for height 3, go for you 2, come at you 1, go round on you 1, drag Kid to cover 1
