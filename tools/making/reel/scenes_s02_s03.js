/* S2 브리프 (8-16s): the collaboration protocol as five stamps (human vs agent) beside the real one-page brief on cream paper */
const PAPER = "#efe6d2", INK = "#1b1a24", MARK = "#d9583a";
REEL.scene({
  id: "s02", start: B("s02"), end: B("s03") + 0.45,
  setup(el) {
    this.root = h("div", "full", el);
    css(this.root, { background: PAPER });
    const tex = h("div", "full", this.root);
    css(tex, { background: "repeating-linear-gradient(0deg, rgba(60,40,10,.04) 0 2px, transparent 2px 6px)" });
    const labels = [["질문", "에이전트"], ["선택지", "에이전트"], ["결정", "사람"], ["초안", "에이전트"], ["승인", "사람"]];
    this.rot = [-2, 1.5, -1, 2, -1.5];
    this.st = labels.map((l, i) => {
      const human = l[1] === "사람";
      const row = h("div", "a", this.root);
      css(row, { left: "120px", top: 130 + i * 150 + "px", width: "700px", height: "112px" });
      const box = h("div", "a px", row, l[0]);
      css(box, { left: "0px", top: "0px", width: "380px", height: "112px", boxSizing: "border-box", border: `8px solid ${human ? MARK : INK}`,
        color: human ? "#fff5e0" : INK, background: human ? MARK : "transparent", fontSize: "64px", fontWeight: 700, textAlign: "center", lineHeight: "96px" });
      const who = h("div", "a px", row, l[1]);
      css(who, { left: "420px", top: "30px", fontSize: "46px", fontWeight: 700, color: human ? MARK : "#6b6355" });
      if (i < 4) { const ln = h("div", "a", this.root); css(ln, { left: "306px", top: 130 + i * 150 + 112 + "px", width: "6px", height: "38px", background: INK }); }
      return { row, box };
    });
    this.chip = makeChip(this.root, 120, 44, "/brainstorm", "한 장짜리 브리프", MARK);
    this.dots = [];
    for (let i = 0; i < 5; i++) for (let k = 0; k < 10; k++) { const d = h("div", "a", this.root); css(d, { width: "16px", height: "16px", background: k % 3 ? (i === 2 || i === 4 ? MARK : INK) : C.amber, opacity: 0 }); this.dots.push([d, i, k]); }
    /* the brief card */
    this.doc = h("div", "a", this.root);
    css(this.doc, { left: "930px", top: "120px", width: "880px", height: "770px", background: "#fbf7ea", boxShadow: "14px 14px 0 rgba(27,26,36,.22)", transform: "rotate(-1deg)" });
    const path = h("div", "a", this.doc, "design/game-brief.md");
    css(path, { left: "48px", top: "30px", fontFamily: MONO, fontSize: "24px", color: "#8b8372" });
    const ttl = h("div", "a", this.doc, "Game Brief: Uncharles");
    css(ttl, { left: "48px", top: "74px", fontFamily: SERIF, fontWeight: 900, fontSize: "62px", color: INK });
    this.pitch = h("div", "a", this.doc, "");
    css(this.pitch, { left: "48px", top: "168px", width: "784px", fontFamily: SERIF, fontWeight: 500, fontSize: "33px", lineHeight: "1.5", color: INK, whiteSpace: "normal" });
    this.mvp = DATA.mvp.map((t, i) => {
      const r = h("div", "a", this.doc);
      css(r, { left: "48px", top: 452 + i * 54 + "px", width: "600px", height: "46px", display: "flex", alignItems: "center", gap: "16px", fontFamily: SERIF, fontWeight: 700, fontSize: "33px", color: INK });
      const bx = h("span", "", r, "✓"); css(bx, { width: "34px", height: "34px", border: `4px solid ${INK}`, textAlign: "center", lineHeight: "30px", color: MARK, fontSize: "30px", boxSizing: "border-box" });
      h("span", "", r, t);
      return r;
    });
    this.num = h("div", "a", this.doc, "0");
    css(this.num, { left: "640px", top: "450px", fontFamily: DISP, fontSize: "300px", lineHeight: "1", color: MARK });
    this.numl = h("div", "a px", this.doc, "MVP");
    css(this.numl, { left: "670px", top: "430px", fontSize: "40px", color: INK, fontWeight: 700 });
    this.svg = s("svg", { width: 880, height: 770, viewBox: "0 0 880 770" }, this.doc);
    css(this.svg, { position: "absolute", left: "0px", top: "0px" });
    this.circ = s("path", { d: "M 640 500 C 650 430 760 430 820 480 C 870 530 830 680 700 720 C 610 740 560 670 585 590 C 600 530 640 510 700 500", fill: "none", stroke: MARK, "stroke-width": 8, "stroke-linecap": "round" }, this.svg);
    this.clen = this.circ.getTotalLength(); this.circ.style.strokeDasharray = this.clen;
    /* sticky notes: what the human chose */
    const notes = ["알바 퀘스트 연작", "턴제 + 설득", "EarthBound 톤"];
    this.notes = notes.map((t, i) => {
      const n = h("div", "a px", this.root, t);
      css(n, { left: 930 + i * 300 + "px", top: 905 + (i % 2) * 14 + "px", width: "270px", height: "120px", background: C.amber, color: INK, fontSize: "36px", fontWeight: 700,
        display: "flex", alignItems: "center", justifyContent: "center", textAlign: "center", boxShadow: "6px 6px 0 rgba(27,26,36,.25)" });
      return n;
    });
    this.nl = h("div", "a px", this.root, "사람이 고른 것 ↓");
    css(this.nl, { left: "930px", top: "880px", fontSize: "28px", color: MARK, fontWeight: 700 });
    this.big = h("div", "a", this.root, "승인");
    css(this.big, { left: "1180px", top: "380px", fontFamily: DISP, fontSize: "240px", lineHeight: "1", color: MARK, border: `16px solid ${MARK}`, padding: "10px 40px", transformOrigin: "50% 50%", opacity: 0, background: "rgba(251,247,234,.6)" });
    this.cy = h("div", "full", this.root);
    css(this.cy, { background: C.cyan, transformOrigin: "50% 0%" });
  },
  render(lt) {
    css(this.cy, { transform: `scaleY(${1 - prog(lt, 0, 0.3, ease.swift)})` });
    this.st.forEach((o, i) => {
      const p = prog(lt, 0.5 + i - 0.12, 0.18, ease.snap);
      css(o.row, { opacity: p > 0.001 ? 1 : 0, transform: `rotate(${this.rot[i]}deg) scale(${lerp(1.7, 1, p)})`, transformOrigin: "190px 56px" });
    });
    this.dots.forEach(([d, i, k]) => {
      const q = prog(lt, 0.5 + i - 0.02, 0.5, ease.outQuint);
      const a = (Math.PI * 2 * k) / 10 + i, r = q * (140 + (k % 3) * 40);
      css(d, { opacity: q > 0.001 && q < 1 ? 1 - q : 0, left: 310 + Math.cos(a) * r + "px", top: 186 + i * 150 + Math.sin(a) * r + "px", transform: `scale(${1 - q * 0.6})` });
    });
    stepIn(this.doc, prog(lt, 0.3, 0.4, ease.snap), 160, 0);
    css(this.doc, { transform: `rotate(-1deg) translate(${(1 - Math.ceil(clamp(prog(lt, 0.3, 0.4, ease.snap), 0, 1) * 3) / 3) * 160}px, 0px)` });
    const n = Math.floor(prog(lt, 1.0, 3.0, ease.linear) * DATA.pitch.length);
    this.pitch.textContent = DATA.pitch.slice(0, n);
    this.mvp.forEach((r, i) => stepIn(r, prog(lt, 4.0 + 0.33 * i, 0.2, ease.snap), 40, 0));
    const c = prog(lt, 6.0, 0.5, ease.linear);
    this.num.textContent = String(Math.round(c * 6));
    css(this.num, { opacity: lt >= 6.0 ? 1 : 0 });
    css(this.numl, { opacity: lt >= 6.0 ? 1 : 0 });
    this.circ.style.strokeDashoffset = this.clen * (1 - prog(lt, 6.6, 0.4, ease.swift));
    this.notes.forEach((nt, i) => {
      const p = prog(lt, 4.6 + 0.4 * i, 0.2, ease.snap);
      css(nt, { opacity: p > 0.001 ? 1 : 0, transform: `rotate(${[-3, 2, -2][i]}deg) scale(${lerp(1.5, 1, p)})` });
    });
    css(this.nl, { opacity: lt >= 4.6 ? 1 : 0 });
    const sp = prog(lt, 6.85, 0.2, ease.snap);
    css(this.big, { opacity: sp > 0.001 ? 1 : 0, transform: `rotate(-12deg) scale(${lerp(3.2, 1, sp)})` });
    const jit = lt >= 7.0 && lt < 7.25 ? (Math.floor(lt * 30) % 2 ? 10 : -10) : 0;
    css(this.doc, { transform: `rotate(-1deg) translate(${jit}px, ${jit / 2}px)` });
    const ex = prog(lt, 7.98, 0.4, ease.swift);
    css(this.root, { transform: `translateY(${-ex * 30}%)` });
  },
});

