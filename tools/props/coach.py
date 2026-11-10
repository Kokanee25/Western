"""The Baron's iron-plated coach and its strongbox (the prop lab, #782; for the heist, #736's comment and #770).

    python3 tools/props/coach.py            # assets/props/kit/{baron_coach,strongbox}.json

A Concord-style road coach (Abbot-Downing's) armoured for the Baron: its body a box of oak framing,
board panels and a board roof, with 28 iron plates 8 mm thick (5/16 in, said of the Black Hills
treasure coaches of 1878) bolted over its sides, doors, back and front, six slits to shoot from; hung
on two leather thoroughbraces from iron-strapped jacks on the axles; the factory's wheels (wagons.py),
bigger at the back; a driver's box with its seat and footboard at the front, a boot at the back; two
doors that open (the kit's "hinges"); benches for four guards; the pole, splinter bar, singletrees and
four trace hooks for the team. The strongbox, under the rear bench, is a kit prop of its own (iron,
a padlock and hasp, a lid on hinges, the Baron's papers inside), carried by the coach ("carries").

Kit space as the wagons': origin on the ground under its middle, long along X with the pole toward
-X, the wheels' axes along Z; the left side (-Z), the right (+Z).

How it stands (the support graph, as wagons.py): each wheel on the felloe under its hub, the hub on
its two spokes there, the axle on the hubs (`cripple`); on each axle its bolster (`furniture_top`),
on the bolsters the jacks, on the jacks the thoroughbraces, on the braces the body's sills and the
two boots' platforms, and everything above stacked on what's under it (`trim`, unchecked, as a
wagon's bed): posts and panels on the sills, the lower plates on the sills' outer edge, the upper
plates on the lower ones, the roof rails on the posts and plates, the roof on its rails. The doors
hang on their hinge posts ("on"), open or shut. So: shoot two spokes out under a hub and that corner
drops; break a brace and the body comes down on that side; the plates stand on the sill.

Measures: Concord coaches (Abbot-Downing's): wheels about 3 ft 8 in front and 5 ft behind, track
about 5 ft 2 in, a body some 8 ft 6 in long hung on thoroughbraces of layered leather ~3 in wide;
~2,500 lb empty. The plates: 5/16 in iron; the game's ballistics (resistance_by_wood iron, 4,000)
take ~3,200 J to put a ball through one: a .45 Colt ball carries ~620 J.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wagons import HUB_LOOK, IRON, GEAR_LOOK, GEAR_WOOD, r4, standing_wheel, vec, write  # noqa: E402

LEATHER = "prop:leather"
PINE = "weathered_pine"
WOOD_LOOK = "wood:dark_oak"

# --- Measures (m) --------------------------------------------------------------------------------
FX, RX = -1.45, 1.40          # front and hind axle x
FR, RR = 0.56, 0.76           # wheel radii: 3 ft 8 in and 5 ft
TRACK = 1.6
WHEEL = {"width": 0.085, "depth": 0.085, "hub_r": 0.1, "hub_len": 0.36, "spoke": (0.065, 0.05)}
AXLE = 0.12
JACK_Z = 0.64                 # the braces and their jacks, under the sills
BRACE_TOP = 0.98              # the body's underside
SILL = 0.10
Y0 = BRACE_TOP + SILL         # the sills' top: the floor, the posts and the panels stand here
BELT = 1.70                   # the lower panels' top: the window row above, behind the upper plates
TOP = 2.40                    # the walls' top: the roof rails sit here
XL = 1.31                     # the body's half length (the end sills' outer face)
ZW = 0.71                     # the side sills' outer face
POST_Z = 0.64                 # the posts' middle (0.60-0.68)
PANEL_Z = 0.69                # the board panels (0.68-0.70), outside the posts
PLATE = 0.008                 # 5/16 in
PLATE_Z = 0.70 + PLATE * 0.5  # the plates (0.70-0.708)
PLATE_X = 1.30 + PLATE * 0.5  # the end plates
DOOR = 0.372                  # the door's plates' half width (the hinge on its fore edge)
SLIT = 0.04                   # a slit's width
SLIT_FROM = 2.12              # a slit's bottom (its top the roof rail, 2.40): 4 x 28 cm
SHOT_BREAKS = 300.0           # J: a ball that breaks a padlock or a trace hook


def box(id_, kind, size, at, wood=GEAR_WOOD, look=WOOD_LOOK, **more):
    m = {"id": id_, "kind": kind, "wood": wood, "look": look, "size": vec(*size), "at": vec(*at)}
    m.update(more)
    return m


def rivets(x0, x1, y0, y1, z, step=0.16, inset=0.025, plane="z"):
    """Rivet heads round a plate's edge (drawn on it): on its outer face `z` (along x and y), or for
    an end plate (`plane` "x") on its face at x = `z`, along z and y."""
    heads = []
    def put(a, y):
        if plane == "z":
            heads.append({"size": vec(0.018, 0.018, 0.006), "at": vec(a, y, z)})
        else:
            heads.append({"size": vec(0.006, 0.018, 0.018), "at": vec(z, y, a)})
    n = max(2, int(round((x1 - x0) / step)) + 1)
    for i in range(n):
        a = x0 + inset + (x1 - x0 - inset * 2) * i / (n - 1)
        put(a, y0 + inset)
        put(a, y1 - inset)
    k = max(2, int(round((y1 - y0) / step)) + 1)
    for i in range(1, k - 1):
        y = y0 + inset + (y1 - y0 - inset * 2) * i / (k - 1)
        put(x0 + inset, y)
        put(x1 - inset, y)
    return [{"look": IRON, "draw": {"shape": "boxes", "boxes": heads}}]


def side_plate(id_, sign, x0, x1, y0, y1):
    """A plate on a side (sign -1 the left, +1 the right), x0..x1, y0..y1, on the sill's outer edge
    or the plate under it."""
    z = sign * PLATE_Z
    out_z = sign * (0.708 + 0.003)
    return box(id_, "trim", (x1 - x0, y1 - y0, PLATE), ((x0 + x1) * 0.5, (y0 + y1) * 0.5, z), wood="iron", look=IRON,
               plate=True, dress=rivets(x0, x1, y0, y1, out_z))


def end_plate(id_, sign, z0, z1, y0, y1):
    """A plate on an end (sign -1 the front, +1 the back), z0..z1, y0..y1."""
    x = sign * PLATE_X
    out_x = sign * (1.308 + 0.003)
    return box(id_, "trim", (PLATE, y1 - y0, z1 - z0), (x, (y0 + y1) * 0.5, (z0 + z1) * 0.5), wood="iron", look=IRON,
               plate=True, dress=rivets(z0, z1, y0, y1, out_x, plane="x"))


def running_gear():
    m = []
    for side, z in (("l", -TRACK * 0.5), ("r", TRACK * 0.5)):
        m += standing_wheel("front_%s" % side, (FX, FR, z), FR, **WHEEL)
        m += standing_wheel("hind_%s" % side, (RX, RR, z), RR, **WHEEL)
    for name, x, r in (("front_axle", FX, FR), ("hind_axle", RX, RR)):
        m.append(box(name, "cripple", (AXLE, AXLE, TRACK + WHEEL["hub_len"] * 0.8), (x, r, 0), look=HUB_LOOK))
    # The bolsters on the axles; on them the jacks (iron-strapped standards) that carry the braces'
    # ends: the hind wheels are bigger, so the hind ones are short.
    f_top, r_top = FR + AXLE * 0.5, RR + AXLE * 0.5
    m.append(box("front_bolster", "furniture_top", (0.12, 0.10, 1.40), (FX, f_top + 0.05, 0), look=HUB_LOOK))
    m.append(box("hind_bolster", "furniture_top", (0.12, 0.04, 1.40), (RX, r_top + 0.02, 0), look=HUB_LOOK,
                 # The brake: a beam before the hind wheels, a shoe on each tyre (drawn).
                 dress=[{"look": HUB_LOOK, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.08, 0.08, TRACK - 0.1), "at": vec(RX - RR - 0.09, RR * 0.9, 0)}] + [
                     {"size": vec(0.06, 0.22, 0.09), "at": vec(RX - RR * 0.97 - 0.01, RR * 0.92, s * TRACK * 0.5)} for s in (-1, 1)]}}]))
    for end, x, y0 in (("front", FX, f_top + 0.10), ("hind", RX, r_top + 0.04)):
        for side, s in (("l", -1), ("r", 1)):
            h = BRACE_TOP - 0.08 - y0
            # Drawn as the iron C of a Concord's jack: up the axle's face and over toward the body.
            m.append(box("%s_jack_%s" % (end, side), "trim", (0.10, h, 0.09), (x, y0 + h * 0.5, s * JACK_Z), look=HUB_LOOK,
                         dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                             {"size": vec(0.03, h + 0.12, 0.05), "at": vec(x + (0.065 if end == "front" else -0.065), y0 + h * 0.5 + 0.02, s * JACK_Z)},
                             {"size": vec(0.10, 0.025, 0.05), "at": vec(x, BRACE_TOP - 0.06, s * JACK_Z)}]}}]))
    # The thoroughbraces: layered leather, jack to jack; the body rides on them.
    bx0, bx1 = FX - 0.12, RX + 0.12
    for side, s in (("l", -1), ("r", 1)):
        m.append(box("brace_%s" % side, "trim", (bx1 - bx0, 0.08, 0.09), ((bx0 + bx1) * 0.5, BRACE_TOP - 0.04, s * JACK_Z),
                     wood="leather", look=LEATHER,
                     dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                         {"size": vec(0.05, 0.10, 0.11), "at": vec(x, BRACE_TOP - 0.04, s * JACK_Z)} for x in (bx0 + 0.06, bx1 - 0.06)]}}]))
    # The reach (perch) from axle to axle.
    import math
    m.append(box("reach", "furniture_top", (RX - FX + 0.3, 0.07, 0.08), ((FX + RX) * 0.5, (FR + RR) * 0.5 + AXLE * 0.5 + 0.035, 0),
                 look=HUB_LOOK, rot=vec(0, 0, -math.degrees(math.atan2(RR - FR, RX - FX)))))
    # The hounds forward of the front axle; the splinter bar across them, the two singletrees on it,
    # a trace hook at each end of each (the wheelers' four traces: break a hook and its trace is free).
    for side, s in (("l", -1), ("r", 1)):
        m.append(box("hound_%s" % side, "furniture_top", (0.65, 0.06, 0.06), (FX - 0.025, f_top + 0.03, s * 0.22), look=HUB_LOOK))
    bar_y = f_top + 0.06
    m.append(box("splinter_bar", "trim", (0.07, 0.07, 1.5), (FX - 0.31, bar_y + 0.035, 0), look=HUB_LOOK,
                 dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.075, 0.075, 0.03), "at": vec(FX - 0.31, bar_y + 0.035, z)} for z in (-0.73, 0.73)]}}]))
    tree_y = bar_y + 0.07
    for side, s in (("l", -1), ("r", 1)):
        m.append(box("singletree_%s" % side, "trim", (0.05, 0.05, 0.75), (FX - 0.31, tree_y + 0.025, s * 0.40), look=HUB_LOOK))
        for end, dz in (("out", 0.35), ("in", -0.35)):
            m.append(box("trace_hook_%s_%s" % (side, end), "trim", (0.03, 0.05, 0.03), (FX - 0.31, tree_y + 0.075, s * (0.40 + dz)),
                         wood="iron", look=IRON, shot_breaks=SHOT_BREAKS,
                         dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                             {"size": vec(0.06, 0.012, 0.012), "at": vec(FX - 0.34, tree_y + 0.09, s * (0.40 + dz))}]}}]))
    # The pole: from between the hounds forward and down to the ground, where a coach standing
    # unhitched rests it; its neck yoke drawn at the tip.
    tl = 3.3
    drop = math.asin(min(0.95, (FR - 0.04) / tl))
    tx = FX - math.cos(drop) * tl * 0.5
    tip_x = FX - math.cos(drop) * tl
    m.append(box("pole", "post", (tl, 0.08, 0.08), (tx - 0.05, FR - math.sin(drop) * tl * 0.5, 0), look=GEAR_LOOK,
                 rot=vec(0, 0, math.degrees(drop)), splits_below=0.4,
                 dress=[{"look": HUB_LOOK, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.06, 0.06, 1.1), "at": vec(tip_x + 0.25, 0.12, 0)}]}},
                        {"look": IRON, "draw": {"shape": "boxes", "boxes": [
                            {"size": vec(0.1, 0.04, 0.1), "at": vec(tip_x + 0.08, 0.06, 0)}]}}]))
    return m


def body():
    m = []
    # Sills: the two ends and a bearer across the middle on the braces, the sides between them.
    for name, x in (("sill_front", -(XL - 0.065)), ("sill_back", XL - 0.065), ("sill_mid", 0.0)):
        m.append(box(name, "trim", (0.13 if name != "sill_mid" else 0.12, SILL, 2 * ZW), (x, BRACE_TOP + SILL * 0.5, 0)))
    for side, s in (("l", -1), ("r", 1)):
        for part, x0, x1 in (("fore", -(XL - 0.13), -0.06), ("aft", 0.06, XL - 0.13)):
            m.append(box("sill_%s_%s" % (side, part), "trim", (x1 - x0, SILL, 0.13), ((x0 + x1) * 0.5, BRACE_TOP + SILL * 0.5, s * 0.645)))
    # The floor along it, inside the side sills.
    n = 6
    for i in range(n):
        z = -0.58 + 1.16 * (i + 0.5) / n
        m.append(box("floor%d" % i, "trim", (2.56, 0.025, 1.16 / n - 0.004), (0, Y0 + 0.0125, z), wood=PINE))
    wall = TOP - Y0
    # Posts: four corners, two each side at the door.
    for sx in (-1, 1):
        for side, s in (("l", -1), ("r", 1)):
            m.append(box("post_%s_%s" % (side, "front" if sx < 0 else "back"), "trim", (0.08, wall, 0.08), (sx * 1.24, Y0 + wall * 0.5, s * POST_Z)))
    for side, s in (("l", -1), ("r", 1)):
        for part, x in (("fore", -0.37), ("aft", 0.37)):
            m.append(box("post_%s_door_%s" % (side, part), "trim", (0.06, wall, 0.08), (x, Y0 + wall * 0.5, s * POST_Z)))
    # The lower panels (boards, outside the posts) and the end walls' lower boards; the window row
    # above is open behind its plates.
    low = BELT - Y0
    for side, s in (("l", -1), ("r", 1)):
        for part, x0, x1 in (("fore", -1.28, -0.40), ("aft", 0.40, 1.28)):
            m.append(box("panel_%s_%s" % (side, part), "trim", (x1 - x0, low, 0.02), ((x0 + x1) * 0.5, Y0 + low * 0.5, s * PANEL_Z), wood=PINE))
    for end, sx in (("front", -1), ("back", 1)):
        m.append(box("panel_%s" % end, "trim", (0.02, low, 2 * 0.68), (sx * 1.29, Y0 + low * 0.5, 0), wood=PINE))
    # The plates: each side's fore and aft panels (lower, then the window row with its slit: the
    # plate either side of it and a filler under it) and the door's; the back's and the front's.
    for side, s in (("l", -1), ("r", 1)):
        for part, x0, x1 in (("fore", -1.308, -DOOR - 0.003), ("aft", DOOR + 0.003, 1.308)):
            m.append(side_plate("plate_%s_%s_low" % (side, part), s, x0, x1, Y0, BELT))
            mid = (x0 + x1) * 0.5
            m.append(side_plate("plate_%s_%s_up_a" % (side, part), s, x0, mid - SLIT * 0.5, BELT, TOP))
            m.append(side_plate("plate_%s_%s_slit" % (side, part), s, mid - SLIT * 0.5, mid + SLIT * 0.5, BELT, SLIT_FROM))
            m.append(side_plate("plate_%s_%s_up_b" % (side, part), s, mid + SLIT * 0.5, x1, BELT, TOP))
    for end, sx in (("front", -1), ("back", 1)):
        m.append(end_plate("plate_%s_low" % end, sx, -0.70, 0.70, Y0, BELT))
        m.append(end_plate("plate_%s_up_a" % end, sx, -0.70, -SLIT * 0.5, BELT, TOP))
        m.append(end_plate("plate_%s_slit" % end, sx, -SLIT * 0.5, SLIT * 0.5, BELT, SLIT_FROM))
        m.append(end_plate("plate_%s_up_b" % end, sx, SLIT * 0.5, 0.70, BELT, TOP))
    # The doors: a board door in the panels' plane and its two plates, hung on the fore door post.
    for side, s in (("l", -1), ("r", 1)):
        dy0 = Y0 + 0.005
        m.append(box("door_%s" % side, "door", (0.67, BELT - dy0, 0.02), (0, (dy0 + BELT) * 0.5, s * PANEL_Z), wood=PINE))
        handle = {"look": IRON, "draw": {"shape": "boxes", "boxes": [
            {"size": vec(0.12, 0.025, 0.02), "at": vec(DOOR - 0.12, 1.62, s * 0.718)},
            {"size": vec(0.03, 0.04, 0.012), "at": vec(DOOR - 0.12, 1.62, s * 0.711)}]}}
        hinges = {"look": IRON, "draw": {"shape": "boxes", "boxes": [
            {"size": vec(0.16, 0.05, 0.01), "at": vec(-DOOR + 0.08, y, s * 0.713)} for y in (Y0 + 0.15, TOP - 0.15)]}}
        low_plate = side_plate("plate_%s_door_low" % side, s, -DOOR, DOOR, dy0, BELT)
        low_plate["dress"] += [handle, hinges]
        m.append(low_plate)
        m.append(side_plate("plate_%s_door_up" % side, s, -DOOR, DOOR, BELT, TOP))
        # The step under the door (drawn on the sill).
        for x in m:
            if x["id"] == "sill_%s_fore" % side:
                x["dress"] = [{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                    {"size": vec(0.03, 0.30, 0.03), "at": vec(-0.12, BRACE_TOP - 0.10, s * 0.76)},
                    {"size": vec(0.03, 0.30, 0.03), "at": vec(0.12, BRACE_TOP - 0.10, s * 0.76)},
                    {"size": vec(0.32, 0.02, 0.14), "at": vec(0.0, BRACE_TOP - 0.25, s * 0.80)}]}}]
    # The roof: rails round its top on the posts and plates, boards along it, an iron luggage rail
    # round the edge (drawn).
    for side, s in (("l", -1), ("r", 1)):
        m.append(box("roof_rail_%s" % side, "trim", (2.62, 0.08, 0.11), (0, TOP + 0.04, s * 0.655)))
    for end, sx in (("front", -1), ("back", 1)):
        m.append(box("roof_rail_%s" % end, "trim", (0.11, 0.08, 1.20), (sx * 1.255, TOP + 0.04, 0)))
    nb = 7
    rail = []
    for x in (-1.25, -0.6, 0.0, 0.6, 1.25):
        for s in (-1, 1):
            rail.append({"size": vec(0.02, 0.14, 0.02), "at": vec(x, TOP + 0.175, s * 0.66)})
    for s in (-1, 1):
        rail.append({"size": vec(2.54, 0.02, 0.02), "at": vec(0, TOP + 0.24, s * 0.66)})
    for sx in (-1, 1):
        rail.append({"size": vec(0.02, 0.02, 1.34), "at": vec(sx * 1.26, TOP + 0.24, 0)})
    for i in range(nb):
        z = -0.72 + 1.44 * (i + 0.5) / nb
        m.append(box("roof%d" % i, "trim", (2.66, 0.025, 1.44 / nb - 0.004), (0, TOP + 0.08 + 0.0125, z), wood=PINE,
                     dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": rail}}] if i == 0 else []))
    # The benches: one against each end, two guards on each, facing; risers on the floor.
    seat_y = Y0 + 0.025 + 0.37
    for end, sx in (("front", -1), ("back", 1)):
        x = sx * 1.04
        for side, s in (("l", -1), ("r", 1)):
            m.append(box("bench_%s_riser_%s" % (end, side), "trim", (0.36, 0.37, 0.03), (x, Y0 + 0.025 + 0.185, s * 0.54), wood=PINE))
        back = {"look": LEATHER, "draw": {"shape": "boxes", "boxes": [
            {"size": vec(0.06, 0.45, 1.10), "at": vec(sx * 1.245, seat_y + 0.30, 0)}]}}
        m.append(box("bench_%s" % end, "trim", (0.40, 0.035, 1.14), (x, seat_y + 0.0175, 0), wood=PINE,
                     dress=[{"look": LEATHER, "draw": {"shape": "boxes", "boxes": [
                         {"size": vec(0.38, 0.05, 1.10), "at": vec(x, seat_y + 0.06, 0)}]}}, back]))
    # The strongbox's chain: an eye in the floor under the rear bench, a few links to the box (drawn).
    links = [{"size": vec(0.05, 0.012, 0.02), "at": vec(0.86 - 0.04 * i, Y0 + 0.032, 0.34 + 0.005 * (i % 2))} for i in range(5)]
    for x in m:
        if x["id"] == "floor5":
            x["dress"] = [{"look": IRON, "draw": {"shape": "boxes", "boxes": links + [
                {"size": vec(0.05, 0.03, 0.05), "at": vec(0.66, Y0 + 0.04, 0.34)}]}}]
    return m


def boots():
    m = []
    # The driver's box: a platform on the braces' front ends, out over the front wheels and on to the
    # footboard's stays; the boot's sides and front on it, its lid the seat, the cushion and back.
    p0, p1 = -2.25, -XL - 0.005
    m.append(box("front_platform", "trim", (p1 - p0, 0.025, 1.24), ((p0 + p1) * 0.5, BRACE_TOP + 0.0125, 0)))
    pt = BRACE_TOP + 0.025
    lid_y = 1.80
    bx0 = -1.85
    for side, s in (("l", -1), ("r", 1)):
        m.append(box("front_boot_%s" % side, "trim", (p1 - bx0, lid_y - pt, 0.025), ((bx0 + p1) * 0.5, (pt + lid_y) * 0.5, s * 0.6075), wood=PINE))
    m.append(box("front_boot_face", "trim", (0.025, lid_y - pt, 1.19), (bx0 + 0.0125, (pt + lid_y) * 0.5, 0), wood=PINE,
                 dress=[{"look": LEATHER, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.012, lid_y - pt - 0.1, 1.1), "at": vec(bx0 - 0.004, (pt + lid_y) * 0.5, 0)}]}}]))
    m.append(box("driver_box", "trim", (p1 - bx0 + 0.04, 0.03, 1.27), ((bx0 + p1) * 0.5 - 0.02, lid_y + 0.015, 0)))
    cush_y = lid_y + 0.03
    m.append(box("driver_seat", "trim", (0.45, 0.07, 1.12), (-1.56, cush_y + 0.035, 0), wood="leather", look=LEATHER,
                 # Its iron rail round the seat's ends, the brake lever up the right of the footboard.
                 dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.40, 0.02, 0.02), "at": vec(-1.56, cush_y + 0.22, s * 0.62)} for s in (-1, 1)] + [
                     {"size": vec(0.02, 0.22, 0.02), "at": vec(x, cush_y + 0.11, s * 0.62)} for x in (-1.74, -1.38) for s in (-1, 1)] + [
                     {"from": vec(-2.02, 1.58, 0.66), "to": vec(-1.92, 2.32, 0.68), "thick": 0.035}]}}]))
    m.append(box("driver_back", "trim", (0.025, 0.28, 1.10), (-XL - 0.0175, cush_y + 0.14, 0), wood="leather", look=LEATHER))
    # The footboard on two iron stays from the platform.
    stay_top = 1.55
    for side, s in (("l", -1), ("r", 1)):
        m.append(box("footboard_stay_%s" % side, "trim", (0.03, stay_top - pt, 0.03), (-2.18, (pt + stay_top) * 0.5, s * 0.45), wood="iron", look=IRON))
    m.append(box("footboard", "trim", (0.40, 0.025, 1.20), (-2.10, stay_top + 0.0125, 0), rot=vec(0, 0, 0)))
    # The boot at the back: a platform on the braces' hind ends, sides, a back board, the leather
    # cover over it and its apron down the back (drawn).
    q0, q1 = XL + 0.005, 1.95
    m.append(box("back_platform", "trim", (q1 - q0, 0.025, 1.24), ((q0 + q1) * 0.5, BRACE_TOP + 0.0125, 0)))
    bt = 1.56
    for side, s in (("l", -1), ("r", 1)):
        m.append(box("back_boot_%s" % side, "trim", (q1 - q0 - 0.025, bt - pt, 0.025), ((q0 + q1 - 0.025) * 0.5, (pt + bt) * 0.5, s * 0.6075), wood=PINE))
    m.append(box("back_boot_end", "trim", (0.025, bt - pt, 1.24), (q1 - 0.0125, (pt + bt) * 0.5, 0), wood=PINE))
    m.append(box("back_boot_cover", "trim", (q1 - q0 + 0.02, 0.012, 1.28), ((q0 + q1) * 0.5 + 0.01, bt + 0.006, 0), wood="leather", look=LEATHER,
                 dress=[{"look": LEATHER, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.012, bt - pt + 0.05, 1.26), "at": vec(q1 + 0.012, (pt + bt) * 0.5, 0)},
                     {"size": vec(0.05, 0.03, 1.30), "at": vec(q0 + 0.03, bt + 0.02, 0)}]}}]))
    return m


def coach():
    members = running_gear() + body() + boots()
    hinges = {}
    for side, s in (("l", -1), ("r", 1)):
        hx, hz = -DOOR, s * 0.708
        hinges["door_%s" % side] = {
            "members": ["door_%s" % side, "plate_%s_door_low" % side, "plate_%s_door_up" % side],
            "axis": [vec(hx, Y0, hz), vec(hx, TOP, hz)],
            # Outward: about +Y, +X turns toward -Z (the left side's outside).
            "open": -100.0 * s,
            "on": ["post_%s_door_fore" % side],
        }
    seat_y = Y0 + 0.025 + 0.37 + 0.035
    return {
        "_doc": "The Baron's iron-plated coach (#782, for the heist, #736/#770): a Concord-style road coach armoured. Its body 2.62 x 1.42 x 1.42 m (to its roof ~2.5 m off the road) of oak framing, pine panels and roof, 28 iron plates 8 mm thick over its sides, doors, back and front (each its own member, `plate`: the dent system's), six slits 4 x 28 cm at a seated guard's eye; hung on two leather thoroughbraces from the jacks on its axles; wheels 3 ft 8 in and 5 ft (the factory's, heavy hubs), track 1.6 m; a driver's box with its seat and footboard, a boot at the back; two doors on hinges (`open_hinge`); two benches for four guards (`seats_at`); the strongbox under the rear bench (`carries`). The pole, splinter bar, two singletrees and four trace hooks (`trace_hook_*`, shot apart by a ball) for the team. ~1,500 kg empty.",
        "id": "baron_coach", "kind": "members", "in_game": True, "factory": "tools/props/coach.py",
        "wood": GEAR_WOOD, "look": WOOD_LOOK, "splits_below": 0.4, "blow_wood_share": 0.5,
        "hinges": hinges,
        "carries": [{"id": "strongbox", "name": "strongbox", "at": vec(1.04, Y0 + 0.025, 0), "yaw": -90}],
        # For the heist's guards and crew (gameplay): where each sits (prop space) and which way he faces (yaw, degrees).
        "seats_at": [
            {"at": vec(-1.04, seat_y, -0.28), "yaw": -90}, {"at": vec(-1.04, seat_y, 0.28), "yaw": -90},
            {"at": vec(1.04, seat_y, -0.28), "yaw": 90}, {"at": vec(1.04, seat_y, 0.28), "yaw": 90},
            {"at": vec(-1.56, 1.90, 0.30), "yaw": 90, "who": "driver"}, {"at": vec(-1.56, 1.90, -0.30), "yaw": 90, "who": "messenger"}],
        "members": members,
    }


def strongbox():
    """The Baron's strongbox: an iron box 60 x 35 x 33 cm, 5 mm walls, a lid on hinges along its
    back, a hasp from the lid over the staple and a padlock through it; his papers inside. Its own
    space: origin on its bottom's middle, its front (the lock) toward +Z."""
    t = 0.005
    L, D, H = 0.60, 0.35, 0.33
    wall = H - t - 0.006           # the walls, between the bottom and the lid
    band = lambda z0, z1, y0, y1, x: {"size": vec(0.03, y1 - y0, z1 - z0), "at": vec(x, (y0 + y1) * 0.5, (z0 + z1) * 0.5)}
    m = []
    # The bottom, a lip proud at the front for the staple: its foot.
    m.append(box("bottom", "post", (L, t, D + 0.015), (0, t * 0.5, 0.0075), wood="iron", look=IRON))
    straps = {"look": IRON, "draw": {"shape": "boxes", "boxes": [
        {"size": vec(0.035, wall, 0.006), "at": vec(x, t + wall * 0.5, D * 0.5 + 0.003)} for x in (-0.2, 0.2)]}}
    m.append(box("front", "trim", (L, wall, t), (0, t + wall * 0.5, D * 0.5 - t * 0.5), wood="iron", look=IRON, dress=[straps]))
    m.append(box("back", "trim", (L, wall, t), (0, t + wall * 0.5, -D * 0.5 + t * 0.5), wood="iron", look=IRON,
                 dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.035, wall, 0.006), "at": vec(x, t + wall * 0.5, -D * 0.5 - 0.003)} for x in (-0.2, 0.2)]}}]))
    for side, s in (("l", -1), ("r", 1)):
        m.append(box("end_%s" % side, "trim", (t, wall, D - 2 * t), (s * (L * 0.5 - t * 0.5), t + wall * 0.5, 0), wood="iron", look=IRON,
                     # A drop handle on each end.
                     dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                         {"size": vec(0.012, 0.012, 0.14), "at": vec(s * (L * 0.5 + 0.02), H * 0.62, 0)},
                         {"size": vec(0.02, 0.04, 0.012), "at": vec(s * (L * 0.5 + 0.01), H * 0.66, -0.065)},
                         {"size": vec(0.02, 0.04, 0.012), "at": vec(s * (L * 0.5 + 0.01), H * 0.66, 0.065)}]}}]))
    lid_y = t + wall
    m.append(box("lid", "trim", (L + 0.01, 0.006, D + 0.01), (0, lid_y + 0.003, 0), wood="iron", look=IRON,
                 dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.035, 0.006, D + 0.01), "at": vec(x, lid_y + 0.009, 0)} for x in (-0.2, 0.2)] + [
                     {"size": vec(0.05, 0.02, 0.02), "at": vec(x, lid_y, -D * 0.5 - 0.008)} for x in (-0.18, 0.18)]}}]))
    # The staple, on the bottom's lip up the front; the padlock through it, on it; the hasp hangs
    # from the lid's front edge over the staple.
    sz = D * 0.5 + 0.006
    staple_top = H - 0.075
    m.append(box("staple", "trim", (0.025, staple_top - t, 0.008), (0, t + (staple_top - t) * 0.5, sz), wood="iron", look=IRON))
    m.append(box("padlock", "trim", (0.06, 0.065, 0.025), (0, staple_top + 0.0325, sz + 0.0165), wood="iron", look=IRON,
                 shot_breaks=SHOT_BREAKS,
                 dress=[{"look": IRON, "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.008, 0.035, 0.008), "at": vec(x, staple_top + 0.08, sz + 0.0165)} for x in (-0.02, 0.02)] + [
                     {"size": vec(0.048, 0.008, 0.008), "at": vec(0, staple_top + 0.096, sz + 0.0165)},
                     {"size": vec(0.008, 0.016, 0.004), "at": vec(0, staple_top + 0.025, sz + 0.031)}]}}]))
    m.append(box("hasp", "trim", (0.05, 0.10, 0.006), (0, H - 0.05, D * 0.5 + 0.0035), wood="iron", look=IRON))
    # The papers: a bundle tied with tape, lying on the bottom.
    m.append(box("papers", "trim", (0.30, 0.04, 0.22), (-0.08, t + 0.02, -0.02), wood="paper", look="prop:ivory",
                 dress=[{"look": "prop:felt", "draw": {"shape": "boxes", "boxes": [
                     {"size": vec(0.012, 0.042, 0.222), "at": vec(-0.08, t + 0.02, -0.02)},
                     {"size": vec(0.302, 0.042, 0.012), "at": vec(-0.08, t + 0.02, -0.02)}]}}]))
    return {
        "_doc": "The Baron's strongbox (#782): an iron box 60 x 35 x 33 cm, 5 mm walls, two straps round it, drop handles on its ends; the lid on two hinges along its back (`open_hinge(\"lid\")`), shut while the padlock and the hasp are whole and no key's turned (`unlock(\"lid\")`); the padlock breaks to a ball (`shot_breaks`), the hasp to a bar (break it); a ball doesn't go through its walls. His papers inside (`papers`: paper, they burn). ~45 kg. Under the coach's rear bench, its chain drawn on the floor.",
        "id": "strongbox", "kind": "members", "in_game": True, "factory": "tools/props/coach.py",
        "wood": "iron", "look": IRON, "splits_below": 0.4, "blow_wood_share": 0.5,
        "hinges": {"lid": {"members": ["lid", "hasp"], "axis": [vec(-L * 0.5, lid_y + 0.003, -D * 0.5), vec(L * 0.5, lid_y + 0.003, -D * 0.5)],
                           # About +X, +Z (the front) turns down: open is the other way.
                           "open": -105.0, "on": ["back"], "locked_by": ["padlock", "hasp"]}},
        "members": m,
    }


def main():
    for data in (coach(), strongbox()):
        print(write(data["id"], data), len(data["members"]), "members")


if __name__ == "__main__":
    main()
