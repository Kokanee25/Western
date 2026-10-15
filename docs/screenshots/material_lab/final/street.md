# Main Street: what each variant costs to draw

Mean of 30 frames a view under lavapipe (CPU-side render time; Sean's GPU differs). A the game today, B the finish, C the final candidate.

| Light | View | Draws A / B / C | Primitives A / B / C | Render CPU ms A / B / C |
|---|---|---|---|---|
| noon | street_east | 2645 / 2923 / 3168 | 833875 / 1162475 / 1164203 | 5.89 / 6.96 / 7.08 |
| noon | street_west | 2374 / 2606 / 2806 | 785311 / 1065519 / 1068095 | 5.67 / 6.91 / 6.76 |
| noon | north_fronts | 1820 / 2027 / 2197 | 765361 / 1014785 / 1015617 | 4.18 / 5.17 / 4.73 |
| noon | south_fronts | 889 / 981 / 1042 | 318107 / 458399 / 458463 | 2.70 / 2.79 / 2.96 |
| noon | saloon_walk | 1277 / 1375 / 1444 | 631410 / 767570 / 768722 | 4.05 / 4.15 / 4.14 |
| golden | street_east | 3645 / 4052 / 4429 | 1050655 / 1481899 / 1484283 | 7.37 / 8.51 / 8.67 |
| golden | street_west | 3897 / 4305 / 4682 | 1236172 / 1644176 / 1648096 | 8.64 / 10.17 / 9.86 |
| golden | north_fronts | 1668 / 1875 / 2018 | 790160 / 1012960 / 1012288 | 5.77 / 6.05 / 6.45 |
| golden | south_fronts | 963 / 1067 / 1153 | 334877 / 493997 / 493997 | 4.01 / 4.39 / 4.29 |
| golden | saloon_walk | 4173 / 4605 / 5012 | 1434114 / 1872574 / 1876638 | 7.79 / 8.77 / 10.98 |

Whole street (visible meshes): A 1715 meshes, 533046 triangles, 839 materials; B 1839 meshes, 721034 triangles, 855 materials; C 1935 meshes, 721930 triangles, 867 materials
