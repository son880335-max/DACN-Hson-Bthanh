import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flood_relief_app/core/data/api_client.dart';
import 'package:flood_relief_app/core/data/relief_repository.dart';
import 'package:flood_relief_app/core/data/request_draft.dart';
import 'package:flood_relief_app/core/data/vault_web.dart';
import 'package:flood_relief_app/core/theme/app_theme.dart';
import 'package:flood_relief_app/features/citizen/screens/c08_request_detail_waiting_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });
  const id = '54a16201-b6af-4d34-bfa2-407b6115fddb';
  for (final role in ['citizen', 'admin']) {
    for (final stage in ['waiting', 'accepted']) {
      testWidgets('$role sees only permitted request actions at $stage', (
        tester,
      ) async {
        var currentStage = stage;
        var revision = 1;
        final cancellations = <http.Request>[];
        Json item() => {
          'id': id,
          'stage': currentStage,
          'revision': revision,
          'verification': 'pending',
          'reviewReason': '',
          'data': {
            ...RequestDraft().values,
            'types': ['Nước uống'],
            'description': 'Dữ liệu thử',
            'latitude': 10.77,
            'longitude': 106.7,
            'locationSource': 'pin',
            'locationConfirmedAt': '2026-11-08T10:00:00Z',
            'address': 'Điểm thử',
          },
          'clientActionAt': '2026-11-08T10:00:00Z',
          'receivedAt': '2026-11-08T10:05:00Z',
          'clockDifferenceSeconds': -300,
          'contact': {'name': 'Tài khoản thử', 'phone': '+12025550101'},
          'history': [],
          'evidence': [],
          'reports': [],
        };
        final original = reliefRepository;
        reliefRepository = ReliefRepository(
          api: ApiClient(
            client: MockClient((r) async {
              Json body;
              if (r.url.path.endsWith('/auth/login')) {
                body = {
                  'token': 'test',
                  'expiresAt': '2099-01-01T00:00:00Z',
                  'account': {
                    'id': 'actions-$role',
                    'role': role,
                    'phone': '+12025550101',
                    'displayName': 'Tài khoản thử',
                  },
                };
              } else if (r.url.path.endsWith('/cancel')) {
                cancellations.add(r);
                currentStage = 'cancelled';
                revision++;
                body = {
                  'requestId': id,
                  'stage': currentStage,
                  'revision': revision,
                  'serverSavedAt': '2026-11-08T10:06:00Z',
                };
              } else if (r.url.path.endsWith('/requests/$id')) {
                body = item();
              } else {
                body = {'items': <Json>[]};
              }
              return http.Response(
                jsonEncode(body),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }),
          ),
          openStore: (_) async => MemoryVault(),
        );
        addTearDown(() {
          reliefRepository.dispose();
          reliefRepository = original;
        });
        await reliefRepository.login('+12025550101', 'test', role);
        await tester.binding.setSurfaceSize(const Size(320, 780));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: C08RequestDetailWaitingScreen(requestId: id),
          ),
        );
        await tester.pumpAndSettle();
        final mayChange = role == 'citizen' && stage == 'waiting';
        expect(
          find.text('Chỉnh sửa yêu cầu'),
          mayChange ? findsOneWidget : findsNothing,
        );
        final cancel = find.text('Hủy yêu cầu cứu trợ này');
        expect(cancel, mayChange ? findsOneWidget : findsNothing);
        if (mayChange) {
          await tester.ensureVisible(cancel);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Quay lại'));
          await tester.pumpAndSettle();
          expect(cancellations, isEmpty);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Xác nhận hủy'));
          await tester.pumpAndSettle();
          expect(cancellations.length, 1);
          expect(jsonDecode(cancellations.single.body)['confirmed'], true);
          expect(cancellations.single.headers['If-Match'], '"1"');
          expect(find.text('Yêu cầu đã được hủy.'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
