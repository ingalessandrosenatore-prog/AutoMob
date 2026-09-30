"""A small skeletal rig; limb weights are blended around the elbow."""
import bpy
from mathutils import Vector
from mesh_tools import weight


def make_rig(pose, target):
    dz = -.23 if pose == "desk" else 0
    data = bpy.data.armatures.new(pose + "_skeleton")
    rig = bpy.data.objects.new("AM_" + pose.upper(), data)
    target.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    rests = {}

    def bone(name, head, tail=None, parent="root"):
        item = data.edit_bones.new(name)
        item.head = head
        item.tail = tail if tail is not None else Vector(head) + Vector((0, 0, .12))
        if parent:
            item.parent = data.edit_bones[parent]
        rests[name] = Vector(head)
        return item

    bone("root", (0, 0, 0), parent=None)
    bone("head", (0, 0, 3.70+dz))
    for side, sign in [("R", -1), ("L", 1)]:
        bone("eye."+side, (sign*.24, -.456, 4.53+dz), parent="head")
        bone("brow."+side, (sign*.24, -.47, 4.78+dz), parent="head")
        shoulder = Vector((sign*.54, 0, 3.38+dz))
        elbow = Vector((sign*.86, -.04, 2.95+dz))
        wrist = Vector((.93, -.38, 3.40+dz) if sign == 1 else (-.81, -.48, 2.71+dz))
        bone("upper."+side, shoulder, elbow)
        bone("lower."+side, elbow, wrist)
        bone("wrist."+side, wrist)
    wrist = rests["wrist.L"]
    for mode in ["closed", "point", "tap", "open"]:
        bone("hand."+mode, wrist, parent="wrist.L")
    for mode in ["relaxed", "support"]:
        bone("hand."+mode+".R", rests["wrist.R"], parent="wrist.R")
    bone("wrench", wrist+Vector((0, -.11, .12)))
    bone("screwdriver", wrist+Vector((0, -.11, .12)))
    bone("tablet", (-.35, -.69, 3.18+dz))
    bone("tire", (1.12, -.30, 1.98))
    bone("smile", (0, -.48, 4.07+dz), parent="head")
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
    rig["pose"] = pose
    return rig, rests


def bind_body(obj, original_name, rig, rests):
    name = original_name.split("_", 1)[1]
    if "ClosedFist" in name or "Thumbnail" in name:
        weight(obj, "hand.closed")
    elif "Hand_-1" in name:
        weight(obj, "hand.support.R")
    elif "Forearm" in name:
        side = "L" if ".001" in name else "R"
        a, b = rests["upper."+side], rests["lower."+side]
        c = rests["wrist."+side]
        def distance(point, start, end):
            segment = end-start
            t = max(0, min(1, (point-start).dot(segment)/segment.length_squared))
            return (point-(start+segment*t)).length
        for vertex in obj.data.vertices:
            # Across a short elbow band both segments contribute continuously.
            du = distance(vertex.co, a, b)
            dl = distance(vertex.co, b, c)
            t = max(0, min(1, .5+(du-dl)/.20))
            if t < 1:
                weight(obj, "upper."+side, [vertex.index], 1-t)
            if t > 0:
                weight(obj, "lower."+side, [vertex.index], t)
    elif "Sleeve" in name:
        weight(obj, "upper.L" if ".001" in name else "upper.R")
    elif "BlackEye" in name or "EyeGlint" in name:
        weight(obj, "eye.L" if ".001" in name else "eye.R")
    elif "Eyebrow" in name:
        weight(obj, "brow.L" if ".001" in name else "brow.R")
    elif "GentleSmile" in name:
        weight(obj, "smile")
    elif any(k in name for k in ["SoftFace", "Ear", "Hair", "Quiff", "SideLock"]):
        weight(obj, "head")
    else:
        weight(obj, "root")
