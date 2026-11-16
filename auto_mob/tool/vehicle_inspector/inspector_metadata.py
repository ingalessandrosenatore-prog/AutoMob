import bpy
from mathutils import Vector

from geometry import empty


def gltf_coordinates(vector):
    x, y, z = vector
    return [round(value, 5) for value in (x, z, -y)]


def camera_presets():
    presets = {}

    def add(name, position, target, fov, label):
        presets[name] = {
            "label": label,
            "position": gltf_coordinates(position),
            "target": gltf_coordinates(target),
            "distance": round((Vector(position)-Vector(target)).length, 5),
            "verticalFovDeg": fov,
        }

    add("vehicle_overview", (4.5, 5.0, 3.3), (0, 0, .68), 35, "Vista generale")
    add("engine_overview", (2.42, .67, 2.11), (1.34, .01, .53), 41, "Vano motore")
    add("timing_system_closeup", (1.78, 1.11, 1.03), (1.35, .462, .593), 36, "Distribuzione")
    add("oil_filter_closeup", (2.22, .94, .82), (1.51, .29, .445), 38, "Filtro olio")
    add("gearbox_closeup", (2.0, -1.26, 1.21), (1.32, -.32, .435), 39, "Cambio e differenziale")
    add("underbody", (-2.78, 2.92, -1.65), (-.32, -.01, .25), 42, "Sottoscocca")
    for axle, direction, x in [("front", 1, 1.30), ("rear", -1, -1.30)]:
        for side, sign in [("left", 1), ("right", -1)]:
            key = f"{axle}_{side}_wheel"
            suffix = f"{'anteriore' if direction > 0 else 'posteriore'} {'sinistra' if sign > 0 else 'destra'}"
            add(key, (x+direction*.43, sign*2.00, .83), (x, sign*.68, .43), 40, f"Ruota {suffix}")
            add(f"{key}_suspension", (x-direction*.45, sign*1.85, .87), (x-.05, sign*.56, .61),
                38, f"Sospensione {suffix}")
    return presets


def meshes_under(obj):
    return [node.name for node in [obj, *obj.children_recursive] if node.type == "MESH"]


class InspectorMetadata:
    def __init__(self, anchor_root):
        self.anchor_root = anchor_root
        self.components = []

    def register(self, obj, label, category, camera, radius, *, meshes=None,
                 anchor=None, assembly=None):
        bpy.context.view_layer.update()
        origin = obj.matrix_world.translation
        center = origin if anchor is None else anchor
        hotspot = empty(f"anchor_{obj.name}", self.anchor_root, center)
        hotspot.empty_display_type = "SPHERE"
        hotspot.empty_display_size = radius
        hotspot["componentId"] = obj.name
        hotspot["pickRadiusMeters"] = radius
        record = {
            "id": obj.name,
            "label": label,
            "category": category,
            "selectable": True,
            "position": gltf_coordinates(origin),
            "target": gltf_coordinates(center),
            "cameraPreset": camera,
            "highlightGroup": obj.name,
            "meshNames": [name for node in (meshes or [obj]) for name in meshes_under(node)],
            "anchor": hotspot.name,
            "pickRadiusMeters": radius,
        }
        if assembly:
            record["assembly"] = assembly
        for key, value in record.items():
            obj[key] = value
        self.components.append(record)
