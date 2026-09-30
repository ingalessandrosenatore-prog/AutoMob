"""Replace only the two generated grips, preserving the rest of the saved scene."""
import importlib.util
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
OUTPUT_STEM = "automob_mascot_mano_v3"


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / filename)
    result = importlib.util.module_from_spec(spec)
    sys.modules[name] = result
    spec.loader.exec_module(result)
    return result


g = module("automob_geometry", "automob_hand_geometry.py")
hands = module("automob_reference_hand", "automob_reference_hand.py")
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "automob_mascot_mano_v2.blend"))
scene = bpy.context.scene
for label, position in [
    ("Standing", (-1.55, -.38, 3.40)),
    ("Counter", (3.03, -.13, 3.17)),
]:
    prefix = label + "_Hand_1"
    old = [obj for obj in scene.objects if obj.name.startswith(prefix)]
    assert {o.name for o in old} == {prefix + "_ClosedFist", prefix + "_Thumbnail"}, f"Unexpected grip objects: {[o.name for o in old]}"
    collection = old[0].users_collection[0]
    for obj in old:
        bpy.data.objects.remove(obj, do_unlink=True)
    hand = hands.make_fist(prefix, position, collection,
                           {"skin": bpy.data.materials["AM2_skin"]}, g)
    assert len(hand.data.vertices) > 1000
    topology = bmesh.new()
    topology.from_mesh(hand.data)
    assert all(edge.is_manifold for edge in topology.edges), "Open hand surface"
    topology.free()
    print("UPDATED", hand.name, len(hand.data.vertices))

block = bpy.data.texts.get("automob_reference_hand.py")
if block:
    block.clear()
else:
    block = bpy.data.texts.new("automob_reference_hand.py")
block.write((ROOT / "automob_reference_hand.py").read_text(encoding="utf8"))
block = bpy.data.texts.new("automob_hand_geometry.py")
block.write((ROOT / "automob_hand_geometry.py").read_text(encoding="utf8"))
scene.render.filepath = str(ROOT / f"{OUTPUT_STEM}.png")
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / f"{OUTPUT_STEM}.blend"))

if "--full" in sys.argv or "--all" in sys.argv:
    bpy.ops.render.render(write_still=True)
if "--full" not in sys.argv:
    camera = scene.camera
    target = Vector((-1.55, -.48, 3.57))
    camera.data.ortho_scale = 1.20
    scene.render.resolution_x = 800
    scene.render.resolution_y = 800
    scene.cycles.samples = 48
    for suffix, offset in [
        ("front", (.3, -5, .65)),
        ("side", (3.5, -4, 1.2)),
    ]:
        camera.location = target + Vector(offset)
        camera.rotation_euler = (target-camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(ROOT / f"{OUTPUT_STEM}_{suffix}.png")
        bpy.ops.render.render(write_still=True)
