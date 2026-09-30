"""Plant one boot and raise the other, showing its sole without ground sliding."""
from mathutils import Matrix, Quaternion, Vector


def shoe_inspection(t):
    from motion import smooth
    return smooth((t - 17.2) / 1.4) * (1 - smooth((t - 20.5) / 1.5))


def pose_legs(rig, rests, t):
    if rig["pose"] != "standing":
        return
    lift = shoe_inspection(t)
    for side in ["L", "R"]:
        amount = lift if side == "L" else 0
        hip, knee, ankle = [rests[part + "." + side] for part in ["thigh", "shin", "foot"]]
        thigh_q = Quaternion((1, 0, 0), -.65 * amount)
        shin_q = Quaternion((1, 0, 0), .85 * amount)
        foot_q = Quaternion((1, 0, 0), -1.10 * amount)
        posed_knee = hip + thigh_q @ (knee - hip)
        posed_ankle = posed_knee + shin_q @ (ankle - knee)
        for part, origin, target, rotation in [
            ("thigh", hip, hip, thigh_q), ("shin", knee, posed_knee, shin_q),
            ("foot", ankle, posed_ankle, foot_q),
        ]:
            name = part + "." + side
            change = Matrix.Translation(target) @ rotation.to_matrix().to_4x4() @ Matrix.Translation(-origin)
            # Retain the small heel lift from the opening idle while the full
            # foot is on the ground; its pivot keeps the toe planted.
            if part == "foot" and lift == 0:
                heel = "heel." + side
                change = rig.pose.bones[heel].matrix @ rig.data.bones[heel].matrix_local.inverted() @ change
            rig.pose.bones[name].matrix = change @ rig.data.bones[name].matrix_local
