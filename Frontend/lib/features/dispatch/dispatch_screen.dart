import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/data/api_client.dart';
import '../../core/data/relief_repository.dart';
import '../../core/data/request_draft.dart';
import '../../core/widgets/notices_dialog.dart';
import '../citizen/screens/c02_request_wizard_step1_screen.dart';
import '../citizen/screens/c08_request_detail_waiting_screen.dart';

const statuses = {
  'waiting': 'Chờ tiếp nhận',
  'accepted': 'Đã tiếp nhận',
  'travelling': 'Đang di chuyển',
  'arrived': 'Đã đến nơi',
  'completed': 'Đã hoàn thành',
  'cancelled': 'Đã hủy',
  'invalid': 'Không hợp lệ',
};

class DispatchScreen extends StatefulWidget {
  const DispatchScreen(this.mode, {super.key});
  final String mode;

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  final search = TextEditingController();
  final items = <Json>[];
  String? cursor, error, status, type, urgency;
  String appliedSearch = '';
  Position? position;
  double? radius;
  bool loading = false, locating = false;
  int generation = 0;
  Timer? timer;

  bool get waiting => widget.mode == 'waiting';
  bool get admin => widget.mode == 'admin';
  bool get citizen => widget.mode == 'mine';

  @override
  void initState() {
    super.initState();
    unawaited(load());
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!loading &&
          items.length <= 30 &&
          mounted &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        unawaited(load(quiet: true));
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false, bool quiet = false}) async {
    if (more && (loading || cursor == null)) return;
    final stamp = ++generation;
    if (!quiet) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    final params = <String, String>{
      'mode': widget.mode,
      if (more) 'before': cursor!,
      if (admin && appliedSearch.isNotEmpty) 'search': appliedSearch,
      if (status != null) 'status': status!,
      if (type != null) 'type': type!,
      if (urgency != null) 'urgency': urgency!,
      if (position != null) 'lat': '${position!.latitude}',
      if (position != null) 'lon': '${position!.longitude}',
      if (radius != null) 'km': '$radius',
    };
    try {
      final result = await reliefRepository.api.json(
        'GET',
        '/dispatch?${Uri(queryParameters: params).query}',
      );
      if (!mounted || stamp != generation) return;
      setState(() {
        if (!more) items.clear();
        items.addAll((result['items'] as List).cast<Json>());
        cursor = result['nextCursor'] as String?;
        error = null;
      });
    } catch (exception) {
      if (mounted && stamp == generation) {
        setState(() {
          if (exception is ApiFailure &&
              [401, 403].contains(exception.status)) {
            items.clear();
            cursor = null;
          }
          error = exception is ApiFailure
              ? exception.message
              : 'Không tải được danh sách.';
        });
      }
    } finally {
      if (mounted && stamp == generation) setState(() => loading = false);
    }
  }

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const ApiFailure(
          0,
          'LOCATION_OFF',
          'Hãy bật dịch vụ vị trí để lọc khoảng cách.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw const ApiFailure(
          0,
          'LOCATION_DENIED',
          'Chưa có quyền vị trí. Bạn vẫn có thể lọc theo nhu cầu.',
        );
      }
      final value = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() => position = value);
      await load();
    } catch (exception) {
      if (mounted) {
        message(
          context,
          exception is ApiFailure
              ? exception.message
              : 'Chưa lấy được vị trí. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> open(Json item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DispatchDetail(item: item, mode: widget.mode),
      ),
    );
    if (mounted) await load();
  }

  Widget filter(
    String label,
    String? value,
    Iterable<String> values,
    ValueChanged<String?> change, {
    Map<String, String> labels = const {},
  }) => DropdownButtonFormField<String>(
    initialValue: value ?? '',
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      const DropdownMenuItem(value: '', child: Text('Tất cả')),
      for (final option in values)
        DropdownMenuItem(value: option, child: Text(labels[option] ?? option)),
    ],
    onChanged: (value) {
      setState(() => change(value == '' ? null : value));
      unawaited(load());
    },
  );

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      'mine' => 'Yêu cầu của tôi',
      'admin' => 'Điều phối yêu cầu',
      'waiting' => 'Nhiệm vụ chờ nhận',
      _ => 'Nhiệm vụ đã nhận',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: citizen,
        actions: [
          if (citizen || admin)
            IconButton(
              tooltip: 'Thông báo',
              onPressed: () => showNotices(context),
              icon: const Icon(Icons.notifications_outlined),
            ),
          if (citizen)
            IconButton(
              tooltip: 'Hướng dẫn cứu trợ',
              onPressed: () => showDispatchGuide(context),
              icon: const Icon(Icons.help_outline),
            ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: loading ? null : () => load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (citizen) ...[
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const C02RequestWizardStep1Screen(),
                    ),
                  );
                  if (mounted) await load();
                },
                icon: const Icon(Icons.add),
                label: const Text('Soạn yêu cầu cứu trợ'),
              ),
              const SizedBox(height: 12),
              const Text('Lịch sử yêu cầu đã gửi'),
            ],
            if (admin)
              TextField(
                controller: search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Mã yêu cầu hoặc khu vực',
                  suffixIcon: IconButton(
                    tooltip: 'Tìm kiếm',
                    icon: const Icon(Icons.search),
                    onPressed: applySearch,
                  ),
                ),
                onSubmitted: (_) => applySearch(),
              ),
            if (admin || citizen)
              filter(
                'Trạng thái',
                status,
                statuses.keys,
                (value) => status = value,
                labels: statuses,
              ),
            if (waiting) ...[
              filter('Loại hỗ trợ', type, [
                'Sơ tán',
                'Thực phẩm',
                'Nước uống',
                'Thuốc men',
                'Cứu hộ',
              ], (value) => type = value),
              filter('Mức khẩn cấp', urgency, [
                'Khẩn cấp',
                'Cao',
                'Trung bình',
              ], (value) => urgency = value),
              if (position != null)
                filter('Phạm vi (km)', radius?.toInt().toString(), [
                  '1',
                  '3',
                  '5',
                  '10',
                  '20',
                  '50',
                ], (value) => radius = double.tryParse(value ?? '')),
              OutlinedButton.icon(
                onPressed: locating ? null : locate,
                icon: const Icon(Icons.my_location),
                label: Text(
                  locating
                      ? 'Đang lấy vị trí…'
                      : position == null
                      ? 'Bật lọc khoảng cách'
                      : 'Cập nhật vị trí đội',
                ),
              ),
            ],
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!loading && error == null && items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Không có yêu cầu phù hợp.'),
              ),
            for (final item in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${item['urgency']} · ${item['people']} người',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text((item['types'] as List).join(', ')),
                      if (!waiting)
                        Text(statuses[item['status']] ?? 'Chưa rõ trạng thái'),
                      if (item['linked'] == true)
                        const Text('Theo dõi qua đơn chính'),
                      if (item['region'] case final String region
                          when region.isNotEmpty)
                        Text(region),
                      if (item['teamName'] case final String team)
                        Text('Đội phụ trách: $team'),
                      if (waiting && item['distanceKm'] != null)
                        Text('Khoảng ${item['distanceKm']} km'),
                      Text(
                        'Mã: ${item['id']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: dispatchOutline,
                        onPressed: () => open(item),
                        child: Text(
                          waiting ? 'Xem và nhận nhiệm vụ' : 'Xem chi tiết',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (cursor != null)
              OutlinedButton(
                onPressed: loading ? null : () => load(more: true),
                child: const Text('Xem thêm'),
              ),
          ],
        ),
      ),
    );
  }

  void applySearch() {
    appliedSearch = search.text.trim();
    unawaited(load());
  }
}

