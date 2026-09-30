"""Continuous scalp-following underlayer, retaining the approved outer tufts."""
import math
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mesh_tools import weight


def make_cap(face, target, hair, dz, geometry):
    vertices=[v.co.copy() for v in face.data.vertices]
    tree=BVHTree.FromPolygons(vertices,[list(p.vertices) for p in face.data.polygons])
    center=Vector((0,0,4.43+dz))
    sides, rows=96,30
    points=[]
    for row in range(rows+1):
        for col in range(sides):
            angle=math.tau*col/sides
            # High forehead, full temples and nape. Ray casting follows the
            # actual rounded-square face, not an ellipsoid that cuts into it.
            front=min(1,max(0,-math.sin(angle))/.50)
            front=front*front*(3-2*front)
            # A broad recessed frontal edge stays UNDER the first quiff row;
            # a sinusoidal hairline alone leaves a dark wedge on the forehead.
            limit=1.50+.70*max(0,math.sin(angle))-.84*front
            theta=.004+(limit-.004)*row/rows
            direction=Vector((math.sin(theta)*math.cos(angle),
                              math.sin(theta)*math.sin(angle),math.cos(theta)))
            hit,_,_,_=tree.ray_cast(center,direction,2)
            assert hit is not None, "Scalp ray missed head"
            points.append(hit+direction*.037)
    faces=[]
    for row in range(rows):
        for col in range(sides):
            a=row*sides+col; b=row*sides+(col+1)%sides
            # Outward normals are essential for glTF's single-sided materials.
            faces.append((a,a+sides,b+sides,b))
    faces.append(tuple(range(sides)))
    mesh=bpy.data.meshes.new('Continuous_scalp')
    mesh.from_pydata(points,[],faces)
    mesh.materials.append(hair)
    obj=bpy.data.objects.new('Continuous_hair_cap',mesh)
    target.objects.link(obj)
    for poly in mesh.polygons:poly.use_smooth=True
    bpy.context.view_layer.objects.active=obj
    solid=obj.modifiers.new('Hairline thickness','SOLIDIFY')
    solid.thickness=.018
    solid.offset=-1
    bpy.ops.object.modifier_apply(modifier=solid.name)
    weight(obj,'head')
    result=[obj]
    # Continue the direction of the existing side locks across the crown.
    # These overlap the underlayer, rather than leaving floating leaf tips.
    for ring in range(2):
        for col in range(12):
            angle=math.tau*col/12+.22*ring
            if math.sin(angle)<-.55:continue
            path=[]; radii=[]
            for step in range(17):
                t=step/16
                theta=.08+.50*ring+.72*t
                phi=angle+.38*t
                direction=Vector((math.sin(theta)*math.cos(phi),
                    math.sin(theta)*math.sin(phi),math.cos(theta)))
                hit,_,_,_=tree.ray_cast(center,direction,2)
                path.append(hit+direction*(.040+.038*math.sin(math.pi*t)))
                radii.append(max(.008,.125*math.sin(math.pi*t)**.7))
            tuft=geometry.tube('Crown_lock',path,radii,hair,target,.58,12,1)
            bpy.context.view_layer.objects.active=tuft
            for mod in list(tuft.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
            weight(tuft,'head')
            result.append(tuft)
    return result
