"""Small rubber tread blocks make the lifted sole readable from the front."""
import bpy
from mesh_tools import cube, material, weight


def ensure_boot_tread(rig):
    if rig["pose"] != "standing":
        return
    body = bpy.data.objects["standing_BODY"]
    if body.get("has_boot_tread"):
        return
    target = body.users_collection[0]
    rubber = material("AM_Boot_Tread", (.085, .095, .11), rough=.88)
    pieces = []
    for side, x in [("L", .34), ("R", -.34)]:
        for index, y in enumerate([-.50, -.36, -.22, -.08, .10]):
            width = .17 if index in {0, 4} else .21
            # Keep the lowest face above z=0 so the neutral boot still rests
            # on the same floor plane, including when runtime scale changes.
            block = cube("Boot_tread_" + side, (x, y, .009),
                         (width, .035, .007), rubber, target, .005)
            weight(block, "foot." + side)
            pieces.append(block)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [body] + pieces:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    body["has_boot_tread"] = True
