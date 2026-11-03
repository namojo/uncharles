# Story 005: 알바 의뢰 3건

> **Epic**: Uncharles MVP
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 4`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop, MVP 4, Inspiration), scoped to this story:*

- [ ] 소개소 게시판에 의뢰 3건이 나오고, 각 의뢰의 주인 후보 이름, 보상, 위험도가 보인다.
- [ ] 의뢰마다 현장 맵 1곳, 주인 후보 1명(대화 상대), 현장 적 2종 이상, 사연의 핵심 인물이나 가전과의 클라이맥스 전투 1회가 있다.
- [ ] 각 클라이맥스는 제압과 설득 두 방법으로 모두 해결할 수 있다. 어느 방법으로 해결했는지에 따라 결말 대사와 호감도 변화가 달라진다.
- [ ] 각 의뢰의 끝에는 인간과 로봇의 관계에 관한 철학적 선택이 1회 있고, 그 결과가 해당 주인의 호감도에 반영된다.
- [ ] 의뢰를 완료하면 돈 보상이 지급되고 완료 플래그가 저장된다. 완료한 의뢰는 게시판에 '완료'로 표시되고 다시 받을 수 없다.
- [ ] 세 의뢰 모두 블랙코미디 톤이다. 영감을 준 원작(Adrian Tchaikovsky, *Service Model*)의 플롯과 인물은 쓰지 않는다.
- [ ] 각 의뢰를 소개소 → 현장 → 복귀까지 끊김 없이 플레이할 수 있다.
- [ ] 의뢰, 적, 대사 내용은 데이터 파일로 정의한다. 코드를 고치지 않고도 의뢰 데이터를 바꾸거나 추가할 수 있다.

---

## Implementation Notes

- Story 001(전투 리소스), 002(대화 포맷), 003(의뢰 데이터·게시판)의 포맷을 그대로 재사용한다. 이 스토리에서는 새 시스템을 만들지 않는다.
- 주인 후보 3명의 성격과 사연은 서로 다른 '인간이 로봇에게 바라는 것'을 대표하게 짠다. 시나리오 초안은 `writer` 또는 `narrative-director` 에이전트에게 맡길 수 있다.

---

## Out of Scope

- Story 006: 최종 면담과 엔딩을 만든다.
- 의뢰 4건 이상 (브리프 Out of scope).

---

## Files

- `assets/data/jobs/job_01.*`, `job_02.*`, `job_03.*`
- `assets/data/dialogue/job_01/*`, `job_02/*`, `job_03/*`
- `assets/data/battle/enemies/*.tres`
- `src/jobs/job_site_01.tscn`, `job_site_02.tscn`, `job_site_03.tscn`
- `tests/integration/jobs/job_flow_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but player-observable changes still need a retained screenshot.*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/jobs/job_flow_test.gd` OR playtest doc (advisory at `qa.level: minimal`)
- 의뢰 현장 3곳의 스크린샷: `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/uncharles/story-003-explore-hub.md`, `production/epics/uncharles/story-004-junkyard-reboot.md`
- Unlocks: `production/epics/uncharles/story-006-endings.md`
