"""Mirror existing hand geometry for a receiving grip and a relaxed left hand."""
import bpy
from mathutils import Quaternion, Vector


def mirrored_hand(body, source_groups, name, origin, destination, target):
    groups = {body.vertex_groups[key].index for key in source_groups}
    selected = {v.index for v in body.data.vertices
                if any(g.group in groups and g.weight > 0 for g in v.groups)}
    indices = sorted(selected)
    lookup = {old: new for new, old in enumerate(indices)}
    vertices = []
    for index in indices:
        vertex = body.data.vertices[index]
        point = vertex.co.copy()
        for group in vertex.groups:
            key = body.vertex_groups[group.group].name
            if key.startswith("finger."):
                pivot = body.parent.data.bones[key].head_local
                curled = pivot + Quaternion((0, 1, 0), -.28) @ (vertex.co - pivot)
                point += group.weight * (curled - vertex.co)
        point -= origin
        vertices.append(destination + Vector((-point.x, point.y, point.z)))
    polygons = [p for p in body.data.polygons if all(i in selected for i in p.vertices)]
    data = bpy.data.meshes.new(name)
    # Reflection reverses winding; reverse faces to retain outward normals.
    data.from_pydata(vertices, [], [tuple(lookup[i] for i in reversed(p.vertices)) for p in polygons])
    for material in body.data.materials:
        data.materials.append(material)
    for face, original in zip(data.polygons, polygons):
        face.material_index = original.material_index
        face.use_smooth = True
    obj = bpy.data.objects.new(name, data)
    target.objects.link(obj)
    obj.vertex_groups.new(name=name).add(list(range(len(vertices))), 1, "REPLACE")
    return obj


def ensure_handoff_hands(rig):
    if "hand.closed.R" in rig.data.bones:
        return
    body = bpy.data.objects[rig["pose"] + "_BODY"]
    left = rig.data.bones["wrist.L"].head_local.copy()
    right = rig.data.bones["wrist.R"].head_local.copy()
    target = body.users_collection[0]
    pieces = [mirrored_hand(body, ["hand.closed"], "hand.closed.R", left, right, target),
              mirrored_hand(body, ["hand.relaxed.R"] + ["finger." + finger + ".R"
                            for finger in ["index", "middle", "ring", "little"]],
                            "hand.relaxed.L", right, left, target)]
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for name, point, parent in [("hand.closed.R", right, "wrist.R"),
                                ("hand.relaxed.L", left, "wrist.L")]:
        bone = rig.data.edit_bones.new(name)
        bone.head = point
        bone.tail = point + Vector((0, 0, .12))
        bone.parent = rig.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    for name in ["hand.closed.R", "hand.relaxed.L"]:
        rig.pose.bones[name].rotation_mode = "QUATERNION"
    # Keep the existing body's modifier and vertex groups as the join target.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [body] + pieces:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
