"""Regression checks for hand direction and tablet contact across every clip."""
import sys
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from motion import pose_at
from idle_motion import body_transform, grooming
from tablet_layout import frame, normal as screen_normal, support_wrist

bpy.ops.wm.open_mainfile(filepath=str(HERE/"automob_mascot_animated.blend"))
samples=0
for pose in ["standing","desk"]:
    rig=bpy.data.objects["AM_"+pose.upper()]
    rig.animation_data.action=None
    rests={bone.name:bone.head_local.copy() for bone in rig.data.bones}
    props=["wrench","screwdriver","tablet"]+(["tire"] if pose=="standing" else [])
    for prop in props:
        gesture={"wrench":"spin","screwdriver":"spin","tablet":"tap","tire":"dribble"}[prop]
        for kind in ["idle",gesture]:
            for t in ([0,.6,1,1.5,2,3.5,4,5.7,7,8] if kind=="idle" else [0,.6,1,1.5,2,3.5,4]):
                pose_at(rig,rests,prop,kind,t)
                body_inverse=body_transform(rig,rests,t).inverted() if kind=="idle" else Matrix.Identity(4)
                head_change=rig.pose.bones["head"].matrix@rig.data.bones["head"].matrix_local.inverted()
                for eye in ["eye.L","eye.R"]:
                    expected=head_change@rests[eye]
                    actual=rig.pose.bones[eye].matrix.translation
                    assert (actual-expected).length<.001,(pose,kind,t,"eye detached from face",actual,expected)
                if prop=="tablet":
                    assert rig.pose.bones["hand.tap"].scale.x>.99
                    assert rig.pose.bones["hand.support.R"].scale.x>.99
                    assert rig.pose.bones["hand.relaxed.R"].scale.x<.001
                    rest=rig.data.bones["wrist.L"].matrix_local
                    change=body_inverse@rig.pose.bones["wrist.L"].matrix@rest.inverted()
                    normal=change.to_3x3()@Vector((0,-1,0))
                    thumb=change.to_3x3()@Vector((-1,0,0))
                    tip=change@(rests["wrist.L"]+Vector((0,-.11,.46)))
                    assert thumb.z>.8,(pose,kind,t,"inverted thumb",thumb)
                    dz=-.23 if pose=="desk" else 0
                    local_tip=frame(dz).inverted()@tip
                    assert .055<local_tip.y<.10,(pose,kind,t,"tip on wrong side",local_tip)
                    assert abs(local_tip.x)<.35 and abs(local_tip.z)<.48
                    assert screen_normal().y>.8 and screen_normal().z>.3
                    actual=(body_inverse@rig.pose.bones["wrist.R"].matrix).translation
                    assert (actual-support_wrist(dz)).length<.001,"Support grip detached"
                else:
                    assert rig.pose.bones["hand.relaxed.R"].scale.x>.99
                    assert rig.pose.bones["hand.support.R"].scale.x<.001
                    change=rig.pose.bones["wrist.R"].matrix@rig.data.bones["wrist.R"].matrix_local.inverted()
                    if kind!="idle" or grooming(t)==0:
                        assert (change.to_3x3()@Vector((0,0,-1))).z<-.95
                    assert (change.to_3x3()@Vector((1,0,0))).x>.95
                if prop in {"wrench","screwdriver"} and kind=="idle":
                    change=rig.pose.bones["wrist.L"].matrix@rig.data.bones["wrist.L"].matrix_local.inverted()
                    tool_change=rig.pose.bones[prop].matrix@rig.data.bones[prop].matrix_local.inverted()
                    assert max(abs(change[row][col]-tool_change[row][col]) for row in range(4) for col in range(4))<.001,"Tool detached from grip"
                samples+=1
print("PASS_HAND_POSES",samples,"samples; relaxed palm inward, tap thumb up, tip near screen")
