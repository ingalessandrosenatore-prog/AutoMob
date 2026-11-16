import math

from geometry import box, empty, instance, ribbon, tube
from sport_fascia import build_fascias, build_lamps


# Longitudinal styling stations: X, half-width at shoulder, shoulder Z,
# upper half-width, and height at the outer edge and crown.
STATIONS = [
    (-2.10, .57, .57, .49, .714, .733), (-2.07, .72, .637, .59, .768, .795),
    (-1.98, .831, .695, .687, .805, .832), (-1.83, .874, .730, .737, .816, .847),
    (-1.64, .889, .767, .738, .830, .863), (-1.53, .895, .790, .686, .902, .942),
    (-1.39, .900, .818, .617, 1.003, 1.054), (-1.23, .891, .823, .565, 1.133, 1.185),
    (-1.05, .866, .818, .547, 1.238, 1.286), (-.84, .838, .806, .542, 1.304, 1.352),
    (-.56, .822, .794, .561, 1.335, 1.387), (-.28, .817, .780, .575, 1.334, 1.388),
    (-.05, .819, .771, .570, 1.300, 1.348), (.13, .825, .760, .554, 1.247, 1.290),
    (.30, .836, .749, .555, 1.150, 1.192), (.49, .850, .743, .610, .987, 1.033),
    (.72, .867, .738, .713, .791, .837), (.96, .883, .742, .744, .794, .839),
    (1.26, .899, .747, .756, .783, .821), (1.52, .892, .735, .752, .759, .796),
    (1.70, .877, .716, .734, .728, .768), (1.89, .849, .680, .690, .691, .733),
    (2.02, .769, .614, .630, .665, .708), (2.075, .640, .555, .558, .663, .701),
    (2.10, .485, .542, .471, .654, .697),
]

REAR_GLASS_BASE, REAR_GLASS_TOP = -1.64, -1.05
FRONT_GLASS_TOP, FRONT_GLASS_BASE = .13, .72
ARCH_RADIUS = .355
TOP_SAMPLES = (-1, -.85, -.68, -.44, -.22, 0, .22, .44, .68, .85, 1)


def station(x):
    for a, b in zip(STATIONS, STATIONS[1:]):
        if a[0] <= x <= b[0]:
            weight = (x-a[0])/(b[0]-a[0])
            return [start+(end-start)*weight for start, end in zip(a[1:], b[1:])]
    raise ValueError(x)


def samples(first, last, step=.06):
    count = math.ceil((last-first)/step)
    positions = {round(first+(last-first)*i/count, 6) for i in range(count+1)}
    positions.update(row[0] for row in STATIONS if first < row[0] < last)
    return sorted(positions)


def sill(x):
    offset = min(abs(x-1.3), abs(x+1.3))
    arch = max(0, ARCH_RADIUS**2-offset**2)
    return .318 + math.sqrt(arch)


def side_point(x, side, height):
    shoulder, shoulder_z, _, _, _ = station(x)
    center_offset = min(abs(x-1.30), abs(x+1.30))
    flare = .067 * max(0, 1-(center_offset/.49)**2)**2
    contour = (-.087*(1-height) + .022*math.sin(math.pi*height)
               + flare*(1-height)**2)
    return x, side*(shoulder+contour), sill(x)+(shoulder_z-sill(x))*height


def upper_point(x, side, height):
    shoulder, z, edge, edge_z, _ = station(x)
    return x, side*(shoulder+(edge-shoulder)*height), z+(edge_z-z)*height


def top_point(x, across):
    _, _, half, edge_z, crown_z = station(x)
    # Two raised lines over the powertrain blend away at the cowl and nose.
    hood = max(0, 1-((x-1.39)/.68)**2) if x >= FRONT_GLASS_BASE else 0
    crease = max(0, 1-abs(abs(across)-.68)/.32)
    return x, half*across, edge_z+(crown_z-edge_z)*(1-across**2)+.021*hood*crease


def trim(name, parent, points, material, radius=.006):
    return instance(name, parent, tube(name, points, radius, material, sides=6))


