import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';
import 'r13_rescue_navigation_route_screen.dart';
import 'r21_complete_task_screen.dart';

class R12AssignedTaskDetailScreen extends StatefulWidget {
  final String taskId;

  const R12AssignedTaskDetailScreen({
    super.key,
    this.taskId = 'TASK-8801',
  });

  @override
  State<R12AssignedTaskDetailScreen> createState() => _R12AssignedTaskDetailScreenState();
}

class _R12AssignedTaskDetailScreenState extends State<R12AssignedTaskDetailScreen> {
  bool _arrivedAtScene = false;

  void _openNavigation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => R13RescueNavigationRouteScreen(
          tasks: [
            {
              'id': widget.taskId,
              'citizen': 'Nguyễn Văn An',
              'phone': '0912 345 678',
              'address': 'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
              'people': 4,
              'needs': '4 người kẹt trên gác xép, nước dâng ngập cổng 1.5m',
              'urgency': 'Khẩn cấp',
              'distance': '1.2 km',
              'gps': '20.8841° N, 105.6215° E',
              'notes': 'Nhà cấp 4 xanh gần đình làng, nước dâng ngập cổng 1.5m',
            }
          ],
        ),
      ),
    );
  }

  void _callCitizen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang kết nối cuộc gọi tới người dân: Nguyễn Văn An (0912 345 678)...')),
    );
  }

  void _reportObstacle() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cảnh báo nguy hiểm trên đường', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gửi cảnh báo tới các đội khác về đoạn đường vừa đi qua:', style: AppTypography.body),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'VD: Dây điện chùng dưới nước, xoáy nước chân cầu...',
                filled: true,
                fillColor: AppColors.canvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Đóng', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã phát tín hiệu cảnh báo nguy hiểm trên bản đồ chung.')),
              );
            },
            child: const Text('Phát cảnh báo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Chi tiết ${widget.taskId}',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.taskId, style: AppTypography.cardTitle.copyWith(color: AppColors.primary)),
                        const StatusChip(status: RequestStatus.inProgress),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '4 người kẹt trên gác xép, nước dâng ngập cổng 1.5m',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text('Tiếp nhận độc quyền bởi: Đội Hương Thủy (4 thành viên)', style: AppTypography.secondary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Citizen contact box
              Text('Thông tin người liên hệ', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.person, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nguyễn Văn An', style: AppTypography.cardTitle),
                              const SizedBox(height: 2),
                              Text('0912 345 678', style: AppTypography.secondaryMedium),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: AppColors.primary, size: 28),
                          onPressed: _callCitizen,
                          tooltip: 'Gọi điện',
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.borderSubtle),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.danger, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ (Gần đình làng, nhà cấp 4 xanh)',
                            style: AppTypography.body,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Route & Distance Card
              Text('Lộ trình & Khoảng cách tiếp cận', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.navigation, color: AppColors.primary, size: 20),
                            const SizedBox(width: 6),
                            Text('Khoảng cách: 1.2 km', style: AppTypography.cardTitle),
                          ],
                        ),
                        Text('Dự kiến: ~8 phút đường thủy', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primaryDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _arrivedAtScene ? 1.0 : 0.65,
                      backgroundColor: AppColors.surfaceContainerLow,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _arrivedAtScene
                          ? 'Đã tiếp cận địa điểm người dân. Bắt đầu phương án cứu hộ.'
                          : 'Đang di chuyển trên đường nhánh thôn Nam Hài. Chú ý dòng nước xiết qua cống tràn.',
                      style: AppTypography.secondary,
                    ),
                    const SizedBox(height: 14),
                    // Navigation CTA right in the route card
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.navigation, size: 22),
                        label: const Text(
                          'Bật dẫn đường đến vị trí này',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _openNavigation,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (!_arrivedAtScene) ...[
                AppButton(
                  text: 'Xác nhận đã đến hiện trường',
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    setState(() => _arrivedAtScene = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật: Đội cứu hộ đã tiếp cận hiện trường!')),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              AppButton(
                text: 'Hoàn thành cứu trợ & Bàn giao',
                icon: Icons.task_alt,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => R21CompleteTaskScreen(taskId: widget.taskId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              AppButton(
                text: 'Báo điểm ngập sâu / Chướng ngại vật',
                icon: Icons.warning_amber_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: _reportObstacle,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
