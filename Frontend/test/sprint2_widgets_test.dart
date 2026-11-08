import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flood_relief_app/core/data/api_client.dart';
import 'package:flood_relief_app/core/data/relief_repository.dart';
import 'package:flood_relief_app/core/data/request_draft.dart';
import 'package:flood_relief_app/core/data/vault_web.dart';
import 'package:flood_relief_app/core/theme/app_theme.dart';
import 'package:flood_relief_app/core/widgets/evidence_preview.dart';
import 'package:flood_relief_app/features/citizen/screens/c02_request_wizard_step1_screen.dart';
import 'package:flood_relief_app/features/citizen/screens/c06_request_wizard_step4_review_submit_screen.dart';
import 'package:flood_relief_app/features/citizen/screens/c07_my_requests_screen.dart';
import 'package:flood_relief_app/features/citizen/screens/c20_profile_screen.dart';
import 'package:flood_relief_app/features/admin/screens/m03_admin_requests_lookup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });
  Future<void> session(String role, {List<Json> items = const []}) async {
    final original = reliefRepository;
    reliefRepository = ReliefRepository(
      api: ApiClient(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(
              request.url.path.endsWith('/auth/login')
                  ? {
                      'token': 'test',
                      'expiresAt': '2099-01-01T00:00:00Z',
                      'account': {
                        'id': 'widget-$role',
                        'role': role,
                        'phone': '+12025550101',
                        'displayName': 'Tài khoản thử',
                      },
                    }
                  : request.url.path.endsWith('/notices')
                  ? {'items': <Json>[]}
                  : {'items': items, 'nextCursor': null},
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
      openStore: (_) async => MemoryVault(),
    );
    await reliefRepository.login('+12025550101', 'test', role);
    addTearDown(() {
      reliefRepository.dispose();
      reliefRepository = original;
    });
  }

  Future<void> render(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: screen),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('profile settings and account actions render and remain usable', (
    tester,
  ) async {
    await session('citizen');
    await render(tester, const C20ProfileScreen());
    final alerts = find.byType(SwitchListTile).first;
    await tester.ensureVisible(alerts);
    expect(tester.widget<SwitchListTile>(alerts).value, isTrue);
    await tester.tap(alerts);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(alerts).value, isFalse);
    final help = find.text('Hướng dẫn kỹ năng an toàn mùa lũ');
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(
      find.text('Hướng dẫn an toàn chưa có sẵn trong ứng dụng.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'complete urgency names survive wizard navigation on a narrow screen',
    (tester) async {
      await session('citizen');
      final draft = RequestDraft(
        values: {
          ...RequestDraft().values,
          'types': ['Nước uống'],
          'description': 'Cần nước uống',
          'people': 4,
        },
      );
      await render(tester, C02RequestWizardStep1Screen(draft: draft));
      final option = find.text('Trung bình (bị cô lập, còn đồ dự trữ)');
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pump();
      final next = find.text('Tiếp tục');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(reliefRepository.draft?.values['urgency'], 'Trung bình');
      expect(find.text('Vị trí cần hỗ trợ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'preview displays saved groups, coordinates and account contact',
    (tester) async {
      await session('citizen');
      final draft = RequestDraft(
        values: {
          ...RequestDraft().values,
          'types': ['Nước uống'],
          'description': 'Cần nước uống',
          'people': 4,
          'elderly': 1,
          'children': 1,
          'special': 1,
          'address': 'Điểm thử',
          'latitude': 0.0,
          'longitude': 106.0,
          'locationSource': 'pin',
          'locationConfirmedAt': '2026-11-08T10:00:00Z',
        },
      );
      await render(
        tester,
        C06RequestWizardStep4ReviewSubmitScreen(
          reliefTypes: ['Nước uống'],
          totalPeople: 4,
          urgency: 'Cao',
          address: 'Điểm thử',
          landmark: '',
          photosCount: 0,
          photoNote: 'Cần nước uống',
          draft: draft,
        ),
      );
      expect(find.text('0.0, 106.0'), findsOneWidget);
      expect(find.text('+12025550101'), findsOneWidget);
      expect(find.textContaining('đặc biệt: 1'), findsOneWidget);
    },
  );
  for (final choice in <String, bool?>{
    'Dùng ảnh': true,
    'Chụp lại': false,
    'Bỏ ảnh': null,
  }.entries) {
    testWidgets('photo preview returns the explicit choice: ${choice.key}', (
      tester,
    ) async {
      var resolved = false;
      bool? result;
      final image = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAAE0lEQVQImWP4z8DwnwGM/zMwAAAf7gP9qS/A4gAAAABJRU5ErkJggg==',
      );
      await render(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await previewCapturedPhoto(context, image);
                resolved = true;
              },
              child: const Text('Mở xem trước'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở xem trước'));
      await tester.pumpAndSettle();
      expect(resolved, false);
      await tester.tap(find.text(choice.key));
      await tester.pumpAndSettle();
      expect(resolved, true);
      expect(result, choice.value);
      expect(tester.takeException(), isNull);
    });
  }
  for (final role in ['citizen', 'admin']) {
    testWidgets('$role request cards fit long real IDs at 320 pixels', (
      tester,
    ) async {
      await session(
        role,
        items: [
          {
            'id': '54a16201-b6af-4d34-bfa2-407b6115fddb',
            'stage': 'waiting',
            'verification': 'pending',
            'revision': 1,
            'types': ['Nước uống'],
            'people': 4,
            'urgency': 'Khẩn cấp',
            'address': 'Địa điểm thử nghiệm',
            'createdAt': '2026-11-08T10:00:00Z',
            'contact': {'name': 'Tài khoản thử', 'phone': '+12025550101'},
          },
        ],
      );
      await render(
        tester,
        role == 'citizen'
            ? const C07MyRequestsScreen()
            : const M03AdminRequestsLookupScreen(),
      );
      expect(find.text('54a16201'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
