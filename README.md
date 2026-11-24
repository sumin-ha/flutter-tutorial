# 한입 수첩 · Flutter + Spring Boot 학습 프로젝트

SNS에서 발견한 맛집을 이름·링크·메모·태그·도로명 주소와 선택 입력인 음식 사진 URL로 저장합니다. Android/iOS와 PC 브라우저를 같은 Flutter 코드로 지원합니다. 모바일은 목록/지도 탭, 화면 너비 960px 이상은 목록과 지도를 함께 보여줍니다. 저장 목록은 작은 음식 썸네일·짧은 메모·태그를 표시하고, 항목을 누르면 상세 바텀시트가 열립니다. 지도 아이콘은 해당 맛집을 지도에서 선택합니다.

학습용 로컬 앱이며 로그인/사용자 구분은 없습니다. 실제 서비스 배포 전 인증, 사용자별 데이터 격리, HTTPS, 스키마 마이그레이션, 운영용 키·요금 제한을 추가하세요. SNS 페이지를 수집하거나 게시물을 임베드하지 않고 사용자가 입력한 링크를 엽니다.

## React 개발자를 위한 Flutter 학습 문서

[소스 읽기와 설계 가이드](docs/flutter-for-react-developers.md)에서 React와의 개념 비교, 파일별 읽는 순서, 상태·폼·비동기 처리, Google Maps 연결, 단계별 실습을 설명합니다.

## 빠른 실행

필요 환경: **Flutter 3.47 이상 / Dart 3.13 이상**, **JDK 21**. 이 저장소의 정적 분석·테스트·웹 빌드는 Flutter 3.50.1, Java 21, Spring Boot 3.5.16으로 검증했습니다. 브라우저에서 모바일 너비의 목록과 실제 지도 화면을 확인했으며, Android/iOS 네이티브 빌드는 검증하지 않았습니다. Maven은 Wrapper가 다운로드합니다. Android는 Android SDK, iOS는 macOS + Xcode와 해당 Flutter 버전의 iOS 빌드 환경이 추가로 필요합니다. 설치 후 `flutter doctor`를 확인하세요.

터미널 1:

```sh
cd backend
./run-local.sh
```

`run-local.sh`는 실행 위치와 관계없이 `backend/`로 이동한 뒤 그곳의 `.env`를 읽어 환경변수로 전달합니다. 이미 만든 `.env`는 그대로 사용하세요. 처음 설정하는 경우에만 `.env.example`을 `.env`로 복사하고 값을 채웁니다. `.env`가 없으면 안내를 출력하고 현재 터미널의 환경변수로 실행합니다.

`.env`는 Bash 설정 파일입니다. `NAME=value` 형식으로 작성하고 `=` 앞뒤에 공백을 두지 마세요. 공백이나 셸 특수문자가 있는 값은 작은따옴표로 감싸세요. 파일을 `source`하므로 신뢰하는 내용만 넣어야 하며, `.env`의 값이 같은 이름의 기존 환경변수를 덮어씁니다. `.env`와 `.env.*`는 Git에서 제외하고 빈 설정 예시인 `.env.example`만 포함합니다.

루트에서는 `./backend/run-local.sh`로 실행할 수 있습니다. Maven 옵션은 그대로 전달됩니다(예: `./backend/run-local.sh -Dspring-boot.run.profiles=postgres`).

터미널 2:

```sh
cd frontend
flutter pub get
flutter run -d chrome --web-port=8081
```

기본 API는 `http://localhost:8080/api`입니다. **기본 실행은 실제 Spring API + 파일 H2 DB**를 사용하며 서버를 껐다 켜도 데이터가 남습니다(`backend/data/`). API 키가 없어도 CRUD는 됩니다. 주소 검색에는 `서울` 또는 `부산`을 입력하고 고정 데모 후보를 선택하세요. 이 후보는 실제 맛집 검색 결과가 아니며 지도도 표시하지 않습니다. 잘못된 주소/후보가 자동으로 저장되지 않도록 검색 후 위치 선택이 필수입니다.

