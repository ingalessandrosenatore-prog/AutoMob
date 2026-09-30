"""Independent soft knuckle curls for the free hand, including the hair gesture."""
import math
import bpy
from mathutils import Quaternion, Vector

FINGERS = [("index", -.086), ("middle", -.024), ("ring", .040), ("little", .094)]


def ensure_relaxed_fingers(rig):
    if "finger.index.R" in rig.data.bones:
        return
    wrist = rig.data.bones["wrist.R"].head_local.copy()
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for name, lane in FINGERS:
        bone = rig.data.edit_bones.new("finger." + name + ".R")
        bone.head = wrist + Vector((.008, lane, -.18))
        bone.tail = wrist + Vector((.035, lane, -.29))
        bone.parent = rig.data.edit_bones["hand.relaxed.R"]
    bpy.ops.object.mode_set(mode="OBJECT")
    body = bpy.data.objects[rig["pose"] + "_BODY"]
    palm = body.vertex_groups["hand.relaxed.R"]
    groups = {name: body.vertex_groups.new(name="finger." + name + ".R") for name, _ in FINGERS}
    for vertex in body.data.vertices:
        weight = next((g.weight for g in vertex.groups if g.group == palm.index), 0)
        local = vertex.co - wrist
        # Restrict the curl to fingers below the palm; the thumb stays separate.
        if not weight or local.z >= -.18 or local.y < -.125:
            continue
        name, _ = min(FINGERS, key=lambda finger: abs(local.y - finger[1]))
        influence = max(0, min(1, (-local.z - .18) / .065))
        groups[name].add([vertex.index], weight * influence, "REPLACE")
        palm.add([vertex.index], weight * (1 - influence), "REPLACE")
    for name, _ in FINGERS:
        rig.pose.bones["finger." + name + ".R"].rotation_mode = "QUATERNION"


def pose_fingers(rig, prop, gesture, t):
    from idle_motion import beat, grooming
    reach = grooming(t) if gesture == "idle" and prop != "tablet" else 0
    for index, (name, _) in enumerate(FINGERS):
        bone = rig.pose.bones["finger." + name + ".R"]
        axis = bone.bone.matrix_local.to_3x3().inverted() @ Vector((0, 1, 0))
        # Fingers curl at slightly different rates; only the knuckles flex,
        # so the palm does not flap like a rigid paddle against the head.
        scratch = .16 * math.sin(math.tau * 2.4 * t + index * .65) * beat(t, 4.35, 5.75)
        curl = .20 + index * .045 + reach * (.24 + scratch)
        bone.rotation_quaternion = Quaternion(axis, -curl)
