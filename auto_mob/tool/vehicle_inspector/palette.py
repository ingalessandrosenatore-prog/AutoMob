import bpy


def linear(channel):
    return channel/12.92 if channel <= .04045 else ((channel+.055)/1.055)**2.4


def material(name, color, opacity, metallic, roughness, *, two_sided=False, emitter=0):
    rgb = tuple(linear(int(color[i:i+2], 16)/255) for i in (0, 2, 4))
    skin = bpy.data.materials.new(name)
    skin.diffuse_color = (*rgb, opacity)
    skin.use_nodes = True
    skin.use_backface_culling = not two_sided
    skin.surface_render_method = "DITHERED"
    shader = skin.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*rgb, 1)
    shader.inputs["Alpha"].default_value = opacity
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Emission Color"].default_value = (*rgb, 1)
    shader.inputs["Emission Strength"].default_value = emitter
    return skin


def build_palette():
    return {
        "body": material("MAT_BODY_XRAY", "9BA9B9", .13, .1, .47, two_sided=True),
        "glass": material("MAT_GLASS_XRAY", "7795AC", .10, .06, .35, two_sided=True),
        "structure": material("MAT_INTERNAL", "748394", .54, .15, .56),
        "mechanical": material("MAT_CAST_ALLOY", "ABBBCA", .60, .22, .49),
        "edge": material("MAT_TECHNICAL_EDGE", "6C8194", .78, .12, .43, emitter=.12),
        "rubber": material("MAT_RUBBER", "3C4655", .58, 0, .84),
        "rim": material("MAT_MACHINED_ALLOY", "BECDD8", .57, .26, .39),
        "lamp": material("MAT_HEADLIGHT", "C7DAE4", .8, .1, .35, emitter=.22),
        "rear_lamp": material("MAT_TAILLIGHT", "AD5656", .73, .08, .45),
        "interactive": material("MAT_INTERACTIVE", "BE7B54", .59, .09, .54),
        "selected": material("MAT_SELECTED", "FF6A00", 1, .05, .38, emitter=.16),
    }


def add_material_variants(scene, mesh_names, palette):
    preferences = bpy.context.preferences.addons["io_scene_gltf2"].preferences
    preferences.KHR_materials_variants_ui = True
    variants = scene.gltf2_KHR_materials_variants_variants
    states = ("interactive", "selected")
    for index, key in enumerate(states):
        variant = variants.add()
        variant.variant_idx = index
        variant.name = palette[key].name
    for data in {bpy.data.objects[name].data for name in mesh_names}:
        default = data.gltf2_variant_default_materials.add()
        default.material_slot_index = 0
        default.default_material = data.materials[0]
        for index, key in enumerate(states):
            mapping = data.gltf2_variant_mesh_data.add()
            mapping.material_slot_index = 0
            mapping.material = palette[key]
            mapping.variants.add().variant.variant_idx = index
