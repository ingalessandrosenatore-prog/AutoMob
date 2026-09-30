"""Baked clip choreography, with analytic two-bone arm posing and no runtime IK."""
import math
import bpy
from mathutils import Matrix, Quaternion, Vector
from tablet_layout import support_wrist, tap_target, tap_direction, normal
from idle_motion import IDLE_DURATION, IDLE_CLIP_DURATION, beat, hands as idle_hands, apply_body
from relaxed_fingers import pose_fingers
from handoff_motion import handoff, hand_modes, receiving, GRIP_SPACING
from leg_motion import shoe_inspection

FPS=30
DURATION=4


def smooth(t):
    t=max(0,min(1,t))
    return t*t*(3-2*t)


def envelope(t, enter=.2, ready=.8, leave=3.15, end=3.8):
    return smooth((t-enter)/(ready-enter))*(1-smooth((t-leave)/(end-leave)))


def pivot(point, rotation=None, scale=None):
    change=rotation.to_matrix().to_4x4() if rotation else Matrix.Identity(4)
    if scale:
        change=change@Matrix.Diagonal((*scale,1))
    return Matrix.Translation(point)@change@Matrix.Translation(-point)


def tap_orientation(direction):
    # A shortest-arc rotation aligns only the finger, leaving wrist roll
    # unconstrained. Also align the thumb upward so the palm faces the screen.
    source_axis=Vector((0,-.11,.46)).normalized()
    source_thumb=Vector((-1,0,0))
    target_axis=Vector(direction).normalized()
    up=Vector((0,0,1))
    target_thumb=(up-target_axis*up.dot(target_axis)).normalized()
    source=Matrix((source_thumb,source_axis.cross(source_thumb),source_axis)).transposed()
    target=Matrix((target_thumb,target_axis.cross(target_thumb),target_axis)).transposed()
    return (target@source.transposed()).to_quaternion()


def arm(rig, rests, side, target, rotation):
    a,b,c=[rests[k+"."+side] for k in ["upper","lower","wrist"]]
    target=Vector(target)
    upper=(b-a).length
    lower=(c-b).length
    delta=target-a
    distance=min(delta.length,(upper+lower)*.995)
    target=a+delta.normalized()*distance
    direction=(target-a).normalized()
    pole=b-a-direction*(b-a).dot(direction)
    if pole.length<.01:
        pole=Vector((0,1,0))
    reach=(upper*upper-lower*lower+distance*distance)/(2*distance)
    height=math.sqrt(max(0,upper*upper-reach*reach))
    elbow=a+direction*reach+pole.normalized()*height
    for key,old_start,old_end,new_start,new_end in [
        ("upper."+side,a,b,a,elbow),("lower."+side,b,c,elbow,target)]:
        q=(old_end-old_start).rotation_difference(new_end-new_start)
        change=Matrix.Translation(new_start)@q.to_matrix().to_4x4()@Matrix.Translation(-old_start)
        rig.pose.bones[key].matrix=change@rig.data.bones[key].matrix_local
    change=Matrix.Translation(target)@rotation.to_matrix().to_4x4()@Matrix.Translation(-c)
    rig.pose.bones["wrist."+side].matrix=change@rig.data.bones["wrist."+side].matrix_local
    return change


def face(rig, rests, t, look=0, glance=0, duration=DURATION):
    wave=math.sin(math.tau*t/duration)
    turn=Quaternion((0,0,1),math.radians(1.8)*wave+glance)
    nod=Quaternion((1,0,0),math.radians(1.1)*math.sin(math.tau*t/2)+.14*look)
    head=pivot(rests["head"],turn@nod)
    rig.pose.bones["head"].matrix=head@rig.data.bones["head"].matrix_local
    # Child world matrices must be resolved against the NEW head transform.
    # Otherwise Blender computes their local poses using the previous parent,
    # doubling the tilt and pushing the eyes through the face surface.
    bpy.context.view_layer.update()
    blink=max(math.exp(-((t-center)/.085)**2) for center in [1.35,3.15,5.4,7.15,10.7,14.2,17.4,20.6,23.1])
    for side in ["L","R"]:
        key="eye."+side
        delta=pivot(rests[key],scale=(1,1,max(.04,1-blink)))
        rig.pose.bones[key].matrix=head@delta@rig.data.bones[key].matrix_local
        key="brow."+side
        delta=Matrix.Translation((0,0,.012*wave+.012*look))
        rig.pose.bones[key].matrix=head@delta@rig.data.bones[key].matrix_local


