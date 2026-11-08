import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flood_relief_app/core/data/api_client.dart';
import 'package:flood_relief_app/core/data/relief_repository.dart';
import 'package:flood_relief_app/core/data/vault_web.dart';
import 'package:flood_relief_app/core/theme/app_theme.dart';
import 'package:flood_relief_app/core/widgets/request_review_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'week2 admin can open the stored request history without an assertion',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      FlutterSecureStorage.setMockInitialValues({});
      final original = reliefRepository;
      reliefRepository = ReliefRepository(
        api: ApiClient(
          client: MockClient(
            (request) async => http.Response(
              jsonEncode(
                request.url.path.endsWith('/auth/login')
                    ? {
                        'token': 'audit-only',
                        'expiresAt': '2099-01-01T00:00:00Z',
                        'account': {
                          'id': 'audit-admin',
                          'role': 'admin',
                          'displayName': 'Audit fixture',
                          'phone': '+12025550103',
                        },
                      }
                    : {'items': [], 'nextCursor': null},
              ),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        ),
        openStore: (_) async => MemoryVault(),
      );
      addTearDown(() {
        reliefRepository.dispose();
        reliefRepository = original;
      });
      await reliefRepository.login('+12025550103', 'audit-only', 'admin');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RequestReviewPanel(
                request: {
                  'id': '00000000-0000-4000-8000-000000000021',
                  'revision': 1,
                  'stage': 'waiting',
                  'verification': 'pending',
                  'reviewReason': '',
                  'data': {
                    'description': 'Audit data',
                    'elderly': 1,
                    'children': 1,
                    'disabled': 0,
                    'special': 0,
                    'specialNotes': '',
                    'locationConfirmedAt': '2026-11-08T08:00:00Z',
                  },
                  'clientActionAt': '2026-11-08T08:00:00Z',
                  'receivedAt': '2026-11-08T08:00:01Z',
                  'clockDifferenceSeconds': -1,
                  'evidence': [],
                  'reports': [],
                  'history': [
                    {
                      'id': '1',
                      'action': 'submitted',
                      'revision': 1,
                      'at': '2026-11-08T08:00:01Z',
                      'details': {},
                    },
                  ],
                },
                reload: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Lịch sử cập nhật'));
      await tester.pumpAndSettle();
      expect(find.text('Đã gửi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