/* S3 뼈대 (16-24s): the six stories deal like cards, the tests go green, and the gate says no thirty times */
REEL.scene({
  id: "s03", start: B("s03"), end: B("s04") + 0.4,
  setup(el) {
    this.root = h("div", "full", el);
    css(this.root, { background: C.bg2 });
    const tex = h("div", "full", this.root);
    css(tex, { background: "repeating-linear-gradient(0deg, rgba(255,255,255,.03) 0 2px, transparent 2px 8px)" });
    this.chip = makeChip(this.root, 120, 44, "/create-stories", "Godot 4.7 · gdUnit4", C.amber);
    this.cards = DATA.stories.map((t, i) => {
      const c = h("div", "a", this.root);
      css(c, { left: 150 + i * 270 + "px", top: "150px", width: "240px", height: "330px", background: C.panel, border: `5px solid ${C.steel}`, boxSizing: "border-box", boxShadow: "8px 8px 0 #0b0a10" });
      const nn = h("div", "a px", c, "00" + (i + 1)); css(nn, { left: "20px", top: "18px", fontSize: "44px", fontWeight: 700, color: C.amber });
      const tt = h("div", "a px", c, t); css(tt, { left: "20px", top: "92px", width: "200px", fontSize: "34px", lineHeight: "1.3", color: C.text });
      const tag = h("div", "a px", c, ["Logic", "Logic", "Integration", "Logic", "Integration", "Logic"][i]);
      css(tag, { left: "20px", top: "276px", fontSize: "28px", color: C.cyan });
      const ok = h("div", "a px", c, "✓"); css(ok, { left: "186px", top: "14px", fontSize: "48px", fontWeight: 700, color: C.mint, opacity: 0 });
      c._ok = ok;
      return c;
    });
    this.test = h("div", "a", this.root);
    css(this.test, { left: "150px", top: "560px", width: "1620px", height: "150px", background: C.panel, border: `5px solid ${C.steel}`, boxSizing: "border-box", boxShadow: "8px 8px 0 #0b0a10" });
    const tl = h("div", "a px", this.test, "gdUnit4"); css(tl, { left: "32px", top: "22px", fontSize: "40px", fontWeight: 700, color: C.text });
    this.tbar = h("div", "a", this.test); css(this.tbar, { left: "32px", top: "86px", width: "1000px", height: "34px", background: `repeating-linear-gradient(135deg, ${C.mint} 0 16px, #2fbfa3 16px 32px)`, transformOrigin: "0 50%", border: `3px solid ${C.ink}` });
    this.ring = h("div", "a", this.root);
    css(this.ring, { left: "860px", top: "535px", width: "200px", height: "200px", borderRadius: "50%", border: `10px solid ${C.mint}`, boxSizing: "border-box", opacity: 0 });
    this.tres = h("div", "a px", this.test, "1 / 1  PASSED"); css(this.tres, { left: "1070px", top: "20px", fontSize: "56px", fontWeight: 700, color: C.mint });
    this.ci = h("div", "a px", this.test, "CI ✓  GitHub Actions"); css(this.ci, { left: "1070px", top: "88px", fontSize: "34px", color: C.text });
    /* the gate */
    this.gate = h("div", "a", this.root);
    css(this.gate, { left: "150px", top: "780px", width: "1620px", height: "200px", background: "#2a1420", border: `5px solid ${C.red}`, boxSizing: "border-box" });
    const g1 = h("div", "a px", this.gate, "GateGuard — 새 파일은 사실부터 말하고 쓰세요"); css(g1, { left: "32px", top: "26px", fontSize: "42px", fontWeight: 700, color: C.text });
    this.g2 = h("div", "a px", this.gate, ""); css(this.g2, { left: "32px", top: "104px", fontSize: "40px", color: C.red });
    this.gok = h("div", "a px", this.gate, "다시 쓰기 ✓"); css(this.gok, { left: "1180px", top: "96px", fontSize: "56px", fontWeight: 700, color: C.mint });
    this.gc = h("div", "a px", this.root, "거부 0");
    css(this.gc, { left: "1480px", top: "716px", fontSize: "34px", color: C.red });
  },
  render(lt) {
    const pin = prog(lt, 0, 0.35, ease.swift);
    css(this.root, { transform: `translateY(${(1 - pin) * 100}%)` });
    this.cards.forEach((c, i) => {
      const p = prog(lt, 0.2 + 0.35 * i - 0.1, 0.3, ease.outBack);
      const fly = prog(lt, 6.7 + i * 0.07, 0.4, ease.exit);
      css(c, { opacity: p > 0.001 ? 1 : 0, transform: `translate(${(1 - p) * 700 + fly * 2300}px, ${(1 - p) * 500}px) rotate(${(1 - p) * 28 + fly * 6}deg)` });
      css(c._ok, { opacity: lt >= 3.2 + i * 0.1 ? 1 : 0 });
    });
    const t = prog(lt, 2.6, 0.5, ease.swift);
    css(this.test, { opacity: lt >= 2.6 ? 1 : 0, transform: `translateY(${(1 - t) * 40}px)` });
    css(this.tbar, { transform: `scaleX(${prog(lt, 2.8, 0.2, ease.linear)})`, backgroundPosition: `${Math.floor(lt * 12) * 10}px 0` });
    const rq = prog(lt, 3.0, 0.8, ease.outQuint);
    css(this.ring, { opacity: rq > 0 && rq < 1 ? 0.8 * (1 - rq) : 0, transform: `scale(${lerp(0.4, 10, rq)})` });
    css(this.tres, { opacity: lt >= 3.0 ? 1 : 0 });
    css(this.ci, { opacity: lt >= 3.1 ? 1 : 0 });
    /* the gate: denied x30, then through */
    const gp = prog(lt, 4.2, 0.3, ease.snap);
    const hit = lt >= 5.0 && lt < 5.12 ? (Math.floor(lt * 30) % 2 ? 12 : -12) : 0;
    css(this.gate, { opacity: gp > 0.001 ? 1 : 0, transform: `translate(${hit}px, ${(1 - gp) * 40}px)` });
    const cnt = Math.round(clamp((lt - 4.8) / 0.7, 0, 1) * 30);
    this.g2.textContent = lt >= 4.8 && lt < 6.4 ? `거부 ×${cnt}  — 파일 이름, 호출하는 곳, 사용자의 말을 먼저 적으세요` : "";
    css(this.gok, { opacity: lt >= 6.5 ? 1 : 0 });
    const flick = lt >= 4.8 && lt < 6.4 && Math.floor(lt * 12) % 2 === 0;
    css(this.gate, { borderColor: flick ? "#ffb0c0" : C.red });
    css(this.gc, { opacity: 0 });
    css(this.root, { transform: `translateY(${(1 - pin) * 100}%)` });
  },
});
