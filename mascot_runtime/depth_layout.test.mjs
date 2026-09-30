import {test} from 'node:test';
import assert from 'node:assert/strict';
import {depthSlot, DepthMotion, visualIndex, dataIndex} from '../auto_mob/lib/assets/mascot/depth_layout.mjs';

test('four slots have foreground priority and receding right neighbours',()=>{
  assert.equal(depthSlot(0).scale,1);
  assert.ok(depthSlot(-1).x<depthSlot(0).x);
  assert.ok(depthSlot(1).x>depthSlot(0).x);
  assert.ok(depthSlot(2).z<depthSlot(1).z);
  assert.ok(depthSlot(2).scale<depthSlot(1).scale);
  assert.equal(depthSlot(-2).opacity,0);
  assert.equal(depthSlot(3).opacity,0);
});
test('drag changes layout continuously before selecting an item',()=>{
  const motion=new DepthMotion();motion.begin(200);motion.drag(158,400,3);
  assert.equal(motion.position,.25);
  assert.equal(depthSlot(.5).scale,(depthSlot(0).scale+depthSlot(1).scale)/2);
  motion.drag(74,400,3);assert.equal(motion.release(3),1);
  const before=motion.position;motion.update(1/30);
  assert.ok(motion.position>before&&motion.position<1);
  for(let i=0;i<30;i++)motion.update(1/30);
  assert.equal(motion.position,1);
});
test('add follows workshops, endpoints do not wrap or overscroll',()=>{
  assert.equal(visualIndex(1,3),0);assert.equal(visualIndex(0,3),3);
  for(let i=0;i<=3;i++)assert.equal(dataIndex(visualIndex(i,3),3),i);
  const motion=new DepthMotion();motion.begin(0);motion.drag(1000,400,3);
  assert.equal(motion.position,0);motion.drag(-1000,400,3);assert.equal(motion.position,3);
  assert.equal(dataIndex(0,0),0);
});
