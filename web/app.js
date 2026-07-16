// Uncorked web app — shell. Wires the store, navigation, tab bar, overlays and
// theme, then hands each screen a single `ctx` object. No build step: this is a
// native ES module; React/ReactDOM/htm/the design-system bundle load as globals
// from index.html first.
//
// SCREEN CONTRACT — every file in web/screens/ exports a default React component
// that takes ONE prop, `ctx`, with:
//   ctx.store  — the CycleStore (methods + getters; see web/core/store.js)
//   ctx.nav    — { tab, setTab(name), open(name, props), close() }  overlays: "garden","session","theme","phase","log"
//   ctx.html   — htm tag bound to React.createElement (write html`<${Card}>…</${Card}>`)
//   ctx.ui     — design-system components (window.FlowtierDesignSystem_6b3d0d)
//   ctx.Icon   — <${Icon} name="calendar" size=22 />  (offline lucide)
//   ctx.fmt    — copy/date helpers (web/core/format.js)
//   ctx.today  — the current Date (passed in so screens stay testable)
// The whole tree re-renders on any store change, so screens just read store state.

import { CycleStore } from "./core/store.js";
import { Icon } from "./vendor/icon.js";
import * as fmt from "./core/format.js";

import Today from "./screens/today.js";
import Calendar from "./screens/calendar.js";
import Log from "./screens/log.js";
import Stretch from "./screens/stretch.js";
import Insights from "./screens/insights.js";
import Garden from "./screens/garden.js";
import StretchSession from "./screens/stretchSession.js";
import ThemeEditor from "./screens/themeEditor.js";
import PhaseDetail from "./screens/phaseDetail.js";

const React = window.React;
const { useState, useEffect } = React;
const html = window.htm.bind(React.createElement);
const UI = window.FlowtierDesignSystem_6b3d0d || {};

const store = new CycleStore();
store.seedSampleIfFirstLaunch();

const TABS = [
  { id: "today", label: "Today", icon: "flower-2", screen: Today },
  { id: "calendar", label: "Calendar", icon: "calendar", screen: Calendar },
  { id: "log", label: "Log", icon: "droplet", screen: Log },
  { id: "stretch", label: "Stretch", icon: "activity", screen: Stretch },
  { id: "insights", label: "Insights", icon: "bar-chart-2", screen: Insights },
];

const OVERLAYS = {
  garden: Garden,
  session: StretchSession,
  theme: ThemeEditor,
  phase: PhaseDetail,
  log: Log,
};

const THEME_KEY = "flowtear.theme";
function applyTheme(name) {
  document.documentElement.setAttribute("data-theme", name || "cherry");
}

// re-render the whole tree whenever the store notifies.
function useStore() {
  const [, setN] = useState(0);
  useEffect(() => store.subscribe(() => setN((x) => x + 1)), []);
  return store;
}

function App() {
  useStore();
  const [tab, setTab] = useState("today");
  const [overlay, setOverlay] = useState(null); // { name, props } | null
  const [theme, setTheme] = useState(localStorage.getItem(THEME_KEY) || "cherry");
  const today = React.useMemo(() => new Date(), []);

  useEffect(() => { applyTheme(theme); localStorage.setItem(THEME_KEY, theme); }, [theme]);

  const nav = {
    tab,
    setTab: (id) => { setOverlay(null); setTab(id); },
    open: (name, props = {}) => setOverlay({ name, props }),
    close: () => setOverlay(null),
    theme,
    setTheme,
  };

  const ctx = { store, nav, html, ui: UI, Icon, fmt, today };
  const Current = (TABS.find((t) => t.id === tab) || TABS[0]).screen;

  const OverlayComp = overlay ? OVERLAYS[overlay.name] : null;

  return html`
    <div class="app">
      <main class="screen" key=${tab}>
        <${Screen} Comp=${Current} ctx=${{ ...ctx, screenProps: {} }} />
      </main>

      <nav class="tabbar" role="tablist">
        ${TABS.map((t) => html`
          <button
            key=${t.id}
            class=${"tabbtn" + (t.id === tab ? " active" : "")}
            role="tab"
            aria-selected=${t.id === tab}
            onClick=${() => nav.setTab(t.id)}
          >
            <${Icon} name=${t.icon} size=${22} />
            <span>${t.label}</span>
          </button>
        `)}
      </nav>

      ${OverlayComp && html`
        <div class="overlay-scrim" onClick=${nav.close}>
          <div class="overlay-sheet" onClick=${(e) => e.stopPropagation()}>
            <${Screen} Comp=${OverlayComp} ctx=${{ ...ctx, screenProps: overlay.props }} />
          </div>
        </div>
      `}
    </div>
  `;
}

// Small error boundary so one broken screen doesn't blank the whole app —
// makes incremental screen development safe.
class Screen extends React.Component {
  constructor(p) { super(p); this.state = { err: null }; }
  static getDerivedStateFromError(err) { return { err }; }
  render() {
    if (this.state.err) {
      return html`<div class="screen-error">
        <p>This screen hit a snag.</p>
        <pre>${String(this.state.err && this.state.err.message)}</pre>
      </div>`;
    }
    const { Comp, ctx } = this.props;
    return html`<${Comp} ...${{ ctx }} />`;
  }
}

window.React.__store = store; // handy for debugging in the WebView console
window.ReactDOM.createRoot(document.getElementById("root")).render(html`<${App} />`);
