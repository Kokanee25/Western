# Blind critic: ragdoll falls (judge_ps2_small, 33 sheets)

Judged only from the contact sheets (times 0, 0.18, 0.38, 0.68, 0.98, 1.48, 2.48, 3.98, 5.98 s). I zoomed every
sheet around the man (crops in `/tmp/claude-0/critic_crops/z/`). Each score is out of 10 and asks one question:
would this pass as real footage of a man falling? Where I quote "com y", "vmax" or flags, they come from the sheet's
own labels.

## 1. Scores

| Sheet | Score | Main fault | Hidden / out of frame |
|---|---|---|---|
| P_balcony_backwards_ball | 6 | Buckles straight down and ends sitting against the rail with his legs folded under him like a tailor. His hat vanishes between 1.48 and 2.48. | hidden: front (head above frame t≤0.38) |
| P_balcony_ball_back | 5 | He touches the rail, then jackknifes stiff-legged (0.98) and falls backward toward the shooter. One knee stays raised at rest. | hidden: back (head above frame t≤0.68) |
| P_balcony_blackout | 4 | The faint is a straight backward topple, rigid as a plank, with no knee buckle. He ends on his back with one knee propped up. | hidden: back (head above frame t≤0.68) |
| P_balcony_run_dead | 4 | His speed dies at once (vmax 4.1 to 0.7 by 0.37 s). He drops to his knees on the spot and ends sitting upright against the rail. | hidden: back and left (head and shoulders above frame t≤0.98) |
| P_bar_front_ball_back | 4 | His head is tipped back at the ceiling, then he backbends (0.68) into a limbo crouch (0.98) and falls flat away from the bar, toward the shooter. | |
| P_bar_side_ball_left | 6 | No sideways reaction to a hit from the left. He holds an all-fours crawling pose for 0.5 s (0.98 to 1.48), then flops prone. | hidden: front (legs behind the end of the bar from 2.48) |
| P_barrel_ball_left | 5 | No sideways reaction. He drops straight to his knees and stays folded, kneeling with his face on the floor, to the end. | hidden: left (behind the chair from 1.48) |
| P_chairs_ball_front | 4 | He folds forward into the shot and ends kneeling upright on his heels for 5 s: a corpse that kneels. He never touches a chair. | hidden: left (partly behind the chair from 0.98) |
| P_crates_ball_back | 4 | The same motion as the bar sheet: staring up, then a deep limbo backbend (0.98), then he falls backward onto the floor toward the shooter. | |
| P_flight_backwards_ball | 5 | He sits down on the top edge, then sleds head-first down the flight on his back with his legs stiff in the air (2.48). He ends on the floor beside the foot. | hidden: left (head above frame t≤0.38) |
| P_flight_side_ball | 4 | He is launched flat through the air over the steps (1.48, vmax 4.2), lands and slides. He is still creeping at 5.98 (flag never_settled). | |
| P_flight_top_ball_back | 4 | He curls into a ball on the landing (0.98 to 2.48), then is on the floor at the foot by 3.98, so the whole drop happens between frames (flag launch). | hidden: front, side and three (head and torso above frame t≤0.68) |
| P_flight_top_blackout | 6 | A good knee buckle, but a snap (vmax 4.2 at 0.98). He ends folded face-down at the landing edge. | hidden: front and left (head and torso above frame t≤0.68) |
| P_flight_top_dead_head | **2** | A head-shot man stays standing for 0.38 s and squats for about 1 s, then goes over head-first. He ends upside down: head on the steps, legs straight up in the air. He never settles. | hidden: front and left (head above frame t≤0.38) |
| P_hitch_ball_back | 7 | A good forward crumple: knees, then hands, then face-down, then he rolls onto his side. The only fault is that the knees-first drop is a bit tidy. There is **no hitching rail** in any view. | |
| P_hitch_run_dead | 6 | He carries his momentum, but pitches forward as a rigid plank (0.38) and lies stiff with legs together and arms at his sides. No hitching rail is visible. | |
| P_porch_edge_backwards_ball | 4 | He squats at the edge, then flips backward off the porch. One leg is left sticking up in the air at rest (flag sunk_into_world). | hidden: back (head and shoulders off the bottom edge from 1.48) |
| P_porch_edge_ball_back | 4 | Head tipped back, then a deep backward bridge with her head near her knees (0.98), then she kneels at the edge. She lands on the street flat and rigid as a board (flag bounce). | |
| P_porch_steps_blackout | 6 | A credible buckle and fold, but he holds a face-down kneel for about 1 s before rolling onto his side. His head ends draped over the step. | |
| P_table_ball_back | 5 | Head tipped back, a stiff-legged jackknife (0.68 to 0.98), then she sits down hard and falls back toward the shooter. | |
| P_table_blackout | 4 | He sinks back onto the chair and hangs there arched backward for about 1 s (0.98 to 1.48), then slides off. The chair never moves. One leg is raised at the end. | |
| S_oak_foot_backwards_ball | 6 | Plausible: he crumples to his knees, then onto his side at the foot of the stair. He sits in a squat too long (0.68 to 0.98). | |
| S_oak_mid_ball_back | 5 | Shot from behind, he falls backward down the stairs toward the shooter and stops on his back after 2 to 3 steps. | hidden: three (head above frame t≤0.68; behind the balusters throughout) |
| S_oak_mid_facing_up_ball | 6 | The best stair fall: he goes backward head-first down the flight and his hat bounces to the floor. He sleds rather than bumps, and is still creeping at 3.98. | hidden: back_left (head above frame t≤0.38; behind the balusters) |
| S_oak_top_backwards_ball | 5 | He folds forward and crouches, then goes over backward and sleds head-first about 1.4 m on his back. | hidden: back (head above frame t≤0.38) |
| S_oak_top_ball_back | 4 | He pitches forward and sticks on the first steps, head down and hips up, for 5 s. He travels less than 1 m. | hidden: front (upper body above frame t≤0.68) |
| S_oak_top_blackout | 6 | His knees go and he falls forward face-down onto the top steps, hat off. This one is good. | hidden: front (upper body above frame t≤0.68) |
| S_oak_top_dead_head | **3** | Killed outright, he crouches at the top for about 1 s, then rolls down in slow motion with his legs twisted sideways (3.98). He is still sliding at 5.98 (flags sunk_into_world, swing_past_limit). | hidden: front (head above frame t≤0.38) |
| S_oak_walk_end_run_dead | **3** | He jackknifes over the end rail (0.37 to 0.67), then springs back to standing (0.97). He sinks to his knees and stays kneeling upright against the rail. | |
| S_oak_walk_rail_ball_back | 6 | His head is tipped back before the hit. He doubles over, then sits down against the rail with his head back; the final pose is right. | partly behind the near balusters in left |
| S_oak_walk_rail_ball_front | 5 | She folds forward into the shot and ends in a face-down, hips-up kneel held for 3.5 s. | |
| S_oak_walk_rail_blackout | 6 | The faint starts as a rigid backward plank onto the rail (0.68 to 0.98), then he slumps well into a sit against the rail. | |
| S_oak_walk_rail_blast | **3** | The blast barely moves him: vmax 0.8 or less through 0.68 s and he stands almost still. Then he sags back onto the rail and sits down like a faint. Nothing throws him. | |

