"""Small mesh helpers for the standalone hand revision."""
import math

import bpy
from mathutils import Vector


def mesh(name, vertices, faces, material, collection, subdivision=2):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    collection.objects.link(obj)
    data.materials.append(material)
    for face in data.polygons:
        face.use_smooth = True
    if subdivision:
        modifier = obj.modifiers.new("Organic surface", "SUBSURF")
        modifier.levels = subdivision
    return obj


def _faces(rings, sides):
    faces = []
    for row in range(rings-1):
        for col in range(sides):
            a = row*sides+col
            b = row*sides+(col+1) % sides
            faces.append((a, b, b+sides, a+sides))
    faces.extend([tuple(reversed(range(sides))),
                  tuple(range((rings-1)*sides, rings*sides))])
    return faces


def loft(name, rings, material, collection):
    vertices = []
    sides = 40
    for x, y, z, rx, ry in rings:
        for index in range(sides):
            angle = math.tau*index/sides
            vertices.append((x+rx*math.cos(angle), y+ry*math.sin(angle), z))
    return mesh(name, vertices, _faces(len(rings), sides), material, collection)


def tube(name, points, radii, material, collection, flat=1, sides=16, subdiv=2):
    points = [Vector(p) for p in points]
    vertices = []
    previous_u = None
    for index, point in enumerate(points):
        tangent = (points[min(index+1, len(points)-1)]-points[max(0, index-1)]).normalized()
        # Parallel transport avoids flipped rings and pinched joints where a
        # bent finger becomes parallel to an arbitrary reference axis.
        if previous_u is None:
            axis = Vector((0, 0, 1))
            if abs(axis.dot(tangent)) > .95:
                axis = Vector((0, 1, 0))
            u = tangent.cross(axis).normalized()
        else:
            u = (previous_u-tangent*previous_u.dot(tangent)).normalized()
        v = tangent.cross(u).normalized()
        previous_u = u
        for side in range(sides):
            angle = math.tau*side/sides
            vertices.append(point+radii[index]*(math.cos(angle)*u+math.sin(angle)*v*flat))
    return mesh(name, vertices, _faces(len(points), sides), material, collection, subdiv)


def fuse(name, objects, material, collection, voxel):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    remesh = obj.modifiers.new("Grip union", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = voxel
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    obj.modifiers.new("Gentle smoothing", "SMOOTH")
    obj.modifiers.new("Surface finish", "SUBSURF").levels = 1
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj
