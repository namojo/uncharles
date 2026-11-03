# Story 002: 대사·선택지 + 주인별 호감도

> **Epic**: Uncharles MVP
> **Status**: In Progress
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

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
- [ ] 대화창에 화자 이름과 본문이 한 글자씩 나온다. 확인 키를 누르면 출력이 즉시 완성되고, 한 번 더 누르면 다음 대사로 넘어간다. 확인 키 대신 화면을 클릭·탭해도 같다.
- [ ] 선택지는 2~4개가 표시되고 키보드로 고른다. 마우스 클릭·터치 탭으로도 고를 수 있다. 고른 선택지에 따라 다음 노드로 분기한다.
- [ ] 선택지에 호감도 변화가 붙어 있으면 해당 주인 후보의 호감도가 그만큼 바뀐다. 노드 자체에 붙은 호감도 변화(예: 전투 결과 노드)도 같은 규칙으로 적용한다. 호감도는 주인 후보 ID별로 따로 관리한다.
- [ ] 노드에서 플래그를 켤 수 있다(`set_flag`). 플래그는 호감도와 같은 저장소 객체에 들어가 Story 003이 저장할 수 있다.
- [ ] 조건 분기를 지원한다. 조건은 특정 후보의 호감도 임계값, 플래그, 완료한 의뢰 수(`jobs_completed`), 재부팅 횟수(`reboot_count`)를 쓸 수 있다. 조건에 맞을 때만 나오는 선택지나 대사를 만들 수 있다.
- [ ] 노드의 `action`(의뢰 수락, 충전, 저장 등)은 대화 실행기가 신호로 내보낸다. 실제 동작은 Story 003이 맡는다.
- [ ] 본문의 이름 있는 자리표시자(`{money}`, `{reward}`, `{money_lost}`, `{reboot_count}`, `{charge_cost}`)는 주입된 값으로 채운다.
- [ ] 대화 노드에서 전투(Story 001)를 시작할 수 있다. 전투 결과(제압 / 설득 / 방전)에 따라 서로 다른 노드로 이어진다.
- [ ] 분기와 호감도 로직은 UI 없이 단위 테스트할 수 있다. 경계 조건(임계값과 같은 값, 존재하지 않는 노드 ID, 꺼진 플래그)도 테스트한다.
- [ ] 캐논 대사 `design/narrative/dialogue/job1-narae.md`의 잠긴 부엌 장면(1-6) → 프로스티 전투 → 결과별 결말(1-7) → 철학적 선택(1-8)을 데이터로 옮겨, 키보드만으로 끝까지 진행할 수 있다. 같은 흐름을 터치 탭만으로도 끝까지 진행할 수 있다.
- [ ] 타이틀의 '새 게임'은 전투가 아니라 프롤로그 대사로 시작한다. 프롤로그(`design/narrative/dialogue/prologue.md`) → 소개소 첫 방문(1-1) → 게시판에서 의뢰 1 수락(1-2) → 1207호 현관(1-3) → 거실(1-4, 먼지대장 전투) → 잠긴 부엌 앞(1-6) → 프로스티 전투 → 결말(1-7) → 철학적 선택(1-8) → 소개소 복귀(1-9) 순서로, 대화 시스템만으로 끝까지 이어진다. 걸어 다니는 탐험은 Story 003이 이 연결 사이를 대체한다. 장면 배경은 기존 그림을 임시로 쓰고, 현장 적(먼지대장·팩트·프로스티)은 캐논 문서 2절 데이터를 `.tres`로 옮긴다(수치는 임시값 + `TUNE` 표시).

---

## Implementation Notes

- 대화 실행기(상태)와 대화창(UI)을 분리한다. 호감도 저장소는 주입받는 객체로 두어 Story 003의 저장 시스템이 직렬화할 수 있게 한다.
- 대화 포맷은 Godot `Resource` 또는 JSON 중 하나로 정하고, 같은 포맷을 Story 005의 의뢰 3건에서도 재사용한다. 캐논 대사는 `design/narrative/dialogue/*.md`의 YAML 블록이므로, 그것을 게임 데이터로 옮기는 변환 도구(`tools/dialogue/`)를 함께 둔다(Godot에는 YAML 파서가 없다).
- 노드 필드와 확장 5종의 정의는 `design/narrative/dialogue/job1-narae.md` 0절 포맷 규약을 따른다(2026-11-03 결정으로 지원 확정).
- 수치(임계값, 호감도 단계값 `++`/`+`/`−`)는 데이터에 임시값으로 넣고 `TUNE` 표시를 남긴다.
- 한국어 폰트(도트 스타일)를 미리 넣어 둔다. 대화창은 한글 렌더링이 핵심이다.

---

## Out of Scope

- Story 003: 필드에서 NPC에게 말을 걸어 대화를 시작한다. Build order 2의 세로 슬라이스는 Story 003에서 완성된다.
- Story 005: 의뢰 2·3건의 대사를 데이터로 옮긴다. (의뢰 1의 소개소·현장 대사 전체를 붙이는 것은 Story 003의 세로 슬라이스다.)
- Story 006: 최종 면담과 엔딩 분기를 만든다.

---

## Files

- `src/dialogue/affinity_store.gd` — 호감도·플래그·카운터 저장소(직렬화, 스냅샷/복원)
- `src/dialogue/dialogue_condition.gd` — 조건식 파서·평가기
- `src/dialogue/dialogue_data.gd` — 대사 JSON 로드·검증
- `src/dialogue/dialogue_runner.gd` — UI 없는 대화 실행기
- `src/dialogue/choice_list.gd`, `src/dialogue/dialogue_box.gd`, `src/dialogue/dialogue_box.tscn` — 대화창·선택지 UI
- `src/flow/story_flow.gd`, `src/flow/story_flow.tscn` — 탐험 대역 흐름 호스트(프롤로그 → 의뢰 1 → 복귀)
- `src/battle/battle_ui.gd` — 호스팅 지원(hosted, result_acknowledged, battery())
- `src/battle/battle_state.gd`, `src/battle/battle_enemy.gd` — {enemy} 자리표시자, 적별 command_lines
- `src/title/title_screen.gd`, `src/title/title_screen.tscn` — 새 게임 → 흐름
- `tools/dialogue/build_dialogue.py` — 캐논 YAML → JSON 변환·검증
- `assets/data/dialogue/*.json`, `assets/data/dialogue/TUNE.md` — 대사·흐름·호감도 데이터, 임시 수치
- `assets/data/battle/enemies/{frosty,dust_chief,fact_scale}.tres`, `assets/data/battle/commands/*.tres`
- `assets/art/backgrounds/{prologue_door,prologue_road,agency_interior,apt_entrance,apt_living}.png`, `assets/art/battle/{dust_chief,fact_scale}.png`
- `export_presets.cfg` — 대사 JSON include_filter
- 테스트 파일 없음 — `qa.level: minimal`에서 면제(헤드리스 논리 점검은 스크래치 스크립트로 수행)

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
