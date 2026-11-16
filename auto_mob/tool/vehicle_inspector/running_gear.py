import math

from mathutils import Vector

from geometry import box, cylinder, empty, instance, lathe, tube


def build_wheels(parent, material, register):
    tire = lathe("Tire 205/50 R16", [
        (.202, -.091), (.234, -.103), (.277, -.104), (.301, -.094), (.319, -.075),
        (.328, -.052), (.329, -.027), (.326, -.024), (.326, -.019), (.329, -.016),
        (.329, .016), (.326, .019), (.326, .024), (.329, .027), (.328, .052),
        (.319, .075), (.301, .094), (.277, .104), (.234, .103), (.202, .091),
    ], material["rubber"], segments=48)
    barrel = lathe("Rim barrel", [
        (.183, -.099), (.205, -.099), (.207, -.086), (.197, -.072),
        (.194, .072), (.207, .086), (.205, .101), (.183, .101),
    ], material["rim"], segments=40)
    disc = lathe("Vented brake rotor", [
        (.061, -.015), (.134, -.015), (.145, -.010), (.145, .010),
        (.134, .015), (.061, .015),
    ], material["rim"], segments=36)
    hub = cylinder("Hub flange", .063, .095, material["structure"])
    bolt = cylinder("Wheel bolt", .008, .015, material["rim"], segments=6, bevel=.001)
    spoke = box("Tapered spoke", (.152, .029, .023), material["rim"], .008)
    cap = cylinder("Center cap", .051, .021, material["rim"])
    jaw = box("Caliper bridge", (.071, .063, .124), material["interactive"], .015)
    caliper_piston = cylinder("Caliper piston", .032, .044, material["interactive"])
    shock_body = cylinder("Damper housing", .035, .25, material["mechanical"])
    shock_rod = cylinder("Damper rod", .014, .25, material["rim"])
    spring_seat = cylinder("Spring seat", .079, .024, material["structure"])
    coil_path = [(.065*math.cos(i*math.tau/14), .065*math.sin(i*math.tau/14),
                  .48*(i/70-.5)) for i in range(71)]
    coil = tube("Coil spring", coil_path, .010, material["interactive"], sides=8)

    for axle, x, end, label in [("F", 1.30, "front", "anteriore"),
                                 ("R", -1.30, "rear", "posteriore")]:
        for side, code, flank, name in [(1, "L", "left", "sinistro"), (-1, "R", "right", "destro")]:
            corner = axle + code
            center = (x, side*.784, .329)
            group = empty(f"wheel_{corner}", parent, center)
            preset = f"{end}_{flank}_wheel"
            focus = f"{preset}_suspension"
            orientation = (-side*math.pi/2, 0, 0)
            rubber = instance(f"tire_{corner}", group, tire, rotation=orientation)

            rim = empty(f"rim_{corner}", group)
            instance(f"rim_barrel_{corner}", rim, barrel, rotation=orientation)
            instance(f"rim_cap_{corner}", rim, cap, (0, side*.091, 0), orientation)
            for index in range(5):
                angle = index*math.tau/5 + .21
                for shift in (-.088, .088):
                    theta = angle+shift
                    pos = (.117*math.cos(theta), side*.084, .117*math.sin(theta))
                    twin = "A" if shift < 0 else "B"
                    instance(f"spoke_{corner}_{index+1}{twin}", rim, spoke, pos,
                             (math.pi/2, -angle, 0))
                instance(f"lug_{corner}_{index+1}", rim, bolt,
                         (.032*math.cos(angle), side*.106, .032*math.sin(angle)), orientation)

            spindle = instance(f"hub_{corner}", group, hub, (0, -side*.052, 0), orientation)
            rotor = instance(f"brake_disc_{corner}", group, disc, (0, side*.032, 0), orientation)
            caliper = empty(f"brake_caliper_{corner}", group, (-.131, side*.031, .047))
            instance(f"caliper_bridge_{corner}", caliper, jaw, rotation=(0, .35, 0))
            instance(f"caliper_piston_{corner}", caliper, caliper_piston,
                     (.015, -side*.042, 0), orientation)

            bottom = Vector((-.049 if axle == "F" else .061, -side*.132, .069))
            top = Vector((bottom.x-.045, -side*.264, .433 if axle == "F" else .617))
            axis = top-bottom
            rotation = axis.to_track_quat("Z", "Y").to_euler()
            damper = empty(f"shock_absorber_{corner}", group, bottom.lerp(top, .47))
            for part, data, first, last in [("body", shock_body, 0, .56), ("rod", shock_rod, .49, 1)]:
                damper_part = instance(f"damper_{part}_{corner}", damper, data,
                                       axis*((first+last)/2-.47), rotation)
                damper_part.scale.z = axis.length*(last-first)/.25
            spring = empty(f"spring_{corner}", group, bottom.lerp(top, .58))
            winding = instance(f"spring_coil_{corner}", spring, coil, rotation=rotation)
            winding.scale.z = axis.length*.68/.48
            for nameplate, fraction in [("lower", .23), ("upper", .93)]:
                instance(f"spring_seat_{nameplate}_{corner}", spring, spring_seat,
                         axis*(fraction-.58), rotation)
            weld = f"steering_knuckle_{corner}"
            knuckle = [bottom, (-.015, -side*.106, -.006), (.013, -side*.097, -.069)]
            instance(weld, group, tube(weld, knuckle, .024, material["structure"]))
            arm = empty(f"control_arm_{corner}", group, (0, -side*.286, -.094))
            for endplate, position in [("front", (.218, -side*.137, .026)),
                                       ("rear", (-.172, -side*.152, .047))]:
                key = f"arm_link_{endplate}_{corner}"
                path = [position, (position[0]*.58, -side*.025, .006), (.013, side*.189, .044)]
                instance(key, arm, tube(key, path, .027, material["structure"]))
                instance(f"arm_bushing_{endplate}_{corner}", arm, hub, position, orientation).scale = (.57, .57, .54)

            suffix = f"{label} {name}"
            register(group, f"Gruppo ruota {suffix}", "wheels", preset, .30,
                     meshes=[rim, rubber], assembly=group.name)
            for obj, title, category, radius, camera in [
                (rubber, "Pneumatico", "wheels", .20, preset),
                (rim, "Cerchione", "wheels", .14, preset),
                (spindle, "Mozzo", "wheels", .06, preset),
                (rotor, "Disco freno", "brakes", .105, preset),
                (caliper, "Pinza freno", "brakes", .075, preset),
                (damper, "Ammortizzatore", "suspension", .105, focus),
                (spring, "Molla", "suspension", .10, focus),
                (arm, "Braccio sospensione", "suspension", .095, focus),
            ]:
                register(obj, f"{title} {suffix}", category, camera, radius, assembly=group.name)
