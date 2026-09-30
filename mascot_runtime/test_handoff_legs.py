"""Check tool continuity, alternate grips and planted feet in the saved asset."""
import sys
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from motion import pose_at
from handoff_motion import GRIP_SPACING

bpy.ops.wm.open_mainfile(filepath=str(HERE / "automob_mascot_animated.blend"))


def change(rig, name):
    return rig.pose.bones[name].matrix @ rig.data.bones[name].matrix_local.inverted()


def error(a, b):
    return max(abs(a[row][column] - b[row][column]) for row in range(4) for column in range(4))


for pose in ["standing", "desk"]:
    rig = bpy.data.objects["AM_" + pose.upper()]
    rig.animation_data.action = None
    rests = {bone.name: bone.head_local.copy() for bone in rig.data.bones}
    for prop in ["wrench", "screwdriver"]:
        for t in [8, 9.4, 9.6, 11, 13.4, 13.6, 15, 24]:
            pose_at(rig, rests, prop, "idle", t)
            holder = "R" if 9.5 <= t < 13.5 else "L"
            expected = change(rig, "wrist." + holder)
            if holder == "R":
                expected @= Matrix.Translation(rests["wrist.R"] - rests["wrist.L"] + Vector((0, 0, GRIP_SPACING)))
            assert error(change(rig, prop), expected) < .001, (pose, prop, t, "detached tool")
            if 10 < t < 13:
                assert rig.pose.bones["hand.closed.R"].scale.x > .99
                assert rig.pose.bones["hand.relaxed.L"].scale.x > .99
                assert rig.pose.bones["hand.closed"].scale.x < .001
        for transfer in [9.5, 13.5]:
            pose_at(rig, rests, prop, "idle", transfer - .001)
            before = change(rig, prop).copy()
            pose_at(rig, rests, prop, "idle", transfer + .001)
            assert error(before, change(rig, prop)) < .003, (pose, prop, "handoff jump")

rig = bpy.data.objects["AM_STANDING"]
rests = {bone.name: bone.head_local.copy() for bone in rig.data.bones}
for t in [17, 18, 19, 20, 21, 22]:
    pose_at(rig, rests, "wrench", "idle", t)
    assert error(change(rig, "foot.R"), Matrix.Identity(4)) < .001, "support boot slides"
    if 19 <= t <= 20:
        assert rig.pose.bones["foot.L"].matrix.translation.z > .8, "boot did not lift"
        sole = change(rig, "foot.L").to_3x3() @ Vector((0, 0, -1))
        assert sole.y < -.8, "sole does not face forward"
body = bpy.data.objects["standing_BODY"]
for vertex in body.data.vertices:
    total = sum(g.weight for g in vertex.groups)
    assert abs(total - 1) < .001, (vertex.index, "invalid skin weights", total)
print("PASS_HANDOFF_LEGS: two poses, two tools, seamless transfers, planted support boot and normalized weights")