class DispatchDetail extends StatefulWidget {
  const DispatchDetail({super.key, required this.item, required this.mode});
  final Json item;
  final String mode;

  @override
  State<DispatchDetail> createState() => _DispatchDetailState();
}

class _DispatchDetailState extends State<DispatchDetail> {
  Json? current;
  Json? pending;
  String? error;
  bool busy = false;
  bool get waiting => widget.mode == 'waiting';
  bool get admin => widget.mode == 'admin';
  bool get citizen => widget.mode == 'mine';
  String get id => widget.item['id'] as String;

  @override
  void initState() {
    super.initState();
    if (!waiting) unawaited(read());
  }

  Future<void> read() async {
    try {
      final response = await reliefRepository.api.json('GET', '/dispatch/$id');
      if (mounted) {
        setState(() {
          current = response;
          error = null;
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          current = null;
          error = exception is ApiFailure
              ? exception.message
              : 'Không tải được chi tiết.';
        });
      }
    }
  }

  Future<void> send(Json action) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action['action'] == 'claim'
              ? 'Nhận nhiệm vụ này?'
              : 'Xác nhận cập nhật nhiệm vụ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    pending = {
      'operationId': const Uuid().v4(),
      'revision': (current ?? widget.item)['revision'],
      'command': action,
    };
    await submit();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      final command = pending!['command'] as Json;
      final response = await reliefRepository.api.json(
        'POST',
        '/dispatch/$id/actions',
        body: pending,
      );
      if (!mounted) return;
      setState(() => pending = null);
      if (command['action'] == 'claim') {
        await read();
        if (mounted && current != null) {
          message(
            context,
            'Đã xác nhận độc quyền cho đội ${response['teamName']}.',
          );
        }
      } else if (command['action'] == 'return') {
        message(context, 'Đã trả nhiệm vụ về chờ.');
        Navigator.pop(context);
      } else {
        await read();
        if (mounted) message(context, 'Đã cập nhật nhiệm vụ.');
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      message(context, failure.message);
      if (!failure.retryable) {
        setState(() => pending = null);
        if (waiting && current == null) {
          Navigator.pop(context);
        } else {
          await read();
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> assign() async {
    try {
      final response = await reliefRepository.api.json(
        'GET',
        '/dispatch/teams',
      );
      if (!mounted) return;
      final teams = (response['items'] as List).cast<Json>();
      final selected = await showDialog<Json>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Chọn đội đủ điều kiện'),
          children: [
            if (teams.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Chưa có đội đủ điều kiện.'),
              ),
            for (final team in teams)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, team),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(team['name'] as String),
                ),
              ),
          ],
        ),
      );
      if (selected != null && mounted) {
        await withReason('assign', {'teamId': selected['id']});
      }
    } on ApiFailure catch (failure) {
      if (mounted) message(context, failure.message);
    }
  }

  Future<void> withReason(String action, [Json fields = const {}]) async {
    final result = await showDialog<Json>(
      context: context,
      builder: (_) => _ReasonForm(link: action == 'link'),
    );
    if (result != null && mounted) {
      await send({'action': action, ...fields, ...result});
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = current ?? widget.item;
    final data = (current?['data'] as Json?) ?? {};
    final contact = (current?['contact'] as Json?) ?? {};
    final status = item['status'] as String?;
    final enabled = !busy && pending == null;
    final active = [
      'waiting',
      'accepted',
      'travelling',
      'arrived',
    ].contains(status);
    final overview = waiting && current == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(overview ? 'Tóm tắt nhiệm vụ' : 'Chi tiết yêu cầu'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SelectableText(id),
            Text(
              statuses[status] ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('${item['urgency']} · ${item['people']} người'),
            Text((item['types'] as List).join(', ')),
            if (item['teamName'] != null)
              Text('Đội phụ trách: ${item['teamName']}'),
            if (item['linked'] == true)
              const Text(
                'Đây là yêu cầu liên kết. Trạng thái lấy từ đơn chính.',
              ),
            if (error != null) Text(error!),
            if (busy) const LinearProgressIndicator(),
            if (data.isNotEmpty) ...[
              const Divider(),
              Text('Tình trạng: ${data['description'] ?? ''}'),
              Text('Địa chỉ: ${data['address'] ?? ''}'),
              Text('Chỉ dẫn: ${data['landmark'] ?? ''}'),
              Text('Liên hệ: ${contact['name']} · ${contact['phone']}'),
              if (current?['location'] case final Json location)
                Text(
                  'Tọa độ: ${location['latitude']}, ${location['longitude']}',
                ),
            ],
            if (overview)
              FilledButton(
                style: dispatchPrimary,
                onPressed: enabled ? () => send({'action': 'claim'}) : null,
                child: const Text('Nhận nhiệm vụ'),
              ),
            if (current != null && !admin && !citizen && active) ...[
              if (status == 'accepted' || status == 'travelling')
                FilledButton(
                  onPressed: enabled
                      ? () => send({
                          'action': 'progress',
                          'progress': status == 'accepted'
                              ? 'travelling'
                              : 'arrived',
                        })
                      : null,
                  child: Text(
                    status == 'accepted' ? 'Đang di chuyển' : 'Đã đến nơi',
                  ),
                ),
              OutlinedButton(
                onPressed: enabled ? () => withReason('return') : null,
                child: const Text('Trả nhiệm vụ về chờ'),
              ),
            ],
            if (admin &&
                current != null &&
                active &&
                item['linked'] != true &&
                item['verification'] == 'valid') ...[
              FilledButton(
                onPressed: enabled ? assign : null,
                child: Text(status == 'waiting' ? 'Phân công' : 'Chuyển đội'),
              ),
              if (status == 'waiting')
                OutlinedButton(
                  onPressed: enabled ? () => withReason('link') : null,
                  child: const Text('Liên kết với đơn chính'),
                ),
            ],
            if ((citizen || admin) && current != null)
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        C08RequestDetailWaitingScreen(requestId: id),
                  ),
                ),
                child: Text(
                  admin ? 'Hồ sơ xác minh' : 'Nội dung và ảnh đã gửi',
                ),
              ),
            if (pending != null && !busy)
              FilledButton(
                onPressed: submit,
                child: const Text('Thử lại cùng thao tác'),
              ),
            if (error != null && !overview)
              OutlinedButton(
                onPressed: read,
                child: const Text('Tải lại chi tiết'),
              ),
            for (final event in (current?['events'] as List? ?? []))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  eventLabels[event['action']] ?? 'Cập nhật nhiệm vụ',
                ),
                subtitle: Text(
                  '${event['at']}${event['details']?['reason'] == null ? '' : '\nLý do: ${event['details']['reason']}'}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const eventLabels = {
  'dispatch.accepted': 'Đội đã nhận nhiệm vụ',
  'dispatch.assigned': 'Đã phân công',
  'dispatch.transferred': 'Đã chuyển đội',
  'dispatch.returned': 'Đã trả về chờ',
  'dispatch.travelling': 'Đang di chuyển',
  'dispatch.arrived': 'Đã đến nơi',
  'dispatch.linked': 'Đã liên kết đơn',
  'dispatch.partial': 'Đã hỗ trợ một phần',
  'dispatch.completed': 'Đã hoàn thành',
};

