"""Check baked loops, visible limb movement and action/idle continuity."""
from pathlib import Path
import sys
import bpy
sys.path.insert(0,str(Path(__file__).resolve().parent))
from idle_motion import IDLE_DURATION, IDLE_CLIP_DURATION

bpy.ops.wm.open_mainfile(filepath=str(Path(__file__).with_name("automob_mascot_animated.blend")))


def sample(rig, action, frame):
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]
    if action.name.endswith("_idle"):
        frame*=IDLE_CLIP_DURATION/IDLE_DURATION
    bpy.context.scene.frame_set(int(frame),subframe=frame%1)
    bpy.context.view_layer.update()
    return {pb.name: pb.matrix.copy() for pb in rig.pose.bones}


def difference(a, b):
    return max(abs(a[row][col] - b[row][col]) for row in range(4) for col in range(4))


count = 0
for rig in [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]:
    for action in [a for a in bpy.data.actions if a.name.startswith(rig["pose"] + "_") and a.name.endswith("_idle")]:
        first = sample(rig, action, 0)
        assert abs(action.frame_range[1]-30*IDLE_CLIP_DURATION)<.001
        last = sample(rig, action, 30*IDLE_DURATION)
        assert all(difference(first[name], last[name]) < .0001 for name in first), (action.name, "loop seam")
        middle = sample(rig, action, 87)
        assert difference(first["torso"], middle["torso"]) > .01, (action.name, "no breathing")
        assert difference(first["wrist.L"], middle["wrist.L"]) > .01, (action.name, "static arm")
        if "tablet" not in action.name:
            grooming = sample(rig, action, 150)
            dz = -.23 if rig["pose"] == "desk" else 0
            assert grooming["wrist.R"].translation.z > 4.05 + dz, (action.name, "hand not at hair")
            resting_fingers = sample(rig, action, 0)
            rest_rotation = rig.pose.bones["finger.index.R"].rotation_quaternion.copy()
            sample(rig, action, 150)
            curl = rig.pose.bones["finger.index.R"].rotation_quaternion
            assert rest_rotation.rotation_difference(curl).angle > .1, (action.name, "rigid fingers")
            if "tire" not in action.name:
                lowered = sample(rig, action, 120)
                minimum_drop = .3 if rig["pose"] == "desk" else .7
                assert first["wrist.L"].translation.z - lowered["wrist.L"].translation.z > minimum_drop, (action.name, "tool stays raised")
        if rig["pose"] == "standing":
            heel = sample(rig, action, 173)
            assert difference(first["heel.L"], heel["heel.L"]) > .04, "static heel"
        prefix = action.name.removesuffix("idle")
        gesture = next(a for a in bpy.data.actions if a.name.startswith(prefix) and a != action)
        end = sample(rig, gesture, 120)
        assert all(difference(first[name], end[name]) < .0001 for name in first), (gesture.name, "action transition")
        count += 1
print("PASS_IDLE", count, "baked loops; arms, breathing, heels and action transitions")
