import 'package:flutter/material.dart';

import '../data/relief_repository.dart';
import '../data/request_draft.dart';
import '../data/request_presentation.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'evidence_preview.dart';
import 'sync_status.dart';

class RequestReviewPanel extends StatefulWidget {
  const RequestReviewPanel({
    super.key,
    required this.request,
    required this.reload,
  });
  final Json request;
  final Future<void> Function() reload;
  @override
  State<RequestReviewPanel> createState() => _RequestReviewPanelState();
}

class _RequestReviewPanelState extends State<RequestReviewPanel> {
  bool _busy = false;
  Future<Json>? _similar;
  final List<Json> _olderHistory = [];
  String? _historyCursor;
  bool _historyStarted = false, _historyLoading = false;
  @override
  void didUpdateWidget(covariant RequestReviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request['id'] != widget.request['id'] ||
        oldWidget.request['revision'] != widget.request['revision']) {
      _olderHistory.clear();
      _historyStarted = false;
      _historyCursor = null;
      _similar = null;
    }
  }

  Future<void> _moreHistory() async {
    if (_historyLoading) return;
    setState(() => _historyLoading = true);
    final requestId = widget.request['id'];
    final revision = widget.request['revision'];
    try {
      final cursor = _historyStarted
          ? _historyCursor
          : widget.request['historyNextCursor'];
      if (cursor == null) return;
      final page = await reliefRepository.api.json(
        'GET',
        '/requests/${widget.request['id']}/history?before=$cursor',
      );
      if (!mounted ||
          widget.request['id'] != requestId ||
          widget.request['revision'] != revision) {
        return;
      }
      setState(() {
        _olderHistory.addAll(
          (page['items'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
        _historyCursor = page['nextCursor'];
        _historyStarted = true;
      });
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _decision({bool report = false}) async {
    final reason = TextEditingController();
    String decision = 'valid';
    String? reasonError;
    final body = await showDialog<Json>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(
            report ? 'Báo cáo dấu hiệu nghi vấn' : 'Kết quả kiểm tra yêu cầu',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!report)
                  DropdownButtonFormField<String>(
                    initialValue: decision,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'valid', child: Text('Hợp lệ')),
                      DropdownMenuItem(
                        value: 'needs_info',
                        child: Text('Cần bổ sung'),
                      ),
                      DropdownMenuItem(
                        value: 'invalid',
                        child: Text('Không hợp lệ'),
                      ),
                    ],
                    onChanged: (v) => setDialog(() => decision = v!),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  onChanged: (_) {
                    if (reasonError != null) {
                      setDialog(() => reasonError = null);
                    }
                  },
                  maxLength: 2000,
                  maxLines: 3,
                  decoration: InputDecoration(
                    errorText: reasonError,
                    labelText: report
                        ? 'Nội dung cần kiểm tra'
                        : 'Lý do / nội dung cần bổ sung',
                  ),
                ),
                const Text(
                  'Dấu hiệu tương tự và chênh lệch thời gian chỉ để đối chiếu, chưa phải kết luận giả mạo.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Quay lại'),
            ),
            TextButton(
              onPressed: () {
                if ((report || decision != 'valid') &&
                    reason.text.trim().isEmpty) {
                  setDialog(
                    () =>
                        reasonError = 'Nhập lý do hoặc nội dung cần kiểm tra.',
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'reason': reason.text.trim(),
                  if (!report) 'decision': decision,
                });
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    reason.dispose();
    if (body == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await reliefRepository.reviewOrReport(
        report ? 'report' : 'review',
        widget.request,
        body,
      );
      if (!mounted) return;
      showFailure(
        context,
        result['pending'] == true
            ? 'Đã giữ thao tác; chưa được máy chủ xác nhận.'
            : 'Máy chủ đã lưu kết quả.',
      );
      await widget.reload();
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request, v = Map<String, dynamic>.from(r['data']);
    final admin = reliefRepository.account?['role'] == 'admin';
    final rescue = reliefRepository.account?['role'] == 'rescue';
    final labels = {
      'pending': 'Chưa có kết luận xác minh',
      'valid': 'Hợp lệ',
      'needs_info': 'Cần bổ sung thông tin',
      'invalid': 'Không hợp lệ',
    };
    final photos = r['evidence'] as List? ?? [],
        history = [...r['history'] as List? ?? [], ..._olderHistory],
        reports = r['reports'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SyncStatus(),
              if (r['cached'] == true)
                const Text(
                  'Dữ liệu đã lưu trên thiết bị; cần tải lại trước khi thay đổi.',
                ),
              Text('Thông tin xác minh', style: AppTypography.cardTitle),
              const SizedBox(height: 8),
              Text(
                labels[r['verification']] ?? 'Chưa có dữ liệu',
                style: AppTypography.bodyMedium,
              ),
              if ((r['reviewReason'] ?? '').isNotEmpty) Text(r['reviewReason']),
              const SizedBox(height: 8),
              Text(v['description'] ?? ''),
              Text(
                'Người cao tuổi: ${v['elderly']} • Trẻ em: ${v['children']}\nNgười khuyết tật: ${v['disabled']} • Cần chăm sóc đặc biệt: ${v['special']}',
              ),
              if ((v['specialNotes'] ?? '').isNotEmpty) Text(v['specialNotes']),
              Text(
                'Xác nhận vị trí: ${formatTimestamp(v['locationConfirmedAt'], seconds: true)}',
              ),
              Text(
                'Giờ gửi trên thiết bị: ${formatTimestamp(r['clientActionAt'], seconds: true)}',
              ),
              Text(
                'Máy chủ tiếp nhận: ${formatTimestamp(r['receivedAt'], seconds: true)}',
              ),
              if (admin)
                Text(
                  'Chênh lệch thiết bị − máy chủ: ${r['clockDifferenceSeconds']} giây. Có thể do đồng hồ hoặc thời gian chờ mạng.',
                ),
              const SizedBox(height: 12),
              if (photos.isEmpty)
                const Text(
                  'Không đính kèm ảnh. Ảnh là thông tin bổ sung, không bắt buộc.',
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final photo in photos)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RemoteEvidencePreview(
                          key: ValueKey(photo['id']),
                          id: photo['id'],
                        ),
                        Text(
                          formatTimestamp(photo['capturedAt'], seconds: true),
                          style: AppTypography.secondary.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Lịch sử cập nhật'),
                children: [
                  SizedBox(
                    height: history.isEmpty ? 48 : 220,
                    child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final h = history[index];
                        final actions = {
                          'submitted': 'Đã gửi',
                          'updated': 'Đã sửa',
                          'cancelled': 'Đã hủy',
                          'reviewed': 'Đã kiểm tra',
                          'reported': 'Có báo cáo cần xác minh',
                          'fixture_assigned': 'Đã phân công (dữ liệu thử)',
                        };
                        return ListTile(
                          dense: true,
                          title: Text(actions[h['action']] ?? 'Đã cập nhật'),
                          subtitle: Text(
                            '${formatTimestamp(h['at'], seconds: true)}\n${h['details']['reason'] ?? ''}${h['details']['changedFields'] == null ? '' : 'Thông tin đã sửa: ${(h['details']['changedFields'] as List).map((f) => requestFieldLabel(f.toString())).join(', ')}'}',
                          ),
                        );
                      },
                    ),
                  ),
                  if ((_historyStarted
                          ? _historyCursor
                          : r['historyNextCursor']) !=
                      null)
                    TextButton(
                      onPressed: _historyLoading ? null : _moreHistory,
                      child: Text(
                        _historyLoading ? 'Đang tải...' : 'Xem lịch sử cũ hơn',
                      ),
                    ),
                ],
              ),
              if (admin) ...[
                for (final report in reports)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(report['reason']),
                    subtitle: Text(
                      formatTimestamp(report['at'], seconds: true),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _similar = reliefRepository.api.json(
                      'GET',
                      '/requests/${r['id']}/similar',
                    );
                  }),
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Đối chiếu yêu cầu tương tự'),
                ),
                if (_similar != null)
                  FutureBuilder<Json>(
                    future: _similar,
                    builder: (context, result) {
                      if (result.hasError) {
                        return Text(userFacingError(result.error!));
                      }
                      if (!result.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final matches = result.data!['items'] as List;
                      if (matches.isEmpty) {
                        return const Text('Chưa có yêu cầu khác để đối chiếu.');
                      }
                      return Column(
                        children: [
                          Text(
                            'Có ${matches.length} yêu cầu tương tự. Đối chiếu thông tin trước khi kết luận.',
                          ),
                          for (final match in matches)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(match['description']),
                              subtitle: Text(
                                'Mã: ${match['id']}\nCách ${match['distanceMetres']} m • Từ trùng: ${match['sharedWords']} • Nội dung tương tự: ${(match['contentSimilarity'] * 100).round()}%',
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                if (['waiting', 'accepted'].contains(r['stage']))
                  TextButton(
                    onPressed: _busy ? null : () => _decision(),
                    child: Text(
                      _busy ? 'Đang lưu...' : 'Đánh dấu kết quả kiểm tra',
                    ),
                  ),
              ],
              if (rescue)
                TextButton.icon(
                  onPressed: _busy ? null : () => _decision(report: true),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Báo cáo dấu hiệu nghi vấn'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
