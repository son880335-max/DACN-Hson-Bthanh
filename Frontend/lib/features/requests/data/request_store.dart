import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'relief_request.dart';
import 'camera_checkpoint.dart';

typedef SaveRequests = Future<void> Function(String value);

/// Kho dữ liệu mẫu dùng chung. Vai trò ở đây chỉ phục vụ demo giao diện,
/// không thay thế kiểm tra quyền ở backend khi tích hợp hệ thống thật.
class RequestStore extends ChangeNotifier {
  static final instance = RequestStore();
  static const citizenId = 'demo-citizen';
  static const storageKey = 'relief_requests_sprint2_v1';
  List<ReliefRequest> _items = [];
  SaveRequests? save;
  CameraCheckpointStore? cameraRecovery;
  final DateTime Function() now;
  bool _busy = false;
  Future<void>? _loading;
  bool get isLoaded => save != null;
  RequestStore({this.save, DateTime Function()? clock})
    : now = clock ?? DateTime.now;

  Future<void> load() => _loading ??= _load().catchError((Object error) {
    _loading = null;
    throw error;
  });
  Future<void> _load() async {
    if (save != null) return;
    final prefs = await SharedPreferences.getInstance();
    cameraRecovery = CameraCheckpointStore(prefs);
    final stored = prefs.getString(storageKey);
    if (stored == null) {
      _items = seedRequests(now());
    } else {
      try {
        _items = (jsonDecode(stored) as List)
            .map((j) => ReliefRequest.fromJson(Map<String, dynamic>.from(j)))
            .toList();
      } catch (_) {
        throw const RequestError(
          'Không đọc được dữ liệu đã lưu. Dữ liệu vẫn được giữ nguyên; hãy thử lại.',
        );
      }
    }
    save = (value) async {
      if (!await prefs.setString(storageKey, value)) {
        throw const RequestError(
          'Không lưu được dữ liệu trên thiết bị. Hãy thử lại.',
        );
      }
    };
    notifyListeners();
  }

  List<ReliefRequest> list({
    DemoRole role = DemoRole.citizen,
    String actor = citizenId,
  }) =>
      _items
          .where(
            (r) => role == DemoRole.admin
                ? r.stage != RequestStage.draft
                : r.ownerId == actor,
          )
          .map((r) => r.copy())
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  ReliefRequest get(
    String id, {
    DemoRole role = DemoRole.citizen,
    String actor = citizenId,
  }) {
    final r = _find(_items, id);
    if (role != DemoRole.admin && r.ownerId != actor) {
      throw const RequestError('Bạn không có quyền xem yêu cầu này.');
    }
    return r.copy();
  }

  static ReliefRequest _find(List<ReliefRequest> items, String id) =>
      items.firstWhere(
        (r) => r.id == id,
        orElse: () => throw const RequestError('Không tìm thấy yêu cầu.'),
      );
  void _owner(ReliefRequest r, String actor) {
    if (r.ownerId != actor) {
      throw const RequestError('Bạn không có quyền thay đổi yêu cầu này.');
    }
  }

  void _version(ReliefRequest r, int? revision) {
    if (revision != null && revision != r.revision) {
      throw const RequestError(
        'Yêu cầu đã thay đổi. Hãy mở lại để xem dữ liệu mới nhất.',
      );
    }
  }

  void _event(ReliefRequest r, String actor, String action) {
    r.updatedAt = now().toUtc();
    r.revision++;
    r.history.add({
      'actor': actor,
      'action': action,
      'at': r.updatedAt.toIso8601String(),
    });
  }

  Future<T> _write<T>(T Function(List<ReliefRequest>) update) async {
    if (_busy) throw const RequestError('Đang lưu dữ liệu. Vui lòng chờ.');
    _busy = true;
    try {
      if (!isLoaded) await load();
      final next = _items.map((r) => r.copy()).toList();
      final result = update(next);
      await save!(jsonEncode(next.map((r) => r.toJson()).toList()));
      _items = next;
      notifyListeners();
      return result;
    } finally {
      _busy = false;
    }
  }

