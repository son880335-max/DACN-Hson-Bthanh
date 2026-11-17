import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flood_relief_app/features/dispatch/dispatch_screen.dart';

void main() {
  testWidgets('US-047/104 shows a redacted task and a large action on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.4)),
        child: child!,
      ),
      home: const DispatchDetail(mode: 'waiting', item: {
        'id': '00000000-0000-4000-8000-000000000001',
        'status': 'waiting', 'urgency': 'Cao', 'people': 4, 'types': ['Sơ tán'],
      }),
    ));
    expect(find.text('Chờ tiếp nhận'), findsOneWidget);
    expect(find.text('Cao · 4 người'), findsOneWidget);
    expect(find.textContaining('Liên hệ:'), findsNothing);
    final button = find.widgetWithText(FilledButton, 'Nhận nhiệm vụ');
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('US-108 opens and closes the send and tracking guide', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => showDispatchGuide(context), child: const Text('Hướng dẫn')),
    ))));
    await tester.tap(find.text('Hướng dẫn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chờ thông báo xác nhận từ máy chủ'), findsOneWidget);
    expect(find.textContaining('Vào Yêu cầu để xem tiến độ'), findsOneWidget);
    await tester.tap(find.text('Đã hiểu'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
