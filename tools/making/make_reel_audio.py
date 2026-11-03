"""Composes the making-of reel's music (120 BPM chiptune, A minor) and writes the
sound-effect plan (script.json) used by the showreel skill's timeline/mix tools.

All sound is synthesized with the game's own generator (tools/audio/make_chiptune.py)
plus a few drum voices defined here, so there is no third-party audio.

Usage:  python tools/making/make_reel_audio.py <project-dir>
Writes: <project>/audio/music/music.wav, analysis.json, <project>/audio/sfx/*.wav, <project>/script.json
"""
from __future__ import annotations

import importlib.util
import json
import shutil
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SR = 44100
BPM = 120.0
BEAT = 60.0 / BPM          # 0.5 s
BAR = 4 * BEAT             # 2.0 s
STEP = BEAT / 2            # eighth note, 0.25 s
DURATION = 76.0
SFX_BOOST_DB = 6          # the effects sit under a busy chiptune bed; lift them (not the quiet rain section)

spec = importlib.util.spec_from_file_location("chip", ROOT / "tools" / "audio" / "make_chiptune.py")
chip = importlib.util.module_from_spec(spec)
spec.loader.exec_module(chip)
chip.RATE = SR             # the generator reads RATE at call time

CHORDS = {  # per-bar chord tones (arp) and bass root
    "Am": (["A3", "C4", "E4", "A4"], "A2"),
    "F": (["F3", "A3", "C4", "F4"], "F2"),
    "C": (["C4", "E4", "G4", "C5"], "C3"),
    "E": (["E3", "G#3", "B3", "E4"], "E2"),
}
PROGRESSION = ["Am", "F", "C", "E"]
ARP_IDX = [0, 1, 2, 3, 2, 1, 2, 3]
HOOK = [  # lead hook, one entry per eighth, per chord bar
    ["E5", None, "E5", "D5", "C5", None, "A4", None],
    ["C5", None, "A4", "C5", "F5", None, "E5", None],
    ["G5", None, "E5", "G5", "C6", None, "B5", None],
    ["B5", None, "G#5", None, "E5", None, "B4", None],
]
TITLE_LEAD = [None] * 4 + ["E5", None, "D5", "C5"] + ["A4"] + [None] * 7


def put(buf: np.ndarray, t: float, x: np.ndarray, gain: float = 1.0) -> None:
    s = int(round(t * SR))
    if s >= len(buf):
        return
    e = min(len(buf), s + len(x))
    buf[s:e] += x[: e - s] * gain


def kick() -> np.ndarray:
    f = np.geomspace(170, 42, int(0.16 * SR))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-np.arange(len(f)) / (0.05 * SR))


def snare() -> np.ndarray:
    n = chip.noise(0.14, 7, hold=2) * chip.env(0.14, attack=0.001, release=0.12) * 0.7
    tone = chip.square(190, 0.08) * chip.env(0.08, release=0.07) * 0.35
    return n + np.pad(tone, (0, len(n) - len(tone)))


def hat() -> np.ndarray:
    x = chip.noise(0.035, 11) * chip.env(0.035, attack=0.001, release=0.035)
    return np.diff(x, prepend=0) * 1.2


def riser(sec: float) -> np.ndarray:
    ramp = np.linspace(0.0, 1.0, int(sec * SR)) ** 2
    n = chip.noise(sec, 3, hold=2) * ramp
    s = chip.square(chip.sweep(180, 1500, sec), sec, 0.25) * ramp * 0.6
    return (n * 0.5 + s) * 0.7


def lead(name: str, steps: float, wave_fn=chip.square, vol: float = 0.3, **kw) -> np.ndarray:
    return chip.tone(name, steps * STEP * 0.85, wave_fn, vol, **kw)


