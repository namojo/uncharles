"""Copies the real footage, fonts and data the making-of reel uses into the showreel project.

Usage:  python tools/making/prep_assets.py <project-dir>
Reads:  production/qa/evidence/**, assets/art/**, assets/fonts/galmuri/*, assets/audio/sfx/*.wav, git history
Writes: <project>/assets/img/*.png, <project>/reel/fonts/Galmuri*.ttf + fonts_game.css, <project>/reel/data.js
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]

IMAGES = {
    "logo": "assets/art/ui/logo_uncharles.png",
    "charles": "assets/art/battle/charles.png",
    "frosty": "assets/art/battle/frosty.png",
    "kitchen": "assets/art/backgrounds/kitchen.png",
    "agency_night": "assets/art/backgrounds/agency_night.png",
    "ev_grey_start": "production/qa/evidence/story-001-battle-persuade/01-greybox-battle-start.png",
    "ev_grey_win": "production/qa/evidence/story-001-battle-persuade/02-greybox-persuaded.png",
    "ev_sprites": "production/qa/evidence/story-001-battle-persuade/03-sprites-battle.png",
    "ev_styled": "production/qa/evidence/story-001-battle-persuade/06-styled-battle.png",
    "ev_title": "production/qa/evidence/title-screen/01-title.png",
    "ev_m_title": "production/qa/evidence/web-mobile/01-mobile-title.png",
    "ev_m_battle": "production/qa/evidence/web-mobile/02-mobile-battle-tap.png",
    "ev_m_result": "production/qa/evidence/web-mobile/03-mobile-result.png",
    "ev_m_portrait": "production/qa/evidence/web-mobile/05-mobile-portrait-hint.png",
    "ev_fx1": "production/qa/evidence/battle-feel/01-attack-flash-number.png",
    "ev_fx2": "production/qa/evidence/battle-feel/02-hp-afterimage.png",
    "ev_fx3": "production/qa/evidence/battle-feel/03-persuade-number.png",
    "ev_fx4": "production/qa/evidence/battle-feel/04-persuade-win.png",
    "ev_fx5": "production/qa/evidence/battle-feel/05-knockout-win.png",
}


def peaks(path: Path, n: int = 64) -> list[float]:
    with wave.open(str(path)) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float) / 32768
    chunk = max(1, len(x) // n)
    p = [float(np.abs(x[i * chunk:(i + 1) * chunk]).max()) for i in range(n)]
    top = max(p) or 1.0
    return [round(v / top, 3) for v in p]


def game_commits() -> list[str]:
    """Subjects of this game's own commits (the repo also carries the framework's history below them)."""
    out = subprocess.run(["git", "log", "--reverse", "--format=%s"], cwd=ROOT, capture_output=True, text=True,
                         encoding="utf-8").stdout.splitlines()
    start = next(i for i, s in enumerate(out) if s.startswith("docs: add Uncharles game brief"))
    return out[start:]


def main() -> None:
    proj = Path(sys.argv[1]).resolve()
    img = proj / "assets" / "img"
    img.mkdir(parents=True, exist_ok=True)
    for name, rel in IMAGES.items():
        shutil.copyfile(ROOT / rel, img / f"{name}.png")
    fonts = proj / "reel" / "fonts"
    for f in ("Galmuri11.ttf", "Galmuri11-Bold.ttf"):
        shutil.copyfile(ROOT / "assets" / "fonts" / "galmuri" / f, fonts / f)
    (fonts / "fonts_game.css").write_text(
        '@font-face { font-family: "Galmuri11"; src: url("Galmuri11.ttf") format("truetype"); font-weight: 400; font-display: block; }\n'
        '@font-face { font-family: "Galmuri11"; src: url("Galmuri11-Bold.ttf") format("truetype"); font-weight: 700; font-display: block; }\n',
        encoding="utf-8")
    sfx = ROOT / "assets" / "audio" / "sfx"
    evidence = sum(1 for p in (ROOT / "production" / "qa" / "evidence").rglob("*.png") if "raw" not in p.parts)
    data = {
        "pitch": "주인에게 버림받은 안드로이드 집사 찰스가 로봇 직업소개소의 알바를 전전하며 인간 주인들의 블랙코미디 같은 사연을 해결하고, 자신을 사랑해 줄 단 한 명의 주인을 고르는(혹은 고르지 않는) B급 도트 RPG.",
        "mvp": ["도트 탐험 + 소개소 허브", "턴제 전투 + 설득 커맨드", "대사·선택지 시스템 + 주인별 호감도",
                "알바 의뢰 3건", "폐기 처리장 재부팅", "엔딩 4종"],
        "stories": ["턴제 전투 + 설득 커맨드", "대사·선택지 + 주인별 호감도", "도트 탐험 + 소개소 허브",
                    "폐기 처리장 재부팅", "알바 의뢰 3건", "엔딩 4종"],
        "commits": game_commits(),
        "evidence_count": evidence,
        "wave": {n: peaks(sfx / f"{n}.wav") for n in ("hit", "persuade", "victory", "power_down", "hurt", "guard")},
        "fx_code": ["const SHAKE_OFFSETS: Array[int] = [6, -6, 4, -4, 2, 0]",
                    "const SHAKE_STEP_SEC: float = 0.04",
                    "const FLASH_SEC: float = 0.08"],
        "sfx_code": ["hit = noise(0.16, 2, hold=3) * env(0.16, release=0.12) * 0.7",
                     "hit += square(sweep(420, 70, 0.16), 0.16) * env(0.16) * 0.6",
                     "out[\"hit\"] = (crush(hit, 4, 2), 0.8)"],
        "yaml": ["- id: prologue_02", "  speaker: 환경", "  text: '[알림] 고객님의 집사 구독이", "    해지되었습니다.'",
                 "  next: prologue_03", "- id: prologue_03", "  speaker: 찰스",
                 "  text: '이 문자의 수신자는 저입니다.'"],
        "prologue": [["환경", "[알림] 고객님의 집사 구독이 해지되었습니다."],
                     ["환경", "해지 사유: 그냥요."],
                     ["찰스", "오발송이 아닙니다. \"그냥요\"는 접수 가능한 사유입니다."],
                     ["내레이션", "찰스는 스티커를 등에 붙였다. 손이 닿지 않아 벽에 등을 대고 붙였다."]],
        "palette": [["#14121a", "배경"], ["#1b1a24", "패널"], ["#8a90a6", "강철"], ["#e8e6f0", "글자"],
                    ["#3fe0e8", "켜진 색"], ["#f2c94c", "보상"], ["#ff4d6d", "위험"], ["#43e0c0", "배터리"],
                    ["#d9583a", "적 HP"], ["#b58cff", "설득"]],
    }
    (proj / "reel" / "data.js").write_text("window.DATA = " + json.dumps(data, ensure_ascii=False) + ";\n", encoding="utf-8")
    print(f"{len(IMAGES)} images, fonts, data.js ({len(data['commits'])} commits, {evidence} evidence images)")


if __name__ == "__main__":
    main()
