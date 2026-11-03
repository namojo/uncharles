/* S1 해지 (0-8s): Hangul IME typing, the cancellation text, logo dissolve, pull back to the studio grid, zoom into the lit tile */
const LOGO_SCALE = 1780 / 80;
REEL.scene({
  id: "s01", start: 0, end: B("s02"),
  setup(el) {
    const grid = h("div", "full", el);
    css(grid, { background: "repeating-linear-gradient(0deg, rgba(255,255,255,.028) 0 2px, transparent 2px 8px)" });
    this.zoom = h("div", "full", el);
    this.G = makeGrid(this.zoom);
    css(this.G.g, { transformOrigin: "960px 540px" });
    this.logoImg = REEL.img("../assets/img/logo.png");
    this.lc = h("canvas", "a", this.G.g);
    this.lc.width = 356; this.lc.height = 116;
    const cc = this.G.center(24);
    css(this.lc, { left: cc.x - 40 + "px", top: cc.y - 13 + "px", width: "80px", height: "26px", imageRendering: "pixelated" });
    css(this.G.tiles[24], { background: C.ink });
    /* typed name + scribbled UN */
    this.name = h("div", "center px", el, "");
    css(this.name, { top: "330px", fontSize: "300px", fontWeight: 700, lineHeight: "1.1" });
    this.un = h("div", "a px", el, "UN");
    css(this.un, { left: "520px", top: "250px", fontSize: "190px", fontWeight: 700, color: C.cyan, transform: "rotate(-8deg)" });
    this.svg = s("svg", { width: W, height: H, viewBox: `0 0 ${W} ${H}` }, el);
    css(this.svg, { position: "absolute", left: "0px", top: "0px" });
    this.slash = s("path", { d: "M 640 470 C 800 400 1000 440 1290 395 M 700 560 C 900 520 1100 560 1250 505", fill: "none", stroke: C.cyan, "stroke-width": 14, "stroke-linecap": "square" }, this.svg);
    this.slen = this.slash.getTotalLength(); this.slash.style.strokeDasharray = this.slen;
    /* cancellation text card */
    this.card = h("div", "a", el);
    css(this.card, { left: "430px", top: "700px", width: "1060px", height: "200px", background: C.panel, border: `6px solid ${C.steel}`, boxSizing: "border-box", boxShadow: "8px 8px 0 #0b0a10" });
    this.c1 = h("div", "a px", this.card, "[알림] 고객님의 집사 구독이 해지되었습니다.");
    css(this.c1, { left: "36px", top: "36px", fontSize: "44px", color: C.text, whiteSpace: "nowrap" });
    this.c2 = h("div", "a px", this.card, "기기는 문 앞에 내놓아 주세요.");
    css(this.c2, { left: "36px", top: "108px", fontSize: "44px", color: C.cyan, whiteSpace: "nowrap" });
    this.sub = h("div", "center px", el, "");
    css(this.sub, { top: "880px", fontSize: "62px", color: C.text });
    this.sub2 = h("div", "center px", el, "사람 1  ·  에이전트 49");
    css(this.sub2, { top: "972px", fontSize: "40px", color: C.amber });
    this.rule = h("div", "center px", el, "한 번에 한 칸만 켜진다");
    css(this.rule, { top: "905px", fontSize: "52px", color: C.cyan });
    this.cut = h("div", "full", el);
    css(this.cut, { background: C.cyan, opacity: 0 });
  },
  render(lt) {
    /* 0.5-1.5: IME typing 찰스, cursor blinks */
    const seq = imeSeq("찰스");
    const k = clamp(Math.floor((lt - 0.5) / 0.25) + 1, 0, seq.length);
    const cur = blink(lt, 0.8) ? `<span style="color:${C.cyan}">▍</span>` : " ";
    this.name.innerHTML = (k ? seq[k - 1] : "") + (lt < 3.3 ? cur : "");
    const nameOut = prog(lt, 3.2, 0.3, ease.exit);
    css(this.name, { color: lt > 2.5 ? C.dim : C.text, opacity: 1 - nameOut, transform: `translateY(${-nameOut * 80}px)` });
    /* 2.0: the scribble and UN */
    this.slash.style.strokeDashoffset = this.slen * (1 - prog(lt, 2.0, 0.3, ease.swift));
    const un = prog(lt, 2.05, 0.4, ease.outBack);
    css(this.un, { opacity: lt >= 2.05 ? 1 - nameOut : 0, transform: `rotate(-8deg) scale(${lerp(0.4, 1, un)})` });
    css(this.svg, { opacity: 1 - nameOut });
    /* 2.5: the text message lands with a two-frame glitch */
    const cin = prog(lt, 2.5, 0.25, ease.snap);
    const glitch = lt >= 2.5 && lt < 2.6 ? (Math.floor(lt * 30) % 2 ? 14 : -14) : 0;
    const cout = prog(lt, 3.3, 0.3, ease.exit);
    css(this.card, { opacity: cin * (1 - cout), transform: `translate(${glitch}px, ${(1 - cin) * 60 + cout * 90}px)` });
    css(this.c1, { textShadow: glitch ? `${glitch > 0 ? 6 : -6}px 0 ${C.red}` : "none" });
    /* 3.5-4.6: logo pixel dissolve (canvas, native size) */
    if (this.logoImg.complete && lt > 3.4) {
      const ctx = this.lc.getContext("2d");
      if (!this.src) {
        const o = document.createElement("canvas"); o.width = 356; o.height = 116;
        o.getContext("2d").drawImage(this.logoImg, 0, 0, 356, 116);
        this.src = o.getContext("2d").getImageData(0, 0, 356, 116);
      }
      const p = prog(lt, 3.5, 1.1, ease.linear);
      const out = ctx.createImageData(356, 116);
      for (let i = 0; i < 356 * 116; i++) {
        const x = i % 356;
        const th = (x / 356) * 0.35 + rand(i, 5) * 0.65;
        const on = th < p * 1.35;
        const j = i * 4;
        out.data[j] = this.src.data[j]; out.data[j + 1] = this.src.data[j + 1]; out.data[j + 2] = this.src.data[j + 2];
        out.data[j + 3] = on ? this.src.data[j + 3] : 0;
      }
      ctx.putImageData(out, 0, 0);
    }
    /* 4.8-5.8 subtitle typed; 6.0 pull back from the logo to the whole studio */
    const full = "이 게임이 만들어진 과정";
    const n = Math.floor(prog(lt, 4.8, 1.0, ease.linear) * full.length);
    this.sub.textContent = full.slice(0, n) + (lt >= 4.8 && lt < 6.0 && blink(lt) ? "▍" : "");
    stepIn(this.sub2, prog(lt, 5.5, 0.3, ease.snap), 0, 24);
    const fade = prog(lt, 6.0, 0.25, ease.exit);
    css(this.sub, { opacity: 1 - fade });
    css(this.sub2, { opacity: (lt > 5.5 ? 1 : 0) * (1 - fade) });
    const pb = prog(lt, 6.0, 1.6, ease.swift);
    const sc = Math.exp(lerp(Math.log(LOGO_SCALE), 0, pb));
    css(this.G.g, { transform: `scale(${lt < 3.4 ? LOGO_SCALE : sc})` });
    css(this.zoom, { opacity: lt >= 3.4 ? 1 : 0 });
    /* 7.2: a tile lights up (2-frame flicker), 7.6-7.95 zoom through it */
    lightTile(this.G.tiles[25], lt >= 7.2 && !(lt >= 7.3 && lt < 7.4));
    const c25 = this.G.center(25);
    const z = prog(lt, 7.6, 0.35, ease.inExpo);
    css(this.zoom, { transformOrigin: `${c25.x}px ${c25.y}px`, transform: `scale(${1 + z * 70})` });
    stepIn(this.rule, prog(lt, 6.95, 0.3, ease.snap), 0, 24);
    css(this.rule, { opacity: (lt >= 6.95 ? 1 : 0) * (1 - prog(lt, 7.7, 0.2, ease.exit)) });
    css(this.cut, { opacity: lt >= 7.9 ? 1 : 0 });
  },
});
