import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flood_relief_app/features/requests/data/relief_request.dart';
import 'package:flood_relief_app/features/requests/data/request_store.dart';
import 'package:flood_relief_app/features/requests/data/camera_checkpoint.dart';
import 'package:flood_relief_app/features/requests/screens/request_detail_screen.dart';
import 'package:flood_relief_app/features/requests/screens/request_wizard_screen.dart';
import 'package:flood_relief_app/features/requests/services/evidence_service.dart';

import 'request_creation_test.dart' show validDraft;

class FakeEvidence extends EvidenceService {
  int cameraCalls = 0, notificationCalls = 0, locationCalls = 0;
  @override
  Future<EvidencePhoto?> capture() async {
    cameraCalls++;
    return null;
  }

  @override
  Future<Position> locate() async {
    locationCalls++;
    throw const RequestError('Quyền vị trí bị từ chối');
  }

  @override
  Future<bool> requestNotifications() async {
    notificationCalls++;
    return false;
  }
}

class RecoveredEvidence extends FakeEvidence {
  @override
  Future<EvidencePhoto?> recoverCapture(DateTime startedAt) async {
    final picture = sample();
    return EvidencePhoto(
      id: 'recovered',
      base64: picture.base64,
      capturedAt: startedAt,
      recovered: true,
    );
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await RequestStore.instance.load();
  });
  Future<void> show(
    WidgetTester tester,
    Widget screen, {
    double width = 440,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Android camera: khôi phục biểu mẫu và ảnh mà không ghi đè yêu cầu đã gửi',
    (tester) async {
      final original = RequestStore.instance.get('CR-0247');
      await tester.runAsync(
        () => RequestStore.instance.cameraRecovery!.write(
          CameraCheckpoint(
            data: original.data.copy()..people = 5,
            requestId: original.id,
            revision: original.revision,
            startedAt: DateTime.now().toUtc(),
          ),
        ),
      );
      await show(
        tester,
        RequestWizardScreen(evidenceService: RecoveredEvidence()),
      );
      expect(find.text('Khôi phục phiên chụp ảnh?'), findsOneWidget);
      await tester.tap(find.text('Khôi phục'));
      await tester.pumpAndSettle();
      expect(find.text('Ảnh xác minh (1/5)'), findsOneWidget);
      expect(
        RequestStore.instance.get(original.id).data.people,
        original.data.people,
      );
      expect(RequestStore.instance.cameraRecovery!.read(), isNull);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'Android Back: lùi bước trước; ở bước đầu phải xác nhận bỏ dữ liệu đang soạn',
    (tester) async {
      tester.view.physicalSize = const Size(440, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestWizardScreen(
                      initialStep: 2,
                      initialData: validDraft(),
                    ),
                  ),
                ),
                child: const Text('Mở biểu mẫu'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở biểu mẫu'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bước 2/4: Vị trí'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Người cần hỗ trợ'), findsOneWidget);
      await tester.tap(find.text('Người khác'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Rời biểu mẫu?'), findsOneWidget);
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(find.text('Người cần hỗ trợ'), findsOneWidget);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('US-021: biểu mẫu nhu cầu không tràn ngang ở chiều rộng 360', (
    tester,
  ) async {
    await show(
      tester,
      RequestWizardScreen(initialData: validDraft()),
      width: 360,
    );
    expect(find.text('Người cần hỗ trợ'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'US-040: quản trị yêu cầu bổ sung có lý do và thông báo cho chủ yêu cầu',
    (tester) async {
      await show(
        tester,
        const RequestDetailScreen(requestId: 'CR-0251', role: DemoRole.admin),
      );
      await tester.scrollUntilVisible(
        find.text('Cần bổ sung'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Cần bổ sung')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cần bổ sung'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Cần ảnh rõ vị trí hiện tại',
      );
      await tester.pump();
      await tester.tap(find.text('Xác nhận'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      final result = RequestStore.instance.get('CR-0251', role: DemoRole.admin);
      expect(result.verification, Verification.needsInfo);
      expect(result.reason, 'Cần ảnh rõ vị trí hiện tại');
      expect(
        result.notices.last['text'],
        contains('Cần ảnh rõ vị trí hiện tại'),
      );
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'US-107: không xin quyền khi mở; camera chỉ chạy khi bấm và hủy không thêm ảnh',
    (tester) async {
      final service = FakeEvidence();
      await show(
        tester,
        RequestWizardScreen(
          initialStep: 2,
          initialData: validDraft(),
          evidenceService: service,
        ),
      );
      expect(service.cameraCalls, 0);
      expect(service.locationCalls, 0);
      expect(service.notificationCalls, 0);
      await tester.tap(find.text('Chụp ảnh'));
      await tester.pumpAndSettle();
      expect(service.cameraCalls, 1);
      expect(service.locationCalls, 0);
      expect(find.text('Ảnh xác minh (0/5)'), findsOneWidget);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets('US-033: xem trước ảnh, từ chối giữ ảnh không thay dữ liệu', (
    tester,
  ) async {
    await show(
      tester,
      RequestWizardScreen(initialStep: 2, initialData: validDraft()),
    );
    await tester.tap(find.text('Thêm ảnh mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra độ rõ của ảnh'), findsOneWidget);
    await tester.tap(find.text('Không dùng ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Ảnh xác minh (0/5)'), findsOneWidget);
    await tester.tap(find.text('Thêm ảnh mẫu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dùng ảnh này'));
    await tester.pumpAndSettle();
    expect(find.text('Ảnh xác minh (1/5)'), findsOneWidget);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets(
    'US-103: giữ yêu cầu không đổi trạng thái; xác nhận hủy cập nhật chi tiết',
    (tester) async {
      await show(tester, const RequestDetailScreen(requestId: 'CR-0247'));
      await tester.tap(find.text('Hủy yêu cầu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giữ yêu cầu'));
      await tester.pumpAndSettle();
      expect(RequestStore.instance.get('CR-0247').stage, RequestStage.waiting);
      await tester.tap(find.text('Hủy yêu cầu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận hủy'));
      await tester.pumpAndSettle();
      expect(
        RequestStore.instance.get('CR-0247').stage,
        RequestStage.cancelled,
      );
      expect(find.text('Xử lý: Đã hủy'), findsOneWidget);
      expect(find.text('Hủy yêu cầu'), findsNothing);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets('US-029/021: xem lại và gửi tạo mã động, chuyển sang chi tiết', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final r in RequestStore.instance.list().where(
        (r) => r.stage == RequestStage.waiting,
      )) {
        await RequestStore.instance.cancel(r.id, confirmed: true);
      }
    });
    await show(
      tester,
      RequestWizardScreen(
        initialStep: 3,
        initialData: validDraft()
          ..special = 1
          ..specialNotes = 'Cần hỗ trợ thở',
      ),
    );
    expect(find.text('Chăm sóc: Cần hỗ trợ thở'), findsOneWidget);
    await tester.tap(find.text('Gửi yêu cầu mẫu'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết yêu cầu'), findsOneWidget);
    final created = RequestStore.instance.list().firstWhere(
      (r) => r.stage == RequestStage.waiting,
    );
    expect(created.id, isNot('CR-0247'));
    expect(created.data.specialNotes, 'Cần hỗ trợ thở');
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets(
    'US-107: từ chối thông báo vẫn xem được thông báo trong ứng dụng',
    (tester) async {
      final service = FakeEvidence();
      final request = RequestStore.instance.list().firstWhere(
        (r) => r.stage != RequestStage.draft,
      );
      await show(
        tester,
        RequestDetailScreen(requestId: request.id, evidenceService: service),
      );
      expect(service.notificationCalls, 0);
      await tester.scrollUntilVisible(
        find.text('Cho phép thông báo hệ thống'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Cho phép thông báo hệ thống')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cho phép thông báo hệ thống'));
      await tester.pumpAndSettle();
      expect(service.notificationCalls, 1);
      expect(service.cameraCalls, 0);
      expect(service.locationCalls, 0);
      expect(
        find.text('Chưa cấp quyền. Bạn vẫn xem được thông báo tại đây.'),
        findsOneWidget,
      );
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
