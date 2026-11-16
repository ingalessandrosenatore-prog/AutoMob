import { Raycaster, Sphere, Vector2, Vector3 } from "three";

export function buildPickables(model, components) {
  const meshOwners = new Map();
  const anchors = [];
  for (const part of components) {
    if (!part.selectable) continue;
    for (const name of part.meshNames) {
      const mesh = model.getObjectByName(name);
      if (!mesh?.isMesh) throw new Error(`Mesh mancante: ${name}`);
      if (!meshOwners.has(mesh)) meshOwners.set(mesh, []);
      meshOwners.get(mesh).push(part);
    }
    const anchor = model.getObjectByName(part.anchor);
    if (!anchor) throw new Error(`Anchor mancante: ${part.anchor}`);
    anchors.push({ part, anchor });
  }
  return { meshOwners, anchors };
}

export class PartPicker {
  constructor(model, components, camera) {
    const { meshOwners, anchors } = buildPickables(model, components);
    this.meshOwners = meshOwners;
    this.anchors = anchors;
    this.camera = camera;
    this.raycaster = new Raycaster();
    this.sphere = new Sphere();
    this.position = new Vector3();
    this.intersection = new Vector3();
  }

  pick(x, y, assembly) {
    const inScope = (part) => !assembly || part.assembly === assembly;
    const assemblyFirst = (part) => !assembly && part.assembly?.startsWith("wheel_")
      && part.id === part.assembly;
    const ordered = (parts) => parts.filter(inScope).sort((a, b) => {
      if (assemblyFirst(a)) return -1;
      if (assemblyFirst(b)) return 1;
      return a.pickRadiusMeters - b.pickRadiusMeters;
    });
    this.raycaster.setFromCamera(new Vector2(x, y), this.camera);

    // In a wheel close-up, the transparent tire and rim must let taps reach
    // brakes and suspension. The two outer parts remain selectable themselves.
    function outerWheel(part) {
      return /^(?:wheel|tire|rim)_/.test(part.id);
    }
    const hits = this.raycaster.intersectObjects([...this.meshOwners.keys()], false);
    let outerHit;
    for (const hit of hits) {
      const candidates = ordered(this.meshOwners.get(hit.object));
      const part = candidates.find((item) => !assembly || item.id !== assembly);
      if (!part) continue;
      if (assembly?.startsWith("wheel_") && outerWheel(part)) {
        outerHit ??= part;
        continue;
      }
      return part;
    }

    let closest;
    let best = Infinity;
    for (const { part, anchor } of this.anchors) {
      if (!inScope(part) || part.id === assembly) continue;
      anchor.getWorldPosition(this.position);
      this.sphere.set(this.position, part.pickRadiusMeters);
      const ray = this.raycaster.ray;
      if (!ray.intersectSphere(this.sphere, this.intersection)) continue;
      const miss = ray.distanceToPoint(this.position) / part.pickRadiusMeters;
      if (miss < best) {
        best = miss;
        closest = part;
      }
    }
    return closest ?? outerHit;
  }
}
