# Story 004: 폐기 처리장 재부팅

> **Epic**: Uncharles MVP
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 5`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Player goal & fail state — 실패), scoped to this story:*

- [ ] 전투가 '방전 패배'로 끝나면 게임 오버 화면 없이 폐기 처리장 씬으로 넘어간다.
- [ ] 재부팅하면 돈이 데이터에 정의된 손실 비율만큼 줄어든다. 소수점은 버리고, 0 아래로는 내려가지 않는다.
- [ ] 진행 중이던 의뢰는 의뢰를 시작한 시점으로 되돌아간다. 현장 진행 상태와 그 의뢰에서 얻은 호감도 변화가 사라지는 것이 '기억 일부 손실'이다. 이미 완료한 의뢰와 그 전에 쌓은 호감도는 그대로 남는다.
- [ ] 재부팅 후 배터리는 데이터에 정의된 값으로 정해지고, 소개소에서 다시 시작한다.
- [ ] 재부팅 횟수는 저장된다. 폐기장 대사는 횟수에 따라 최소 2종으로 바뀐다(블랙코미디 톤).
- [ ] 페널티 계산과 상태 롤백은 단위 테스트로 검증한다. 경계 조건으로 돈이 0일 때, 진행 중인 의뢰가 없을 때, 같은 의뢰에서 두 번 연속 방전했을 때를 포함한다.

---

## Implementation Notes

- 손실 비율, 재부팅 후 배터리 값, 대사 세트는 `assets/data/tuning/`에 두는 튜닝 값이다. 브리프에 수치가 없으므로, 초기값은 개발 중 플레이테스트로 정하고 데이터 파일에만 적는다.
- 의뢰를 시작할 때 롤백용 스냅샷(의뢰 관련 상태, 호감도)을 떠 둔다.

---

## Out of Scope

- Story 003: 저장 시스템과 허브 자체를 만든다.
- Story 005: 의뢰 내용을 만든다.

---

## Files

- `src/core/reboot_service.gd`
- `src/junkyard/junkyard_scene.tscn`, `src/junkyard/junkyard_scene.gd`
- `assets/data/tuning/reboot_tuning.tres`
- `tests/unit/reboot/reboot_penalty_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but player-observable changes still need a retained screenshot.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/reboot/reboot_penalty_test.gd` (advisory at `qa.level: minimal`)
- 폐기장 화면 스크린샷: `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/uncharles/story-001-battle-persuade.md`, `production/epics/uncharles/story-003-explore-hub.md`
- Unlocks: `production/epics/uncharles/story-005-three-jobs.md`