  Future<String> saveDraft(
    RequestDraft data, {
    String? id,
    int? revision,
    String actor = citizenId,
  }) => _write((items) {
    ReliefRequest r;
    if (id == null) {
      final stamp = now().toUtc();
      r = ReliefRequest(
        id: 'CR-${stamp.microsecondsSinceEpoch}',
        ownerId: actor,
        data: data.copy(),
        createdAt: stamp,
        updatedAt: stamp,
      );
      items.add(r);
    } else {
      r = _find(items, id);
      _owner(r, actor);
      _version(r, revision);
      if (r.stage != RequestStage.draft) {
        throw const RequestError('Chỉ lưu nháp cho yêu cầu chưa gửi.');
      }
      r.data = data.copy();
    }
    _event(r, actor, 'Lưu bản nháp');
    return r.id;
  });
  Future<String> submit(
    RequestDraft data, {
    String? id,
    int? revision,
    String actor = citizenId,
  }) => _write((items) {
    final errors = data.validate();
    if (errors.isNotEmpty) throw RequestError(errors.join('\n'));
    ReliefRequest r;
    if (id == null) {
      final stamp = now().toUtc();
      r = ReliefRequest(
        id: 'CR-${stamp.microsecondsSinceEpoch}',
        ownerId: actor,
        data: data.copy(),
        createdAt: stamp,
        updatedAt: stamp,
      );
      items.add(r);
    } else {
      r = _find(items, id);
      _owner(r, actor);
      _version(r, revision);
      if (!r.editable) {
        throw const RequestError(
          'Yêu cầu đã được tiếp nhận hoặc đã kết thúc, không thể sửa.',
        );
      }
      r.data = data.copy();
    }
    final wasDraft = r.stage == RequestStage.draft;
    if (wasDraft &&
        items.any(
          (other) =>
              other.id != r.id &&
              other.ownerId == actor &&
              (other.stage == RequestStage.accepted ||
                  (other.stage == RequestStage.waiting &&
                      other.verification != Verification.invalid)),
        )) {
      throw const RequestError(
        'Bạn đang có yêu cầu chưa hoàn tất. Hãy cập nhật yêu cầu hiện tại hoặc hủy yêu cầu chưa được tiếp nhận trước khi gửi mới.',
      );
    }
    r.stage = RequestStage.waiting;
    r.verification = Verification.pending;
    r.reason = '';
    r.submittedAt = now().toUtc();
    // Đây là đồng hồ mô phỏng tiếp nhận; không phải thời gian máy chủ thật.
    r.receivedAt = now().toUtc();
    r.flags = evidenceFlags(data, r.receivedAt!);
    if (r.reports.isNotEmpty) {
      r.flags.add('Có báo cáo nghi giả mạo');
    }
    final similar = similarRequests(data, items.where((x) => x.id != r.id));
    if (similar.isNotEmpty) {
      r.flags.add(
        'Nội dung hoặc vị trí tương tự: ${similar.map((x) => x.id).join(', ')}',
      );
    }
    _event(
      r,
      actor,
      wasDraft ? 'Gửi yêu cầu' : 'Cập nhật yêu cầu; chờ xác minh lại',
    );
    if (r.flags.isNotEmpty) {
      r.notices.add({
        'at': r.updatedAt.toIso8601String(),
        'text': 'Yêu cầu ${r.id} cần xác minh thêm: ${r.flags.join('; ')}',
      });
    }
    return r.id;
  });
  Future<void> cancel(
    String id, {
    required bool confirmed,
    int? revision,
    String actor = citizenId,
  }) => _write((items) {
    final r = _find(items, id);
    _owner(r, actor);
    _version(r, revision);
    if (!confirmed) {
      throw const RequestError('Cần xác nhận trước khi hủy yêu cầu.');
    }
    if (!r.cancellable) {
      throw const RequestError('Chỉ hủy yêu cầu chưa được đội tiếp nhận.');
    }
    r.stage = RequestStage.cancelled;
    _event(r, actor, 'Hủy yêu cầu sau khi xác nhận');
  });
  Future<void> review(
    String id,
    Verification decision,
    String reason, {
    required DemoRole role,
    int? revision,
  }) => _write((items) {
    if (role != DemoRole.admin) {
      throw const RequestError('Chỉ quản trị viên được xác minh yêu cầu.');
    }
    final r = _find(items, id);
    _version(r, revision);
    if (r.stage != RequestStage.waiting) {
      throw const RequestError('Chỉ xác minh yêu cầu đang chờ tiếp nhận.');
    }
    if (decision == Verification.pending) {
      throw const RequestError('Chọn kết quả xác minh.');
    }
    if (decision != Verification.valid && reason.trim().isEmpty) {
      throw const RequestError('Nhập lý do hoặc nội dung cần bổ sung.');
    }
    if (decision != Verification.invalid &&
        items.any(
          (other) =>
              other.id != r.id &&
              other.ownerId == r.ownerId &&
              (other.stage == RequestStage.accepted ||
                  (other.stage == RequestStage.waiting &&
                      other.verification != Verification.invalid)),
        )) {
      throw const RequestError(
        'Chủ yêu cầu đang có một yêu cầu khác chưa hoàn tất. Không thể khôi phục yêu cầu này về trạng thái đang hoạt động.',
      );
    }
    if (reason.length > 1000) {
      throw const RequestError('Lý do tối đa 1.000 ký tự.');
    }
    r.verification = decision;
    r.reason = reason.trim();
    _event(
      r,
      'demo-admin',
      'Xác minh: ${verificationLabel(decision)}. ${r.reason}',
    );
    r.notices.add({
      'at': r.updatedAt.toIso8601String(),
      'text':
          '${r.id}: ${verificationLabel(decision)}${r.reason.isEmpty ? '' : ' — ${r.reason}'}',
    });
  });
  Future<void> report(
    String id,
    String reason, {
    String actor = citizenId,
  }) => _write((items) {
    final r = _find(items, id);
    if (r.stage == RequestStage.draft) {
      throw const RequestError('Không báo cáo bản nháp.');
    }
    if (reason.trim().isEmpty || reason.length > 1000) {
      throw const RequestError('Nhập lý do báo cáo từ 1 đến 1.000 ký tự.');
    }
    if (r.reports.any((p) => p['actor'] == actor)) {
      throw const RequestError('Bạn đã báo cáo yêu cầu này.');
    }
    r.reports.add({
      'actor': actor,
      'reason': reason.trim(),
      'at': now().toUtc().toIso8601String(),
    });
    if (!r.flags.contains('Có báo cáo nghi giả mạo')) {
      r.flags.add('Có báo cáo nghi giả mạo');
    }
    _event(r, actor, 'Báo cáo dấu hiệu giả mạo');
    r.notices.add({
      'at': r.updatedAt.toIso8601String(),
      'text':
          '${r.id} được đánh dấu cần xác minh thêm. Báo cáo chưa phải kết luận giả mạo.',
    });
  });
  // Chỉ để kiểm thử điều kiện US-030; không thêm luồng điều phối ngoài sprint.
  Future<void> acceptForDemo(String id, {required DemoRole role}) =>
      _write((items) {
        if (role != DemoRole.rescue) {
          throw const RequestError('Chỉ đội cứu hộ được tiếp nhận.');
        }
        final r = _find(items, id);
        if (r.stage != RequestStage.waiting ||
            r.verification != Verification.valid) {
          throw const RequestError('Yêu cầu chưa đủ điều kiện tiếp nhận.');
        }
        r.stage = RequestStage.accepted;
        _event(r, 'demo-rescue', 'Đội cứu hộ tiếp nhận');
      });
}

