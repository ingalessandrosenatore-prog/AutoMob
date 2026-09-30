/** Runtime contract shared by the preview and a future Flutter WebView bridge. */
export class MascotController {
  constructor({ root, clips, mixer, engine, manifest, onChange = () => {} }) {
    Object.assign(this, { root, clips, mixer, engine, manifest, onChange });
    this.state = { ...manifest.default, gesture: 'idle', paused: false };
    this.materials = new Map();
    root.traverse(node => {
      for (const mat of [].concat(node.material ?? [])) {
        if (!this.materials.has(mat.name)) this.materials.set(mat.name, new Set());
        this.materials.get(mat.name).add(mat);
      }
    });
    this.finished = event => {
      if (event.action !== this.action || this.state.gesture === 'idle') return;
      const completed = this.state.gesture;
      this.play('idle');
      this.onChange({ ...this.state, completed });
    };
    mixer.addEventListener('finished', this.finished);
    this.configure(manifest.default);
  }

  configure({ pose = this.state.pose, prop = this.state.prop } = {}) {
    const configuration = this.manifest.poses[pose];
    if (!configuration || !configuration.props.includes(prop)) {
      throw new Error(`Combinazione non disponibile: ${pose}/${prop}`);
    }
    this.getClip(pose, prop, 'idle'); // Validate before changing visible state.
    for (const [name, spec] of Object.entries(this.manifest.poses)) {
      const actor = this.root.getObjectByName(spec.root);
      if (!actor) throw new Error(`Nodo mancante: ${spec.root}`);
      actor.visible = name === pose;
      for (const accessory of spec.props) {
        this.root.getObjectByName(`${name}_PROP_${accessory}`).visible = accessory === prop;
      }
    }
    Object.assign(this.state, { pose, prop });
    this.play('idle');
  }

  setPose(pose) { this.configure({ pose }); }
  setProp(prop) { this.configure({ prop }); }

  setColors({ base, accent }) {
    const updates = Object.entries({ base, accent }).filter(([, value]) => value !== undefined);
    for (const [key, value] of updates) {
      if (!/^#[0-9a-f]{6}$/i.test(value)) throw new Error(`Colore ${key} non valido`);
      if (!this.materials.has(this.manifest.materials[key])) throw new Error(`Materiale ${key} mancante`);
    }
    for (const [key, value] of updates) {
      for (const mat of this.materials.get(this.manifest.materials[key])) mat.color.set(value);
    }
  }

  getClip(pose, prop, gesture) {
    const name = `${pose}_${prop}_${gesture}`;
    const clip = this.clips.find(item => item.name === name);
    if (!clip) throw new Error(`Animazione non disponibile: ${name}`);
    return clip;
  }

  play(gesture = 'idle', { loop = gesture === 'idle' } = {}) {
    const clip = this.getClip(this.state.pose, this.state.prop, gesture);
    this.action?.stop();
    this.action = this.mixer.clipAction(clip).reset();
    this.action.setLoop(loop ? this.engine.LoopRepeat : this.engine.LoopOnce, loop ? Infinity : 1);
    this.action.clampWhenFinished = !loop;
    this.action.play();
    this.mixer.timeScale = 1;
    Object.assign(this.state, { gesture, paused: false });
    this.mixer.update(0);
    this.onChange({ ...this.state });
  }

  stop() { this.play('idle'); }
  pause() { this.mixer.timeScale = 0; this.state.paused = true; }
  resume() { this.mixer.timeScale = 1; this.state.paused = false; }
  seek(seconds) {
    if (!Number.isFinite(seconds)) throw new Error('Tempo non valido');
    this.pause();
    this.action.time = Math.max(0, Math.min(seconds, this.action.getClip().duration - .0001));
    this.mixer.update(0);
  }
  dispose() {
    this.mixer.removeEventListener('finished', this.finished);
    this.mixer.stopAllAction();
    this.mixer.uncacheRoot(this.root);
  }
}
