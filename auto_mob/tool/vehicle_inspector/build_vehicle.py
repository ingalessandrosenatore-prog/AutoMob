import argparse
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))

from body import build_body
from geometry import empty
from inspector_metadata import InspectorMetadata, camera_presets
from palette import add_material_variants, build_palette
from powertrain import build_engine, build_other, build_transmission
from running_gear import build_wheels


def set_up_studio(scene, presets):
    studio = bpy.data.collections.new("Studio • solo Blender")
    scene.collection.children.link(studio)
    camera = bpy.data.cameras.new("Overview lens")
    camera.sensor_fit = "VERTICAL"
    view = bpy.data.objects.new("Vehicle overview", camera)
    studio.objects.link(view)
    preset = presets["vehicle_overview"]
    x, z, neg_y = preset["position"]
    view.location = (x, -neg_y, z)
    x, z, neg_y = preset["target"]
    target = Vector((x, -neg_y, z))
    view.rotation_euler = (target-view.location).to_track_quat("-Z", "Y").to_euler()
    camera.angle_y = math.radians(preset["verticalFovDeg"])
    scene.camera = view
    for name, position, energy, size in [
        ("Key softbox", (2, 2.8, 5.3), 580, 5),
        ("Fill softbox", (-2, -3, 3.5), 430, 4),
        ("Front softbox", (4, -1, 1.7), 180, 3),
    ]:
        data = bpy.data.lights.new(name, "AREA")
        data.energy, data.size = energy, size
        light = bpy.data.objects.new(name, data)
        studio.objects.link(light)
        light.location = position
        light.rotation_euler = (target-light.location).to_track_quat("-Z", "Y").to_euler()
    scene.world = bpy.data.worlds.new("Neutral ambient light")
    scene.world.color = (.22, .22, .22)
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = 1120
    scene.render.resolution_y = 760
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = "RGBA"
    for screen in bpy.data.screens:
        for area in (area for area in screen.areas if area.type == "VIEW_3D"):
            space = area.spaces.active
            space.region_3d.view_location = target
            space.region_3d.view_distance = 5.75
            space.region_3d.view_rotation = view.rotation_euler.to_quaternion()
            space.region_3d.view_perspective = "PERSP"
            space.overlay.show_overlays = False
            space.shading.type = "MATERIAL"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = "AutoMob • Vehicle Inspector"
    scene.unit_settings.system = "METRIC"
    palette = build_palette()
    root = empty("AutoMob_Vehicle", None)
    root["schemaVersion"] = 1
    root["wheelbaseMeters"] = 2.60
    anchors = empty("Anchors", root)
    metadata = InspectorMetadata(anchors)

    build_body(empty("Body", root), palette)
    build_engine(empty("Engine", root), palette, metadata.register)
    build_transmission(empty("Transmission", root), palette, metadata.register)
    build_wheels(empty("Wheels", root), palette, metadata.register)
    build_other(empty("Other_Systems", root), palette, metadata.register)

    presets = camera_presets()
    add_material_variants(scene, {name for c in metadata.components for name in c["meshNames"]}, palette)
    set_up_studio(scene, presets)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(output/"automob_vehicle.blend"))
    for obj in [root, *root.children_recursive]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=str(output/"automob_vehicle.glb"), export_format="GLB",
        use_selection=True, export_extras=True, export_yup=True,
        export_animations=False, export_cameras=False, export_lights=False,
    )
    manifest = {
        "schemaVersion": 1,
        "model": "automob_vehicle.glb",
        "root": root.name,
        "axes": {"forward": "+X", "up": "+Y", "left": "-Z", "unit": "meter"},
        "dimensionsMeters": {"length": 4.20, "width": 1.80, "height": 1.39, "wheelbase": 2.60},
        "materials": {"shell": "MAT_BODY_XRAY", "internal": "MAT_INTERNAL",
                      "interactive": "MAT_INTERACTIVE", "selected": "MAT_SELECTED",
                      "selectedColor": "#FF6A00"},
        "cameraPresets": presets,
        "components": metadata.components,
    }
    (output/"components.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n",
                                          encoding="utf-8")
    if args.preview:
        scene.render.filepath = str(args.preview.resolve())
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
