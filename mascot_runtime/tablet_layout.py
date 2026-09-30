"""One device coordinate system shared by geometry, contact poses and tests."""
import math
from mathutils import Matrix, Vector


def frame(dz=0):
    # +Y is the character-facing screen; its top leans away from his face.
    return Matrix.Translation((-.20,-.73,3.13+dz)) @ Matrix.Rotation(math.radians(22),4,'X')


def point(local, dz=0):
    return frame(dz) @ Vector(local)


def normal():
    return frame().to_3x3() @ Vector((0,1,0))


def support_wrist(dz=0):
    return point((-.47,.09,-.27),dz)


def tap_target(dz=0):
    return point((.16,.092,.12),dz)


def tap_direction():
    return Vector((-.42,-.80,-.43)).normalized()
