/// Flag MANUALE (per ora) che decide se attivare gli effetti GPU pesanti.
///
/// - `true`  → device top di gamma: vero liquid glass + blur reali.
/// - `false` → device medio/basso: fallback statici leggeri (container + gradienti).
///
/// Si passa a mano a [SmartGlass.liquid] e [SmartEdge.blur] nei punti d'uso.
///
/// TODO: in futuro derivarlo automaticamente dalla fascia del device
/// (RAM disponibile, refresh rate, GPU, ecc.) invece di una costante.
const bool kHeavyEffects = false;
