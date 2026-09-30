"""Explicit NLA references make every clip discoverable by the glTF exporter."""
from pathlib import Path
import json
import bpy
from mobile_geometry import mobile_geometry

HERE=Path(__file__).resolve().parent


def export_asset():
    scene=bpy.context.scene
    for obj in scene.objects:
        if obj.type=="MESH":
            if obj.data.validate(clean_customdata=False):
                print("REPAIRED_MESH",obj.name,flush=True)
            obj.data.update()
        if obj.type!="ARMATURE":continue
        obj.animation_data_create()
        obj.animation_data.action=None
        for action in bpy.data.actions:
            if not action.name.startswith(obj["pose"]+"_"):continue
            if any(t.name==action.name for t in obj.animation_data.nla_tracks):continue
            track=obj.animation_data.nla_tracks.new()
            track.name=action.name
            track.mute=True
            strip=track.strips.new(action.name,0,action)
            strip.action_slot=action.slots[0]
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/"automob_mascot_animated.blend"))
    with mobile_geometry(scene) as report:
        bpy.ops.export_scene.gltf(filepath=str(HERE/"automob_mascot.glb"),export_format="GLB",
            use_active_scene=True,export_animations=True,export_animation_mode="ACTIONS",
            export_merge_animation="ACTION",export_frame_range=False,export_force_sampling=True,
            export_anim_slide_to_zero=True,export_anim_single_armature=False,
            export_skins=True,export_def_bones=True,export_apply=False,
            export_texcoords=False,export_all_vertex_colors=False,
            export_cameras=False,export_lights=False,export_extras=True,export_materials="EXPORT")
    (HERE/"mobile_geometry_report.json").write_text(json.dumps(report,indent=2),encoding="utf8")


if __name__=="__main__":
    bpy.ops.wm.open_mainfile(filepath=str(HERE/"automob_mascot_animated.blend"))
    export_asset()
