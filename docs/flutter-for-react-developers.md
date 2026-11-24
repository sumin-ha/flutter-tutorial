# React 개발자를 위한 Flutter 소스 읽기 가이드

이 프로젝트는 맛집 저장 기능을 소재로 Flutter의 화면 구성, 상태 관리, 폼, 비동기 통신, 반응형 레이아웃, 플랫폼 플러그인을 연습하는 프로토타입입니다. 제품 기능보다 **사용자 입력이 상태를 바꾸고, 바뀐 상태가 화면에 반영되는 과정**을 따라가는 데 집중하면 좋습니다.

React 웹 개발 경험을 기준으로 설명합니다. 비교 예시의 React 코드는 이해를 돕기 위한 코드이며 저장소에 들어 있는 구현은 아닙니다. Flutter 설명은 현재 저장소의 실제 클래스와 메서드에 연결했습니다. 작성 기준은 2026년 11월 22일입니다.

## 1. 먼저 실행하고 읽을 순서

첫 학습에서는 서버와 지도 키 없이 시작하세요. 프로젝트 루트에서 다음 명령을 실행합니다.

```sh
cd frontend
flutter pub get
flutter run -d chrome --web-port=8081 --dart-define=DEMO_MODE=true
```

`DemoRepository`가 가상의 맛집 세 개와 메모리 저장소를 제공합니다. 생성·수정·삭제는 되지만 새로고침하면 초기화되고 실제 지도는 나오지 않습니다. 검색창, 태그, 상세 보기, 저장 폼부터 조작해보세요. 8081 포트를 이미 사용 중이라면 다른 포트로 실행할 수 있습니다.

처음부터 모든 파일을 읽기보다 아래 순서로 한 번씩 왕복하세요.

| 순서 | 파일과 먼저 볼 대상 | 이해할 질문 |
| --- | --- | --- |
| 1 | [bookmark.dart](../frontend/lib/bookmark.dart)의 세 모델 | 화면에 필요한 데이터는 어떤 형태인가? |
| 2 | [main.dart](../frontend/lib/main.dart)의 `initState`, `build` | 앱을 시작하면서 무엇을 만들고 누구에게 전달하는가? |
| 3 | [bookmark_widgets.dart](../frontend/lib/bookmark_widgets.dart)의 `BookmarkSummary` | 데이터 하나가 어떤 Widget 트리로 바뀌는가? |
| 4 | [home_screen.dart](../frontend/lib/home_screen.dart)의 `build`, `collection`, `list` | 목록과 지도를 어떻게 조합하고 전환하는가? |
| 5 | [bookmark_store.dart](../frontend/lib/bookmark_store.dart)의 `search`, `visible`, `load` | 화면 상태를 어디에 보관하고 어떻게 알리는가? |
| 6 | [editor.dart](../frontend/lib/editor.dart)의 `initState`, `search`, `save` | 입력값과 비동기 요청의 수명을 어떻게 관리하는가? |
| 7 | [repository.dart](../frontend/lib/repository.dart)의 인터페이스와 두 구현 | 화면 코드를 바꾸지 않고 저장소를 어떻게 교체하는가? |
| 8 | [map_panel.dart](../frontend/lib/map_panel.dart)의 `onMapCreated`, `didUpdateWidget`, `fit` | 선언적인 화면과 명령형 지도 API를 어떻게 연결하는가? |
| 9 | [widget_test.dart](../frontend/test/widget_test.dart), [store_test.dart](../frontend/test/store_test.dart) | 어떤 동작이 유지되어야 하는가? |

`home_screen.dart`의 긴 스타일 코드는 처음에는 건너뛰어도 됩니다. `onTap`, `onChanged`, `onPressed`에서 시작해 호출되는 메서드만 따라가면 동작을 먼저 이해할 수 있습니다.

## 2. 전체 구조를 한 번에 보기

```text
main.dart
  └─ FoodmarksApp
      ├─ BookmarkStore 생성 및 수명 관리
      ├─ ApiRepository 또는 DemoRepository 선택
      └─ HomeScreen에 store 전달
          ├─ 목록과 검색 → 공통 BookmarkSummary / FoodThumbnail
          ├─ 상세 보기 → 바텀시트
          ├─ 생성과 수정 → BookmarkEditor 다이얼로그
          └─ 지도 → MapPanel

사용자 이벤트 → State 또는 Store 변경 → build로 화면 갱신
                            │
                            └─ Repository → Spring REST API → DB / Geocoding API
```

역할은 네 가지로 나눠 읽으면 됩니다.

