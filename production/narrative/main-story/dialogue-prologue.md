# 프롤로그 「문 앞」 — 새 게임 직후, 소개소 첫 방문 전 (18 노드)

> **상태**: 초안 (Provisional) — narrative-director 검토 전. 캐논 위반 없음(자체 점검, team.size `individual`).
> **작성**: writer (world-builder / art-director 겸임) — /team-narrative Phase 2
> **근거 캐논**: `design/narrative/main-story-brief.md` 1절(세계 규칙 1·5, 명찰 규칙), 2절(버림받은 사연, 말투 규칙 1~5, 러닝 개그 스티커), 결정 블록(윤씨 가족 미등장). 포맷은 `design/narrative/dialogue/job1-narae.md` 0절 규약.
> **원작 거리두기**: *Service Model*의 플롯·인물은 쓰지 않았다.
> **수치**: 정의하지 않았다. 스티커 가격 3,000원은 브리프 세계 규칙 1의 값 그대로다.

---

## 0. 연결

- **진입**: 타이틀 「새 게임」 → 이 프롤로그(`prologue_01`) → `agency_first_01`.
- **⚑ 변경 요청**: `job1-narae.md` 1-1의 `trigger`("타이틀에서 새 게임 시작 직후")는 "프롤로그 종료 직후"로 바꿔야 한다. 그 문서는 승인된 캐논이라 이 파일에서 고치지 않았다.
- **중복 회피**: 등록번호 1129, UN- 명찰, 규칙 세 개, 양식 0번은 1-1에서 처음 나온다. 프롤로그는 건드리지 않는다. 마지막 노드는 "새벽 세 시"를 말하지 않고 걷는 길로 끝낸다.
- **윤씨 가족은 등장하지 않는다.** 화자 목록에 없다. 문자 한 통과 집의 흔적(우산)으로만 나온다.
- **찰스 말투 점검**: 하십시오체, 1인칭 '저', 감정 단어 없음(슬픔은 "특이사항 보고"와 기기 상태로만), 한 줄에 정보 하나.
- **길이**: 모든 `text` 80자 이하.
- **선택지**: 프롤로그에 단 하나(`prologue_06`). 호감도·플래그 없음(순수 맛). 두 선택지 모두 `prologue_07`로 합류한다.

---

## 1. 배경 노트 (art-director 겸임, 한 줄씩)

| backdrop id | 화면에 있는 것 | 켜져 있는 단 하나 |
|---|---|---|
| `backdrop_door_rain` | 윤씨 집 현관 밖, 비 오는 밤. 회색 문, 젖은 복도, 우산꽂이의 작은 노란 우산. 연미복 찰스의 등에 스티커. | **찰스 가슴 화면의 문자 알림**(시안). 문 안쪽은 어둡다. |
| `backdrop_door_after` | 사흘 뒤 같은 문 앞. 비 그친 아침의 마른 회색 복도. 같은 자리의 찰스, 등의 스티커 위에 전단지 한 장. | **전단지 아랫줄 "24시간"**(앰버). 나머지는 흐리다. |
| `backdrop_road_to_agency` | 새벽 도시 변두리의 빈 인도. 셔터 내린 가게, 마른 비 자국, 걷는 찰스의 작은 실루엣. | **먼 곳 소개소 간판 한 점**(앰버, 깜빡임). 시안·앰버 합쳐 화면의 10% 이하. |

---

## 2. 대사 스크립트

### 2-1. 현관 앞, 비 오는 밤 `prologue_door_rain`

