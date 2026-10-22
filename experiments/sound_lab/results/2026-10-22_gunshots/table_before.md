| scenario | dist m | peak dBFS | LUFS max | onset s | length s | decay20 s | C50 dB | tail dB | centroid Hz | sounds |
|---|---|---|---|---|---|---|---|---|---|---|
| revolver_saloon_0 | 0.0 | -3.9 | -18.6 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_saloon_2 | 2.0 | -4.5 | -18.6 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_saloon_20 | 19.92 | -9.0 | -22.7 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_saloon_80 | 79.0 | -21.8 | -35.4 | 0.02 | 2.02 | 0.27 | -2.1 | -7.7 | 196 | cock, gunshot |
| revolver_saloon_door7 | 7.02 | -4.8 | -18.6 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_saloon_wall7 | 7.05 | -4.8 | -18.6 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_street_0 | 0.0 | -3.9 | -18.6 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_street_2 | 2.0 | -4.7 | -18.6 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_street_20 | 20.0 | -9.0 | -22.7 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_street_7 | 7.0 | -4.8 | -18.6 | 0.02 | 2.02 | 0.27 | -1.6 | -7.9 | 318 | cock, gunshot |
| revolver_street_80 | 80.0 | -22.0 | -35.5 | 0.02 | 2.02 | 0.27 | -2.1 | -7.7 | 195 | cock, gunshot |
| shotgun_saloon_0 | 0.0 | -2.9 | -14.2 | 0.01 | 1.98 | 0.27 | -7.0 | -3.3 | 786 | cock, shotgun, timber_crack |
| shotgun_saloon_2 | 2.0 | -2.3 | -14.2 | 0.01 | 1.98 | 0.27 | -7.0 | -3.3 | 785 | cock, shotgun, timber_crack |
| shotgun_saloon_20 | 19.92 | -8.1 | -21.5 | 0.01 | 2.02 | 0.31 | -3.4 | -5.4 | 433 | cock, shotgun, timber_crack |
| shotgun_saloon_80 | 79.0 | -21.3 | -33.7 | 0.01 | 2.02 | 0.38 | -4.5 | -4.7 | 240 | cock, shotgun, timber_crack |
| shotgun_saloon_door7 | 7.02 | -4.0 | -16.7 | 0.01 | 2.02 | 0.38 | -4.3 | -4.7 | 492 | cock, shotgun, timber_crack |
| shotgun_saloon_wall7 | 7.05 | -4.0 | -15.5 | 0.01 | 2.02 | 0.38 | -5.5 | -3.9 | 776 | cock, shotgun, timber_crack |
| shotgun_street_0 | 0.0 | -2.9 | -18.6 | 0.01 | 2.02 | 0.36 | -1.6 | -7.3 | 708 | cock, shotgun |
| shotgun_street_2 | 2.0 | -3.9 | -18.6 | 0.01 | 2.02 | 0.36 | -1.6 | -7.3 | 708 | cock, shotgun |
| shotgun_street_20 | 20.0 | -8.1 | -22.7 | 0.01 | 2.02 | 0.36 | -1.6 | -7.3 | 708 | cock, shotgun |
| shotgun_street_7 | 7.0 | -4.0 | -18.6 | 0.01 | 2.02 | 0.36 | -1.6 | -7.3 | 708 | cock, shotgun |
| shotgun_street_80 | 80.0 | -21.4 | -35.9 | 0.01 | 2.02 | 0.36 | -2.0 | -7.1 | 383 | cock, shotgun |

```
{
 "revolver_street_falloff_db_per_doubling": -3.2,
 "revolver_street_delay": {
  "2": {
   "heard_after_s": 0.02,
   "sound_would_take_s": 0.006
  },
  "7": {
   "heard_after_s": 0.02,
   "sound_would_take_s": 0.02
  },
  "20": {
   "heard_after_s": 0.02,
   "sound_would_take_s": 0.058
  },
  "80": {
   "heard_after_s": 0.02,
   "sound_would_take_s": 0.233
  }
 },
 "revolver_saloon_falloff_db_per_doubling": -3.0,
 "revolver_saloon_delay": {
  "2": {
   "heard_after_s": 0.02,
   "sound_would_take_s": 0.006
  },
  "20": {
   "heard_after_s": 0.02,
   "sound_would_take_s": 0.058
  },
  "80": {
   "heard_after_s": 0.02,
   "sound_would_take_s": 0.23
  }
 },
 "revolver_inside_vs_out_at_2m": {
  "lufs_max": [
   -18.6,
   -18.6
  ],
  "decay20_s": [
   0.27,
   0.27
  ],
  "c50_db": [
   -1.6,
   -1.6
  ],
  "tail_db": [
   -7.9,
   -7.9
  ],
  "length_s": [
   2.02,
   2.02
  ],
  "centroid_hz": [
   318,
   318
  ]
 },
 "revolver_open_door_wall_at_7m": {
  "distance_m": [
   7.0,
   7.02,
   7.05
  ],
  "lufs_max": [
   -18.6,
   -18.6,
   -18.6
  ],
  "centroid_hz": [
   318,
   318,
   318
  ]
 },
 "shotgun_street_falloff_db_per_doubling": -3.2,
 "shotgun_street_delay": {
  "2": {
   "heard_after_s": 0.01,
   "sound_would_take_s": 0.006
  },
  "7": {
   "heard_after_s": 0.01,
   "sound_would_take_s": 0.02
  },
  "20": {
   "heard_after_s": 0.01,
   "sound_would_take_s": 0.058
  },
  "80": {
   "heard_after_s": 0.01,
   "sound_would_take_s": 0.233
  }
 },
 "shotgun_saloon_falloff_db_per_doubling": -3.5,
 "shotgun_saloon_delay": {
  "2": {
   "heard_after_s": 0.01,
   "sound_would_take_s": 0.006
  },
  "20": {
   "heard_after_s": 0.01,
   "sound_would_take_s": 0.058
  },
  "80": {
   "heard_after_s": 0.01,
   "sound_would_take_s": 0.23
  }
 },
 "shotgun_inside_vs_out_at_2m": {
  "lufs_max": [
   -18.6,
   -14.2
  ],
  "decay20_s": [
   0.36,
   0.27
  ],
  "c50_db": [
   -1.6,
   -7.0
  ],
  "tail_db": [
   -7.3,
   -3.3
  ],
  "length_s": [
   2.02,
   1.98
  ],
  "centroid_hz": [
   708,
   785
  ]
 },
 "shotgun_open_door_wall_at_7m": {
  "distance_m": [
   7.0,
   7.02,
   7.05
  ],
  "lufs_max": [
   -18.6,
   -16.7,
   -15.5
  ],
  "centroid_hz": [
   708,
   492,
   776
  ]
 }
}
```
