import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:flood_relief_app/core/widgets/notices_dialog.dart';
import 'package:flood_relief_app/core/widgets/evidence_preview.dart';
import 'package:flood_relief_app/core/widgets/request_review_panel.dart';
import 'package:flood_relief_app/features/admin/screens/m19_admin_statistics_screen.dart';
import 'package:flood_relief_app/features/citizen/screens/c04_request_wizard_step3_photo_screen.dart';
import 'package:flood_relief_app/features/rescue/screens/r06_my_team_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  final image = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAAE0lEQVQImWP4z8DwnwGM/zMwAAAf7gP9qS/A4gAAAABJRU5ErkJggg==',
  );
  Json request() => {
    'id': '54a16201-b6af-4d34-bfa2-407b6115fddb',
    'stage': 'accepted',
    'revision': 3,
    'verification': 'pending',
    'reviewReason': '',
    'data': {
      'description': 'Nước dâng tại điểm thử',
      'elderly': 1,
      'children': 1,
      'disabled': 1,
      'special': 1,
      'specialNotes': '',
      'locationConfirmedAt': '2026-11-08T10:00:00Z',
    },
    'clientActionAt': '2026-11-08T10:00:00Z',
    'receivedAt': '2026-11-08T10:05:00Z',
    'clockDifferenceSeconds': -300,
    'evidence': [],
    'history': [
      {
        'action': 'updated',
        'revision': 3,
        'at': '2026-11-08T10:05:00Z',
        'details': {
          'changedFields': ['people'],
          'reason': 'Đã cập nhật số người',
        },
      },
    ],
    'reports': [
      {'reason': 'Nội dung cần kiểm tra', 'at': '2026-11-08T10:05:00Z'},
    ],
  };
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    calls.clear();
  });
  Future<void> session(String role) async {
    final original = reliefRepository;
    reliefRepository = ReliefRepository(
      api: ApiClient(
        client: MockClient((r) async {
          calls.add('${r.method} ${r.url.path}');
          final Json body;
          if (r.url.path.endsWith('/auth/login')) {
            body = {
              'token': 'test',
              'expiresAt': '2099-01-01T00:00:00Z',
              'account': {
                'id': 'workflow-$role',
                'role': role,
                'phone': '+12025550101',
                'displayName': 'Tài khoản thử',
              },
            };
          } else if (r.url.path.endsWith('/notices')) {
            body = {
              'items': [
                {
                  'id': 'test-notice',
                  'message': 'Yêu cầu cần bổ sung thông tin.',
                  'createdAt': '2026-11-08T10:05:00Z',
                  'read': false,
                },
              ],
            };
          } else if (r.url.path.endsWith('/similar')) {
            body = {
              'items': [
                {
                  'id': 'other-request',
                  'description': 'Cần nước uống tại điểm thử',
                  'distanceMetres': 10,
                  'sharedWords': 3,
                  'contentSimilarity': 0.8,
                },
              ],
            };
          } else {
            body = {'items': <Json>[], 'nextCursor': null};
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
  }

  Future<void> render(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: screen),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final role in ['admin', 'rescue']) {
    testWidgets(
      '$role sign out revokes the session and clears local account data',
      (tester) async {
        await session(role);
        await render(
          tester,
          role == 'admin'
              ? const M19AdminStatisticsScreen()
              : const R06MyTeamScreen(),
        );
        final button = find.text('Đăng xuất');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(calls, contains('DELETE /api/v1/auth/session'));
        expect(reliefRepository.signedIn, false);
        expect(reliefRepository.api.token, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'admin can inspect reports, similarity and history with real-shaped data',
    (tester) async {
      await session('admin');
      await render(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: RequestReviewPanel(request: request(), reload: () async {}),
          ),
        ),
      );
      final similar = find.text('Đối chiếu yêu cầu tương tự');
      await tester.ensureVisible(similar);
      await tester.tap(similar);
      await tester.pumpAndSettle();
      expect(find.text('Cần nước uống tại điểm thử'), findsOneWidget);
      final history = find.text('Lịch sử cập nhật');
      await tester.ensureVisible(history);
      await tester.tap(history);
      await tester.pumpAndSettle();
      expect(find.textContaining('Thông tin đã sửa: Số người'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('report form explains a missing reason without submitting', (
    tester,
  ) async {
    await session('rescue');
    await render(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: RequestReviewPanel(request: request(), reload: () async {}),
        ),
      ),
    );
    final button = find.text('Báo cáo dấu hiệu nghi vấn');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập lý do hoặc nội dung cần kiểm tra.'), findsOneWidget);
    expect(calls.where((c) => c.contains('/reports')), isEmpty);
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final granted in [true, false]) {
    testWidgets(
      'notification permission is requested only on demand ($granted)',
      (tester) async {
        await session('citizen');
        var permissionCalls = 0;
        const channel = MethodChannel(
          'flutter.baseflow.com/permissions/methods',
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'requestPermissions') {
              permissionCalls++;
              return {
                for (final id in call.arguments as List) id: granted ? 1 : 0,
              };
            }
            throw PlatformException(code: 'unexpected-test-call');
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await render(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showNotices(context),
                child: const Text('Mở thông báo'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mở thông báo'));
        await tester.pumpAndSettle();
        expect(permissionCalls, 0);
        expect(find.text('Yêu cầu cần bổ sung thông tin.'), findsOneWidget);
        await tester.tap(find.text('Cho phép thông báo'));
        await tester.pumpAndSettle();
        expect(permissionCalls, 1);
        expect(find.text('Yêu cầu cần bổ sung thông tin.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final use in [true, false]) {
    testWidgets(
      'recovered photo ${use ? 'replaces' : 'does not replace'} the previous photo',
      (tester) async {
        await session('citizen');
        final old = await reliefRepository.savePhoto(image);
        final draft = RequestDraft(
          values: {
            ...RequestDraft().values,
            'types': ['Nước uống'],
            'description': 'Dữ liệu thử',
            'address': 'Điểm thử',
            'latitude': 10.77,
            'longitude': 106.7,
            'locationSource': 'pin',
            'locationConfirmedAt': '2026-11-08T10:00:00Z',
          },
          photos: [old],
        );
        await reliefRepository.saveDraft(draft);
        await reliefRepository.cameraPending(
          context: {
            'requestId': null,
            'replacingKey': old['key'],
            'capturedAt': '2026-11-08T10:00:00Z',
            'latitude': 10.77,
            'longitude': 106.7,
          },
        );
        await reliefRepository.stageCameraPhoto(image);
        await render(
          tester,
          C04RequestWizardStep3PhotoScreen(
            reliefTypes: ['Nước uống'],
            totalPeople: 1,
            urgency: 'Cao',
            address: 'Điểm thử',
            landmark: '',
            draft: draft,
          ),
        );
        await tester.tap(find.text(use ? 'Dùng ảnh' : 'Bỏ ảnh'));
        await tester.pumpAndSettle();
        expect(draft.photos.length, 1);
        expect(draft.photos.single['key'] == old['key'], !use);
        if (use) {
          expect(draft.photos.single['capturedAt'], '2026-11-08T10:00:00.000Z');
          expect(draft.photos.single['latitude'], 10.77);
        }
        expect(await reliefRepository.hasPendingCamera(), false);
        expect(await reliefRepository.recoveredCameraPhoto(), isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'denying camera permission leaves the optional-photo path usable',
    (tester) async {
      await session('citizen');
      var requested = 0;
      const permission = MethodChannel(
        'flutter.baseflow.com/permissions/methods',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        permission,
        (call) async {
          if (call.method == 'requestPermissions') {
            requested++;
            return {for (final id in call.arguments as List) id: 0};
          }
          throw PlatformException(code: 'unexpected-test-call');
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          permission,
          null,
        ),
      );
      final draft = RequestDraft(
        values: {
          ...RequestDraft().values,
          'types': ['Nước uống'],
          'description': 'Cần nước uống',
          'address': 'Điểm thử',
          'latitude': 10.77,
          'longitude': 106.7,
          'locationSource': 'pin',
          'locationConfirmedAt': '2026-11-08T10:00:00Z',
        },
      );
      await render(
        tester,
        C04RequestWizardStep3PhotoScreen(
          reliefTypes: const ['Nước uống'],
          totalPeople: 1,
          urgency: 'Cao',
          address: 'Điểm thử',
          landmark: '',
          draft: draft,
        ),
      );
      expect(requested, 0);
      await tester.tap(find.text('Chụp ảnh'));
      await tester.pumpAndSettle();
      expect(requested, 1);
      expect(draft.photos, isEmpty);
      expect(find.textContaining('Chưa cấp quyền camera.'), findsOneWidget);
      final next = find.text('Tiếp tục không thêm ảnh');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận thông tin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('invalid image data cannot be accepted in the preview', (
    tester,
  ) async {
    Object? error;
    await render(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            child: const Text('Thử ảnh lỗi'),
            onPressed: () async {
              try {
                await previewCapturedPhoto(
                  context,
                  Uint8List.fromList([1, 2, 3]),
                );
              } catch (failure) {
                error = failure;
              }
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Thử ảnh lỗi'));
    await tester.pumpAndSettle();
    expect(error, isA<String>());
    expect(find.text('Dùng ảnh'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
