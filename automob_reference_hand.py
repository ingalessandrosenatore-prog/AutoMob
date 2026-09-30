"""Left power grip: shaped metacarpals, four curled fingers and opposed thumb."""

import bpy
import bmesh
from mathutils import Matrix, Vector


def _apply_surface(obj):
    bpy.context.view_layer.objects.active = obj
    for modifier in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=modifier.name)


def make_fist(name, position, collection, materials, geometry):
    x, y, z = position
    g = geometry
    skin = materials["skin"]

    def points(local):
        return [(x + a, y + b, z + c) for a, b, c in local]

    def finger(label, path, radii):
        obj = g.tube(name + label, points(path), radii, skin,
                     collection, 1, 16, 2)
        _apply_surface(obj)
        return obj

    # Palm stays behind the shaft (Y=-.11); the front exposes curled fingers.
    palm = g.loft(name + "_Metacarpals", [
        (x-.015, y+.010, z-.105, .078, .074),
        (x-.015, y+.005, z-.065, .090, .078),
        (x-.021, y-.007, z+.005, .111, .076),
        (x-.030, y-.017, z+.100, .135, .071),
        (x-.026, y-.024, z+.195, .130, .060),
        (x-.018, y-.022, z+.249, .111, .052),
        (x-.008, y-.016, z+.267, .070, .035),
    ], skin, collection)
    _apply_surface(palm)
    parts = [palm]

    # Gaps between rows survive union. Each finger has a proximal knuckle,
    # bent middle phalanx and tapered pad returning behind the grip.
    for label, height, radius, reach in [
        ("Index", .235, .049, 1.00),
        ("Middle", .147, .051, 1.03),
        ("Ring", .059, .048, .97),
        ("Little", -.020, .041, .86),
    ]:
        path = [
            (-.098, -.024, height-.020),
            (-.151*reach, -.075, height),
            (-.162*reach, -.137, height+.005),
            (-.120*reach, -.187, height+.003),
            (-.052, -.207, height-.001),
            (+.029*reach, -.207, height-.010),
            (+.093*reach, -.177, height-.022),
            (+.116*reach, -.120, height-.033),
            (+.078*reach, -.055, height-.037),
        ]
        parts.append(finger("_" + label, path, [
            radius*.93, radius*1.04, radius*1.06, radius,
            radius*.94, radius*.94, radius*.92, radius*.85, radius*.62,
        ]))

    # Opposed thumb arches from the radial side over the upper two fingers.
    parts.append(finger("_Thumb", [
        (+.081, -.010, +.087),
        (+.138, -.039, +.139),
        (+.167, -.108, +.219),
        (+.148, -.197, +.257),
        (+.110, -.247, +.230),
        (+.070, -.259, +.184),
        (+.045, -.251, +.160),
    ], [.071, .068, .060, .053, .050, .046, .027]))

    hand = g.fuse(name + "_ClosedFist", parts, skin, collection, .004)
    smooth = next(mod for mod in hand.modifiers if mod.type == "SMOOTH")
    smooth.factor = .32
    smooth.iterations = 2
    hand["anatomy"] = "Left hand: four fingers, opposed thumb, tapered wrist"

    # A restrained nail makes thumb direction readable without dark outlines.
    nail_mat = bpy.data.materials.get("AM_Thumbnail")
    if nail_mat is None:
        nail_mat = skin.copy()
        nail_mat.name = "AM_Thumbnail"
        shader = next(n for n in nail_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        shader.inputs["Base Color"].default_value = (.81, .59, .47, 1)
        shader.inputs["Roughness"].default_value = .42
        nail_mat.diffuse_color = (.81, .59, .47, 1)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20,
        location=(x+.090, y-.298, z+.210))
    nail = bpy.context.object
    nail.name = name + "_Thumbnail"
    nail.scale = (.024, .002, .034)
    nail.rotation_euler.y = .67
    nail.data.materials.append(nail_mat)
    for current in list(nail.users_collection):
        current.objects.unlink(nail)
    collection.objects.link(nail)
    for face in nail.data.polygons:
        face.use_smooth = True
    # The construction coordinates describe a right palm facing the camera.
    # Reflect its lateral axis for the character's LEFT arm. A 180-degree
    # rotation would swap palm/back as well and would not correct handedness.
    origin = Vector((x, y, z))
    bpy.context.view_layer.update()
    reflection = (Matrix.Translation(origin)
                  @ Matrix.Diagonal((-1, 1, 1, 1))
                  @ Matrix.Translation(-origin))
    for obj in (hand, nail):
        local_reflection = obj.matrix_world.inverted() @ reflection @ obj.matrix_world
        obj.data.transform(local_reflection)
        topology = bmesh.new()
        topology.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(topology, faces=list(topology.faces))
        topology.to_mesh(obj.data)
        topology.free()
        obj.data.update()
    return hand
