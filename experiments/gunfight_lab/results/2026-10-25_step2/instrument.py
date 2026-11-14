#!/usr/bin/env python3
"""Temporary sub-timers in HumanBody._physics_step / _apply_pose (step 2's probe), applied to a
worktree and reverted; never committed. python3 instrument2.py ROOT"""
import sys
R = sys.argv[1] + "/src/bodies/human_body.gd"
s = open(R).read()
def sub(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
T = lambda name, body: "\tvar _tp_%s := Prof.start()\n%s\tProf.stop(&\"hb_%s\", _tp_%s)\n" % (name, body, name, name)
sub("\tphysiology.step(delta * scale_now)\n", T("physiology", "\tphysiology.step(delta * scale_now)\n"))
sub("\t_update_stains(delta * scale_now)\n\tsigns_now().step(delta * scale_now)\n",
    T("signs", "\t_update_stains(delta * scale_now)\n\tsigns_now().step(delta * scale_now)\n"))
sub("\t_after_step(delta, delta * scale_now)\n", T("after", "\t_after_step(delta, delta * scale_now)\n"))
sub("\t\t_favour_step(delta)\n\t\t_apply_pose(delta)\n",
    "\t\tvar _tf := Prof.start()\n\t\t_favour_step(delta)\n\t\tProf.stop(&\"hb_favour\", _tf)\n\t\t_tf = Prof.start()\n\t\t_apply_pose(delta)\n\t\tProf.stop(&\"hb_pose\", _tf)\n")
sub("\tif not limp:\n\t\t_track_carry(delta)\n", "\tvar _tc := Prof.start()\n\tif not limp:\n\t\t_track_carry(delta)\n\tProf.stop(&\"hb_carry\", _tc)\n")
sub("\t_cough(delta)\n\tvar conscious", "\tvar _tg := Prof.start()\n\t_cough(delta)\n\tProf.stop(&\"hb_cough\", _tg)\n\tvar conscious")
# the pose: its head (clips, gait overlay, injury targets), the loop, the tail
sub("\tvar clip := _mocap_now(delta)\n", "\tvar _ta := Prof.start()\n\tvar clip := _mocap_now(delta)\n")
sub("\tvar writes := 0\n\tfor sid: StringName in pivots:", "\tvar writes := 0\n\tProf.stop(&\"hb_pose_head\", _ta)\n\t_ta = Prof.start()\n\tfor sid: StringName in pivots:")
sub("\tProf.count(&\"q_writes\", writes)\n\t_place_rig(delta, snap)\n", "\tProf.count(&\"q_writes\", writes)\n\tProf.stop(&\"hb_pose_loop\", _ta)\n\t_ta = Prof.start()\n\t_place_rig(delta, snap)\n")
sub("\tif held_gun != null and not gun_holstered:\n\t\tcurl_hand(\"r\", 0.85)\n\n\nconst _MOCAP_ALWAYS",
    "\tif held_gun != null and not gun_holstered:\n\t\tcurl_hand(\"r\", 0.85)\n\tProf.stop(&\"hb_pose_tail\", _ta)\n\n\nconst _MOCAP_ALWAYS")
open(R, "w").write(s)
print("instrumented", R)
