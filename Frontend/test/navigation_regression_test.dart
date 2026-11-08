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
import 'package:flood_relief_app/core/widgets/app_button.dart';
import 'package:flood_relief_app/features/auth/screens/a01_role_selection_screen.dart';
import 'package:flood_relief_app/features/auth/screens/a02_citizen_login_screen.dart';
import 'package:flood_relief_app/features/admin/screens/m01_admin_login_screen.dart';
import 'package:flood_relief_app/features/admin/screens/admin_shell_screen.dart';
import 'package:flood_relief_app/features/citizen/screens/citizen_shell_screen.dart';
import 'package:flood_relief_app/features/citizen/screens/c06_request_wizard_step4_review_submit_screen.dart';
import 'package:flood_relief_app/features/citizen/screens/c08_request_detail_waiting_screen.dart';
import 'package:flood_relief_app/features/rescue/screens/r01_rescue_login_screen.dart';
import 'package:flood_relief_app/features/rescue/screens/rescue_shell_screen.dart';
import 'package:flood_relief_app/features/rescue/screens/r17_offline_download_screen.dart';
import 'package:flood_relief_app/features/rescue/screens/r13_rescue_navigation_route_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> calls;
  const requestId = '54a16201-b6af-4d34-bfa2-407b6115fddb';
  final values = {
    ...RequestDraft().values,
    'types': ['Nước uống'],
    'people': 2,
    'description': 'Cần nước uống tại điểm thử',
    'latitude': 10.77,
    'longitude': 106.7,
    'locationSource': 'pin',
    'locationConfirmedAt': DateTime.now().toUtc().toIso8601String(),
    'address': 'Điểm thử',
  };
  Json item() => {
    'id': requestId,
    'stage': 'waiting',
    'revision': 1,
    'verification': 'pending',
    'data': values,
    'contact': {'name': 'Tài khoản thử', 'phone': '+12025550101'},
    'receivedAt': DateTime.now().toUtc().toIso8601String(),
    'clientActionAt': DateTime.now().toUtc().toIso8601String(),
    'evidence': [],
    'history': [],
    'reports': [],
  };
  void repository(String role) {
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
                'id': 'nav-$role',
                'role': role,
                'phone': '+12025550101',
                'displayName': 'Tài khoản thử',
              },
            };
          } else if (r.method == 'POST' && r.url.path.endsWith('/requests')) {
            body = {
              'requestId': requestId,
              'revision': 1,
              'serverSavedAt': DateTime.now().toUtc().toIso8601String(),
            };
          } else if (r.url.path.endsWith('/requests/$requestId')) {
            body = item();
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
  }

  setUp(() {
    calls = [];
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });
  Future<void> render(
    WidgetTester tester,
    Widget screen,
    GlobalKey<NavigatorState> key,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, navigatorKey: key, home: screen),
    );
    await tester.pumpAndSettle();
  }

  for (final role in ['citizen', 'rescue', 'admin']) {
    testWidgets(
      '$role login clears authentication history; Back never returns to login',
      (tester) async {
        repository(role);
        final navigator = GlobalKey<NavigatorState>();
        await render(tester, const A01RoleSelectionScreen(), navigator);
        final login = switch (role) {
          'citizen' => const A02CitizenLoginScreen(),
          'rescue' => const R01RescueLoginScreen(),
          _ => const M01AdminLoginScreen(),
        };
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => login),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).at(0), '+12025550101');
        await tester.enterText(find.byType(TextField).at(1), 'test');
        final submit = find.widgetWithText(AppButton, 'Đăng nhập');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(navigator.currentState!.canPop(), isFalse);
        expect(find.byType(A01RoleSelectionScreen), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(reliefRepository.signedIn, isTrue);
        expect(find.byType(A02CitizenLoginScreen), findsNothing);
        expect(find.byType(R01RescueLoginScreen), findsNothing);
        expect(find.byType(M01AdminLoginScreen), findsNothing);
        expect(calls.where((c) => c.startsWith('DELETE')), isEmpty);
      },
    );
  }
  testWidgets(
    'submit then arrow Back returns to citizen home instead of login or wizard',
    (tester) async {
      repository('citizen');
      await reliefRepository.login('+12025550101', 'test', 'citizen');
      final navigator = GlobalKey<NavigatorState>();
      await render(tester, const CitizenShellScreen(), navigator);
      final draft = RequestDraft();
      draft.values.addAll(values);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => C06RequestWizardStep4ReviewSubmitScreen(
            reliefTypes: const ['Nước uống'],
            totalPeople: 2,
            urgency: 'Cao',
            address: 'Điểm thử',
            landmark: '',
            photosCount: 0,
            photoNote: '',
            draft: draft,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final send = find.widgetWithText(AppButton, 'Gửi yêu cầu cứu trợ');
      await tester.ensureVisible(send);
      await tester.tap(send);
      // The submit button remains busy while the receipt dialog is open.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Xem yêu cầu'), findsOneWidget);
      await tester.tap(find.text('Xem yêu cầu'));
      await tester.pumpAndSettle();
      expect(find.byType(C08RequestDetailWaitingScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.byType(CitizenShellScreen), findsOneWidget);
      expect(
        find.byType(C06RequestWizardStep4ReviewSubmitScreen),
        findsNothing,
      );
      expect(navigator.currentState!.canPop(), isFalse);
      expect(reliefRepository.signedIn, isTrue);
    },
  );
  for (final role in ['citizen', 'rescue', 'admin']) {
    testWidgets(
      '$role system Back from a secondary tab returns to the first tab',
      (tester) async {
        repository(role);
        await reliefRepository.login('+12025550101', 'test', role);
        final Widget shell = switch (role) {
          'citizen' => const CitizenShellScreen(initialIndex: 1),
          'rescue' => const RescueShellScreen(initialIndex: 2),
          _ => const AdminShellScreen(initialIndex: 1),
        };
        final navigator = GlobalKey<NavigatorState>();
        await render(tester, shell, navigator);
        if (role == 'rescue') {
          expect(find.byType(R17OfflineDownloadScreen), findsOneWidget);
          expect(find.byTooltip('Quay lại'), findsNothing);
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .currentIndex,
          0,
        );
        expect(navigator.currentState!.canPop(), isFalse);
        expect(reliefRepository.signedIn, isTrue);
        expect(
          find.text(switch (role) {
            'citizen' => 'Cứu trợ lũ lụt',
            'rescue' => 'Yêu cầu đang phụ trách',
            _ => 'Tổng quan cứu trợ (minh họa)',
          }),
          findsOneWidget,
        );
      },
    );
  }
  testWidgets(
    'offline preview keeps the rescue shell and Back returns to its tab',
    (tester) async {
      repository('rescue');
      await reliefRepository.login('+12025550101', 'test', 'rescue');
      final navigator = GlobalKey<NavigatorState>();
      await render(tester, const RescueShellScreen(initialIndex: 2), navigator);
      final preview = find.widgetWithText(AppButton, 'Xem bản đồ minh họa');
      await tester.ensureVisible(preview);
      await tester.tap(preview);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Xem bản đồ minh họa'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(R13RescueNavigationRouteScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.byType(R17OfflineDownloadScreen), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        2,
      );
      expect(navigator.currentState!.canPop(), isFalse);
      expect(reliefRepository.signedIn, isTrue);
    },
  );
}
