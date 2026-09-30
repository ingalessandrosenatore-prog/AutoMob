import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { MascotController } from './controller.mjs';

function fixture(){
  const manifest=JSON.parse(readFileSync(new URL('./manifest.json',import.meta.url)));
  const nodes=new Map();
  const colors=new Map();
  for(const [pose,spec] of Object.entries(manifest.poses)){
    nodes.set(spec.root,{visible:true});
    for(const prop of spec.props)nodes.set(`${pose}_PROP_${prop}`,{visible:true});
  }
  for(const name of [...Object.values(manifest.materials),'skin'])nodes.set(name,{material:{name,color:{set:v=>colors.set(name,v)}}});
  const listeners={};
  const mixer={timeScale:1,addEventListener:(k,f)=>listeners[k]=f,removeEventListener:()=>{},update:()=>{},stopAllAction:()=>{},uncacheRoot:()=>{},
    clipAction(clip){return {clip,time:0,reset(){return this},setLoop(mode,n){this.loop=mode;this.repetitions=n},play(){return this},stop(){this.stopped=true},getClip(){return clip}}}};
  const root={traverse:f=>nodes.forEach(f),getObjectByName:n=>nodes.get(n)};
  const controller=new MascotController({root,clips:manifest.clips.map(c=>({name:c.name,duration:c.duration})),mixer,engine:{LoopOnce:1,LoopRepeat:2},manifest});
  return {controller,nodes,colors,listeners,mixer};
}
test('one actor and selected prop, all seven combinations',()=>{
  const {controller:c,nodes}=fixture();
  for(const [pose,spec] of Object.entries(c.manifest.poses))for(const prop of spec.props){
    c.configure({pose,prop});
    assert.equal(nodes.get(spec.root).visible,true);
    for(const candidate of spec.props)assert.equal(nodes.get(`${pose}_PROP_${candidate}`).visible,candidate===prop);
  }
});
test('unsupported seated tire leaves state unchanged',()=>{
  const {controller:c}=fixture();const before={...c.state};
  assert.throws(()=>c.configure({pose:'desk',prop:'tire'}));assert.deepEqual(c.state,before);
});
test('palette changes only named clothes materials; invalid palette is atomic',()=>{
  const {controller:c,colors}=fixture();c.setColors({base:'#000000',accent:'#ff0000'});
  assert.equal(colors.get('AM_Clothes_Accent'),'#ff0000');assert.equal(colors.has('skin'),false);
  assert.throws(()=>c.setColors({base:'#ffffff',accent:'bad'}));assert.equal(colors.get('AM_Clothes_Base'),'#000000');
});
test('one shot returns to idle, explicit loops remain possible',()=>{
  const {controller:c,listeners}=fixture();c.play('spin');assert.equal(c.action.loop,1);
  listeners.finished({action:c.action});assert.equal(c.state.gesture,'idle');
  c.play('spin',{loop:true});assert.equal(c.action.loop,2);
});
test('unsupported gesture is rejected without stopping active action',()=>{
  const {controller:c}=fixture();const action=c.action;assert.throws(()=>c.play('dribble'));assert.equal(action.stopped,undefined);
});
