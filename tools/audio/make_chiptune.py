"""Synthesizes Uncharles' sound effects and chiptune loops as 16-bit mono WAV.

Everything is generated from code, so there are no third-party samples to
license. The sound follows the brief: chiptune, plus effects that sound a
little broken (bit-crush, pitch wobble, stutter).

Usage:  python tools/audio/make_chiptune.py
Writes: assets/audio/sfx/<event>.wav and assets/audio/music/<track>.wav
"""
from __future__ import annotations

import wave
from pathlib import Path

import numpy as np

RATE = 22050
ROOT = Path(__file__).resolve().parents[2]
SFX_DIR = ROOT / "assets" / "audio" / "sfx"
MUSIC_DIR = ROOT / "assets" / "audio" / "music"


# --- oscillators and helpers -------------------------------------------------

def t_axis(sec: float) -> np.ndarray:
    return np.arange(int(sec * RATE)) / RATE


def _freq(freq, sec: float) -> np.ndarray:
    return np.broadcast_to(np.asarray(freq, dtype=float), t_axis(sec).shape)


def square(freq, sec: float, duty: float = 0.5) -> np.ndarray:
    p = (np.cumsum(_freq(freq, sec)) / RATE) % 1.0
    return np.where(p < duty, 1.0, -1.0)


def triangle(freq, sec: float) -> np.ndarray:
    p = (np.cumsum(_freq(freq, sec)) / RATE) % 1.0
    return 4.0 * np.abs(p - 0.5) - 1.0


