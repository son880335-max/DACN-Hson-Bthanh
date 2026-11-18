import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flood_relief_app/core/data/api_client.dart';
import 'package:flood_relief_app/core/data/relief_repository.dart';
import 'package:flood_relief_app/features/dispatch/dispatch_screen.dart';

void main() {
  test('API error mapping translates dispatch error codes to Vietnamese', () {
    final client = ApiClient();
    for (final entry in dispatchErrorMessages.entries) {
      final response = http.Response(
        jsonEncode({'code': entry.key, 'message': 'Original English error'}),
        409,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
      try {
        client.decode(response);
        fail('Should throw ApiFailure');
      } on ApiFailure catch (e) {
        expect(e.code, entry.key);
        expect(e.message, entry.value);
      }
    }
  });

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

  testWidgets('DispatchDetail shows Vietnamese error and triggers reload callback on conflict', (tester) async {
    var reloaded = false;
    final mockHttp = MockClient((request) async {
      if (request.url.path.contains('/actions')) {
        return http.Response(
          jsonEncode({
            'code': 'TASK_TAKEN',
            'message': 'Task already taken',
          }),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{}', 200);
    });

    reliefRepository = ReliefRepository(
      api: ApiClient(client: mockHttp),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DispatchDetail(
                    mode: 'waiting',
                    item: const {
                      'id': '00000000-0000-4000-8000-000000000001',
                      'revision': 1,
                      'status': 'waiting',
                      'urgency': 'Cao',
                      'people': 2,
                      'types': ['Sơ tán'],
                    },
                    onConflict: () {
                      reloaded = true;
                    },
                  ),
                ),
              );
            },
            child: const Text('Mở chi tiết'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Mở chi tiết'));
    await tester.pumpAndSettle();

    // Tap "Nhận nhiệm vụ"
    await tester.tap(find.widgetWithText(FilledButton, 'Nhận nhiệm vụ'));
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Nhận nhiệm vụ này?'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    // Verify Vietnamese message is shown
    expect(find.text('Nhiệm vụ vừa được đội khác tiếp nhận.'), findsOneWidget);
    // Verify reload callback was triggered
    expect(reloaded, isTrue);
  });
}
