# Render CPU (light_views.gd --cpu, 1280x720, lavapipe; x0.65 for Sean's), #829

| view | before (#828) | round 2 (this) | merged with #826's windows |
|---|---|---|---|
| desk | 1.06 ms, 925 draws | 2.57 ms, 2789 draws | 2.54 ms, 2735 draws |
| dispensary | 1.02 ms, 692 draws | 2.81 ms, 3063 draws | 2.83 ms, 3057 draws |
| window | - | 1.64 ms, 1156 draws | 1.69 ms, 1177 draws |
| night | 2.03 ms, 2075 draws | 1.71 ms, 1819 draws (window shadows off by night) | 1.88 ms, 2140 draws |

Budget 4 ms. The day views' rise is the windows' shadows (their shadow maps redrawn as things in
them move). With shadows by night too the night view was 3.16 ms (3875 draws): off by night.
