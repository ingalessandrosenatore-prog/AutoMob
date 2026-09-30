"""Render a Blender idle preview without saving preview scene changes."""
import sys
from pathlib import Path
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from idle_motion import IDLE_DURATION, IDLE_CLIP_DURATION
from mobile_geometry import mobile_geometry
bpy.ops.wm.open_mainfile(filepath=str(HERE / "automob_mascot_animated.blend"))
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
pose = args[0] if args else "standing"
prop = args[1] if len(args) > 1 else "wrench"
scene = bpy.context.scene
for obj in scene.objects:
    obj.hide_render = (obj.name.startswith("AM_") and obj.name != "AM_" + pose.upper()) or (
        obj.type == "MESH" and (not obj.name.startswith(pose + "_") or
        ("_PROP_" in obj.name and obj.name != pose + "_PROP_" + prop)))
rig = bpy.data.objects["AM_" + pose.upper()]
action = bpy.data.actions[f"{pose}_{prop}_idle"]
rig.animation_data.action = action
rig.animation_data.action_slot = action.slots[0]
camera_data = bpy.data.cameras.new("IdlePreview")
camera = bpy.data.objects.new("IdlePreview", camera_data)
scene.collection.objects.link(camera)
camera.location = (-9, -16, 7) if "--hand-view" in args else (7, -18, 7)
camera.rotation_euler = (Vector((0, 0, 2.65)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 6.2
scene.camera = camera
for name, location, energy, size in [
    ("Key", (2, -6, 9), 850, 5), ("Fill", (-4, -2, 5), 600, 5), ("Rim", (2, 4, 7), 1000, 4),
]:
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.shape, data.size = energy, "DISK", size
    light = bpy.data.objects.new(name, data)
    scene.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (Vector((0, 0, 2.7)) - light.location).to_track_quat("-Z", "Y").to_euler()
scene.render.engine = "CYCLES"
scene.cycles.samples = 12
scene.cycles.use_denoising = True
scene.render.resolution_x = 360
scene.render.resolution_y = 440
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.world = bpy.data.worlds.new("PreviewWorld")
scene.world.use_nodes = True
background = scene.world.node_tree.nodes.new("ShaderNodeBackground")
output_world = scene.world.node_tree.nodes.new("ShaderNodeOutputWorld")
scene.world.node_tree.links.new(background.outputs[0], output_world.inputs[0])
background.inputs[0].default_value = (.10, .13, .19, 1)
background.inputs[1].default_value = .5
scene.render.image_settings.file_format = "PNG"
view_suffix = "_hand" if "--hand-view" in args else ""
if "--mobile" in args:
    view_suffix += "_mobile"
output = HERE / "idle_preview" / f"{pose}_{prop}{view_suffix}"
output.mkdir(parents=True, exist_ok=True)
frames = [round(f*IDLE_CLIP_DURATION/IDLE_DURATION) for f in [0, 150, 285, 315, 345, 405, 580, 610, 650]] if "--stills" in args else range(0, int(action.frame_range[1]), 3)
from contextlib import nullcontext
with mobile_geometry(scene) if "--mobile" in args else nullcontext():
    for frame in frames:
        scene.frame_set(frame)
        scene.render.filepath = str(output / f"{frame:03}.png")
        bpy.ops.render.render(write_still=True)
print("PREVIEW_READY", output)
