import 'package:flutter/material.dart';

import '../data/request_store.dart';

/// Báo cáo theo mã, không mở ảnh hoặc dữ liệu riêng của chủ yêu cầu khác.
class ReportRequestDialog extends StatefulWidget {
  const ReportRequestDialog({super.key});
  @override
  State<ReportRequestDialog> createState() => _ReportRequestDialogState();
}

class _ReportRequestDialogState extends State<ReportRequestDialog> {
  final _id = TextEditingController(), _reason = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _id.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await RequestStore.instance.report(
        _id.text.trim().toUpperCase(),
        _reason.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Báo cáo yêu cầu nghi giả mạo'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nhập mã yêu cầu bạn muốn báo cáo. Báo cáo được lưu để quản trị kiểm tra, chưa phải kết luận giả mạo.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _id,
            enabled: !_busy,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Mã yêu cầu (ví dụ CR-0251)',
            ),
          ),
          TextField(
            controller: _reason,
            enabled: !_busy,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Lý do và dấu hiệu quan sát được',
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed: _busy ? null : _send,
        child: const Text('Gửi báo cáo'),
      ),
    ],
  );
}
