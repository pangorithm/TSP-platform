# TSP 플랫폼

`TSP-platform`은 TSP 기반 저장소의 관계, 호환성, 로컬 작업 방식과 통합 CI를 관리하는 상위 메타 저장소입니다.

실제 애플리케이션 소스는 각 저장소가 독립적으로 소유합니다. 이 저장소는 하위 저장소의 코드를 복사하거나 Git submodule로 포함하지 않습니다.

## 저장소

| 저장소 | 역할 |
| --- | --- |
| [`TSP-template`](https://github.com/pangorithm/TSP-template) | Tauri v2, SolidJS, Phaser 기반 게임 클라이언트 템플릿 |
| [`TSP-backend`](https://github.com/pangorithm/TSP-backend) | 여러 게임이 공유하는 REST·WebSocket 백엔드 기반 |
| [`TSP-bastion-gambit`](https://github.com/pangorithm/TSP-bastion-gambit) | 체스에서 영감을 받은 전략 디펜스 게임 |
| 게임 저장소 | `TSP-template`에서 시작해 게임별 코드, 에셋, 출시 정책을 소유 |

등록된 저장소와 공통 프로토콜 버전은 [`repositories.json`](repositories.json)에 기록합니다.

## 로컬 작업공간 준비

이 저장소와 구성 저장소는 같은 디렉터리 아래에 나란히 둡니다.

```text
TSP-workspace/
├─ TSP-platform/
├─ TSP-template/
├─ TSP-backend/
└─ <game-repository>/
```

Windows PowerShell:

```powershell
.\scripts\bootstrap.ps1
```

macOS 또는 Linux:

```bash
bash scripts/bootstrap.sh
```

스크립트는 없는 저장소만 clone합니다. 이미 존재하는 저장소는 `origin`이 등록된 URL과 일치하는지만 확인하며 pull, reset 또는 checkout을 수행하지 않습니다.

## 통합 확인

각 저장소는 자체 CI에서 빌드, 단위 테스트, 린트와 플랫폼 검사를 소유합니다. 이 저장소의 통합 CI는 다음 경계만 함께 확인합니다.

1. `repositories.json`의 구조와 등록 정보
2. `TSP-template`의 타입 검사와 계약 테스트
3. `TSP-backend`의 Rust 테스트
4. 실행 중인 백엔드의 `/api/v1/health/ready`와 `/api/v1/echo` 계약

로컬 백엔드 계약 확인:

Rust 1.98.1 toolchain이 필요합니다. helper는 `rustup run 1.98.1`로 정확한 버전을 선택하며 전역 기본 toolchain은 변경하지 않습니다.

```powershell
.\scripts\integration-smoke.ps1
```

```bash
bash scripts/integration-smoke.sh
```

현재 `TSP-template`에는 실제 백엔드 어댑터가 없습니다. 따라서 통합 CI는 백엔드의 공개 진단 계약까지 검증하며, Tauri 네이티브 어댑터가 추가되면 해당 포트의 왕복 계약을 이곳에 확장합니다.

## 게임 저장소 추가

새 게임 저장소를 만들 때 다음 순서로 등록합니다.

1. `TSP-template`에서 독립 저장소를 생성합니다.
2. 게임 저장소가 사용하는 template ref, REST API major, WebSocket protocol version을 기록합니다.
3. `repositories.json`에 `kind: "game"` 항목을 추가합니다.
4. 해당 게임의 가장 작은 호환성 검사를 통합 CI에 추가합니다.

게임 전체 빌드와 배포를 상위 CI에 복제하지 않습니다. 저장소 간 공개 계약이 실제로 연결되는 경로만 추가합니다.

## 문서

- [아키텍처](docs/architecture.md)
- [저장소 운영 정책](docs/repository-policy.md)
- [호환성 정책](docs/compatibility.md)
