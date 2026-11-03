/* Uncharles making-of: shared helpers. Every scene file reads these globals. */
const { ease, prog, win, kf, spring, clamp, lerp, map, rand, noise, split, stagger, count, scramble, shake, pulse, level, inout, css, h, s, cue } = REEL;
REEL.config({ duration: 76, fps: 30, width: 1920, height: 1080, audio: "../audio/mix.wav", push: 0 });
const W = 1920, H = 1080, FPS = 30;
const C = { ink: "#0c0b12", bg2: "#14121a", panel: "#1b1a24", band: "#2e2c40", steel: "#8a90a6", text: "#e8e6f0", dim: "#9a9cb0",
  cyan: "#3fe0e8", amber: "#f2c94c", red: "#ff4d6d", mint: "#43e0c0", orange: "#d9583a", violet: "#b58cff" };
const PX = `"Galmuri11","Pretendard",monospace`;
const DISP = `"Black Han Sans","Pretendard",sans-serif`;
const SERIF = `"Noto Serif KR","Pretendard",serif`;
const MONO = `"JetBrains Mono","Galmuri11","Pretendard",monospace`;
/* scene boundary: half a frame early so the cut frame already shows the new state */
const B = (id) => cue("scene." + id) - 0.5 / FPS;
const q12 = (t) => Math.floor(t * 12) / 12;               /* 12 fps stepped time */
const blink = (t, period = 0.8) => (Math.floor(t / (period / 2)) % 2 === 0);

/* Hangul IME typing states: ㅊ -> 차 -> 찰 -> 찰ㅅ -> 찰스 */
const CHO = ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"];
function imeSeq(str) {
  const out = []; let done = "";
  for (const ch of str) {
    const c = ch.charCodeAt(0) - 0xAC00;
    if (c < 0 || c > 11171) { done += ch; out.push(done); continue; }
    const cho = Math.floor(c / 588), jung = Math.floor((c % 588) / 28), jong = c % 28;
    out.push(done + CHO[cho]);
    out.push(done + String.fromCharCode(0xAC00 + (cho * 21 + jung) * 28));
    if (jong) out.push(done + ch);
    done += ch;
  }
  return out;
}

/* the studio: 7x7 tiles, one per agent (49). returns tiles and a centre lookup */
function makeGrid(parent, size = 96, gap = 16) {
  const g = h("div", "a", parent);
  css(g, { left: "0px", top: "0px", width: W + "px", height: H + "px" });
  const N = 7, span = N * size + (N - 1) * gap, x0 = W / 2 - span / 2, y0 = H / 2 - span / 2, tiles = [];
  for (let i = 0; i < 49; i++) {
    const t = h("div", "a", g);
    css(t, { left: x0 + (i % 7) * (size + gap) + "px", top: y0 + Math.floor(i / 7) * (size + gap) + "px", width: size + "px", height: size + "px",
      background: C.panel, border: `3px solid ${C.band}`, boxSizing: "border-box" });
    tiles.push(t);
  }
  const center = (i) => ({ x: x0 + (i % 7) * (size + gap) + size / 2, y: y0 + Math.floor(i / 7) * (size + gap) + size / 2 });
  return { g, tiles, center, size, gap };
}
function lightTile(t, on, color = C.cyan) {
  css(t, { background: on ? color : C.panel, borderColor: on ? color : C.band, boxShadow: on ? `0 0 40px ${color}99` : "none" });
}
/* chip: which skill / which agent did this step (information, not decoration) */
function makeChip(parent, left, top, skill, agent, color) {
  const c = h("div", "a", parent);
  css(c, { left: left + "px", top: top + "px", display: "flex", gap: "0px", fontFamily: PX, fontSize: "30px", lineHeight: "1", whiteSpace: "nowrap" });
  const a = h("span", "", c, skill); css(a, { background: color, color: C.ink, padding: "10px 16px", fontWeight: 700 });
  const b = h("span", "", c, agent); css(b, { background: C.panel, color: C.text, padding: "10px 16px", border: `3px solid ${color}`, borderLeft: "0" });
  return c;
}
function stepIn(el, p, dx = 0, dy = 40) { /* three-step entrance (12 fps feel) */
  const k = Math.ceil(clamp(p, 0, 1) * 3) / 3;
  css(el, { opacity: p > 0 ? 1 : 0, transform: `translate(${(1 - k) * dx}px, ${(1 - k) * dy}px)` });
}
