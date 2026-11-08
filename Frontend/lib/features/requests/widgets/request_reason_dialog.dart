import 'package:flutter/material.dart';

import '../data/relief_request.dart';

class RequestReasonDialog extends StatefulWidget {
  final Verification? decision;
  const RequestReasonDialog({super.key, this.decision});
  @override
  State<RequestReasonDialog> createState() => _RequestReasonDialogState();
}

class _RequestReasonDialogState extends State<RequestReasonDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(
      widget.decision == null
          ? 'Báo cáo dấu hiệu giả mạo'
          : verificationLabel(widget.decision!),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.decision == null
              ? 'Báo cáo được lưu để quản trị kiểm tra. Báo cáo không tự kết luận yêu cầu là giả mạo.'
              : 'Kết quả được lưu vào lịch sử và thông báo cho chủ yêu cầu.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLength: 1000,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: widget.decision == Verification.valid
                ? 'Ghi chú (không bắt buộc)'
                : 'Lý do / nội dung cần bổ sung',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed:
            widget.decision == Verification.valid ||
                _controller.text.trim().isNotEmpty
            ? () => Navigator.pop(context, _controller.text.trim())
            : null,
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
