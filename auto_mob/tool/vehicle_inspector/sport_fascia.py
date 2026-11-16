from geometry import instance, mesh, ribbon, tube


def outline(name, parent, points, material, radius, *, closed=False):
    return instance(name, parent, tube(name, points, radius, material, sides=6, closed=closed))


def skin(name, parent, rows, material, *, reverse=False):
    return instance(name, parent, ribbon(name, rows, material, reverse=reverse))


def build_fascias(shell, materials, top_point, side_point):
    body, glass, edge = (materials[key] for key in ("body", "glass", "edge"))
    sections = (-1, -.84, -.66, -.45, -.23, 0, .23, .45, .66, .84, 1)
    # Wrap the lower bumper back towards the wheels at each corner.
    for name, x, direction in [("front_fascia", 2.10, 1), ("rear_fascia", -2.10, -1)]:
        rows = []
        for section in sections:
            top = top_point(x, section)
            width = .765 if direction > 0 else .80
            lower_x = x-direction*(.016+.115*abs(section)**3)
            rows.append([
                (lower_x, width*section, .276 if direction > 0 else .300),
                (lower_x, width*section, .398 if direction > 0 else .421),
                (x-direction*.03*abs(section), top[1]*1.065, top[2]-.09),
                top,
            ])
        skin(name, shell, rows, body, reverse=direction > 0)
        lip = [[(a-direction*.075, b, z), (a, b, z), (a, b*.981, z-.024)]
               for a, b, z in (row[0] for row in rows)]
        key = "front_splitter" if direction > 0 else "rear_diffuser"
        skin(key, shell, lip, body)
        outline(f"{key}_edge", shell, [row[1] for row in lip], edge, .008)
        for side, code in [(1, "L"), (-1, "R")]:
            outer = rows[-1] if side > 0 else rows[0]
            x_corner = outer[0][0]
            side_curve = [side_point(x_corner, side, h) for h in (0, .29, .68, 1)]
            end_curve = [side_point(x, side, h) for h in (0, .29, .68, 1)]
            skin(f"{key}_return_{code}", shell, [outer, side_curve, end_curve], body)

    shield = [(2.105, y, z) for y, z in [
        (-.201, .623), (-.159, .655), (-.068, .677), (0, .682),
        (.068, .677), (.159, .655), (.201, .623), (.166, .536),
        (.113, .447), (.049, .354), (0, .320),
        (-.049, .354), (-.113, .447), (-.166, .536),
    ]]
    outline("center_shield_rim", shell, shield, edge, .012, closed=True)
    instance("center_shield_insert", shell, mesh("Center shield", shield,
                                                [tuple(reversed(range(len(shield))))], glass))
    for i, (height, half_width) in enumerate([
        (.384, .055), (.422, .081), (.460, .106), (.498, .128),
        (.536, .150), (.574, .169), (.612, .180),
    ], start=1):
        outline(f"center_shield_slat_{i}", shell,
                [(2.108, -half_width, height), (2.108, 0, height+.005),
                 (2.108, half_width, height)], edge, .0035)

    for side, code in [(1, "L"), (-1, "R")]:
        intake = [(x, side*y, z) for x, y, z in [
            (2.095, .168, .324), (2.095, .226, .467), (2.065, .427, .498),
            (2.015, .622, .502), (1.968, .749, .459), (1.997, .666, .343),
            (2.04, .544, .321), (2.09, .306, .313),
        ]]
        outline(f"bumper_intake_{code}", shell, intake, edge, .011, closed=True)
        rows = [[point, (point[0]-.056, point[1]*.96, .409+(point[2]-.409)*.73)]
                for point in [*intake, intake[0]]]
        skin(f"bumper_intake_wall_{code}", shell, rows, body)
        for index, z in enumerate((.363, .399, .435), start=1):
            outline(f"intake_vane_{code}_{index}", shell,
                    [(2.093, side*.246, z), (2.069, side*.425, z+.007),
                     (2.009, side*.632, z+.018)], edge, .005)

    lip = [(-2.008+.147*abs(f)**1.8, .710*f, .840-.037*f*f) for f in sections]
    outline("rear_deck_lip", shell, lip, edge, .012)
    for i, y in enumerate((-.30, -.14, .14, .30), start=1):
        rows = [[(x, y-.014, z), (x, y+.014, z), (x, y+.014, z-.054)]
                for x, z in [(-1.99, .297), (-2.055, .304), (-2.079, .318)]]
        skin(f"diffuser_fin_{i}", shell, rows, body)


def build_lamps(shell, materials):
    glass, light, rear_light = (materials[key] for key in ("glass", "lamp", "rear_lamp"))
    for side, code in [(1, "L"), (-1, "R")]:
        # The very thin lens tapers from the wing towards the center shield.
        lamp_profile = [(2.094, .253, .592, .021), (2.070, .377, .623, .044),
                        (2.023, .533, .649, .064), (1.958, .678, .668, .060),
                        (1.854, .774, .676, .042), (1.760, .821, .684, .008)]
        rows = [[(x, side*y, z-w*.48), (x+.004, side*y, z), (x, side*y, z+w*.52)]
                for x, y, z, w in lamp_profile]
        skin(f"headlight_{code}", shell, rows, glass)
        outline(f"headlight_brow_{code}", shell, [row[2] for row in rows], light, .008)
        for index, (x, y, z) in enumerate([(2.051, .427, .632), (2.014, .560, .651),
                                           (1.962, .674, .667)], start=1):
            outline(f"headlight_arc_{code}_{index}", shell,
                    [(x+.008, side*(y-.037), z-.003), (x+.008, side*(y-.026), z-.019),
                     (x+.007, side*(y+.011), z-.013), (x+.001, side*(y+.035), z+.008)],
                    light, .005)
        tail = [(-2.094, side*.289, .657), (-2.075, side*.464, .681),
                (-2.013, side*.613, .711), (-1.930, side*.728, .746),
                (-1.829, side*.823, .771)]
        outline(f"taillight_{code}", shell, tail, rear_light, .013)
        outline(f"taillight_return_{code}", shell,
                [(x+.009, y, z-.030) for x, y, z in tail[1:]], rear_light, .0055)
