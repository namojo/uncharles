# TUNE — temporary values (Story 002)

Every number below is a placeholder chosen by the programmer so the vertical
slice can be played. None is designed. game-designer owns them
(`design/narrative/dialogue/job1-narae.md` section 5: all `TBD`).

| File | Field | Value | Why this temporary value |
|---|---|---|---|
| `assets/data/dialogue/affinity_values.json` | `steps."++"` | 2 | Double of `+`, so the canon "++" choice outweighs one "+" |
| `assets/data/dialogue/affinity_values.json` | `steps."+"` | 1 | Unit step |
| `assets/data/dialogue/affinity_values.json` | `steps."0"` | 0 | Canon: no change |
| `assets/data/dialogue/affinity_values.json` | `steps."−"` | -1 | Mirror of `+` |
| `assets/data/dialogue/affinity_values.json` | `thresholds.threshold_narae_warm` | 3 | Job 1 range is −1..4. 3 = warm farewell needs the birthday line + persuasion + the "+" choice, or the "++" choice with one other "+"; replacing Frosty (−) never reaches it |
| `assets/data/dialogue/affinity_values.json` | `counter_defaults.money` | 500 | Enough for a few charges and one reboot fee |
| `assets/data/dialogue/affinity_values.json` | `counter_defaults.battery` | 100 | Full battery at new game |
| `assets/data/dialogue/flow.json` | `jobs[job1_narae].reward` | 300 | Shown as `{reward}` on the board and at the return |
| `assets/data/dialogue/flow.json` | `money_loss_ratio` | 0.2 | Reboot fee `{money_lost}` = floor(money × 0.2) |
| `assets/data/dialogue/flow.json` | `charge_cost` | 100 | `{charge_cost}` (no canon line uses it yet; charging is Story 003) |
| `assets/data/dialogue/flow.json` | `battery_max` | 100 | Same as Story 001's battle default |
| `assets/data/dialogue/flow.json` | `reboot_battery` | 100 | Battery after a DEPLETED reboot |
| `assets/data/battle/enemies/dust_chief.tres` | `max_hp` | 30 | First fight: two silver-tray hits win |
| `assets/data/battle/enemies/dust_chief.tres` | `attack_power` | 8 | Light, so the first fight cannot drain the battery |
| `assets/data/battle/enemies/dust_chief.tres` | `persuade_max` | 60 | Two persuade commands win |
| `assets/data/battle/enemies/fact_scale.tres` | `max_hp` | 40 | Between Dust Chief and Frosty |
| `assets/data/battle/enemies/fact_scale.tres` | `attack_power` | 10 | Optional fight: a real but small battery cost |
| `assets/data/battle/enemies/fact_scale.tres` | `persuade_max` | 80 | Three persuade commands win |
| `assets/data/battle/enemies/frosty.tres` | `max_hp` / `attack_power` / `persuade_max` | 60 / 15 / 100 | Kept from Story 001 (already temporary there) |

Battery carries over between fights in a run, and the charger is still a stub
(Story 003). If Charles goes into Frosty after both optional fights, he has
about 72% left: enough to win, or to be DEPLETED by a slow fight.
