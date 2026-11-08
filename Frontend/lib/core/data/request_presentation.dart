import '../widgets/status_chip.dart';
import 'request_draft.dart';

ReliefStatus stageStatus(String stage) => switch (stage) {
  'accepted' => ReliefStatus.assigned,
  'completed' => ReliefStatus.completed,
  'cancelled' => ReliefStatus.cancelled,
  _ => ReliefStatus.waiting,
};
Json requestCard(Json request) => {
  ...request,
  'title': (request['types'] as List? ?? []).join(', '),
  'needs': (request['types'] as List? ?? []).join(', '),
  'citizen': request['contact']?['name'] ?? '',
  'phone': request['contact']?['phone'] ?? '',
  'time': formatTimestamp(request['createdAt']),
  'isUrgent': request['urgency'] == 'Khẩn cấp',
  'status': stageStatus(request['stage']),
  'distance': '',
  'tools': '',
};
String shortRequestId(String id) => id.length > 12 ? id.substring(0, 8) : id;
String formatTimestamp(String? value, {bool seconds = false}) {
  final time = DateTime.tryParse(value ?? '')?.toLocal();
  if (time == null) return 'Chưa có dữ liệu';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}${seconds ? ':${two(time.second)}' : ''} ${two(time.day)}/${two(time.month)}/${time.year}';
}

String requestFieldLabel(String field) =>
    const {
      'types': 'Loại hỗ trợ',
      'people': 'Số người',
      'elderly': 'Người cao tuổi',
      'children': 'Trẻ em',
      'disabled': 'Người khuyết tật',
      'special': 'Người cần chăm sóc đặc biệt',
      'specialNotes': 'Nội dung chăm sóc',
      'description': 'Mô tả tình trạng',
      'urgency': 'Mức độ khẩn cấp',
      'address': 'Địa chỉ',
      'landmark': 'Mốc nhận diện',
      'latitude': 'Vĩ độ',
      'longitude': 'Kinh độ',
      'locationSource': 'Cách xác định vị trí',
      'locationConfirmedAt': 'Thời điểm xác nhận vị trí',
      'clientActionAt': 'Thời điểm gửi',
      'evidenceIds': 'Ảnh đính kèm',
    }[field] ??
    'Thông tin khác';
