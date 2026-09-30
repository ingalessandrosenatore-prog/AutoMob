"""Right hand wraps the left bezel: thumb on screen side, fingers behind."""
import bpy
from mathutils import Matrix, Vector
from mesh_tools import weight
from tablet_layout import frame, support_wrist


def make_support(wrist, target, geometry, skin, dz):
    # Model directly around the bezel in device space; translate to the bone's
    # rest location only after sculpting. No inherited palm-up grip or roll.
    palm=geometry.loft('Tablet_grip_palm',[
        (-.47,.09,-.35,.073,.067),(-.47,.085,-.27,.085,.070),
        (-.465,.07,-.14,.084,.073),(-.465,.055,.025,.072,.058),
        (-.465,.05,.09,.052,.046)],skin,target)
    parts=[palm]
    for i,z in enumerate([.065,-.015,-.09,-.16]):
        r=.038-i*.0025
        parts.append(geometry.tube('Tablet_grip_finger',[
            (-.46,.045,z),(-.45,-.035,z+.007),(-.403,-.095,z),
            (-.342,-.105,z-.007),(-.302,-.088,z-.018)],
            [r,r,r,r*.9,r*.5],skin,target,1,12,2))
    parts.append(geometry.tube('Tablet_grip_thumb',[
        (-.46,.10,-.19),(-.397,.135,-.135),(-.334,.125,-.068),
        (-.30,.099,-.028)], [.055,.052,.045,.022],skin,target,1,12,2))
    for part in parts:
        bpy.context.view_layer.objects.active=part
        for mod in list(part.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
    obj=geometry.fuse('Tablet_support_hand',parts,skin,target,.005)
    bpy.context.view_layer.objects.active=obj
    for mod in list(obj.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.calc_loop_triangles()
    lod=obj.modifiers.new('Grip LOD','DECIMATE')
    lod.ratio=min(1,4000/len(obj.data.loop_triangles))
    bpy.ops.object.modifier_apply(modifier=lod.name)
    obj.data.transform(Matrix.Translation(Vector(wrist)-support_wrist(dz))@frame(dz))
    weight(obj,'hand.support.R')
    return obj
