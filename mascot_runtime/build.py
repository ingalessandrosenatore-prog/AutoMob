"""Build the standalone runtime asset without modifying the approved source."""
import sys
import json
import importlib.util
import time
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parent
sys.path.insert(0,str(HERE))
from mesh_tools import collection,copy_mesh,join,weight
from rigging import make_rig,bind_body
from hand_variants import make_hand,make_relaxed_right
from tablet_hand import make_support
from hair_cap import make_cap
from props import screwdriver,tablet
from motion import make_actions,pose_at
from export_asset import export_asset
from idle_rig import ensure_idle_controls
from skin_palette import apply_skin_palette
from relaxed_fingers import ensure_relaxed_fingers
from handoff_rig import ensure_handoff_hands
from leg_rig import ensure_leg_controls
from boot_tread import ensure_boot_tread
from idle_motion import IDLE_CLIP_DURATION
from motion import FPS

spec=importlib.util.spec_from_file_location("hand_geometry",ROOT/"automob_hand_geometry.py")
geometry=importlib.util.module_from_spec(spec)
spec.loader.exec_module(geometry)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/"automob_mascot_mano_v3.blend"))
source=bpy.context.scene
original=list(source.objects)
source.name="SOURCE_Approved_V3"
targets=[]
actors=[]
clips=[]


def budget(name):
    for key,limit in [("SoftFace",8000),("ClosedFist",4500),("HairFoundation",1800),
                      ("Forearm",1200),("Hand_-1",1500),("CargoTrousers",1500),
                      ("StrapStitch",80),("Tread",80)]:
        if key in name:return limit
    return 500


for pose,prefix,origin in [("standing","Standing",(-2.48,0,0)),("desk","Counter",(2.1,.25,0))]:
    target=collection("Runtime_"+pose,source)
    targets.append(target)
    rig,rests=make_rig(pose,target)
    body=[]
    for obj in original:
        if obj.type!="MESH" or not obj.name.startswith(prefix+"_"):continue
        if any(word in obj.name for word in ["_Strand","_Tablet","_Tire","_Tread","_Spanner","_Screwdriver","_Seat","_Hand_-1","_HairFoundation"]):continue
        item=copy_mesh(obj,target,-Vector(origin),budget(obj.name))
        bind_body(item,obj.name,rig,rests)
        body.append(item)
    skin=bpy.data.materials["RT_AM2_skin"]
    dz=-.23 if pose=="desk" else 0
    face=next(item for item in body if "SoftFace" in item.name)
    body.extend(make_cap(face,target,bpy.data.materials["RT_AM2_hair"],dz,geometry))
    for mode in ["point","tap","open"]:
        body.append(make_hand(mode,rests["wrist.L"],target,geometry,skin))
    body.append(make_relaxed_right(rests["wrist.R"],target,geometry,skin))
    body.append(make_support(rests["wrist.R"],target,geometry,skin,dz))
    join(body,pose+"_BODY",rig)
    spanner=next(o for o in original if o.name==prefix+"_Spanner")
    item=copy_mesh(spanner,target,-Vector(origin),1200)
    weight(item,"wrench")
    join([item],pose+"_PROP_wrench",rig)
    screwdriver(rests["wrist.L"],target,rig)
    tablet(rests["tablet"],target,rig)
    if pose=="standing":
        tire=[]
        displacement=rests["tire"]-Vector((-1.69,.31,.68))
        for obj in original:
            if obj.name.startswith("Standing_Tire") or obj.name.startswith("Standing_Tread"):
                item=copy_mesh(obj,target,displacement,budget(obj.name))
                weight(item,"tire")
                tire.append(item)
        join(tire,"standing_PROP_tire",rig)
    else:
        bench=[]
        for obj in original:
            if obj.name.startswith("Workbench_") or obj.name=="Counter_Seat":
                item=copy_mesh(obj,target,-Vector(origin),700)
                weight(item,"root")
                bench.append(item)
        join(bench,"desk_WORKBENCH",rig)
    print("BUILD_ACTOR",pose,flush=True)
    ensure_idle_controls(rig)
    ensure_relaxed_fingers(rig)
    ensure_handoff_hands(rig)
    ensure_leg_controls(rig)
    ensure_boot_tread(rig)
    rests={bone.name:bone.head_local.copy() for bone in rig.data.bones}
    actors.append((rig,rests))
    clips.extend(make_actions(rig,rests))

runtime=bpy.data.scenes.new("AutoMob_Runtime")
runtime.world=source.world.copy()
runtime.render.fps=30
runtime.frame_start=0
runtime.frame_end=FPS*IDLE_CLIP_DURATION
for target in targets:
    source.collection.children.unlink(target)
    runtime.collection.children.link(target)
bpy.context.window.scene=runtime
runtime.frame_set(0)
for rig,rests in actors:
    pose_at(rig,rests,"wrench","idle",0)
runtime["defaultPose"]="standing"
runtime["defaultProp"]="wrench"
runtime["runtimeVisibility"]="Select one actor and one PROP node; see manifest.json"
manifest={"schemaVersion":1,"revision":str(time.time_ns()),"asset":"automob_mascot.glb","default":{"pose":"standing","prop":"wrench"},
          "poses":{"standing":{"root":"AM_STANDING","props":["wrench","screwdriver","tablet","tire"]},
                   "desk":{"root":"AM_DESK","props":["wrench","screwdriver","tablet"]}},
          "materials":{"base":"AM_Clothes_Base","accent":"AM_Clothes_Accent"},"clips":clips}
(HERE/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf8")
for path in HERE.glob("*.py"):
    block=bpy.data.texts.new("runtime/"+path.name)
    block.write(path.read_text(encoding="utf8"))
apply_skin_palette()
export_asset()
print("RUNTIME_READY",len(clips),str(HERE/"automob_mascot.glb"),flush=True)
