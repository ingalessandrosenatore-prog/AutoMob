import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { clone as cloneSkeleton } from 'three/addons/utils/SkeletonUtils.js';
import { MascotController } from '../../../../mascot_runtime/controller.mjs';
import { depthSlot, visualIndex, dataIndex, DepthMotion } from './depth_layout.mjs';

const stage=document.querySelector('#stage');
const overlay=document.querySelector('#overlay');
const add=document.querySelector('#add');
const status=document.querySelector('#status');
const emit=(message)=>window.WorkshopBridge?.postMessage(JSON.stringify(message));
let manifest, model, items=[], figures=new Map(), selected=0, ready=false;
const motion = new DepthMotion();
let pendingAnimation = false;
let visible = true;
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');

const renderer=new THREE.WebGLRenderer({antialias:true,alpha:true,powerPreference:'low-power'});
renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));
renderer.setClearColor(0x000000,0);
renderer.toneMapping=THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure=1.15;
stage.append(renderer.domElement);
const scene=new THREE.Scene();
scene.add(new THREE.HemisphereLight(0xffffff,0x394155,2.2));
for(const [position,color,power] of [[[3,7,6],0xffe8d0,2.7],[[-4,5,1],0xbbd6ff,1.8],[[1,4,-4],0xff8d43,2.4]]){
  const light=new THREE.DirectionalLight(color,power);light.position.set(...position);scene.add(light);
}
const camera=new THREE.PerspectiveCamera(39,1,.1,50);
camera.position.set(0,3.1,8.8);
camera.lookAt(0,2.55,0);
new ResizeObserver(()=>{
  const {clientWidth:w,clientHeight:h}=stage;
  camera.aspect=w/h;camera.updateProjectionMatrix();renderer.setSize(w,h);
  layout();
}).observe(stage);

