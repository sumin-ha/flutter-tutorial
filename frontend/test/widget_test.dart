import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodmarks/main.dart';
import 'package:foodmarks/repository.dart';

void main() {
  testWidgets('mobile lists, filters and validates a bookmark', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(FoodmarksApp(repository: DemoRepository()));
    await tester.pumpAndSettle();
    expect(find.text('한입 수첩'), findsOneWidget);
    expect(find.textContaining('UI 데모'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '국밥');
    await tester.pumpAndSettle();
    expect(find.text('퇴근길 따뜻한 국밥'), findsOneWidget);
    expect(find.text('골목의 작은 파스타집'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();
    expect(find.text('데모 모드 · 실제 지도 없음'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('내 수첩'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('맛집 저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    expect(find.text('필수 입력입니다.'), findsWidgets);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop shows list and explicit map placeholder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(FoodmarksApp(repository: DemoRepository()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('데모 모드 · 실제 지도 없음'), findsOneWidget);
    await tester.tap(find.byTooltip('지도에서 보기').first);
    await tester.pumpAndSettle();
    expect(find.text('수정'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('small screen keeps search across tabs and opens full details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(FoodmarksApp(repository: DemoRepository()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '파스타');
    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '파스타',
    );
    await tester.tap(find.text('골목의 작은 파스타집'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('맛집 상세 보기'));
    await tester.pumpAndSettle();
    expect(find.text('기억할 메모'), findsOneWidget);
    expect(find.text('바질 파스타가 궁금해서 저장. 다음 주 친구와 방문하기!'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('검색 지우기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
