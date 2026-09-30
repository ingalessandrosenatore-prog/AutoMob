"""A spacious idle cycle with breathing and separated character gestures."""
import math
import bpy
from mathutils import Matrix, Quaternion, Vector

IDLE_DURATION = 24
# Keep choreography in its original time coordinates, but bake a more active
# 18-second loop. One-shot gestures keep their existing four-second timing.
IDLE_CLIP_DURATION = 18


def beat(t, start, end):
    if not start < t < end:
        return 0
    return math.sin(math.pi * (t - start) / (end - start)) ** 2


def grooming(t):
    from motion import smooth
    return smooth((t - 3.2) / 1.15) * (1 - smooth((t - 5.75) / 1.15))


def hands(prop, t, wrist, right, rotation, pose):
    wave = math.sin(math.tau * t / 8)
    inspect = beat(t, 1.0, 4.8)
    relax = beat(t, 4.7, 7.5)
    right_rotation = Quaternion()
    if prop in {"wrench", "screwdriver"}:
        lower = beat(t, .3, 7.8) + .72 * beat(t, 7.8, 23.8)
        # The counter limits how far the seated hand may drop. Standing tools
        # rest near the hip for most of the grooming gesture, then return softly.
        drop = .40 if pose == "desk" else .84
        wrist += Vector((.08 * lower - .08 * inspect, -.13 * lower, -drop * lower))
        rotation = Quaternion((0, 1, 0), .32 * lower + .10 * wave)
        rotation @= Quaternion((1, 0, 0), .13 * inspect)
    if prop != "tablet":
        right += Vector((-.08 * relax, -.20 * relax, .13 * relax))
        reach = grooming(t)
        dz = -.23 if pose == "desk" else 0
        target = Vector((-.80, .02, 4.16 + dz))
        target.z += .018 * math.sin(math.tau * 2.4 * (t - 4.35)) * beat(t, 4.35, 5.75)
        right = right.lerp(target, reach)
        # Lift around the outside of the shoulder, keeping the fingers clear
        # of the cheek while the relaxed palm turns toward the hair.
        right.x -= .30 * math.sin(math.pi * reach)
        right.y -= .23 * math.sin(math.pi * reach)
        right_rotation = Quaternion((1, 0, 0), math.pi * reach)
        right_rotation @= Quaternion((0, 1, 0), .10 * wave * (1 - reach))
    if prop == "tire":
        # Tire and hand receive the same displacement, maintaining their contact.
        wrist += Vector((.025 * wave, 0, .035 * inspect))
    return wrist, right, rotation, right_rotation


def body_transform(rig, rests, t):
    from motion import pivot
    from leg_motion import shoe_inspection
    breath = 1 - math.cos(math.tau * t / 4)
    shift = math.sin(math.tau * t / IDLE_DURATION)
    lift = shoe_inspection(t) if rig["pose"] == "standing" else 0
    rotation = Quaternion((0, 1, 0), .017 * shift - .035 * lift)
    rotation @= Quaternion((1, 0, 0), .08 * lift)
    return Matrix.Translation((.022 * shift - .10 * lift, -.035 * lift, .009 * breath)) @ pivot(rests["torso"], rotation)


def apply_body(rig, rests, prop, t):
    from motion import pivot
    change = body_transform(rig, rests, t)
    # Apply one common transform to torso, head, arms and accessories. Child
    # face/hand bones inherit it once, so grips and facial attachments stay rigid.
    names = [pb.name for pb in rig.pose.bones
             if pb.parent and pb.parent.name == "root" and not pb.name.startswith("heel.")]
    matrices = {name: rig.pose.bones[name].matrix.copy() for name in names}
    for name, matrix in matrices.items():
        rig.pose.bones[name].matrix = change @ matrix
    if rig["pose"] == "standing":
        for side, start, end in [("L", 4.9, 6.6), ("R", 6.5, 7.7)]:
            name = "heel." + side
            rotation = Quaternion((1, 0, 0), .075 * beat(t, start, end))
            rig.pose.bones[name].matrix = pivot(rests[name], rotation) @ rig.data.bones[name].matrix_local
        from leg_motion import pose_legs
        pose_legs(rig, rests, t)
    bpy.context.view_layer.update()
