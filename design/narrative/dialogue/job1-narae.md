# 의뢰 1 금나래 — 세로 슬라이스 대사·적·로어 (Stories 002 + 003)

> **상태**: 승인됨(CANON) — 2026-11-03 Phase 2 게이트에서 사용자가 "진행"으로 승인. 이 문서에서 새로 정한 설정(등록번호 1129, UN-FROSTY, 새벽 배경, 주문 취소 알림 등)도 캐논이다. 결정은 5절 끝. ND-CONSISTENCY는 실행하지 않았다(team.size `individual`, writer 자체 점검).
> **작성**: writer (team.size `individual`, world-builder / art-director 겸임) — /team-narrative Phase 2
> **근거 캐논**: `design/narrative/main-story-brief.md` 1·2·3절, 4절 의뢰 1, 6절, 결정 블록(2026-11-03). 아트 규칙은 `design/art/art-bible.md` 1·2·3절.
> **수치**: 하나도 정하지 않았다. HP·공격력·설득 최대치·보상·수거 비용·충전 비용·호감도 임계값은 모두 `TBD`(game-designer 몫).
> **원작 거리두기**: *Service Model*의 플롯·인물은 쓰지 않았다.
> **캐논 대사 그대로 쓴 곳**은 노드 옆에 `# 캐논`으로 표시했다. 고치지 않았다.

---

## 0. 포맷 규약

노드 필드는 요청 포맷을 따른다: `id`, `speaker`, `text`, 그리고 `next` / `choices` / `battle` + `on_*` / `condition` + `then`/`else` / `end` 중 하나.

**Story 002 AC 밖의 확장 (⚑ 표시, 구현 여부는 programmer·game-designer가 정한다)**

| 확장 | 쓰는 곳 | 이유 |
|---|---|---|
| ⚑ 노드 단위 `affinity: {narae: "+"}` | 프로스티 설득 결말 | 캐논상 호감도 변화가 선택지가 아니라 **전투 결과**에 붙어 있다 |
| ⚑ `set_flag: <이름>` | 프로스티 결과, 철학적 선택 | 소개소 카메오(프로스티 등록), Story 005/006 분기용 |
| ⚑ 조건식 `flag.<이름>`, `jobs_completed`, `reboot_count` | 게시판, 키오스크 공지, 폐기장 | 예시 조건은 호감도뿐이었다 |
| ⚑ `action: accept_job / charge_battery / save_game` | 게시판·충전기·저장 단말 | Story 003의 허브 기능을 대화에서 부르는 지점 |
| `end: <맵 id>` | 현장 대화 끝 | **씬 이동이 아니라 해당 맵에서 조작을 돌려준다**는 뜻. `end: return_to_agency`는 소개소로 이동 |

- 전투 노드의 `on_depleted`는 모두 `junkyard_reboot_01`로 간다.
- 현장 적(먼지대장·팩트)은 화자 목록에 없어서, 전투 밖에서는 말하지 않는다. 전투 안의 대사는 BattleEnemy 데이터에만 있다.
- 플레이스홀더는 `{money}`, `{reward}`, `{money_lost}`, `{reboot_count}`만 쓴다. 전투 데이터는 기존 `{damage}` / `{persuade}` / `{guard}`.
- 길이: 모든 `text`는 80자 이하로 맞췄다(120자 상한, 216px 창 3줄).

---

## 1. 대사 스크립트

### 1-1. 소개소 첫 방문 `agency_first` (양식 0번 받침 씬 포함)

```yaml
scene: agency_first
trigger: 프롤로그 종료 직후, 소개소 입장 시 자동
nodes:
  - id: agency_first_01
    speaker: 내레이션
    text: '새벽 세 시. 로봇 직업소개소. 천장 형광등 하나가 깜빡인다.'
    next: agency_first_02
  - id: agency_first_02
    speaker: 오 실장
    text: '번호표 뽑아. ...아, 아무도 없구나. 그냥 와.'
    next: agency_first_03
  - id: agency_first_03
    speaker: 찰스
    text: '안녕하십니까. 전단지를 보고 왔습니다. 집사 모델 CH-4, 찰스입니다.'
    next: agency_first_04
  - id: agency_first_04
    speaker: 오 실장
    text: '찰스? 오늘 찰스만 세 대 왔어.'
    next: agency_first_05
  - id: agency_first_05
    speaker: 오 실장
    text: '이름 말고 등록번호. 여기선 이름 아무도 안 불러.'   # 캐논
    next: agency_first_06
  - id: agency_first_06
    speaker: 내레이션
    text: '오 실장이 명찰에 도장을 찍었다. 명찰에 글자가 떠올랐다. UN-CHARLES.'
    next: agency_first_07
  - id: agency_first_07
    speaker: 찰스
    text: '명찰에 오류가 있습니다. 제 이름 앞에 두 글자가 더 있습니다.'
    next: agency_first_08
  - id: agency_first_08
    speaker: 오 실장
    text: '오류 아냐. UN, 미배정. 주인 없으면 다 붙어.'
    next: agency_first_09
  - id: agency_first_09
    speaker: 오 실장
    text: '넌 1129번. 됐지?'
    choices:
      - text: '확인했습니다. 1129번입니다.'
        next: agency_first_11
      - text: '고객님, 차를 내올까요?'
        next: agency_first_10
  - id: agency_first_10
    speaker: 오 실장
    text: '나 고객 아냐. 그리고 여기 물은 셀프야.'
    next: agency_first_11
  - id: agency_first_11
    speaker: 오 실장
    text: '규칙 세 개. 한 번만 말해.'
    next: agency_first_12
  - id: agency_first_12
    speaker: 오 실장
    text: '하나. 일은 게시판에서. 의뢰인은 임시 고객이야. 주인 아냐.'
    next: agency_first_13
  - id: agency_first_13
    speaker: 오 실장
    text: '둘. 충전은 유료. 저기 코인 충전기. 0% 되면 수거차가 주워 가.'
    next: agency_first_14
  - id: agency_first_14
    speaker: 오 실장
    text: '셋. 저장은 저 단말기에서만. 밖에서 꺼지면 그날 일은 없던 거야.'
    next: agency_first_15
  - id: agency_first_15
    speaker: 찰스
    text: '확인했습니다. 질문이 하나 있습니다. 정식 주인 등록은 어디서 합니까?'
    next: agency_first_16
  - id: agency_first_16
    speaker: 오 실장
    text: '최종 면담. 아직 먼 얘기야. 일부터 해.'
    next: agency_first_17
  # --- 양식 0번: 컵라면 받침 ---
  - id: agency_first_17
    speaker: 내레이션
    text: '오 실장이 컵라면 뚜껑을 열었다. 라면 밑에 누런 서류 한 장이 깔려 있다.'
    next: agency_first_18
  - id: agency_first_18
    speaker: 찰스
    text: '고객님, 받침이 필요하시면 제 쟁반을 쓰십시오. 은도금입니다.'
    next: agency_first_19
  - id: agency_first_19
    speaker: 오 실장
    text: '됐어. 받침 있어.'
    next: agency_first_20
  - id: agency_first_20
    speaker: 찰스
    text: '그 서류 맨 위에 양식 0번이라고 적혀 있습니다. 나머지는 국물 자국에 가려져 있습니다.'
    next: agency_first_21
  - id: agency_first_21
    speaker: 오 실장
    text: '그거? 아무도 안 쓰는 양식. 컵라면 받침이야.'   # 캐논
    next: agency_first_22
  - id: agency_first_22
    speaker: 찰스
    text: '확인했습니다. 받침으로 쓰기에 적당한 두께입니다.'
    next: agency_first_23
  - id: agency_first_23
    speaker: 오 실장
    text: '...게시판 가 봐. 급한 거 하나 붙었어.'
    end: agency_hub
```

