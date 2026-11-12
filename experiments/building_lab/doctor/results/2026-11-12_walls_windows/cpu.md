# Render CPU and draws (#826; light_views.gd --cpu, 1280x720, lavapipe; x0.65 for Sean's)

## after (round 1 build; the round 2 change only closes board gaps)
window: render CPU median 1.15 ms here, 0.74 at Sean's (x0.65); 294 draws
front_gold: render CPU median 3.52 ms here, 2.29 at Sean's (x0.65); 1146 draws

## Draw calls in the rendered frame (before -> after)
window: 287 -> 292
front_gold: 967 -> 1007 (the panes: 14 in the building before, 52 after; glass isn't batched)

## The lab's count (tests/test_building_doctor.gd, Checks.draw_calls)
before: batches 98, own meshes 60, total 158
after: batches 97, own meshes 98, total 195