def pose_at(rig, rests, prop, gesture, t):
    for pb in rig.pose.bones:
        pb.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    active=envelope(t) if gesture!="idle" else 0
    dz=-.23 if rig["pose"]=="desk" else 0
    q=Quaternion()
    right_q=Quaternion()
    wrist=rests["wrist.L"].copy()
    # The empty arm hangs at the side; its hand is not the palm-up tablet grip.
    right=Vector((-.88,-.10,2.46+dz))
    mode="closed"
    right_mode="support" if prop=="tablet" else "relaxed"
    passing=gesture=="idle" and prop in {"wrench","screwdriver"}
    if prop=="tablet":
        right=support_wrist(dz)
        fingertip=tap_target(dz)
        direction=tap_direction()
        wrist=fingertip-direction*Vector((0,-.11,.46)).length
        q=tap_orientation(direction)
        mode="tap"
        if gesture=="tap":
            taps=sum(math.exp(-((t-center)/.095)**2) for center in [1.0,1.65,2.30,2.95])
            wrist-=normal()*.030*taps
    elif prop=="tire":
        wrist=Vector((1.0,-.33,2.64))
        q=Quaternion((1,0,0),math.pi/2)
        mode="open"
        if gesture=="dribble":
            # Three parabolic bounces. At the endpoints the tire is held again.
            phase=max(0,min(3,(t-.55)/.82))
            u=phase%1 if phase<3 else 0
            drop=1.36*4*u*(1-u) if 0<phase<3 else 0
            wrist.z-=.14*math.sin(math.pi*u)*active
            tire_delta=Matrix.Translation((0,0,-drop))
            squash=.08*math.exp(-((u-.5)/.07)**2) if 0<phase<3 else 0
            tire_delta=tire_delta@pivot(rests["tire"],scale=(1+squash*.5,1+squash*.5,1-squash))
            rig.pose.bones["tire"].matrix=tire_delta@rig.data.bones["tire"].matrix_local
    elif gesture=="spin":
        wrist.z+=.06*active
        q=Quaternion((0,1,0),.04*math.sin(math.tau*t)*active)
        mode="point" if .55<t<3.45 else "closed"

    if gesture=="idle":
        before=wrist.copy()
        wrist,right,q,right_q=idle_hands(prop,t,wrist,right,q,rig["pose"])
        if passing:
            wrist,right,q,right_q=handoff(rig["pose"],t,wrist,right,q,right_q)
            mode,right_mode=hand_modes(t)
        if prop=="tire":
            rig.pose.bones["tire"].matrix=Matrix.Translation(wrist-before)@rig.data.bones["tire"].matrix_local
    hand=arm(rig,rests,"L",wrist,q)
    right_hand=arm(rig,rests,"R",right,right_q)
    for variant in ["closed","point","tap","open"]:
        rig.pose.bones["hand."+variant].scale=(1,1,1) if variant==mode else (.0001,)*3
    rig.pose.bones["hand.relaxed.L"].scale=(1,1,1) if mode=="relaxed" else (.0001,)*3
    for variant in ["relaxed","support","closed"]:
        visible=variant==right_mode
        rig.pose.bones["hand."+variant+".R"].scale=(1,1,1) if visible else (.0001,)*3
    pose_fingers(rig,prop,gesture,t)
    for tool in ["wrench","screwdriver"]:
        change=hand
        if passing and receiving(t):
            offset=rests["wrist.R"]-rests["wrist.L"]+Vector((0,0,GRIP_SPACING))
            change=right_hand@Matrix.Translation(offset)
        if gesture=="spin" and prop==tool:
            # Hold still, lift onto the index, spin six turns, then catch.
            progress=smooth((t-.85)/2.15)
            theta=math.tau*6*progress
            spin=Quaternion((0,0,1),theta)
            lift=(.73 if tool=="wrench" else .48)*active
            change=hand@Matrix.Translation((0,0,lift))@pivot(rests[tool],spin)
        rig.pose.bones[tool].matrix=change@rig.data.bones[tool].matrix_local
    glance=.10*beat(t,.5,2.7) if gesture=="idle" and prop in {"wrench","screwdriver"} else 0
    look=.8+.2*active if prop=="tablet" else 0
    if gesture=="idle" and rig["pose"]=="standing":
        look+=1.2*shoe_inspection(t)
    face(rig,rests,t,look,glance,
         IDLE_DURATION if gesture=="idle" else DURATION)
    bpy.context.view_layer.update()
    if gesture=="idle":
        apply_body(rig,rests,prop,t)


def make_actions(rig, rests):
    props=["wrench","screwdriver","tablet"]
    if rig["pose"]=="standing":
        props.append("tire")
    clips=[]
    for prop in props:
        gesture={"wrench":"spin","screwdriver":"spin","tablet":"tap","tire":"dribble"}[prop]
        for kind in ["idle",gesture]:
            name=f'{rig["pose"]}_{prop}_{kind}'
            action=bpy.data.actions.new(name)
            action.use_fake_user=True
            rig.animation_data_create()
            rig.animation_data.action=action
            duration=IDLE_CLIP_DURATION if kind=="idle" else DURATION
            for frame in range(0,FPS*duration+1,2):
                bpy.context.scene.frame_set(frame)
                time=frame/FPS
                if kind=="idle":
                    time*=IDLE_DURATION/IDLE_CLIP_DURATION
                pose_at(rig,rests,prop,kind,time)
                for pb in rig.pose.bones:
                    for path in ["location","rotation_quaternion","scale"]:
                        pb.keyframe_insert(path,frame=frame,group=pb.name)
            # Sampling removes IK dependencies; glTF only needs bone transforms.
            for layer in action.layers:
                for strip in layer.strips:
                    for slot in action.slots:
                        bag=strip.channelbag(slot,ensure=False)
                        if bag:
                            for curve in bag.fcurves:
                                for key in curve.keyframe_points:
                                    key.interpolation="LINEAR"
            clips.append({"name":name,"pose":rig["pose"],"prop":prop,
                          "gesture":kind,"duration":duration,"loop":kind=="idle"})
    rig.animation_data.action=None
    pose_at(rig,rests,"wrench","idle",0)
    return clips
