/* S7 모션·사운드 (48-56s): one sentence from the human, then real frames and the real waveforms of the sounds the code synthesized */
const LANES = [["hit", C.amber, [1.0, 2.0]], ["persuade", C.violet, [4.0]], ["guard", C.mint, [5.0]], ["power_down", C.red, [7.2]]];
REEL.scene({
  id: "s07", start: B("s07"), end: B("s08") + 0.05,
  setup(el) {
    this.root = h("div", "full", el);
    css(this.root, { background: "#08070c" });
    const tex = h("div", "full", this.root);
    css(tex, { background: "repeating-linear-gradient(0deg, rgba(255,255,255,.03) 0 2px, transparent 2px 8px)" });
    this.qwrap = h("div", "a", this.root);
    css(this.qwrap, { left: "110px", top: "130px", transformOrigin: "0 0" });
    const tag = h("div", "a px", this.qwrap, "사람의 한마디");
    css(tag, { left: "0px", top: "-70px", background: C.amber, color: C.ink, fontSize: "32px", fontWeight: 700, padding: "6px 16px", whiteSpace: "nowrap" });
    this.q1 = h("div", "a", this.qwrap, "너무 모션도 없고,"); css(this.q1, { left: "0px", top: "0px", fontFamily: DISP, fontSize: "120px", lineHeight: "1.1", whiteSpace: "nowrap", color: C.text });
    this.q2 = h("div", "a", this.qwrap, "사운드도 없네요."); css(this.q2, { left: "0px", top: "135px", fontFamily: DISP, fontSize: "120px", lineHeight: "1.1", whiteSpace: "nowrap", color: C.amber });
    this.c1 = split(this.q1, "char", { mask: true });
    this.c2 = split(this.q2, "char", { mask: true });
    /* code panel */
    this.code = h("div", "a", this.root);
    css(this.code, { left: "980px", top: "100px", width: "900px", height: "236px", background: C.panel, border: `5px solid ${C.steel}`, boxSizing: "border-box", boxShadow: "8px 8px 0 #0b0a10" });
    this.ch = h("div", "a px", this.code, ""); css(this.ch, { left: "26px", top: "16px", fontSize: "30px", fontWeight: 700, color: C.mint });
    this.cl = [0, 1, 2].map((i) => { const l = h("div", "a px", this.code, ""); css(l, { left: "26px", top: 70 + i * 52 + "px", fontSize: "28px", color: C.text, whiteSpace: "nowrap" }); return l; });
    /* filmstrip */
    const caps = ["돌진 · 흰 번쩍임", "게이지 잔상", "설득 +35", "결과 배너", "깜빡이며 퇴장"];
    this.frames = caps.map((cp, i) => {
      const f = h("div", "a", this.root);
      css(f, { left: 20 + i * 380 + "px", top: "430px", width: "360px", height: "203px", border: `5px solid ${C.steel}`, boxSizing: "border-box", overflow: "hidden", background: "#000" });
      const im = REEL.img(`../assets/img/ev_fx${i + 1}.png`);
      css(im, { position: "absolute", left: "0px", top: "0px", width: "350px", height: "193px" });
      f.appendChild(im);
      const c = h("div", "a px", this.root, cp);
      css(c, { left: 20 + i * 380 + "px", top: "642px", width: "360px", fontSize: "30px", color: C.text, textAlign: "center" });
      return { f, c };
    });
    this.fric = h("div", "a px", this.root, "첫 배너가 바닥에 먼저 떴다 → 한 프레임 기다리게 고침");
    css(this.fric, { left: "560px", top: "694px", width: "880px", fontSize: "32px", fontWeight: 700, color: C.ink, background: C.amber, padding: "8px 18px", boxShadow: "6px 6px 0 #0b0a10", whiteSpace: "nowrap" });
    this.cv = h("canvas", "a", this.root); this.cv.width = 1880; this.cv.height = 290;
    css(this.cv, { left: "20px", top: "770px", width: "1880px", height: "290px" });
    this.chip = makeChip(this.root, 980, 36, "/dev-story", "gameplay-programmer", C.amber);
    this.fx = h("div", "full", this.root);
  },
  render(lt) {
    const pin = prog(lt, 0, 0.4, ease.swift);
    css(this.root, { transform: `translateX(${(1 - pin) * 100}%)`, opacity: 1 - prog(lt, 7.62, 0.35, ease.exit) });
    /* the sentence slams, then docks top-left */
    [this.c1, this.c2].forEach((cs, k) => cs.forEach((c, i) => {
      const p = stagger(lt, 0.45 + k * 0.5, 0.04, 0.35, i, ease.snap);
      css(c, { transform: `translateY(${(1 - p) * 135}%)`, opacity: p > 0 ? 1 : 0 });
    }));
    const dock = prog(lt, 1.9, 0.5, ease.swift);
    css(this.qwrap, { transform: `translate(${-dock * 50}px, ${-dock * 50}px) scale(${lerp(1, 0.36, dock)})`, opacity: lt < 0.4 ? 0 : 1 });
    css(this.chip, { opacity: lt >= 2.0 ? 1 : 0 });
    /* code panel: two real snippets */
    const first = lt < 4.2;
    const lines = first ? DATA.fx_code : DATA.sfx_code;
    this.ch.textContent = first ? "battle_fx.gd" : "make_chiptune.py";
    const t0 = first ? 2.1 : 4.3;
    this.cl.forEach((l, i) => {
      const n = Math.floor(prog(lt, t0 + i * 0.3, 0.3, ease.linear) * lines[i].length);
      l.textContent = lines[i].slice(0, n);
    });
    css(this.code, { opacity: lt >= 2.0 ? 1 : 0 });
    /* filmstrip */
    [1.0, 2.0, 3.5, 5.0, 6.0].forEach((t, i) => {
      const p = prog(lt, t - 0.15, 0.25, ease.snap);
      const o = this.frames[i];
      css(o.f, { opacity: p > 0.001 ? 1 : 0, transform: `translateY(${(1 - p) * 60}px) rotate(${(1 - p) * 3}deg)` });
      css(o.c, { opacity: lt >= t + 0.1 ? 1 : 0 });
    });
    css(this.fric, { opacity: lt >= 6.4 && lt < 7.6 ? 1 : 0 });
    /* waveforms of the real sound files */
    const ctx = this.cv.getContext("2d");
    ctx.clearRect(0, 0, 1880, 290);
    ctx.font = `30px ${PX}`;
    LANES.forEach(([name, col, trig], li) => {
      const x0 = li * 470;
      const wav = DATA.wave[name];
      const last = trig.filter((t) => t <= lt).pop();
      ctx.fillStyle = last === undefined ? "#4a4860" : C.text;
      ctx.fillText(`${name}.wav`, x0, 34);
      const prog_ = last === undefined ? 0 : clamp((lt - last) / 0.5, 0, 1);
      const playing = last !== undefined && lt - last < 0.5;
      for (let b = 0; b < 64; b++) {
        const hh = Math.max(8, Math.round(wav[b] * 170 / 8) * 8);
        const on = last !== undefined && b / 64 <= prog_;
        ctx.fillStyle = on ? (playing && Math.abs(b / 64 - prog_) < 0.04 ? "#fff" : col) : "#2a2838";
        ctx.fillRect(x0 + b * 6.6, 160 - hh / 2 + 30, 5, hh);
      }
    });
  },
});

