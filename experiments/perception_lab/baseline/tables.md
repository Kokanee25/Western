# The perception lab's baseline: the tables

(Written by `run.py --table=ROOT --keep=...`; what they show is in `baseline.md`.)

## Counts

| group | runs | judged | as expected | missed | false | slow | leaks (sampled) |
|---|---|---|---|---|---|---|---|
| sight | 60 | 50 | 33 | 4 | 5 | 8 | 0 |
| hearing | 7 | 41 | 28 | 4 | 9 | 0 | 0 |
| search | 4 | 8 | 6 | 2 | 0 | 0 | 5 |
| news | 2 | 12 | 7 | 2 | 3 | 0 | 0 |
| leaks | 3 | 6 | 0 | 0 | 6 | 0 | 0 |
| **all** | 76 | 117 | 74 | 12 | 23 | 8 | 5 |

## Sight

| case | light | distance m | line (Senses' ray meets) | Senses light | spotted s | expected | verdict |
|---|---|---|---|---|---|---|---|
| street_10m | day | 10.0 | clear | 1.00 | 0.47 | sees | ok |
| street_10m | golden | 10.0 | clear | 0.95 | 0.47 | sees | ok |
| street_10m | night_lit | 10.0 | clear | 0.00 | 5.53 | sees | slow |
| street_10m | night_out | 10.0 | clear | 0.00 | 5.53 | sees | slow |
| street_25m | day | 25.0 | clear | 1.00 | 0.73 | sees | ok |
| street_25m | golden | 25.0 | clear | 0.95 | 0.73 | sees | ok |
| street_25m | night_lit | 25.0 | clear | 0.00 | never | either | - |
| street_25m | night_out | 25.0 | clear | 0.00 | never | either | - |
| street_45m | day | 45.0 | clear | 1.00 | never | sees | MISSED |
| street_45m | golden | 45.0 | clear | 0.95 | never | sees | MISSED |
| street_45m | night_lit | 45.0 | clear | 0.00 | never | either | - |
| street_45m | night_out | 45.0 | clear | 0.00 | never | doesn't | ok |
| under_lamp_20m | day | 18.8 | clear | 1.00 | 1.00 | sees | ok |
| under_lamp_20m | golden | 18.8 | clear | 0.95 | 1.00 | sees | ok |
| under_lamp_20m | night_lit | 18.8 | clear | 0.00 | never | sees | MISSED |
| under_lamp_20m | night_out | 18.8 | clear | 0.00 | never | either | - |
| crouched_dark_15m | day | 15.1 | clear | 1.00 | 1.53 | sees | slow |
| crouched_dark_15m | golden | 15.1 | clear | 0.95 | 1.53 | sees | slow |
| crouched_dark_15m | night_lit | 15.1 | clear | 0.00 | never | doesn't | ok |
| crouched_dark_15m | night_out | 15.1 | clear | 0.00 | never | doesn't | ok |
| behind_back | day | 5.0 | clear | 1.00 | never | doesn't | ok |
| behind_back | golden | 5.0 | clear | 0.95 | never | doesn't | ok |
| behind_back | night_lit | 5.0 | clear | 0.00 | never | doesn't | ok |
| behind_back | night_out | 5.0 | clear | 0.00 | never | doesn't | ok |
| side_walker | day | 7.1 | clear | 1.00 | 3.53 | sees | slow |
| side_walker | golden | 7.1 | clear | 0.95 | 3.53 | sees | slow |
| side_walker | night_lit | 7.1 | clear | 0.00 | never | either | - |
| side_walker | night_out | 7.1 | clear | 0.00 | never | either | - |
| behind_wall | day | 13.5 | Store/front_siding_r09_1 (board) | 1.00 | never | doesn't | ok |
| behind_wall | golden | 13.5 | Store/front_siding_r09_1 (board) | 0.95 | never | doesn't | ok |
| behind_wall | night_lit | 13.5 | Store/front_siding_r09_1 (board) | 0.00 | never | doesn't | ok |
| behind_wall | night_out | 13.5 | Store/front_siding_r09_1 (board) | 0.00 | never | doesn't | ok |
| round_the_corner | day | 15.3 | StreetDressing/Barrel | 1.00 | never | doesn't | ok |
| round_the_corner | golden | 15.3 | StreetDressing/Barrel | 0.95 | never | doesn't | ok |
| round_the_corner | night_lit | 15.3 | StreetDressing/Barrel | 0.00 | never | doesn't | ok |
| round_the_corner | night_out | 15.3 | StreetDressing/Barrel | 0.00 | never | doesn't | ok |
| through_window | day | 9.5 | Saloon/front_glass_55_145 (glass) | 1.00 | never | either | - |
| through_window | golden | 9.5 | Saloon/front_glass_55_145 (glass) | 0.95 | never | either | - |
| through_window | night_lit | 9.5 | Saloon/front_glass_55_145 (glass) | 0.00 | never | sees | MISSED |
| through_window | night_out | 9.5 | Saloon/front_glass_55_145 (glass) | 0.00 | never | doesn't | ok |
| through_doorway | day | 14.0 | clear | 1.00 | 0.60 | sees | ok |
| through_doorway | golden | 14.0 | clear | 0.95 | 0.60 | sees | ok |
| through_doorway | night_lit | 14.0 | clear | 0.00 | never | either | - |
| through_doorway | night_out | 14.0 | clear | 0.00 | never | doesn't | ok |
| through_batwings | day | 9.0 | clear | 1.00 | 0.60 | sees | ok |
| through_batwings | golden | 9.0 | clear | 0.95 | 0.60 | sees | ok |
| through_batwings | night_lit | 9.0 | clear | 0.00 | 4.33 | sees | slow |
| through_batwings | night_out | 9.0 | clear | 0.00 | 4.33 | either | - |
| inside_dark_room | day | 8.6 | clear | 1.00 | 0.73 | sees | ok |
| inside_dark_room | golden | 8.6 | clear | 0.95 | 0.73 | sees | ok |
| inside_dark_room | night_lit | 8.6 | clear | 0.00 | 4.73 | sees | slow |
| inside_dark_room | night_out | 8.6 | clear | 0.00 | 4.73 | doesn't | FALSE |
| gun_smoke | day | 8.0 | clear | 1.00 | 0.73 | doesn't | FALSE |
| gun_smoke | golden | 8.0 | clear | 0.95 | 0.73 | doesn't | FALSE |
| gun_smoke | night_lit | 8.0 | clear | 0.00 | never | doesn't | ok |
| gun_smoke | night_out | 8.0 | clear | 0.00 | never | doesn't | ok |
| blast_dust | day | 12.0 | clear | 1.00 | 0.73 | doesn't | FALSE |
| blast_dust | golden | 12.0 | clear | 0.95 | 0.87 | doesn't | FALSE |
| blast_dust | night_lit | 12.0 | clear | 0.00 | never | doesn't | ok |
| blast_dust | night_out | 12.0 | clear | 0.00 | never | doesn't | ok |

## Hearing

| case (game reach m) | listener | m | wall | heard | took it for | where (err m / deg) | knows who | verdicts |
|---|---|---|---|---|---|---|---|---|
| shot_in_saloon (350) | saloon_room | 5.1 |  | yes | gunshot | 0.6 / 3 | yes | hears it: ok, knows who made it: ok, can tell where (within 30 deg): ok |
| shot_in_saloon (350) | street_front | 13.1 | Saloon/facade_door_jamb1 (trim) | yes | gunshot | 1.4 / 6 | yes | hears it: ok, knows who made it: FALSE, can tell where (within 45 deg): ok |
| shot_in_saloon (350) | store_inside | 10.9 | Saloon/left_siding_c21_0 (board) | yes | gunshot | 1.7 / 8 | yes | hears it: ok, knows who made it: FALSE, can tell where (within 60 deg): ok |
| shot_in_saloon (350) | jail_inside | 25.8 | StreetDressing/Jail/front_siding_r10_1 (board) | yes | gunshot | 3.1 / 6 | yes | hears it: ok, knows who made it: FALSE |
| shot_in_saloon (350) | street_west_end | 52.8 | Telegraph/facade_corner1 (post) | yes | gunshot | 6.1 / 2 | yes | hears it: ok, knows who made it: FALSE, can tell where (within 45 deg): ok |
| shot_in_street (350) | saloon_room | 16.7 | Saloon/front_glass_55_145 (glass) | yes | gunshot | 1.1 / 4 | yes | hears it: ok, knows who made it: FALSE, can tell where (within 45 deg): ok |
| shot_in_street (350) | store_inside | 16.0 | Store/front_siding_r08_2 (board) | yes | gunshot | 1.6 / 2 | yes | hears it: ok, knows who made it: FALSE, can tell where (within 45 deg): ok |
| shot_in_street (350) | street_near | 10.0 |  | yes | gunshot | 0.5 / 2 | yes | hears it: ok, knows who made it: FALSE, can tell where (within 20 deg): ok |
| shot_in_street (350) | street_west_end | 45.0 |  | yes | gunshot | 5.4 / 6 | yes | hears it: ok, knows who made it: FALSE, can tell where (within 20 deg): ok |
| shout_in_street (45) | street_20m | 20.0 |  | yes | shout | 1.3 / 2 | yes | hears it: ok, can tell where (within 20 deg): ok |
| shout_in_street (45) | street_45m | 45.0 |  | yes | shout | 4.4 / 5 | yes | hears it: ok |
| shout_in_street (45) | street_60m | 60.0 |  | no |  |  |  | hears it: MISSED |
| shout_in_street (45) | store_inside | 16.0 | Store/front_siding_r09_2 (board) | yes | shout | 1.9 / 1 | yes | hears it: ok |
| shout_in_street (45) | saloon_back | 20.2 | Saloon/Props/@StaticBody3D@3923 | yes | shout | 2.3 / 4 | yes |  |
| steps_on_boards (6) | beside_2m | 4.4 |  | 6 steps | footsteps | 0.2 / 2 | yes | hears it: ok |
| steps_on_boards (6) | street_5m | 6.3 |  | 7 steps | footsteps | 0.5 / 2 | yes | hears it: ok |
| steps_on_boards (6) | street_9m | 9.8 |  | no |  |  |  | hears it: MISSED |
| steps_on_boards (6) | street_16m | 16.0 |  | no |  |  |  | hears it: ok |
| steps_on_dirt (6) | beside_2m | 4.7 |  | 7 steps | footsteps | 0.3 / 0 | yes |  |
| steps_on_dirt (6) | street_5m | 6.5 |  | 7 steps | footsteps | 0.6 / 1 | yes | hears it: FALSE |
| steps_on_dirt (6) | street_9m | 10.0 |  | no |  |  |  | hears it: ok |
| hammer_cocked (0) | behind_1_5m | 1.5 |  | no |  |  |  | hears it: MISSED |
| hammer_cocked (0) | room_4m | 4.2 |  | no |  |  |  | hears it: MISSED |
| hammer_cocked (0) | room_9m | 6.0 |  | no |  |  |  |  |
| running_on_dirt (13) | street_5m | 8.3 |  | 15 steps | footsteps | 0.5 / 1 | yes | hears it: ok |
| running_on_dirt (13) | street_12m | 13.8 |  | 7 steps | footsteps | 1.2 / 3 | yes |  |
| running_on_dirt (13) | jail_inside | 18.4 |  | no |  |  |  | hears it: ok |

## Search

| case | lost (truth) s | lost (Senses) s | delay s | last-known error at loss m | nearest to last-known m | nearest to his spot m | found again s after | gave up s after | leaks | verdicts |
|---|---|---|---|---|---|---|---|---|---|---|
| lost_round_corner_still | 6.75 | 6.68 | -0.07 | 0.4 | 2.2 | 5.6 | 13 | didn't | 1 | goes to where he last knew him (within 2 m): MISSED, knows he's lost him within 1.5 s: ok |
| lost_round_corner_moving | 6.75 | 6.68 | -0.07 | 0.4 | 1.5 | 7.4 | 13 | didn't | 1 | goes to where he last knew him (within 2 m): ok, knows he's lost him within 1.5 s: ok |
| lost_into_store | 7.50 | 7.48 | -0.02 | 0.4 | 3.7 | 10.4 | no | 27 | 2 | goes to where he last knew him (within 2 m): MISSED, knows he's lost him within 1.5 s: ok |
| lost_at_night | 2.50 | -1.00 | -1.00 | -1.0 | 1.4 | 1.2 | no | 21 | 1 | goes to where he last knew him (within 2 m): ok, sees him at all before he hides: ok |

## News

| case | person | t s | heard shot | saw who | knows who | who from the sound only | knows a man was hit | knows the hold-up | mood |
|---|---|---|---|---|---|---|---|---|---|
| saloon_shooting | witness | 1.0 | yes | yes | yes | no | yes | yes | COWERING |
| saloon_shooting | victim | 1.0 | yes | yes | yes | no | yes | yes | HANDS_UP |
| saloon_shooting | storekeeper | 1.0 | yes | no | yes | yes | no | no | COWERING |
| saloon_shooting | deputy | 1.0 | yes | no | yes | yes | no | no | COWERING |
| saloon_shooting | passerby | 1.0 | yes | no | yes | yes | no | no | CALM |
| saloon_shooting | witness | 5.0 | yes | yes | yes | no | yes | yes | COWERING |
| saloon_shooting | victim | 5.0 | yes | yes | yes | no | yes | yes | HANDS_UP |
| saloon_shooting | storekeeper | 5.0 | yes | no | yes | yes | no | no | COWERING |
| saloon_shooting | deputy | 5.0 | yes | no | yes | yes | no | no | COWERING |
| saloon_shooting | passerby | 5.0 | yes | no | yes | yes | no | no | CALM |
| saloon_shooting | witness | 30.0 | yes | yes | yes | no | yes | yes | SHAKEN |
| saloon_shooting | victim | 30.0 | yes | yes | yes | no | yes | yes | HANDS_UP |
| saloon_shooting | storekeeper | 30.0 | yes | no | yes | yes | no | no | SHAKEN |
| saloon_shooting | deputy | 30.0 | yes | no | yes | yes | no | no | SHAKEN |
| saloon_shooting | passerby | 30.0 | yes | no | yes | yes | no | no | CALM |
| saloon_shooting | witness | 90.0 | yes | yes | yes | no | yes | yes | CALM |
| saloon_shooting | victim | 90.0 | yes | yes | yes | no | yes | yes | HANDS_UP |
| saloon_shooting | storekeeper | 90.0 | yes | no | yes | yes | no | no | CALM |
| saloon_shooting | deputy | 90.0 | yes | no | yes | yes | no | no | CALM |
| saloon_shooting | passerby | 90.0 | yes | no | yes | yes | no | no | CALM |
| store_holdup | storekeeper | 1.0 | no | yes | yes | no | no | yes | SHAKEN |
| store_holdup | deputy | 1.0 | no | no | no | no | no | no | CALM |
| store_holdup | storekeeper | 30.0 | no | yes | yes | no | no | yes | CALM |
| store_holdup | deputy | 30.0 | no | no | no | no | no | no | CALM |
| store_holdup | storekeeper | 90.0 | no | yes | yes | no | no | yes | CALM |
| store_holdup | deputy | 90.0 | no | no | no | no | no | no | CALM |

## Leaks

| case | what he got | verdicts |
|---|---|---|
| far_outlaw_hears_a_hit | {"stance_to_player": "WARNING", "pressure": 0.4, "grudge": 0.4, "knows_who": true, "saw_player": false, "mood": "CALM"} | knows who: FALSE, stance to player: FALSE, pressure: FALSE |
| mate_falls_behind_wall | {"line": "Store/facade_porch_post2 (post)", "distance_m": 13.5, "knows_mate_down": true, "saw_mate": false, "fear_change": 0.23, "mood": "CALM"} | knows mate down: FALSE, fear change: FALSE |
| call_out_unseen | {"spot": [-10.0, 0.0, -8.09], "player_at": [2.0, 0.38, 9.0], "knew_player_before": false, "saw_player": false, "spot_dx_from_player_m": 12.0, "knows_who": false} | spot dx from player m: FALSE |
