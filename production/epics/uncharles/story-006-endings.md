# Story 006: 엔딩 4종

> **Epic**: Uncharles MVP
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 6`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Player goal — 목표, MVP 6), scoped to this story:*

- [ ] 의뢰 3건을 모두 완료하면 소개소에서 '최종 면담'이 열린다.
- [ ] 최종 면담에서는 호감도가 데이터에 정의된 임계값 이상인 주인 후보만 선택지로 나온다.
- [ ] 주인 후보를 고르면 그 후보의 엔딩(3종 중 하나)으로 간다.
- [ ] '아무도 고르지 않는다'는 언제나 고를 수 있고, 독립 엔딩('찰스가 아닌 나')으로 이어진다. 임계값을 넘은 후보가 하나도 없으면 이 선택지만 남는다.
- [ ] 엔딩 판정은 단위 테스트로 검증한다. 호감도 조합별로 고를 수 있는 후보, 임계값과 같은 값, 후보 0명인 경우를 포함한다.
- [ ] 각 엔딩은 짧은 결말 장면과 크레딧으로 끝나고 타이틀로 돌아간다. 크레딧에는 영감을 준 원작을 표기한다.
- [ ] 엔딩에 도달하면 달성한 엔딩이 저장 데이터에 기록된다.

---

## Implementation Notes

- 엔딩 판정은 순수 함수로 만든다. 입력은 호감도 맵과 임계값, 출력은 고를 수 있는 후보 목록이다. 결말 장면의 대사는 Story 002의 대화 포맷을 쓴다.
- 독립 엔딩은 제목 'Uncharles(찰스가 아닌 나)'의 의미를 회수하는 장면이다.

---

## Out of Scope

- 엔딩 5종 이상, 엔딩 갤러리, 회차 시스템 (브리프 Out of scope).

---

## Files

- `src/ending/ending_selector.gd`
- `src/ending/final_interview.tscn`, `src/ending/ending_scene.tscn`, `src/ending/credits.tscn`
- `assets/data/dialogue/endings/*`
- `assets/data/tuning/ending_tuning.tres`
- `tests/unit/ending/ending_select_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but player-observable changes still need a retained screenshot.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/ending/ending_select_test.gd` (advisory at `qa.level: minimal`)
- 엔딩 4종의 스크린샷: `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/uncharles/story-005-three-jobs.md`
- Unlocks: None
