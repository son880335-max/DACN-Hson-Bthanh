import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const reliefTypes = ['Sơ tán', 'Thực phẩm', 'Nước uống', 'Thuốc men', 'Cứu hộ'];
const urgencyLevels = ['Khẩn cấp', 'Cao', 'Trung bình'];

enum Verification { pending, valid, needsInfo, invalid }

enum RequestStage { draft, waiting, accepted, completed, cancelled }

enum DemoRole { citizen, admin, rescue }

String verificationLabel(Verification v) => switch (v) {
  Verification.pending => 'Chờ xác minh',
  Verification.valid => 'Hợp lệ',
  Verification.needsInfo => 'Cần bổ sung',
  Verification.invalid => 'Không hợp lệ',
};
String stageLabel(RequestStage v) => switch (v) {
  RequestStage.draft => 'Bản nháp',
  RequestStage.waiting => 'Chờ tiếp nhận',
  RequestStage.accepted => 'Đã tiếp nhận',
  RequestStage.completed => 'Đã hoàn thành',
  RequestStage.cancelled => 'Đã hủy',
};

class EvidencePhoto {
  final String id;
  final String base64;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final bool demo;
  final bool recovered;
  const EvidencePhoto({
    required this.id,
    required this.base64,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.demo = false,
    this.recovered = false,
  });
  Uint8List get bytes => base64Decode(base64);
  Map<String, dynamic> toJson() => {
    'id': id,
    'base64': base64,
    'capturedAt': capturedAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'demo': demo,
    'recovered': recovered,
  };
  factory EvidencePhoto.fromJson(Map<String, dynamic> j) => EvidencePhoto(
    id: j['id'],
    base64: j['base64'],
    capturedAt: DateTime.parse(j['capturedAt']),
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    demo: j['demo'] == true,
    recovered: j['recovered'] == true,
  );
}

class RequestDraft {
  String recipient = 'self';
  String contactName = '';
  String contactPhone = '';
  List<String> types = [];
  int people = 1, elderly = 0, children = 0, disabled = 0, special = 0;
  String specialNotes = '',
      description = '',
      urgency = '',
      address = '',
      landmark = '';
  double? latitude, longitude, accuracy;
  String locationSource = '';
  List<EvidencePhoto> photos = [];

  List<String> validate({int throughStep = 4}) {
    final errors = <String>[];
    if (!['self', 'other'].contains(recipient)) {
      errors.add('Đối tượng hỗ trợ không hợp lệ.');
    }
    if (types.isEmpty || types.any((t) => !reliefTypes.contains(t))) {
      errors.add('Chọn ít nhất một loại hỗ trợ hợp lệ.');
    }
    if (people < 1 || people > 10000) {
      errors.add('Tổng số người phải từ 1 đến 10.000.');
    }
    if (elderly + children > people) {
      errors.add(
        'Tổng số người cao tuổi và trẻ em không được vượt tổng số người.',
      );
    }
    // Các nhóm có thể trùng nhau: một người có thể vừa cao tuổi vừa khuyết tật.
    if ([
      elderly,
      children,
      disabled,
      special,
    ].any((n) => n < 0 || n > people)) {
      errors.add('Số người mỗi nhóm ưu tiên phải từ 0 đến tổng số người.');
    }
    if (special > 0 && specialNotes.trim().isEmpty) {
      errors.add('Mô tả nhu cầu chăm sóc đặc biệt.');
    }
    if (specialNotes.length > 1000 || contactName.length > 100) {
      errors.add('Nội dung chăm sóc tối đa 1.000 ký tự; tên tối đa 100 ký tự.');
    }
    if (!urgencyLevels.contains(urgency)) errors.add('Chọn mức độ khẩn cấp.');
    if (description.trim().isEmpty || description.length > 2000) {
      errors.add('Mô tả tình trạng từ 1 đến 2.000 ký tự.');
    }
    if (recipient == 'other') {
      if (contactName.trim().isEmpty) errors.add('Nhập tên người cần hỗ trợ.');
      if (!RegExp(r'^0[35789]\d{8}$').hasMatch(contactPhone.trim())) {
        errors.add('Số điện thoại liên hệ không hợp lệ.');
      }
    }
    if (throughStep >= 2) {
      if (!validCoordinates(latitude, longitude)) {
        errors.add('Chọn vị trí hợp lệ trên bản đồ hoặc dùng GPS.');
      }
      if (address.trim().isEmpty && landmark.trim().isEmpty) {
        errors.add('Nhập địa chỉ hoặc hướng dẫn nhận diện địa điểm.');
      }
      if (address.length > 500 || landmark.length > 1000) {
        errors.add('Địa chỉ tối đa 500 ký tự; hướng dẫn tối đa 1.000 ký tự.');
      }
    }
    if (throughStep >= 3 && photos.length > 5) {
      errors.add('Mỗi yêu cầu tối đa 5 ảnh.');
    }
    if (throughStep >= 3) {
      for (final photo in photos) {
        try {
          final bytes = photo.bytes;
          if (bytes.length < 4 ||
              bytes.length > 1024 * 1024 ||
              bytes[0] != 0xff ||
              bytes[1] != 0xd8 ||
              img.decodeJpg(bytes) == null) {
            errors.add('Ảnh bị lỗi hoặc vượt quá 1 MB. Hãy chụp lại.');
          }
        } catch (_) {
          errors.add('Không đọc được dữ liệu ảnh. Hãy chụp lại.');
        }
      }
    }
    return errors;
  }

