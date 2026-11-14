# Materials judge: 2026-11-12_floor_furniture_r1

Blind judgment against `docs/concept/judge/MATERIAL.md` (floors and furniture, #825). Yardstick:
the six AAA screenshots (RDR2 street/saloon boards, banisters and bar; Hunt's dark boards; KCD2's
timber). Crop boxes are `x y w h` in the named file's own pixels (near and saloon_night 1400x780,
far 560x360).

**Known light fault, noted once and not counted:** the saw-toothed sun shadow is visible under
every chest's top overhang (e.g. FN1_new_near `150 120 890 30`). At noon it also shows as a
rope-like serration in the floor's board gaps (FL1_old_near `0 380 1300 400`). Those gaps are clean
by lamplight (FL1_old_saloon_night), so it is the light, not the floor.

---

## FL1: fir and pine floor boards, oiled, worn where feet go

### FL1_new
| check | result | evidence |
|---|---|---|
| 1 Real stuff | **FAIL** | FL1_new_near `270 560 1060 60`: big, high-contrast cathedral loops at the same strength on nearly every board, pale on tan. It reads as a printed laminate or a deck stain, not oiled fir. By lamplight the same loops glow orange (FL1_new_saloon_night `270 560 1060 60`). |
| 2 Age reads | see set | |
| 3 No tile tells | **FAIL** | FL1_new_near `100 440 520 330`: the nails are blue-grey dots in perfectly regular rows, two to a joist line, reading as dots printed on. Iron nail heads in a floor are dark. |
| 4 Board to board | **FAIL** | FL1_new_near `0 440 1350 330`: every board is the same pale tan. Only the loops' placement changes, with no heart and sap difference and no board darker or redder than the next. |
| 5 Edges and joints | **FAIL** | FL1_new_far `0 306 560 12`: the board joint shows as a bright orange dashed line across the whole floor. At 1 m the joints are thin, clean dark lines (acceptable). |
| 6 Holds at distance | **FAIL** | FL1_new_far `0 220 560 140`: a flat orange sheet with the grain smoothed away and only the dashed joints left. |

Grade: **game**

### FL1_few
| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | Fir/pine figure with knots (FL1_few_near `620 640 90 50`, `1060 580 90 50`), oiled brown. It reads as a floor. |
| 2 Age reads | see set | |
| 3 No tile tells | **FAIL** | FL1_few_near `380 380 140 400`: a column of bright white nail dots, evenly spaced. |
| 4 Board to board | PASS | Boards differ in figure and slightly in tone; the lengths and butt joints vary. The tone spread is still narrow. |
| 5 Edges and joints | **FAIL** | FL1_few_far `0 285 560 25`: the same bright orange dashed joint lines at 5 m. |
| 6 Holds at distance | **FAIL** | FL1_few_far `0 220 560 140`: the floor goes to a dark red-brown wash, and the dashed lines are the only detail left. |

Grade: **game**

### FL1_old
| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | It reads as oiled softwood boards with open gaps between them. |
| 2 Age reads | see set | |
| 3 No tile tells | **FAIL** | FL1_old_near `640 420 60 330`: bright white nail dots in rows. |
| 4 Board to board | PASS | Grain contrast and tone vary from board to board (FL1_old_near `0 520 1300 160`). |
| 5 Edges and joints | **FAIL** | FL1_old_far `0 260 560 65`: several bright orange dashed joint lines, worse than the younger floors. |
| 6 Holds at distance | **FAIL** | Same box: the stripes of dashes become the floor's main pattern at 5 m. |

Grade: **game**

### FL1 set: Age reads, **FAIL**
- New → a few years: clear (a pale tan raw floor becomes an oiled brown one with a worn path from the doorway).
- A few years → old: barely different. The same tone and the same path haze sit in the same place
  (FL1_few_near `0 380 650 300` against FL1_old_near `0 380 650 300`). Old adds only wider gaps.
- The worn path is a soft whitish fog laid over the boards. It ignores the board edges and the
  grain, and reads as a smear more than feet wearing the oil off.
- There is no darker, dustier band along the wall (FL1_old_near `0 320 1150 60` is as clean as
  mid-room).

Best age: **few**.
**The one change:** make the board joints dark gaps that stay dark at distance. The bright orange
dashed lines at 5 m are the floor's loudest tell in every age. Next after that: dark iron nail
heads, and an old floor that is darker and grimier at the wall.

