/* @ds-bundle: {"format":4,"namespace":"FlowtierDesignSystem_6b3d0d","components":[{"name":"FlowerMark","sourcePath":"components/brand/FlowerMark.jsx"},{"name":"FlowtierLogo","sourcePath":"components/brand/FlowtierLogo.jsx"},{"name":"PetalRain","sourcePath":"components/brand/PetalRain.jsx"},{"name":"Toast","sourcePath":"components/brand/Toast.jsx"},{"name":"Wordmark","sourcePath":"components/brand/Wordmark.jsx"},{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"Chip","sourcePath":"components/core/Chip.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"ListRow","sourcePath":"components/core/ListRow.jsx"},{"name":"SegmentedTabs","sourcePath":"components/core/SegmentedTabs.jsx"},{"name":"Switch","sourcePath":"components/core/Switch.jsx"},{"name":"CycleRing","sourcePath":"components/tracking/CycleRing.jsx"},{"name":"DayCell","sourcePath":"components/tracking/DayCell.jsx"},{"name":"FLOW_LEVELS","sourcePath":"components/tracking/FlowScale.jsx"},{"name":"FlowScale","sourcePath":"components/tracking/FlowScale.jsx"},{"name":"IntensityBar","sourcePath":"components/tracking/IntensityBar.jsx"},{"name":"PhaseBadge","sourcePath":"components/tracking/PhaseBadge.jsx"},{"name":"StatTile","sourcePath":"components/tracking/StatTile.jsx"},{"name":"SYMPTOMS","sourcePath":"components/tracking/SymptomChip.jsx"},{"name":"SymptomChip","sourcePath":"components/tracking/SymptomChip.jsx"}],"sourceHashes":{"components/brand/FlowerMark.jsx":"fed9f3ed9492","components/brand/FlowtierLogo.jsx":"2c96b10f758c","components/brand/PetalRain.jsx":"cc83a250360e","components/brand/Toast.jsx":"108839e90b1c","components/brand/Wordmark.jsx":"c1a9be7426dd","components/core/Badge.jsx":"ec3f93f38ccd","components/core/Button.jsx":"622e0109ea3d","components/core/Card.jsx":"8ffac365f353","components/core/Chip.jsx":"f4a5aec68e93","components/core/IconButton.jsx":"a2d4354837ce","components/core/ListRow.jsx":"339e7f3f14f3","components/core/SegmentedTabs.jsx":"220c966b4e3c","components/core/Switch.jsx":"0f0ee751a0f1","components/tracking/CycleRing.jsx":"3d9930726f64","components/tracking/DayCell.jsx":"52d89534aee4","components/tracking/FlowScale.jsx":"dbda872c71a2","components/tracking/IntensityBar.jsx":"ec5ec11c455b","components/tracking/PhaseBadge.jsx":"770ef6e4a012","components/tracking/StatTile.jsx":"75b681f7e6a7","components/tracking/SymptomChip.jsx":"68604cce2a45"},"inlinedExternals":[],"unexposedExports":[{"name":"phaseForDay","sourcePath":"components/tracking/CycleRing.jsx"}]} */

