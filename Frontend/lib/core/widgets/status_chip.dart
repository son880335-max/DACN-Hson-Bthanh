import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum ReliefStatus {
  pending,      // Chờ tiếp nhận
  assigned,     // Đã phân công / tiếp nhận
  inTransit,    // Đang di chuyển
  arrived,      // Đã đến nơi
  completed,    // Đã hoàn thành
  cancelled,    // Đã hủy
  needsInfo,    // Cần bổ sung thông tin
  waiting,      // Alias for pending
  inProgress,   // Alias for inTransit
}

typedef RequestStatus = ReliefStatus;

class StatusChip extends StatelessWidget {
  final ReliefStatus status;
  final String? customLabel;

  const StatusChip({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    IconData icon;
    String label;

    switch (status) {
      case ReliefStatus.pending:
      case ReliefStatus.waiting:
        bg = AppColors.warningContainer;
        fg = AppColors.warning;
        border = AppColors.warningBorder;
        icon = Icons.hourglass_top;
        label = customLabel ?? 'Chờ tiếp nhận';
        break;
      case ReliefStatus.assigned:
        bg = AppColors.primaryContainer;
        fg = AppColors.primary;
        border = AppColors.primary;
        icon = Icons.assignment_turned_in;
        label = customLabel ?? 'Đã tiếp nhận';
        break;
      case ReliefStatus.inTransit:
      case ReliefStatus.inProgress:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        border = const Color(0xFF7DD3FC);
        icon = Icons.directions_boat;
        label = customLabel ?? 'Đang di chuyển';
        break;
      case ReliefStatus.arrived:
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        border = const Color(0xFFD8B4FE);
        icon = Icons.pin_drop;
        label = customLabel ?? 'Đã đến nơi';
        break;
      case ReliefStatus.completed:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        border = const Color(0xFF86EFAC);
        icon = Icons.check_circle;
        label = customLabel ?? 'Đã hoàn thành';
        break;
      case ReliefStatus.cancelled:
        bg = AppColors.dangerContainer;
        fg = AppColors.danger;
        border = const Color(0xFFFCA5A5);
        icon = Icons.cancel;
        label = customLabel ?? 'Đã hủy';
        break;
      case ReliefStatus.needsInfo:
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFC2410C);
        border = const Color(0xFFFDBA74);
        icon = Icons.info;
        label = customLabel ?? 'Cần bổ sung';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.chip.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
