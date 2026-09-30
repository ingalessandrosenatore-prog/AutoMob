"""Prepare compact, editable meshes and plain glTF-compatible materials."""
import bpy
from mathutils import Matrix, Vector


def material(name, color, metal=0, rough=.6):
    found = bpy.data.materials.get(name)
    if found:
        return found
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    shader = next(n for n in result.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metal
    shader.inputs["Roughness"].default_value = rough
    return result


def runtime_material(original, object_name):
    key = original.name
    clothing = any(word in object_name for word in (
        "Tshirt", "Sleeve", "Overall", "Pocket", "Strap", "BuckleInset",
        "Belt", "Cargo", "ClothFold", "Boot", "Outsole", "Collar"))
    if clothing and key in {"AM2_red", "AM2_blue"} or "Laces" in object_name:
        return material("AM_Clothes_Accent", (.8, .16, .015))
    if clothing and key in {"AM2_shirt", "AM2_pants", "AM2_black", "AM2_sole"}:
        return material("AM_Clothes_Base", (.028, .036, .049), rough=.78)
    shader = next((n for n in original.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    color = tuple(shader.inputs["Base Color"].default_value[:3]) if shader else original.diffuse_color[:3]
    return material("RT_" + key, color,
                    shader.inputs["Metallic"].default_value if shader else 0,
                    shader.inputs["Roughness"].default_value if shader else .6)


def collection(name, scene):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


def copy_mesh(source, target, offset=(0, 0, 0), budget=800):
    # Evaluate bevel/subdivision once, then reduce only the runtime copy.
    evaluated = source.evaluated_get(bpy.context.evaluated_depsgraph_get())
    data = bpy.data.meshes.new_from_object(evaluated)
    data.transform(Matrix.Translation(Vector(offset)) @ source.matrix_world)
    obj = bpy.data.objects.new("RT_" + source.name, data)
    target.objects.link(obj)
    for index, mat in enumerate(list(data.materials)):
        data.materials[index] = runtime_material(mat, source.name)
    data.calc_loop_triangles()
    count = len(data.loop_triangles)
    if count > budget:
        bpy.context.view_layer.objects.active = obj
        mod = obj.modifiers.new("Mobile geometry", "DECIMATE")
        mod.ratio = budget / count
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def weight(obj, bone, indices=None, value=1):
    group = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
    group.add(list(indices) if indices is not None else list(range(len(obj.data.vertices))), value, "REPLACE")


def join(objects, name, rig=None):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    result = bpy.context.object
    result.name = name
    if rig:
        result.parent = rig
        result.matrix_parent_inverse = Matrix.Identity(4)
        result.modifiers.new("Mascot rig", "ARMATURE").object = rig
    return result


def cube(name, center, half, mat, target, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=2, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.scale = half
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for col in list(obj.users_collection):
        col.objects.unlink(obj)
    target.objects.link(obj)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Rounded edges", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)
    return obj


def cylinder(name, center, radius, depth, mat, target):
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=radius, depth=depth, location=center)
    obj = bpy.context.object
    obj.name = name
    for col in list(obj.users_collection):
        col.objects.unlink(obj)
    target.objects.link(obj)
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    obj.data.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)
    return obj