---

## FN1: oak, straight-grained, varnished (office furniture)

### FN1_new
| check | result | evidence |
|---|---|---|
| 1 Real stuff | **FAIL** | FN1_new_near `240 460 700 150`: a plain-sawn softwood flame and cathedral figure, with no ray fleck, no open-pore lines and no straight grain. It reads as a stock "wood" veneer or laminate, pine-coloured, not oak. |
| 2 Age reads | see set | |
| 3 No tile tells | PASS | No repeat or seam found on the faces. The top is soft and almost figureless (FN1_new_near `100 0 1000 100`) but not blocky. |
| 4 Board to board | PASS | Each drawer front has its own figure and contrast. |
| 5 Edges and joints | **FAIL** | FN1_new_near `330 305 550 20`: a continuous pale beaded line runs along every rail arris, like a highlight drawn on rather than a worn edge. It is there on the new piece too. |
| 6 Holds at distance | **FAIL** | FN1_new_far `75 240 310 120`: the lower drawers go to busy, swirly orange figure while the upper ones are flat. It reads as an orange laminate cabinet. |

Grade: **game**

### FN1_few
| check | result | evidence |
|---|---|---|
| 1 Real stuff | **FAIL** | FN1_few_near `240 460 700 150`: the same non-oak flame figure, a little darker. |
| 2 Age reads | see set | |
| 3 No tile tells | PASS | |
| 4 Board to board | PASS | |
| 5 Edges and joints | **FAIL** | FN1_few_near `330 305 550 20`: the same pale piped line on the arrises. |
| 6 Holds at distance | **FAIL** | FN1_few_far `75 240 310 120`: busy orange swirl on the lower drawers. |

Grade: **game**

### FN1_old
| check | result | evidence |
|---|---|---|
| 1 Real stuff | **FAIL** | The same non-oak figure (FN1_old_near `240 460 700 150`). |
| 2 Age reads | see set | |
| 3 No tile tells | **FAIL** | FN1_old_near `150 130 880 170`: a network of thin dark squiggly outlines across the drawer fronts, like a map. It reads as a crackle pattern stamped over the wood, not as varnish checking along the grain. |
| 4 Board to board | PASS | |
| 5 Edges and joints | **FAIL** | FN1_old_near `330 305 550 20`: the piped arris line, the same as when new. The edges are not rubbed through. |
| 6 Holds at distance | **FAIL** | FN1_old_far `75 160 310 160`: a red-orange swirl over three drawers. |

Grade: **fake**

### FN1 set: Age reads, **FAIL**
New and a few years are only a shade apart. Old adds the stamped crackle and a faint pale halo
round the pulls (FN1_old_near `360 200 80 60`). There is no rub-through on the edges or the top's
nosing, no grease darkening round the pulls and no dust on the top.
Best age: **new**.
**The one change:** replace the figure with real quartersawn or rift oak (straight dark pore lines
with ray fleck), dulled under the varnish. As it stands it is the wrong wood.

---

## FN2: painted pine, slate grey-green oil paint

### FN2_new
| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | A paint film with the pine grain raised through it, and the chips show bare wood under a film edge. The colour reads more teal-blue than grey-green at noon but is believable. |
| 2 Age reads | see set | |
| 3 No tile tells | PASS | |
| 4 Board to board | PASS | |
| 5 Edges and joints | **FAIL** | FN2_new_near `330 305 550 20`: a bright blue-grey line along each rail arris, like piping drawn on, not a paint edge catching light. |
| 6 Holds at distance | PASS | FN2_new_far: it reads as an olive-painted chest. The row of chips along the top's underside is slightly too regular (FN2_new_far `75 85 310 10`). |

Grade: **game**

### FN2_few
| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | |
| 2 Age reads | see set | |
| 3 No tile tells | PASS | The chips are scattered fairly evenly over the faces (FN2_few_near `480 630 320 60`). That is close to a sprinkle, but not a pattern. |
| 4 Board to board | PASS | |
| 5 Edges and joints | **FAIL** | FN2_few_near `330 305 550 20`: the same piped arris line. |
| 6 Holds at distance | PASS | |

Grade: **game**