## 2. The five worst

**P_flight_top_dead_head (2)**
- 0 to 0.38 s: a man killed by a shot to the head is still standing straight.
- 0.68 to 1.48: he drops into a deep squat and holds it at the lip of the landing for nearly a second. Dead men don't squat.
- 2.48: he finally tips forward head-first, and his hat comes off.
- 3.98 to 5.98: he is jammed upside down, head and shoulders on the steps, legs straight up and splayed in the air like a handstand. He is still twitching at the end (never_settled, awake_at_end).

**S_oak_top_dead_head (3)**
- 0 to 0.38: standing after a head shot.
- 0.68 to 1.48: crouched and kneeling on the top step for about a second.
- 2.48 to 3.98: a slow-motion roll down the flight. At 3.98 his legs stick out sideways across the stair while his torso faces the other way.
- 5.98: still sliding (com y 2.10 to 1.63 between 3.98 and 5.98), curled against the left banister. There is no impact and no weight; he oozes down the stairs.

**S_oak_walk_end_run_dead (3)**
- 0 to 0.17: running to the railed end of the walkway.
- 0.37 to 0.67: he folds over the rail at the waist, head and arms hanging over the far side. That much is good.
- 0.97: he springs back upright and is standing again. The rail threw a dead man back onto his feet.
- 1.47 to 5.98: he sinks to his knees and stays kneeling bolt upright against the rail, then never settles.

**S_oak_walk_rail_blast (3)**
- 0 to 0.68: an explosion behind him and he barely sways (vmax 0.4 to 0.8).
- 0.98: a slow lean back against the rail.
- 1.48: he sits down against the rail, legs out.
- 2.48 to 5.98: he tips sideways to lie along the walkway against the rail.
- No throw, no stagger and no flying hat until he is down. It reads as a man fainting, not as a blast.

**P_porch_edge_ball_back (4)**
- 0.38: shot from behind, she tips her head back to stare at the sky.
- 0.68 to 0.98: a deep backward bridge, her head down near her knees, arched like a limbo dancer, before anything else moves.
- 1.48: she is kneeling at the porch edge, hands down.
- 2.48: she lies off the porch on the street, perfectly straight with legs together, like a dropped plank (flag bounce).
- The backbend is impossible for a wounded man, and the landing has no give.

(Close behind, also at 4: P_flight_top_ball_back drops the whole flight between two frames, and P_table_blackout hangs arched over a chair back.)

## 3. Faults that recur

