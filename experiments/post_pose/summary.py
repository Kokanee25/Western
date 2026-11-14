"""One line a seed from post_views.gd's checks.json: python3 summary.py DIR/checks.json"""
import json, sys
c = json.load(open(sys.argv[1]))
for s, v in sorted(c.items(), key=lambda kv: int(kv[0])):
    d = v['dials']; h = v['hidden_from_threat']
    print(f"{s:>3} {d['style']:<7} {d['show']:<8} {d['legs']:<9} upper_r {v['upper_arm_r_from_vertical']:5.1f} elbow {v['elbow']:5.1f} "
          f"fore_lvl {v['forearm_from_level']:5.1f} fore_off {v['forearm_off_threat']:5.1f} gap {v['forearm_to_trunk_gap']:.3f} "
          f"left {v['upper_arm_l_from_vertical']:4.1f} into {v['body_into_post']:.3f}{(' ' + v['body_into_post_what']) if v['body_into_post'] > 0 else ''} "
          f"hidden {h['all']:.2f} (head {h['head']:.2f} trunk {h['trunk']:.2f} legs {h['legs']:.2f}) eye_sees {v['eye_sees_threat']} "
          f"gun_in_post {v['gun_into_post']} muzzle_seen {v['muzzle_seen_by_threat']} gun_h {v['gun_height']}")
