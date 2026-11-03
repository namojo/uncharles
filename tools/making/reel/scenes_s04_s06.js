/* S4 아트 (24-32s): gray boxes become the real pixel art, the palette from the art bible, a failed image model and the fix, then the art dissolves into cells */
REEL.scene({
  id: "s04", start: B("s04"), end: B("s05") + 0.05,
  setup(el) {
    this.root = h("div", "full", el);
    css(this.root, { background: C.bg2 });
    /* greybox world */
    this.grey = h("div", "full", this.root);
    css(this.grey, { background: "#3a3a44" });
    const floor = h("div", "a", this.grey); css(floor, { left: "0px", top: "800px", width: W + "px", height: "280px", background: "#2c2c34" });
    [["찰스", 400, "#8c9099"], ["프로스티", 1250, "#9a8f90"]].forEach(([nm, x, col]) => {
      const b = h("div", "a px", this.grey, nm);
      css(b, { left: x + "px", top: "560px", width: "230px", height: "240px", background: col, color: "#fff", fontSize: "40px", textAlign: "center", lineHeight: "240px" });
    });
    const gl = h("div", "a px", this.grey, "그레이박스: 전투가 웃긴지부터 본다");
    css(gl, { left: "120px", top: "130px", fontSize: "52px", color: C.amber });
    /* real art */
    this.art = h("div", "full", this.root);
    this.kit = REEL.img("../assets/img/kitchen.png");
    css(this.kit, { position: "absolute", left: "0px", top: "0px", width: W + "px", height: H + "px", imageRendering: "pixelated" });
    this.art.appendChild(this.kit);
    this.ch = REEL.img("../assets/img/charles.png");
    css(this.ch, { position: "absolute", left: "330px", top: "440px", width: "243px", height: "360px", imageRendering: "pixelated" });
    this.art.appendChild(this.ch);
    this.fr = REEL.img("../assets/img/frosty.png");
    css(this.fr, { position: "absolute", left: "1120px", top: "440px", width: "381px", height: "360px", imageRendering: "pixelated" });
    this.art.appendChild(this.fr);
    this.scan = h("div", "a", this.root);
    css(this.scan, { top: "0px", width: "12px", height: H + "px", background: C.cyan, boxShadow: `0 0 30px ${C.cyan}` });
    /* palette */
    this.band = h("div", "a", this.root);
    css(this.band, { left: "0px", top: "800px", width: W + "px", height: "280px", background: "rgba(20,18,26,.9)" });
    this.cap = h("div", "a px", this.root, "아트 바이블: 켜진 색은 화면의 10% 이하");
    css(this.cap, { left: "147px", top: "826px", fontSize: "40px", color: C.amber, fontWeight: 700 });
    this.sw = DATA.palette.map(([hex, nm], i) => {
      const d = h("div", "a", this.root);
      css(d, { left: 147 + i * 164 + "px", top: "904px", width: "150px", height: "118px", background: hex, border: `4px solid ${C.ink}`, boxSizing: "border-box" });
      const dark = ["#14121a", "#1b1a24", "#8a90a6", "#d9583a"].includes(hex);
      const a = h("div", "a px", d, nm); css(a, { left: "10px", top: "10px", fontSize: "26px", fontWeight: 700, color: dark ? "#fff" : C.ink });
      const b = h("div", "a", d, hex); css(b, { left: "10px", top: "70px", fontFamily: MONO, fontSize: "22px", fontWeight: 500, color: dark ? "#ddd" : C.ink });
      return d;
    });
    /* codex panel */
    this.cx = h("div", "a", this.root);
    css(this.cx, { left: "920px", top: "90px", width: "900px", height: "230px", background: C.panel, border: `5px solid ${C.steel}`, boxSizing: "border-box", boxShadow: "8px 8px 0 #0b0a10" });
    this.cx1 = h("div", "a px", this.cx, "codex exec  →  400 model_not_found"); css(this.cx1, { left: "30px", top: "34px", fontSize: "38px", color: C.red, fontWeight: 700 });
    this.cx2 = h("div", "a px", this.cx, "-m gpt-6-astra  →  이미지 3장 ✓"); css(this.cx2, { left: "30px", top: "128px", fontSize: "38px", color: C.mint, fontWeight: 700 });
    this.chip = makeChip(this.root, 120, 44, "art-director", "codex-image", C.mint);
    /* dissolve into cells */
    this.cv = h("canvas", "a", this.root); this.cv.width = 48; this.cv.height = 27;
    css(this.cv, { left: "0px", top: "0px", width: W + "px", height: H + "px", imageRendering: "pixelated" });
    this.wipe = h("div", "full", this.root);
    css(this.wipe, { background: C.amber });
  },
  render(lt) {
    /* 3 -> 4: amber colour wipe covers S3 and drops away */
    const wi = prog(lt, 0, 0.2, ease.swift), wo = prog(lt, 0.2, 0.3, ease.swift);
    css(this.wipe, { transform: `scaleX(${wo > 0 ? 1 - wo : wi})`, transformOrigin: wo > 0 ? "100% 50%" : "0% 50%" });
    /* greybox -> art: the scan bar sweeps left to right at lt 1.0 */
    const sp = prog(lt, 1.0, 0.9, ease.swift);
    css(this.art, { clipPath: `inset(0 ${(1 - sp) * 100}% 0 0)` });
    css(this.scan, { left: sp * W - 6 + "px", opacity: sp > 0 && sp < 1 ? 1 : 0 });
    /* stepped idle (6 fps) */
    const f = Math.floor(lt * 6);
    css(this.ch, { transform: `translateY(${lt > 2.0 ? (f % 2) * -9 : 0}px)` });
    css(this.fr, { transform: `translateY(${lt > 2.0 ? ((f + 1) % 2) * -6 : 0}px)` });
    css(this.grey, { opacity: sp > 0.999 ? 0 : 1 });
    css(this.band, { opacity: lt >= 3.0 ? 1 : 0 });
    stepIn(this.cap, prog(lt, 3.0, 0.3, ease.snap), 0, 20);
    this.sw.forEach((d, i) => stepIn(d, prog(lt, 3.1 + 0.08 * i, 0.25, ease.snap), 0, 40));
    /* codex friction */
    stepIn(this.cx, prog(lt, 3.95, 0.25, ease.snap), 0, -40);
    css(this.cx1, { opacity: lt >= 4.0 ? 1 : 0 });
    css(this.cx2, { opacity: lt >= 5.0 ? 1 : 0 });
    const shk = lt >= 4.0 && lt < 4.12 ? (Math.floor(lt * 30) % 2 ? 10 : -10) : 0;
    css(this.cx, { transform: `translate(${shk}px, ${lt >= 3.95 ? 0 : -40}px)` });
    /* 7.0-7.95: the art falls apart into dark cells (reads as the next scene's pixels) */
    const ctx = this.cv.getContext("2d");
    ctx.clearRect(0, 0, 48, 27);
    const dp = prog(lt, 7.0, 0.9, ease.linear);
    if (dp > 0) {
      ctx.fillStyle = C.bg2;
      for (let i = 0; i < 48 * 27; i++) if (rand(i, 3) < dp * 1.05) ctx.fillRect(i % 48, Math.floor(i / 48), 1, 1);
    }
  },
});

