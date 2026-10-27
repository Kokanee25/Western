# The physics lab's falls, main (c1352a34) against step 4 (c69aa698, people threads on)

`python3 experiments/physics_lab/run.py --out=... --jobs=1` on each build, then every scenario's
`summary.json` compared whole but its frame times (`frame_ms*`, which are the clock's).

**151 of 151 falls identical.**

An earlier build of the second commit (98a9a919: the same arithmetic, the prepared state kept on
the man between ticks instead of taken once a tick) gave 150 of 151, the 151st `Q_rail_run_dead`;
that scenario lands two ways on main itself (settle 3.27 s or 4.27 s: run alone twice on each
build, main gave 4.27 then 3.27, step 4 3.27 twice), the railing's settle timed by the clock in
this lab, as step 2 found for `Q_rail_charge_front`.