final dispatchPrimary = FilledButton.styleFrom(minimumSize: const Size(48, 48));
final dispatchOutline = OutlinedButton.styleFrom(
  minimumSize: const Size(48, 48),
);

class _ReasonForm extends StatefulWidget {
  const _ReasonForm({required this.link});
  final bool link;
  @override
  State<_ReasonForm> createState() => _ReasonFormState();
}

class _ReasonFormState extends State<_ReasonForm> {
  final reason = TextEditingController(), primary = TextEditingController();
  @override
  void dispose() {
    reason.dispose();
    primary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.link ? 'Liên kết yêu cầu trùng' : 'Ghi lý do'),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.link)
          TextField(
            controller: primary,
            decoration: const InputDecoration(labelText: 'Mã đơn chính'),
            onChanged: (_) => setState(() {}),
          ),
        TextField(
          controller: reason,
          maxLength: 2000,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Lý do bắt buộc'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        onPressed:
            reason.text.trim().isEmpty ||
                (widget.link && primary.text.trim().isEmpty)
            ? null
            : () => Navigator.pop(context, {
                'reason': reason.text.trim(),
                if (widget.link) 'primaryId': primary.text.trim(),
              }),
        child: const Text('Tiếp tục'),
      ),
    ],
  );
}

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<void> showDispatchGuide(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Gửi và theo dõi yêu cầu cứu trợ'),
    scrollable: true,
    content: const Text(
      '1. Chọn nhu cầu, nhập số người và mô tả tình trạng.\n\n'
      '2. Xác nhận vị trí trên bản đồ. Bạn có thể đính kèm ảnh.\n\n'
      '3. Xem lại thông tin và bấm gửi. Chờ thông báo xác nhận từ máy chủ.\n\n'
      '4. Vào Yêu cầu để xem tiến độ. Bấm biểu tượng chuông để xem thông báo.',
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đã hiểu'),
      ),
    ],
  ),
);
