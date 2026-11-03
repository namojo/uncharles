# Story 002: 대사·선택지 + 주인별 호감도

> **Epic**: Uncharles MVP
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 3`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop 3, Player goal, MVP 3), scoped to this story:*

- [ ] 대화 데이터(화자, 본문, 선택지, 선택지별 호감도 변화량, 다음 노드)는 외부 데이터 파일에서 읽는다.
- [ ] 대화창에 화자 이름과 본문이 한 글자씩 나온다. 확인 키를 누르면 출력이 즉시 완성되고, 한 번 더 누르면 다음 대사로 넘어간다.
- [ ] 선택지는 2~4개가 표시되고 키보드로 고른다. 고른 선택지에 따라 다음 노드로 분기한다.
- [ ] 선택지에 호감도 변화가 붙어 있으면 해당 주인 후보의 호감도가 그만큼 바뀐다. 호감도는 주인 후보 ID별로 따로 관리한다.
- [ ] 조건 분기를 지원한다. 예를 들어 특정 후보의 호감도가 임계값 이상일 때만 나오는 선택지나 대사를 만들 수 있다.
- [ ] 대화 노드에서 전투(Story 001)를 시작할 수 있다. 전투 결과(제압 / 설득 / 방전)에 따라 서로 다른 노드로 이어진다.
- [ ] 분기와 호감도 로직은 UI 없이 단위 테스트할 수 있다. 경계 조건(임계값과 같은 값, 존재하지 않는 노드 ID)도 테스트한다.
- [ ] 더미 주인 후보 1명과의 테스트 대화(선택지 → 전투 → 결과별 대사)를 키보드만으로 끝까지 진행할 수 있다.

---

## Implementation Notes

- 대화 실행기(상태)와 대화창(UI)을 분리한다. 호감도 저장소는 주입받는 객체로 두어 Story 003의 저장 시스템이 직렬화할 수 있게 한다.
- 대화 포맷은 Godot `Resource` 또는 JSON 중 하나로 정하고, 같은 포맷을 Story 005의 의뢰 3건에서도 재사용한다.
- 한국어 폰트(도트 스타일)를 미리 넣어 둔다. 대화창은 한글 렌더링이 핵심이다.

---

## Out of Scope

- Story 003: 필드에서 NPC에게 말을 걸어 대화를 시작한다. Build order 2의 세로 슬라이스는 Story 003에서 완성된다.
- Story 005: 실제 의뢰의 대사 내용을 쓴다.
- Story 006: 최종 면담과 엔딩 분기를 만든다.

---

## Files

- `src/dialogue/dialogue_runner.gd`
- `src/dialogue/dialogue_data.gd`
- `src/dialogue/affinity_store.gd`
- `src/dialogue/dialogue_box.tscn`, `src/dialogue/dialogue_box.gd`
- `assets/data/dialogue/test_owner.*`
- `tests/unit/dialogue/dialogue_branch_test.gd`
- `tests/unit/dialogue/dialogue_affinity_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory), but player-observable changes still need a retained screenshot.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/dialogue/dialogue_branch_test.gd`, `tests/unit/dialogue/dialogue_affinity_test.gd` (advisory at `qa.level: minimal`)
- 대화창 스크린샷 1장: `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/uncharles/story-001-battle-persuade.md`
- Unlocks: `production/epics/uncharles/story-003-explore-hub.md`