### 1-2. 소개소 상호작용 `agency_board` / `agency_charger` / `agency_save` / `agency_kiosk_notice`

```yaml
scene: agency_board
trigger: 게시판 앞에서 확인 키
nodes:
  - id: agency_board_00
    condition: 'jobs_completed >= 1'
    then: agency_board_done_01
    else: agency_board_01
  - id: agency_board_01
    speaker: 환경
    text: '[긴급·당일] 냉장고가 부엌 점거 중. 진압 또는 대화 가능하신 분. 아침밥 먹고 출근하고 싶어요.'   # 캐논
    next: agency_board_02
  - id: agency_board_02
    speaker: 환경
    text: '의뢰인: 금나래 / 장소: 오피스텔 1207호 / 보상: {reward}원 / 위험도: ★☆☆'
    next: agency_board_03
  - id: agency_board_03
    speaker: 내레이션
    text: '게시판의 나머지 칸은 비어 있다. 압정만 꽂혀 있다.'
    choices:
      - text: '수락한다'
        next: agency_board_accept_01
      - text: '그만둔다'
        next: agency_board_cancel
  - id: agency_board_accept_01
    action: accept_job   # ⚑ job_id: job1_narae
    speaker: 오 실장
    text: '냉장고야? 문 열 때 정면에 서지 마.'
    next: agency_board_accept_02
  - id: agency_board_accept_02
    speaker: 찰스
    text: '확인했습니다. 측면에서 열겠습니다.'
    end: job1_entrance
  - id: agency_board_cancel
    speaker: 내레이션
    text: '찰스는 압정 하나가 비뚤어진 것을 바로 꽂고 물러났다.'
    end: agency_hub
  - id: agency_board_done_01
    speaker: 내레이션
    text: '게시판에 새 의뢰가 없다. 1207호 쪽지를 떼어 낸 자국만 남았다.'
    end: agency_hub
```

```yaml
scene: agency_charger
trigger: 코인 충전기 앞에서 확인 키
nodes:
  - id: agency_charger_01
    speaker: 환경
    text: '코인 충전기. "1회 충전. 금액은 화면 참조. 거스름돈 없음."'
    next: agency_charger_02
  - id: agency_charger_02
    speaker: 환경
    text: '보유 금액: {money}원'
    choices:
      - text: '충전한다'
        next: agency_charger_03
      - text: '그만둔다'
        next: agency_charger_cancel
  - id: agency_charger_03
    action: charge_battery   # ⚑ 성공 시 _ok, 잔액 부족 시 _poor 로 분기하는 것은 시스템 몫
    speaker: 찰스
    text: '충전 완료. 배터리 100%입니다. 업무에 지장 없습니다.'
    end: agency_hub
  - id: agency_charger_poor
    speaker: 찰스
    text: '잔액이 부족합니다. 확인했습니다. 여기 서서 기다리겠습니다.'
    end: agency_hub
  - id: agency_charger_cancel
    speaker: 내레이션
    text: '충전 포드의 시안 불빛이 찰스를 따라 한 번 깜빡였다.'
    end: agency_hub
```

```yaml
scene: agency_save
trigger: 저장 단말 앞에서 확인 키
nodes:
  - id: agency_save_01
    speaker: 환경
    text: '저장 단말. 화면 구석에 스티커: "키오스크 전환 대비 시범 운영".'
    choices:
      - text: '저장한다'
        next: agency_save_02
      - text: '그만둔다'
        next: agency_save_cancel
  - id: agency_save_02
    action: save_game   # ⚑
    speaker: 환경
    text: '저장되었습니다. 오늘의 기록: 분실물 1129번.'
    end: agency_hub
  - id: agency_save_cancel
    speaker: 찰스
    text: '저장하지 않겠습니다. 아직 기록할 업무가 없습니다.'
    end: agency_hub
```

```yaml
scene: agency_kiosk_notice
trigger: 벽 공지 앞에서 확인 키 (대사로는 절대 언급하지 않는다. 환경 텍스트 전용)
nodes:
  - id: agency_kiosk_00
    condition: 'jobs_completed >= 1'
    then: agency_kiosk_02
    else: agency_kiosk_01
  - id: agency_kiosk_01
    speaker: 환경
    text: '[공지] 무인 키오스크 설치 예정: 다음 달'
    end: agency_hub
  - id: agency_kiosk_02
    speaker: 환경
    text: '[공지] 무인 키오스크 설치 예정: 다음 주'
    next: agency_kiosk_03
  - id: agency_kiosk_03
    speaker: 내레이션
    text: "'다음 달'에는 볼펜으로 줄이 그어져 있다."
    end: agency_hub
```

### 1-3. 1207호 현관 `job1_entrance`

