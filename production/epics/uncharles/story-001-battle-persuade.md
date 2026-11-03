# Story 001: 턴제 전투 + 설득 커맨드

> **Epic**: Uncharles MVP
> **Status**: In Progress
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 2`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop, Player goal & fail state, MVP 2), scoped to this story:*

- [ ] 전투가 시작되면 찰스와 적 1체가 화면에 나오고, 턴은 찰스 → 적 순서로 번갈아 진행된다.
- [ ] 찰스의 HP는 배터리(%)로 표시된다. 적의 공격을 받으면 줄어들고 0% 아래로는 내려가지 않는다.
- [ ] 찰스의 커맨드는 집사 스킬 공격 2개 이상, 설득 2개 이상, 방어 1개다. 커맨드 목록과 모든 수치(위력, 설득량, 적 HP·공격력)는 외부 데이터 리소스에서 읽고 코드에 하드코딩하지 않는다.
- [ ] 설득 커맨드는 적의 설득 게이지를 올린다. 게이지가 최대치에 닿으면 적을 쓰러뜨리지 않고 '설득 승리'로 전투가 끝난다.
- [ ] 적 HP가 0이 되면 '제압 승리'로 끝난다.
- [ ] 배터리가 0%가 되면 '방전 패배'로 끝난다. 폐기장 처리는 Story 004에서 한다.
- [ ] 전투가 끝나면 결과(제압 / 설득 / 방전)를 담은 종료 시그널이 나가서, 대화·의뢰 시스템이 받아 쓸 수 있다.
- [ ] 커맨드마다 결과 대사가 1줄씩 나온다. 더미 적 1종으로 블랙코미디 톤을 시연한다.
- [ ] 전투 규칙(턴 순서, 데미지, 설득 게이지, 세 가지 종료 조건)은 씬이나 노드 없이 순수 GDScript 클래스로 단위 테스트할 수 있다.
- [ ] 회색 박스 아트 상태에서 키보드만으로 전투 한 판을 끝까지 플레이할 수 있다.

---

## Implementation Notes

- 전투 규칙 클래스(상태·턴·판정)와 표시(씬·UI)를 분리한다. 규칙 클래스는 의존성 주입으로 데이터를 받는다.
- 커맨드와 적은 `Resource`(.tres)로 정의해 `assets/data/battle/`에 둔다.
- 결과 열거형은 `DEFEATED / PERSUADED / DEPLETED` 3개다.
- 이 스토리의 목표는 "전투와 설득이 웃음을 만드는가"를 먼저 확인하는 것(Build order 1)이다. 연출보다 커맨드 대사와 템포를 우선한다.

---

## Out of Scope

- Story 002: 대화에서 전투를 호출하고, 결과에 따라 대사를 분기한다.
- Story 004: 방전 패배 후의 폐기장 재부팅을 처리한다.
- Story 005: 실제 의뢰의 적 종류와 클라이맥스 전투를 만든다.

---

## Files

- `src/battle/battle_state.gd`
- `src/battle/battle_command.gd`
- `src/battle/battle_enemy.gd`
- `src/battle/battle_ui.gd`
- `src/battle/battle_scene.tscn`
- `assets/data/battle/enemies/dummy_enemy.tres`
- `assets/data/battle/commands/attack_silver_tray.tres`
- `assets/data/battle/commands/attack_perfect_cleaning.tres`
- `assets/data/battle/commands/persuade_manual.tres`
- `assets/data/battle/commands/persuade_flatter.tres`
- `assets/data/battle/commands/persuade_plead.tres`
- `assets/data/battle/commands/defend_bow.tres`
- `assets/art/battle/charles.png`
- `assets/art/battle/frosty.png`
- `src/battle/*.gd.uid` (Godot-generated, committed with their scripts)
- `assets/art/battle/*.png.import` (Godot-generated)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but player-observable changes still need a retained screenshot.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/battle/battle_turn_test.gd`, `tests/unit/battle/battle_persuade_test.gd` (advisory at `qa.level: minimal`)
- 플레이 화면 스크린샷 1장: `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/uncharles/story-002-dialogue-affinity.md`, `production/epics/uncharles/story-004-junkyard-reboot.md`
