import math

from mathutils import Vector

from geometry import box, cylinder, empty, instance, lathe, ribbon, tube


Y_AXIS = (-math.pi/2, 0, 0)


def build_engine(parent, material, register):
    metal = material["mechanical"]
    cast = material["structure"]
    bright = material["rim"]
    accent = material["interactive"]

    def casting(name, dimensions, location, bevel=.03, skin=metal, group=parent):
        return instance(name, group, box(name, dimensions, skin, bevel), location)

    def part(name, label, dimensions, location, camera="engine_overview", radius=.10, **kwargs):
        obj = casting(name, dimensions, location, **kwargs)
        register(obj, label, "engine", camera, radius, assembly="engine")
        return obj

    block = empty("engine_block", parent, (1.35, .168, .505))
    casting("block_casting", (.308, .508, .237), (0, 0, 0), .042, metal, block)
    boss = cylinder("Cylinder casting relief", .067, .158, bright, segments=20)
    for index in range(4):
        y = (index-1.5)*.112
        for x, code in [(.122, "front"), (-.119, "rear")]:
            instance(f"cylinder_boss_{code}_{index+1}", block, boss, (x, y, .011))
    register(block, "Blocco motore · 4 cilindri in linea", "engine", "engine_overview", .215,
             assembly="engine")

    head = empty("cylinder_head", parent, (1.344, .168, .687))
    casting("head_casting", (.329, .525, .115), (0, 0, 0), .026, bright, head)
    casting("cam_cover", (.29, .511, .057), (0, 0, .061), .022, cast, head)
    coil = box("Ignition coil pack", (.083, .067, .026), bright, .007)
    for index in range(4):
        instance(f"ignition_coil_{index+1}", head, coil, (.014, (index-1.5)*.108, .095))
    instance("oil_fill_cap", head, cylinder("Fill cap", .026, .016, accent, segments=16),
             (-.076, .189, .094))
    register(head, "Testata e coperchio punterie", "engine", "engine_overview", .14,
             assembly="engine")
    part("oil_pan", "Coppa dell’olio", (.295, .409, .125), (1.322, .16, .354),
         "oil_filter_closeup", .12, bevel=.037, skin=cast)
    oil = empty("oil_filter", parent, (1.543, .31, .447))
    shell = lathe("Oil filter canister", [
        (0, -.055), (.035, -.055), (.041, -.048), (.041, .035),
        (.038, .046), (.029, .052), (0, .052),
    ], accent, closed=False)
    instance("oil_filter_canister", oil, shell, rotation=(0, 1.26, 0))
    mount = cylinder("Filter threaded flange", .046, .017, bright, segments=18)
    instance("oil_filter_flange", oil, mount, (-.049, 0, -.015), (0, 1.26, 0))
    register(oil, "Filtro olio", "engine", "oil_filter_closeup", .075, assembly="engine")

    timing = empty("timing_drive", parent)
    pivots = [(1.336, .457, .445, .066), (1.246, .457, .696, .069),
              (1.432, .457, .696, .069), (1.492, .457, .574, .042)]
    pulleys = empty("timing_pulley", timing, (1.34, .457, .664))
    for index, (x, y, z, radius) in enumerate(pivots[:3]):
        key = f"timing_sprocket_{index+1}"
        data = cylinder(key, radius, .032, bright, segments=32)
        instance(key, pulleys, data, (x-1.34, y-.457, z-.664), Y_AXIS)
    register(pulleys, "Pulegge distribuzione", "engine", "timing_system_closeup", .08,
             anchor=(1.24, .48, .69), assembly="engine")
    tensioner = instance("timing_tensioner", timing, cylinder("Trinchetto", .026, .031, bright),
                         (1.376, .457, .55), Y_AXIS)
    register(tensioner, "Tendicinghia", "engine", "timing_system_closeup", .043, assembly="engine")
    pump = empty("water_pump", timing, (1.492, .457, .574))
    instance("water_pump_housing", pump, cylinder("Pump body", .055, .084, cast), (0, -.042, 0), Y_AXIS)
    instance("water_pump_sprocket", pump, cylinder("Pump sprocket", .042, .031, bright),
             rotation=Y_AXIS)
    register(pump, "Pompa dell’acqua", "engine", "timing_system_closeup", .060,
             assembly="engine")

    # The convex envelope of the pulleys gives straight belt runs tangent to
    # each sprocket. The visible ribbon is the width of the belt along Y.
    envelope = []
    for index in range(144):
        angle = index*math.tau/144
        cos, sin = math.cos(angle), math.sin(angle)
        x, _, z, radius = max(pivots, key=lambda p: p[0]*cos+p[2]*sin+p[3])
        envelope.append((x+(radius+.004)*cos, z+(radius+.004)*sin, cos, sin))
    rows = [[(x, .436, z), (x, .476, z),
             (x-.008*cos, .476, z-.008*sin), (x-.008*cos, .436, z-.008*sin),
             (x, .436, z)] for x, z, cos, sin in [*envelope, envelope[0]]]
    belt = instance("timing_belt", timing, ribbon("Toothed timing belt", rows, accent))
    register(belt, "Cinghia di distribuzione", "engine", "timing_system_closeup", .062,
             anchor=(1.34, .477, .769), assembly="engine")

    intake = empty("intake_manifold", parent, (1.08, .174, .674))
    casting("intake_plenum", (.125, .462, .087), (-.065, 0, -.039), .030, cast, intake)
    for index in range(4):
        key = f"intake_runner_{index+1}"
        y = (index-1.5)*.109
        path = [(-.065, y, -.02), (-.049, y, .052), (.004, y, .086),
                (.060, y, .063), (.105, y, .023)]
        instance(key, intake, tube(key, path, .023, bright, sides=10))
    register(intake, "Collettore di aspirazione", "engine", "engine_overview", .125, assembly="engine")
    air = empty("air_intake", parent, (1.23, -.538, .676))
    casting("air_box", (.247, .24, .106), (0, 0, 0), .026, cast, air)
    path = [(0, .07, 0), (-.075, .157, .013), (-.16, .225, .006), (-.207, .467, -.012)]
    instance("air_duct", air, tube("Air intake duct", path, .034, cast, sides=12))
    register(air, "Aspirazione e scatola filtro aria", "engine", "engine_overview", .11, assembly="engine")
    battery = empty("battery", parent, (1.639, -.53, .611))
    casting("battery_case", (.239, .246, .152), (0, 0, 0), .020, cast, battery)
    casting("battery_lid", (.249, .256, .025), (0, 0, .078), .007, bright, battery)
    for y, name, skin in [(.083, "positive", accent), (-.083, "negative", bright)]:
        instance(f"battery_terminal_{name}", battery, cylinder(name, .014, .017, skin), (.071, y, .1))
    register(battery, "Batteria 12 V", "electrical", "engine_overview", .12, assembly="engine")

    radiator = empty("radiator", parent, (1.863, 0, .485))
    casting("radiator_core", (.055, .848, .285), (0, 0, 0), .014, cast, radiator)
    fin = box("Cooling rib", (.009, .815, .005), bright, .001)
    for index in range(16):
        instance(f"radiator_fin_{index+1:02d}", radiator, fin, (.031, 0, .016*(index-7.5)))
    path = [(1.86, .42, .568), (1.79, .50, .56), (1.67, .51, .56), (1.50, .41, .568)]
    instance("coolant_hose", radiator, tube("Upper radiator hose", path, .017, cast),
             (-1.863, 0, -.485))
    register(radiator, "Radiatore e manicotto", "cooling", "engine_overview", .135, assembly="engine")


