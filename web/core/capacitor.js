// The Capacitor bridge, defensively — the one place the web app talks to native.
//
// WHY THIS EXISTS (the trap): the native bridge injects only
// `window.Capacitor.PluginHeaders` (see @capacitor/android JSExport.java) plus
// `Capacitor.nativePromise`. It does **not** populate `Capacitor.Plugins` —
// that only happens inside @capacitor/core's `registerPlugin()`, which needs a
// bundler this no-build app doesn't have. So `window.Capacitor.Plugins.Foo` is
// ALWAYS undefined here and any code reaching for it silently no-ops on device.
//
// We therefore try the registered proxy first (in case a global @capacitor/core
// is ever vendored) and fall back to the raw `nativePromise` bridge call, which
// is exactly what core's own createPluginMethod does internally.
//
// In a plain desktop browser there is no bridge at all: `available()` is false
// and callers degrade honestly rather than throwing.

const cap = () => (typeof window === "undefined" ? null : window.Capacitor || null);

/// The native method list a plugin advertises, or null when it isn't there.
function nativeMethods(plugin) {
  return cap()?.PluginHeaders?.find?.((h) => h.name === plugin)?.methods || null;
}

/// True when `plugin` can actually be called on this device.
export function available(plugin) {
  return !!(cap()?.Plugins?.[plugin] || nativeMethods(plugin));
}

/// Call a native plugin method. Rejects when the bridge or method is missing —
/// callers should gate on `available()` (or catch) and degrade.
export function call(plugin, method, options = {}) {
  const c = cap();
  const proxy = c?.Plugins?.[plugin];
  if (proxy && typeof proxy[method] === "function") return proxy[method](options);
  if (nativeMethods(plugin)?.some((m) => m.name === method) && typeof c?.nativePromise === "function") {
    return c.nativePromise(plugin, method, options);
  }
  return Promise.reject(new Error(`${plugin}.${method}() is unavailable`));
}