- **모델:** 화면과 서버 사이를 오가는 데이터 형태.
- **Widget와 State:** 화면 표현, 입력 제어, 화면 안에서만 필요한 상태.
- **Store:** 여러 화면이 공유하는 목록·검색·선택 상태와 작업 흐름.
- **Repository:** 데이터를 읽고 저장하는 방법.

현재 Store는 화면 상태와 조회·저장 흐름을 함께 가진 작은 ViewModel에 가깝습니다. 별도의 Provider나 Riverpod 없이 생성자 인자로 의존성을 전달합니다. 이 정도 규모에서는 구조를 직접 눈으로 따라가기 좋습니다.

## 3. React 개념과 Flutter 개념 연결하기

| React 웹에서 익숙한 것 | 이 프로젝트의 Flutter 코드 | 기억할 차이 |
| --- | --- | --- |
| 컴포넌트와 JSX | Widget와 `build()` | JSX 대신 Dart 생성자로 UI 트리를 구성 |
| props | Widget의 생성자 인자와 `final` 필드 | State에서는 `widget.store`처럼 접근 |
| `useState` | `State`의 필드와 `setState()` | 값 변경과 화면 갱신 요청을 직접 묶음 |
| 외부 상태 저장소 구독 | `ChangeNotifier`와 `ListenableBuilder` | 필드 대입만으로 구독자에게 자동 통지되지 않음 |
| 컴포넌트의 파생 값 | `visible`, `tags`, `selected` getter | 현재 구현은 읽을 때 계산하며 메모이제이션하지 않음 |
| `useRef`에 보관한 외부 객체 | `TextEditingController`, 지도 controller | 사용 후 `dispose()`가 필요한 객체가 있음 |
| effect와 cleanup | `initState`, `didUpdateWidget`, `dispose` | 실행 시점과 의존성 처리가 일대일로 같지는 않음 |
| Context로 상위 값 접근 | `Theme.of(context)`, `MediaQuery` | `BuildContext`는 Widget 트리의 위치를 나타내는 핸들 |
| CSS와 flex 배치 | `Row`, `Column`, `Expanded`, `Padding` | 부모가 전달하는 크기 제약을 이해해야 함 |
| `Promise<T>` | `Future<T>` | 둘 다 `async/await`로 순차 흐름을 표현 가능 |
| 배열 `map`, `filter` | Iterable의 `map`, `where` | 필요한 지점에 `.toList()`로 목록을 구체화 |

