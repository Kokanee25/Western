# How the gang moves (`moves.py`)

Runs and stays a man a fight are of men who fought. Dropped: left his cover within 2 s (0.5 s) of getting there, "you can see him there now".

| Run | Opening | Fights | Runs a man | Run m (med) | Running s a man | Got there | Switched | Given up | Stays a man | Stay s (med) | Dropped 2 s / 0.5 s of arrivals |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 100 | 3.2 | 3.4 | 5.8 | 91% | 0% | 9% | 2.9 | 7.7 | 83 / 32 of 866 |
| base | you | 100 | 2.7 | 2.7 | 5.7 | 79% | 0% | 21% | 2.1 | 7.2 | 29 / 17 of 509 |
| fix | they | 100 | 3.3 | 3.2 | 6.0 | 90% | 0% | 10% | 2.9 | 8.1 | 86 / 35 of 879 |
| fix | you | 100 | 2.7 | 3.0 | 6.0 | 81% | 0% | 19% | 2.2 | 7.5 | 31 / 16 of 521 |

| Run | Opening | Runs to a post | Stays at a post | Post s a man | Hits taken / given there | Climbs | Stays up | Up s a man | Hits on you from up | Shooting s (med) | 45-90 s | Hits on you | You down |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| base | they | 96 | 87 | 2.7 | 6 / 15 | 29 | 220 | 7.4 | 19 | 49.5 | 36% | 2.2 | 62% |
| base | you | 58 | 43 | 1.8 | 3 / 17 | 31 | 127 | 5.0 | 28 | 26.4 | 25% | 1.9 | 49% |
| fix | they | 107 | 94 | 2.8 | 5 / 13 | 29 | 211 | 7.1 | 20 | 49.4 | 32% | 2.1 | 58% |
| fix | you | 58 | 47 | 2.2 | 5 / 12 | 33 | 136 | 5.3 | 30 | 25.9 | 25% | 1.8 | 44% |

Runs given up, by why:

- base, they: give that cover up 49, run for cover 19, go for you 8, fight from the floor 5, come at you 2, drag Brody to cover 2, drag Kid to cover 1, back off 1, go up for height 1
- base, you: give that cover up 67, run for cover 20, drag Brody to cover 10, tend his wound 10, drag Lyle to cover 8, go for you 6, go up for height 5, come at you 3, go round on you 1, back off 1, fight from the floor 1, drag Kid to cover 1
- fix, they: give that cover up 58, run for cover 17, go for you 8, drag Lyle to cover 6, fight from the floor 5, come at you 2, go up for height 2, drag Brody to cover 1, get away 1, go round on you 1, drag Kid to cover 1, back off 1
- fix, you: give that cover up 60, run for cover 20, tend his wound 11, go for you 7, drag Brody to cover 7, go up for height 5, drag Lyle to cover 4, go round on you 2, fight from the floor 1, come at you 1, drag Kid to cover 1