  Map<String, dynamic> toJson() => {
    'recipient': recipient,
    'contactName': contactName,
    'contactPhone': contactPhone,
    'types': types,
    'people': people,
    'elderly': elderly,
    'children': children,
    'disabled': disabled,
    'special': special,
    'specialNotes': specialNotes,
    'description': description,
    'urgency': urgency,
    'address': address,
    'landmark': landmark,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'locationSource': locationSource,
    'photos': photos.map((p) => p.toJson()).toList(),
  };
  factory RequestDraft.fromJson(Map<String, dynamic> j) => RequestDraft()
    ..recipient = j['recipient'] ?? 'self'
    ..contactName = j['contactName'] ?? ''
    ..contactPhone = j['contactPhone'] ?? ''
    ..types = List<String>.from(j['types'] ?? [])
    ..people = j['people'] ?? 1
    ..elderly = j['elderly'] ?? 0
    ..children = j['children'] ?? 0
    ..disabled = j['disabled'] ?? 0
    ..special = j['special'] ?? 0
    ..specialNotes = j['specialNotes'] ?? ''
    ..description = j['description'] ?? ''
    ..urgency = j['urgency'] ?? ''
    ..address = j['address'] ?? ''
    ..landmark = j['landmark'] ?? ''
    ..latitude = (j['latitude'] as num?)?.toDouble()
    ..longitude = (j['longitude'] as num?)?.toDouble()
    ..accuracy = (j['accuracy'] as num?)?.toDouble()
    ..locationSource = j['locationSource'] ?? ''
    ..photos = (j['photos'] as List? ?? [])
        .map((p) => EvidencePhoto.fromJson(Map<String, dynamic>.from(p)))
        .toList();
  RequestDraft copy() =>
      RequestDraft.fromJson(jsonDecode(jsonEncode(toJson())));
  RequestDraft();
}

bool validCoordinates(double? lat, double? lon) =>
    lat != null &&
    lon != null &&
    lat.isFinite &&
    lon.isFinite &&
    lat >= -90 &&
    lat <= 90 &&
    lon >= -180 &&
    lon <= 180;

double distanceMetres(double lat1, double lon1, double lat2, double lon2) {
  double rad(double n) => n * math.pi / 180;
  final a =
      math.pow(math.sin(rad(lat2 - lat1) / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(rad(lon2 - lon1) / 2), 2);
  return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
}

class ReliefRequest {
  String id, ownerId;
  RequestDraft data;
  RequestStage stage;
  Verification verification;
  DateTime createdAt, updatedAt;
  DateTime? submittedAt, receivedAt;
  String reason;
  int revision;
  List<String> flags;
  List<Map<String, dynamic>> history, reports, notices;
  ReliefRequest({
    required this.id,
    required this.ownerId,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.stage = RequestStage.draft,
    this.verification = Verification.pending,
    this.submittedAt,
    this.receivedAt,
    this.reason = '',
    this.revision = 0,
    List<String>? flags,
    List<Map<String, dynamic>>? history,
    List<Map<String, dynamic>>? reports,
    List<Map<String, dynamic>>? notices,
  }) : flags = flags ?? [],
       history = history ?? [],
       reports = reports ?? [],
       notices = notices ?? [];
  bool get editable =>
      stage == RequestStage.draft ||
      (stage == RequestStage.waiting && verification != Verification.invalid);
  bool get cancellable => stage == RequestStage.waiting;
  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'data': data.toJson(),
    'stage': stage.name,
    'verification': verification.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
    'receivedAt': receivedAt?.toIso8601String(),
    'reason': reason,
    'revision': revision,
    'flags': flags,
    'history': history,
    'reports': reports,
    'notices': notices,
  };
  factory ReliefRequest.fromJson(Map<String, dynamic> j) => ReliefRequest(
    id: j['id'],
    ownerId: j['ownerId'],
    data: RequestDraft.fromJson(Map<String, dynamic>.from(j['data'])),
    stage: RequestStage.values.byName(j['stage']),
    verification: Verification.values.byName(j['verification']),
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
    submittedAt: DateTime.tryParse(j['submittedAt'] ?? ''),
    receivedAt: DateTime.tryParse(j['receivedAt'] ?? ''),
    reason: j['reason'] ?? '',
    revision: j['revision'] ?? 0,
    flags: List<String>.from(j['flags'] ?? []),
    history: (j['history'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
    reports: (j['reports'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
    notices: (j['notices'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
  );
  ReliefRequest copy() =>
      ReliefRequest.fromJson(jsonDecode(jsonEncode(toJson())));
}