서버 없이 화면부터 연습하려면:

```sh
cd frontend
flutter run -d chrome --web-port=8081 --dart-define=DEMO_MODE=true
```

이 모드만 가상의 맛집 3개를 보여주며 **메모리 CRUD**입니다. 새로고침하면 초기화됩니다. 실제 지도 대신 안내 패널을 보여줍니다. API 연결 오류 시 자동으로 데모로 전환하지 않습니다.

| 실행 조합 | CRUD 저장소 | 주소 검색 | 지도 |
| --- | --- | --- | --- |
| 기본 | Spring + 파일 H2 | 고정 데모 주소 3곳 | 연결 안내 |
| `DEMO_MODE=true` | 메모리, 재시작 시 초기화 | 고정 데모 주소 3곳 | 데모 안내 |
| 서버 Google 키 + 클라이언트 지도 키 + `MAPS_ENABLED=true` | Spring + 파일 H2 또는 PostgreSQL | Google Geocoding | Google 지도/여러 마커 |

## 실제 Google 지도 연결

Google Cloud에서 결제 계정을 연결하고 **Geocoding API**와 플랫폼에 맞는 **Maps SDK for Android / Maps SDK for iOS / Maps JavaScript API**를 켭니다. 키는 서버용, Android용, iOS용, 웹용으로 분리하세요. 서버 키는 Geocoding API 및 서버 IP로, Android는 앱 패키지와 SHA-1 인증서로, iOS는 bundle ID로, 웹은 HTTP referrer로 제한합니다. 클라이언트 키는 앱에 노출되는 값이므로 제한 설정이 필요합니다. 서버 키를 Dart나 HTML에 넣지 마세요.

서버:

```sh
cd backend
# .env에 GOOGLE_GEOCODING_KEY를 설정한 뒤 실행
./run-local.sh
```

키가 있으면 주소 검색 결과에 Google의 후보 주소를 표시합니다. 사용자가 후보를 선택하면 서버가 place ID를 재검증해서 좌표를 저장합니다. 사용자가 입력한 도로명 주소와 메모는 별도 데이터입니다. Google이 반환한 후보 주소 문자열은 DB에 저장하지 않습니다. 주소를 수정하면 위치 선택이 해제됩니다.

웹: `frontend/web/maps-config.example.js`를 `frontend/web/maps-config.js`로 복사한 뒤 `window.foodmarksMapsApiKey`에 **웹용 제한 키**를 입력합니다. 실제 키를 담은 `maps-config.js`는 Git에서 제외합니다. `index.html`의 `maps-loader.js`가 Google 지도 로딩 후 Flutter를 시작합니다. 기존 로컬 설정은 덮어쓰지 마세요. 키 없는 UI 연습에서는 예시 파일의 빈 문자열을 그대로 사용할 수 있습니다.

```sh
# 처음 설정할 때만 실행
cp frontend/web/maps-config.example.js frontend/web/maps-config.js
```

```sh
cd frontend
./run-local.sh
```

`frontend/run-local.sh`는 지도 활성화 옵션을 항상 전달하고 `http://127.0.0.1:8081`에서 실행합니다. `lsof`가 있으면 실행 전에 포트 점유를 검사해 이전 정적 서버와의 충돌을 안내합니다. 기존 Flutter를 실행 중이었다면 그 터미널에서 `Ctrl+C`로 종료한 뒤 실행하세요. 브라우저는 새 실행에서 열린 탭을 사용하고, 이전 화면이 남으면 새로고침하세요. `dart-define` 변경은 hot reload로 반영되지 않으므로 앱을 다시 실행해야 합니다. 이 스크립트는 실제 지도 키 설정 후 사용하며, 키 없는 UI 연습은 앞의 `DEMO_MODE=true` 명령을 사용하세요.

