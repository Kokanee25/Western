#!/usr/bin/env python3
"""Temporary instrumentation for the more-cores measurements (NOT to be committed): sub-timers
inside people_body / outlaw_brain / senses and a count of physics queries per system, all
through Prof so the lab's per_system_ms carries them. Applied to a working copy, reverted with
`git checkout -- src`."""
import re
import sys

ROOT = "/home/user/Western/"


def sub(path, old, new, count=1):
    p = ROOT + path
    s = open(p).read()
    if s.count(old) < count:
        sys.exit("NOT FOUND in %s: %r" % (path, old[:60]))
    s = s.replace(old, new, count)
    open(p, "w").write(s)


# Prof: a counter (1 "ms" = 1 call a frame).
sub("src/debug/prof.gd",
    "static func stop(system: StringName, t0: int) -> void:",
    "static func count(system: StringName, n := 1) -> void:\n\tif on:\n\t\t_sum[system] = int(_sum.get(system, 0)) + n * 1000\n\n\nstatic func stop(system: StringName, t0: int) -> void:")

# HumanBody._physics_step: the parts.
sub("src/bodies/human_body.gd",
    "\tphysiology.step(delta * scale_now)\n\t_update_stains(delta * scale_now)\n\tsigns_now().step(delta * scale_now)\n\t_after_step(delta, delta * scale_now)\n",
    "\tvar _t1 := Prof.start()\n\tphysiology.step(delta * scale_now)\n\tProf.stop(&\"hb_physiology\", _t1)\n\t_t1 = Prof.start()\n\t_update_stains(delta * scale_now)\n\tsigns_now().step(delta * scale_now)\n\tProf.stop(&\"hb_signs\", _t1)\n\t_t1 = Prof.start()\n\t_after_step(delta, delta * scale_now)\n\tProf.stop(&\"hb_after\", _t1)\n")
sub("src/bodies/human_body.gd",
    "\t\t_favour_step(delta)\n\t\t_apply_pose(delta)\n",
    "\t\t_favour_step(delta)\n\t\tvar _t2 := Prof.start()\n\t\t_apply_pose(delta)\n\t\tProf.stop(&\"hb_pose\", _t2)\n")
sub("src/bodies/human_body.gd",
    "\tif limp:\n\t\tif hat_body != null:\n\t\t\t_hat_meets_ground()\n",
    "\tvar _t3 := Prof.start()\n\tif limp:\n\t\tif hat_body != null:\n\t\t\t_hat_meets_ground()\n")
sub("src/bodies/human_body.gd",
    "\t\t_update_pool()\n\t_cough(delta)\n",
    "\t\t_update_pool()\n\tProf.stop(&\"hb_limp\", _t3)\n\t_cough(delta)\n")
# the pose's tail: the rig and hands
sub("src/bodies/human_body.gd",
    "\t_place_rig(delta, snap)\n\tif _clip_w > 0.0:\n\t\t_clip_strikes(delta)\n\t_reach_step()\n\t_grab_step(delta)\n\t_sling_step(delta)\n",
    "\tvar _t4 := Prof.start()\n\t_place_rig(delta, snap)\n\tif _clip_w > 0.0:\n\t\t_clip_strikes(delta)\n\t_reach_step()\n\t_grab_step(delta)\n\t_sling_step(delta)\n\tProf.stop(&\"hb_pose_tail\", _t4)\n")
# walking: slide and ground
sub("src/bodies/human_body.gd",
    "\tvar step := minf(speed * delta, dist)\n\tvar moved := _slide(dir * step)\n",
    "\tvar step := minf(speed * delta, dist)\n\tvar _t5 := Prof.start()\n\tvar moved := _slide(dir * step)\n\tProf.stop(&\"hb_slide\", _t5)\n")
sub("src/bodies/human_body.gd",
    "\t\tglobal_rotation.y = atan2(-fwd.x, -fwd.z)\n\t_snap_to_ground()\n\tgait = how\n",
    "\t\tglobal_rotation.y = atan2(-fwd.x, -fwd.z)\n\tvar _t6 := Prof.start()\n\t_snap_to_ground()\n\tProf.stop(&\"hb_ground\", _t6)\n\tgait = how\n")
sub("src/bodies/human_body.gd",
    "\t\tvar frac := space.cast_motion(q)\n\t\tif frac[0] <= 0.0 and frac[1] <= 0.0:",
    "\t\tProf.count(&\"q_walk\")\n\t\tvar frac := space.cast_motion(q)\n\t\tif frac[0] <= 0.0 and frac[1] <= 0.0:")
