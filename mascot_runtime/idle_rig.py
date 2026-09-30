"""Add breathing and heel controls to the existing, approved runtime mesh."""
import bpy
from mathutils import Vector


def ensure_idle_controls(rig):
    if "torso" in rig.data.bones:
        return
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    dz = -.23 if rig["pose"] == "desk" else 0
    controls = {"torso": (0, 0, 2.25 + dz)}
    if rig["pose"] == "standing":
        controls.update({"heel.L": (.34, -.59, .03), "heel.R": (-.34, -.59, .03)})
    for name, point in controls.items():
        bone = rig.data.edit_bones.new(name)
        bone.head = point
        bone.tail = Vector(point) + Vector((0, 0, .15))
        bone.parent = rig.data.edit_bones["root"]
    bpy.ops.object.mode_set(mode="OBJECT")
    for name in controls:
        rig.pose.bones[name].rotation_mode = "QUATERNION"
    body = bpy.data.objects[rig["pose"] + "_BODY"]
    root = body.vertex_groups["root"]
    groups = {name: body.vertex_groups.new(name=name) for name in controls}
    # Only redistribute root weights: hand, face and elbow skinning stays intact.
    # The waist/ankle bands avoid a hard seam where moving parts meet the body.
    for vertex in body.data.vertices:
        weight = next((g.weight for g in vertex.groups if g.group == root.index), 0)
        if not weight:
            continue
        z = vertex.co.z
        name, influence = "torso", max(0, min(1, (z - (2.1 + dz)) / .45))
        if rig["pose"] == "standing" and z < 1.2:
            name = "heel.L" if vertex.co.x > 0 else "heel.R"
            influence = max(0, min(1, (1.2 - z) / .55))
        if influence:
            groups[name].add([vertex.index], weight * influence, "REPLACE")
            root.add([vertex.index], weight * (1 - influence), "REPLACE")