Android: `~/.gradle/gradle.properties`에 `MAPS_API_KEY=Android용_제한_키`를 추가합니다(커밋하지 않음). 이미 manifest placeholder가 연결되어 있습니다. applicationId는 `dev.foodmarks.foodmarks`, 최소 SDK는 24입니다. Android 에뮬레이터는 호스트 PC의 localhost를 `10.0.2.2`로 접근합니다.

```sh
cd frontend
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8080/api --dart-define=MAPS_ENABLED=true
```

Android debug 설정만 로컬 HTTP를 허용합니다. Release는 HTTPS API를 사용하세요. 위치 권한은 요청하지 않습니다(현재 위치 기능 없음).

iOS: `frontend/ios/Runner.xcworkspace`를 Xcode로 열고 Runner target의 Build Settings에 User-Defined setting `GOOGLE_MAPS_API_KEY`를 추가하세요. `Info.plist` → `AppDelegate.swift` → `GMSServices.provideAPIKey`로 전달됩니다. bundle ID에 맞게 키를 제한합니다. 시뮬레이터는 localhost를 사용하고 실기기는 PC의 LAN IP를 `API_BASE_URL`로 전달합니다. iOS는 로컬 네트워크만 ATS 예외가 적용되므로 실기기 환경에 따라 HTTPS 개발 서버를 사용하세요. Android/iOS 네이티브 빌드는 이 환경에서 검증하지 않았습니다.

데모에서 만든 데이터는 `demo-*` place ID라 Google 모드에서 갱신할 수 없습니다. 실제 키를 연결한 뒤 데모 북마크의 주소를 다시 검색·선택하여 저장하세요.

Google 좌표는 29일만 캐시하고 매시간/목록 조회/시작 직후 만료 좌표를 삭제합니다. place ID와 사용자 입력은 남습니다. 좌표가 만료된 북마크는 목록 메뉴의 **위치 갱신**으로 다시 조회합니다. 정지 중인 서버는 다음 시작 시 삭제하므로 장기간 정지/백업에서 좌표 보존이 30일을 넘지 않게 운영해야 합니다. DB 백업의 좌표에도 같은 보존 정책이 필요합니다. 이 구현은 운영 정책 준수를 대신하지 않습니다.

