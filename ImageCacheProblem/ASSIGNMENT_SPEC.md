# ImageCacheProblem Assignment Spec

## 1. Goal

서버 URL로부터 이미지를 다운로드해 셀에 표시하되, 메모리 캐시와 셀 재사용 문제를 함께 고려하는 iOS 샘플 앱을 구현한다.

## 2. Core Requirements

- 셀은 이미지 1개를 표시한다.
- 이미지는 서버 URL 기반으로 다운로드한다.
- 캐시 hit 시 이미지를 다시 다운로드하지 않는다.
- 메모리 사용량 문제를 고려해야 한다.
- 셀 재사용 상황을 고려해야 한다.
- 메모리에는 약 100개 정도의 이미지만 유지한다.
- 100개를 초과해 제거된 이미지는 다시 필요할 때 remote에서 재조회한다.

## 3. Expected Behaviors

### Image Loading

- 동일한 URL의 이미지가 메모리 캐시에 존재하면 캐시된 이미지를 즉시 사용한다.
- 캐시에 없으면 네트워크로 이미지를 다운로드한다.
- 다운로드 성공 시 캐시에 저장한 뒤 화면에 반영한다.

### Cache Policy

- 메모리 캐시는 최대 100개 항목을 유지한다.
- 용량 초과 시 가장 오래 사용되지 않은 이미지부터 제거한다.
- 캐시 정책은 LRU(Least Recently Used)를 기준으로 구현한다.

### Cell Reuse

- 셀이 재사용될 때 이전 이미지 요청 결과가 잘못 반영되지 않아야 한다.
- 진행 중인 이미지 로딩 작업은 필요 시 취소할 수 있어야 한다.
- ViewModel 또는 비동기 Task 단에서 요청 생명주기를 관리하는 방향을 우선 고려한다.

## 4. Architecture Direction

Clean Architecture 구조를 목표로 한다.

### Proposed Layer Responsibilities

- Presentation
  - 셀 또는 화면의 상태를 관리한다.
  - 이미지 요청 시작, 취소, 결과 반영을 담당한다.
- Domain
  - 이미지 로딩 유스케이스를 정의한다.
  - Repository 인터페이스를 통해 비즈니스 흐름을 조합한다.
- Data
  - 네트워크 다운로드와 메모리 캐시를 구현한다.
  - cache-first 전략의 Repository 구현체를 제공한다.

## 5. Key Component

### CacheStorage

핵심 컴포넌트는 `CacheStorage`이다.

권장 책임:

- key 기반 이미지 조회
- key 기반 이미지 저장
- 캐시 용량 제한 관리
- 최근 사용 순서 갱신
- 용량 초과 시 LRU 제거

## 6. Recommended Implementation Strategy

### Data Layer

- `ImageCacheStorage` 또는 이에 준하는 프로토콜을 정의한다.
- `ImageMemoryCacheStorage`에서 메모리 기반 LRU 캐시를 구현한다.
- 캐시 key는 URL 문자열 또는 이를 감싼 값 타입을 사용한다.

### Repository

- Repository는 cache-first 전략을 따른다.
- 조회 순서:
  1. 메모리 캐시 확인
  2. miss면 remote 다운로드
  3. 다운로드 결과 캐시 저장
  4. 반환

### Presentation

- 셀 바인딩 시 이미지 로딩을 시작한다.
- 셀 재사용 또는 화면 이탈 시 진행 중 Task를 취소한다.
- 비동기 응답이 돌아왔을 때 현재 요청과 일치하는지 확인한 뒤 반영한다.

## 7. Test Scope

현재 테스트 프레임워크는 XCTest가 아니라 Swift Testing을 사용한다.

### Existing Test File

- `ImageCacheProblemTests/ImageMemoryCacheStorageTests.swift`

### Current Placeholder Tests

- `image_forMissingKey_returnsNil()`
- `insert_storesImageForKey()`
- `insert_whenCapacityExceeded_removesLeastRecentlyUsedImage()`
- `image_whenAccessed_updatesRecentUsageOrder()`

이 테스트들은 현재 placeholder 상태이며, 실제 red-green-refactor 흐름으로 교체 및 구현할 예정이다.

## 8. Build/Test Note

이전에 아래 명령으로 테스트 실행을 시도했다.

```bash
xcodebuild test -project ImageCacheProblem/ImageCacheProblem.xcodeproj -scheme ImageCacheProblem -destination 'platform=iOS Simulator,name=iPhone 16'
```

확인된 메시지:

```text
[MT] IDERunDestination: Supported platforms for the buildables in the current scheme is empty.
```

다음 실행 전에는 아래를 먼저 확인하는 것이 안전하다.

- `xcodebuild -showdestinations`
- 사용 가능한 simulator 목록

## 9. Next Steps

1. 사용 가능한 destination과 simulator를 확인한다.
2. `ImageMemoryCacheStorageTests`를 실제 red 상태로 실행한다.
3. `CacheStorage` 프로토콜을 정의한다.
4. 첫 번째 green 구현을 시작한다.
5. 이후 Repository와 셀 재사용 대응 로직으로 확장한다.