def build_transmission(parent, material, register):
    cast, bright = material["structure"], material["rim"]
    for name, label, location, profile, skin in [
        ("clutch", "Frizione", (1.345, -.145, .505),
         [(0, -.048), (.124, -.048), (.155, -.023), (.155, .019), (.123, .048), (0, .048)], bright),
        ("gearbox", "Cambio manuale", (1.344, -.365, .493),
         [(0, -.211), (.076, -.211), (.12, -.174), (.134, -.089), (.152, .107),
          (.134, .174), (0, .174)], cast),
        ("differential", "Differenziale anteriore", (1.30, -.309, .330),
         [(0, -.117), (.082, -.117), (.112, -.079), (.112, .085), (.083, .126), (0, .126)], bright),
    ]:
        obj = instance(name, parent, lathe(label, profile, skin, closed=False), location, Y_AXIS)
        register(obj, label, "transmission", "gearbox_closeup", .115, assembly="engine")
    shafts = empty("driveshafts", parent)
    for code, side, first in [("L", 1, -.18), ("R", -1, -.433)]:
        start = Vector((1.30, first, .33))
        end = Vector((1.30, side*.713, .329))
        delta = end-start
        pivot = start.lerp(end, .5)
        name = f"driveshaft_{code}"
        rotation = delta.to_track_quat("Z", "Y").to_euler()
        axle = empty(name, shafts, pivot)
        instance(f"shaft_{code}", axle, cylinder(name, .021, delta.length, bright), rotation=rotation)
        for label, fraction in [("inner", .10), ("outer", .93)]:
            cv = lathe(f"CV boot {label}", [
                (0, -.04), (.034, -.04), (.047, -.026), (.034, -.014), (.045, 0),
                (.032, .013), (.04, .025), (.025, .035), (0, .035),
            ], cast, segments=20, closed=False)
            instance(f"cv_boot_{label}_{code}", axle, cv, delta*(fraction-.5), rotation)
        register(axle, f"Semiasse {'sinistro' if side > 0 else 'destro'}", "transmission",
                 "gearbox_closeup", .086, assembly="engine")


def build_other(parent, material, register):
    exhaust = empty("exhaust_system", parent, (-.40, -.121, .241))
    path = [(1.51, .14, .583), (1.59, .14, .495), (1.58, .13, .355),
            (1.49, .10, .243), (1.13, .076, .224), (.76, -.079, .221), (.42, -.121, .221),
            (-.82, -.121, .221), (-1.12, -.348, .241), (-1.52, -.44, .254),
            (-1.88, -.44, .26), (-2.072, -.49, .267)]
    origin = exhaust.location.copy()
    instance("exhaust_pipe", exhaust, tube("Exhaust routing", [Vector(p)-origin for p in path],
                                          .026, material["rim"], sides=12))
    for name, position, radius, length in [
        ("exhaust_catalyst", (.99, .034, .234), .049, .21),
        ("exhaust_resonator", (-.45, -.121, .228), .060, .46),
        ("exhaust_muffler", (-1.68, -.44, .292), .081, .32),
    ]:
        instance(name, exhaust, cylinder(name, radius, length, material["mechanical"]),
                 Vector(position)-origin, (0, math.pi/2, 0))
    register(exhaust, "Impianto di scarico", "exhaust", "underbody", .12)
    tank = instance("fuel_tank", parent,
                    box("Fuel tank", (.556, .715, .155), material["structure"], .065),
                    (-.93, .29, .275))
    register(tank, "Serbatoio carburante", "fuel", "underbody", .135)
