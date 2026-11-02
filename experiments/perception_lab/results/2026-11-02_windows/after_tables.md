## Counts

| group | runs | judged | as expected | missed | false | slow | leaks (sampled) |
|---|---|---|---|---|---|---|---|
| sight | 60 | 50 | 29 | 2 | 4 | 15 | 0 |
| hearing | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| search | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| news | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| leaks | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **all** | 60 | 50 | 29 | 2 | 4 | 15 | 0 |

## Sight

| case | light | distance m | line (Senses' ray meets) | sky (Senses) | on him, lux | spotted s | expected | verdict |
|---|---|---|---|---|---|---|---|---|
| street_10m | day | 10.0 | clear | 1.00 | 1e+04 | 0.65 | sees | ok |
| street_10m | golden | 10.0 | clear | 0.95 | 4.97e+03 | 0.65 | sees | ok |
| street_10m | night_lit | 10.0 | clear | 0.00 | 0.02 | 5.98 | sees | slow |
| street_10m | night_out | 10.0 | clear | 0.00 | 0.02 | 5.98 | sees | slow |
| street_25m | day | 25.0 | clear | 1.00 | 1e+04 | 0.88 | sees | ok |
| street_25m | golden | 25.0 | clear | 0.95 | 4.97e+03 | 0.88 | sees | ok |
| street_25m | night_lit | 25.0 | clear | 0.00 | 0.02 | never | either | - |
| street_25m | night_out | 25.0 | clear | 0.00 | 0.02 | never | either | - |
| street_45m | day | 45.2 | clear | 1.00 | 1e+04 | never | sees | MISSED |
| street_45m | golden | 45.2 | clear | 0.95 | 4.97e+03 | never | sees | MISSED |
| street_45m | night_lit | 45.2 | clear | 0.00 | 0.02 | never | either | - |
| street_45m | night_out | 45.2 | clear | 0.00 | 0.02 | never | doesn't | ok |
| under_lamp_20m | day | 18.8 | clear | 1.00 | 2.5e+03 | 1.15 | sees | slow |
| under_lamp_20m | golden | 18.8 | clear | 0.95 | 1.25e+03 | 1.15 | sees | slow |
| under_lamp_20m | night_lit | 18.8 | clear | 0.00 | 11.2 | 3.02 | sees | slow |
| under_lamp_20m | night_out | 18.8 | clear | 0.00 | 0.005 | never | either | - |
| crouched_dark_15m | day | 15.1 | clear | 1.00 | 1e+04 | 1.72 | sees | slow |
| crouched_dark_15m | golden | 15.1 | clear | 0.95 | 4.97e+03 | 1.72 | sees | slow |
| crouched_dark_15m | night_lit | 15.1 | clear | 0.00 | 0.02 | never | doesn't | ok |
| crouched_dark_15m | night_out | 15.1 | clear | 0.00 | 0.02 | never | doesn't | ok |
| behind_back | day | 5.0 | clear | 1.00 | 1e+04 | never | doesn't | ok |
| behind_back | golden | 5.0 | clear | 0.95 | 4.97e+03 | never | doesn't | ok |
| behind_back | night_lit | 5.0 | clear | 0.00 | 0.02 | never | doesn't | ok |
| behind_back | night_out | 5.0 | clear | 0.00 | 0.02 | never | doesn't | ok |
| side_walker | day | 7.1 | clear | 1.00 | 5e+03 | 4.92 | sees | slow |
| side_walker | golden | 7.1 | clear | 0.95 | 2.5e+03 | 4.92 | sees | slow |
| side_walker | night_lit | 7.1 | clear | 0.00 | 14 | 5.45 | either | - |
| side_walker | night_out | 7.1 | clear | 0.00 | 0.01 | never | either | - |
| behind_wall | day | 13.5 | Store/front_siding_r09_1 (board) | 1.00 | 300 | never | doesn't | ok |
| behind_wall | golden | 13.5 | Store/front_siding_r09_1 (board) | 0.95 | 150 | never | doesn't | ok |
| behind_wall | night_lit | 13.5 | Store/front_siding_r09_1 (board) | 0.00 | 1.03 | never | doesn't | ok |
| behind_wall | night_out | 13.5 | Store/front_siding_r09_1 (board) | 0.00 | 0.0006 | never | doesn't | ok |
| round_the_corner | day | 15.3 | StreetDressing/Barrel1/stave9 (post) | 1.00 | 1e+04 | never | doesn't | ok |
| round_the_corner | golden | 15.3 | StreetDressing/Barrel1/stave9 (post) | 0.95 | 4.97e+03 | never | doesn't | ok |
| round_the_corner | night_lit | 15.3 | StreetDressing/Barrel1/stave9 (post) | 0.00 | 0.02 | never | doesn't | ok |
| round_the_corner | night_out | 15.3 | StreetDressing/Barrel1/stave9 (post) | 0.00 | 0.02 | never | doesn't | ok |
| through_window | day | 9.5 | Saloon/front_glass_55_145 (glass) | 1.00 | 300 | 3.32 | either | - |
| through_window | golden | 9.5 | Saloon/front_glass_55_145 (glass) | 0.95 | 167 | 3.32 | either | - |
| through_window | night_lit | 9.5 | Saloon/front_glass_55_145 (glass) | 0.00 | 35 | 1.18 | sees | slow |
| through_window | night_out | 9.5 | Saloon/front_glass_55_145 (glass) | 0.00 | 0.0006 | never | doesn't | ok |
| through_doorway | day | 14.0 | clear | 1.00 | 300 | 1.18 | sees | slow |
| through_doorway | golden | 14.0 | clear | 0.95 | 149 | 1.18 | sees | slow |
| through_doorway | night_lit | 14.0 | clear | 0.00 | 1.53 | 1.18 | either | - |
| through_doorway | night_out | 14.0 | clear | 0.00 | 0.0006 | never | doesn't | ok |
| through_batwings | day | 9.0 | clear | 1.00 | 300 | 0.65 | sees | ok |
| through_batwings | golden | 9.0 | clear | 0.95 | 150 | 0.65 | sees | ok |
| through_batwings | night_lit | 9.0 | clear | 0.00 | 6.31 | 0.65 | sees | ok |
| through_batwings | night_out | 9.0 | clear | 0.00 | 0.0006 | never | either | - |
| inside_dark_room | day | 8.6 | clear | 1.00 | 300 | 1.18 | sees | slow |
| inside_dark_room | golden | 8.6 | clear | 0.95 | 159 | 1.18 | sees | slow |
| inside_dark_room | night_lit | 8.6 | clear | 0.00 | 28.7 | 1.18 | sees | slow |
| inside_dark_room | night_out | 8.6 | clear | 0.00 | 0.0006 | never | doesn't | ok |
| gun_smoke | day | 8.0 | clear | 1.00 | 1e+04 | 0.65 | doesn't | FALSE |
| gun_smoke | golden | 8.0 | clear | 0.95 | 4.97e+03 | 0.65 | doesn't | FALSE |
| gun_smoke | night_lit | 8.0 | clear | 0.00 | 0.02 | never | doesn't | ok |
| gun_smoke | night_out | 8.0 | clear | 0.00 | 0.02 | never | doesn't | ok |
| blast_dust | day | 12.0 | clear | 1.00 | 1e+04 | 1.18 | doesn't | FALSE |
| blast_dust | golden | 12.0 | clear | 0.95 | 4.97e+03 | 1.18 | doesn't | FALSE |
| blast_dust | night_lit | 12.0 | clear | 0.00 | 0.02 | never | doesn't | ok |
| blast_dust | night_out | 12.0 | clear | 0.00 | 0.02 | never | doesn't | ok |