```yaml
scene: job1_entrance
trigger: 게시판 수락 후 현장 진입 시 자동
nodes:
  - id: job1_entrance_01
    speaker: 내레이션
    text: '오피스텔 12층, 1207호. 복도 센서등이 한 박자 늦게 켜진다.'
    next: job1_entrance_02
  - id: job1_entrance_02
    speaker: 환경
    text: '[택배 안내] 신형 냉장고 배송 예정: 화요일. 기존 제품 수거 동의: ☑'
    next: job1_entrance_03
  - id: job1_entrance_03
    speaker: 찰스
    text: '화요일입니다.'
    next: job1_entrance_04
  - id: job1_entrance_04
    speaker: 찰스
    text: '특이사항 없습니다. 화요일은 수거가 많은 요일입니다.'
    next: job1_entrance_05
  - id: job1_entrance_05
    speaker: 내레이션
    text: '초인종을 누르기 전에 문이 열렸다.'
    next: job1_entrance_06
  - id: job1_entrance_06
    speaker: 금나래
    text: '소개소에서 오신 거죠? 일찍 오셨네요.'
    next: job1_entrance_07
  - id: job1_entrance_07
    speaker: 찰스
    text: '안녕하십니까, 고객님. 의뢰를 받고 왔습니다.'
    next: job1_entrance_08
  - id: job1_entrance_08
    speaker: 내레이션
    text: '찰스가 90도로 허리를 숙였다. 등의 스티커가 나래 쪽을 향했다.'
    next: job1_entrance_09
  - id: job1_entrance_09
    speaker: 금나래
    text: '...대형폐기물? 등에 그거 붙어 있는 거 알아요?'
    next: job1_entrance_10
  - id: job1_entrance_10
    speaker: 찰스
    text: '알고 있습니다. 정식으로 납부한 것입니다.'   # 캐논 (러닝 개그)
    next: job1_entrance_11
  - id: job1_entrance_11
    speaker: 금나래
    text: '아... 네. 명찰은, 언... 찰스? 언찰스 씨?'
    next: job1_entrance_12
  - id: job1_entrance_12
    speaker: 찰스
    text: '찰스입니다. 앞의 두 글자는 미배정 표시입니다.'
    next: job1_entrance_13
  - id: job1_entrance_13
    speaker: 금나래
    text: '그럼 찰스 씨. 들어오세요. 부엌은 저쪽인데, 못 가요.'
    end: job1_living_intro
```

### 1-4. 거실 겸 침실 `job1_living` (먼지대장 필수 전투)

```yaml
scene: job1_living
trigger: 거실 진입 시 자동 (job1_living_intro)
nodes:
  - id: job1_living_01
    speaker: 내레이션
    text: '거실 겸 침실. 소파 겸 침대. 한쪽만 눌려 있다.'
    next: job1_living_02
  - id: job1_living_02
    speaker: 금나래
    text: '냉장고가 어젯밤부터 부엌 문을 안 열어 줘요. 잠금 기능 같은 건 없었는데.'
    next: job1_living_03
  - id: job1_living_03
    speaker: 금나래
    text: '케이크를 넣어 놨거든요. 어제 생일이었어요. 뭐, 별건 아니고.'
    choices:
      - text: '생일 축하드립니다. 하루 늦었습니다.'
        affinity: {narae: "+"}
        next: job1_living_04a
      - text: '케이크의 보관 상태부터 확인하겠습니다.'
        affinity: {narae: "0"}
        next: job1_living_04b
      - text: '차를 내올까요? 부엌이 잠겨 있어 물이 없습니다.'
        affinity: {narae: "0"}
        next: job1_living_04c
  - id: job1_living_04a
    speaker: 금나래
    text: '...아, 고마워요. 올해는 하루 늦은 게 제일 빠르네요.'
    next: job1_living_05
  - id: job1_living_04b
    speaker: 금나래
    text: '냉장고 안이니까 상하진 않았을 거예요. 아마.'
    next: job1_living_05
  - id: job1_living_04c
    speaker: 금나래
    text: '괜찮아요. 저 원래 아침 안 먹... 아니, 오늘은 먹고 싶었는데.'
    next: job1_living_05
  - id: job1_living_05
    speaker: 내레이션
    text: '바닥에서 모터 소리가 났다. 둥근 것이 찰스의 발목으로 직진해 왔다.'
    next: job1_living_06
  - id: job1_living_06
    speaker: 금나래
    text: '아, 먼지대장. 걔 3년째 똑같은 길로만 돌아요. 조심—'
    battle: dust_chief
    on_persuaded: job1_living_07p
    on_defeated: job1_living_07d
    on_depleted: junkyard_reboot_01
  - id: job1_living_07p
    speaker: 금나래
    text: '어? 걔가 뭘 비켜 가는 거 처음 봐요.'
    next: job1_living_08
  - id: job1_living_07d
    speaker: 금나래
    text: '...뒤집히면 혼자 못 일어나요. 이따 제가 세워 줄게요.'
    next: job1_living_08
  - id: job1_living_08
    speaker: 금나래
    text: '부엌은 저기예요. 침대 옆 체중계는 밟지 마세요. 말이 많아요.'
    end: job1_living
```

### 1-5. 침대 옆 체중계 `job1_fact` (선택 전투)

```yaml
scene: job1_fact
trigger: 침대 옆 체중계 앞에서 확인 키 (선택. 안 밟아도 부엌으로 갈 수 있다)
nodes:
  - id: job1_fact_01
    speaker: 환경
    text: '스마트 체중계. 액정에 작은 글씨: "등록 사용자 1명".'
    choices:
      - text: '올라간다'
        next: job1_fact_02
      - text: '그만둔다'
        next: job1_fact_cancel
  - id: job1_fact_02
    speaker: 내레이션
    text: '찰스가 은쟁반을 든 채 한 발을 올렸다.'
    battle: fact_scale
    on_persuaded: job1_fact_03p
    on_defeated: job1_fact_03d
    on_depleted: junkyard_reboot_01
  - id: job1_fact_03p
    speaker: 찰스
    text: '특이사항 보고. 체중계에 등록되었습니다. 사용자 2번입니다.'
    end: job1_living
  - id: job1_fact_03d
    speaker: 내레이션
    text: '팩트가 조용해졌다. 멀리서 나래가 작게 박수를 쳤다.'
    end: job1_living
  - id: job1_fact_cancel
    speaker: 찰스
    text: '측정을 사양하겠습니다. 쟁반 포함 여부로 다툴 것 같습니다.'
    end: job1_living
```

### 1-6. 잠긴 부엌 앞 → 프로스티 전투 `job1_kitchen_door`

