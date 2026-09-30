"""Independent selectable props, including a geometric lightning screen icon."""
import bpy
from mathutils import Vector
from mesh_tools import cube, cylinder, material, join, weight
from tablet_layout import frame


def screwdriver(wrist, target, rig):
    x, y, z = wrist+Vector((0,-.11,.12))
    orange = material("AM_Tool_Handle", (.8,.16,.015))
    metal = material("RT_AM2_steel", (.43,.49,.55), .8, .32)
    parts = [cylinder("Driver_handle", (x,y,z-.03), .066, .32, orange,target),
             cylinder("Driver_shaft", (x,y,z+.29), .025, .36, metal,target),
             cube("Driver_tip", (x,y,z+.49), (.036,.012,.044),metal,target,.005)]
    for part in parts:
        weight(part,"screwdriver")
    return join(parts, rig["pose"]+"_PROP_screwdriver",rig)


def tablet(center, target, rig):
    x,y,z = 0,0,0
    shell = material("AM_Tablet_Frame", (.018,.025,.035), .25,.38)
    glass = material("AM_Tablet_Screen", (.012,.07,.12), .1,.25)
    bolt = material("AM_Tablet_Lightning", (1,.65,.06),0,.4)
    shader = next(n for n in bolt.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Emission Color"].default_value = (1,.47,.015,1)
    shader.inputs["Emission Strength"].default_value = .6
    parts = [cube("Tablet_frame",(0,0,0),(.40,.055,.55),shell,target,.05),
             cube("Tablet_screen",(x,y+.057,z),(.351,.005,.488),glass,target,.025)]
    outline=[(-.035,.31),(-.18,-.025),(-.035,-.025),(-.10,-.30),
             (.20,.08),(.04,.08),(.10,.31)]
    data=bpy.data.meshes.new("Lightning")
    data.from_pydata([(x+a,y+.065,z+b) for a,b in outline],[],[tuple(reversed(range(len(outline))))])
    data.materials.append(bolt)
    obj=bpy.data.objects.new("Tablet_lightning",data)
    target.objects.link(obj)
    parts.append(obj)
    for part in parts:
        part.data.transform(frame(-.23 if rig["pose"]=="desk" else 0))
        weight(part,"tablet")
    return join(parts,rig["pose"]+"_PROP_tablet",rig)
