import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flood_relief_app/features/requests/data/relief_request.dart';
import 'package:flood_relief_app/features/requests/data/request_store.dart';
import 'package:flood_relief_app/features/requests/services/evidence_service.dart';

import 'request_creation_test.dart' show validDraft;

void main() {
  test('US-036: nhận diện nội dung gần giống, không chỉ trùng chuỗi', () {
    expect(
      similarContent(
        'Gia đình mắc kẹt trên mái nhà',
        'Gia đình đang mắc kẹt trên mái nhà!',
      ),
      isTrue,
    );
    expect(
      similarContent('Cần nước uống cho gia đình', 'Hỗ trợ y tế người bệnh'),
      isFalse,
    );
  });
  test('US-038/039: báo cáo theo mã yêu cầu khác nhưng không đọc được dữ liệu riêng', () async {
    final store = RequestStore(save: (_) async {});
    final id = await store.submit(validDraft(), actor: 'other-citizen');
    expect(() => store.get(id), throwsA(isA<RequestError>()));
    await store.report(id, 'Có dấu hiệu dùng lại nội dung');
    expect(store.get(id, role: DemoRole.admin).reports, hasLength(1));
    expect(store.list(), isEmpty);
  });
  test('US-031: từ chối tệp hỏng, quá lớn, ảnh quá nhỏ', () {
    final service = EvidenceService();
    expect(
      () => service.stamp(
        Uint8List.fromList([1, 2, 3]),
        capturedAt: DateTime.now(),
      ),
      throwsA(isA<RequestError>()),
    );
    expect(
      () => service.stamp(
        Uint8List(10 * 1024 * 1024 + 1),
        capturedAt: DateTime.now(),
      ),
      throwsA(isA<RequestError>()),
    );
    expect(
      () => service.stamp(
        Uint8List.fromList(img.encodePng(img.Image(width: 1, height: 1))),
        capturedAt: DateTime.now(),
      ),
      throwsA(isA<RequestError>()),
    );
  });
  test('US-032: đóng dấu vào pixel và lưu tọa độ/thời gian kèm ảnh', () {
    final time = DateTime.utc(2026, 11, 7, 8, 15);
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 720, height: 420)),
    );
    final photo = EvidenceService().stamp(
      bytes,
      capturedAt: time,
      latitude: 0,
      longitude: 0,
    );
    final decoded = img.decodeJpg(photo.bytes)!;
    expect(decoded.width, 720);
    expect(decoded.height, 500);
    expect(photo.capturedAt, time);
    expect(photo.latitude, 0);
    expect(photo.longitude, 0);
    expect(photo.bytes, isNot(orderedEquals(bytes)));
    final restored = EvidencePhoto.fromJson(photo.toJson());
    expect(restored.bytes, orderedEquals(photo.bytes));
  });
  test(
    'US-033: thay ảnh không thêm ảnh trùng, không đổi dữ liệu đã lưu',
    () async {
      final service = EvidenceService();
      final draft = validDraft()..photos = [service.sample()];
      final store = RequestStore(save: (_) async {});
      final id = await store.saveDraft(draft);
      final edited = store.get(id).data;
      final replacement = service.sample();
      edited.photos[0] = replacement;
      expect(edited.photos.length, 1);
      expect(store.get(id).data.photos[0].id, isNot(replacement.id));
    },
  );
  test('US-034: thiếu GPS hoặc không ảnh thì yêu cầu cần xác minh, không chặn cứu trợ', () async {
    final time = DateTime.utc(2026, 11, 7);
    final p = EvidenceService().stamp(
      Uint8List.fromList(img.encodePng(img.Image(width: 100, height: 100))),
      capturedAt: time,
    );
    final draft = validDraft()..photos = [p];
    final flags = evidenceFlags(draft, time);
    expect(flags, contains('Ảnh thiếu tọa độ'));
    expect(draft.validate(), isEmpty);
    expect(evidenceFlags(validDraft(), time), contains('Chưa có ảnh xác minh'));
  });
  test(
    'US-035: phát hiện ảnh cũ/tương lai, không coi mẫu là giờ máy chủ thật',
    () {
      final time = DateTime.utc(2026, 11, 7);
      EvidencePhoto photo(DateTime t) => EvidencePhoto(
        id: 'p',
        base64: '',
        capturedAt: t,
        latitude: 20.8841,
        longitude: 105.6215,
      );
      for (final delta in [-20, 20]) {
        expect(
          evidenceFlags(
            validDraft()..photos = [photo(time.add(Duration(minutes: delta)))],
            time,
          ),
          contains(
            'Thời gian ảnh lệch quá 10 phút với thời điểm tiếp nhận mô phỏng',
          ),
        );
      }
      expect(
        evidenceFlags(validDraft()..photos = [photo(time)], time),
        isEmpty,
      );
    },
  );
  test('US-036: tương tự theo khoảng cách hoặc nội dung, không gồm yêu cầu đã kết thúc', () async {
    final store = RequestStore(save: (_) async {});
    final id = await store.submit(validDraft());
    expect(similarRequests(validDraft(), store.list()), hasLength(1));
    expect(
      similarRequests(
        validDraft()
          ..latitude = 10
          ..longitude = 100
          ..description = 'Nội dung khác hẳn',
        store.list(),
      ),
      isEmpty,
    );
    expect(
      similarRequests(
        validDraft()
          ..latitude = 10
          ..longitude = 100,
        store.list(),
      ),
      hasLength(1),
    );
    await store.cancel(id, confirmed: true);
    expect(similarRequests(validDraft(), store.list()), isEmpty);
  });
  test(
    'US-037: đánh dấu tự động và yêu cầu bổ sung đều có thông báo lưu bền',
    () async {
      final store = RequestStore(save: (_) async {});
      final id = await store.submit(validDraft());
      expect(
        store.get(id).notices.single['text'],
        contains('cần xác minh thêm'),
      );
      await store.review(
        id,
        Verification.needsInfo,
        'Bổ sung ảnh rõ hơn',
        role: DemoRole.admin,
      );
      expect(
        store.get(id).notices.last['text'],
        contains('Bổ sung ảnh rõ hơn'),
      );
      expect(store.get(id).verification, Verification.needsInfo);
    },
  );
  test(
    'US-038: báo cáo cần lý do, ngăn gửi trùng, chưa tự kết luận không hợp lệ',
    () async {
      final store = RequestStore(save: (_) async {});
      final id = await store.submit(validDraft());
      await expectLater(store.report(id, ' '), throwsA(isA<RequestError>()));
      await store.report(id, 'Thông tin địa điểm không khớp');
      expect(store.get(id).reports, hasLength(1));
      expect(store.get(id).verification, Verification.pending);
      await expectLater(
        store.report(id, 'Lần hai'),
        throwsA(isA<RequestError>()),
      );
    },
  );
  test(
    'US-039: quyền xem và snapshot không sửa được lịch sử trong kho',
    () async {
      final store = RequestStore(save: (_) async {});
      final id = await store.submit(validDraft());
      expect(() => store.get(id, actor: 'other'), throwsA(isA<RequestError>()));
      expect(store.get(id, role: DemoRole.admin).history, isNotEmpty);
      final snapshot = store.get(id);
      snapshot.history.clear();
      snapshot.flags.clear();
      expect(store.get(id).history, isNotEmpty);
      expect(store.get(id).flags, isNotEmpty);
    },
  );
  test(
    'US-040: chỉ admin, bắt buộc lý do, lưu quyết định và reset khi bổ sung',
    () async {
      final store = RequestStore(save: (_) async {});
      final id = await store.submit(validDraft());
      await expectLater(
        store.review(id, Verification.valid, '', role: DemoRole.citizen),
        throwsA(isA<RequestError>()),
      );
      await expectLater(
        store.review(id, Verification.invalid, ' ', role: DemoRole.admin),
        throwsA(isA<RequestError>()),
      );
      await store.review(
        id,
        Verification.needsInfo,
        'Cần xác minh vị trí',
        role: DemoRole.admin,
      );
      await store.submit(validDraft()..landmark = 'Nhà mái xanh', id: id);
      expect(store.get(id).verification, Verification.pending);
      expect(store.get(id).reason, isEmpty);
      await store.review(
        id,
        Verification.invalid,
        'Bằng chứng không hợp lệ',
        role: DemoRole.admin,
      );
      await expectLater(
        store.submit(validDraft(), id: id),
        throwsA(isA<RequestError>()),
      );
      expect(store.get(id).history.last['action'], contains('Không hợp lệ'));
    },
  );
}
