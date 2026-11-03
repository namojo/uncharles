# Epic: Uncharles MVP

> **Source**: `design/game-brief.md` (workflow: minimal — no GDD, no ADRs)
> **Engine**: Godot 4.7 (GDScript)

## Goal

주인에게 버림받은 안드로이드 집사 찰스가 로봇 직업소개소의 알바를 전전하며 인간 주인들의 블랙코미디 같은 사연을 해결하고, 자신을 사랑해 줄 단 한 명의 주인을 고르는(혹은 고르지 않는) B급 도트 RPG.

## Scope (brief MVP)

1. 도트 탐험 + 소개소 허브 (의뢰 선택·배터리 충전·저장)
2. 턴제 전투 + 설득 커맨드 (배터리=HP, 설득으로 비폭력 해소 가능)
3. 대사·선택지 시스템 + 주인별 호감도
4. 알바 의뢰 3건 (= 주인 후보 3명, 의뢰당 현장 1곳)
5. 폐기 처리장 재부팅 (실패 루프)
6. 엔딩 4종 (후보 3명 중 선택 3 + 독립 1)

Out of scope: see `design/game-brief.md` § Out of scope.

## Order

Brief § Build order: 전투+설득 → 대사·호감도 → 허브·탐험·재부팅 → 의뢰 3건·엔딩 → 아트·사운드 폴리시.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 턴제 전투 + 설득 커맨드 | Logic | Ready | N/A (minimal) |
| 002 | 대사·선택지 + 주인별 호감도 | Logic | Ready | N/A (minimal) |
| 003 | 도트 탐험 + 소개소 허브 | Integration | Ready | N/A (minimal) |
| 004 | 폐기 처리장 재부팅 | Logic | Ready | N/A (minimal) |
| 005 | 알바 의뢰 3건 | Integration | Ready | N/A (minimal) |
| 006 | 엔딩 4종 | Logic | Ready | N/A (minimal) |
