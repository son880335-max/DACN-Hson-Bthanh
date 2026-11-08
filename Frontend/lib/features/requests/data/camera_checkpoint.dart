import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'relief_request.dart';

/// Lưu riêng phiên camera; không ghi đè nội dung yêu cầu đã gửi.
class CameraCheckpoint {
  final RequestDraft data;
  final String? requestId;
  final int? revision, replaceIndex;
  final DateTime startedAt;
  CameraCheckpoint({
    required this.data,
    required this.startedAt,
    this.requestId,
    this.revision,
    this.replaceIndex,
  });
  Map<String, dynamic> toJson() => {
    'data': data.toJson(),
    'requestId': requestId,
    'revision': revision,
    'replaceIndex': replaceIndex,
    'startedAt': startedAt.toIso8601String(),
  };
  factory CameraCheckpoint.fromJson(Map<String, dynamic> j) => CameraCheckpoint(
    data: RequestDraft.fromJson(Map<String, dynamic>.from(j['data'])),
    startedAt: DateTime.parse(j['startedAt']),
    requestId: j['requestId'],
    revision: j['revision'],
    replaceIndex: j['replaceIndex'],
  );
}

class CameraCheckpointStore {
  static const key = 'relief_camera_checkpoint_v1';
  final SharedPreferences preferences;
  CameraCheckpointStore(this.preferences);
  CameraCheckpoint? read() {
    final raw = preferences.getString(key);
    return raw == null
        ? null
        : CameraCheckpoint.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<void> write(CameraCheckpoint checkpoint) async {
    if (!await preferences.setString(key, jsonEncode(checkpoint.toJson()))) {
      throw Exception(
        'Không lưu được biểu mẫu trước khi mở camera. Hãy thử lại.',
      );
    }
  }

  Future<void> clear() async {
    if (!await preferences.remove(key)) {
      throw Exception('Không xóa được phiên camera đã xử lý.');
    }
  }
}
