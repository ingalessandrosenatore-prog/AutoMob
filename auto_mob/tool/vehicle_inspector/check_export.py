"""Check the asset contract used by Flutter or another glTF renderer."""

from collections import Counter
import json
import math
from pathlib import Path
import struct


def require(condition, message):
    if not condition:
        raise ValueError(message)


def parse_glb(path):
    data = path.read_bytes()
    magic, version, size, length, chunk = struct.unpack_from("<4sIII4s", data)
    require((magic, version, size, chunk) == (b"glTF", 2, len(data), b"JSON"), "GLB header")
    require(len(data) <= 15_000_000, "GLB exceeds 15 MB")
    return json.loads(data[20:20+length])


def index_nodes(gltf, root_name):
    nodes = gltf["nodes"]
    by_name = {}
    positions = {}

    def visit(index, parent_position):
        node = nodes[index]
        name = node["name"]
        require(name not in by_name, f"Duplicate node: {name}")
        by_name[name] = node
        # Only the leaf parts rotate or scale. Their transforms do not move anchors.
        local = node.get("translation", (0, 0, 0))
        positions[name] = tuple(a+b for a, b in zip(parent_position, local))
        children = node.get("children", ())
        require(not children or not ({"rotation", "scale", "matrix"} & node.keys()),
                f"Non-translation parent: {name}")
        for child in children:
            visit(child, positions[name])

    default_scene = gltf["scenes"][gltf.get("scene", 0)]
    roots = default_scene["nodes"]
    require(len(roots) == 1 and nodes[roots[0]]["name"] == root_name, "GLB scene root")
    visit(roots[0], (0, 0, 0))
    require(len(by_name) == len(nodes), "Disconnected GLB nodes")
    return by_name, positions


def check_components(manifest, nodes, positions, gltf):
    presets = manifest["cameraPresets"]
    for key, preset in presets.items():
        distance = math.dist(preset["position"], preset["target"])
        require(abs(distance-preset["distance"]) < .0001 and 0 < preset["verticalFovDeg"] < 180, key)
    components = manifest["components"]
    require(len({part["id"] for part in components}) == len(components), "Duplicate component ID")
    extension = "KHR_materials_variants"
    variants = gltf["extensions"][extension]["variants"]
    expected = {manifest["materials"][key] for key in ("selected", "interactive")}
    require(expected <= {item["name"] for item in variants}, "Missing material variants")
    for part in components:
        key = part["id"]
        require(part["selectable"] and part["meshNames"] and part["cameraPreset"] in presets, key)
        require(nodes[key]["extras"] == part, f"Mismatch between JSON and GLB extras: {key}")
        anchor = nodes[part["anchor"]]
        require("mesh" not in anchor and anchor["extras"]["componentId"] == key, key)
        require(math.isclose(anchor["extras"]["pickRadiusMeters"], part["pickRadiusMeters"])
                and part["pickRadiusMeters"] > 0, key)
        require(math.dist(positions[key], part["position"]) < .0001, f"Component position: {key}")
        require(math.dist(positions[part["anchor"]], part["target"]) < .0001, f"Camera target: {key}")
        for name in part["meshNames"]:
            for primitive in gltf["meshes"][nodes[name]["mesh"]]["primitives"]:
                mappings = primitive["extensions"][extension]["mappings"]
                require(expected <= {gltf["materials"][row["material"]]["name"] for row in mappings},
                        f"Missing selectable material: {name}")


def measure(gltf):
    accessors = gltf["accessors"]
    occurrences = Counter(node["mesh"] for node in gltf["nodes"] if "mesh" in node)
    unique_positions = set()
    vertex_instances = triangles = 0
    for index, mesh in enumerate(gltf["meshes"]):
        for primitive in mesh["primitives"]:
            position = primitive["attributes"]["POSITION"]
            unique_positions.add(position)
            copies = occurrences[index]
            vertex_instances += accessors[position]["count"] * copies
            require(primitive.get("mode", 4) == 4, "All primitives must use triangles")
            faces = accessors[primitive.get("indices", position)]["count"] // 3
            triangles += faces * copies
    require(triangles < 150_000, "Mobile triangle budget")
    return {
        "nodes": len(gltf["nodes"]),
        "meshObjects": sum(occurrences.values()),
        "sharedAndUniqueMeshData": len(occurrences),
        "uniqueVertices": sum(accessors[index]["count"] for index in unique_positions),
        "vertexInstances": vertex_instances,
        "triangleInstances": triangles,
    }


if __name__ == "__main__":
    directory = Path(__file__).resolve().parent
    manifest = json.loads((directory/"components.json").read_text(encoding="utf-8"))
    path = directory/manifest["model"]
    gltf = parse_glb(path)
    require(not gltf.get("textures"), "Unexpected textures")
    nodes, positions = index_nodes(gltf, manifest["root"])
    check_components(manifest, nodes, positions, gltf)
    print(json.dumps({
        **measure(gltf),
        "components": len(manifest["components"]),
        "cameraPresets": len(manifest["cameraPresets"]),
        "glbBytes": path.stat().st_size,
    }, indent=2))
