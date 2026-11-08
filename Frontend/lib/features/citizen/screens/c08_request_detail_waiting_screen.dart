import 'package:flutter/material.dart';

import '../../../core/widgets/status_chip.dart';
import '../../requests/screens/request_detail_screen.dart';

// Giữ chữ ký điều hướng hiện có; chi tiết luôn đọc dữ liệu mới nhất từ kho.
class C08RequestDetailWaitingScreen extends StatelessWidget {
  final String requestId;
  final ReliefStatus initialStatus;
  final String? title, address, urgency;
  final int? people;
  const C08RequestDetailWaitingScreen({
    super.key,
    this.requestId = 'CR-0247',
    this.initialStatus = ReliefStatus.pending,
    this.title,
    this.address,
    this.people,
    this.urgency,
  });
  @override
  Widget build(BuildContext context) =>
      RequestDetailScreen(requestId: requestId);
}
