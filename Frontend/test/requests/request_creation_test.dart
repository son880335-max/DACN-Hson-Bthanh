import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flood_relief_app/features/requests/data/relief_request.dart';
import 'package:flood_relief_app/features/requests/data/request_store.dart';

RequestDraft validDraft() => RequestDraft()
  ..types = ['Sơ tán']
  ..people = 4
  ..urgency = 'Khẩn cấp'
  ..description = 'Gia đình mắc kẹt trên mái nhà'
  ..latitude = 20.8841
  ..longitude = 105.6215
  ..address = 'Thôn Nam Hài';

void main() {
  test(
    'US-021: gửi hợp lệ lưu một yêu cầu và lịch sử; lỗi không tạo dữ liệu',
    () async {
      String? saved;
      final store = RequestStore(
        save: (s) async {
          saved = s;
        },
      );
      await expectLater(
        store.submit(RequestDraft()),
        throwsA(isA<RequestError>()),
      );
      expect(store.list(), isEmpty);
      final id = await store.submit(validDraft());
      expect(store.get(id).stage, RequestStage.waiting);
      expect(store.get(id).history.single['action'], 'Gửi yêu cầu');
      expect((jsonDecode(saved!) as List).length, 1);
    },
  );
  test('US-022: phải chọn loại hỗ trợ hợp lệ', () {
    expect((validDraft()..types = []).validate(), isNotEmpty);
    expect((validDraft()..types = ['khác']).validate(), isNotEmpty);
    expect((validDraft()..types = reliefTypes.toList()).validate(), isEmpty);
  });
  test('US-023: số người phải dương và có giới hạn', () {
    expect((validDraft()..people = 0).validate(), isNotEmpty);
    expect((validDraft()..people = -1).validate(), isNotEmpty);
    expect((validDraft()..people = 10001).validate(), isNotEmpty);
    expect((validDraft()..people = 1).validate(), isEmpty);
  });
  test('US-024: nhóm ưu tiên không vượt tổng, cho phép giao nhóm', () {
    expect((validDraft()..elderly = 5).validate(), isNotEmpty);
    expect((validDraft()..special = 1).validate(), isNotEmpty);
    expect(
      (validDraft()
            ..elderly = 4
            ..disabled = 4
            ..special = 1
            ..specialNotes = 'Cần hỗ trợ thở')
          .validate(),
      isEmpty,
    );
  });
  test('US-025: phải có mô tả và mức khẩn cấp đầy đủ', () {
    expect((validDraft()..description = ' ').validate(), isNotEmpty);
    expect((validDraft()..urgency = 'Khẩn').validate(), isNotEmpty);
    for (final urgency in urgencyLevels) {
      expect((validDraft()..urgency = urgency).validate(), isEmpty);
    }
  });
  test(
    'US-021: lỗi lưu không báo thành công hoặc làm thay đổi dữ liệu',
    () async {
      final store = RequestStore(
        save: (_) async => throw Exception('disk full'),
      );
      await expectLater(store.submit(validDraft()), throwsException);
      expect(store.list(), isEmpty);
    },
  );
}
