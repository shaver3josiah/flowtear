import React from "react";

/* Standard cycle model (shared with the source trackers): ovulation ~14 days
   before the next period; fertile window = the 5 days before ovulation through
   ovulation day. All derived from cycleLength + periodLength. */
function computeCycle(cycleLength, periodLength) {
  const ovDay = Math.min(Math.max(cycleLength - 14, periodLength + 1), cycleLength - 1);
  const fertileStart = Math.max(ovDay - 5, periodLength + 1);
  return { ovDay, fertileStart };
}

export function phaseForDay(day, cycleLength, periodLength) {
  const { ovDay, fertileStart } = computeCycle(cycleLength, periodLength);
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
  luteal: "Luteal",
};
const PHASE_VAR = {
  menstrual: "var(--phase-menstrual)",
  follicular: "var(--phase-follicular)",
  fertile: "var(--phase-fertile)",
  ovulation: "var(--phase-ovulation)",
  luteal: "var(--phase-luteal)",
};

function polar(cx, cy, r, deg) {
  const a = ((deg - 90) * Math.PI) / 180;
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
export function CycleRing({
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
  const { ovDay, fertileStart } = computeCycle(cycleLength, periodLength);
  const A = (day) => (day / cycleLength) * 360;
  const phase = phaseForDay(cycleDay, cycleLength, periodLength);
  const [kx, ky] = polar(cx, cy, r, A(cycleDay - 0.5));

  // Optional fidget-spinner: drag to spin the dial, release for inertial decay.
  const wrapRef = React.useRef(null);
  const [rot, setRot] = React.useState(0);
  const drag = React.useRef({ active: false, lastAng: 0, lastT: 0, vel: 0, raf: 0 });
  const reduce = typeof window !== "undefined" && window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  React.useEffect(() => () => cancelAnimationFrame(drag.current.raf), []);
  const angOf = (e) => {
    const b = wrapRef.current.getBoundingClientRect();
    return (Math.atan2(e.clientY - (b.top + b.height / 2), e.clientX - (b.left + b.width / 2)) * 180) / Math.PI;
  };
  const onDown = (e) => {
    if (!spinnable || reduce) return;
    cancelAnimationFrame(drag.current.raf);
    drag.current.active = true; drag.current.lastAng = angOf(e); drag.current.lastT = performance.now(); drag.current.vel = 0;
    if (e.currentTarget.setPointerCapture) e.currentTarget.setPointerCapture(e.pointerId);
  };
  const onMove = (e) => {
    if (!drag.current.active) return;
    const a = angOf(e);
    let d = a - drag.current.lastAng;
    if (d > 180) d -= 360; else if (d < -180) d += 360;
    const t = performance.now();
    drag.current.vel = (d / Math.max(t - drag.current.lastT, 1)) * 16;
    drag.current.lastAng = a; drag.current.lastT = t;
    setRot((v) => v + d);
  };
  const onUp = () => {
    if (!drag.current.active) return;
    drag.current.active = false;
    const step = () => {
      drag.current.vel *= 0.96;
      setRot((v) => v + drag.current.vel);
      if (Math.abs(drag.current.vel) > 0.05) drag.current.raf = requestAnimationFrame(step);
    };
    if (Math.abs(drag.current.vel) > 0.12) drag.current.raf = requestAnimationFrame(step);
  };

  return (
    <div
      ref={wrapRef}
      className={className}
      style={{ position: "relative", width: size, height: size, touchAction: spinnable ? "none" : undefined, cursor: spinnable && !reduce ? "grab" : undefined, ...style }}
      role="img"
      aria-label={`Cycle day ${cycleDay} of ${cycleLength}, ${PHASE_LABEL[phase]} phase`}
      onPointerDown={onDown}
      onPointerMove={onMove}
      onPointerUp={onUp}
      onPointerLeave={onUp}
      {...rest}
    >
      <svg viewBox={`0 0 ${V} ${V}`} width={size} height={size} style={{ display: "block", transform: `rotate(${rot}deg)`, transformOrigin: "50% 50%" }}>
        {/* soft full track */}
        <circle cx={cx} cy={cy} r={r} fill="none" stroke="var(--surface-soft)" strokeWidth={w} />
        {/* menstrual (bleed) days */}
        <path d={arc(cx, cy, r, A(0), A(periodLength))} fill="none" stroke={PHASE_VAR.menstrual} strokeWidth={w} strokeLinecap="round" />
        {/* fertile window through ovulation */}
        <path d={arc(cx, cy, r, A(fertileStart - 1), A(ovDay + 1))} fill="none" stroke={PHASE_VAR.fertile} strokeWidth={w} strokeLinecap="round" />
        {/* ovulation peak */}
        <path d={arc(cx, cy, r, A(ovDay - 0.6), A(ovDay + 0.6))} fill="none" stroke={PHASE_VAR.ovulation} strokeWidth={w} strokeLinecap="round" />
        {/* today knob */}
        <circle cx={kx} cy={ky} r={w / 2 + 4} fill="var(--surface)" stroke={PHASE_VAR[phase]} strokeWidth={4} />
        <circle cx={kx} cy={ky} r={3} fill={PHASE_VAR[phase]} />
      </svg>
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          textAlign: "center",
          padding: "0 18%",
        }}
      >
        {children || (
          <>
            <span style={{ fontFamily: "var(--font-body)", fontWeight: 600, fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-label)", textTransform: "uppercase", color: PHASE_VAR[phase] }}>
              {PHASE_LABEL[phase]}
            </span>
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: size * 0.26, lineHeight: 1, color: "var(--deep)", margin: "2px 0" }}>
              {cycleDay}
            </span>
            <span style={{ fontFamily: "var(--font-body)", fontSize: "var(--text-sm)", color: "var(--muted)" }}>
              day of your cycle
            </span>
          </>
        )}
      </div>
    </div>
  );
}
