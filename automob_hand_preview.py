"""Render the actual saved fist and tool up close, without modifying the blend."""
from pathlib import Path
import bpy
from mathutils import Vector

root = Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(root / "automob_mascot_reference.blend"))
scene = bpy.context.scene
camera = scene.camera
target = Vector((-1.55, -.45, 3.49))
camera.location = target + Vector((1.1, -5, 1.0))
camera.rotation_euler = (target-camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.ortho_scale = 1.45
scene.render.resolution_x = 850
scene.render.resolution_y = 850
scene.cycles.samples = 64
scene.render.filepath = str(root / "automob_hand_detail.png")
bpy.ops.render.render(write_still=True)