def music() -> np.ndarray:
    buf = np.zeros(int(DURATION * SR))
    for b in range(int(DURATION / BAR)):
        t0 = b * BAR
        sec = min(b // 4 + 1, 9)            # section 1..9 (S9 spans bars 33-38)
        chord = PROGRESSION[b % 4]
        arp_notes, root = CHORDS[chord]
        # bass
        if sec >= 2 and sec != 8:
            for k in range(8):
                octave_up = root[:-1] + str(int(root[-1]) + 1)
                put(buf, t0 + k * STEP, chip.tone(octave_up if k % 2 else root, STEP * 0.9, chip.triangle, 0.55))
        else:
            put(buf, t0, chip.tone(root, BAR * 0.95, chip.triangle, 0.35))
        # arpeggio
        arp_vol = {1: 0.16, 2: 0.2, 3: 0.2, 4: 0.2, 5: 0.12, 6: 0.22, 7: 0.24, 8: 0.1, 9: 0.22}[sec]
        soft = sec in (1, 5, 8)
        steps = 16 if sec in (6, 7) else 8
        for k in range(steps):
            name = arp_notes[ARP_IDX[k % 8]]
            if soft:
                x = chip.tone(name, BAR / steps * 0.6, chip.triangle, arp_vol * 1.3)
            else:
                x = chip.tone(name, BAR / steps * 0.6, chip.square, arp_vol, duty=0.25)
            put(buf, t0 + k * (BAR / steps), x)
        # pad (calm sections)
        if sec in (5, 8):
            for n in (arp_notes[0], arp_notes[2]):
                put(buf, t0, chip.tone(n, BAR * 0.98, chip.triangle, 0.22))
        # drums
        if sec in (3, 4, 9):
            for beat in (0, 2):
                put(buf, t0 + beat * BEAT, kick(), 0.8)
            for beat in (1, 3):
                put(buf, t0 + beat * BEAT, snare(), 0.45)
        if sec in (2, 3, 4, 6, 7, 9):
            for k in range(8):
                if k % 2 == 1 or sec in (6, 7):
                    put(buf, t0 + k * STEP, hat(), 0.25)
        if sec == 6:
            for beat in range(4):
                put(buf, t0 + beat * BEAT, kick(), 0.8)
            put(buf, t0 + 1 * BEAT, snare(), 0.4)
            put(buf, t0 + 3 * BEAT, snare(), 0.4)
        if sec == 7:
            for off in (0, 0.75, 1.0, 1.75, 2.0, 2.5, 3.0):
                put(buf, t0 + off * BEAT, kick(), 0.9)
            put(buf, t0 + 1 * BEAT, snare(), 0.6)
            put(buf, t0 + 3 * BEAT, snare(), 0.6)
        # lead
        if sec in (4, 6, 7, 9) or (sec == 5 and b % 2 == 1):
            for k, name in enumerate(HOOK[b % 4]):
                if name:
                    put(buf, t0 + k * STEP, lead(name, 1.6, vol=0.32 if sec != 5 else 0.2, duty=0.5))
        if sec == 1 and b == 2:
            for k, name in enumerate(TITLE_LEAD):
                if name:
                    put(buf, t0 + k * STEP, lead(name, 1.6, vol=0.22, duty=0.125))
        if sec == 8 and b % 2 == 0:
            for k, name in enumerate(["E5", None, None, None, "C5", None, None, None]):
                if name:
                    put(buf, t0 + k * STEP, lead(name, 3.2, chip.triangle, 0.3))
        if sec == 2 and b >= 6:
            for k, name in enumerate(HOOK[b % 4][:4]):
                if name:
                    put(buf, t0 + k * STEP, lead(name, 1.6, vol=0.16, duty=0.25))
    # risers into each section start
    for t_end in (8.0, 16.0, 24.0, 32.0, 40.0, 48.0, 56.0, 64.0):
        put(buf, t_end - 1.5, riser(1.5), 0.5)
    # S7 ends with a dropout so S8 starts from near silence
    cut = slice(int(55.0 * SR), int(56.0 * SR))
    buf[cut] *= np.linspace(1.0, 0.0, cut.stop - cut.start) ** 2
    # S9: a break at 70..72, then the final chord rings to the end
    buf[int(70.0 * SR): int(72.0 * SR)] *= 0.45
    for n, g in (("A3", 0.35), ("C4", 0.3), ("E4", 0.3), ("A4", 0.25)):
        put(buf, 72.0, chip.tone(n, 4.0, chip.triangle, g))
    fade = int(1.5 * SR)
    buf[-fade:] *= np.linspace(1.0, 0.0, fade)
    # slow amplitude flutter in the calm section: a tired tape
    t = np.arange(len(buf)) / SR
    calm = ((t >= 56) & (t < 64)).astype(float)
    buf *= 1.0 + 0.05 * np.sin(2 * np.pi * 0.7 * t) * calm
    return buf


def write_wav(path: Path, x: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.9
    pcm = np.int16(np.clip(x, -1, 1) * 32767)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# (name = a wav from assets/audio/sfx, at seconds, gain dB, align)
SFX = [
    # S1: IME typing, the text message, the logo
    *[("cursor", 0.5 + 0.25 * i, -9, "start") for i in range(5)],
    ("hurt", 2.5, -9, "start"), ("confirm", 3.5, -8, "start"), ("victory", 4.0, -14, "start"),
    # S2: five protocol stamps, MVP count
    *[("confirm", 8.5 + 1.0 * i, -9, "start") for i in range(5)],
    *[("cursor", 14.0 + 0.25 * i, -12, "start") for i in range(6)],
    ("confirm", 14.85, -5, "start"),
    # S3: cards, tests, gate denial
    *[("swing", 16.2 + 0.35 * i, -11, "start") for i in range(6)],
    ("confirm", 19.0, -9, "start"), ("enemy_attack", 21.0, -12, "start"), ("hurt", 21.5, -12, "start"),
    ("confirm", 22.5, -9, "start"),
    ("swing", 23.0, -12, "start"),
    # S4: the sprite scan, the 400 error, the fix
    ("persuade", 25.0, -10, "start"), ("enemy_attack", 28.0, -12, "start"), ("confirm", 29.0, -9, "start"),
    # S5: pixel cells, title
    *[("cursor", 32.5 + 0.125 * i, -14, "start") for i in range(10)], ("confirm", 34.0, -9, "start"), ("confirm", 37.0, -9, "start"),
    # S6: rotate, taps
    ("cursor", 41.2, -9, "start"), ("confirm", 42.8, -9, "start"), ("cursor", 43.5, -9, "start"), ("swing", 45.2, -10, "start"), ("swing", 46.3, -10, "start"), ("cursor", 47.2, -9, "start"),
    # S7: the battle frames and the sound itself
    ("swing", 48.8, -8, "start"), ("hit", 49.0, -6, "start"), ("hit", 50.0, -6, "start"), ("hurt", 51.0, -8, "start"),
    ("persuade", 52.0, -8, "start"), ("guard", 53.0, -9, "start"), ("enemy_down", 54.0, -8, "start"),
    ("power_down", 55.2, -8, "start"),
    # S8: rain, a few quiet taps while lines type
    *[("cursor", t, -9, "start") for t in (59.0, 60.4, 61.3, 62.6)],
    # S9: the three statements, the end
    ("confirm", 64.0, -7, "start"), ("confirm", 65.0, -7, "start"), ("confirm", 66.0, -7, "start"),
    ("victory", 72.0, -8, "start"),
]
SCENES = [("s01", 0.0), ("s02", 8.0), ("s03", 16.0), ("s04", 24.0), ("s05", 32.0),
          ("s06", 40.0), ("s07", 48.0), ("s08", 56.0), ("s09", 64.0)]


def main() -> None:
    proj = Path(sys.argv[1]).resolve()
    write_wav(proj / "audio" / "music" / "music.wav", music())
    for name in {s[0] for s in SFX}:
        dst = proj / "audio" / "sfx" / f"{name}.wav"
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / "assets" / "audio" / "sfx" / f"{name}.wav", dst)
    beats = [round(i * BEAT, 3) for i in range(int(DURATION / BEAT))]
    downbeats = [round(i * BAR, 3) for i in range(int(DURATION / BAR))]
    hits = sorted({t for _, t in SCENES} | {6.0, 22.5, 28.0, 36.0, 49.0, 50.0, 64.0, 65.0, 66.0, 72.0})
    (proj / "audio" / "music" / "analysis.json").write_text(json.dumps(
        {"file": "music.wav", "duration": DURATION, "bpm": BPM, "beats": beats, "downbeats": downbeats,
         "hits": hits, "energy": []}))
    script = {
        "duration": DURATION,
        "lines": [],
        "sfx": [{"name": n, "file": f"audio/sfx/{n}.wav", "at": a, "gain_db": min(g + SFX_BOOST_DB, -2) if not 58.5 < a < 63 else g, "align": al} for n, a, g, al in SFX],
        "scenes": [{"id": i, "start": s} for i, s in SCENES],
        "music": {"file": "audio/music/music.wav", "gain_db": -9, "duck": 0.75, "analysis": "audio/music/analysis.json"},
    }
    (proj / "script.json").write_text(json.dumps(script, ensure_ascii=False, indent=1))
    print("music, sfx and script.json written to", proj)


if __name__ == "__main__":
    main()