(() => {

const __ds_ns = (window.FlowtierDesignSystem_6b3d0d = window.FlowtierDesignSystem_6b3d0d || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/brand/FlowerMark.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* Rose-petal ring geometry, recreated faithfully from the Bloom family's
   FlowerLogo (three concentric elliptical-petal rings + a gold center).
   Each petal is an ellipse pushed out along (angle - 90°) and rotated by angle. */
function petalRing({
  count,
  lengthScale,
  widthScale,
  offsetFraction
}) {
  const C = 50;
  const petalLength = 100 * lengthScale;
  const petalWidth = 100 * widthScale;
  const out = [];
  for (let i = 0; i < count; i++) {
    const angleDeg = i * (360 / count);
    const a = (angleDeg - 90) * Math.PI / 180;
    const cx = C + petalLength * offsetFraction * Math.cos(a);
    const cy = C + petalLength * offsetFraction * Math.sin(a);
    out.push(/*#__PURE__*/React.createElement("ellipse", {
      key: i,
      cx: cx,
      cy: cy,
      rx: petalWidth / 2,
      ry: petalLength / 2,
      transform: `rotate(${angleDeg} ${cx} ${cy})`
    }));
  }
  return out;
}
const RINGS = [{
  count: 8,
  lengthScale: 0.44,
  widthScale: 0.3,
  offsetFraction: 0.52,
  fill: "var(--primary)",
  opacity: 0.55,
  rot: 6
}, {
  count: 7,
  lengthScale: 0.34,
  widthScale: 0.24,
  offsetFraction: 0.5,
  fill: "var(--primary)",
  opacity: 1,
  rot: -9
}, {
  count: 6,
  lengthScale: 0.24,
  widthScale: 0.18,
  offsetFraction: 0.46,
  fill: "var(--primary-strong)",
  opacity: 1,
  rot: 15
}];

/**
 * FlowerMark — the Flowtier bloom, the brand's signature motif.
 * A procedural rose: three petal rings in the theme pinks around a gold center.
 */
function FlowerMark({
  size = 48,
  spin = false,
  breathe = false,
  title = "Flowtier",
  style,
  className,
  ...rest
}) {
  const anim = spin ? "flowtier-spin 14s linear infinite" : breathe ? "flowtier-breathe 4s var(--ease-in-out, ease-in-out) infinite" : undefined;
  return /*#__PURE__*/React.createElement("svg", _extends({
    viewBox: "0 0 100 100",
    width: size,
    height: size,
    role: "img",
    "aria-label": title,
    className: className,
    style: {
      display: "block",
      transformOrigin: "50% 50%",
      animation: anim,
      ...style
    }
  }, rest), RINGS.map((r, idx) => /*#__PURE__*/React.createElement("g", {
    key: idx,
    transform: `rotate(${r.rot} 50 50)`,
    fill: r.fill,
    opacity: r.opacity
  }, petalRing(r))), /*#__PURE__*/React.createElement("circle", {
    cx: "50",
    cy: "50",
    r: "11",
    fill: "var(--flower-center)"
  }));
}
Object.assign(__ds_scope, { FlowerMark });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/FlowerMark.jsx", error: String((e && e.message) || e) }); }

// components/brand/FlowtierLogo.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * FlowtierLogo — the Flowtier brand mark: a smiling pink alarm clock (time +
 * cycles, made friendly). Theme-tinted via tokens, so it re-colors with the
 * active preset. Pair with the Wordmark, or use solo as an app icon / splash.
 */
function FlowtierLogo({
  size = 96,
  title = "Flowtier",
  className = "",
  style,
  ...rest
}) {
  const uid = React.useMemo(() => "ftlogo" + Math.random().toString(36).slice(2, 8), []);
  const cx = 50,
    cy = 55;
  const ticks = [];
  for (let i = 0; i < 12; i++) {
    const a = i * 30 * Math.PI / 180;
    const r1 = 27.5,
      r2 = i % 3 === 0 ? 23 : 25.2;
    ticks.push({
      x1: cx + r1 * Math.sin(a),
      y1: cy - r1 * Math.cos(a),
      x2: cx + r2 * Math.sin(a),
      y2: cy - r2 * Math.cos(a),
      major: i % 3 === 0
    });
  }
  const eyes = [[cx - 10.5, cy - 2], [cx + 10.5, cy - 2]];
  return /*#__PURE__*/React.createElement("svg", _extends({
    viewBox: "0 0 100 100",
    width: size,
    height: size,
    role: "img",
    "aria-label": title,
    className: className,
    style: {
      display: "block",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("defs", null, /*#__PURE__*/React.createElement("linearGradient", {
    id: uid,
    x1: "0",
    y1: "0",
    x2: "0",
    y2: "1"
  }, /*#__PURE__*/React.createElement("stop", {
    offset: "0",
    stopColor: "var(--primary)"
  }), /*#__PURE__*/React.createElement("stop", {
    offset: "1",
    stopColor: "var(--primary-strong)"
  }))), /*#__PURE__*/React.createElement("ellipse", {
    cx: "30",
    cy: "22",
    rx: "12",
    ry: "9.5",
    fill: "var(--primary-strong)",
    transform: "rotate(-26 30 22)"
  }), /*#__PURE__*/React.createElement("ellipse", {
    cx: "70",
    cy: "22",
    rx: "12",
    ry: "9.5",
    fill: "var(--primary-strong)",
    transform: "rotate(26 70 22)"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "47",
    y: "9",
    width: "6",
    height: "10",
    rx: "3",
    fill: "var(--primary-strong)"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "28",
    y: "85",
    width: "14",
    height: "9",
    rx: "4.5",
    fill: "var(--primary-strong)",
    transform: "rotate(26 35 90)"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "58",
    y: "85",
    width: "14",
    height: "9",
    rx: "4.5",
    fill: "var(--primary-strong)",
    transform: "rotate(-26 65 90)"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: cx,
    cy: cy,
    r: "38",
    fill: `url(#${uid})`
  }), /*#__PURE__*/React.createElement("circle", {
    cx: cx,
    cy: cy,
    r: "38",
    fill: "none",
    stroke: "var(--deep)",
    strokeOpacity: "0.15",
    strokeWidth: "1.5"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: cx,
    cy: cy,
    r: "30.5",
    fill: "#fff"
  }), ticks.map((t, i) => /*#__PURE__*/React.createElement("line", {
    key: i,
    x1: t.x1,
    y1: t.y1,
    x2: t.x2,
    y2: t.y2,
    stroke: "var(--primary)",
    strokeOpacity: "0.7",
    strokeWidth: t.major ? 2.6 : 1.8,
    strokeLinecap: "round"
  })), /*#__PURE__*/React.createElement("ellipse", {
    cx: cx - 13.5,
    cy: cy + 7,
    rx: "4.6",
    ry: "3",
    fill: "var(--primary)",
    opacity: "0.55"
  }), /*#__PURE__*/React.createElement("ellipse", {
    cx: cx + 13.5,
    cy: cy + 7,
    rx: "4.6",
    ry: "3",
    fill: "var(--primary)",
    opacity: "0.55"
  }), eyes.map(([x, y], i) => /*#__PURE__*/React.createElement("g", {
    key: i
  }, /*#__PURE__*/React.createElement("circle", {
    cx: x,
    cy: y,
    r: "3",
    fill: "var(--deep)"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: x + 1,
    cy: y - 1,
    r: "0.9",
    fill: "#fff"
  }))), /*#__PURE__*/React.createElement("path", {
    d: `M ${cx - 8.5} ${cy + 2.5} Q ${cx} ${cy + 13} ${cx + 8.5} ${cy + 2.5}`,
    fill: "none",
    stroke: "var(--deep)",
    strokeWidth: "2.8",
    strokeLinecap: "round"
  }));
}
Object.assign(__ds_scope, { FlowtierLogo });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/FlowtierLogo.jsx", error: String((e && e.message) || e) }); }

// components/brand/PetalRain.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-petalrain-css", `.ft-petal{position:absolute;top:-8%;border-radius:100% 0 100% 0;will-change:top,transform;animation-name:ft-petal-fall;animation-timing-function:linear;animation-iteration-count:infinite}
@keyframes ft-petal-fall{0%{top:-10%;opacity:0;transform:translateX(0) rotate(0)}12%{opacity:var(--_o,.8)}88%{opacity:var(--_o,.6)}100%{top:110%;opacity:0;transform:translateX(var(--_drift)) rotate(var(--_spin))}}
@media (prefers-reduced-motion: reduce){.ft-petal{animation:none;display:none}}`);
const rnd = (min, max) => min + Math.random() * (max - min);

/**
 * PetalRain — the signature "magical" layer: soft rose petals drifting down,
 * from the Bloom family's petal curtain. Absolutely fills its positioned parent,
 * ignores pointer events, and disappears entirely under reduced-motion.
 */
function PetalRain({
  count = 14,
  zIndex = 0,
  className = "",
  style,
  ...rest
}) {
  const petals = React.useMemo(() => Array.from({
    length: count
  }).map(() => ({
    left: rnd(0, 100),
    size: rnd(8, 17),
    delay: -rnd(0, 14),
    dur: rnd(7, 15),
    drift: rnd(-45, 45),
    spin: rnd(160, 520),
    op: rnd(0.45, 0.9),
    strong: Math.random() < 0.5
  })), [count]);
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["ft-petalrain", className].filter(Boolean).join(" "),
    "aria-hidden": "true",
    style: {
      position: "absolute",
      inset: 0,
      overflow: "hidden",
      pointerEvents: "none",
      zIndex,
      ...style
    }
  }, rest), petals.map((p, i) => /*#__PURE__*/React.createElement("span", {
    key: i,
    className: "ft-petal",
    style: {
      left: p.left + "%",
      width: p.size,
      height: p.size * 1.15,
      background: `linear-gradient(135deg, ${p.strong ? "var(--primary)" : "var(--primary-strong)"}, var(--deep))`,
      "--_drift": p.drift + "px",
      "--_spin": p.spin + "deg",
      "--_o": p.op,
      animationDelay: p.delay + "s",
      animationDuration: p.dur + "s"
    }
  })));
}
Object.assign(__ds_scope, { PetalRain });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/PetalRain.jsx", error: String((e && e.message) || e) }); }

// components/brand/Toast.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Toast — the gentle flower-headed notice from the Bloom family. A white card
 * with the bloom mark, a deep title, and a muted message. Used for saves,
 * reminders, and little affectionate confirmations.
 */
function Toast({
  title,
  message,
  icon,
  style,
  className,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: className,
    role: "status",
    style: {
      display: "flex",
      alignItems: "center",
      gap: "12px",
      padding: "14px 16px",
      background: "var(--surface)",
      borderRadius: "var(--radius)",
      boxShadow: "0 10px 24px -8px var(--shadow)",
      maxWidth: "380px",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: "none",
      display: "grid",
      placeItems: "center"
    }
  }, icon || /*#__PURE__*/React.createElement(__ds_scope.FlowerMark, {
    size: 34,
    "aria-hidden": "true"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: "2px",
      minWidth: 0
    }
  }, title && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-body)",
      fontWeight: "var(--weight-semibold)",
      fontSize: "var(--text-base)",
      color: "var(--deep)"
    }
  }, title), message && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-body)",
      fontSize: "var(--text-sm)",
      color: "var(--muted)",
      lineHeight: "var(--leading-snug)",
      overflow: "hidden",
      textOverflow: "ellipsis"
    }
  }, message)));
}
Object.assign(__ds_scope, { Toast });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/Toast.jsx", error: String((e && e.message) || e) }); }

// components/brand/Wordmark.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Wordmark — the Flowtier name set in the brand type, with the bloom mark.
 * `display` uses Playfair Display (the everyday lockup); `script` uses Great
 * Vibes (splash screens, affectionate moments). There is no logo image asset —
 * the wordmark IS the logo.
 */
function Wordmark({
  variant = "display",
  size = 28,
  showMark = true,
  text = "Flowtier",
  style,
  className,
  ...rest
}) {
  const isScript = variant === "script";
  return /*#__PURE__*/React.createElement("span", _extends({
    className: className,
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: isScript ? "0.4em" : "0.55em",
      color: "var(--deep)",
      lineHeight: 1,
      ...style
    }
  }, rest), showMark && /*#__PURE__*/React.createElement(__ds_scope.FlowerMark, {
    size: isScript ? size * 1.15 : size * 1.0,
    "aria-hidden": "true"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: isScript ? "var(--font-script)" : "var(--font-display)",
      fontWeight: isScript ? 400 : 600,
      fontSize: size,
      letterSpacing: isScript ? "0.01em" : "var(--tracking-tight)"
    }
  }, text));
}
Object.assign(__ds_scope, { Wordmark });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/Wordmark.jsx", error: String((e && e.message) || e) }); }

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-badge-css", `.ft-badge{display:inline-flex;align-items:center;gap:.45em;font-family:var(--font-body);font-weight:var(--weight-semibold);font-size:var(--text-xs);height:24px;padding:0 10px;border-radius:var(--radius-pill);letter-spacing:var(--tracking-wide);white-space:nowrap;line-height:1}
.ft-badge__dot{width:7px;height:7px;border-radius:50%;background:currentColor;flex:none}
.ft-badge--neutral{background:var(--surface-soft);color:var(--muted)}
.ft-badge--menstrual{background:var(--phase-menstrual-soft);color:var(--phase-menstrual)}
.ft-badge--follicular{background:var(--phase-follicular-soft);color:#C4568A}
.ft-badge--fertile{background:var(--phase-fertile-soft);color:#B67A1E}
.ft-badge--ovulation{background:var(--phase-ovulation-soft);color:#B0700F}
.ft-badge--luteal{background:var(--phase-luteal-soft);color:#9B569A}
.ft-badge--good{background:color-mix(in srgb,var(--good) 14%,#fff);color:var(--good)}`);

/**
 * Badge — a small soft-tinted status label with an optional leading dot.
 * Tones map to cycle phases plus neutral & good.
 */
function Badge({
  tone = "neutral",
  dot = false,
  className = "",
  children,
  ...rest
}) {
  const cls = ["ft-badge", `ft-badge--${tone}`, className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("span", _extends({
    className: cls
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    className: "ft-badge__dot"
  }), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-btn-css", `.ft-btn{display:inline-flex;align-items:center;justify-content:center;gap:.5em;font-family:var(--font-body);font-weight:var(--weight-semibold);border:none;border-radius:var(--radius-pill);cursor:pointer;white-space:nowrap;user-select:none;line-height:1;text-decoration:none;transition:transform var(--dur-fast) var(--ease-out),box-shadow var(--dur-base) var(--ease-out),background var(--dur-base) var(--ease-out),filter var(--dur-base) var(--ease-out)}
.ft-btn--sm{height:38px;padding:0 16px;font-size:var(--text-sm)}
.ft-btn--md{height:46px;padding:0 22px;font-size:var(--text-base)}
.ft-btn--lg{height:54px;padding:0 30px;font-size:var(--text-md)}
.ft-btn--block{width:100%}
.ft-btn--primary{background:var(--primary-strong);color:#fff;box-shadow:0 8px 20px -10px var(--shadow)}
.ft-btn--primary:hover{filter:brightness(1.05);box-shadow:0 12px 26px -10px var(--shadow)}
.ft-btn--deep{background:var(--deep);color:#fff;box-shadow:0 8px 20px -10px var(--shadow)}
.ft-btn--deep:hover{filter:brightness(1.08)}
.ft-btn--soft{background:var(--surface-soft);color:var(--deep)}
.ft-btn--soft:hover{background:color-mix(in srgb,var(--surface-soft) 76%,var(--primary) 24%)}
.ft-btn--ghost{background:transparent;color:var(--primary-strong)}
.ft-btn--ghost:hover{background:var(--surface-soft)}
.ft-btn:active{transform:scale(.96)}
.ft-btn:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-btn:disabled,.ft-btn[aria-disabled="true"]{opacity:.45;pointer-events:none;box-shadow:none}
.ft-btn__ico{display:inline-flex;flex:none}`);

/**
 * Button — the primary action pill. Rounded to a full capsule, springy on
 * press, soft themed shadow. Variants cover the emphasis ladder.
 */
function Button({
  variant = "primary",
  size = "md",
  block = false,
  iconLeft,
  iconRight,
  className = "",
  children,
  ...rest
}) {
  const cls = ["ft-btn", `ft-btn--${variant}`, `ft-btn--${size}`, block ? "ft-btn--block" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("button", _extends({
    className: cls
  }, rest), iconLeft && /*#__PURE__*/React.createElement("span", {
    className: "ft-btn__ico"
  }, iconLeft), children, iconRight && /*#__PURE__*/React.createElement("span", {
    className: "ft-btn__ico"
  }, iconRight));
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-card-css", `.ft-card{border-radius:var(--radius);padding:var(--gap-card);background:var(--surface);box-shadow:var(--shadow-card);transition:transform var(--dur-base) var(--ease-out),box-shadow var(--dur-base) var(--ease-out)}
.ft-card--soft{background:var(--surface-soft);box-shadow:none}
.ft-card--accent{background:var(--surface-2);box-shadow:none}
.ft-card--outline{background:var(--surface);box-shadow:none;border:1px solid var(--line)}
.ft-card--interactive{cursor:pointer}
.ft-card--interactive:hover{transform:translateY(-2px);box-shadow:var(--shadow-float)}
.ft-card--interactive:active{transform:translateY(0)}`);

/**
 * Card — the fundamental surface. White with a soft themed drop shadow and the
 * canonical 22px corner (from the Bloom Card). Soft/accent/outline variants for
 * quieter panels.
 */
function Card({
  variant = "plain",
  interactive = false,
  as = "div",
  padding,
  className = "",
  style,
  children,
  ...rest
}) {
  const Tag = as;
  const cls = ["ft-card", variant !== "plain" ? `ft-card--${variant}` : "", interactive ? "ft-card--interactive" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement(Tag, _extends({
    className: cls,
    style: padding != null ? {
      padding,
      ...style
    } : style
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/Chip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-chip-css", `.ft-chip{display:inline-flex;align-items:center;gap:.4em;font-family:var(--font-body);font-weight:var(--weight-semibold);border-radius:var(--radius-pill);border:1.5px solid transparent;cursor:pointer;user-select:none;background:var(--surface-soft);color:var(--muted);transition:transform var(--dur-fast) var(--ease-out),background var(--dur-base) var(--ease-out),color var(--dur-base) var(--ease-out),border-color var(--dur-base) var(--ease-out)}
.ft-chip--sm{height:32px;padding:0 12px;font-size:var(--text-xs)}
.ft-chip--md{height:40px;padding:0 16px;font-size:var(--text-sm)}
.ft-chip:hover{color:var(--deep);border-color:var(--line)}
.ft-chip[aria-pressed="true"]{background:var(--primary-strong);color:#fff;border-color:transparent}
.ft-chip[aria-pressed="true"]:hover{color:#fff;filter:brightness(1.04)}
.ft-chip:active{transform:scale(.95)}
.ft-chip:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-chip:disabled{opacity:.4;pointer-events:none}
.ft-chip__ico{display:inline-flex;flex:none}`);

/**
 * Chip — a selectable pill for multi-select vocabularies (symptoms, moods,
 * tags). Toggles to the strong-pink selected state. Controlled via `selected`.
 */
function Chip({
  selected = false,
  size = "md",
  icon,
  onClick,
  className = "",
  children,
  ...rest
}) {
  const cls = ["ft-chip", `ft-chip--${size}`, className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    className: cls,
    "aria-pressed": selected,
    onClick: onClick
  }, rest), icon && /*#__PURE__*/React.createElement("span", {
    className: "ft-chip__ico"
  }, icon), children);
}
Object.assign(__ds_scope, { Chip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Chip.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-iconbtn-css", `.ft-iconbtn{display:inline-flex;align-items:center;justify-content:center;border:none;border-radius:var(--radius-pill);cursor:pointer;flex:none;color:var(--deep);transition:transform var(--dur-fast) var(--ease-out),background var(--dur-base) var(--ease-out),filter var(--dur-base) var(--ease-out)}
.ft-iconbtn--sm{width:36px;height:36px}
.ft-iconbtn--md{width:44px;height:44px}
.ft-iconbtn--lg{width:52px;height:52px}
.ft-iconbtn--soft{background:var(--surface-soft);color:var(--deep)}
.ft-iconbtn--soft:hover{background:color-mix(in srgb,var(--surface-soft) 76%,var(--primary) 24%)}
.ft-iconbtn--ghost{background:transparent;color:var(--muted)}
.ft-iconbtn--ghost:hover{background:var(--surface-soft);color:var(--deep)}
.ft-iconbtn--primary{background:var(--primary-strong);color:#fff;box-shadow:0 8px 18px -10px var(--shadow)}
.ft-iconbtn--primary:hover{filter:brightness(1.06)}
.ft-iconbtn:active{transform:scale(.92)}
.ft-iconbtn:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-iconbtn:disabled{opacity:.4;pointer-events:none}`);

/**
 * IconButton — a round, icon-only tap target (min 44px). For toolbar actions,
 * calendar nav arrows, close buttons, and the like.
 */
function IconButton({
  variant = "soft",
  size = "md",
  label,
  className = "",
  children,
  ...rest
}) {
  const cls = ["ft-iconbtn", `ft-iconbtn--${variant}`, `ft-iconbtn--${size}`, className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("button", _extends({
    className: cls,
    "aria-label": label
  }, rest), children);
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/ListRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-listrow-css", `.ft-listrow{display:flex;align-items:center;gap:14px;width:100%;padding:12px 4px;background:transparent;border:none;text-align:left;font-family:var(--font-body);color:var(--text)}
.ft-listrow--interactive{cursor:pointer;border-radius:var(--radius-md);padding:12px;transition:background var(--dur-base) var(--ease-out)}
.ft-listrow--interactive:hover{background:var(--surface-2)}
.ft-listrow--interactive:active{background:var(--surface-soft)}
.ft-listrow__lead{width:40px;height:40px;border-radius:var(--radius-sm);background:var(--surface-soft);display:grid;place-items:center;color:var(--primary-strong);flex:none}
.ft-listrow__body{flex:1;min-width:0;display:flex;flex-direction:column;gap:2px}
.ft-listrow__title{font-size:var(--text-base);font-weight:var(--weight-semibold);color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ft-listrow__sub{font-size:var(--text-xs);color:var(--muted);overflow:hidden;text-overflow:ellipsis}
.ft-listrow__trail{flex:none;display:inline-flex;align-items:center;gap:8px;color:var(--muted);font-size:var(--text-sm);font-weight:var(--weight-medium)}`);

/**
 * ListRow — a settings / reminders row: soft rounded leading icon, title +
 * subtitle, and a trailing slot (Switch, chevron, value). Renders as a button
 * when `onClick` is given.
 */
function ListRow({
  icon,
  title,
  subtitle,
  trailing,
  onClick,
  className = "",
  ...rest
}) {
  const interactive = !!onClick;
  const Tag = interactive ? "button" : "div";
  const cls = ["ft-listrow", interactive ? "ft-listrow--interactive" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement(Tag, _extends({
    className: cls,
    onClick: onClick
  }, interactive ? {
    type: "button"
  } : {}, rest), icon && /*#__PURE__*/React.createElement("span", {
    className: "ft-listrow__lead"
  }, icon), /*#__PURE__*/React.createElement("span", {
    className: "ft-listrow__body"
  }, /*#__PURE__*/React.createElement("span", {
    className: "ft-listrow__title"
  }, title), subtitle && /*#__PURE__*/React.createElement("span", {
    className: "ft-listrow__sub"
  }, subtitle)), trailing && /*#__PURE__*/React.createElement("span", {
    className: "ft-listrow__trail"
  }, trailing));
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/core/SegmentedTabs.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-segtabs-css", `.ft-segtabs{display:inline-flex;gap:4px;padding:4px;background:var(--surface-soft);border-radius:var(--radius-pill)}
.ft-segtabs--block{display:flex;width:100%}
.ft-seg{flex:1;display:inline-flex;align-items:center;justify-content:center;gap:.4em;border:none;background:transparent;cursor:pointer;font-family:var(--font-body);font-weight:var(--weight-semibold);font-size:var(--text-sm);color:var(--muted);height:36px;padding:0 18px;border-radius:var(--radius-pill);white-space:nowrap;transition:color var(--dur-base) var(--ease-out),background var(--dur-base) var(--ease-out),box-shadow var(--dur-base) var(--ease-out)}
.ft-seg:hover{color:var(--deep)}
.ft-seg[aria-selected="true"]{background:var(--primary-strong);color:#fff;box-shadow:0 4px 12px -6px var(--shadow)}
.ft-seg:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-seg__ico{display:inline-flex;flex:none}`);

/**
 * SegmentedTabs — the capsule tab switcher from the Bloom KTabBar. A soft
 * track with a strong-pink active pill. Controlled via `value`/`onChange`.
 */
function SegmentedTabs({
  options = [],
  value,
  onChange,
  block = false,
  className = "",
  ...rest
}) {
  const cls = ["ft-segtabs", block ? "ft-segtabs--block" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("div", _extends({
    className: cls,
    role: "tablist"
  }, rest), options.map(opt => {
    const val = typeof opt === "string" ? opt : opt.value;
    const label = typeof opt === "string" ? opt : opt.label;
    const icon = typeof opt === "string" ? null : opt.icon;
    const selected = val === value;
    return /*#__PURE__*/React.createElement("button", {
      key: val,
      type: "button",
      role: "tab",
      "aria-selected": selected,
      className: "ft-seg",
      onClick: () => onChange && onChange(val)
    }, icon && /*#__PURE__*/React.createElement("span", {
      className: "ft-seg__ico"
    }, icon), label);
  }));
}
Object.assign(__ds_scope, { SegmentedTabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SegmentedTabs.jsx", error: String((e && e.message) || e) }); }

// components/core/Switch.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-switch-css", `.ft-switch{position:relative;display:inline-flex;align-items:center;width:52px;height:30px;border-radius:var(--radius-pill);background:var(--surface-soft);border:none;cursor:pointer;padding:0;flex:none;transition:background var(--dur-base) var(--ease-out)}
.ft-switch[aria-checked="true"]{background:var(--primary-strong)}
.ft-switch__knob{position:absolute;top:3px;left:3px;width:24px;height:24px;border-radius:50%;background:#fff;box-shadow:0 2px 6px rgba(66,21,39,.28);transition:transform var(--dur-base) var(--spring)}
.ft-switch[aria-checked="true"] .ft-switch__knob{transform:translateX(22px)}
.ft-switch:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-switch:disabled{opacity:.4;pointer-events:none}`);

/**
 * Switch — the settings/reminder toggle. Track fills strong-pink when on; the
 * knob springs across. Controlled via `checked`/`onChange`.
 */
function Switch({
  checked = false,
  onChange,
  label,
  className = "",
  disabled,
  ...rest
}) {
  const cls = ["ft-switch", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": checked,
    "aria-label": label,
    disabled: disabled,
    className: cls,
    onClick: () => onChange && onChange(!checked)
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "ft-switch__knob"
  }));
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Switch.jsx", error: String((e && e.message) || e) }); }

// components/tracking/CycleRing.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* Standard cycle model (shared with the source trackers): ovulation ~14 days
   before the next period; fertile window = the 5 days before ovulation through
   ovulation day. All derived from cycleLength + periodLength. */
function computeCycle(cycleLength, periodLength) {
  const ovDay = Math.min(Math.max(cycleLength - 14, periodLength + 1), cycleLength - 1);
  const fertileStart = Math.max(ovDay - 5, periodLength + 1);
  return {
    ovDay,
    fertileStart
  };
}
function phaseForDay(day, cycleLength, periodLength) {
  const {
    ovDay,
    fertileStart
  } = computeCycle(cycleLength, periodLength);
  if (day <= periodLength) return "menstrual";
  if (day < fertileStart) return "follicular";
  if (day < ovDay) return "fertile";
  if (day <= ovDay + 1) return "ovulation";
  return "luteal";
}
const PHASE_LABEL = {
  menstrual: "Menstrual",
  follicular: "Follicular",
  fertile: "Fertile window",
  ovulation: "Ovulation",
  luteal: "Luteal"
};
const PHASE_VAR = {
  menstrual: "var(--phase-menstrual)",
  follicular: "var(--phase-follicular)",
  fertile: "var(--phase-fertile)",
  ovulation: "var(--phase-ovulation)",
  luteal: "var(--phase-luteal)"
};
function polar(cx, cy, r, deg) {
  const a = (deg - 90) * Math.PI / 180;
  return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
}
function arc(cx, cy, r, startDeg, endDeg) {
  const [x1, y1] = polar(cx, cy, r, startDeg);
  const [x2, y2] = polar(cx, cy, r, endDeg);
  const large = endDeg - startDeg <= 180 ? 0 : 1;
  return `M ${x1} ${y1} A ${r} ${r} 0 ${large} 1 ${x2} ${y2}`;
}

/**
 * CycleRing — the hero cycle visualization. A soft donut walked day-by-day:
 * the bleed days, the fertile window, and ovulation are marked in their phase
 * colors, and a knob sits on today. Center shows the current day + phase, or
 * any custom `children` (e.g. a days-until-period countdown).
 */
function CycleRing({
  cycleDay = 1,
  cycleLength = 28,
  periodLength = 5,
  size = 260,
  spinnable = false,
  children,
  className = "",
  style,
  ...rest
}) {
  const V = 200;
  const cx = 100;
  const cy = 100;
  const r = 84;
  const w = 15;
  const {
    ovDay,
    fertileStart
  } = computeCycle(cycleLength, periodLength);
  const A = day => day / cycleLength * 360;
  const phase = phaseForDay(cycleDay, cycleLength, periodLength);
  const [kx, ky] = polar(cx, cy, r, A(cycleDay - 0.5));

  // Optional fidget-spinner: drag to spin the dial, release for inertial decay.
  const wrapRef = React.useRef(null);
  const [rot, setRot] = React.useState(0);
  const drag = React.useRef({
    active: false,
    lastAng: 0,
    lastT: 0,
    vel: 0,
    raf: 0
  });
  const reduce = typeof window !== "undefined" && window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  React.useEffect(() => () => cancelAnimationFrame(drag.current.raf), []);
  const angOf = e => {
    const b = wrapRef.current.getBoundingClientRect();
    return Math.atan2(e.clientY - (b.top + b.height / 2), e.clientX - (b.left + b.width / 2)) * 180 / Math.PI;
  };
  const onDown = e => {
    if (!spinnable || reduce) return;
    cancelAnimationFrame(drag.current.raf);
    drag.current.active = true;
    drag.current.lastAng = angOf(e);
    drag.current.lastT = performance.now();
    drag.current.vel = 0;
    if (e.currentTarget.setPointerCapture) e.currentTarget.setPointerCapture(e.pointerId);
  };
  const onMove = e => {
    if (!drag.current.active) return;
    const a = angOf(e);
    let d = a - drag.current.lastAng;
    if (d > 180) d -= 360;else if (d < -180) d += 360;
    const t = performance.now();
    drag.current.vel = d / Math.max(t - drag.current.lastT, 1) * 16;
    drag.current.lastAng = a;
    drag.current.lastT = t;
    setRot(v => v + d);
  };
  const onUp = () => {
    if (!drag.current.active) return;
    drag.current.active = false;
    const step = () => {
      drag.current.vel *= 0.96;
      setRot(v => v + drag.current.vel);
      if (Math.abs(drag.current.vel) > 0.05) drag.current.raf = requestAnimationFrame(step);
    };
    if (Math.abs(drag.current.vel) > 0.12) drag.current.raf = requestAnimationFrame(step);
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    ref: wrapRef,
    className: className,
    style: {
      position: "relative",
      width: size,
      height: size,
      touchAction: spinnable ? "none" : undefined,
      cursor: spinnable && !reduce ? "grab" : undefined,
      ...style
    },
    role: "img",
    "aria-label": `Cycle day ${cycleDay} of ${cycleLength}, ${PHASE_LABEL[phase]} phase`,
    onPointerDown: onDown,
    onPointerMove: onMove,
    onPointerUp: onUp,
    onPointerLeave: onUp
  }, rest), /*#__PURE__*/React.createElement("svg", {
    viewBox: `0 0 ${V} ${V}`,
    width: size,
    height: size,
    style: {
      display: "block",
      transform: `rotate(${rot}deg)`,
      transformOrigin: "50% 50%"
    }
  }, /*#__PURE__*/React.createElement("circle", {
    cx: cx,
    cy: cy,
    r: r,
    fill: "none",
    stroke: "var(--surface-soft)",
    strokeWidth: w
  }), /*#__PURE__*/React.createElement("path", {
    d: arc(cx, cy, r, A(0), A(periodLength)),
    fill: "none",
    stroke: PHASE_VAR.menstrual,
    strokeWidth: w,
    strokeLinecap: "round"
  }), /*#__PURE__*/React.createElement("path", {
    d: arc(cx, cy, r, A(fertileStart - 1), A(ovDay + 1)),
    fill: "none",
    stroke: PHASE_VAR.fertile,
    strokeWidth: w,
    strokeLinecap: "round"
  }), /*#__PURE__*/React.createElement("path", {
    d: arc(cx, cy, r, A(ovDay - 0.6), A(ovDay + 0.6)),
    fill: "none",
    stroke: PHASE_VAR.ovulation,
    strokeWidth: w,
    strokeLinecap: "round"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: kx,
    cy: ky,
    r: w / 2 + 4,
    fill: "var(--surface)",
    stroke: PHASE_VAR[phase],
    strokeWidth: 4
  }), /*#__PURE__*/React.createElement("circle", {
    cx: kx,
    cy: ky,
    r: 3,
    fill: PHASE_VAR[phase]
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      textAlign: "center",
      padding: "0 18%"
    }
  }, children || /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-body)",
      fontWeight: 600,
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-label)",
      textTransform: "uppercase",
      color: PHASE_VAR[phase]
    }
  }, PHASE_LABEL[phase]), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-display)",
      fontWeight: 600,
      fontSize: size * 0.26,
      lineHeight: 1,
      color: "var(--deep)",
      margin: "2px 0"
    }
  }, cycleDay), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-body)",
      fontSize: "var(--text-sm)",
      color: "var(--muted)"
    }
  }, "day of your cycle"))));
}
Object.assign(__ds_scope, { phaseForDay, CycleRing });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/tracking/CycleRing.jsx", error: String((e && e.message) || e) }); }

// components/tracking/DayCell.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const FLOW_COLOR = {
  spotting: "var(--flow-spotting)",
  light: "var(--flow-light)",
  medium: "var(--flow-medium)",
  heavy: "var(--flow-heavy)",
  none: "var(--flow-none)"
};

/**
 * DayCell — one calendar day. Composable states: period (logged bleed),
 * predicted (forecast period), fertile, ovulation; plus today, selected and
 * muted (outside month). An optional flow dot shows logged intensity.
 */
function DayCell({
  day,
  state = null,
  flow = null,
  today = false,
  selected = false,
  muted = false,
  size = 40,
  onClick,
  className = "",
  style,
  ...rest
}) {
  let bg = "transparent";
  let color = "var(--text)";
  let border = "1.5px solid transparent";
  let boxShadow = "none";
  if (state === "fertile") {
    bg = "var(--phase-fertile-soft)";
    color = "#8a5a12";
  }
  if (state === "ovulation") {
    bg = "var(--phase-fertile-soft)";
    border = "2px solid var(--phase-ovulation)";
    color = "#8a5a12";
  }
  if (state === "period") {
    bg = "var(--phase-menstrual-soft)";
    color = "var(--phase-menstrual)";
  }
  if (state === "predicted") {
    border = "1.5px dashed var(--phase-menstrual)";
    color = "var(--phase-menstrual)";
  }
  if (muted) color = "color-mix(in srgb, var(--muted) 42%, transparent)";
  if (today) boxShadow = "0 0 0 2px var(--surface), 0 0 0 4px var(--primary-strong)";
  if (selected) {
    bg = "var(--primary-strong)";
    color = "#fff";
    border = "1.5px solid transparent";
  }
  const dot = flow && !selected ? FLOW_COLOR[flow] : null;
  const Tag = onClick ? "button" : "div";
  return /*#__PURE__*/React.createElement(Tag, _extends({
    className: className,
    onClick: onClick
  }, onClick ? {
    type: "button"
  } : {}, {
    style: {
      position: "relative",
      width: size,
      height: size,
      borderRadius: "50%",
      border,
      background: bg,
      color,
      boxShadow,
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      fontFamily: "var(--font-body)",
      fontWeight: today || selected ? "var(--weight-bold)" : "var(--weight-medium)",
      fontSize: "var(--text-sm)",
      cursor: onClick ? "pointer" : "default",
      padding: 0,
      transition: "background var(--dur-base) var(--ease-out), transform var(--dur-fast) var(--ease-out)",
      ...style
    }
  }, rest), day, dot && /*#__PURE__*/React.createElement("span", {
    style: {
      position: "absolute",
      bottom: size * 0.14,
      width: 5,
      height: 5,
      borderRadius: "50%",
      background: dot
    }
  }));
}
Object.assign(__ds_scope, { DayCell });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/tracking/DayCell.jsx", error: String((e && e.message) || e) }); }

// components/tracking/FlowScale.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-flow-css", `.ft-flow{display:flex;gap:8px}
.ft-flow--block{width:100%}
.ft-flowcell{flex:1;display:flex;flex-direction:column;align-items:center;gap:6px;padding:12px 6px;border-radius:var(--radius-md);border:1.5px solid transparent;background:transparent;cursor:pointer;transition:background var(--dur-base) var(--ease-out),border-color var(--dur-base) var(--ease-out),transform var(--dur-fast) var(--ease-out)}
.ft-flowcell:hover{background:var(--surface-2)}
.ft-flowcell:active{transform:scale(.95)}
.ft-flowcell[aria-pressed="true"]{background:var(--surface-soft);border-color:var(--line)}
.ft-flowcell:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-flowcell__label{font-family:var(--font-body);font-size:var(--text-xs);font-weight:var(--weight-semibold);color:var(--muted)}
.ft-flowcell[aria-pressed="true"] .ft-flowcell__label{color:var(--deep)}
.ft-flowcell__drop{opacity:.45;transition:opacity var(--dur-base) var(--ease-out)}
.ft-flowcell[aria-pressed="true"] .ft-flowcell__drop{opacity:1}`);
const FLOW_LEVELS = [{
  key: "spotting",
  label: "Spotting",
  color: "var(--flow-spotting)",
  drop: 20
}, {
  key: "light",
  label: "Light",
  color: "var(--flow-light)",
  drop: 24
}, {
  key: "medium",
  label: "Medium",
  color: "var(--flow-medium)",
  drop: 28
}, {
  key: "heavy",
  label: "Heavy",
  color: "var(--flow-heavy)",
  drop: 32
}];
function Droplet({
  color,
  size
}) {
  return /*#__PURE__*/React.createElement("svg", {
    className: "ft-flowcell__drop",
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M12 2.4c0 0-6.6 7.5-6.6 12.3a6.6 6.6 0 0 0 13.2 0C18.6 9.9 12 2.4 12 2.4Z",
    fill: color
  }));
}

/**
 * FlowScale — the period flow selector: four droplets that deepen and grow from
 * spotting to heavy. Single-select; controlled via `value`/`onChange`.
 */
function FlowScale({
  value = null,
  onChange,
  block = true,
  className = "",
  ...rest
}) {
  const cls = ["ft-flow", block ? "ft-flow--block" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("div", _extends({
    className: cls,
    role: "group",
    "aria-label": "Flow intensity"
  }, rest), FLOW_LEVELS.map(lvl => /*#__PURE__*/React.createElement("button", {
    key: lvl.key,
    type: "button",
    className: "ft-flowcell",
    "aria-pressed": value === lvl.key,
    onClick: () => onChange && onChange(value === lvl.key ? null : lvl.key)
  }, /*#__PURE__*/React.createElement(Droplet, {
    color: lvl.color,
    size: lvl.drop
  }), /*#__PURE__*/React.createElement("span", {
    className: "ft-flowcell__label"
  }, lvl.label))));
}
Object.assign(__ds_scope, { FLOW_LEVELS, FlowScale });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/tracking/FlowScale.jsx", error: String((e && e.message) || e) }); }

// components/tracking/IntensityBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
injectOnce("ft-ibar-css", `.ft-ibar{display:flex;flex-direction:column;gap:6px;font-family:var(--font-body)}
.ft-ibar__head{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.ft-ibar__label{font-size:var(--text-sm);font-weight:var(--weight-semibold);color:var(--text)}
.ft-ibar__meta{font-size:var(--text-xs);color:var(--muted);flex:none}
.ft-ibar__track{height:9px;border-radius:var(--radius-pill);background:var(--surface-soft);overflow:hidden}
.ft-ibar__fill{height:100%;border-radius:var(--radius-pill);transition:width var(--dur-slow) var(--ease-signature)}`);

/**
 * IntensityBar — a labeled horizontal bar for breakdown charts (flow-by-day,
 * pain, symptom frequency). Give it a 0–1 `value` and a `color`.
 */
function IntensityBar({
  label,
  value = 0,
  color = "var(--primary)",
  meta,
  className = "",
  ...rest
}) {
  const pct = Math.max(0, Math.min(1, value)) * 100;
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["ft-ibar", className].filter(Boolean).join(" ")
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "ft-ibar__head"
  }, /*#__PURE__*/React.createElement("span", {
    className: "ft-ibar__label"
  }, label), meta != null && /*#__PURE__*/React.createElement("span", {
    className: "ft-ibar__meta"
  }, meta)), /*#__PURE__*/React.createElement("div", {
    className: "ft-ibar__track"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ft-ibar__fill",
    style: {
      width: pct + "%",
      background: color
    }
  })));
}
Object.assign(__ds_scope, { IntensityBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/tracking/IntensityBar.jsx", error: String((e && e.message) || e) }); }

// components/tracking/PhaseBadge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const PHASE = {
  menstrual: {
    label: "Menstrual",
    soft: "var(--phase-menstrual-soft)",
    fg: "var(--phase-menstrual)"
  },
  follicular: {
    label: "Follicular",
    soft: "var(--phase-follicular-soft)",
    fg: "#C4568A"
  },
  fertile: {
    label: "Fertile window",
    soft: "var(--phase-fertile-soft)",
    fg: "#B67A1E"
  },
  ovulation: {
    label: "Ovulation",
    soft: "var(--phase-ovulation-soft)",
    fg: "#B0700F"
  },
  luteal: {
    label: "Luteal",
    soft: "var(--phase-luteal-soft)",
    fg: "#9B569A"
  }
};

/**
 * PhaseBadge — a prominent current-phase indicator: a phase-tinted pill with a
 * color dot, the phase name, and an optional subtitle (e.g. "Day 3").
 */
function PhaseBadge({
  phase = "follicular",
  subtitle,
  className = "",
  style,
  ...rest
}) {
  const p = PHASE[phase] || PHASE.follicular;
  return /*#__PURE__*/React.createElement("span", _extends({
    className: className,
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: "8px",
      padding: "8px 14px",
      borderRadius: "var(--radius-pill)",
      background: p.soft,
      color: p.fg,
      fontFamily: "var(--font-body)",
      fontSize: "var(--text-sm)",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 8,
      height: 8,
      borderRadius: "50%",
      background: "currentColor",
      flex: "none"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: "var(--weight-semibold)"
    }
  }, p.label), subtitle && /*#__PURE__*/React.createElement("span", {
    style: {
      opacity: 0.8,
      fontWeight: "var(--weight-medium)"
    }
  }, "\xB7 ", subtitle));
}
Object.assign(__ds_scope, { PhaseBadge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/tracking/PhaseBadge.jsx", error: String((e && e.message) || e) }); }

// components/tracking/StatTile.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * StatTile — a compact stat panel: a big Playfair value with a muted label and
 * an optional icon. Grid these for the Insights summary (avg cycle, avg period,
 * cycles tracked, …).
 */
function StatTile({
  value,
  unit,
  label,
  icon,
  tone = "soft",
  className = "",
  style,
  ...rest
}) {
  const bg = tone === "accent" ? "var(--surface-2)" : tone === "card" ? "var(--surface)" : "var(--surface-soft)";
  return /*#__PURE__*/React.createElement("div", _extends({
    className: className,
    style: {
      background: bg,
      borderRadius: "var(--radius-md)",
      padding: "16px",
      display: "flex",
      flexDirection: "column",
      gap: "3px",
      boxShadow: tone === "card" ? "var(--shadow-card)" : "none",
      ...style
    }
  }, rest), icon && /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--primary-strong)",
      display: "inline-flex",
      marginBottom: 2
    }
  }, icon), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-display)",
      fontWeight: 600,
      fontSize: "var(--text-2xl)",
      color: "var(--deep)",
      lineHeight: 1
    }
  }, value, unit && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "0.5em",
      color: "var(--muted)",
      fontWeight: 500,
      marginLeft: 3
    }
  }, unit)), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-body)",
      fontSize: "var(--text-xs)",
      color: "var(--muted)",
      fontWeight: 500
    }
  }, label));
}
Object.assign(__ds_scope, { StatTile });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/tracking/StatTile.jsx", error: String((e && e.message) || e) }); }

// components/tracking/SymptomChip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* The built-in symptom vocabulary, verbatim from the source trackers. `icon` is
   the recommended Lucide glyph name (the system's icon set — see README). */
const SYMPTOMS = [{
  key: "cramps",
  label: "Cramps",
  icon: "zap"
}, {
  key: "headache",
  label: "Headache",
  icon: "brain"
}, {
  key: "bloating",
  label: "Bloating",
  icon: "circle-dot"
}, {
  key: "fatigue",
  label: "Fatigue",
  icon: "battery-low"
}, {
  key: "tenderBreasts",
  label: "Tender breasts",
  icon: "heart"
}, {
  key: "backPain",
  label: "Back pain",
  icon: "person-standing"
}, {
  key: "acne",
  label: "Acne",
  icon: "sparkle"
}, {
  key: "moodSwings",
  label: "Mood swings",
  icon: "cloud-sun"
}, {
  key: "nausea",
  label: "Nausea",
  icon: "waves"
}, {
  key: "insomnia",
  label: "Insomnia",
  icon: "moon"
}, {
  key: "depressed",
  label: "Low mood",
  icon: "cloud-rain"
}];

/**
 * SymptomChip — a selectable chip bound to the built-in symptom vocabulary.
 * Pass a `symptom` key for the canonical label, or `label` to override. Provide
 * `icon` (a Lucide node) for the leading glyph.
 */
function SymptomChip({
  symptom,
  label,
  selected = false,
  onClick,
  icon,
  size = "md",
  ...rest
}) {
  const meta = SYMPTOMS.find(s => s.key === symptom);
  return /*#__PURE__*/React.createElement(__ds_scope.Chip, _extends({
    selected: selected,
    onClick: onClick,
    size: size,
    icon: icon
  }, rest), label || meta && meta.label || symptom);
}
Object.assign(__ds_scope, { SYMPTOMS, SymptomChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/tracking/SymptomChip.jsx", error: String((e && e.message) || e) }); }

__ds_ns.FlowerMark = __ds_scope.FlowerMark;

__ds_ns.FlowtierLogo = __ds_scope.FlowtierLogo;

__ds_ns.PetalRain = __ds_scope.PetalRain;

__ds_ns.Toast = __ds_scope.Toast;

__ds_ns.Wordmark = __ds_scope.Wordmark;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Chip = __ds_scope.Chip;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.SegmentedTabs = __ds_scope.SegmentedTabs;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.CycleRing = __ds_scope.CycleRing;

__ds_ns.DayCell = __ds_scope.DayCell;

__ds_ns.FLOW_LEVELS = __ds_scope.FLOW_LEVELS;

__ds_ns.FlowScale = __ds_scope.FlowScale;

__ds_ns.IntensityBar = __ds_scope.IntensityBar;

__ds_ns.PhaseBadge = __ds_scope.PhaseBadge;

__ds_ns.StatTile = __ds_scope.StatTile;

__ds_ns.SYMPTOMS = __ds_scope.SYMPTOMS;

__ds_ns.SymptomChip = __ds_scope.SymptomChip;

})();
