"""Temporary mobile meshes: keep the editable Blender source at full quality."""
from contextlib import contextmanager
import bpy


def triangle_count(mesh):
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


@contextmanager
def mobile_geometry(scene):
    originals = []
    report = []
    try:
        for obj in list(scene.objects):
            if obj.type != "MESH":
                continue
            before = triangle_count(obj.data)
            limit = 28000 if obj.name.endswith("_BODY") else 1800
            if before > limit:
                original = obj.data
                obj.data = original.copy()
                originals.append((obj, original, obj.data))
                bpy.context.view_layer.objects.active = obj
                modifier = obj.modifiers.new("Mobile export reduction", "DECIMATE")
                modifier.ratio = limit / before
                modifier.use_collapse_triangulate = True
                # Reduce rest geometry before skinning. Applying a modifier
                # after the armature would bake the current pose into the mesh.
                while obj.modifiers.find(modifier.name) > 0:
                    bpy.ops.object.modifier_move_up(modifier=modifier.name)
                bpy.ops.object.modifier_apply(modifier=modifier.name)
            report.append({"mesh": obj.name, "sourceTriangles": before,
                           "mobileTriangles": triangle_count(obj.data)})
        yield report
    finally:
        for obj, original, temporary in originals:
            obj.data = original
            if temporary.users == 0:
                bpy.data.meshes.remove(temporary)
        bpy.context.view_layer.update()
