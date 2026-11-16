import math

import bpy
from mathutils import Vector


def mesh(name, vertices, faces, material, *, smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    data.materials.append(material)
    for face in data.polygons:
        face.use_smooth = smooth
    return data


def empty(name, parent, location=(0, 0, 0)):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.location = location
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = 0.025
    return obj


def instance(name, parent, data, location=(0, 0, 0), rotation=None):
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.location = location
    if rotation is not None:
        obj.rotation_euler = rotation
    return obj


def box(name, dimensions, material, bevel):
    x, y, z = (extent / 2 for extent in dimensions)
    vertices = [(a*x, b*y, c*z) for c in (-1, 1)
                for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    faces = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4),
             (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    if not bevel:
        return mesh(name, vertices, faces, material)

    import bmesh

    builder = bmesh.new()
    points = [builder.verts.new(vertex) for vertex in vertices]
    for face in faces:
        builder.faces.new([points[index] for index in face])
    bmesh.ops.bevel(builder, geom=list(builder.edges), offset=bevel,
                   segments=2, affect="EDGES")
    builder.normal_update()
    data = bpy.data.meshes.new(name)
    builder.to_mesh(data)
    builder.free()
    data.materials.append(material)
    return data


def lathe(name, profile, material, *, segments=32, closed=True):
    """Sweep a radius/height section around local Z. A zero radius caps the end."""
    vertices, rings = [], []
    for radius, height in profile:
        first = len(vertices)
        count = segments if radius else 1
        for index in range(count):
            angle = math.tau * index / segments
            vertices.append((radius * math.cos(angle), radius * math.sin(angle), height))
        rings.append(list(range(first, first + count)))
    faces = []
    neighbors = list(zip(rings, rings[1:]))
    if closed:
        neighbors.append((rings[-1], rings[0]))
    for inner, outer in neighbors:
        for index in range(segments):
            following = (index + 1) % segments
            if len(inner) == 1:
                faces.append((inner[0], outer[following], outer[index]))
            elif len(outer) == 1:
                faces.append((inner[index], inner[following], outer[0]))
            else:
                faces.append((inner[index], inner[following], outer[following], outer[index]))
    return mesh(name, vertices, faces, material, smooth=True)


def cylinder(name, radius, length, material, *, segments=24, bevel=0.006):
    depth = length / 2
    chamfer = min(bevel, radius * 0.3, depth * 0.4)
    profile = [(0, -depth), (radius-chamfer, -depth), (radius, -depth+chamfer),
               (radius, depth-chamfer), (radius-chamfer, depth), (0, depth)]
    return lathe(name, profile, material, segments=segments, closed=False)


def tube(name, points, radius, material, *, sides=8, closed=False, caps=True):
    positions = list(map(Vector, points))
    vertices = []
    for index, point in enumerate(positions):
        before = positions[(index - 1) % len(positions)] if closed or index else point
        after = positions[(index + 1) % len(positions)] if closed or index < len(positions)-1 else point
        tangent = (after - before).normalized()
        # Carry the frame along the path to avoid sudden twists on helical springs.
        if not index:
            normal = tangent.orthogonal().normalized()
        else:
            normal = (normal - tangent * tangent.dot(normal)).normalized()
        bitangent = tangent.cross(normal)
        for side in range(sides):
            angle = math.tau * side / sides
            vertices.append(point + radius * (math.cos(angle)*normal + math.sin(angle)*bitangent))
    faces = []
    for index in range(len(positions) if closed else len(positions)-1):
        start = index * sides
        end = ((index + 1) % len(positions)) * sides
        for side in range(sides):
            following = (side + 1) % sides
            faces.append((start+side, start+following, end+following, end+side))
    if not closed and caps:
        faces.extend((tuple(reversed(range(sides))),
                      tuple(range(len(vertices)-sides, len(vertices)))))
    return mesh(name, vertices, faces, material, smooth=True)


def ribbon(name, rows, material, *, reverse=False):
    width = len(rows[0])
    faces = [(base+j, base+j+1, base+j+width+1, base+j+width)
             for base in range(0, (len(rows)-1)*width, width)
             for j in range(width-1)]
    if reverse:
        faces = [face[::-1] for face in faces]
    return mesh(name, [point for row in rows for point in row], faces, material, smooth=True)
