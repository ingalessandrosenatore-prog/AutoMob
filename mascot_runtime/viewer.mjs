import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { MascotController } from './controller.mjs';

const stage=document.querySelector('#stage');
const status=document.querySelector('#status');
const renderer=new THREE.WebGLRenderer({antialias:true,alpha:true});
renderer.setPixelRatio(Math.min(devicePixelRatio,2));
renderer.toneMapping=THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure=1.1;
stage.append(renderer.domElement);
const scene=new THREE.Scene();
scene.add(new THREE.HemisphereLight(0xffffff,0x3b4058,2));
for(const [position,color,power] of [[[3,8,6],0xffead7,3],[[-4,5,2],0xc0d6ff,2],[[2,7,-5],0xff8c38,3]]){
  const light=new THREE.DirectionalLight(color,power);light.position.set(...position);scene.add(light);
}
const camera=new THREE.PerspectiveCamera(32,1,.1,100);
camera.position.set(5,4.7,12);
const controls=new OrbitControls(camera,renderer.domElement);
controls.target.set(0,2.75,0);controls.enableDamping=true;controls.update();
new ResizeObserver(()=>{
  camera.aspect=stage.clientWidth/stage.clientHeight;camera.updateProjectionMatrix();
  renderer.setSize(stage.clientWidth,stage.clientHeight);
}).observe(stage);
const clock=new THREE.Clock();
let mascot;
renderer.setAnimationLoop(()=>{
  const dt=Math.min(clock.getDelta(),.05);
  mascot?.mixer.update(dt);controls.update();renderer.render(scene,camera);
});
const gesture={wrench:'spin',screwdriver:'spin',tablet:'tap',tire:'dribble'};
const labels={wrench:'Chiave inglese',screwdriver:'Cacciavite',tablet:'Tablet',tire:'Gomma'};
const verbs={spin:'Fai ruotare e riprendi',tap:'Tocca il tablet',dribble:'Palleggia con la gomma'};
try{
  const manifest=await fetch('./manifest.json',{cache:'no-store'}).then(r=>r.json());
  const gltf=await new GLTFLoader().loadAsync(`./automob_mascot.glb?v=${encodeURIComponent(manifest.revision??'hands-2')}`);
  scene.add(gltf.scene);
  mascot=new MascotController({root:gltf.scene,clips:gltf.animations,mixer:new THREE.AnimationMixer(gltf.scene),engine:THREE,manifest,
    onChange:state=>{
      status.textContent=`${labels[state.prop]} · ${state.gesture==='idle'?'in attesa':state.gesture} · ${gltf.animations.length} clip`;
      window.AutoMobChannel?.postMessage(JSON.stringify({type:'state',...state}));
    }});
  window.automob=mascot;
  // Diagnostic surface for actual GLB/browser verification, not a Flutter API.
  window.mascotPreview={scene,camera,renderer,controls,gltf};
  const pose=document.querySelector('#pose'),prop=document.querySelector('#prop');
  function populate(){
    const previous=prop.value;
    prop.replaceChildren(...manifest.poses[pose.value].props.map(key=>new Option(labels[key],key)));
    if(manifest.poses[pose.value].props.includes(previous))prop.value=previous;
    mascot.configure({pose:pose.value,prop:prop.value});
    document.querySelector('#play').textContent=verbs[gesture[prop.value]];
  }
  populate();
  pose.addEventListener('change',populate);
  prop.addEventListener('change',()=>{mascot.setProp(prop.value);document.querySelector('#play').textContent=verbs[gesture[prop.value]];});
  for(const key of ['base','accent'])document.querySelector('#'+key).addEventListener('input',e=>mascot.setColors({[key]:e.target.value}));
  document.querySelector('#play').addEventListener('click',()=>mascot.play(gesture[prop.value]));
  document.querySelector('#idle').addEventListener('click',()=>mascot.stop());
  document.querySelector('#time').addEventListener('input',e=>{if(mascot.state.gesture==='idle')mascot.play(gesture[prop.value]);mascot.seek(Number(e.target.value));});
  document.querySelectorAll('button').forEach(button=>button.disabled=false);
  window.dispatchEvent(new Event('mascot-ready'));
}catch(error){status.textContent=`Impossibile caricare: ${error.message}`;window.mascotError=error.stack;console.error(error);}