```yaml
scene: job1_kitchen_door
trigger: 부엌 미닫이문 앞에서 확인 키
nodes:
  - id: job1_kitchen_01
    speaker: 내레이션
    text: '부엌 미닫이문. 틈으로 호박빛이 샌다. 안쪽에서 무언가가 문을 버티고 있다.'
    next: job1_kitchen_02
  - id: job1_kitchen_02
    speaker: 환경
    text: '문 너머에서 기계음: "취사가 완료되었습니다."'
    next: job1_kitchen_03
  - id: job1_kitchen_03
    speaker: 금나래
    text: '밥솥이에요. 사흘째 보온이에요. 끌 시간이 없었어요.'
    next: job1_kitchen_04
  - id: job1_kitchen_04
    speaker: 내레이션
    text: '찰스가 문을 두 번 두드렸다. 정확히 두 번.'
    next: job1_kitchen_05
  - id: job1_kitchen_05
    speaker: 찰스
    text: '실례합니다. 소개소에서 왔습니다.'
    next: job1_kitchen_06
  - id: job1_kitchen_06
    speaker: 프로스티
    text: '소개소? 교체 기사구나! 나 수거하러 왔지!'
    next: job1_kitchen_07
  - id: job1_kitchen_07
    speaker: 찰스
    text: '아닙니다. 저는 교체되는 쪽입니다.'
    next: job1_kitchen_08
  - id: job1_kitchen_08
    speaker: 프로스티
    text: '...거짓말. 화요일에 새 게 온대. 나 주문 내역 다 봤어.'
    next: job1_kitchen_09
  - id: job1_kitchen_09
    speaker: 금나래
    text: '...그걸 봤구나.'
    next: job1_kitchen_10
  - id: job1_kitchen_10
    speaker: 프로스티
    text: '이 집에선 이제 아무것도 안 버려. 요거트도. 케이크도. 나도.'
    next: job1_kitchen_11
  - id: job1_kitchen_11
    speaker: 프로스티
    text: '들어와 봐. 들어올 수 있으면.'
    next: job1_kitchen_12
  - id: job1_kitchen_12
    speaker: 내레이션
    text: '철컥. 잠금이 풀렸다.'
    battle: frosty   # intro_line(캐논) "문을 열자 냉장고가 포효했다..."로 이어진다
    on_persuaded: job1_end_p_01
    on_defeated: job1_end_d_01
    on_depleted: junkyard_reboot_01
```

### 1-7. 결과별 결말 `job1_end_persuaded` / `job1_end_defeated`

전투의 `persuaded_line` / `defeated_line`이 먼저 나온 뒤 이 노드들이 이어진다. 프로스티의 캐논 대사는 반복하지 않는다.

```yaml
scene: job1_end_persuaded
nodes:
  - id: job1_end_p_01
    affinity: {narae: "+"}   # ⚑ 캐논: 설득 결말 호감도 +
    set_flag: job1_frosty_persuaded   # ⚑
    speaker: 내레이션
    text: '냉기가 멎었다. 프로스티 안쪽의 호박빛만 남았다.'
    next: job1_end_p_02
  - id: job1_end_p_02
    speaker: 찰스
    text: '프로스티 고객님, 감사합니다. 다만 저는 먹지 않습니다.'
    next: job1_end_p_03
  - id: job1_end_p_03
    speaker: 내레이션
    text: '작은 케이크 상자. 숫자 초 3과 4가 꽂혀 있다.'
    next: job1_end_p_04
  - id: job1_end_p_04
    speaker: 내레이션
    text: '찰스가 찬장에서 접시를 꺼냈다. 케이크를 옮겨 담고, 포크를 곁에 놓았다.'
    next: job1_end_p_05
  - id: job1_end_p_05
    speaker: 찰스
    text: '고객님. 하루 늦은 생일 케이크입니다. 아침 식사로 내겠습니다.'
    next: job1_end_p_06
  - id: job1_end_p_06
    speaker: 금나래
    text: '...누가 내 생일 케이크를 접시에 담아 준 거, 처음이에요.'   # 캐논
    next: job1_end_p_07
  - id: job1_end_p_07
    speaker: 금나래
    text: '아침이 케이크네요. 유통기한은 어제지만.'
    next: job1_choice_01
```

```yaml
scene: job1_end_defeated
nodes:
  - id: job1_end_d_01
    set_flag: job1_frosty_defeated   # ⚑ 캐논: 제압 결말 호감도 0 (변화 없음)
    speaker: 내레이션
    text: '프로스티의 문이 힘없이 열렸다. 안쪽 불빛이 꺼졌다.'
    next: job1_end_d_02
  - id: job1_end_d_02
    speaker: 내레이션
    text: '케이크는 은쟁반 모양대로 납작해져 있었다.'
    next: job1_end_d_03
  - id: job1_end_d_03
    speaker: 금나래
    text: '고마워요. 어차피 화요일에 새 거 와요.'   # 캐논
    next: job1_end_d_04
  - id: job1_end_d_04
    speaker: 찰스
    text: '특이사항 없습니다.'   # 캐논
    next: job1_end_d_05
  - id: job1_end_d_05
    speaker: 내레이션
    text: '찰스가 쟁반을 닦았다. 평소보다 2초 길었다.'
    next: job1_end_d_06
  - id: job1_end_d_06
    speaker: 금나래
    text: '아침은 편의점에서 먹을게요.'
    next: job1_choice_01
```

### 1-8. 철학적 선택 `job1_choice` → 작별 `job1_farewell`

선택지 3개와 호감도 방향은 캐논 그대로다. 두 결말 경로 모두 여기로 온다.