### FN2_old
| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | Paint lost in strips along the rails and edges, with film edges. It reads as paint on wood. |
| 2 Age reads | see set | |
| 3 No tile tells | PASS | The top's mottled clouding (FN2_old_near `100 0 1000 100`) is close to smear, but acceptable. |
| 4 Board to board | PASS | |
| 5 Edges and joints | **FAIL** | FN2_old_near `330 305 550 20`: the piped line is still there under the chipping. |
| 6 Holds at distance | PASS | FN2_old_far: edge loss and pull wear read at 5 m. This is the best far view of the round. |

Grade: **game** (the best piece in the round)

### FN2 set: Age reads, **FAIL**
The progression is clear (few chips → many → edges and pulls worn through). New is not a sound
coat, though: it is already chipped along the rails (FN2_new_near `290 285 600 30`, `730 440 80 30`).
On the old piece the wear under each pull is a flat cut-out patch of fresh orange wood
(FN2_old_near `370 225 60 35`, `790 215 60 35`). It reads as a decal, with no feathered rub, no
grease darkening and the exposed wood not aged.
Best age: **old**.
**The one change:** wear at the pulls and arrises as a rubbed gradient. The paint should thin to
primer and then to darkened, greasy wood, not hard-edged bare patches. And keep the new coat
unbroken.

---

## FN3: black walnut, varnished (the room's good piece)

### FN3_new
| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | A chocolate-brown, fine-figured hardwood under varnish. It reads as walnut-ish at 1 m, if uniformly: every drawer carries the same fine wiggle (FN3_new_near `240 470 700 140`). |
| 2 Age reads | see set | |
| 3 No tile tells | **FAIL** | FN3_new_near `150 0 900 100`: large soft purple-grey cloud blotches across a new top. They read as a smear (possibly a reflection, but they sit like a stain). |
| 4 Board to board | PASS | |
| 5 Edges and joints | **FAIL** | FN3_new_near `330 305 550 20`: a lavender-grey piped line along every rail arris. |
| 6 Holds at distance | PASS | FN3_new_far holds as a dark varnished chest. The swirl on drawer 3 (`80 245 300 75`) is busy but not shimmering. |

Grade: **game**

### FN3_few
| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | |
| 2 Age reads | see set | |
| 3 No tile tells | PASS | |
| 4 Board to board | PASS | |
| 5 Edges and joints | **FAIL** | FN3_few_near `330 305 550 20`: the same piped arris line. |
| 6 Holds at distance | PASS | |

Grade: **game**

### FN3_old
| check | result | evidence |
|---|---|---|
| 1 Real stuff | PASS | |
| 2 Age reads | see set | |
| 3 No tile tells | **FAIL** | FN3_old_near `150 140 880 160`: a faint network of dark squiggly crack outlines on the drawer fronts, the same stamped crackle as FN1_old. |
| 4 Board to board | PASS | |
| 5 Edges and joints | **FAIL** | FN3_old_near `330 305 550 20`: a crisp piped line on the arrises, which are not worn at all. |
| 6 Holds at distance | PASS | |

Grade: **game**

### FN3 set: Age reads, **FAIL**
The three ages are nearly the same chest. Only a slight lightening of the top and the faint
crackle on the old one tell them apart, with a faint dark halo at the old pulls
(FN3_old_near `360 200 80 60`). Nothing is rubbed through on the edges, nothing dulled in patches
where hands go, and there is no dust on the top.
Best age: **few**.
**The one change:** real use wear. Rub the varnish through to paler wood on the top's nosing and
the drawer arrises, darken the wood round the pulls, and dull the top in patches. At the moment the
ages can't be told apart.

---

## Summary

| swatch | new | few | old | best age | worst remaining tell |
|---|---|---|---|---|---|
| FL1 floor (fir/pine, oiled) | game | game | game | few | bright orange dashed joint lines at 5 m; white dot nails; few ≈ old |
| FN1 oak, varnished | game | game | fake | new | softwood flame figure, not oak (reads as laminate); stamped crackle when old |
| FN2 painted pine | game | game | game | old | pull wear as hard decal patches; new already chipped; piped arrises |
| FN3 walnut, varnished | game | game | game | few | ages indistinguishable (no use wear); piped arrises |

Shared by all three chests: a pale piped line along every drawer-rail arris, the same on new and
old, that reads as drawn on.