function slot(index){
  const place=depthSlot(visualIndex(index,items.length)-motion.position);
  // Compensate horizontal perspective: slot x is a fraction of viewport width.
  const viewHeight=2*Math.tan(THREE.MathUtils.degToRad(camera.fov/2))*(camera.position.z-place.z);
  return {...place,x:place.x*viewHeight*camera.aspect};
}
function screenX(x,y,z){
  const p=new THREE.Vector3(x,y,z).project(camera);
  return (p.x+1)*stage.clientWidth/2;
}
function layout(){
  if(!stage.clientWidth)return;
  const plus=slot(0);
  add.style.left=`${screenX(plus.x,2.0,plus.z)}px`;
  add.style.transform=`translateX(-50%) scale(${plus.scale})`;
  add.style.opacity=String(plus.opacity);
  add.style.pointerEvents=plus.opacity>.1?'auto':'none';
  add.style.bottom=`${29+(1-plus.scale)*65}px`;
  for(let i=0;i<items.length;i++){
    const entry=figures.get(items[i].id),place=slot(i+1);
    if(!entry)continue;
    entry.group.position.set(place.x,(1-place.scale)*1.8,place.z);
    entry.group.scale.setScalar(place.scale);
    entry.group.visible=place.opacity>0;
    entry.label.style.left=`${screenX(place.x,0,place.z)}px`;
    entry.label.style.opacity=String(place.opacity);
    entry.label.style.bottom=`${5+(1-place.scale)*70}px`;
    entry.label.style.pointerEvents=place.opacity>.1?'auto':'none';
    entry.label.style.zIndex=String(Math.round(place.scale*100));
    entry.label.style.maxWidth=`${Math.max(65,stage.clientWidth*.35*place.scale)}px`;
    entry.label.classList.toggle('active',selected===i+1);
  }
}
function makeFigure(item,index){
  // SkeletonUtils gives each character independent bones while sharing one
  // immutable geometry buffer. Clothes materials are copied per workshop.
  const root=cloneSkeleton(model.scene);
  root.traverse(node=>{
    if(!node.isMesh)return;
    node.material=[].concat(node.material).map(mat=>
      mat.name==='AM_Clothes_Base'||mat.name==='AM_Clothes_Accent'?mat.clone():mat);
    if(node.material.length===1)node.material=node.material[0];
  });
  const group=new THREE.Group();group.add(root);scene.add(group);
  const mixer=new THREE.AnimationMixer(root);
  const controller=new MascotController({root,clips:model.animations,mixer,engine:THREE,manifest});
  controller.configure({pose:item.pose,prop:item.prop});
  controller.setColors({base:item.baseColor,accent:item.accentColor});
  // Static neighbours receive their first pose but never a per-frame update.
  mixer.update(0);
  const label=document.createElement('div');
  label.className='label';label.textContent=item.name.toUpperCase();
  label.addEventListener('click',()=>selectOrOpen(items.findIndex(value=>value.id===item.id)+1));
  overlay.append(label);
  return {group,mixer,controller,label};
}
function disposeFigure(entry){
  entry.controller.dispose();scene.remove(entry.group);entry.label.remove();
  entry.group.traverse(node=>{
    for(const mat of [].concat(node.material??[])){
      if(mat.name==='AM_Clothes_Base'||mat.name==='AM_Clothes_Accent')mat.dispose();
    }
  });
}
function renderItems(){
  if(!ready)return;
  const incoming=new Set(items.map(item=>item.id));
  for(const [id,entry] of figures)if(!incoming.has(id)){disposeFigure(entry);figures.delete(id);}
  items.forEach((item,index)=>{
    const previous=figures.get(item.id);
    if(previous){
      previous.label.textContent=item.name.toUpperCase();
      previous.controller.configure({pose:item.pose,prop:item.prop});
      previous.controller.setColors({base:item.baseColor,accent:item.accentColor});
    }else figures.set(item.id,makeFigure(item,index));
  });
  selected=Math.min(selected,items.length);
  activate();layout();
}
function activate(){
  figures.forEach(entry=>entry.controller.stop());
  if(selected>0){
    const item=items[selected-1],entry=figures.get(item?.id);
    if(entry){
      const gesture={wrench:'spin',screwdriver:'spin',tablet:'tap',tire:'dribble'}[item.prop];
      entry.controller.play(gesture);
    }
  }
}
function select(index,send=true){
  const next=Math.max(0,Math.min(index,items.length));
  if(next===selected)return;
  selected=next;
  motion.target=visualIndex(next,items.length);
  pendingAnimation=true;
  if(reducedMotion.matches)motion.jump(motion.target);
  if(send)emit({type:'selected',index:next});
}
function selectOrOpen(index){
  if(index===selected)emit(index===0?{type:'add'}:{type:'open',index});
  else select(index);
}
add.addEventListener('click',()=>selectOrOpen(0));
let startX, startY;
stage.addEventListener('pointerdown',e=>{
  startX=e.clientX;startY=e.clientY;
  motion.begin(e.clientX);stage.setPointerCapture(e.pointerId);
});
stage.addEventListener('pointermove',e=>{
  if(startX===undefined)return;
  motion.drag(e.clientX,stage.clientWidth,items.length);layout();
});
stage.addEventListener('pointerup',e=>{
  if(startX===undefined)return;
  const delta=e.clientX-startX,vertical=Math.abs(e.clientY-startY);startX=undefined;
  const next=motion.release(items.length);
  if(Math.abs(delta)>8){select(dataIndex(next,items.length));}
  else if(vertical<8){motion.target=visualIndex(selected,items.length);selectOrOpen(selected);}
});
stage.addEventListener('pointercancel',()=>{
  startX=undefined;motion.dragging=false;motion.target=visualIndex(selected,items.length);
});

// Flutter sends only domain data and an index. JS owns scene and GPU lifetime.
window.setWorkshops=(payload)=>{
  const changed=JSON.stringify(items)!==JSON.stringify(payload.items??[]);
  items=payload.items??[];
  const next=Math.max(0,Math.min(payload.selected??0,items.length));
  if(changed){selected=next;motion.jump(visualIndex(next,items.length));renderItems();}
  else select(next,false);
};
window.selectWorkshop=(index)=>select(index,false);
window.setSceneVisible=(value)=>{visible=Boolean(value);};

async function start(){try{
  manifest=await fetch('./manifest.json').then(r=>r.json());
  model=await new GLTFLoader().loadAsync('./automob_mascot.glb');
  ready=true;renderItems();emit({type:'ready'});
  const clock=new THREE.Clock();
  let elapsed=0;
  renderer.setAnimationLoop(()=>{
    elapsed+=clock.getDelta();
    if(elapsed<1/30)return;
    const dt=Math.min(elapsed,.05);elapsed=0;
    if(document.hidden||!visible)return;
    motion.update(dt);layout();
    if(pendingAnimation&&!motion.moving){activate();pendingAnimation=false;}
    const active=items[selected-1];
    if(active&&!motion.moving&&!reducedMotion.matches)figures.get(active.id)?.mixer.update(dt);
    renderer.render(scene,camera);
  });
}catch(error){
  status.style.display='grid';status.textContent='Personaggi 3D non disponibili';
  emit({type:'error',message:String(error)});
}}
start();