참조: [Geocoding 정책](https://developers.google.com/maps/documentation/geocoding/policies), [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter), [Google Maps API 키 제한](https://developers.google.com/maps/api-security-best-practices). 실제 키가 없어 Google 검색·지도 렌더링과 과금은 검증하지 않았습니다.

## PostgreSQL 선택

기본은 설치가 간단한 H2입니다. PostgreSQL 연습 시 루트에서 `docker compose up -d` 후:

```sh
cd backend
SPRING_PROFILES_ACTIVE=postgres ./run-local.sh
```

연결 설정은 `DB_URL`, `DB_USER`, `DB_PASSWORD`로 바꿉니다. Compose 기본값은 로컬 학습용 `foodmarks`입니다. PostgreSQL 경로는 제공하지만 이 환경에서는 실행하지 않았습니다. H2 데이터가 자동 이관되지는 않습니다.

## 구조와 학습 순서

```text
frontend/lib/
  main.dart             앱 설정, Repository 선택
  bookmark.dart         불변 모델/요청 DTO
  repository.dart       HTTP 통신, 명시적 메모리 데모
  bookmark_store.dart   ChangeNotifier: 목록/검색/선택/비동기 상태
  home_screen.dart      반응형 목록과 사용자 액션
  editor.dart           폼 검증, 주소 후보 선택, 저장
  map_panel.dart        지도 마커/선택 카드/데모 안내
backend/src/main/java/dev/foodmarks/
  ApiController         REST 경로와 입력 검증
  BookmarkService       저장/삭제/좌표 캐시 규칙
  GeocodingService      Google 호출, 키 없는 데모 검색
  BookmarkRepository    Spring Data JPA
  Bookmark              DB entity
```

React/Vue 경험과 연결하면 Widget은 컴포넌트, `build()`는 렌더 함수, 생성자 인자는 props, `State` + `setState()`는 로컬 state, `ChangeNotifier` + `ListenableBuilder`는 작은 store/구독입니다. `Future`와 `async/await`는 Promise와 비슷합니다. Dart의 `final`, named arguments, null safety(`?`, `!`)부터 익히세요. 이 앱은 학습 흐름을 보기 쉽게 Provider/BLoC/코드 생성 없이 구성했습니다.

1. `bookmark.dart`를 읽고 Dart 타입과 JSON 변환을 익힙니다.
2. `DEMO_MODE=true`로 실행해 `home_screen.dart`의 Widget 트리와 레이아웃을 봅니다.
3. `editor.dart`에서 Form/validator/TextEditingController를 익힙니다.
4. `bookmark_store.dart`에서 비동기 상태와 구독을 확인합니다.
5. 기본 API 모드로 전환해 Repository → REST → Service → JPA를 따라갑니다.
6. Google 키를 연결하고 MapPanel의 여러 마커/선택 동기화를 확인합니다.
7. 이후 인증, 방문 여부, 사진, 공유하기 등을 작은 단위로 추가합니다.

기능은 제목·메모·주소·태그 통합 검색, 태그 필터, 생성/수정/삭제 확인, 원문 링크 열기, 로딩/빈 상태/오류 재시도, 지도 마커 선택/선택 카드/전체 위치 보기를 포함합니다. PC 지원은 **브라우저 웹**이며 Windows/macOS 네이티브 앱 타깃은 만들지 않았습니다.

## REST API

모든 응답은 JSON, 오류는 `{ "message": "..." }` 형태입니다. ID는 UUID입니다.

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| GET | `/api/status` | 서버 상태와 geocodingMode |
| GET | `/api/bookmarks` | 생성일 내림차순 목록 |
| POST | `/api/bookmarks` | 생성 (201) |
| PUT | `/api/bookmarks/{id}` | 수정 |
| DELETE | `/api/bookmarks/{id}` | 삭제 (204) |
| GET | `/api/geocode?address=...` | 주소 후보 |
| POST | `/api/bookmarks/{id}/location` | 좌표 캐시 갱신 |

저장 요청:

```json
{"title":"가보고 싶은 국밥집","snsUrl":"https://www.instagram.com/p/example/","description":"점심에 가보기","tags":["혼밥"],"address":"서울특별시 중구 세종대로 110","placeId":"demo-seoul-cityhall"}
```

`thumbnailUrl`은 선택 입력이며 최대 2000자의 HTTPS 이미지 주소입니다. 미입력·로드 실패 시 기본 음식 아이콘을 보여줍니다. SNS 링크에서 사진을 자동 추출하지 않습니다. 기존 데이터는 사진 없이 그대로 표시됩니다. 데모 사진은 실제 가게 사진이 아닌 예시이며 출처는 `frontend/assets/images/SOURCES.md`에 있습니다.

`title` 100자, `snsUrl` 2000자(HTTPS만), `description` 2000자, `address`/`placeId` 300자, 태그 8개/각 20자로 제한합니다. 위 링크는 예시입니다. 검색/태그 필터는 현재 Flutter 메모리에서 처리합니다. CORS 기본 허용은 localhost/127.0.0.1입니다. 별도 개발 호스트는 `CORS_ORIGINS`를 쉼표로 구분해 설정하세요.

## 검증

```sh
cd frontend
flutter analyze
flutter test
flutter build web
# 다른 터미널
cd backend
./mvnw test
./mvnw package
cd ..
python3 scripts/check_persistence.py
```

실행 검증 기록은 [docs/verification.md](docs/verification.md)에 정리합니다. 실제 지도 연결에는 유효한 키와 해당 API 활성화가 필요합니다.