```yaml
scene: job1_choice
nodes:
  - id: job1_choice_01
    speaker: 내레이션
    text: '나래가 현관에서 택배 안내문을 떼어 왔다.'
    next: job1_choice_02
  - id: job1_choice_02
    speaker: 금나래
    text: '찰스 씨, 멀쩡한데 더 좋은 게 나오면… 바꾸는 게 맞죠?'   # 캐논
    choices:
      - text: '바꾸십시오. 더 나은 것이 고객님께 맞습니다.'   # 캐논
        affinity: {narae: "−"}
        next: job1_choice_a1
      - text: '고장 나지 않았습니다. 그는 고객님의 생일을 기억했습니다.'   # 캐논
        affinity: {narae: "++"}
        next: job1_choice_b1
      - text: '프로스티를 소개소에 등록하겠습니다. 다음 주인을 찾을 수 있습니다.'   # 캐논
        affinity: {narae: "+"}
        next: job1_choice_c1
  # --- (a) 바꾼다 ---
  - id: job1_choice_a1
    set_flag: job1_choice_replace   # ⚑
    speaker: 금나래
    text: '...그렇죠. 맞아요. 다들 그렇게 해요.'
    next: job1_choice_a2
  - id: job1_choice_a2
    speaker: 내레이션
    text: '나래가 안도한 듯 웃었다. 웃음 말고는 아무것도 없었다.'
    next: job1_farewell_00
  # --- (b) 주문 취소 ---
  - id: job1_choice_b1
    set_flag: job1_choice_keep   # ⚑ 신형 주문 취소
    speaker: 금나래
    text: '생일을... 기억했다고요?'
    next: job1_choice_b2
  - id: job1_choice_b2
    speaker: 내레이션
    text: '나래가 휴대폰을 한참 보다가, 버튼 하나를 눌렀다.'
    next: job1_choice_b3
  - id: job1_choice_b3
    speaker: 환경
    text: '[알림] 고객님의 주문이 취소되었습니다.'
    next: job1_choice_b4
  - id: job1_choice_b4
    speaker: 찰스
    text: '특이사항 보고. 이 알림음을 들은 적이 있습니다. 그때는 해지였습니다.'
    next: job1_choice_b5
  - id: job1_choice_b5
    speaker: 금나래
    text: '...반품 수수료 아까워서 그러는 거예요. 그런 거예요.'
    next: job1_farewell_00
  # --- (c) 소개소 등록 ---
  - id: job1_choice_c1
    set_flag: frosty_registered   # ⚑ 소개소 카메오 조건
    speaker: 금나래
    text: '냉장고도 거기 등록돼요?'
    next: job1_choice_c2
  - id: job1_choice_c2
    speaker: 찰스
    text: '주인이 없는 것은 모두 분실물입니다. 저도 그렇습니다.'
    next: job1_choice_c3
  - id: job1_choice_c3
    speaker: 금나래
    text: '...그럼 부탁할게요. 걔, 좋은 데 갔으면 좋겠어요.'
    next: job1_farewell_00
```

```yaml
scene: job1_farewell
nodes:
  - id: job1_farewell_00
    condition: 'affinity.narae >= threshold_narae_warm'
    then: job1_farewell_w1
    else: job1_farewell_n1
  - id: job1_farewell_w1
    speaker: 금나래
    text: '찰스 씨, 다음에도 소개소에 부탁하면... 찰스 씨가 와요?'
    next: job1_farewell_w2
  - id: job1_farewell_w2
    speaker: 찰스
    text: '배정은 게시판이 정합니다. 다만 저는 1207호를 기억하겠습니다.'
    next: job1_farewell_w3
  - id: job1_farewell_w3
    speaker: 금나래
    text: '그럼 됐어요. 다녀오세... 아, 나가는 건 저구나.'
    end: return_to_agency
  - id: job1_farewell_n1
    speaker: 금나래
    text: '수고하셨어요. 리뷰 별 다섯 개 드릴게요.'
    next: job1_farewell_n2
  - id: job1_farewell_n2
    speaker: 찰스
    text: '감사합니다. 별은 소개소로 전달하겠습니다.'
    end: return_to_agency
```

### 1-9. 소개소 복귀 `agency_return_job1`

```yaml
scene: agency_return_job1
trigger: 의뢰 1 완료 후 소개소 도착 시 자동 (보상 지급 직후)
nodes:
  - id: agency_return_01
    speaker: 내레이션
    text: '소개소. 형광등 하나가 여전히 깜빡인다.'
    next: agency_return_02
  - id: agency_return_02
    speaker: 오 실장
    text: '1129번. 보상 {reward}원 들어왔어. 잔액 {money}원.'
    next: agency_return_03
  - id: agency_return_03
    speaker: 오 실장
    text: '냉장고랑 싸웠다며.'
    next: agency_return_04
  - id: agency_return_04
    speaker: 찰스
    text: '부엌은 열렸습니다. 케이크는 회수되었습니다.'
    next: agency_return_05
  - id: agency_return_05
    speaker: 오 실장
    text: '그거 물은 거 아냐. 배터리 몇이야.'
    next: agency_return_06
  - id: agency_return_06
    speaker: 찰스
    text: '특이사항 보고. 돌아오는 길에 1207호 창문을 두 번 돌아봤습니다. 원인은 불명입니다.'
    next: agency_return_07
  - id: agency_return_07
    speaker: 오 실장
    text: '감정은 접수 안 받아. ...자판기 커피는 받고.'   # 캐논
    next: agency_return_08
  - id: agency_return_08
    speaker: 내레이션
    text: '오 실장이 자판기 커피 한 잔을 책상 끝에 놓았다.'
    next: agency_return_09
  - id: agency_return_09
    speaker: 찰스
    text: '저는 마시지 못합니다.'
    next: agency_return_10
  - id: agency_return_10
    speaker: 오 실장
    text: '알아. 받으라고.'
    next: agency_return_11
  - id: agency_return_11
    condition: 'flag.frosty_registered'
    then: agency_return_12f
    else: agency_return_14
  - id: agency_return_12f
    speaker: 내레이션
    text: '구석에 냉장고 한 대가 서 있다. 명찰: UN-FROSTY.'
    next: agency_return_13f
  - id: agency_return_13f
    speaker: 프로스티
    text: '...유통기한은 아직 안 정했어.'
    next: agency_return_14
  - id: agency_return_14
    speaker: 내레이션
    text: '벽의 공지가 바뀌어 있다.'
    next: agency_return_15
  - id: agency_return_15
    speaker: 환경
    text: '[공지] 무인 키오스크 설치 예정: 다음 주'
    next: agency_return_16
  - id: agency_return_16
    speaker: 내레이션
    text: "'다음 달'에는 볼펜으로 줄이 그어져 있다."
    end: agency_hub
```

### 1-10. 폐기 처리장 재부팅 `junkyard_reboot` → `agency_after_reboot`

슬라이스는 1회차만 쓴다. 2~5회차 캐논 대사는 아래 Story 004용 블록에 데이터로만 옮겨 두었다.

