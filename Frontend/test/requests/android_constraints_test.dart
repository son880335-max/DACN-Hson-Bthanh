import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flood_relief_app/features/requests/data/camera_checkpoint.dart';
import 'package:flood_relief_app/features/requests/data/relief_request.dart';
import 'package:flood_relief_app/features/requests/data/request_store.dart';
import 'package:flood_relief_app/features/requests/services/evidence_service.dart';

import 'request_creation_test.dart' show validDraft;

void main() {
  test('US-024: người già và trẻ em không thể cộng vượt tổng; khuyết tật được giao nhóm', () {
    expect(
      (validDraft()
            ..elderly = 3
            ..children = 2)
          .validate(),
      isNotEmpty,
    );
    expect(
      (validDraft()
            ..elderly = 3
            ..children = 1
            ..disabled = 4)
          .validate(),
      isEmpty,
    );
  });
  test('US-031: không chấp nhận tệp chỉ giả chữ ký JPEG', () {
    final draft = validDraft()
      ..photos = [
        EvidencePhoto(
          id: 'bad',
          base64: base64Encode([255, 216, 0, 0]),
          capturedAt: DateTime.now(),
        ),
      ];
    expect(draft.validate(), isNotEmpty);
  });
  test('Android: checkpoint giữ đủ biểu mẫu, phiên bản và vị trí thay ảnh qua lần mở lại', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = CameraCheckpointStore(prefs);
    final data = validDraft()
      ..photos = [EvidenceService().sample()]
      ..special = 1
      ..specialNotes = 'Cần chăm sóc';
    await store.write(
      CameraCheckpoint(
        data: data,
        startedAt: DateTime.utc(2026, 11, 7),
        requestId: 'CR-0247',
        revision: 3,
        replaceIndex: 0,
      ),
    );
    data.description = 'Thay đổi ngoài snapshot';
    final restored = CameraCheckpointStore(prefs).read()!;
    expect(restored.requestId, 'CR-0247');
    expect(restored.revision, 3);
    expect(restored.replaceIndex, 0);
    expect(restored.data.photos, hasLength(1));
    expect(restored.data.specialNotes, 'Cần chăm sóc');
    expect(restored.data.description, isNot(data.description));
    await store.clear();
    expect(store.read(), isNull);
  });
  test('US-034/035: ảnh khôi phục luôn có cảnh báo thời gian, không gán GPS hiện tại', () {
    final photo = EvidenceService().sample();
    final recovered = EvidencePhoto(
      id: photo.id,
      base64: photo.base64,
      capturedAt: photo.capturedAt,
      recovered: true,
    );
    final restored = EvidencePhoto.fromJson(recovered.toJson());
    expect(restored.recovered, isTrue);
    expect(restored.latitude, isNull);
    expect(
      evidenceFlags(validDraft()..photos = [restored], DateTime.now()),
      contains('Ảnh khôi phục: chưa xác định chính xác giờ và GPS lúc chụp'),
    );
  });
  test('US-040: duyệt lại yêu cầu cũ không làm phát sinh hai yêu cầu đang hoạt động', () async {
    final store = RequestStore(save: (_) async {});
    final old = await store.submit(validDraft());
    await store.review(
      old,
      Verification.invalid,
      'Sai thông tin',
      role: DemoRole.admin,
    );
    final current = await store.submit(validDraft());
    await expectLater(
      store.review(
        old,
        Verification.valid,
        'Xác minh lại',
        role: DemoRole.admin,
      ),
      throwsA(isA<RequestError>()),
    );
    expect(store.get(old).verification, Verification.invalid);
    expect(store.get(current).stage, RequestStage.waiting);
  });
}
