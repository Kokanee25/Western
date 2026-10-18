# The CMU walk and run (an experiment)

Sean (2026-10-17): "merge the falls then do the CMU walk let's just experiment with it".

People walk and run by motion capture instead of `_gait_overlay`'s swinging sines:
- a walk (CMU 35_01) and a run (35_17), one subject, retargeted onto our rig;
- one stride each, sampled 40 times from a left heel strike, as each pivot's quaternion from its parent's;
- the stride's length is scaled to our leg, and the loop is advanced by the ground covered (his planted foot stays planted);
- the hips ride at the capture's height (a run leaves the ground).

It's off unless switched on: `HumanBody.mocap_gait`, or the lab's `--mocap`.

    experiments/mocap_walk/fetch.sh                      # the BVH files into build/cmu/ (not in git)
    godot --headless -s res://experiments/mocap_walk/rig_rest.gd | grep '^RIG ' | cut -c5- > experiments/mocap_walk/rig_rest.json
    python3 experiments/mocap_walk/retarget.py build/cmu/35_01.bvh --gait=walk --out=experiments/mocap_walk/clips/walk.json
    python3 experiments/mocap_walk/retarget.py build/cmu/35_17.bvh --gait=run --out=experiments/mocap_walk/clips/run.json
    python3 experiments/physics_lab/run.py --scenario=J_run_head_front --render --follow --mocap --out=build/physics_lab/mc

How a segment is retargeted (`retarget.py`):
- It turns from our rest by what its CMU bone turned from the capture's T pose (frame one).
- First comes a fixed turn taking the T pose's bone onto ours: the arms are out in the T pose and hang at our rest.
- Then it's converted to our axes (the capture faces +z, ours -z) and to his heading (the way his hips went).

Quaternions, not Euler angles: read as Euler, a knee flips between frames and blends through a spin.

Licence and credit: `CREDITS.md` (Motion).

Left to look at:
- one clip per gait: other speeds just step faster or slower;
- starting off, stopping and turning are eased over 0.2 s, not looked at closely;
- aiming, hands up or clutching: the clip has only his legs and hips;
- not yet seen in town.