```yaml
scene: junkyard_reboot
trigger: 어느 전투든 on_depleted
nodes:
  - id: junkyard_reboot_01
    speaker: 내레이션
    text: '암전. 그리고 위에서 한 줄기 빛.'
    next: junkyard_reboot_02
  - id: junkyard_reboot_02
    speaker: 내레이션
    text: '고철 더미 위에서 찰스의 눈에 시안 불이 들어왔다. 재부팅 완료.'
    next: junkyard_reboot_03
  - id: junkyard_reboot_03
    condition: 'reboot_count == 1'   # 카운트는 이 씬 진입 전에 증가한다고 가정
    then: junkyard_reboot_c1a
    else: junkyard_reboot_c2   # Story 004 블록
  - id: junkyard_reboot_c1a
    speaker: 엔디
    text: '스티커 확인! 정식 폐기물이시군요. 이렇게 성실한 분은 오랜만이에요.'   # 캐논
    next: junkyard_reboot_c1b
  - id: junkyard_reboot_c1b
    speaker: 엔디
    text: '환영합니다! 고객님은 폐기 대기 4,812번입니다. 예상 대기 시간은 11년. 그냥 가셔도 됩니다.'   # 캐논
    next: junkyard_reboot_common
  - id: junkyard_reboot_common
    speaker: 엔디
    text: '수거 비용 {money_lost}원이 차감되었습니다. 회수한 기억은 재활용됩니다. 좋은 데 쓰일 거예요.'   # 캐논
    choices:
      - text: '신세 졌습니다. 다음에는 정식으로 버려지도록 노력하겠습니다.'   # 캐논
        next: junkyard_reboot_exit
      - text: '(말없이 일어선다)'
        next: junkyard_reboot_exit
  - id: junkyard_reboot_exit
    speaker: 엔디
    text: '출구는 저쪽이에요! 나가시면서 만족도 조사도 부탁드려요. 제 KPI예요.'
    end: return_to_agency
```

```yaml
# Story 004용 (슬라이스 밖) — 캐논 대사를 데이터로만 옮겨 둠
scene: junkyard_reboot_ext
nodes:
  - id: junkyard_reboot_c2
    condition: 'reboot_count == 2'
    then: junkyard_reboot_c2_line
    else: junkyard_reboot_c3
  - id: junkyard_reboot_c2_line
    speaker: 엔디
    text: '또 오셨네요! 적립 스탬프 2개째입니다. 10개 모으시면 무료 압축 1회를 드려요.'   # 캐논
    next: junkyard_reboot_common
  - id: junkyard_reboot_c3
    condition: 'reboot_count == 3'
    then: junkyard_reboot_c3_line
    else: junkyard_reboot_c4
  - id: junkyard_reboot_c3_line
    speaker: 엔디
    text: "고객님 자리를 따로 마련해 뒀어요. 이름표도 붙였어요. 'UN-CHARLES 지정석'."   # 캐논
    next: junkyard_reboot_common
  - id: junkyard_reboot_c4
    condition: 'reboot_count == 4'
    then: junkyard_reboot_c4_line
    else: junkyard_reboot_c5
  - id: junkyard_reboot_c4_line
    speaker: 엔디
    text: 'KPI상 고객님은 저희 최우수 재방문 고객이세요. 축하드려요. 이건 칭찬이 아닙니다.'   # 캐논
    next: junkyard_reboot_common
  - id: junkyard_reboot_c5
    speaker: 엔디
    text: '...고객님. 여기는 돌아오는 곳이 아니에요. 저는 아무도 기다리지 않게 만들어졌거든요. 그러니까, 가 주세요.'   # 캐논 (5회 이상)
    next: junkyard_reboot_common
```

```yaml
scene: agency_after_reboot
trigger: 재부팅 후 소개소 도착 시 자동
nodes:
  - id: agency_reboot_01
    speaker: 내레이션
    text: '소개소. 찰스가 문을 열고 들어왔다. 연미복에 녹 가루가 묻어 있다.'
    next: agency_reboot_02
  - id: agency_reboot_02
    speaker: 오 실장
    text: '1129번. 실려 갔다 왔다며.'
    next: agency_reboot_03
  - id: agency_reboot_03
    speaker: 찰스
    text: '기록이 없습니다. 제가 어디에 다녀왔습니까?'
    next: agency_reboot_04
  - id: agency_reboot_04
    speaker: 오 실장
    text: '1207호. 냉장고.'
    next: agency_reboot_05
  - id: agency_reboot_05
    speaker: 찰스
    text: '확인했습니다. 다시 다녀오겠습니다.'
    next: agency_reboot_06
  - id: agency_reboot_06
    speaker: 오 실장
    text: '충전부터 해. ...돈 있으면.'
    end: agency_hub
```

---

## 2. 의뢰 1 현장 적 (BattleEnemy 데이터)

### 고른 2종: 먼지대장 + 팩트 (보온72는 문 너머 환경 음성으로만)

- **먼지대장(필수)**: 거실 바닥이 무대라 동선에 자연스럽다. "발목 들이받기"는 첫 전투로 읽기 쉬운 위협이다. "3년째 같은 동선"이 의뢰의 질문(대체)과 맞닿는다. 이 집에서 3년 동안 새로 들어온 게 없었다는 사실을 대사 없이 보여 준다.
- **팩트(선택)**: 침대 옆에 자연스럽게 둘 수 있다. 은쟁반 무게 개그로 찰스의 고유 소품을 쓴다. 액정의 "등록 사용자 1명"이 혼자 사는 나래를 설명 없이 보여 준다.
- **보온72(제외)**: 밥솥은 부엌 안의 가전이다. 부엌은 프로스티 전투 전까지 잠겨 있어야 하므로 동선이 충돌한다. 대신 잠긴 문 너머의 "취사가 완료되었습니다."(환경 텍스트)로만 등장시켜 사흘째 꺼지지 않은 밥솥을 보여 준다. 전투는 재방문이나 확장 때 후보로 남긴다.

