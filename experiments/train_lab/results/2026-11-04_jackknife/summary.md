# Cars that jackknife come apart (Sean, #620)

Sean, on #620's fourth question: "if they're jack knifing make them come apart". Now two coupled
cars folded past `jackknife_deg` at their coupler (seen from above) come apart: the coupler's pin
shears, and both cars, if they're cars of boards, break into their front, back and roof, a tick
apart. The engine and tender are iron and stay whole (`TrainWreck._couplers`, `_fold`, `BREAKS`).

**The angle, 20 degrees (proposed):** the first round with 40 degrees broke nothing. Measured, the
step-5 wrecks fold 21-28 degrees at their worst coupler, and a car on the 120 m bend folds about 5.

**The 18 runs again** (`table.md`, `runs/`):

- Every derail now shears a coupler at its jackknife, from walking pace to 40 km/h: the train
  comes apart where it folds. That's mostly the engine and tender (the engine runs off to the side
  of the broken rail and the tender folds behind it).
- A car of boards breaks into sections where it's in the fold itself: an ore car at 40 km/h by
  night, the cars behind it sheared off whole.
- Even at walking pace the engine's sideways lurch shears the engine-tender coupler (nothing
  breaks: both are iron).
- The frames: every run inside #492's gate, worst 45 ms here (29 at Sean's), the longest slow spell
  0.05 s.

Test: `test_cars_that_jackknife_come_apart` (a coach folded 60 degrees: the coupler shears, both
cars break up).
