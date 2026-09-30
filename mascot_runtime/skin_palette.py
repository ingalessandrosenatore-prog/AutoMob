"""A restrained olive undertone, shared by the face and all hand variants."""
import bpy

SKIN_COLOR = (.73, .58, .40, 1)


def apply_skin_palette():
    material = bpy.data.materials["RT_AM2_skin"]
    # Absolute values keep repeated exports from progressively darkening skin.
    material.diffuse_color = SKIN_COLOR
    for node in material.node_tree.nodes:
        if node.type == "BSDF_PRINCIPLED":
            node.inputs["Base Color"].default_value = SKIN_COLOR