```yaml
- id: dust_chief
  display_name: "로봇청소기 '먼지대장'"
  portrait: TBD
  max_hp: TBD
  attack_power: TBD
  persuade_max: TBD
  intro_line: '먼지대장이 찰스의 발목을 들이받았다. "장애물 감지! 새 장애물입니다. 3년 만입니다."'
  attack_lines:
    - '먼지대장이 찰스의 왼쪽 발목을 들이받았다. 배터리 {damage}% 감소.'
    - '먼지대장이 후진했다가 다시 들이받았다. 아까와 같은 자리였다. 배터리 {damage}% 감소.'
    - '먼지대장이 연미복 꼬리를 빨아들였다. "이물질 감지." 배터리 {damage}% 감소.'
  defeated_line: '먼지대장이 뒤집혔다. 바퀴가 허공에 3년 치 동선을 마저 그렸다.'
  persuaded_line: '먼지대장이 찰스를 비켜 돌았다. "동선 갱신 완료. ...장애물 아님. 손님."'
  depleted_line: '찰스가 쓰러졌다. 먼지대장이 찰스를 장애물로 등록하고 둘레를 돌기 시작했다.'

- id: fact_scale
  display_name: "스마트 체중계 '팩트'"
  portrait: TBD
  max_hp: TBD
  attack_power: TBD
  persuade_max: TBD
  intro_line: '체중계가 불을 켰다. "올라오세요. 숫자는 거짓말을 안 합니다. 쟁반도 같이요."'
  attack_lines:
    - '"쟁반 빼면 반칙입니다!" 팩트가 숫자를 외쳤다. 배터리 {damage}% 감소.'
    - '"어제보다 무겁습니다!" 처음 재는 것이었다. 배터리 {damage}% 감소.'
    - '"BMI 판정: 연미복!" 팩트가 아무 숫자나 외쳤다. 배터리 {damage}% 감소.'
  defeated_line: '팩트의 액정이 꺼졌다. 마지막 숫자는 0.0이었다. 거짓말은 아니었다.'
  persuaded_line: '팩트가 조용히 측정을 마쳤다. "사용자 2명 등록. ...이 집에서 처음입니다."'
  depleted_line: '찰스가 팩트 위로 쓰러졌다. "측정 불가. 너무 무겁습니다. 쟁반 포함."'

# 프로스티 — 기존 dummy_enemy.tres의 대사를 한 글자도 바꾸지 않고 id만 frosty로 옮긴다
- id: frosty
  display_name: "폭주 냉장고 '프로스티'"
  portrait: TBD   # 기존 프로스티 스프라이트
  max_hp: TBD
  attack_power: TBD
  persuade_max: TBD
  intro_line: '문을 열자 냉장고가 포효했다. "유통기한은 내가 정한다!"'   # 캐논
  attack_lines:   # 기존 데이터 그대로
    - '프로스티가 유통기한 지난 요거트를 던졌다! 배터리 {damage}% 감소.'
    - '프로스티가 냉동실 문으로 찰스를 끼웠다. "신선도 검사다!" 배터리 {damage}% 감소.'
    - '프로스티가 제빙기에서 얼음을 난사했다. 배터리 {damage}% 감소.'
  defeated_line: '프로스티의 컴프레서가 멎었다. 안에 있던 요거트가 조용히 상하기 시작했다.'   # 기존 데이터
  persuaded_line: '프로스티가 문을 천천히 닫았다. "...알겠어. 안의 케이크는 네가 먹어. 유통기한은 어제였지만."'   # 캐논
  depleted_line: '찰스의 눈이 꺼졌다. 마지막으로 본 것은 유통기한 임박 스티커였다.'   # 기존 데이터
```

프로스티의 전투 앞뒤 대사는 1-6(문 앞)과 1-7(결말)에 있다.

---

## 3. 찰스 신규 커맨드 제안 (최대 2개, 수치 TBD)

두 현장 적 모두 그 장면에서만 통하는 설득 대사가 필요하다. 이유는 아래 4번 CONCERN을 참고한다.

```yaml
- id: persuade_route_guide
  display_name: '동선 안내'
  kind: PERSUADE
  persuade_amount: TBD
  result_line: '찰스가 비켜 서서 손바닥으로 길을 가리켰다. "이쪽으로 모시겠습니다." 먼지대장이 처음으로 방향을 틀었다. 설득 +{persuade}.'
  # 대상: 먼지대장. 3년 동안 아무도 길을 비켜 준 적이 없었다는 데서 나온 대사.

- id: persuade_weigh_in
  display_name: '쟁반 포함 계량'
  kind: PERSUADE
  persuade_amount: TBD
  result_line: '찰스가 은쟁반을 든 채 정중히 올라섰다. "쟁반 포함입니다." 팩트의 숫자가 만족스럽게 깜빡였다. 설득 +{persuade}.'
  # 대상: 팩트. 우기는 상대의 규칙을 그대로 따라 주는 것이 곧 설득이다.
```

---

## 4. 로어·비주얼 노트

### 4-1. 1207호 방별 환경 소품 (전부 Provisional)

아트 규칙: 대부분 탁하게 두고 **방마다 켜진 점은 하나**(시안 또는 호박, 화면 면적 10% 이하)만 둔다. 켜진 점은 ★로 표시했다.

**현관**
- 문에 붙은 택배 안내문: "신형 냉장고 배송 예정: 화요일. 기존 제품 수거 동의: ☑". 체크 표시는 볼펜으로 했다.
- 신발장 위 구두 한 켤레. 오른쪽 앞코만 닳았다. 매일 같은 쪽 발로 문을 밀고 나간다.
- 신발장 위 카드사 우편: "생일 축하 쿠폰: 커피 1잔 (유효기간: 어제까지)". 생일을 기억한 곳은 카드사뿐이었다.
- ★ 도어락 키패드의 시안 숫자판. 현관에서 유일하게 켜진 것.
- 현관 센서등은 고장 나서 꺼져 있다.

**거실 겸 침실**
- 소파 겸 침대. 한쪽만 사람 모양으로 눌려 있다.
- 바닥 먼지 속에 먼지대장의 3년 치 동선 자국. 그 고리 모양 안쪽만 깨끗하다. 고리 밖은 3년 동안 아무것도 지나가지 않았다.
- 침대 옆 체중계 팩트. 꺼진 액정 위에 "등록 사용자 1명"이 흐릿하게 남아 있다.
- 벽 달력. 어제 칸에만 작은 글씨: "케이크 찾기(퇴근 후)".
- ★ 덮인 노트북의 충전 LED(호박빛) 한 점. 회사가 이 방에서 유일하게 깨어 있다.

