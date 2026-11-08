import 'package:flutter/material.dart';

import '../data/relief_request.dart';
import '../data/request_store.dart';
import '../services/evidence_service.dart';
import '../widgets/request_loader.dart';
import '../widgets/request_reason_dialog.dart';
import 'request_wizard_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  final DemoRole role;
  final EvidenceService? evidenceService;
  const RequestDetailScreen({
    super.key,
    required this.requestId,
    this.role = DemoRole.citizen,
    this.evidenceService,
  });
  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) requestMessage(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(ReliefRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy yêu cầu cứu trợ?'),
        content: Text(
          'Yêu cầu ${request.id} sẽ ngừng chờ cứu trợ. Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ yêu cầu'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await RequestStore.instance.cancel(
        request.id,
        confirmed: true,
        revision: request.revision,
      );
      if (mounted) requestMessage(context, 'Đã hủy yêu cầu.');
    });
  }

  Future<void> _reasonDialog(
    ReliefRequest request, {
    Verification? decision,
  }) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => RequestReasonDialog(decision: decision),
    );
    if (reason == null || !mounted) return;
    await _run(() async {
      if (decision == null) {
        await RequestStore.instance.report(
          request.id,
          reason,
          actor: widget.role == DemoRole.admin
              ? 'demo-admin'
              : RequestStore.citizenId,
        );
      } else {
        await RequestStore.instance.review(
          request.id,
          decision,
          reason,
          role: widget.role,
          revision: request.revision,
        );
      }
      if (mounted) {
        requestMessage(
          context,
          decision == null ? 'Đã lưu báo cáo.' : 'Đã lưu kết quả xác minh.',
        );
      }
    });
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
  Widget _body(RequestStore store) {
    final ReliefRequest r;
    try {
      r = store.get(widget.requestId, role: widget.role);
    } catch (e) {
      return Center(child: Text('$e'));
    }
    final d = r.data;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(padding: EdgeInsets.all(8), child: Text(demoNotice)),
            _section(r.id, [
              Text('Xử lý: ${stageLabel(r.stage)}'),
              Text('Xác minh: ${verificationLabel(r.verification)}'),
              if (r.reason.isNotEmpty) Text('Lý do / ghi chú: ${r.reason}'),
              Text('Cập nhật: ${r.updatedAt.toLocal()}'),
              if (r.editable && widget.role == DemoRole.citizen)
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RequestWizardScreen(requestId: r.id),
                          ),
                        ),
                  icon: const Icon(Icons.edit),
                  label: Text(
                    r.stage == RequestStage.draft
                        ? 'Tiếp tục bản nháp'
                        : 'Sửa / bổ sung yêu cầu',
                  ),
                ),
              if (r.cancellable && widget.role == DemoRole.citizen)
                OutlinedButton(
                  onPressed: _busy ? null : () => _cancel(r),
                  child: const Text('Hủy yêu cầu'),
                ),
              if (!r.editable && r.stage != RequestStage.draft)
                const Text('Không thể chỉnh sửa ở trạng thái hiện tại.'),
            ]),
            _section('Thông tin cứu trợ', [
              Text(
                'Đối tượng: ${d.recipient == 'self' ? 'Bản thân / gia đình' : '${d.contactName} — ${d.contactPhone}'}',
              ),
              Text('Nhu cầu: ${d.types.join(', ')}'),
              Text('Tổng số: ${d.people} người'),
              Text(
                'Người cao tuổi: ${d.elderly}; trẻ em: ${d.children}; khuyết tật: ${d.disabled}; chăm sóc đặc biệt: ${d.special}',
              ),
              if (d.specialNotes.isNotEmpty)
                Text('Chăm sóc: ${d.specialNotes}'),
              Text('Khẩn cấp: ${d.urgency}'),
              Text('Tình trạng: ${d.description}'),
              Text('Địa chỉ: ${d.address}'),
              Text('Nhận diện: ${d.landmark}'),
              Text(
                'Vị trí (${d.locationSource}): ${d.latitude}, ${d.longitude}',
              ),
            ]),
            _section('Ảnh và đối chiếu thời gian', [
              const Text(
                'Chế độ mẫu: thời điểm tiếp nhận được mô phỏng bằng đồng hồ thiết bị. Chưa xác minh được độ lệch với máy chủ thật. Dấu thời gian/GPS không tự chứng minh ảnh là thật.',
              ),
              Text(
                'Thời gian thiết bị khi gửi: ${r.submittedAt?.toLocal() ?? 'Chưa gửi'}',
              ),
              Text(
                'Tiếp nhận mô phỏng: ${r.receivedAt?.toLocal() ?? 'Chưa gửi'}',
              ),
              if (d.photos.isEmpty) const Text('Chưa có ảnh xác minh.'),
              for (final p in d.photos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: InteractiveViewer(
                                    child: Image.memory(p.bytes),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Đóng'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: Image.memory(
                          p.bytes,
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Text('Ảnh bị lỗi.'),
                        ),
                      ),
                      Text(
                        '${p.demo ? 'Ảnh mẫu • ' : ''}${p.recovered ? 'Giờ ước tính của ảnh khôi phục' : 'Giờ ảnh'}: ${p.capturedAt.toLocal()}',
                      ),
                      Text(
                        'GPS ảnh: ${p.latitude ?? 'không có'}, ${p.longitude ?? 'không có'}',
                      ),
                      if (r.receivedAt != null)
                        Text(
                          'Chênh thời gian ảnh / tiếp nhận mô phỏng: ${p.capturedAt.difference(r.receivedAt!).inSeconds} giây',
                        ),
                    ],
                  ),
                ),
            ]),
            _section('Dấu hiệu cần xác minh', [
              const Text(
                'Các dấu hiệu chỉ hỗ trợ kiểm tra, không tự kết luận giả mạo.',
              ),
              if (r.flags.isEmpty)
                const Text('Chưa ghi nhận dấu hiệu nghi vấn.'),
              for (final flag in r.flags) Text('• $flag'),
              if (r.stage != RequestStage.draft)
                OutlinedButton(
                  onPressed: _busy ? null : () => _reasonDialog(r),
                  child: const Text('Báo cáo dấu hiệu giả mạo'),
                ),
              if (widget.role == DemoRole.admin) ...[
                for (final report in r.reports)
                  Text('Báo cáo ${report['at']}: ${report['reason']}'),
                if (r.stage == RequestStage.waiting)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final decision in [
                        Verification.valid,
                        Verification.needsInfo,
                        Verification.invalid,
                      ])
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _reasonDialog(r, decision: decision),
                          child: Text(verificationLabel(decision)),
                        ),
                    ],
                  ),
              ],
            ]),
            _section('Thông báo của yêu cầu', [
              if (r.notices.isEmpty) const Text('Chưa có thông báo.'),
              for (final n in r.notices.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text('${n['text']}'),
                  subtitle: Text('${n['at']}'),
                ),
              const Text(
                'Thông báo trong ứng dụng luôn được lưu, kể cả khi không cấp quyền thông báo hệ thống.',
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        final granted =
                            await (widget.evidenceService ?? EvidenceService())
                                .requestNotifications();
                        if (mounted) {
                          requestMessage(
                            context,
                            granted
                                ? 'Đã cấp quyền. Bản mẫu vẫn dùng thông báo trong ứng dụng.'
                                : 'Chưa cấp quyền. Bạn vẫn xem được thông báo tại đây.',
                          );
                        }
                      }),
                child: const Text('Cho phép thông báo hệ thống'),
              ),
            ]),
            _section('Lịch sử cập nhật', [
              for (final event in r.history.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${event['action']}'),
                  subtitle: Text('${event['actor']} • ${event['at']}'),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết yêu cầu')),
    body: Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        Expanded(child: RequestLoader(builder: (_, store) => _body(store))),
      ],
    ),
  );
}
