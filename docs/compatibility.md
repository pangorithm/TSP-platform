# 호환성 정책

## 기준

`repositories.json`의 `protocols`가 현재 통합 기준입니다.

- `restApiMajor`: REST URL major. 현재 `/api/v1`의 `v1`
- `webSocketProtocol`: WebSocket envelope의 숫자형 `version`

REST major 또는 WebSocket protocol version을 올릴 때는 기존 소비자의 지원 종료 시점과 migration 경로를 먼저 문서화합니다.

## ref 정책

기반 저장소의 `ciRef`는 기본 branch의 최신 호환성을 지속적으로 확인합니다. 실제 게임 저장소는 재현 가능한 template tag 또는 commit을 `templateRef`에 기록하고, backend protocol version은 명시적으로 고정합니다.

초기 개발 중에는 `main` 통합 검사를 사용합니다. 첫 안정 릴리스부터는 component tag 조합을 추가해 최신 조합과 출시 조합을 모두 확인합니다.

## 실패 처리

통합 CI가 실패하면 공개 계약을 변경한 저장소가 다음 중 하나를 제공합니다.

1. 기존 소비자와 호환되는 구현
2. 새 major 또는 protocol version
3. 소비자 migration과 두 버전의 전환 기간

단순히 상위 CI의 검사를 삭제하거나 하위 저장소의 품질 게이트를 완화해서 해결하지 않습니다.
