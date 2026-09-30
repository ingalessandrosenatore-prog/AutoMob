"""Structural checks on the exported GLB, not just the Blender source."""
import json
import struct
from pathlib import Path

ROOT=Path(__file__).resolve().parent
blob=(ROOT/"automob_mascot.glb").read_bytes()
magic,version,total=struct.unpack_from("<4sII",blob)
assert magic==b"glTF" and version==2 and total==len(blob)
size,kind=struct.unpack_from("<II",blob,12)
assert kind==0x4E4F534A
doc=json.loads(blob[20:20+size])
manifest=json.loads((ROOT/"manifest.json").read_text(encoding="utf8"))
names={item.get("name") for item in doc.get("animations",[])}
print("CLIPS", sorted(names))
assert names=={c["name"] for c in manifest["clips"]}, "Missing or unexpected animation clips"
nodes={n.get("name") for n in doc["nodes"]}
for pose,data in manifest["poses"].items():
    assert data["root"] in nodes
    assert pose+"_BODY" in nodes
    for prop in data["props"]:
        assert pose+"_PROP_"+prop in nodes
materials={m.get("name") for m in doc["materials"]}
assert set(manifest["materials"].values()) <= materials
assert "AM_Tablet_Lightning" in materials
assert "desk_PROP_tire" not in nodes
assert len(doc.get("skins",[]))>=2
assert all("uri" not in b for b in doc.get("buffers",[]))
for clip in doc["animations"]:
    assert len(clip["channels"])>=3
    maximum=max(doc["accessors"][s["input"]]["max"][0] for s in clip["samplers"])
    expected=next(c["duration"] for c in manifest["clips"] if c["name"]==clip["name"])
    assert abs(maximum-expected)<.001,(clip["name"],maximum,expected)
accessors=doc["accessors"]
triangles=sum(accessors[p["indices"]]["count"]//3 for mesh in doc["meshes"] for p in mesh["primitives"])
vertices=sum(accessors[p["attributes"]["POSITION"]]["count"] for mesh in doc["meshes"] for p in mesh["primitives"])
assert triangles<=65000,("Mobile geometry budget exceeded",triangles)
assert len(blob)<=5*1024*1024,("Mobile asset budget exceeded",len(blob))
report={"bytes":len(blob),"triangles":triangles,"vertices":vertices,"animations":sorted(names),"nodes":len(nodes),
        "meshes":len(doc["meshes"]),"materials":sorted(materials),"skins":len(doc["skins"])}
(ROOT/"verification.json").write_text(json.dumps(report,indent=2),encoding="utf8")
print("PASS",json.dumps(report))
