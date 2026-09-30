"""Rebake gesture clips without touching the approved geometry."""
import sys
import time
import json
from pathlib import Path
import bpy

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from motion import make_actions
from export_asset import export_asset
from idle_rig import ensure_idle_controls
from skin_palette import apply_skin_palette
from relaxed_fingers import ensure_relaxed_fingers
from handoff_rig import ensure_handoff_hands
from leg_rig import ensure_leg_controls
from boot_tread import ensure_boot_tread
from idle_motion import IDLE_CLIP_DURATION
from motion import FPS

bpy.ops.wm.open_mainfile(filepath=str(HERE/"automob_mascot_animated.blend"))
apply_skin_palette()
clips=[]
for rig in [o for o in bpy.context.scene.objects if o.type=="ARMATURE"]:
    rig.animation_data_clear()
    ensure_idle_controls(rig)
    ensure_relaxed_fingers(rig)
    ensure_handoff_hands(rig)
    ensure_leg_controls(rig)
    ensure_boot_tread(rig)
    for action in list(bpy.data.actions):
        if action.name.startswith(rig["pose"]+"_"):
            bpy.data.actions.remove(action)
    rests={bone.name:bone.head_local.copy() for bone in rig.data.bones}
    clips.extend(make_actions(rig,rests))
    print("REBAKED",rig.name,flush=True)
manifest=json.loads((HERE/"manifest.json").read_text(encoding="utf8"))
manifest["revision"]=str(time.time_ns())
manifest["clips"]=clips
bpy.context.scene.frame_end=FPS*IDLE_CLIP_DURATION
(HERE/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf8")
for path in HERE.glob("*.py"):
    block=bpy.data.texts.get("runtime/"+path.name) or bpy.data.texts.new("runtime/"+path.name)
    block.clear()
    block.write(path.read_text(encoding="utf8"))
export_asset()
