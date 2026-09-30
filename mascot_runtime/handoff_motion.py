"""A supported two-handed handoff, with matched tool transforms at each release."""
from mathutils import Quaternion, Vector

GRIP_SPACING = .20


def receiving(t):
    return 9.5 <= t < 13.5


def handoff(pose, t, left, right, left_q, right_q):
    from motion import smooth
    if not 8 < t < 15:
        return left, right, left_q, right_q
    dz = -.23 if pose == "desk" else 0
    meeting_left = Vector((0, -.76, 3.13 + dz))
    meeting_right = meeting_left - Vector((0, 0, GRIP_SPACING))
    empty_left = Vector((.88, -.15, 2.62 + dz))
    holding_right = Vector((-.86, -.48, 3.05 + dz))
    neutral = Quaternion()
    held_q = Quaternion((0, 1, 0), -.16)
    # During each meeting the lower hand grips the same handle before the
    # upper hand releases. A vertical offset keeps the fists from overlapping.
    keys = [(8, left, right, left_q, right_q),
            (9.5, meeting_left, meeting_right, neutral, neutral),
            (10.6, empty_left, holding_right, neutral, held_q),
            (12.3, empty_left, holding_right, neutral, held_q),
            (13.5, meeting_left, meeting_right, neutral, neutral),
            (15, left, right, left_q, right_q)]
    for a, b in zip(keys, keys[1:]):
        if a[0] <= t <= b[0]:
            u = smooth((t - a[0]) / (b[0] - a[0]))
            return a[1].lerp(b[1], u), a[2].lerp(b[2], u), a[3].slerp(b[3], u), a[4].slerp(b[4], u)


def hand_modes(t):
    return ("relaxed" if 9.65 < t < 13.35 else "closed",
            "closed" if 9.3 < t < 13.7 else "relaxed")