Widget는 화면을 설명하는 설정 객체입니다. Widget 객체가 다시 만들어져도 대응하는 Element와 State가 유지될 수 있습니다. `StatefulWidget`의 설정과 그에 연결된 `State`를 나누어 생각하세요. React의 함수 컴포넌트가 다시 실행되어도 Hook 상태가 보존되는 경험과 연결하면 이해하기 쉽습니다. [Flutter State 수명 주기](https://api.flutter.dev/flutter/widgets/State-class.html)

`build()`가 호출됐다는 사실이 곧 전체 화면을 모두 다시 그렸다는 뜻은 아닙니다. Flutter는 Widget 설명을 기존 트리와 대조해 필요한 갱신을 수행합니다. `build()`에는 UI 구성을 두고, HTTP 호출이나 controller 생성은 다른 수명 주기와 이벤트 메서드에서 처리하세요.

### Dart 문법은 이 정도부터

```dart
final String title;             // 한 번 대입한 필드의 재대입을 금지
final double? latitude;         // null 허용
late final BookmarkStore store; // 나중에 초기화할 필드

const BookmarkSummary({
  super.key,
  required this.bookmark,       // 필수 named argument
  this.trailing,               // 선택 named argument
});
```

호출은 `BookmarkSummary(bookmark: b)`처럼 인자 이름을 씁니다. TypeScript의 옵션 객체를 넘기는 모양과 비슷하지만 Dart의 named parameter 문법입니다.

- `?.`는 null이면 접근을 중단하고, `??`는 null일 때 기본값을 정합니다.
- `!`는 null이 아니라고 개발자가 단언하는 연산자입니다. 잘못 단언하면 실행 중 오류가 납니다.
- `factory Bookmark.fromJson(...)`은 JSON을 모델로 만드는 생성자입니다.
- `get visible => ...`은 메서드 호출 괄호 없이 읽는 계산 속성입니다.
- `..load()`는 cascade입니다. `BookmarkStore(...)..load()`는 Store 객체에서 `load()`를 호출한 뒤 Store 자체를 표현식의 값으로 사용합니다. 비동기 완료를 기다리는 문법은 아닙니다.
- `const`는 컴파일 시점 상수 생성에 사용합니다. `React.memo`처럼 props 비교로 렌더를 막는 장치와는 다릅니다.
- `final List<String>`도 목록 내부의 변경까지 막지는 않습니다. 현재 모델은 필드 재대입을 막지만 깊은 불변성을 보장하는 구현은 아닙니다.
- `?trailing`은 이 코드에 쓰인 null-aware collection element입니다. null이 아니면 자식 목록에 넣습니다. 처음에는 조건부 자식 삽입 문법으로 읽으면 됩니다.

자세한 문법은 [Dart 언어 소개](https://dart.dev/language)를 필요한 항목별로 읽으세요.

## 4. main.dart에서 앱의 수명 이해하기

시작점은 `void main() => runApp(FoodmarksApp());`입니다. React의 root에 최상위 컴포넌트를 붙이는 부분에 대응합니다.

`FoodmarksApp`의 State가 `initState()`에서 Repository와 Store를 만들고 처음 데이터를 불러옵니다. `build()`에서는 `MaterialApp`의 테마와 시작 화면을 구성합니다. 같은 State가 살아 있는 동안 `build()`가 반복되어도 Store는 다시 생성되지 않습니다.

```dart
store = BookmarkStore(
  widget.repository ?? (demo ? DemoRepository() : ApiRepository(api)),
)..load();
```

`widget.repository`는 테스트에서 저장소를 주입하기 위한 통로입니다. 테스트가 네트워크 없이 실행되는 이유가 이 구조에 있습니다. 앱이 끝나면 `store.dispose()`가 Repository의 HTTP client 정리까지 이어집니다. 누가 객체를 만들고 누가 정리하는지 연결해서 보세요.

이 앱의 `MaterialApp` 이름은 Flutter의 Material UI 체계에서 옵니다. React의 MUI 패키지를 연결한 것이 아닙니다. 현재 소스는 `package:material_ui/material_ui.dart`를 사용하며, Flutter 공식 예제에서 자주 보이는 `package:flutter/material.dart`와 import 경로가 다릅니다. 실제 사용 의존성은 `pubspec.yaml`과 `pubspec.lock`을 기준으로 확인하세요.

`ThemeData`는 반복되는 색·입력창·버튼 스타일을 상위에서 정하는 곳입니다. 개별 Widget는 `Theme.of(context)`로 이를 조회할 수 있습니다. 현재 코드에는 공통 테마와 일부 직접 지정한 스타일이 함께 있습니다.

## 5. 화면 상태와 공유 상태를 나누는 방법

### 화면 안에서만 쓰는 상태

`HomeScreen`의 `tab`은 목록과 지도 중 무엇을 보여줄지 결정합니다.

```dart
onDestinationSelected: (v) => setState(() => tab = v)
```

React라면 `setTab(v)`를 호출할 자리입니다. Flutter의 `setState`는 동기 콜백 안에서 상태를 바꾸고 해당 State의 재빌드를 요청합니다. 콜백 자체를 `async`로 만들지 마세요. 비동기 작업을 마친 뒤 필요한 값을 동기적으로 반영합니다.

`BookmarkEditor`의 `saving`, `searching`, 주소 후보 목록도 편집창 안에서만 필요하므로 로컬 State에 있습니다.

### 목록과 지도 사이에 공유하는 상태

`BookmarkStore`에는 `items`, `query`, `tag`, `selectedId`, `loading`, `error`가 있습니다. 목록에서 선택한 맛집을 지도도 알아야 하므로 `selectedId`가 Store에 있습니다.

검색은 다음 세 단계입니다.

```dart
void search(String value) {
  query = value;
  notifyListeners();
}
```

1. `TextField.onChanged`가 `store.search`를 호출합니다.
2. Store가 검색어를 바꾸고 구독자에게 알립니다.
3. `ListenableBuilder`가 다시 builder를 실행하고, `store.visible`을 바탕으로 목록과 지도를 구성합니다.

현재 검색은 서버 재조회 없이 이미 받아온 목록을 필터링합니다. `visible`을 별도 상태로 저장하지 않으므로 검색어와 결과가 서로 어긋날 가능성을 줄입니다. 다만 계산 결과를 캐시하지 않으므로 대규모 데이터용 구현은 아닙니다.

[공식 ListenableBuilder 설명](https://api.flutter.dev/flutter/widgets/ListenableBuilder-class.html)에서도 알림을 받은 하위 트리를 다시 구성하는 방식을 확인할 수 있습니다.

### React 코드와 짧게 비교하기

```jsx
// 이해를 위한 React 예시
const [query, setQuery] = useState('');
const visible = items.filter(item => item.title.includes(query));
return <input value={query} onChange={e => setQuery(e.target.value)} />;
```

Flutter의 이 프로젝트에서는 입력을 `TextEditingController`가 관리하고, 검색 조건은 Store에도 보관합니다. controller를 공유해 탭을 바꿔도 입력이 유지되며, 검색 지우기는 controller와 Store 양쪽에 반영합니다. 둘 중 한쪽만 지우면 보이는 문자열과 필터가 어긋납니다.

설계할 때는 **여러 화면이 알아야 하는 값인지, 해당 입력창에서만 필요한 값인지**부터 결정하세요. 모든 상태를 전역 Store로 옮길 필요는 없습니다.

## 6. UI 트리를 읽고 레이아웃 설계하기

`BookmarkSummary`를 먼저 읽으면 복잡한 홈 화면보다 쉽게 시작할 수 있습니다.

```text
Row
  ├─ FoodThumbnail
  ├─ SizedBox             ← 가로 간격
  ├─ Expanded
  │   └─ Column
  │       ├─ 제목
  │       ├─ 주소
  │       ├─ 짧은 메모
  │       └─ BookmarkTags
  └─ trailing             ← 부모가 필요에 따라 전달하는 보조 UI
```

React의 `children`이나 slot prop처럼 `trailing`에 Widget를 넘길 수 있습니다. 공통 Widget는 데이터를 표현하고, 수정·삭제·지도 이동 등 행동은 부모가 결정하도록 구성했습니다. `MapPanel`도 `onSelect`, `onOpen`, `onEdit`, `onDetails` 콜백을 받아 부모에게 이벤트를 돌려줍니다.

Flutter에서는 부모가 자식에게 허용 크기를 전달하고, 자식이 그 안에서 자신의 크기를 정한 뒤, 부모가 위치를 정합니다. CSS의 `width`나 `flex: 1`을 이름만 바꿔 대입하기보다 이 제약 흐름을 먼저 보세요. [Flutter 레이아웃 제약 설명](https://docs.flutter.dev/ui/layout/constraints)

이 앱의 자주 쓰는 조합은 다음과 같습니다.

| Widget | 이 코드에서 쓰는 이유 |
| --- | --- |
| `Row`, `Column` | 가로·세로로 자식 배치 |
| `Expanded` | 남는 공간을 목록·지도·텍스트에 배분 |
| `SizedBox` | 고정 크기 또는 간격 지정 |
| `Padding` | 내부 여백을 별도 Widget로 표현 |
| `Wrap` | 태그를 공간에 맞춰 다음 줄로 배치 |
| `ListView.separated` | 스크롤 목록을 항목별로 만들고 구분선 삽입 |
| `Stack`, `Positioned` | 지도 위에 검색창과 미리보기 카드 겹치기 |
| `LayoutBuilder` | 부모로부터 받은 제약을 기준으로 지도 카드 높이 제한 |
| `MediaQuery` | 화면 너비와 안전 영역 등 주변 화면 정보 조회 |

`Column` 안에서 스크롤 목록의 높이가 정해지지 않으면 레이아웃 오류가 나기 쉽습니다. 이 코드의 `Expanded(child: list())`가 목록에 남은 높이를 배정하는 이유를 먼저 이해하세요. 제약이 무한한 상황에서는 `Expanded`를 추가하는 것만으로 해결되지 않습니다. 부모가 유한한 크기를 주는지도 확인해야 합니다.

반응형 분기 기준은 `HomeScreen`의 너비 960입니다. 넓으면 410 너비의 목록과 나머지 공간의 지도를 나란히, 좁으면 하단 탭으로 전환합니다. Flutter의 크기 수치는 일반적으로 논리 픽셀이므로 기기의 물리 픽셀 수와 그대로 같지는 않습니다.

`StatelessWidget`도 부모가 새 설정을 전달하거나 의존한 Theme 등이 바뀌면 다시 build될 수 있습니다. “자기 내부의 변경 가능한 State가 없다”는 뜻으로 이해하세요.

## 7. 폼과 비동기 코드를 따라가기

### 입력과 검증

`BookmarkEditor`는 생성과 수정을 같은 폼으로 처리합니다. `bookmark`가 있으면 `initState()`에서 기존 값으로 controller를 초기화합니다. React에서 기존 데이터를 `useState`의 초기값으로 쓰는 상황과 연결할 수 있습니다.

`TextEditingController`는 텍스트뿐 아니라 커서와 선택 상태도 다룹니다. 이 코드에서는 State가 controller를 만들고 `dispose()`에서 정리합니다. `build()` 안에서 매번 생성하면 입력과 커서가 예상치 않게 초기화될 수 있습니다.

`GlobalKey<FormState>`는 현재 폼의 상태를 찾아 `validate()`를 실행하는 연결점입니다. React 목록의 `key`처럼 항목의 대응 관계만 지정하려고 쓰는 key와 목적이 다릅니다. 각 `TextFormField.validator`는 정상일 때 null, 잘못된 입력일 때 오류 문자열을 반환합니다.

주소 입력과 위치 선택은 별개입니다. 주소를 수정하면 선택한 후보도 지워서 이전 주소의 좌표로 저장되는 일을 막습니다.

### 오래된 요청 결과 무시하기

주소 검색에서 다음 패턴을 찾아보세요.

```dart
final version = ++searchVersion;
final result = await widget.store.repository.searchAddress(entered);
if (!mounted || version != searchVersion) return;
```

A 검색 뒤에 B 검색을 했는데 A가 늦게 도착하면 B의 결과를 덮어쓸 수 있습니다. 요청마다 번호를 주고 최신 번호만 반영합니다. React effect cleanup의 ignore 플래그나 request ID를 쓰는 방식과 유사합니다. 실제 HTTP 요청을 취소하는 구현은 아닙니다.

`mounted`는 이 State가 아직 트리에 있는지 확인합니다. `await` 중 사용자가 창을 닫았으면 결과를 화면에 반영하거나 그 context로 이동을 시도하지 않도록 검사합니다. 이것도 요청 취소와는 구분해야 합니다.

### 저장이 끝나고 목록에 보이기까지

```text
저장 버튼
  → form.validate()와 주소 후보 선택 확인
  → BookmarkDraft 생성
  → store.save(draft)
  → repository.save(draft)
  → store.load()로 목록 재조회
  → notifyListeners()로 화면 반영
  → Navigator.pop(context, true)
  → HomeScreen이 다이얼로그 결과를 받고 안내 메시지 표시
```

`showDialog<bool>`은 결과를 돌려주는 `Future`입니다. `Navigator.pop(context, true)`의 true가 다이얼로그를 기다리던 코드로 전달됩니다. 단순히 창을 닫는 동작에 결과 전달까지 포함됩니다.

현재 방식은 저장 후 전체 목록을 재조회합니다. 낙관적 업데이트와 캐시 무효화 전략을 따로 구현하지 않아 학습 흐름이 단순합니다. React Query처럼 재시도·캐시·요청 중복 제거를 자동 제공하는 구조는 아닙니다.

## 8. Repository로 HTTP와 화면 분리하기

`BookmarkRepository`는 `load`, `save`, `delete`, `searchAddress`, `refreshLocation`이라는 기능 계약입니다.

`ApiRepository`는 HTTP를 사용하고, `DemoRepository`는 메모리를 사용합니다. 화면과 Store는 같은 계약만 호출하므로 서버 없이 UI를 연습하거나 테스트할 수 있습니다. 의존성 주입은 반드시 프레임워크가 필요한 개념이 아닙니다. 이 코드처럼 생성자 인자로 객체를 넘기는 것부터 시작할 수 있습니다.

`Bookmark`는 서버에서 읽어온 항목이고 `BookmarkDraft`는 저장 요청에 보낼 값입니다. ID·생성 시각·좌표 같은 서버 관리 값을 입력 폼에 섞지 않기 위해 나눴습니다. `PlaceCandidate`는 주소 검색 중 잠깐 사용하는 후보입니다.

`fromJson`과 `toJson`을 직접 작성한 이유는 데이터 경계를 눈으로 확인하기 위해서입니다. TypeScript의 타입 선언과 달리 실제 런타임에 JSON의 숫자를 `double`로 바꾸고 문자열을 `DateTime`으로 변환하는 작업입니다. 현재는 전체 JSON 스키마를 엄격히 검증하는 라이브러리를 사용하지 않습니다.

사진은 사용자가 입력한 URL을 `Image.network`로 읽습니다. 실패하거나 사진이 없으면 기본 음식 아이콘을 표시합니다. `Image.asset`은 앱에 포함한 데모 사진을 읽습니다. SNS 링크에서 이미지를 수집하거나 파일을 업로드하는 기능은 구현하지 않았습니다.

## 9. Google Maps 연동 이해하기

### 지도 표시와 주소 검색은 서로 다른 경로

```text
지도 표시
Flutter MapPanel → google_maps_flutter → 각 플랫폼의 Google 지도 SDK

주소 검색과 저장
BookmarkEditor → ApiRepository → Spring GeocodingService → Geocoding API
                                         │
                                         └─ place ID 재확인 → 좌표와 함께 저장
```

지도 SDK를 붙였다고 주소 검색 API가 자동으로 연결되는 것은 아닙니다. 현재 검색은 **도로명 주소를 Geocoding API로 변환하는 기능**입니다. 가게 이름 자동완성이나 주변 맛집 추천을 위한 Places 검색 구현은 아닙니다.

사용자가 후보를 고르면 폼이 `placeId`를 저장 요청에 넣습니다. 서버는 그 ID를 다시 조회해 좌표를 결정합니다. 클라이언트가 보낸 임의 위도·경도를 그대로 DB에 넣는 구조가 아닙니다.

### 연결에 필요한 설정

Google Cloud 프로젝트에서 결제와 필요한 API를 설정하고, 서버용 키와 플랫폼별 지도 키를 분리합니다. 다음 표는 이 저장소의 연결 지점입니다. 실제 키 값은 문서에 복사하지 마세요. [Google 공식 Flutter 설정](https://developers.google.com/maps/flutter-package/config)

| 용도 | 활성화할 API 또는 SDK | 이 프로젝트의 설정 위치 |
| --- | --- | --- |
| 서버 주소 검색 | Geocoding API | `backend/.env`의 `GOOGLE_GEOCODING_KEY` → Spring `app.google-key` |
| 웹 지도 | Maps JavaScript API | `frontend/web/maps-config.js`의 로컬 키 → `maps-loader.js`에서 지도 로드 후 Flutter 시작 |
| Android 지도 | Maps SDK for Android | Gradle `MAPS_API_KEY` → AndroidManifest의 placeholder |
| iOS 지도 | Maps SDK for iOS | Xcode `GOOGLE_MAPS_API_KEY` → Info.plist → AppDelegate의 `provideAPIKey` |

서버 키는 서버에서만 사용합니다. 클라이언트 지도 키는 브라우저나 앱에서 사용되므로 노출 자체를 완전히 막을 수 있는 비밀로 취급하면 안 됩니다. 웹은 HTTP referrer, Android는 패키지와 인증서, iOS는 bundle ID에 맞게 애플리케이션 제한을 걸고 API 제한도 설정합니다. [Google 키 제한 가이드](https://developers.google.com/maps/api-security-best-practices)

기존 키 설정을 유지한 상태에서 실행하는 기본 흐름은 다음과 같습니다.

```sh
# 프로젝트 루트의 터미널 1
./backend/run-local.sh

# 프로젝트 루트의 터미널 2
./frontend/run-local.sh
```

프론트 스크립트는 `MAPS_ENABLED=true`를 전달합니다. 서버와 플랫폼 키 설정이 모두 있어야 실제 검색과 지도 표시가 함께 됩니다. 세 가지 모드를 구분하세요.

| 모드 | 데이터 저장 | 주소 검색 | 실제 지도 |
| --- | --- | --- | --- |
| `DEMO_MODE=true` | 메모리 | 고정 후보 | 표시 안 함 |
| 기본 API 실행, 서버 키 없음 | Spring DB | 고정 후보 | 이 앱에서는 표시 안 함 |
| API 실행 + 서버 키 + 플랫폼 지도 키 + `MAPS_ENABLED=true` | Spring DB | Google Geocoding | 표시 |

`DEMO_MODE`, `MAPS_ENABLED`, `API_BASE_URL`은 `--dart-define`으로 넘기고 `fromEnvironment`로 읽습니다. 앱 빌드 설정이므로 값을 바꾼 뒤에는 hot reload 대신 앱을 다시 실행하세요. 프론트의 기본 API 주소는 `http://localhost:8080/api`입니다.

Android 에뮬레이터에서 PC 서버를 부를 때는 보통 `http://10.0.2.2:8080/api`로 변경합니다. 실제 휴대폰의 localhost는 PC가 아니므로 PC의 LAN 주소 등 접근 가능한 개발 주소가 필요합니다. 브라우저 요청에는 CORS도 적용되며, CORS 허용과 Google 지도 키의 referrer 제한은 서로 다른 설정입니다. 자세한 실행 명령은 루트 [README](../README.md)를 참고하세요.

### map_panel.dart를 읽는 순서

1. `located`: 좌표가 있고 만료되지 않은 항목만 골라냅니다.
2. `GoogleMap`: 최초 카메라와 현재 마커 집합을 선언합니다.
3. `onMapCreated`: 실제 지도 준비 후 controller를 보관합니다.
4. 마커 `onTap`: `onSelect(id)`를 호출해 선택 상태를 부모 Store로 올립니다.
5. `didUpdateWidget`: 새 props의 선택이나 항목이 달라지면 라벨을 갱신하고 카메라를 이동합니다.
6. `fit`: 한 지점이면 확대하고, 여러 지점이면 경계 안에 들어오도록 전체 보기를 실행합니다.
7. `buildMarkers`: 가게명 라벨을 이미지로 만들어 마커 아이콘으로 사용합니다.

React에서 지도를 다뤘다면 `ref`에 지도 인스턴스를 넣고 effect에서 `panTo`를 호출하는 구도와 비슷합니다. `initialCameraPosition`만 계속 바꿔서 지도 이동을 구현하는 대신, 준비된 controller의 `animateCamera`를 사용합니다.

지도 화면은 `Stack`으로 지도와 Flutter 카드를 겹칩니다. 카드가 지도 중앙을 가리지 않도록 지도 `padding`도 설정합니다. `BitmapDescriptor.bytes`는 Widget를 직접 올리는 API가 아니어서 `TextPainter`와 `Canvas`로 PNG 바이트를 만듭니다. 이 부분은 고급 응용이므로 첫 학습에서는 기본 마커와 카메라 이동부터 이해해도 됩니다. `markerVersion`은 라벨 이미지 생성 중 선택이 바뀌었을 때 오래된 이미지 결과를 버리는 장치입니다.

웹 지도는 HTML 기반 플랫폼 뷰를 사용합니다. 위에 겹친 Flutter 버튼의 클릭이 지도로 전달되지 않도록 `PointerInterceptor`로 감쌌습니다. 일반 Flutter Widget만 배치할 때와 다른 플랫폼 연동의 특성입니다. [웹 지도 플러그인 설명](https://pub.dev/packages/google_maps_flutter_web)

현재 앱은 사용자의 현재 위치를 요청하지 않습니다. 저장한 장소 좌표로 이동하는 것과 GPS 권한을 요청해 현재 위치를 구하는 것은 별도 기능입니다.

### 좌표 만료를 넣은 이유

서버는 좌표에 29일의 만료 시각을 넣고 목록 조회와 정기 작업에서 만료 좌표를 지웁니다. `placeId`와 사용자 입력은 유지해 위치 갱신이 가능합니다. 프론트의 `hasLocation`도 만료 여부를 검사해 오래된 좌표를 마커로 사용하지 않습니다.

이는 외부 API 데이터의 보관 수명을 다뤄보기 위한 구현입니다. 현재 정책 준수 전체를 자동 보장하는 장치는 아니며, 실제 서비스에서는 계약과 저장·표시 조건을 확인해야 합니다. [Geocoding 데이터 보관·표시 정책](https://developers.google.com/maps/documentation/geocoding/policies)

## 10. 백엔드는 이 정도만 이해하면 충분합니다

Spring의 흐름은 `ApiController → BookmarkService → BookmarkRepository → DB`입니다. `GeocodingService`가 외부 Google API 호출을 담당합니다.

| API | 프론트에서 쓰는 곳 |
| --- | --- |
| `GET /api/status` | 실제 주소 검색인지 데모인지 판별 |
| `GET /api/bookmarks` | 최초 목록과 저장 후 목록 재조회 |
| `POST /api/bookmarks`, `PUT /api/bookmarks/{id}` | 생성과 수정 |
| `DELETE /api/bookmarks/{id}` | 삭제 |
| `GET /api/geocode?address=...` | 주소 후보 검색 |
| `POST /api/bookmarks/{id}/location` | 만료 좌표 갱신 |

기본 저장소는 파일 H2이며 PostgreSQL 프로필도 있습니다. 입력 검증, place ID 재확인, 좌표 만료 처리는 서버 책임입니다. 로그인과 사용자별 데이터 분리는 없는 로컬 학습용 구현입니다.

## 11. 이 코드를 바탕으로 설계할 때의 기준

### 지금부터 유지하면 좋은 경계

UI는 Repository 구현이나 HTTP 응답을 직접 해석하지 않게 하고, Store에는 화면에 필요한 상태와 작업을 둡니다. 지도 이동처럼 화면 인스턴스에 종속된 객체는 해당 State에 둡니다. 데이터를 하위 Widget에 전달하고 이벤트는 콜백으로 부모에게 올리는 흐름을 유지하면 동작을 추적하기 쉽습니다.

상태를 추가하기 전에 다음을 정하세요.

1. 이 값은 편집창 하나에서만 필요한가, 목록·지도에서도 필요한가?
2. 기존 상태에서 계산 가능한가, 별도로 저장해야 하는가?
3. 누가 객체를 생성하고 누가 dispose하는가?
4. 실패·로딩·빈 결과일 때 어떤 화면이 나오는가?
5. 사용자 동작 순서와 요청 응답 순서가 달라도 안전한가?

### 규모가 커지면 개선할 부분

현재 `HomeScreen`은 레이아웃과 다이얼로그 제어, 메뉴 동작을 한 파일에 많이 담고 있습니다. 다음 단계에서는 `BookmarkList`, `BookmarkListItem`, `BookmarkDetailsSheet`, `SearchToolbar`를 독립 Widget로 분리하는 연습이 적절합니다. 지금의 `list()` 같은 helper 메서드는 코드 묶음이며, 독립 Widget와 같은 별도 Element 경계를 만드는 것은 아닙니다.

Store는 하나의 `loading`과 `error`를 사용하고, 저장 완료 후 재조회 실패를 `load()` 내부에서 처리합니다. 따라서 서버 저장 성공과 최신 목록 동기화 실패가 구별되는 결과 타입은 아직 없습니다. 기능이 커지면 작업별 상태와 결과를 구분하고, 중복 요청·재시도·대량 목록의 페이지네이션을 설계하세요.

지금의 생성자 주입은 충분히 학습하기 좋은 출발점입니다. 깊은 트리에 의존성을 전달하기 어려워지거나 구독 범위를 세밀하게 나눌 필요가 생길 때 Provider/Riverpod 등을 검토하면 됩니다. 상태 관리 패키지를 선택하는 것과 상태의 책임을 올바르게 나누는 것은 별개입니다.

공식 아키텍처 가이드는 View·ViewModel·Repository·Service 분리의 참고 자료로 읽으세요. 이 프로토타입은 그 전체 구조를 그대로 구현한 예제는 아닙니다. [Flutter 앱 아키텍처 가이드](https://docs.flutter.dev/app-architecture/guide)

## 12. 직접 수정하며 공부하는 실습

아래 순서대로 작은 변경을 하고 실행 결과를 비교해보세요. 현재 미구현 기능은 실습 과제로 표시했습니다.

| 실습 | 수정할 곳 | 확인할 내용 |
| --- | --- | --- |
| 썸네일을 76에서 64로 변경 | `FoodThumbnail`, `BookmarkSummary` | 작은 화면에서 제목과 태그 공간이 어떻게 달라지는가? |
| 메모를 한 줄에서 두 줄로 변경 | `BookmarkSummary` | 행 높이와 지도 카드가 함께 어떻게 달라지는가? |
| 태그 필터를 눌러 데이터 흐름 설명 | `HomeScreen.filterPill` → `Store.filter` → `visible` | HTTP 없이 목록과 지도가 같이 바뀌는 이유는 무엇인가? |
| 상세 시트를 독립 Widget로 분리 | `HomeScreen.showDetails` | 표시 데이터와 행동 콜백을 어떻게 나눌 것인가? |
| 방문 여부 추가하기 — 미구현 | 모델 → 폼 → Store/필터 → Repository/API | UI만 바꾸는 것과 저장까지 연결하는 작업의 차이는 무엇인가? |
| 지도 라벨 생성을 잠시 기본 마커로 단순화 | `MapPanel.buildMarkers`, `Marker.icon` | 이미지 생성 없이 선택과 카메라 이동을 설명할 수 있는가? |
| 저장 실패 시나리오 추가 — 미구현 | 실패하는 테스트 Repository 주입 | 폼 유지·로딩 해제·오류 표시가 기대대로 동작하는가? |

기본 확인 명령은 다음과 같습니다.

```sh
cd frontend
flutter analyze
flutter test
flutter build web
```

`pumpWidget`은 테스트 화면을 만들고 `pumpAndSettle`은 예정된 프레임과 애니메이션이 가라앉을 때까지 진행합니다. React Testing Library처럼 입력·탭·기대 화면을 중심으로 읽되, Flutter에서는 프레임 진행을 테스트가 명시적으로 제어한다는 차이를 기억하세요.

Widget 테스트는 실제 지도 SDK나 Google 네트워크 성공을 보장하지 않습니다. 검색과 폼은 데모 저장소로 반복 검증하고, 실제 지도·주소 검색·플랫폼 설정은 연결한 환경에서 따로 확인하세요. 기존 검증 범위는 [verification.md](verification.md)에 기록되어 있습니다.

학습의 첫 목표는 새 패키지를 추가하는 것보다, **검색 입력 하나가 어떤 메서드를 거쳐 목록과 지도를 갱신하는지 소스를 보며 설명하고, 같은 흐름으로 작은 기능을 직접 추가하는 것**으로 잡으면 좋습니다.
