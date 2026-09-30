"""Add hip, knee and ankle deformation to the standing trousers and boots."""
import bpy
from mathutils import Vector


def ensure_leg_controls(rig):
    if rig["pose"] != "standing" or "thigh.L" in rig.data.bones:
        return
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    names = []
    for side, x in [("L", .34), ("R", -.34)]:
        for part, height in [("thigh", 2.15), ("shin", 1.25), ("foot", .45)]:
            name = part + "." + side
            bone = rig.data.edit_bones.new(name)
            bone.head = (x, 0, height)
            bone.tail = (x, 0, height - .15)
            bone.parent = rig.data.edit_bones["root"]
            names.append(name)
    bpy.ops.object.mode_set(mode="OBJECT")
    for name in names:
        rig.pose.bones[name].rotation_mode = "QUATERNION"
    body = bpy.data.objects["standing_BODY"]
    groups = {name: body.vertex_groups.new(name=name) for name in names}
    old = {body.vertex_groups[name].index: body.vertex_groups[name]
           for name in ["root", "heel.L", "heel.R"]}
    for vertex in body.data.vertices:
        if vertex.co.z >= 2.25:
            continue
        available = sum(g.weight for g in vertex.groups if g.group in old)
        if not available:
            continue
        z = vertex.co.z
        side = "L" if vertex.co.x > 0 else "R"
        influence = max(0, min(1, (2.25 - z) / .20))
        thigh = max(0, min(1, (z - 1.10) / .30))
        foot = max(0, min(1, (.78 - z) / .20))
        for group in old.values():
            group.remove([vertex.index])
        body.vertex_groups["root"].add([vertex.index], available * (1 - influence), "REPLACE")
        for part, weight in [("thigh", thigh), ("shin", 1 - thigh - foot), ("foot", foot)]:
            if weight > 0:
                groups[part + "." + side].add([vertex.index], available * influence * weight, "REPLACE")