def build_body(parent, material):
    shell = empty("body_shell", parent)
    body = material["body"]
    glass = material["glass"]
    edge = material["edge"]
    for name, first, last, skin in [
        ("tailgate_lower", -2.10, REAR_GLASS_BASE, body),
        ("rear_windshield", REAR_GLASS_BASE, REAR_GLASS_TOP, glass),
        ("roof", REAR_GLASS_TOP, FRONT_GLASS_TOP, body),
        ("windshield", FRONT_GLASS_TOP, FRONT_GLASS_BASE, glass),
        ("hood", FRONT_GLASS_BASE, 2.02, body), ("nose", 2.02, 2.10, body),
    ]:
        rows = [[top_point(x, f) for f in TOP_SAMPLES] for x in samples(first, last)]
        instance(name, shell, ribbon(name, rows, skin, reverse=True))

    arch_samples = {
        axle: sorted({round(x + ARCH_RADIUS*math.cos(i*math.pi/40), 6) for i in range(41)})
        for axle, x in (("F", 1.30), ("R", -1.30))
    }
    arch_stations = arch_samples["F"] + arch_samples["R"]
    for side, code in [(1, "L"), (-1, "R")]:
        for name, first, last in [
            ("bumper_rear", -2.10, -1.91), ("rear_quarter", -1.91, -1.17),
            ("rear_door", -1.17, -.27), ("front_door", -.27, .64),
            ("front_fender", .64, 1.90), ("bumper_front", 1.90, 2.10),
        ]:
            key = f"{name}_{code}"
            xs = sorted(set(samples(first, last, step=.046)) |
                        {x for x in arch_stations if first < x < last})
            rows = [[side_point(x, side, h) for h in (0, .23, .55, .80, 1)]
                    for x in xs]
            instance(key, shell, ribbon(key, rows, body, reverse=(side < 0)))
        for name, first, last, skin in [
            ("rear_cap", -2.10, REAR_GLASS_BASE, body),
            ("C_pillar", REAR_GLASS_BASE, -1.37, body), ("rear_window", -1.37, -.30, glass),
            ("B_pillar", -.30, -.24, body), ("front_window", -.24, .55, glass),
            ("A_pillar", .55, FRONT_GLASS_BASE, body),
            ("hood_shoulder", FRONT_GLASS_BASE, 2.10, body),
        ]:
            key = f"{name}_{code}"
            rows = [[upper_point(x, side, h) for h in (0, .4, .75, 1)]
                    for x in samples(first, last)]
            instance(key, shell, ribbon(key, rows, skin, reverse=(side < 0)))
        for name, first, last, height, radius in [
            ("shoulder", -2.1, 2.1, 0, .009),
            ("roof_rail", REAR_GLASS_BASE, FRONT_GLASS_BASE, 1, .011),
            ("hood_edge", FRONT_GLASS_BASE, 2.02, 1, .006),
        ]:
            trim(f"{name}_{code}", shell,
                 [upper_point(x, side, height) for x in samples(first, last)], edge, radius)
        trim(f"hood_crease_{code}", shell,
             [top_point(x, side*.68) for x in samples(.93, 2.02)], edge, .004)
        for axle, xs in arch_samples.items():
            outline = [side_point(p, side, 0) for p in xs]
            trim(f"wheel_arch_{axle}{code}", shell, outline, edge, .012)
            liner = [[(p[0], p[1], p[2]),
                      (p[0], p[1]-side*.085, p[2]+.008)] for p in outline]
            key = f"wheel_liner_{axle}{code}"
            instance(key, shell, ribbon(key, liner, body))
        sill_points = [side_point(x, side, 0) for x in samples(-.945, .945)]
        skirt = [[(x, y, z), (x, y+side*.04, z-.052), (x, y+side*.026, z-.065)]
                 for x, y, z in sill_points]
        key = f"side_skirt_{code}"
        instance(key, shell, ribbon(key, skirt, body, reverse=(side < 0)))
        trim(f"rocker_{code}", shell, [row[1] for row in skirt], edge, .009)
        trim(f"door_scallop_{code}", shell,
             [side_point(x, side, .23+.11*(x+.90)) for x in samples(-.91, .77)],
             edge, .004)
        for x, door in [(-1.17, "rear"), (-.27, "center"), (.64, "front")]:
            trim(f"{door}_door_seam_{code}", shell,
                 [side_point(x, side, h) for h in (.08, .25, .45, .65, .85, 1)], edge, .004)
        for x, door in [(-.99, "rear"), (-.07, "front")]:
            trim(f"{door}_handle_{code}", shell,
                 [(p, y+side*.013, z) for p, y, z in
                  [side_point(x-.065, side, .84), side_point(x+.065, side, .84)]], edge, .010)
        trim(f"mirror_mount_{code}", shell, [(.487, side*.783, .817),
                                           (.449, side*.839, .863)], edge, .011)
        mirror = f"mirror_housing_{code}"
        instance(mirror, shell, box(mirror, (.126, .10, .063), body, .028),
                 (.437, side*.851, .877), (0, .11, -side*.23))
        trim(f"mirror_edge_{code}", shell, [(.384, side*.807, .876),
                                          (.373, side*.864, .879),
                                          (.395, side*.900, .884)], edge, .005)

    build_fascias(shell, material, top_point, side_point)
    build_lamps(shell, material)
    for name, x in [("windshield_base", FRONT_GLASS_BASE), ("windshield_header", FRONT_GLASS_TOP),
                    ("rear_glass_header", REAR_GLASS_TOP), ("rear_glass_base", REAR_GLASS_BASE)]:
        trim(name, shell, [top_point(x, f) for f in TOP_SAMPLES], edge, .007)

    chassis = empty("chassis", parent)
    for label, dims, pos in [
        ("floor_pan", (2.16, 1.32, .055), (-.22, 0, .297)),
        ("front_crossmember", (.16, 1.26, .10), (1.48, 0, .316)),
        ("rear_crossmember", (.15, 1.31, .10), (-1.38, 0, .315)),
        ("front_crash_beam", (.11, 1.4, .09), (1.94, 0, .415)),
        ("rear_crash_beam", (.13, 1.43, .09), (-1.94, 0, .414)),
    ]:
        instance(label, chassis, box(label, dims, material["structure"], .022), pos)
    rail = box("side_rail_geo", (3.43, .104, .13), material["structure"], .034)
    for side, code in [(1, "L"), (-1, "R")]:
        instance(f"side_rail_{code}", chassis, rail, (0, side*.49, .332))