/* S8 이야기 (56-64s): the second human sentence, a real YAML file, and the prologue it turned into, in the rain */
REEL.scene({
  id: "s08", start: B("s08"), end: B("s09"),
  setup(el) {
    this.root = h("div", "full", el);
    css(this.root, { background: "#0e1230" });
    this.rain = h("canvas", "a", this.root); this.rain.width = W; this.rain.height = H;
    css(this.rain, { left: "0px", top: "0px", width: W + "px", height: H + "px" });
    this.chip = makeChip(this.root, 110, 44, "/team-narrative", "writer", C.cyan);
    const tag = h("div", "a px", this.root, "사람의 한마디");
    css(tag, { left: "110px", top: "130px", background: C.amber, color: C.ink, fontSize: "32px", fontWeight: 700, padding: "6px 16px" });
    this.q = h("div", "a", this.root, "");
    css(this.q, { left: "110px", top: "200px", width: "760px", fontFamily: SERIF, fontWeight: 700, fontSize: "54px", lineHeight: "1.4", color: C.text });
    this.yp = h("div", "a", this.root);
    css(this.yp, { left: "110px", top: "560px", width: "720px", height: "420px", background: "rgba(20,18,26,.85)", border: `4px solid ${C.band}`, boxSizing: "border-box" });
    const yh = h("div", "a", this.yp, "design/narrative/dialogue/prologue.md"); css(yh, { left: "22px", top: "14px", fontFamily: MONO, fontSize: "22px", color: C.dim });
    this.yl = DATA.yaml.map((t, i) => { const l = h("div", "a px", this.yp, t); css(l, { left: "22px", top: 56 + i * 44 + "px", fontSize: "28px", color: t.trim().startsWith("-") ? C.mint : C.text, whiteSpace: "pre" }); return l; });
    /* the game's own dialogue box: the one lit thing */
    this.box = h("div", "a", this.root);
    css(this.box, { left: "930px", top: "330px", width: "880px", height: "400px", background: C.bg2, border: `6px solid ${C.cyan}`, boxSizing: "border-box", boxShadow: `0 0 60px ${C.cyan}66, 10px 10px 0 #0b0a10` });
    this.nm = h("div", "a px", this.box, ""); css(this.nm, { left: "-6px", top: "-62px", background: C.cyan, color: C.ink, fontSize: "36px", fontWeight: 700, padding: "8px 22px" });
    this.tx = h("div", "a px", this.box, ""); css(this.tx, { left: "40px", top: "50px", width: "800px", fontSize: "44px", lineHeight: "1.5", color: C.text });
    this.mk = h("div", "a px", this.box, "▼"); css(this.mk, { left: "790px", top: "330px", fontSize: "40px", color: C.cyan });
    this.flash = h("div", "full", this.root);
    css(this.flash, { background: "#c8d8ff", opacity: 0 });
    this.cap = h("div", "a px", this.root, "게임 속 대화창");
    css(this.cap, { left: "930px", top: "760px", fontSize: "34px", color: C.cyan });
  },
  render(lt) {
    css(this.root, { opacity: lt < 0.3 ? prog(lt, 0, 0.3, ease.linear) : 1 - prog(lt, 7.72, 0.28, ease.exit) });
    css(this.flash, { opacity: (lt >= 1.0 && lt < 1.1) || (lt >= 4.1 && lt < 4.2) || (lt >= 6.5 && lt < 6.6) ? 0.12 : 0 });
    /* rain: every drop is a pure function of time */
    const ctx = this.rain.getContext("2d");
    ctx.clearRect(0, 0, W, H);
    ctx.strokeStyle = "rgba(170,195,255,.38)"; ctx.lineWidth = 3;
    ctx.beginPath();
    for (let i = 0; i < 240; i++) {
      const sp = 900 + rand(i, 2) * 800, ln = 40 + rand(i, 3) * 70, x0 = rand(i, 4) * (W + 600);
      const y = ((rand(i, 5) * (H + ln) + q12(lt) * sp) % (H + ln)) - ln;
      const x = x0 - y * 0.25 - 200;
      ctx.moveTo(x, y); ctx.lineTo(x - ln * 0.25, y + ln);
    }
    ctx.stroke();
    /* the quote types out */
    const full = "스토리도 갑자기.. 전투로 시작하지 말고.. 좀 맥락이 있어야하지 않나?";
    const n = Math.floor(prog(lt, 0.4, 2.2, ease.linear) * full.length);
    this.q.textContent = full.slice(0, n);
    css(this.q, { opacity: 1 });
    /* the YAML file */
    css(this.yp, { opacity: lt >= 2.6 ? 1 : 0 });
    this.yl.forEach((l, i) => css(l, { opacity: lt >= 2.8 + i * 0.28 ? 1 : 0 }));
    /* the dialogue box types the prologue */
    const times = [3.0, 4.4, 5.3, 6.6];
    const ends = [4.3, 5.2, 6.5, 8.0];
    let k = -1; times.forEach((t, i) => { if (lt >= t) k = i; });
    css(this.box, { opacity: k >= 0 ? 1 : 0 });
    css(this.cap, { opacity: k >= 0 ? 1 : 0 });
    if (k >= 0) {
      const [who, text] = DATA.prologue[k];
      this.nm.textContent = who;
      css(this.nm, { opacity: who === "환경" || who === "내레이션" ? 0.0 : 1 });
      const m = Math.floor(prog(lt, times[k], Math.min(1.1, text.length / 40), ease.linear) * text.length);
      this.tx.textContent = text.slice(0, m);
      css(this.mk, { opacity: lt > times[k] + 1.0 && blink(lt) ? 1 : 0 });
    }
  },
});