**잠긴 부엌 (문 앞 → 전투 배경 → 결말)**
- ★ 미닫이문 틈으로 새는 호박빛(프로스티 내부광). 거실에서 문을 볼 때는 이것이 켜진 점이다.
- 문 위쪽 유리에 서린 김. 사흘째 보온 중인 보온72가 문 너머에 있다는 흔적.
- 프로스티 문짝의 자석 문자: "유통기한 심사중". 배달앱 쿠폰 자석이 일곱 개 붙어 있고, 사진은 한 장도 없다.
- 프로스티 안쪽 칸칸이 정렬된 '버리지 못하게 된 것들': 요거트 세 개, 뚜껑에 날짜를 적은 반찬통, 1인용 케이크 상자(숫자 초 3·4).
- 제압 결말에서는 부엌의 켜진 점이 전부 꺼진다(아트 바이블 '제압 = 광원이 꺼짐').

### 4-2. 캐릭터 스프라이트 노트 (art-director 겸임, 초안)

실루엣 규칙: 32px 검은 실루엣으로 구분한다. 인간은 곡선과 비대칭을 쓴다. 구분 특징은 1개다.

- **오 실장(오미자)**
  - 실루엣: 창구 뒤에 앉은 반신이 기본 자세다. 둥근 등과 한쪽으로 기운 어깨로 비대칭을 만든다. 로봇들의 각진 수직선과 대비된다.
  - 구분 특징: **손에 든 컵라면과 그 위로 올라가는 김 한 줄.** 김은 곡선(아트 바이블에서 곡선은 온기)이고, 색은 탁한 회백색이다. 켜진 색이 아니다.
  - 그 밖: 낡은 강철색 작업 조끼에 라벨 테이프 명찰 "야간". 실루엣에는 영향이 없는 작은 세부다.
- **금나래**
  - 실루엣: 34세 회사원이 출근 준비를 하다 만 차림이다. 어깨에서 한쪽으로 흘러내린 큰 카디건이 비대칭을 만든다.
  - 구분 특징: **정수리의 큰 집게핀.** 32px에서는 머리 위 돌기로 읽힌다. 머리를 묶다 만 피곤함이 보인다.
  - 주인 accent 색은 art-director가 확정할 몫이다. 후보는 케이크 크림의 **탁한 분홍**이다(제안일 뿐이다).
- **찰스 등의 대형폐기물 스티커**
  - 위치: 견갑골 사이, 등 중앙보다 약간 위. 가로형 직사각형이다.
  - 문구(도트로 읽힐 만큼만): "대형폐기물 / 3,000원 / 납부필".
  - 색: 바랜 종이 흰색(탁한 색). 시안·호박은 쓰지 않는다. 위쪽 모서리 하나가 들떠 있다.
  - 디테일: 위쪽에 테이프 자국 두 개가 있다. 사흘 뒤 누군가 붙인 소개소 전단지를 떼어 낸 흔적이다.
  - 노출: 위쪽 방향 걷기 프레임과 90도 인사 컷에서만 보인다. 정면 실루엣은 바꾸지 않는다. 탐험 중 위로 걸을 때마다 러닝 개그가 화면에 보인다.

### 4-3. 이 문서에서 새로 정한 소품 설정 (Provisional, 기존 캐논과 충돌 없음)

- 찰스의 소개소 등록번호 **1129**. 명찰은 캐논대로 UN-CHARLES이고, 오 실장만 번호로 부른다.
- 소개소 명찰 규칙은 가전에도 적용된다: 등록된 프로스티는 **UN-FROSTY**.
- 양식 0번은 슬라이스에서 **제목만** 보인다. 본문은 국물 자국에 가려져 있다. 정체(자기 소유 신고서)는 엔딩까지 숨긴다.
- 의뢰 1은 새벽 출근 전에 일어난다. 엔딩의 "밤 11시"와 겹치지 않는다.

---

## 5. 열린 항목

- [game-designer] 수치 전부 TBD: 세 적의 max_hp·attack_power·persuade_max, `{reward}`, `{money_lost}`, 충전 비용, `threshold_narae_warm`, 호감도 `+`/`++`/`−`의 실제 값.
- [game-designer] 현장 적(먼지대장·팩트)의 결과가 나래 호감도를 바꾸는가? 초안에서는 바꾸지 않았다.
- [game-designer] 팩트 전투를 선택으로 둘지 필수로 둘지. 초안은 선택이다.
- [game-designer] 방전 후 의뢰 1의 진행이 처음부터 다시 시작되는가? 그 회차에 얻은 나래 호감도는 남는가? (캐논: 진행 중 의뢰의 기억을 잃는다)
- [game-designer] 신규 커맨드 2종을 해당 적과 싸울 때만 보이게 할지, 늘 보이게 할지.
- [programmer] ⚑ 확장 5종(노드 단위 affinity, set_flag, flag·jobs_completed·reboot_count 조건, action, `end: <맵>`)을 Story 002/003에서 지원할지.
- [programmer] 충전 비용을 보여 줄 플레이스홀더가 없다(`{charge_cost}` 같은 것이 필요한가?).
- [narrative-director] 프로스티 카메오를 복귀 직후 바로 보여 줄지, 다음 방문부터 보여 줄지. 초안은 복귀 직후다.
- [narrative-director] 재도전 때 나래는 찰스를 기억하는데 찰스는 기억하지 못하는 장면(재방문 변형 대사)을 넣을지. 초안에는 없다.
- [art-director] 금나래 accent 색 확정, 그리고 오 실장·금나래 스프라이트 실루엣 검토.

### 결정 (2026-11-03, 사용자 "진행" — 권장안)
- ⚑ 확장 5종은 지원한다. 노드 단위 affinity, `set_flag`, `flag.*`·`jobs_completed`·`reboot_count` 조건, `end: <맵>`은 Story 002(대화 시스템)에서 구현한다. `action:`은 대화 시스템이 이벤트로 내보내기만 하고, 실제 의뢰 수락·충전·저장 동작은 Story 003이 맡는다.
- 전투 커맨드 결과 문구는 적 이름을 `{enemy}` 자리표시자로 부른다(프로스티 고정 이름 제거).
- 충전 비용 자리표시자 `{charge_cost}`를 허용 목록에 추가한다.
- 방전 후 처리는 Story 004 기준을 따른다. 의뢰 1은 시작 시점으로 되돌아가고, 그 시도에서 얻은 나래 호감도는 사라진다.
- 수치(HP·공격력·설득 최대치·보상·수거 비용·충전 비용·임계값·호감도 단계값)는 구현 때 임시값을 넣고 `# TUNE` 표시로 남긴다. 나머지 game-designer·narrative-director·art-director 항목은 위 목록대로 열린 채로 둔다.