class RequestError implements Exception {
  final String message;
  const RequestError(this.message);
  @override
  String toString() => message;
}

List<String> evidenceFlags(RequestDraft data, DateTime receivedAt) {
  final flags = <String>[];
  if (data.photos.isEmpty) flags.add('Chưa có ảnh xác minh');
  for (final p in data.photos) {
    if (p.recovered) {
      flags.add('Ảnh khôi phục: chưa xác định chính xác giờ và GPS lúc chụp');
    }
    if (p.demo) flags.add('Ảnh minh họa mẫu; chưa phải bằng chứng thực tế');
    if (!validCoordinates(p.latitude, p.longitude)) {
      flags.add('Ảnh thiếu tọa độ');
    }
    if (p.capturedAt.difference(receivedAt).inSeconds.abs() > 600) {
      flags.add(
        'Thời gian ảnh lệch quá 10 phút với thời điểm tiếp nhận mô phỏng',
      );
    }
    if (validCoordinates(p.latitude, p.longitude) &&
        validCoordinates(data.latitude, data.longitude) &&
        distanceMetres(
              p.latitude!,
              p.longitude!,
              data.latitude!,
              data.longitude!,
            ) >
            500) {
      flags.add('Vị trí ảnh cách vị trí yêu cầu hơn 500m');
    }
  }
  return flags.toSet().toList();
}

