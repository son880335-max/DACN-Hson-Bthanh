import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flood_relief_app/features/requests/data/relief_request.dart';
import 'package:flood_relief_app/features/requests/data/request_store.dart';

import 'request_creation_test.dart' show validDraft;

void main() {
  test('Giữ quy tắc mẫu: chỉ một yêu cầu đang hoạt động; gửi lại nháp không tạo bản trùng', () async {
    final store = RequestStore(save: (_) async {});
    final active = await store.submit(validDraft());
    final draft = await store.saveDraft(validDraft());
    await expectLater(
      store.submit(validDraft(), id: draft),
      throwsA(isA<RequestError>()),
    );
    expect(store.get(draft).stage, RequestStage.draft);
    await store.cancel(active, confirmed: true);
    final submitted = await store.submit(validDraft(), id: draft);
    expect(submitted, draft);
    expect(store.list().where((r) => r.id == draft), hasLength(1));
  });
  test('US-026: tọa độ hợp lệ, biên, thiếu, NaN và ngoài miền', () {
    expect(
      (validDraft()
            ..latitude = 0
            ..longitude = 0)
          .validate(),
      isEmpty,
    );
    expect(
      (validDraft()
            ..latitude = -90
            ..longitude = 180)
          .validate(),
      isEmpty,
    );
    expect((validDraft()..latitude = null).validate(), isNotEmpty);
    expect((validDraft()..latitude = double.nan).validate(), isNotEmpty);
    expect((validDraft()..latitude = 91).validate(), isNotEmpty);
    expect((validDraft()..longitude = -181).validate(), isNotEmpty);
  });
  test('US-027: cần địa chỉ hoặc chỉ dẫn, không chấp nhận cả hai trống', () {
    expect(
      (validDraft()
            ..address = ' '
            ..landmark = ' ')
          .validate(),
      isNotEmpty,
    );
    expect(
      (validDraft()
            ..address = ''
            ..landmark = 'Gần đình làng, nhà mái xanh')
          .validate(),
      isEmpty,
    );
  });
  test('US-028: lưu nháp thiếu dữ liệu, mở lại sau khởi tạo kho mới', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RequestStore();
    await store.load();
    final partial = RequestDraft()
      ..special = 2
      ..specialNotes = 'Cần máy thở'
      ..description = 'Đang soạn';
    final id = await store.saveDraft(partial);
    final reloaded = RequestStore();
    await reloaded.load();
    expect(reloaded.get(id).stage, RequestStage.draft);
    expect(reloaded.get(id).data.specialNotes, 'Cần máy thở');
    expect(reloaded.get(id).data.types, isEmpty);
  });
  test(
    'US-029: snapshot xem lại giữ đủ dữ liệu, sửa form không đổi bản đã lưu',
    () async {
      String? raw;
      final store = RequestStore(
        save: (v) async {
          raw = v;
        },
      );
      final data = validDraft()
        ..elderly = 1
        ..children = 1
        ..disabled = 1
        ..special = 1
        ..specialNotes = 'Chăm sóc riêng';
      final id = await store.saveDraft(data);
      data.description = 'Sửa ngoài kho';
      final copied = ReliefRequest.fromJson(
        Map<String, dynamic>.from((jsonDecode(raw!) as List).single),
      );
      expect(copied.data.specialNotes, 'Chăm sóc riêng');
      expect(copied.data.elderly, 1);
      expect(copied.data.children, 1);
      expect(copied.data.disabled, 1);
      expect(store.get(id).data.description, isNot('Sửa ngoài kho'));
    },
  );
  test(
    'US-030: sửa chỉ trước tiếp nhận, không đổi chủ, chống ghi đè phiên cũ',
    () async {
      final store = RequestStore(save: (_) async {});
      final id = await store.submit(validDraft());
      final before = store.get(id);
      await expectLater(
        store.submit(validDraft(), id: id, actor: 'other'),
        throwsA(isA<RequestError>()),
      );
      await store.submit(
        validDraft()..people = 5,
        id: id,
        revision: before.revision,
      );
      await expectLater(
        store.submit(validDraft(), id: id, revision: before.revision),
        throwsA(isA<RequestError>()),
      );
      await store.review(id, Verification.valid, '', role: DemoRole.admin);
      await store.acceptForDemo(id, role: DemoRole.rescue);
      await expectLater(
        store.submit(validDraft(), id: id),
        throwsA(isA<RequestError>()),
      );
      await expectLater(
        store.cancel(id, confirmed: true),
        throwsA(isA<RequestError>()),
      );
    },
  );
  test('US-103: phải xác nhận, hủy xong không hủy lần nữa', () async {
    final store = RequestStore(save: (_) async {});
    final id = await store.submit(validDraft());
    await expectLater(
      store.cancel(id, confirmed: false),
      throwsA(isA<RequestError>()),
    );
    expect(store.get(id).stage, RequestStage.waiting);
    await store.cancel(id, confirmed: true);
    expect(store.get(id).stage, RequestStage.cancelled);
    await expectLater(
      store.cancel(id, confirmed: true),
      throwsA(isA<RequestError>()),
    );
  });
}
