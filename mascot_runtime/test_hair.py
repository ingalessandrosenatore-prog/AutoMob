"""Check crown/back coverage and the recessed front edge on generated meshes."""
import math
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

bpy.ops.wm.open_mainfile(filepath=str(Path(__file__).with_name('automob_mascot_animated.blend')))
samples=0
for pose in ['standing','desk']:
    body=bpy.data.objects[pose+'_BODY']
    vertices=[v.co.copy() for v in body.data.vertices]
    def surface(material):
        return BVHTree.FromPolygons(vertices,[list(p.vertices) for p in body.data.polygons
            if body.data.materials[p.material_index].name==material])
    hair=surface('RT_AM2_hair')
    skin=surface('RT_AM2_skin')
    center=Vector((0,0,4.43+(-.23 if pose=='desk' else 0)))
    for col in range(24):
        phi=math.tau*col/24
        # Crown everywhere, sides and nape beyond the recessed frontal sector.
        angles=[.15,.35,.55]
        if math.sin(phi)>=0:angles += [.85,1.15,1.45]
        if math.sin(phi)>.5:angles += [1.7,1.9]
        for theta in angles:
            direction=Vector((math.sin(theta)*math.cos(phi),
                math.sin(theta)*math.sin(phi),math.cos(theta)))
            # Test the visible surface from outside. Tuft roots intentionally
            # intersect the scalp and are not the coverage surface.
            scalp=skin.ray_cast(center+direction*2,-direction,2)[0]
            cover=hair.ray_cast(center+direction*2,-direction,2)[0]
            assert scalp is not None and cover is not None,(pose,phi,theta,'Missing coverage')
            assert (cover-center).length>(scalp-center).length+.015,(pose,phi,theta,'Hair inside scalp')
            samples+=1
    # Forehead sample above the eyebrows must remain skin, not the new cap.
    origin=Vector((0,-2,center.z+.37))
    direction=Vector((0,1,0))
    scalp=skin.ray_cast(origin,direction,2)[0]
    cover=hair.ray_cast(origin,direction,2)[0]
    assert scalp is not None
    assert cover is None or cover.y>scalp.y, 'Dark forehead band'
print('PASS_HAIR_COVERAGE',samples,'rays; forehead clear in both poses')
