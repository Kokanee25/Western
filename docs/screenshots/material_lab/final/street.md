# Main Street: what each variant costs to draw

Mean of 30 frames a view under lavapipe (CPU-side render time; Sean's GPU differs). A the game today, B the finish, C the final candidate.

| Light | View | Draws A / B / C | Primitives A / B / C | Render CPU ms A / B / C |
|---|---|---|---|---|
| noon | street_east | 2645 / 2943 / 3189 | 833875 / 1162811 / 1164539 | 5.89 / 7.07 / 6.80 |
| noon | street_west | 2374 / 2623 / 2821 | 785311 / 1065775 / 1068351 | 5.67 / 6.52 / 6.52 |
| noon | north_fronts | 1820 / 2043 / 2213 | 765361 / 1015041 / 1015873 | 4.18 / 4.43 / 4.72 |
| noon | south_fronts | 889 / 984 / 1045 | 318107 / 458447 / 458511 | 2.70 / 2.86 / 2.75 |
| noon | saloon_walk | 1277 / 1379 / 1448 | 631410 / 767634 / 768786 | 4.05 / 4.11 / 4.23 |
| golden | street_east | 3645 / 4086 / 4463 | 1050655 / 1482443 / 1484827 | 7.37 / 8.48 / 8.62 |
| golden | street_west | 3897 / 4337 / 4714 | 1236172 / 1644688 / 1648608 | 8.64 / 8.94 / 9.85 |
| golden | north_fronts | 1668 / 1886 / 2030 | 790160 / 1013136 / 1012464 | 5.77 / 6.03 / 6.42 |
| golden | south_fronts | 963 / 1072 / 1158 | 334877 / 494077 / 494077 | 4.01 / 3.90 / 4.12 |
| golden | saloon_walk | 4173 / 4639 / 5045 | 1434114 / 1873134 / 1877198 | 7.79 / 7.95 / 9.06 |

Whole street (visible meshes): A 1715 meshes, 533046 triangles, 839 materials; B 1848 meshes, 721322 triangles, 855 materials; C 1944 meshes, 722218 triangles, 867 materials
