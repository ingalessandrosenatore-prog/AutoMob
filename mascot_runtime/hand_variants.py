"""Additional gesture meshes; the approved closed grip is kept unchanged."""
import bpy
from mathutils import Matrix, Vector
from mesh_tools import weight


def make_hand(mode, wrist, target, geometry, skin):
    x, y, z = wrist
    parts = []
    def tube(label, path, radii):
        obj = geometry.tube(mode+label, [(x+a, y+b, z+c) for a, b, c in path],
                            radii, skin, target, 1, 12, 2)
        bpy.context.view_layer.objects.active = obj
        for mod in list(obj.modifiers):
            bpy.ops.object.modifier_apply(modifier=mod.name)
        parts.append(obj)
    palm = geometry.loft(mode+"_palm", [
        (x, y, z-.07, .078, .067), (x, y-.018, z, .10, .061),
        (x, y-.025, z+.11, .135, .060), (x, y-.027, z+.20, .118, .048),
    ], skin, target)
    bpy.context.view_layer.objects.active = palm
    bpy.ops.object.modifier_apply(modifier=palm.modifiers[0].name)
    parts.append(palm)
    if mode in {"point", "tap"}:
        fingertip = .46 if mode == "tap" else .57
        tube("_index", [(-.04,-.05,.17), (-.018,-.095,.29),
                       (0,-.11,fingertip-.10), (0,-.11,fingertip-.02), (0,-.11,fingertip)],
                       [.047,.046,.041,.036,.018])
        for index, h in enumerate([.14,.053,-.024]):
            r = .047-index*.003
            tube("_curl", [(.10,-.02,h),(.15,-.11,h),(.08,-.19,h),
                           (-.07,-.19,h-.013),(-.11,-.08,h-.03)],
                           [r,r,r,r*.90,r*.65])
        tube("_thumb", [(-.09,-.012,.08),(-.16,-.08,.19),(-.12,-.19,.21),
                        (-.05,-.24,.15),(-.015,-.22,.12)], [.064,.060,.053,.046,.025])
    else:
        for index, (xx, length) in enumerate([(-.10,.32),(-.029,.37),(.045,.34),(.109,.25)]):
            tube("_finger", [(xx,-.023,.17), (xx*1.16,-.04,.25),
                              (xx*1.23,-.055,.20+length), (xx*1.23,-.07,.22+length)],
                              [.042,.038,.032,.016])
        tube("_thumb", [(-.08,-.02,.05),(-.16,-.04,.12),(-.21,-.065,.22),
                        (-.22,-.08,.26)], [.061,.052,.042,.019])
    obj = geometry.fuse("Gesture_"+mode, parts, skin, target, .006)
    bpy.context.view_layer.objects.active = obj
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.calc_loop_triangles()
    mod = obj.modifiers.new("Gesture LOD", "DECIMATE")
    mod.ratio = min(1, 4500/len(obj.data.loop_triangles))
    bpy.ops.object.modifier_apply(modifier=mod.name)
    weight(obj, "hand."+mode)
    return obj


def make_relaxed_right(wrist, target, geometry, skin):
    """Right-hand neutral pose: fingers down, palm inward, thumb forward."""
    x,y,z=wrist
    palm=geometry.loft("Right_relaxed_palm",[
        (x,y,z-.205,.060,.101), (x,y,z-.15,.068,.113),
        (x,y,z-.055,.070,.102), (x,y,z+.015,.085,.088),
        (x,y,z+.09,.078,.080)],skin,target)
    parts=[palm]
    for lane,length,radius in [(-.086,.105,.036),(-.024,.133,.038),(.040,.118,.035),(.094,.083,.029)]:
        path=[(x+.005,y+lane,z-.158),(x+.008,y+lane,z-.207),
              (x+.032,y+lane,z-.205-length),(x+.073,y+lane,z-.20-length+.022)]
        parts.append(geometry.tube("Right_relaxed_finger",path,
            [radius,radius,radius*.90,radius*.50],skin,target,1,12,2))
    parts.append(geometry.tube("Right_relaxed_thumb",[
        (x+.015,y-.077,z-.035),(x+.042,y-.139,z-.08),
        (x+.083,y-.15,z-.145),(x+.095,y-.13,z-.173)],
        [.052,.048,.038,.022],skin,target,1,12,2))
    for part in parts:
        bpy.context.view_layer.objects.active=part
        for mod in list(part.modifiers):
            bpy.ops.object.modifier_apply(modifier=mod.name)
    obj=geometry.fuse("Right_relaxed_hand",parts,skin,target,.006)
    bpy.context.view_layer.objects.active=obj
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.calc_loop_triangles()
    mod=obj.modifiers.new("Relaxed hand LOD","DECIMATE")
    mod.ratio=min(1,3500/len(obj.data.loop_triangles))
    bpy.ops.object.modifier_apply(modifier=mod.name)
    weight(obj,"hand.relaxed.R")
    return obj
