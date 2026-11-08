import 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;
const operationUuid = Uuid();

class RequestDraft {
  RequestDraft({
    Json? values,
    this.requestId,
    this.revision,
    List<Json>? photos,
  }) : values =
           values ??
           {
             'types': <String>[],
             'people': 1,
             'elderly': 0,
             'children': 0,
             'disabled': 0,
             'special': 0,
             'specialNotes': '',
             'description': '',
             'urgency': 'Cao',
             'address': '',
             'landmark': '',
             'evidenceIds': <String>[],
           },
       photos = photos ?? [];
  final Json values;
  final List<Json> photos;
  final String? requestId;
  final int? revision;
  Json toJson() => {
    'values': values,
    'photos': photos,
    'requestId': requestId,
    'revision': revision,
  };
  factory RequestDraft.fromJson(Json json) => RequestDraft(
    values: Map<String, dynamic>.from(json['values']),
    requestId: json['requestId'],
    revision: json['revision'],
    photos: (json['photos'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
  );
  factory RequestDraft.fromRequest(Json request) => RequestDraft(
    values: Map<String, dynamic>.from(request['data']),
    requestId: request['id'],
    revision: request['revision'],
  );
  String? validate({bool location = true}) {
    const types = ['Sơ tán', 'Thực phẩm', 'Nước uống', 'Thuốc men', 'Cứu hộ'];
    final selected = values['types'];
    if (selected is! List || selected.isEmpty) {
      return 'Chọn ít nhất một loại hỗ trợ.';
    }
    if (selected.any((v) => !types.contains(v)) ||
        selected.toSet().length != selected.length) {
      return 'Chọn loại hỗ trợ trong danh sách, không chọn trùng.';
    }
    final people = values['people'];
    if (people is! int || people < 1 || people > 2147483647) {
      return 'Nhập số người cần hỗ trợ bằng số nguyên dương.';
    }
    for (final key in ['elderly', 'children', 'disabled', 'special']) {
      final count = values[key];
      if (count is! int || count < 0 || count > people) {
        return 'Số người trong mỗi nhóm phải từ 0 đến tổng số người cần hỗ trợ.';
      }
    }
    final description = values['description'];
    if (description is! String ||
        description.trim().isEmpty ||
        description.trim().length > 4000) {
      return 'Nhập mô tả tình trạng, tối đa 4000 ký tự.';
    }
    if (!['Khẩn cấp', 'Cao', 'Trung bình'].contains(values['urgency'])) {
      return 'Chọn mức độ khẩn cấp trong danh sách.';
    }
    for (final entry in {
      'specialNotes': 2000,
      'address': 1000,
      'landmark': 2000,
    }.entries) {
      final value = values[entry.key];
      if (value is! String || value.trim().length > entry.value) {
        return 'Thông tin nhập quá dài. Hãy rút gọn trước khi tiếp tục.';
      }
    }
    if (location) {
      if (values['latitude'] is! num ||
          values['longitude'] is! num ||
          values['locationConfirmedAt'] == null) {
        return 'Lấy GPS hoặc ghim và xác nhận vị trí trước khi gửi.';
      }
      if (!(values['latitude'] as num).isFinite ||
          !(values['longitude'] as num).isFinite ||
          values['latitude'] < -90 ||
          values['latitude'] > 90 ||
          values['longitude'] < -180 ||
          values['longitude'] > 180) {
        return 'Tọa độ chưa hợp lệ.';
      }
      if (!['gps', 'pin'].contains(values['locationSource']) ||
          DateTime.tryParse(values['locationConfirmedAt'].toString()) == null) {
        return 'Xác nhận lại vị trí trước khi tiếp tục.';
      }
      if ((values['address'] as String).trim().isEmpty &&
          (values['landmark'] as String).trim().isEmpty) {
        return 'Nhập địa chỉ hoặc hướng dẫn nhận diện địa điểm.';
      }
    }
    return null;
  }
}