List<ReliefRequest> similarRequests(
  RequestDraft draft,
  Iterable<ReliefRequest> items,
) {
  final text = draft.description
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return items.where((r) {
    if (r.verification == Verification.invalid ||
        (r.stage != RequestStage.waiting && r.stage != RequestStage.accepted)) {
      return false;
    }
    final sameText =
        text.length >= 10 &&
        r.data.description
                .toLowerCase()
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim() ==
            text;
    final near =
        validCoordinates(draft.latitude, draft.longitude) &&
        validCoordinates(r.data.latitude, r.data.longitude) &&
        distanceMetres(
              draft.latitude!,
              draft.longitude!,
              r.data.latitude!,
              r.data.longitude!,
            ) <=
            100;
    return sameText ||
        similarContent(draft.description, r.data.description) ||
        near;
  }).toList();
}

bool similarContent(String a, String b) {
  Set<String> words(String s) => s
      .toLowerCase()
      .split(RegExp(r'[\s,.!?;:()/\-]+'))
      .where((w) => w.isNotEmpty)
      .toSet();
  final left = words(a), right = words(b);
  if (left.length < 4 || right.length < 4) {
    return false;
  }
  return left.intersection(right).length / left.union(right).length >= 0.65;
}

List<ReliefRequest> seedRequests(DateTime now) {
  ReliefRequest seed(
    String id,
    RequestStage stage,
    int people,
    String address,
    List<String> types,
  ) {
    final data = RequestDraft()
      ..types = types
      ..people = people
      ..elderly = 1
      ..children = 1
      ..description = 'Nước ngập ngang hiên nhà, thiếu đồ ăn và nước sạch.'
      ..urgency = 'Cao'
      ..address = address
      ..landmark = 'Nhà cấp 4 màu xanh gần đình làng'
      ..latitude = 20.8841
      ..longitude = 105.6215
      ..locationSource = 'Vị trí mẫu';
    return ReliefRequest(
      id: id,
      ownerId: RequestStore.citizenId,
      data: data,
      stage: stage,
      verification: Verification.valid,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
      submittedAt: now.toUtc(),
      receivedAt: now.toUtc(),
      history: [
        {
          'actor': 'Dữ liệu mẫu',
          'action': 'Yêu cầu mẫu ban đầu',
          'at': now.toUtc().toIso8601String(),
        },
      ],
    );
  }

  return [
    seed(
      'CR-0247',
      RequestStage.waiting,
      4,
      'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
      ['Sơ tán', 'Thực phẩm', 'Nước uống'],
    ),
    seed(
      'CR-0189',
      RequestStage.completed,
      2,
      'Thôn Nhân Lý, Nam Phương Tiến, Chương Mỹ',
      ['Nước uống', 'Thực phẩm'],
    ),
    seed(
      'CR-0102',
      RequestStage.completed,
      3,
      'Xã Tân Tiến, Chương Mỹ, Hà Nội',
      ['Thuốc men'],
    ),
    seed(
        'DRAFT-0001',
        RequestStage.draft,
        4,
        'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
        ['Sơ tán'],
      )
      ..verification = Verification.pending
      ..submittedAt = null
      ..receivedAt = null,
    seed(
        'CR-0251',
        RequestStage.waiting,
        2,
        'Thôn Nhân Lý, Xã Nam Phương Tiến',
        ['Cứu hộ', 'Thuốc men'],
      )
      ..ownerId = 'demo-mai'
      ..data.contactName = 'Hoàng Thị Mai'
      ..data.contactPhone = '0988776554'
      ..data.description = 'Sản phụ chuyển dạ cần ca nô hỗ trợ y tế'
      ..data.urgency = 'Khẩn cấp'
      ..data.latitude = 20.89,
    seed(
        'CR-0238',
        RequestStage.accepted,
        6,
        'Khu gò đồi, Xã Tân Tiến, Chương Mỹ',
        ['Nước uống', 'Thực phẩm'],
      )
      ..ownerId = 'demo-bao'
      ..data.contactName = 'Đặng Quốc Bảo'
      ..data.contactPhone = '0903221445',
    seed(
        'CR-0199',
        RequestStage.completed,
        3,
        'Khu tập thể ven sông, Chương Mỹ',
        ['Sơ tán'],
      )
      ..ownerId = 'demo-hang'
      ..data.contactName = 'Phạm Thu Hằng'
      ..data.contactPhone = '0977443219',
  ];
}