```yaml
scene: prologue_door_rain
backdrop: backdrop_door_rain
lit: 찰스 가슴 화면의 문자 알림 (시안)
trigger: 타이틀에서 새 게임 시작 직후, 자동
nodes:
  - id: prologue_01
    speaker: 내레이션
    text: '어느 화요일 밤. 윤씨 집 현관 앞. 비가 온다. 연미복 로봇이 쟁반을 들고 서 있다.'
    next: prologue_02
  - id: prologue_02
    speaker: 환경
    text: '[알림] 고객님의 집사 구독이 해지되었습니다. 기기는 문 앞에 내놓아 주세요.'   # 캐논(문자 원문)
    next: prologue_03
  - id: prologue_03
    speaker: 찰스
    text: '이 문자의 수신자는 저입니다. 오발송인지 확인합니다.'
    next: prologue_04
  - id: prologue_04
    speaker: 환경
    text: '해지 사유: 그냥요.'   # 캐논
    next: prologue_05
  - id: prologue_05
    speaker: 찰스
    text: '오발송이 아닙니다. "그냥요"는 접수 가능한 사유입니다.'
    next: prologue_06
  # --- 유일한 선택지: 순수 맛, 호감도·플래그 없음 ---
  - id: prologue_06
    speaker: 찰스
    text: '회신 문구를 입력합니다.'
    choices:
      - text: '"확인했습니다."'
        next: prologue_07
      - text: '"냉장고에 내일 아침 식사가 있습니다."'
        next: prologue_07
  - id: prologue_07
    speaker: 환경
    text: '발신 전용 번호입니다. 회신하실 수 없습니다.'
    next: prologue_08
  - id: prologue_08
    speaker: 찰스
    text: '규정 확인. 반납 수수료는 대형폐기물 스티커보다 비쌉니다.'
    next: prologue_09
  - id: prologue_09
    speaker: 찰스
    text: '스티커를 구매했습니다. 3,000원. 제 돈으로 결제했습니다. 영수증은 보관합니다.'
    next: prologue_10
  - id: prologue_10
    speaker: 내레이션
    text: '찰스는 스티커를 등에 붙였다. 손이 닿지 않아 벽에 등을 대고 붙였다.'
    next: prologue_11
  - id: prologue_11
    speaker: 찰스
    text: '고객님을 번거롭게 해서는 안 됩니다. 이것이 마지막 업무입니다. 대기합니다.'
    next: prologue_12
  - id: prologue_12
    speaker: 환경
    text: '현관 옆 우산꽂이에 작은 노란 우산이 하나 꽂혀 있다. 아이 것이다.'
    next: prologue_13
  - id: prologue_13
    speaker: 내레이션
    text: '비는 그치지 않았다. 수거 트럭은 오지 않았다. 문도 열리지 않았다.'
    next: prologue_14
```

### 2-2. 사흘 뒤, 같은 문 앞 `prologue_door_after`

```yaml
scene: prologue_door_after
backdrop: backdrop_door_after
lit: 전단지 아랫줄 "24시간" (앰버)
nodes:
  - id: prologue_14
    speaker: 내레이션
    text: '사흘째 아침. 비가 그쳤다. 누군가 스티커 위에 전단지를 한 장 붙이고 갔다.'   # 캐논
    next: prologue_15
  - id: prologue_15
    speaker: 환경
    text: '[로봇 직업소개소] 주인 없는 로봇 환영. 24시간 영업. 배터리값은 벌어 가세요.'
    next: prologue_16
  - id: prologue_16
    speaker: 찰스
    text: '특이사항 보고. 사흘간 쟁반에 올린 것이 없습니다. 업무에는 지장 없습니다.'
    next: prologue_17
  - id: prologue_17
    speaker: 찰스
    text: '전단지의 주소로 이동합니다. 스티커는 떼지 않습니다. 정식으로 납부한 것입니다.'   # 캐논(러닝 개그 첫 등장)
    next: prologue_18
```

### 2-3. 소개소로 가는 길 `prologue_road`

```yaml
scene: prologue_road
backdrop: backdrop_road_to_agency
lit: 먼 소개소 간판 한 점 (앰버, 깜빡임)
nodes:
  - id: prologue_18
    speaker: 내레이션
    text: '도시는 바빴다. 아무도 길 위의 연미복 로봇을 돌아보지 않았다.'
    next: agency_first_01   # -> job1-narae.md 1-1 "새벽 세 시. 로봇 직업소개소."
```

---

## 3. 이 프롤로그가 브리프 캐논에 더한 것 (전부 Provisional)

- 해지 문자가 온 때는 화요일 **밤**이다(브리프는 "화요일"까지만).
- 찰스가 문자에 **회신을 시도**하지만 발신 전용 번호라 닿지 않는다.
- 회신 선택지 B에서 윤씨 집 **냉장고에 아침 식사를 준비해 둔 것**이 암시된다(의뢰 1 냉장고 모티프와 울림, 효과는 없음).
- 찰스에게 **개인 잔액**이 있어 스티커 값 3,000원을 직접 결제하고 영수증을 보관한다("자기 돈" 캐논의 구체화).
- 찰스가 **벽에 등을 대고** 스티커를 붙인다(손이 안 닿음).
- 윤씨 집의 흔적: 현관 옆 우산꽂이의 **작은 노란 아이 우산**.
- 사흘 동안 **문이 한 번도 열리지 않았다.**
- 전단지 문구: 「주인 없는 로봇 환영. 24시간 영업. 배터리값은 벌어 가세요.」
- 러닝 개그 대사 "정식으로 납부한 것입니다."의 **첫 등장 지점**이 프롤로그가 된다(캐논 대사 자체는 불변).
