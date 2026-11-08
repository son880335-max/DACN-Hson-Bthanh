import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flood_relief_app/features/requests/data/relief_request.dart';
import 'package:flood_relief_app/features/requests/data/request_store.dart';
import 'package:flood_relief_app/features/requests/screens/request_wizard_screen.dart';
import 'package:flood_relief_app/features/requests/services/evidence_service.dart';

/// Chạy trên AVD kiểm thử. Dùng plugin Android thật, không mock platform channel.
/// Cấp quyền bằng adb trước khi chạy để bài kiểm thử không kẹt ở hộp thoại OS.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: đăng ký plugin, quyền và GPS thật của máy ảo', (
    tester,
  ) async {
    debugPrint('ANDROID_PERMISSION_SETUP_READY');
    final deadline = DateTime.now().add(const Duration(seconds: 40));
    while (DateTime.now().isBefore(deadline)) {
      if (await Permission.camera.isGranted &&
          await Permission.locationWhenInUse.isGranted) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(await Permission.camera.status, PermissionStatus.granted);
    expect(await Permission.locationWhenInUse.status, PermissionStatus.granted);
    final position = await EvidenceService().locate();
    expect(validCoordinates(position.latitude, position.longitude), isTrue);
    expect(position.accuracy, greaterThanOrEqualTo(0));
    debugPrint('ANDROID_GPS_OK: ${position.latitude}, ${position.longitude}');
  });

  testWidgets(
    'Android: gửi từ giao diện, lưu thật, đọc lại và quản trị bổ sung',
    (tester) async {
      final store = RequestStore.instance;
      await store.load();
      for (final r in store.list().where(
        (r) => r.stage == RequestStage.waiting,
      )) {
        await store.cancel(r.id, confirmed: true);
      }
      final draft = RequestDraft()
        ..types = ['Sơ tán', 'Thuốc men']
        ..people = 4
        ..elderly = 1
        ..children = 1
        ..special = 1
        ..specialNotes = 'Cần hỗ trợ chăm sóc'
        ..urgency = 'Khẩn cấp'
        ..description = 'Kiểm thử Android: gia đình bị cô lập'
        ..latitude = 20.8841
        ..longitude = 105.6215
        ..locationSource = 'Vị trí kiểm thử'
        ..address = 'Thôn Nam Hài'
        ..landmark = 'Nhà mái xanh'
        ..photos = [EvidenceService().sample()];
      await tester.pumpWidget(
        MaterialApp(
          home: RequestWizardScreen(initialStep: 3, initialData: draft),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi yêu cầu mẫu'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết yêu cầu'), findsOneWidget);
      final request = store.list().firstWhere(
        (r) => r.stage == RequestStage.waiting,
      );
      await (await SharedPreferences.getInstance()).reload();
      final reopened = RequestStore();
      await reopened.load();
      expect(reopened.get(request.id).data.specialNotes, 'Cần hỗ trợ chăm sóc');
      expect(reopened.get(request.id).data.photos.single.bytes, isNotEmpty);
      await store.review(
        request.id,
        Verification.needsInfo,
        'Bổ sung ảnh rõ hơn',
        role: DemoRole.admin,
      );
      await tester.pumpAndSettle();
      expect(
        store.get(request.id).notices.last['text'],
        contains('Bổ sung ảnh rõ hơn'),
      );
      debugPrint('ANDROID_PERSISTENCE_AND_FLOW_OK: ${request.id}');
    },
  );

  if (const bool.fromEnvironment('ANDROID_CAMERA_TEST')) {
    testWidgets('Android: camera hệ thống trả ảnh và đóng dấu JPEG', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('ANDROID_CAMERA_READY'))),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('ANDROID_CAMERA_READY');
      final photo = await EvidenceService().capture();
      expect(photo, isNotNull);
      expect(
        (RequestDraft()..photos = [photo!]).validate(throughStep: 3),
        isNot(contains('Ảnh bị lỗi hoặc vượt quá 1 MB. Hãy chụp lại.')),
      );
      expect(photo.demo, isFalse);
      debugPrint('ANDROID_CAMERA_OK: ${photo.bytes.length} bytes');
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
