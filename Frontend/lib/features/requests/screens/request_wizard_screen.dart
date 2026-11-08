import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../data/relief_request.dart';
import '../data/camera_checkpoint.dart';
import '../data/request_store.dart';
import '../services/evidence_service.dart';
import '../widgets/request_loader.dart';
import 'request_detail_screen.dart';

class RequestWizardScreen extends StatefulWidget {
  final String? requestId;
  final bool resumeDraft;
  final RequestDraft? initialData;
  final int initialStep;
  final EvidenceService? evidenceService;
  const RequestWizardScreen({
    super.key,
    this.requestId,
    this.resumeDraft = false,
    this.initialData,
    this.initialStep = 0,
    this.evidenceService,
  });
  @override
  State<RequestWizardScreen> createState() => _RequestWizardScreenState();
}

class _RequestWizardScreenState extends State<RequestWizardScreen> {
  late final _service = widget.evidenceService ?? EvidenceService();
  late RequestDraft _data;
  String? _id;
  int? _revision;
  int _step = 0;
  int _coordinateRevision = 0;
  bool _initialized = false, _busy = false, _dirty = false, _allowPop = false;
  bool _submitted = false;
  bool _waitingForPhotoChoice = false;
  List<String> _errors = [];
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _initialize(RequestStore store) {
    if (_initialized) return;
    _step = widget.initialStep;
    _id = widget.requestId;
    if (_id == null && widget.resumeDraft) {
      final drafts = store.list().where((r) => r.stage == RequestStage.draft);
      if (drafts.isNotEmpty) _id = drafts.first.id;
    }
    if (_id != null) {
      final request = store.get(_id!);
      _data = request.data.copy();
      _revision = request.revision;
      if (!request.editable) {
        throw const RequestError('Yêu cầu này không còn được chỉnh sửa.');
      }
      _submitted = request.stage != RequestStage.draft;
    } else {
      _data = widget.initialData?.copy() ?? RequestDraft();
    }
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        _restoreCamera();
      }
    });
  }

  void _restoreCamera() {
    final recovery = RequestStore.instance.cameraRecovery;
    if (recovery == null) return;
    final CameraCheckpoint? checkpoint;
    try {
      checkpoint = recovery.read();
    } catch (_) {
      requestMessage(
        context,
        'Không đọc được phiên camera trước đó. Dữ liệu yêu cầu vẫn được giữ nguyên.',
      );
      return;
    }
    if (checkpoint == null) return;
    final CameraCheckpoint session = checkpoint;
    _run(() async {
      EvidencePhoto? photo;
      try {
        photo = await _service.recoverCapture(session.startedAt);
      } catch (e) {
        if (mounted) requestMessage(context, e);
      }
      if (!mounted) return;
      final recoveredPhoto = photo;
      setState(() => _waitingForPhotoChoice = true);
      final restore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          scrollable: true,
          title: const Text('Khôi phục phiên chụp ảnh?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Android đã gián đoạn phiên camera của ${session.requestId ?? 'biểu mẫu mới'}. Khôi phục thông tin đang soạn trước khi mở camera?',
              ),
              if (recoveredPhoto != null) ...[
                Image.memory(recoveredPhoto.bytes, height: 180),
                const Text(
                  'Ảnh khôi phục có giờ ước tính và chưa xác định được GPS lúc chụp; cần xác minh thêm.',
                ),
              ] else
                const Text(
                  'Không có ảnh trả về. Có thể khôi phục biểu mẫu rồi chụp lại.',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bỏ phiên cũ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Khôi phục'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _waitingForPhotoChoice = false);
      if (restore == true) {
        final existing = session.requestId == null
            ? null
            : RequestStore.instance.get(session.requestId!);
        if (existing != null && !existing.editable) {
          await recovery.clear();
          throw const RequestError(
            'Yêu cầu đã kết thúc hoặc được đội tiếp nhận; không khôi phục thay đổi cũ vào yêu cầu này.',
          );
        }
        setState(() {
          _data = session.data.copy();
          _id = session.requestId;
          _revision = session.revision;
          _submitted = existing != null && existing.stage != RequestStage.draft;
          _step = 2;
          _dirty = true;
          _coordinateRevision++;
          final replace = session.replaceIndex;
          if (recoveredPhoto != null) {
            if (replace != null &&
                replace >= 0 &&
                replace < _data.photos.length) {
              _data.photos[replace] = recoveredPhoto;
            } else if (_data.photos.length < 5) {
              _data.photos.add(recoveredPhoto);
            }
          }
        });
      }
      await recovery.clear();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_initialized) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) requestMessage(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run(() async {
    _id = await RequestStore.instance.saveDraft(
      _data,
      id: _id,
      revision: _revision,
    );
    _revision = RequestStore.instance.get(_id!).revision;
    _dirty = false;
    if (mounted) requestMessage(context, 'Đã lưu bản nháp trên thiết bị.');
  });
  Future<void> _leave() async {
    if (_busy) return;
    if (!_dirty) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời biểu mẫu?'),
        content: Text(
          _submitted
              ? 'Các thay đổi chưa gửi sẽ bị bỏ. Yêu cầu đã gửi vẫn được giữ nguyên.'
              : 'Bạn có thể lưu bản nháp để tiếp tục sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'stay'),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Bỏ thay đổi'),
          ),
          if (!_submitted)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('Lưu nháp'),
            ),
        ],
      ),
    );
    if (choice == 'save') {
      await _save();
      if (_dirty) return;
    }
    if ((choice == 'save' || choice == 'discard') && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  void _next() {
    final errors = _data.validate(throughStep: _step + 1);
    setState(() => _errors = errors);
    if (errors.isEmpty) {
      setState(() => _step++);
      _scroll.jumpTo(0);
    }
  }

  Future<void> _submit() => _run(() async {
    final errors = _data.validate();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    final id = await RequestStore.instance.submit(
      _data,
      id: _id,
      revision: _revision,
    );
    _dirty = false;
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: id)),
    );
  });
  Future<void> _gps() => _run(() async {
    final position = await _service.locate();
    if (!mounted) return;
    setState(() {
      _data.latitude = position.latitude;
      _data.longitude = position.longitude;
      _data.accuracy = position.accuracy;
      _data.locationSource = 'GPS';
      _coordinateRevision++;
      _dirty = true;
    });
  });
  Future<void> _photo({bool demo = false, int? replace}) => _run(() async {
    if (replace == null && _data.photos.length >= 5) {
      throw const RequestError('Mỗi yêu cầu tối đa 5 ảnh.');
    }
    final recovery = RequestStore.instance.cameraRecovery;
    if (!demo && recovery != null) {
      await recovery.write(
        CameraCheckpoint(
          data: _data.copy(),
          startedAt: DateTime.now().toUtc(),
          requestId: _id,
          revision: _revision,
          replaceIndex: replace,
        ),
      );
    }
    final EvidencePhoto? photo;
    try {
      photo = demo ? _service.sample() : await _service.capture();
    } catch (_) {
      if (!demo && recovery != null) await recovery.clear();
      rethrow;
    }
    if (photo == null || !mounted) {
      if (!demo && recovery != null) await recovery.clear();
      return;
    }
    final EvidencePhoto previewPhoto = photo;
    setState(() => _waitingForPhotoChoice = true);
    final keep = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kiểm tra độ rõ của ảnh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(previewPhoto.bytes),
              const SizedBox(height: 8),
              Text(
                previewPhoto.demo
                    ? 'Ảnh mẫu — không dùng làm bằng chứng thực tế.'
                    : 'Ảnh đã đóng dấu thời gian và tình trạng tọa độ.',
              ),
              if (previewPhoto.latitude == null)
                const Text(
                  'Không lấy được GPS tại thời điểm chụp. Ảnh sẽ được đánh dấu cần xác minh thêm.',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không dùng ảnh'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Dùng ảnh này'),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _waitingForPhotoChoice = false);
    if (keep == true && mounted) {
      setState(() {
        if (replace != null) {
          _data.photos[replace] = previewPhoto;
        } else {
          _data.photos.add(previewPhoto);
        }
        _dirty = true;
      });
    }
    if (!demo && recovery != null) await recovery.clear();
  });
  Widget _field(
    String label,
    String value,
    ValueChanged<String> change, {
    int maxLines = 1,
    TextInputType? keyboard,
    int maxLength = 500,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: ValueKey(
        '$_step-$label${label == 'Vĩ độ' || label == 'Kinh độ' ? '-$_coordinateRevision' : ''}',
      ),
      initialValue: value,
      enabled: !_busy,
      keyboardType: keyboard,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) {
        change(v);
        if (!_dirty) setState(() => _dirty = true);
      },
      onFieldSubmitted: (_) {
        if (label == 'Vĩ độ' || label == 'Kinh độ') setState(() {});
      },
    ),
  );
  Widget _count(
    String label,
    int count,
    ValueChanged<int> update, {
    int minimum = 0,
    int maximum = 10000,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: 'Giảm $label',
          onPressed: !_busy && count > minimum
              ? () => setState(() {
                  update(count - 1);
                  _dirty = true;
                })
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(width: 42, child: Text('$count', textAlign: TextAlign.center)),
        IconButton(
          tooltip: 'Tăng $label',
          onPressed: !_busy && count < maximum
              ? () => setState(() {
                  update(count + 1);
                  _dirty = true;
                })
              : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    ),
  );
  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
  Widget _needs() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section('Người cần hỗ trợ', [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'self', label: Text('Bản thân / gia đình')),
            ButtonSegment(value: 'other', label: Text('Người khác')),
          ],
          selected: {_data.recipient},
          onSelectionChanged: _busy
              ? null
              : (v) => setState(() {
                  _data.recipient = v.first;
                  _dirty = true;
                }),
        ),
        if (_data.recipient == 'other') ...[
          const SizedBox(height: 12),
          _field(
            'Tên người cần hỗ trợ',
            _data.contactName,
            (v) => _data.contactName = v,
            maxLength: 100,
          ),
          _field(
            'Số điện thoại liên hệ',
            _data.contactPhone,
            (v) => _data.contactPhone = v,
            keyboard: TextInputType.phone,
            maxLength: 10,
          ),
        ],
      ]),
      _section(
        'Loại hỗ trợ (chọn ít nhất một)',
        reliefTypes
            .map(
              (type) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(type),
                value: _data.types.contains(type),
                onChanged: _busy
                    ? null
                    : (checked) => setState(() {
                        if (checked == true) {
                          _data.types.add(type);
                        } else {
                          _data.types.remove(type);
                        }
                        _dirty = true;
                      }),
              ),
            )
            .toList(),
      ),
      _section('Số người và nhóm ưu tiên', [
        _count(
          'Tổng số người',
          _data.people,
          (v) => _data.people = v,
          minimum: 1,
        ),
        const Text(
          'Nhóm khuyết tật/chăm sóc đặc biệt có thể trùng nhóm khác. Tổng người cao tuổi và trẻ em không vượt tổng số người.',
        ),
        _count(
          'Người cao tuổi',
          _data.elderly,
          (v) => _data.elderly = v,
          maximum: _data.people,
        ),
        _count(
          'Trẻ em',
          _data.children,
          (v) => _data.children = v,
          maximum: _data.people,
        ),
        _count(
          'Người khuyết tật',
          _data.disabled,
          (v) => _data.disabled = v,
          maximum: _data.people,
        ),
        _count(
          'Cần chăm sóc đặc biệt',
          _data.special,
          (v) => _data.special = v,
          maximum: _data.people,
        ),
        _field(
          'Nhu cầu chăm sóc đặc biệt',
          _data.specialNotes,
          (v) => _data.specialNotes = v,
          maxLines: 2,
          maxLength: 1000,
        ),
      ]),
      _section('Tình trạng hiện tại', [
        _field(
          'Mô tả tình trạng',
          _data.description,
          (v) => _data.description = v,
          maxLines: 4,
          maxLength: 2000,
        ),
        DropdownButtonFormField<String>(
          initialValue: _data.urgency.isEmpty ? null : _data.urgency,
          decoration: const InputDecoration(
            labelText: 'Mức độ khẩn cấp',
            border: OutlineInputBorder(),
          ),
          items: urgencyLevels
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: _busy
              ? null
              : (v) => setState(() {
                  _data.urgency = v ?? '';
                  _dirty = true;
                }),
        ),
      ]),
    ],
  );
  Widget _location() => _section('Vị trí cần cứu trợ', [
    const Text(
      'Chạm bản đồ để ghim vị trí hoặc dùng GPS. Chỉ xin quyền khi bạn bấm lấy GPS.',
    ),
    const SizedBox(height: 10),
    SizedBox(
      height: 280,
      child: FlutterMap(
        key: ValueKey('${_data.latitude}-${_data.longitude}'),
        options: MapOptions(
          initialCenter: validCoordinates(_data.latitude, _data.longitude)
              ? LatLng(_data.latitude!, _data.longitude!)
              : const LatLng(20.8841, 105.6215),
          initialZoom: 14,
          onTap: _busy
              ? null
              : (_, point) => setState(() {
                  _data.latitude = point.latitude;
                  _data.longitude = point.longitude;
                  _data.locationSource = 'Ghim bản đồ';
                  _coordinateRevision++;
                  _data.accuracy = null;
                  _dirty = true;
                }),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flood_relief_app',
          ),
          if (validCoordinates(_data.latitude, _data.longitude))
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(_data.latitude!, _data.longitude!),
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 42,
                  ),
                ),
              ],
            ),
          const Align(
            alignment: Alignment.bottomRight,
            child: ColoredBox(
              color: Colors.white,
              child: Text('© OpenStreetMap contributors'),
            ),
          ),
        ],
      ),
    ),
    const Text(
      'Nếu nền bản đồ không tải, bạn vẫn có thể dùng GPS hoặc nhập tọa độ.',
    ),
    Text(
      validCoordinates(_data.latitude, _data.longitude)
          ? '${_data.locationSource}: ${_data.latitude!.toStringAsFixed(6)}, ${_data.longitude!.toStringAsFixed(6)}${_data.accuracy == null ? '' : ' (±${_data.accuracy!.round()}m)'}'
          : 'Chưa chọn tọa độ.',
    ),
    Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _gps,
          icon: const Icon(Icons.my_location),
          label: const Text('Lấy GPS'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _data.latitude = 20.8841;
                  _data.longitude = 105.6215;
                  _data.locationSource = 'Vị trí mẫu';
                  _coordinateRevision++;
                  _data.accuracy = null;
                  _dirty = true;
                }),
          child: const Text('Dùng vị trí mẫu'),
        ),
        TextButton(
          onPressed: _busy ? null : () => openAppSettings(),
          child: const Text('Cài đặt quyền'),
        ),
      ],
    ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: _field(
            'Vĩ độ',
            _data.latitude?.toString() ?? '',
            (v) {
              _data.latitude = double.tryParse(v);
              _data.locationSource = 'Nhập tọa độ';
              _data.accuracy = null;
            },
            keyboard: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            maxLength: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _field(
            'Kinh độ',
            _data.longitude?.toString() ?? '',
            (v) {
              _data.longitude = double.tryParse(v);
              _data.locationSource = 'Nhập tọa độ';
              _data.accuracy = null;
            },
            keyboard: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            maxLength: 20,
          ),
        ),
      ],
    ),
    _field('Địa chỉ', _data.address, (v) => _data.address = v, maxLines: 2),
    _field(
      'Hướng dẫn nhận diện địa điểm',
      _data.landmark,
      (v) => _data.landmark = v,
      maxLines: 3,
      maxLength: 1000,
    ),
  ]);
  Widget _photos() => _section('Ảnh xác minh (${_data.photos.length}/5)', [
    const Text(
      'Ảnh được đóng dấu giờ thiết bị (UTC) và tọa độ lúc chụp. Ghim bản đồ không thay thế GPS của ảnh. Nếu không chụp được, bạn vẫn có thể gửi và bổ sung sau; yêu cầu sẽ cần xác minh thêm.',
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : () => _photo(),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Chụp ảnh'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _photo(demo: true),
          child: const Text('Thêm ảnh mẫu'),
        ),
      ],
    ),
    for (var i = 0; i < _data.photos.length; i++) _photoCard(i),
    if (_data.photos.isEmpty)
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Chưa có ảnh — sẽ đánh dấu cần xác minh thêm.'),
      ),
  ]);
  Widget _photoCard(int index) {
    final p = _data.photos[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Image.memory(
              p.bytes,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Text('Không đọc được ảnh. Hãy chụp lại.'),
            ),
            Text(
              '${p.demo ? 'Ảnh mẫu • ' : ''}${p.recovered ? 'Ảnh khôi phục, giờ ước tính • ' : ''}${p.capturedAt.toLocal()}',
            ),
            if (p.latitude == null) const Text('Thiếu vị trí GPS của ảnh.'),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _photo(replace: index),
                  child: const Text('Chụp lại'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _photo(demo: true, replace: index),
                  child: const Text('Thay bằng ảnh mẫu'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _data.photos.removeAt(index);
                          _dirty = true;
                        }),
                  child: const Text('Xóa ảnh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _review(RequestStore store) {
    final similar = similarRequests(
      _data,
      store.list(role: DemoRole.admin).where((r) => r.id != _id),
    );
    return _section('Kiểm tra trước khi gửi', [
      Text(
        'Đối tượng: ${_data.recipient == 'self' ? 'Bản thân / gia đình' : '${_data.contactName} — ${_data.contactPhone}'}',
      ),
      Text('Hỗ trợ: ${_data.types.join(', ')}'),
      Text('Tổng số: ${_data.people} người'),
      Text(
        'Cao tuổi: ${_data.elderly} • Trẻ em: ${_data.children} • Khuyết tật: ${_data.disabled} • Chăm sóc đặc biệt: ${_data.special}',
      ),
      if (_data.specialNotes.isNotEmpty)
        Text('Chăm sóc: ${_data.specialNotes}'),
      Text('Khẩn cấp: ${_data.urgency}'),
      Text('Tình trạng: ${_data.description}'),
      Text('Địa chỉ: ${_data.address}'),
      Text('Nhận diện: ${_data.landmark}'),
      Text('${_data.locationSource}: ${_data.latitude}, ${_data.longitude}'),
      Text('${_data.photos.length} ảnh'),
      for (final p in _data.photos)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Image.memory(p.bytes, height: 140),
        ),
      Text('Thời gian thiết bị hiện tại: ${DateTime.now().toLocal()}'),
      const Text(
        'Thời điểm tiếp nhận chỉ được tạo sau khi gửi. Bản mẫu dùng đồng hồ thiết bị để mô phỏng, chưa có máy chủ đối chiếu.',
      ),
      for (final flag in evidenceFlags(_data, DateTime.now())) Text('⚠ $flag'),
      if (similar.isNotEmpty)
        Text(
          '⚠ Có ${similar.length} yêu cầu đang hoạt động có nội dung giống hoặc vị trí trong 100m. Đây là cảnh báo, không tự từ chối yêu cầu.',
        ),
      const SizedBox(height: 12),
      const Text(demoNotice),
    ]);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop || (!_dirty && !_busy && _step == 0),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        if (!_busy && _step > 0) {
          setState(() {
            _step--;
            _errors = [];
          });
        } else {
          _leave();
        }
      }
    },
    child: Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Bước ${_step + 1}/4: ${['Nhu cầu', 'Vị trí', 'Ảnh xác minh', 'Xem lại'][_step]}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy
              ? null
              : () => _step > 0 ? setState(() => _step--) : _leave(),
        ),
        actions: [
          if (!_submitted)
            TextButton(
              onPressed: _busy ? null : _save,
              child: const Text('Lưu nháp'),
            ),
        ],
      ),
      body: RequestLoader(
        builder: (context, store) {
          try {
            _initialize(store);
          } catch (e) {
            return Center(child: Text('$e'));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Column(
                children: [
                  LinearProgressIndicator(value: (_step + 1) / 4),
                  if (_busy && !_waitingForPhotoChoice)
                    const LinearProgressIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(demoNotice),
                          ),
                          if (_errors.isNotEmpty)
                            Card(
                              color: Colors.red.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _errors.join('\n'),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          KeyedSubtree(
                            key: ValueKey(_step),
                            child: switch (_step) {
                              0 => _needs(),
                              1 => _location(),
                              2 => _photos(),
                              _ => _review(store),
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (_step > 0)
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _step--;
                                      _errors = [];
                                    }),
                              child: const Text('Quay lại'),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _busy
                                  ? null
                                  : (_step < 3 ? _next : _submit),
                              child: Text(
                                _step < 3
                                    ? 'Tiếp tục'
                                    : _submitted
                                    ? 'Gửi cập nhật'
                                    : 'Gửi yêu cầu mẫu',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