sub("src/bodies/human_body.gd",
    "\tif _blocker and is_instance_valid(_blocker):\n\t\tq.exclude = [_blocker.get_rid()]\n\treturn space.intersect_ray(q)",
    "\tif _blocker and is_instance_valid(_blocker):\n\t\tq.exclude = [_blocker.get_rid()]\n\tProf.count(&\"q_walk\")\n\treturn space.intersect_ray(q)")

# OutlawBrain: the hand, the cover search, the rays.
sub("src/bodies/outlaw_brain.gd",
    "\tif variant != Variant.A:\n\t\t_step_hand(delta)\n\t_quiet += delta\n",
    "\tif variant != Variant.A:\n\t\tvar _th := Prof.start()\n\t\t_step_hand(delta)\n\t\tProf.stop(&\"ob_hand\", _th)\n\t_quiet += delta\n")
sub("src/bodies/outlaw_brain.gd",
    "func _step_search() -> void:\n\tif _search == null or not _search.step(40):\n\t\treturn\n",
    "func _step_search() -> void:\n\tif _search == null:\n\t\treturn\n\tvar _ts := Prof.start()\n\tvar _done := _search.step(40)\n\tProf.stop(&\"ob_cover_search\", _ts)\n\tif not _done:\n\t\treturn\n")
sub("src/bodies/outlaw_brain.gd",
    "\tq.exclude = _exclude(t)\n\tvar hit := body.get_world_3d().direct_space_state.intersect_ray(q)\n\treturn hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.15",
    "\tq.exclude = _exclude(t)\n\tProf.count(&\"q_brain\")\n\tvar hit := body.get_world_3d().direct_space_state.intersect_ray(q)\n\treturn hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.15")
sub("src/bodies/outlaw_brain.gd",
    "\tq.exclude = _exclude()\n\tvar hit := body.get_world_3d().direct_space_state.intersect_ray(q)\n\treturn not hit.is_empty() and crew.is_mate",
    "\tq.exclude = _exclude()\n\tProf.count(&\"q_brain\")\n\tvar hit := body.get_world_3d().direct_space_state.intersect_ray(q)\n\treturn not hit.is_empty() and crew.is_mate")

# Senses: the look's rays, the look itself.
sub("src/people/senses.gd",
    "\tq.exclude = ex\n\tvar hit := space.intersect_ray(q)\n\treturn hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.15",
    "\tq.exclude = ex\n\tProf.count(&\"q_senses\")\n\tvar hit := space.intersect_ray(q)\n\treturn hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.15")
sub("src/people/senses.gd",
    "\t\treturn\n\t_look(dt)\n",
    "\t\treturn\n\tvar _tl := Prof.start()\n\t_look(dt)\n\tProf.stop(&\"senses_look\", _tl)\n")

# SightLight: its lines.
sub("src/people/sight_light.gd",
    "\t\te.sky = _sky_on(at, space, ex)\n\t\te.reach = _lamps_reaching(at, space, ex)\n",
    "\t\tvar _tsl := Prof.start()\n\t\te.sky = _sky_on(at, space, ex)\n\t\te.reach = _lamps_reaching(at, space, ex)\n\t\tProf.stop(&\"sight_light_lines\", _tsl)\n")

# Cover: every ray.
cov = open(ROOT + "src/bodies/cover.gd").read()
n = cov.count("space.intersect_ray(") + cov.count("space.intersect_shape(")
out = []
for line in cov.split("\n"):
    m = re.match(r"^(\t+)(var \w+ :?= |return |if |elif |\w+ = )?.*space\.(intersect_ray|intersect_shape)\(", line)
    if m and "func " not in line:
        out.append(m.group(1) + "Prof.count(&\"q_cover\")")
    out.append(line)
open(ROOT + "src/bodies/cover.gd", "w").write("\n".join(out))

# Ballistics' rays.
sub("src/ballistics/ballistics.gd",
    "\t\tq.exclude = b.exclude\n\t\tvar hit := space.intersect_ray(q)\n",
    "\t\tq.exclude = b.exclude\n\t\tProf.count(&\"q_balls\")\n\t\tvar hit := space.intersect_ray(q)\n")

# The skeleton copy: the bones and the fingers.
sub("src/bodies/human_body.gd",
    "\t\t\tskeleton.set_bone_pose(i, inv * part.global_transform)\n\t_pose_fingers()\n",
    "\t\t\tskeleton.set_bone_pose(i, inv * part.global_transform)\n\tvar _tf := Prof.start()\n\t_pose_fingers()\n\tProf.stop(&\"sk_fingers\", _tf)\n")
print("instrumented; cover rays patched:", n)
