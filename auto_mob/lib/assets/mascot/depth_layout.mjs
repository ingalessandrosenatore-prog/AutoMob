// Slots are presentation positions, not workshop IDs. The add item is last.
const slots = [
  {x: -.58, scale: .48, z: -3, opacity: 0},
  {x: -.29, scale: .72, z: -1.4, opacity: .75},
  {x: -.08, scale: 1, z: 0, opacity: 1},
  {x: .23, scale: .74, z: -1.5, opacity: .85},
  {x: .40, scale: .55, z: -3, opacity: .62},
  {x: .62, scale: .40, z: -4.5, opacity: 0},
];

export function depthSlot(distance) {
  const value = Math.max(0, Math.min(slots.length - 1, distance + 2));
  const index = Math.min(slots.length - 2, Math.floor(value));
  const t = value - index;
  return Object.fromEntries(Object.keys(slots[0]).map(key =>
    [key, slots[index][key] + (slots[index + 1][key] - slots[index][key]) * t]));
}

export const visualIndex = (index, count) => index === 0 ? count : index - 1;
export const dataIndex = (position, count) => position === count ? 0 : position + 1;

export class DepthMotion {
  constructor() { this.position = 0; this.target = 0; this.dragging = false; }
  jump(value) { this.position = this.target = value; }
  begin(x) { this.dragging = true; this.originX = x; this.origin = this.position; }
  drag(x, width, max) {
    this.position = Math.max(0, Math.min(max, this.origin + (this.originX - x) / (width * .42)));
  }
  release(max) {
    this.dragging = false;
    this.target = Math.max(0, Math.min(max, Math.round(this.position)));
    return this.target;
  }
  get moving() { return this.dragging || Math.abs(this.position - this.target) > .001; }
  update(dt) {
    if (!this.dragging) {
      this.position += (this.target - this.position) * (1 - Math.exp(-15 * dt));
      if (Math.abs(this.position - this.target) < .001) this.position = this.target;
    }
  }
}
