---
title: Lint Rules
last_updated: 2026-04-15
---

# 린트 규칙

## 소스 파일 필수 frontmatter
- title: 필수
- source_id: 필수 (형식: {type}-{YYYY-MM-DD}-{NNN})
- date: 필수 (YYYY-MM-DD)
- author: 필수
- type: 필수 (support-ticket | incident-report | external-article | runbook)
- classification: 필수 (public | internal | restricted). 기본값 없음
- tags: 필수 (배열)
- aliases: 권장 (배열, 검색/그래프용 대체 이름)

## 위키 페이지 필수 frontmatter
- title: 필수
- canonical_id: 필수 (영문 kebab-case, 파일명과 동일)
- domain: 필수 (ontology.md의 도메인 중 하나)
- tags: 필수 (배열)
- aliases: 권장 (배열)
- status: 필수 (current | conflict | retired)
- last_reviewed: 필수 (YYYY-MM-DD)
- sources: 필수 (배열, 각 항목에 source_id)

## 파일명 규칙
- 소스: {YYYY-MM-DD}-{NNN}.md (예: 2026-04-15-001.md)
- 위키: 영문 kebab-case (예: eks-node-scaling-failure.md)
- 한국어 제목은 frontmatter title 필드에만

## LLM + Graphify 필수 규칙
1. ATX 헤딩만 사용: # ## ###
2. 명시적 내부 링크: [[canonical_id]] 또는 [[제목]]
3. generic heading 금지: "상세", "기타", "메모" 대신 "원인", "진단", "해결"
4. canonical name 1개 + aliases 보조: 중복 페이지 대신 alias로 흡수
5. 표/리스트 앞뒤에 설명 문장 추가
6. 한 섹션에 여러 주제 섞지 않기: 길어지면 새 문서로 분리

## 문서 단위 원칙
- 한 파일 = 한 주제
- H1은 1개만, H2는 3~6개
- 각 H2는 혼자 잘려 나가도 이해되는 단위

## 소스 본문 구조
요약 → 증상 → 환경 → 원인 → 해결 → 예방 → 관련 엔티티

## 위키 본문 구조
한 줄 요약 → 언제 의심할까 → 대표 원인 → 진단 방법 → 해결 방법 → 관련 문서

## 품질 게이트
- 모든 소스는 classification 필드 필수 (미분류 시 거부)
- restricted 소스에서 위키 합성 시 PII 제거 필수
