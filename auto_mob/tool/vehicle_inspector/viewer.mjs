import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { PartPicker } from "./selection.mjs";

const stage = document.querySelector("#stage");
const status = document.querySelector("#status");
const presetInput = document.querySelector("#preset");
const partInput = document.querySelector("#part");
const reset = document.querySelector("#reset");
const caption = document.querySelector("#caption");
const code = document.querySelector("#component-id");

async function start() {
  const response = await fetch("./components.json");
  if (!response.ok) throw new Error(`Metadati non disponibili (HTTP ${response.status})`);
  const manifest = await response.json();
  const loader = new GLTFLoader();
  const gltf = await loader.loadAsync(manifest.model);
  const vehicle = gltf.scene.getObjectByName(manifest.root);
  if (!vehicle) throw new Error("Gerarchia del veicolo mancante");

  const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 1.75));
  renderer.setClearColor(0x000000, 0);
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.AgXToneMapping;
  stage.prepend(renderer.domElement);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(35, 1, 0.025, 80);
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.minDistance = .26;
  controls.maxDistance = 16;
  scene.add(vehicle, new THREE.HemisphereLight(0xeaf4ff, 0x8c99ab, 2.1));
  for (const [color, intensity, position] of [
    [0xffffff, 2.1, [5, 7, -4]], [0xe7f1ff, 1.3, [-4, 3, 3]],
  ]) {
    const light = new THREE.DirectionalLight(color, intensity);
    light.position.fromArray(position);
    scene.add(light);
  }
  scene.updateMatrixWorld(true);

  const picker = new PartPicker(vehicle, manifest.components, camera);
  const parts = new Map(manifest.components.map((part) => [part.id, part]));
  const surfaces = [];
  const shell = vehicle.getObjectByName("body_shell");
  const exterior = new Set();
  shell.traverse((node) => exterior.add(node));
  vehicle.traverse((node) => {
    if (node.isMesh) {
      surfaces.push({ mesh: node, original: node.material, exterior: exterior.has(node) });
    }
  });
  const definitions = gltf.parser.json.materials;
  const selectedIndex = definitions.findIndex((material) => material.name === manifest.materials.selected);
  if (selectedIndex < 0) throw new Error("Materiale di selezione mancante");
  const selectedMaterial = (await gltf.parser.getDependency("material", selectedIndex)).clone();
  selectedMaterial.toneMapped = false;
  selectedMaterial.emissive.set(manifest.materials.selectedColor).multiplyScalar(.72);

  const mutedAccent = surfaces.find(({ original }) =>
    original.name === manifest.materials.interactive).original.clone();
  mutedAccent.color.set("#a1adbb");
  const faded = new Map();
  function fadedMaterial(material, factor) {
    const key = `${material.uuid}/${factor}`;
    if (!faded.has(key)) {
      const copy = material.clone();
      copy.opacity *= factor;
      copy.transparent = true;
      copy.depthWrite = false;
      faded.set(key, copy);
    }
    return faded.get(key);
  }

  function styleParts(part, assembly) {
    const chosen = new Set(part?.meshNames ?? []);
    const corner = parts.get(assembly);
    const outer = new Set(corner?.meshNames ?? []);
    for (const { mesh, original, exterior: isExterior } of surfaces) {
      mesh.renderOrder = isExterior ? 2 : 0;
      if (chosen.has(mesh.name) && part.id !== assembly) {
        mesh.material = selectedMaterial;
        continue;
      }
      const factor = assembly && isExterior ? .25 : outer.has(mesh.name) ? .19 : 1;
      const base = part && original.name === manifest.materials.interactive ? mutedAccent : original;
      mesh.material = factor === 1 ? base : fadedMaterial(base, factor);
    }
  }

  let motion;
  let assembly;
  function moveCamera(presetKey, part, immediate = false) {
    const preset = manifest.cameraPresets[presetKey];
    const target = new THREE.Vector3().fromArray(preset.target);
    const position = new THREE.Vector3().fromArray(preset.position);
    if (part && part.id !== part.assembly && part.id !== "engine_block") {
      const componentTarget = new THREE.Vector3().fromArray(part.target);
      position.add(componentTarget.clone().sub(target));
      target.copy(componentTarget);
    }
    // Fit the full vehicle at portrait aspect ratios while keeping preset FOV.
    if (presetKey === "vehicle_overview" && camera.aspect < 1.15) {
      position.sub(target).multiplyScalar(1.15 / camera.aspect).add(target);
    }
    motion = {
      start: performance.now(), duration: immediate || matchMedia("(prefers-reduced-motion: reduce)").matches ? 0 : 640,
      from: camera.position.clone(), to: position, targetFrom: controls.target.clone(),
      targetTo: target, fovFrom: camera.fov, fovTo: preset.verticalFovDeg,
    };
  }

  function populateParts(selectedId = "") {
    const options = [new Option(assembly ? "Componenti del gruppo" : "Tutti i componenti", "")];
    for (const part of parts.values()) {
      if (!assembly || part.assembly === assembly) options.push(new Option(part.label, part.id));
    }
    partInput.replaceChildren(...options);
    partInput.value = selectedId;
  }

  function show(presetKey, part, immediate = false) {
    const corner = /^(front|rear)_(left|right)_wheel/.exec(presetKey);
    assembly = part?.assembly || (corner ? `wheel_${corner[1][0].toUpperCase()}${corner[2][0].toUpperCase()}` : undefined);
    if (!assembly && /^(engine|timing|oil_filter|gearbox)/.test(presetKey)) assembly = "engine";
    populateParts(part?.id);
    presetInput.value = presetKey;
    caption.textContent = part?.label ?? manifest.cameraPresets[presetKey].label;
    code.textContent = part?.id ?? "";
    styleParts(part, assembly);
    moveCamera(presetKey, part, immediate);
    stage.dispatchEvent(new CustomEvent("automob:selection", { detail: part?.id ?? null }));
  }

  let tap;
  const canvas = renderer.domElement;
  canvas.addEventListener("pointerdown", (event) => {
    tap = event.isPrimary && event.button === 0 ? { x: event.clientX, y: event.clientY } : undefined;
  });
  canvas.addEventListener("pointermove", (event) => {
    if (tap && Math.hypot(event.clientX-tap.x, event.clientY-tap.y) > 7) tap = undefined;
  });
  canvas.addEventListener("pointercancel", () => { tap = undefined; });
  canvas.addEventListener("pointerup", (event) => {
    if (!tap || !event.isPrimary) return;
    tap = undefined;
    const rect = canvas.getBoundingClientRect();
    const part = picker.pick((event.clientX-rect.left)/rect.width*2-1,
      1-(event.clientY-rect.top)/rect.height*2, assembly);
    if (part) show(part.cameraPreset, part);
  });
  controls.addEventListener("start", () => { motion = undefined; });

  function resize() {
    const { clientWidth: w, clientHeight: h } = stage;
    camera.aspect = w / Math.max(h, 1);
    camera.updateProjectionMatrix();
    renderer.setSize(w, h, false);
  }
  new ResizeObserver(resize).observe(stage);
  resize();
  for (const [key, preset] of Object.entries(manifest.cameraPresets)) {
    presetInput.add(new Option(preset.label, key));
  }
  presetInput.addEventListener("change", () => show(presetInput.value));
  partInput.addEventListener("change", () => {
    const part = parts.get(partInput.value);
    show(part?.cameraPreset ?? presetInput.value, part);
  });
  reset.addEventListener("click", () => show("vehicle_overview"));
  show("vehicle_overview", undefined, true);
  presetInput.disabled = partInput.disabled = reset.disabled = false;
  status.hidden = true;

  renderer.setAnimationLoop((now) => {
    if (motion) {
      const t = motion.duration ? THREE.MathUtils.clamp((now-motion.start)/motion.duration, 0, 1) : 1;
      const eased = t*t*(3-2*t);
      camera.position.lerpVectors(motion.from, motion.to, eased);
      controls.target.lerpVectors(motion.targetFrom, motion.targetTo, eased);
      camera.fov = THREE.MathUtils.lerp(motion.fovFrom, motion.fovTo, eased);
      camera.updateProjectionMatrix();
      if (t >= 1) motion = undefined;
    }
    controls.update();
    renderer.render(scene, camera);
  });
}

function showError(error) {
  status.textContent = `Impossibile aprire il modello. ${error.message}`;
  console.error(error);
}

start().catch(showError);