/* S5 한글 도트 (32-40s): one syllable assembles cell by cell in Galmuri's 11px grid, then the real title and battle UI */
REEL.scene({
  id: "s05", start: B("s05"), end: B("s06") + 0.2,
  setup(el) {
    this.root = h("div", "full", el);
    css(this.root, { background: C.bg2 });
    const tex = h("div", "full", this.root);
    css(tex, { background: "repeating-linear-gradient(0deg, rgba(255,255,255,.03) 0 2px, transparent 2px 8px)" });
    this.chip = makeChip(this.root, 120, 44, "/art-bible §7", "Galmuri11 · OFL", C.cyan);
    /* read the syllable's pixels out of the font itself */
    const cv = document.createElement("canvas"); cv.width = 20; cv.height = 20;
    const cx = cv.getContext("2d"); cx.font = `12px "Galmuri11"`; cx.textBaseline = "top"; cx.fillStyle = "#fff";
    cx.fillText("찰", 2, 2);
    const d = cx.getImageData(0, 0, 20, 20).data;
    this.pix = [];
    let x0 = 99, y0 = 99, x1 = -1, y1 = -1;
    for (let y = 0; y < 20; y++) for (let x = 0; x < 20; x++) if (d[(y * 20 + x) * 4 + 3] > 200) { this.pix.push([x, y]); x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
    this.gw = x1 - x0 + 1; this.gh = y1 - y0 + 1; this.pix = this.pix.map(([x, y]) => [x - x0, y - y0]);
    const N = 12, CELL = 46, gx = 130, gy = 250;
    this.cells = [];
    for (let i = 0; i < N * N; i++) {
      const c = h("div", "a", this.root);
      css(c, { left: gx + (i % N) * CELL + "px", top: gy + Math.floor(i / N) * CELL + "px", width: CELL + "px", height: CELL + "px", boxSizing: "border-box", border: "1px solid rgba(138,144,166,.25)" });
    }
    const ox = Math.floor((N - this.gw) / 2), oy = Math.floor((N - this.gh) / 2);
    this.lit = this.pix.map(([x, y], i) => {
      const c = h("div", "a", this.root);
      css(c, { width: CELL - 4 + "px", height: CELL - 4 + "px", background: C.cyan, boxShadow: `0 0 14px ${C.cyan}88` });
      return { c, tx: gx + (x + ox) * CELL + 2, ty: gy + (y + oy) * CELL + 2, i };
    });
    this.lab = h("div", "a px", this.root, "Galmuri11 · 11×11 한 칸씩");
    css(this.lab, { left: "130px", top: "835px", fontSize: "40px", color: C.text });
    /* real screens */
    this.frame = h("div", "a", this.root);
    css(this.frame, { left: "800px", top: "270px", width: "960px", height: "540px", overflow: "hidden", border: `6px solid ${C.steel}`, boxSizing: "border-box", boxShadow: "10px 10px 0 #0b0a10" });
    this.t1 = REEL.img("../assets/img/ev_title.png");
    css(this.t1, { position: "absolute", left: "0px", top: "0px", width: "948px", height: "528px", imageRendering: "auto" });
    this.frame.appendChild(this.t1);
    this.t2 = REEL.img("../assets/img/ev_styled.png");
    css(this.t2, { position: "absolute", left: "0px", top: "0px", width: "948px", height: "528px" });
    this.frame.appendChild(this.t2);
    this.boxes = [[1032, 341, 124, 90, "UN"], [1160, 547, 158, 79, "창 한 칸"], [1150, 676, 64, 50, "커서"]].map(([x, y, w, hh, t]) => {
      const b = h("div", "a", this.root);
      css(b, { left: x + "px", top: y + "px", width: w + "px", height: hh + "px", border: `5px solid ${C.cyan}`, boxSizing: "border-box" });
      const l = h("div", "a px", this.root, t); css(l, { left: x + "px", top: y - 44 + "px", fontSize: "32px", color: C.cyan, fontWeight: 700, whiteSpace: "nowrap", background: C.bg2, padding: "0 8px" });
      return { b, l };
    });
    this.boxes2 = [[813, 281, 933, 124, "게이지"], [811, 636, 332, 163, "커맨드"], [1152, 636, 596, 163, "로그"]].map(([x, y, w, hh, t]) => {
      const b = h("div", "a", this.root);
      css(b, { left: x + "px", top: y + "px", width: w + "px", height: hh + "px", border: `5px solid ${C.amber}`, boxSizing: "border-box" });
      const l = h("div", "a px", this.root, t); css(l, { left: x + 10 + "px", top: y + 8 + "px", fontSize: "30px", color: C.amber, fontWeight: 700, background: C.bg2, padding: "0 8px" });
      return { b, l };
    });
    this.stack = h("div", "a", this.root);
    css(this.stack, { left: "0px", top: "0px", width: W + "px", height: H + "px", transformOrigin: "1280px 540px" });
    [this.frame, ...this.boxes.flatMap((o) => [o.b, o.l]), ...this.boxes2.flatMap((o) => [o.b, o.l])].forEach((e) => this.stack.appendChild(e));
    this.rule = h("div", "a px", this.root, "켜진 색은 10% 이하");
    css(this.rule, { left: "800px", top: "840px", fontSize: "46px", color: C.cyan, fontWeight: 700 });
    this.rule2 = h("div", "a px", this.root, "패널·게이지·로그까지 같은 폰트와 팔레트");
    css(this.rule2, { left: "800px", top: "840px", fontSize: "40px", color: C.amber, fontWeight: 700 });
  },
  render(lt) {
    css(this.root, { opacity: 1 });
    /* 0.4-1.8 the cells fly in */
    this.lit.forEach((o) => {
      const p = prog(lt, 0.4 + rand(o.i, 1) * 1.0, 0.35, ease.outBack);
      const sx = 900 + (rand(o.i, 2) - 0.5) * 1600, sy = (rand(o.i, 3) < 0.5 ? -200 : 1280);
      if (lt < 6.9) css(o.c, { opacity: p > 0.001 ? 1 : 0, left: lerp(sx, o.tx, p) + "px", top: lerp(sy, o.ty, p) + "px" });
    });
    stepIn(this.lab, prog(lt, 1.9, 0.3, ease.snap), 0, 20);
    /* 2.0: the real title screen scans in from the left */
    const tp = prog(lt, 2.0, 0.6, ease.swift);
    css(this.frame, { opacity: tp > 0.001 ? 1 : 0, clipPath: `inset(0 ${(1 - tp) * 100}% 0 0)` });
    const swap = prog(lt, 5.0, 0.4, ease.swift);
    css(this.t2, { clipPath: `inset(${(1 - swap) * 100}% 0 0 0)` });
    this.boxes.forEach((o, i) => {
      const on = lt >= 2.8 + i * 0.5 && lt < 5.0;
      css(o.b, { opacity: on ? 1 : 0 }); css(o.l, { opacity: on ? 1 : 0 });
    });
    css(this.rule, { opacity: lt >= 4.2 && lt < 5.0 ? 1 : 0 });
    this.boxes2.forEach((o, i) => {
      const on = lt >= 5.5 + i * 0.4;
      css(o.b, { opacity: on ? 1 : 0 }); css(o.l, { opacity: on ? 1 : 0 });
    });
    css(this.rule2, { opacity: lt >= 6.6 ? 1 : 0 });
    css(this.stack, { transform: `scale(${lerp(1, 1.14, prog(lt, 2.0, 5.5, ease.linear))})` });
    /* 6.9-7.7: the glyph cells scatter away */
    this.lit.forEach((o) => {
      const q = prog(lt, 6.9 + rand(o.i, 7) * 0.5, 0.4, ease.exit);
      if (q > 0) css(o.c, { left: o.tx + q * (rand(o.i, 8) - 0.3) * 1600 + "px", top: o.ty + (rand(o.i, 9) - 0.5) * q * 900 + "px", opacity: 1 - q });
    });
    css(this.lab, { opacity: lt >= 6.9 ? 1 - prog(lt, 6.9, 0.3, ease.exit) : 1 });
  },
});

/* S6 웹·폰 (40-48s): the web build on a phone, touch ripples, the checklist, two honest friction notes, then the portrait hint */
REEL.scene({
  id: "s06", start: B("s06"), end: B("s07") + 0.4,
  setup(el) {
    this.root = h("div", "full", el);
    css(this.root, { background: "#dfe7ee" });
    const tex = h("div", "full", this.root);
    css(tex, { background: "repeating-linear-gradient(135deg, rgba(20,18,26,.04) 0 3px, transparent 3px 14px)" });
    this.chip = makeChip(this.root, 120, 44, "Godot Web", "GitHub Pages", "#0a97a3");
    this.phone = h("div", "a", this.root);
    css(this.phone, { left: "455px", top: "282px", width: "1010px", height: "516px", background: "#0f0f14", borderRadius: "56px", boxShadow: "0 30px 70px rgba(20,18,26,.38)", transformOrigin: "505px 258px" });
    this.scr = h("div", "a", this.phone);
    css(this.scr, { left: "45px", top: "45px", width: "920px", height: "426px", borderRadius: "10px", overflow: "hidden", background: "#000" });
    this.shots = ["ev_m_title", "ev_m_battle", "ev_m_result"].map((n) => {
      const im = REEL.img(`../assets/img/${n}.png`);
      css(im, { position: "absolute", left: "0px", top: "0px", width: "920px", height: "426px" });
      this.scr.appendChild(im);
      return im;
    });
    this.hint = REEL.img("../assets/img/ev_m_portrait.png");
    css(this.hint, { position: "absolute", left: "247px", top: "-248px", width: "426px", height: "922px", transform: "rotate(90deg)" });
    this.scr.appendChild(this.hint);
    this.rip = [[0.5, 0.86], [0.2, 0.72], [0.2, 0.80], [0.22, 0.80]].map(([fx, fy]) => {
      const r = h("div", "a", this.scr);
      css(r, { left: fx * 920 - 40 + "px", top: fy * 426 - 40 + "px", width: "80px", height: "80px", borderRadius: "50%", border: `6px solid ${C.cyan}`, boxSizing: "border-box", opacity: 0 });
      return r;
    });
    this.list = ["Web 내보내기", "GitHub Pages 배포", "휴대폰 터치 확인"].map((t, i) => {
      const r = h("div", "a", this.root);
      css(r, { left: "70px", top: 380 + i * 110 + "px", width: "370px", display: "flex", gap: "16px", alignItems: "center", fontWeight: 800, fontSize: "36px", color: "#14121a" });
      const bx = h("span", "", r, "✓"); css(bx, { width: "46px", height: "46px", background: "#0a97a3", color: "#fff", textAlign: "center", lineHeight: "46px", flex: "none", fontSize: "30px" });
      h("span", "", r, t);
      return r;
    });
    this.notes = [["Chrome 캡처가 막혔다", "Playwright로 폰을 흉내 냈다"], ["탭이 안 먹혔다", "로그를 찍어 보니 busy=true"]].map(([a, b], i) => {
      const n = h("div", "a", this.root);
      css(n, { left: "1500px", top: 380 + i * 190 + "px", width: "360px", background: "#fff", borderLeft: "10px solid #ff4d6d", boxSizing: "border-box", padding: "18px 20px", boxShadow: "8px 8px 0 rgba(20,18,26,.15)" });
      const x = h("div", "", n, a); css(x, { fontWeight: 900, fontSize: "36px", color: "#14121a", lineHeight: "1.25" });
      const y = h("div", "", n, b); css(y, { fontWeight: 600, fontSize: "32px", color: "#5b6272", lineHeight: "1.3", marginTop: "8px" });
      return n;
    });
  },
  render(lt) {
    /* 5 -> 6: an iris opens from the middle */
    const ir = prog(lt, 0, 0.45, ease.swift);
    css(this.root, { clipPath: `circle(${ir * 1500}px at 50% 50%)` });
    const idx = lt < 1.6 ? 0 : lt < 3.4 ? 1 : 2;
    this.shots.forEach((im, i) => css(im, { opacity: lt < 5.0 && i === idx ? 1 : 0 }));
    css(this.hint, { opacity: lt >= 5.0 && lt < 6.9 ? 1 : 0 });
    css(this.shots[1], { opacity: (lt >= 6.9 && lt < 7.6) || (lt < 5.0 && idx === 1) ? 1 : 0 });
    css(this.shots[2], { opacity: lt >= 7.6 || (lt < 5.0 && idx === 2) ? 1 : 0 });
    [1.2, 2.8, 7.2, 7.6].forEach((t0, i) => {
      const p = prog(lt, t0, 0.45, ease.outQuint);
      css(this.rip[i], { opacity: p > 0 && p < 1 ? 1 - p : 0, transform: `scale(${lerp(0.4, 1.6, p)})` });
    });
    this.list.forEach((r, i) => stepIn(r, prog(lt, 1.0 + i * 1.0, 0.25, ease.snap), -40, 0));
    this.notes.forEach((n, i) => stepIn(n, prog(lt, 4.0 + i * 0.6, 0.25, ease.snap), 60, 0));
    const rp = prog(lt, 5.2, 0.7, ease.swift) - prog(lt, 6.3, 0.6, ease.swift);
    const hand = lt > 1.4 && lt < 5.2 ? 1 : 0;
    css(this.phone, { transform: `translateY(${hand * Math.sin(lt * 2.6) * 10}px) rotate(${-90 * rp + hand * Math.sin(lt * 1.9) * 1.6}deg) scale(${lerp(1, 0.9, rp)})` });
    const out = prog(lt, 7.98, 0.4, ease.swift);
    css(this.root, { transform: `translateX(${-out * 25}%)`, filter: `blur(${out * 6}px)` });
  },
});
