# Story 003: 도트 탐험 + 소개소 허브

> **Epic**: Uncharles MVP
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 1`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop 1·4, MVP 1, Art direction), scoped to this story:*

- [ ] 게임은 저해상도 기준 해상도(프로젝트 설정 값)를 정수 배율로만 확대해 그린다. 텍스처 필터는 nearest라서 도트가 번지지 않는다.
- [ ] 찰스는 타일맵 위를 4방향으로 이동하고, 벽과 가구에 막힌다.
- [ ] NPC나 사물 앞에서 확인 키를 누르면 Story 002의 대화가 시작된다.
- [ ] 소개소 허브에는 세 가지가 있다. 게시판은 의뢰 목록을 보여 주고, 고른 의뢰의 현장으로 이동시킨다. 충전기는 배터리를 100%로 채우고, 비용은 데이터 값이다. 저장 단말은 게임을 저장한다.
- [ ] 저장은 소개소에서만 할 수 있다. 저장 항목은 돈, 배터리, 주인별 호감도, 완료한 의뢰, 진행 중인 의뢰, 재부팅 횟수다.
- [ ] 저장하고 종료한 뒤 불러오면 위 항목이 모두 같은 값으로 복원된다. 통합 테스트로 이 왕복을 검증한다.
- [ ] 현장에는 소개소로 돌아가는 출구가 있다. 의뢰를 완료하고 복귀하면 데이터에 정의된 보상(돈)이 지급된다.
- [ ] 더미 의뢰 1건을 소개소 → 현장 탐험 → 대화 → 전투 → 복귀까지 끊김 없이 플레이할 수 있다. 이것으로 Build order 2의 세로 슬라이스가 완성된다.

---

## Implementation Notes

- 게임 상태(돈, 배터리, 호감도, 의뢰 진행)는 한 상태 객체에 모아 저장 시스템이 직렬화한다. 오토로드 싱글턴에 직접 의존하지 말고 주입해서 테스트할 수 있게 한다.
- 저장 파일은 `user://` 아래에 둔다.
- 이 스토리에서 `project.godot`의 `run/main_scene`을 소개소(또는 타이틀) 씬으로 정한다.

---

## Out of Scope

- Story 004: 방전 패배 후 재부팅하고 페널티를 적용한다.
- Story 005: 실제 의뢰 3건의 맵과 내용을 만든다.

---

## Files

- `src/world/player_mover.gd`, `src/world/interactable.gd`
- `src/hub/agency_hub.tscn`, `src/hub/job_board.gd`, `src/hub/charger.gd`
- `src/core/game_state.gd`, `src/core/save_system.gd`
- `assets/data/jobs/dummy_job.*`
- `tests/integration/save/save_roundtrip_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but player-observable changes still need a retained screenshot.*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/save_roundtrip_test.gd` OR playtest doc (advisory at `qa.level: minimal`)
- 소개소 허브와 현장 스크린샷: `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/uncharles/story-001-battle-persuade.md`, `production/epics/uncharles/story-002-dialogue-affinity.md`
- Unlocks: `production/epics/uncharles/story-004-junkyard-reboot.md`, `production/epics/uncharles/story-005-three-jobs.md`