| Fault | Count | Sheets |
|---|---|---|
| Head or upper body above the top of the frame while he stands, so the first half-second can't be judged | 14 | the balcony sheets (4), P_flight_backwards, P_flight_top (3), S_oak_mid (2), S_oak_top (4) |
| Goes down knees-first into a squat or kneel before falling (fine for faints, wrong for most kills and for head shots) | 17 | most P_ and S_ ball and dead sheets |
| Holds a crouch or kneel for 0.5 s or more while dead or limp | 7 | flight_top_dead_head, S_oak_top_dead_head, flight_top_ball_back (balled up), bar_side (all fours), porch_steps_blackout, flight_backwards (sits), S_oak_foot |
| Ends in a kneeling or "praying" pose (upright on his heels, or face-down with hips up) held to the end | 6 | barrel, chairs, S_oak_top_ball_back, S_oak_walk_end_run_dead, S_oak_walk_rail_ball_front, P_flight_top_blackout |
| Shot from behind but falls backward, toward the shooter | 5 of 10 ball_back sheets | balcony_ball_back, bar_front, crates, table_ball_back, S_oak_mid_ball_back |
| Head tipped back to stare at the sky before or as the hit lands | 5 | bar_front, crates, porch_edge_ball_back, table_ball_back, S_oak_walk_rail_ball_back |
| Backward bridge or limbo backbend | 3 | bar_front, crates, porch_edge_ball_back |
| Rigid plank: topples or lands straight-bodied with no bend | 4 | balcony_blackout, hitch_run_dead, porch_edge_ball_back, S_oak_walk_rail_blackout |
| Stiff-legged jackknife at the hips | 3 | balcony_ball_back, table_ball_back, S_oak_walk_end_run_dead |
| A leg or knee left raised in the air at rest | 6 | balcony_ball_back, balcony_blackout, porch_edge_backwards, table_ball_back, table_blackout, flight_top_dead_head (both legs) |
| Still visibly moving at 3.98 to 5.98 | 5 | flight_side, flight_top_dead_head, S_oak_top_dead_head, S_oak_mid_facing_up, S_oak_walk_end_run_dead |
| No sideways reaction to a hit from the left | 2 of 2 | bar_side, barrel |
| Running death loses all its momentum at once | 2 of 3 | balcony_run_dead, S_oak_walk_end_run_dead (hitch_run_dead is the exception) |
| On stairs: sleds on his back or sticks within about 1 m; never bumps or tumbles step by step | 6 of 11 stair sheets | flight_backwards, S_oak_mid_ball_back, S_oak_mid_facing_up, S_oak_top_backwards, S_oak_top_ball_back, S_oak_top_dead_head |
| Props never move (chairs, table, barrel, crates) | all prop sheets | |

## 4. How he meets the objects

**Stairs (P flights and the oak stair).**
- Nobody falls down a stair like a real man. There is no step-by-step bumping, no tumble and no limbs catching on the nosings.
- Backward falls sled head-first on the back and stop after 1 to 1.5 m (S_oak_mid_ball_back, S_oak_top_backwards, P_flight_backwards).
- Forward falls stick hips-up on the first steps (S_oak_top_ball_back).
- On the open P flight he is either launched clear (flight_side), dropped between frames (flight_top_ball_back) or jammed upside down (flight_top_dead_head).
- Faints at the top stay on the landing or fold onto the top steps, which is right.
- Nobody ever reaches for or hits the banister.

**Rails (the balcony rail and the walkway rail).**
- The rail works best as a backrest. Sitting slumped against it is the most convincing ending in the set (walk_rail_ball_back, walk_rail_blackout, balcony_backwards).
- The moment of contact is wrong. He bounces off the rail and falls the other way (balcony_ball_back), springs back to standing from a fold over it (walk_end_run_dead), or leans on it as a rigid plank (walk_rail_blackout).
- Nobody goes over the 1 m rail, which is fine, but nobody hangs over it either.

**Tables and chairs.**
- No one touches the table.
- Chairs never move, tip or slide. One may be nudged in table_ball_back.
- In table_blackout he hangs arched backward over a chair that stays rock-solid, then slides off.
- In chairs_ball_front he kneels between the chairs without touching them.

**Barrel.** He collapses beside it with a shoulder against it. The barrel doesn't budge. He ends in a kneeling fold.

**Bar and crates.**
- He pushes his hips into the bar face or the crate stack, backbends over nothing and falls away from them, never down them.
- At the bar side she drops to all fours alongside the bar face.
- The stacked crates never shift, though he leans his full weight on them.

**Hitching rail.** It is not in any view of either hitch sheet, so there is no contact to judge. Both men fall on open ground.

**Porch edge and steps.**
- Going off the edge looks either like a backward flip with a leg left propped up on the porch, or like a rigid board landing.
- The porch-steps faint ending, head draped over the step edge, is good.

## 5. Mean score

The scores sum to 157 over 33 sheets, a **mean of 4.8 out of 10**. The best is P_hitch_ball_back (7). The worst is
P_flight_top_dead_head (2).

Out of frame or hidden in at least one view: **18 sheets**. In 14 the head or upper body is above the frame while he
stands; in 4 he is hidden behind the bar, a chair or the bottom edge.