def noise(sec: float, seed: int, hold: int = 1) -> np.ndarray:
    """White noise; `hold` > 1 repeats samples for a gritty NES-style hiss."""
    rng = np.random.default_rng(seed)
    n = int(sec * RATE)
    raw = rng.uniform(-1.0, 1.0, n // hold + 1)
    return np.repeat(raw, hold)[:n]


def env(sec: float, attack: float = 0.004, release: float | None = None) -> np.ndarray:
    """Linear attack, then a linear fall to zero over `release` (default: all of it)."""
    t = t_axis(sec)
    a = np.clip(t / max(attack, 1e-6), 0.0, 1.0)
    rel = sec if release is None else release
    r = np.clip((sec - t) / rel, 0.0, 1.0)
    return a * r


def sweep(f0: float, f1: float, sec: float) -> np.ndarray:
    return np.geomspace(max(f0, 1.0), max(f1, 1.0), int(sec * RATE))


def crush(x: np.ndarray, bits: int = 5, hold: int = 2) -> np.ndarray:
    """Bit-depth and sample-rate reduction: the 'slightly broken' colour."""
    half = 2 ** bits / 2
    y = np.round(x * half) / half
    return np.repeat(y[::hold], hold)[: len(x)]


def stutter(x: np.ndarray, at: float, length: float, repeats: int) -> np.ndarray:
    """Repeats a short slice, like a skipping speaker."""
    s, n = int(at * RATE), int(length * RATE)
    chunk = x[s : s + n]
    return np.concatenate([x[: s + n]] + [chunk] * repeats + [x[s + n :]])


def lowpass(x: np.ndarray, amount: float) -> np.ndarray:
    """One-pole low-pass; amount 0..1, higher is darker."""
    y = np.empty_like(x)
    acc = 0.0
    k = 1.0 - amount
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def cat(*parts: np.ndarray) -> np.ndarray:
    return np.concatenate(parts)


def note_hz(name: str) -> float:
    offsets = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3,
               "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((offsets[pitch] + 12 * (octave - 4)) / 12)


def tone(name: str | None, sec: float, wave_fn=square, vol: float = 1.0, **kw) -> np.ndarray:
    if name is None:
        return np.zeros(int(sec * RATE))
    return wave_fn(note_hz(name), sec, **kw) * env(sec, release=sec * 0.9) * vol


def write(path: Path, x: np.ndarray, peak: float) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    m = np.max(np.abs(x)) or 1.0
    pcm = np.int16(np.clip(x / m * peak, -1.0, 1.0) * 32767)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    print(f"{path.relative_to(ROOT)}  {len(x) / RATE:.2f}s")


# --- sound effects -----------------------------------------------------------

def sfx() -> dict[str, tuple[np.ndarray, float]]:
    """Event id -> (samples, output peak). The ids are the audio events the game plays."""
    out: dict[str, tuple[np.ndarray, float]] = {}

    out["cursor"] = (square(1320, 0.035, 0.25) * env(0.035), 0.4)
    out["confirm"] = (cat(square(880, 0.05, 0.25) * env(0.05), square(1320, 0.08, 0.25) * env(0.08)), 0.45)

    # Swing: a short filtered whoosh.
    out["swing"] = (lowpass(noise(0.14, 1, hold=2) * env(0.14, attack=0.05, release=0.09), 0.75), 0.55)

    # Hit on the enemy: noise crack + falling square, crushed.
    hit = noise(0.16, 2, hold=3) * env(0.16, release=0.12) * 0.7
    hit += square(sweep(420, 70, 0.16), 0.16) * env(0.16) * 0.6
    out["hit"] = (crush(hit, 4, 2), 0.8)

    # Charles hurt: lower, with a skipping-speaker stutter.
    hurt = square(sweep(260, 50, 0.18), 0.18, 0.3) * env(0.18) * 0.7
    hurt += noise(0.18, 3, hold=6) * env(0.18, release=0.1) * 0.5
    out["hurt"] = (stutter(crush(hurt, 4, 3), 0.03, 0.025, 2), 0.8)

    # Persuade: warbling rising triangle arpeggio, slightly off-key.
    def vib(f: float, s: float) -> np.ndarray:
        return f * (1.0 + 0.012 * np.sin(2 * np.pi * 9 * t_axis(s)))
    steps = [note_hz("C5"), note_hz("E5") * 1.01, note_hz("G5")]
    out["persuade"] = (cat(*[triangle(vib(f, 0.09), 0.09) * env(0.09, release=0.07) for f in steps],
                           triangle(vib(note_hz("C6"), 0.16), 0.16) * env(0.16)), 0.6)

    # Guard: metallic ping (two detuned squares).
    ping = (square(1180, 0.24) + square(1243, 0.24)) * env(0.24, attack=0.002) * 0.5
    out["guard"] = (crush(ping, 6, 1), 0.45)

    # Enemy attack: a fridge-compressor buzz with wobble.
    buzz_f = 98 * (1.0 + 0.08 * np.sin(2 * np.pi * 14 * t_axis(0.3)))
    out["enemy_attack"] = (crush(square(buzz_f, 0.3, 0.35) * env(0.3, attack=0.02, release=0.12), 4, 2), 0.6)

    # Victory jingle: lead + bass, ending one step sour (it is that kind of game).
    lead = ["C5", "E5", "G5", "C6", None, "B5", "C6", "D6"]
    lens = [0.09, 0.09, 0.09, 0.18, 0.06, 0.09, 0.09, 0.42]
    melody = cat(*[tone(n, s, square, duty=0.25) for n, s in zip(lead, lens)])
    bass = cat(tone("C3", 0.45, triangle), tone("G2", 0.33, triangle), tone("C3", 0.33, triangle))
    bass = np.pad(bass, (0, max(0, len(melody) - len(bass))))[: len(melody)]
    out["victory"] = (melody * 0.6 + bass * 0.5, 0.65)

    # Enemy down: descending glide with stutters.
    down = square(sweep(700, 90, 0.5), 0.5, 0.25) * env(0.5)
    out["enemy_down"] = (stutter(stutter(crush(down, 5, 2), 0.1, 0.03, 1), 0.3, 0.03, 2), 0.6)

    # Power down: Charles' battery dies: a long falling whine, hiss, silence.
    whine = triangle(sweep(900, 40, 1.1), 1.1) * env(1.1, attack=0.01)
    hiss = noise(1.1, 4, hold=4) * np.linspace(0.25, 0.0, int(1.1 * RATE))
    out["power_down"] = (crush(whine * 0.8 + hiss, 5, 2), 0.7)

    return out


# --- music -------------------------------------------------------------------

def sequence(steps: list[str | None], step_sec: float, wave_fn, vol: float, gate: float = 0.85, **kw) -> np.ndarray:
    """One note (or rest) per step; `gate` is how much of the step the note holds."""
    step_len = int(step_sec * RATE)
    parts = []
    for n in steps:
        on = tone(n, step_sec * gate, wave_fn, vol, **kw)
        parts.append(np.pad(on, (0, step_len - len(on))))
    return cat(*parts)


def hats(count: int, step_sec: float, seed: int, vol: float) -> np.ndarray:
    hit = noise(0.03, seed) * env(0.03, attack=0.001) * vol
    return np.tile(np.pad(hit, (0, int(step_sec * RATE) - len(hit))), count)


def mix(*tracks: np.ndarray) -> np.ndarray:
    n = min(len(t) for t in tracks)
    return np.sum([t[:n] for t in tracks], axis=0)


def music_title() -> np.ndarray:
    """72 bpm, A minor: a slow arpeggio pad and a sparse, lonely lead. 8 bars, loops."""
    step = 60 / 72 / 2
    chords = [["A3", "C4", "E4", "C4"], ["F3", "A3", "C4", "A3"],
              ["C3", "E3", "G3", "E3"], ["E3", "G#3", "B3", "G#3"]]
    arp = [n for c in chords for n in c * 2] * 2
    lead = ([None] * 4 + ["E5", None, "D5", "C5"] + ["A4"] + [None] * 7
            + [None] * 4 + ["G4", None, "A4", "C5"] + ["B4"] + [None] * 3 + ["G#4"] + [None] * 3
            + [None] * 4 + ["E5", None, "F5", "E5"] + ["C5"] + [None] * 7
            + ["D5", None, "C5", None, "B4", None, "A4", None] + ["E4"] + [None] * 7)
    pad = sequence(arp, step, triangle, 0.5, gate=0.95)
    melody = sequence(lead, step, square, 0.28, gate=0.7, duty=0.125)
    # Slow amplitude flutter: a tired, slightly broken tape.
    flutter = 1.0 + 0.06 * np.sin(2 * np.pi * 0.7 * t_axis(len(pad) / RATE))
    return mix(pad * flutter, melody)


def music_battle() -> np.ndarray:
    """144 bpm, E minor: driving bass, arpeggio, noise hats and a hook. 8 bars, loops."""
    step = 60 / 144 / 2
    bass = []
    for root in ["E2", "E2", "C2", "D2"]:
        bass += [root, root[:-1] + str(int(root[-1]) + 1)] * 4
    bass = bass * 2
    chords = [["E4", "G4", "B4", "G4"], ["E4", "G4", "B4", "G4"],
              ["C4", "E4", "G4", "E4"], ["D4", "F#4", "A4", "F#4"]]
    arp = [n for c in chords for n in c * 2] * 2
    hook = (["B4", None, "B4", "A4", "G4", None, "E4", None] * 2
            + ["G4", None, "G4", "A4", "B4", None, "D5", None]
            + ["C5", "B4", "A4", None, "F#4", None, None, None]
            + ["E5", None, "D5", "B4", "D5", None, "B4", "A4"]
            + ["G4", None, "E4", None, "G4", "A4", "B4", None]
            + ["C5", None, "B4", None, "A4", None, "G4", None]
            + ["F#4", None, "A4", None, "E4", None, None, None])
    b = sequence(bass, step, triangle, 0.7, gate=0.9)
    a = sequence(arp, step, square, 0.18, gate=0.5, duty=0.25)
    h = sequence(hook, step, square, 0.3, gate=0.8, duty=0.5)
    return crush(mix(b, a, h, hats(len(bass), step, 9, 0.12)), 7, 1)


def main() -> None:
    for name, (data, peak) in sfx().items():
        write(SFX_DIR / f"{name}.wav", data, peak)
    write(MUSIC_DIR / "title_theme.wav", music_title(), 0.55)
    write(MUSIC_DIR / "battle_theme.wav", music_battle(), 0.55)


if __name__ == "__main__":
    main()