/* S9 수렴 (64-76s): three sentences, the commit timeline, the studio lights up, and the end card */
REEL.scene({
  id: "s09", start: B("s09"), end: 76,
  setup(el) {
    this.root = h("div", "full", el);
    css(this.root, { background: C.ink });
    const tex = h("div", "full", this.root);
    css(tex, { background: "repeating-linear-gradient(0deg, rgba(255,255,255,.028) 0 2px, transparent 2px 8px)" });
    this.stm = [["사람이 정하고", C.text], ["에이전트가 쓰고", C.cyan], ["증거가 닫는다", C.amber]].map(([t, col], i) => {
      const d = h("div", "a", this.root, t);
      css(d, { left: "120px", top: 150 + i * 230 + "px", fontFamily: DISP, fontSize: "170px", lineHeight: "1.05", whiteSpace: "nowrap", color: col, transformOrigin: "0 0" });
      return d;
    });
    this.cm = DATA.commits.map((t, i) => {
      const d = h("div", "a px", this.root, "✓ " + t);
      css(d, { left: "800px", top: 130 + i * 62 + "px", fontSize: "30px", color: C.text, whiteSpace: "nowrap" });
      return d;
    });
    this.n1 = h("div", "a", this.root, "0"); css(this.n1, { left: "120px", top: "770px", fontFamily: DISP, fontSize: "170px", lineHeight: "1", color: C.amber });
    this.n1l = h("div", "a px", this.root, "증거 스크린샷"); css(this.n1l, { left: "120px", top: "960px", fontSize: "40px", color: C.text });
    this.n2 = h("div", "a", this.root, "0"); css(this.n2, { left: "620px", top: "770px", fontFamily: DISP, fontSize: "170px", lineHeight: "1", color: C.cyan });
    this.n2l = h("div", "a px", this.root, "커밋"); css(this.n2l, { left: "620px", top: "960px", fontSize: "40px", color: C.text });
    this.G = makeGrid(this.root);
    css(this.G.g, { transformOrigin: "960px 540px" });
    this.order = [...Array(49).keys()].sort((a, b) => rand(a, 9) - rand(b, 9));
    this.gcap = h("div", "center px", this.root, "불 켜진 칸이 하나씩 늘어난다");
    css(this.gcap, { top: "930px", fontSize: "50px", color: C.cyan });
    /* end card */
    this.end = h("div", "full", this.root);
    css(this.end, { background: C.ink });
    this.logo = REEL.img("../assets/img/logo.png");
    css(this.logo, { position: "absolute", left: "320px", top: "50px", width: "1280px", height: "417px", imageRendering: "pixelated" });
    this.end.appendChild(this.logo);
    this.e1 = h("div", "center px", this.end, "구현 가능성 확인 ✓"); css(this.e1, { top: "500px", fontSize: "64px", fontWeight: 700, color: C.cyan });
    this.e2 = h("div", "center px", this.end, "프롤로그 + 의뢰 1, 지금 플레이할 수 있다"); css(this.e2, { top: "590px", fontSize: "50px", color: C.text });
    this.e3 = h("div", "center px", this.end, "나머지 이야기는 이미지 슬라이드로"); css(this.e3, { top: "665px", fontSize: "42px", color: C.dim });
    this.e4 = h("div", "center px", this.end, "Claude Code Game Studios"); css(this.e4, { top: "770px", fontSize: "44px", fontWeight: 700, color: C.text });
    this.e5 = h("div", "center", this.end, "영감: Adrian Tchaikovsky, Service Model"); css(this.e5, { top: "838px", fontSize: "32px", fontWeight: 500, color: C.dim });
    this.e6 = h("div", "center px", this.end, "정식으로 납부한 것입니다."); css(this.e6, { top: "895px", fontSize: "34px", color: C.amber });
  },
  render(lt) {
    /* 0-3: the three sentences land on the downbeats */
    this.stm.forEach((d, i) => {
      const p = prog(lt, i - 0.25, 0.3, ease.snap);
      const dock = prog(lt, 3.0, 0.5, ease.swift);
      const y0 = 150 + i * 230, y1 = 110 + i * 105;
      const beat = lt > i + 0.3 && lt < 3.0 ? 0.04 * Math.max(0, 1 - ((lt * 2) % 1) * 3) : 0;
      css(d, { opacity: p > 0.001 ? 1 : 0, transform: `translate(${lerp(0, 0, dock)}px, ${lerp(0, y1 - y0, dock)}px) scale(${(lerp(1.6, 1, p) + beat) * lerp(1, 0.55, dock)})`, filter: `blur(${(1 - p) * 14}px)` });
    });
    /* 3-6: commits tick in, counters */
    this.cm.forEach((d, i) => css(d, { opacity: lt >= 3.5 + i * 0.26 && lt < 6.0 ? 1 : 0 }));
    css(this.n1, { opacity: lt >= 5.0 && lt < 6.0 ? 1 : 0 }); css(this.n1l, { opacity: lt >= 5.0 && lt < 6.0 ? 1 : 0 });
    css(this.n2, { opacity: lt >= 5.0 && lt < 6.0 ? 1 : 0 }); css(this.n2l, { opacity: lt >= 5.0 && lt < 6.0 ? 1 : 0 });
    this.n1.textContent = String(Math.round(prog(lt, 5.0, 0.5, ease.outQuart) * DATA.evidence_count));
    this.n2.textContent = String(Math.round(prog(lt, 5.0, 0.5, ease.outQuart) * DATA.commits.length));
    const gone = lt >= 6.0;
    this.stm.forEach((d) => { if (gone) css(d, { opacity: 0 }); });
    /* 6-8 (the music breaks): the studio comes back and tiles light one by one */
    css(this.G.g, { opacity: lt >= 6.0 ? 1 : 0, transform: `scale(${lerp(1.5, 1, prog(lt, 6.0, 0.8, ease.swift))})` });
    const lit = Math.floor(prog(lt, 6.4, 1.4, ease.linear) * 16);
    this.order.forEach((ti, r) => lightTile(this.G.tiles[ti], lt >= 6.0 && r < lit, r % 3 === 1 ? C.amber : C.cyan));
    css(this.gcap, { opacity: lt >= 6.9 && lt < 8.0 ? 1 : 0 });
    /* 8-12: the end card */
    css(this.end, { opacity: lt >= 8.0 ? 1 : 0 });
    const lp = prog(lt, 8.0, 0.5, ease.outBack);
    css(this.logo, { transform: `scale(${lerp(0.6, 1, lp)})`, opacity: lp > 0.001 ? 1 : 0 });
    [[this.e1, 8.7], [this.e2, 9.3], [this.e3, 9.9], [this.e4, 10.4], [this.e5, 10.7], [this.e6, 11.1]].forEach(([e, t]) => {
      stepIn(e, prog(lt, t, 0.25, ease.snap), 0, 20);
    });
  },
});
