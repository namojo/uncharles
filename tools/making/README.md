# Uncharles making-of reel (source)

The 76-second reel on `site/making/` (published at `/making/`) is rendered from code with the
`showreel` skill's engine. This folder holds only the sources; the engine, fonts and heavy
intermediates (frames, raw audio) are not committed.

| File | What it is |
|---|---|
| `concept.md` | Concept, the four candidates compared, per-section art direction |
| `reel/index.html`, `reel/scenes_*.js` | The nine scenes (S1 cancellation ... S9 end card) |
| `prep_assets.py` | Copies the real evidence screenshots, art, Galmuri font and builds `reel/data.js` |
| `make_reel_audio.py` | Composes the 120 BPM chiptune (with the game's own generator) and writes `script.json` |

## Rebuild

1. Create a showreel project: `python <showreel>/scripts/new_project.py <project> --ratio 16:9 --duration 76`
2. `python tools/making/prep_assets.py <project>` (images, Galmuri font, data.js)
3. `python tools/making/make_reel_audio.py <project>` (music, sfx, script.json)
4. Copy `tools/making/reel/*` over `<project>/reel/`
5. `python <showreel>/scripts/timeline.py <project>/script.json --music-analysis <project>/audio/music/analysis.json`
6. `node <showreel>/scripts/render.mjs --dir <project>/reel --out <project>/out/video.mp4 --sub 4 --format png`
7. `python <showreel>/scripts/mix.py <project>/timeline.json --tp -3.2`, then `finish.py` and copy the mp4 and poster to `site/making/`

All sound is synthesized from `tools/audio/make_chiptune.py`; the font is Galmuri11 (SIL OFL 1.1).
