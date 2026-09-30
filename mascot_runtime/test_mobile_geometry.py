"""Guard skin weights, mobile triangle budgets and restoration of source meshes."""
import sys
from pathlib import Path
import bpy

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from mobile_geometry import mobile_geometry, triangle_count

bpy.ops.wm.open_mainfile(filepath=str(HERE / "automob_mascot_animated.blend"))
scene = bpy.context.scene
originals = {obj.name: obj.data for obj in scene.objects if obj.type == "MESH"}
source_count = sum(triangle_count(mesh) for mesh in originals.values())
with mobile_geometry(scene) as report:
    mobile_count = sum(item["mobileTriangles"] for item in report)
    assert mobile_count < source_count * .30, (source_count, mobile_count)
    assert mobile_count <= 65000
    for obj in scene.objects:
        if obj.type != "MESH":
            continue
        assert all(abs(sum(g.weight for g in v.groups) - 1) < .002 for v in obj.data.vertices), obj.name
        assert all(vertex.co.length < 12 for vertex in obj.data.vertices), "corrupt geometry"
for name, mesh in originals.items():
    assert bpy.data.objects[name].data == mesh, "Source mesh was replaced"
assert sum(triangle_count(mesh) for mesh in originals.values()) == source_count
print("PASS_MOBILE_GEOMETRY", source_count, "->", mobile_count, "triangles; source and skin weights preserved")
