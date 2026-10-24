import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';
import 'm03_admin_requests_lookup_screen.dart';

class M02AdminDashboardScreen extends StatelessWidget {
  const M02AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(
        title: 'Tổng quan điều phối cứu trợ',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-time river alert
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dangerContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.danger, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Báo động lũ cấp 3 - Sông Bùi', style: AppTypography.cardTitle.copyWith(color: AppColors.danger)),
                          const SizedBox(height: 2),
                          Text('Mực nước hiện tại vượt báo động 3: +0.45m. Ưu tiên sơ tán các xã vùng trũng.', style: AppTypography.secondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Stats Grid
              Text('Chỉ số vận hành toàn hệ thống', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Khẩn cấp đỏ',
                      value: '18',
                      sub: 'Cần xuồng cứu nạn',
                      color: AppColors.danger,
                      bgColor: AppColors.dangerContainer,
                      icon: Icons.priority_high,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Đang ứng cứu',
                      value: '42',
                      sub: 'Đội đang tiếp cận',
                      color: AppColors.primary,
                      bgColor: AppColors.primaryContainer,
                      icon: Icons.directions_boat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Đã hoàn thành',
                      value: '156',
                      sub: '520 người đã an toàn',
                      color: AppColors.success,
                      bgColor: AppColors.successContainer,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Lực lượng túc trực',
                      value: '24',
                      sub: 'Đội thuyền & ca nô',
                      color: AppColors.primaryDark,
                      bgColor: AppColors.surfaceContainerLow,
                      icon: Icons.groups,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Urgent requests section
              Row(
                children: [
                  Expanded(
                    child: Text('Yêu cầu cấp bách cần điều phối', style: AppTypography.sectionTitle),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const M03AdminRequestsLookupScreen()),
                      );
                    },
                    child: Text('Xem tất cả', style: AppTypography.button.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2 Sample Urgent Items
              _buildUrgentItem(
                context,
                id: 'CR-0247',
                title: '4 người kẹt trên gác xép, nước ngập 1.5m',
                address: 'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
                urgency: 'Cực kỳ khẩn cấp',
              ),
              const SizedBox(height: 10),
              _buildUrgentItem(
                context,
                id: 'CR-0251',
                title: 'Cần ca nô chuyển cấp cứu sản phụ',
                address: 'Thôn Nhân Lý, Xã Nam Phương Tiến',
                urgency: 'Cực kỳ khẩn cấp',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.secondaryMedium.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.pageTitle.copyWith(color: color, fontSize: 32)),
          const SizedBox(height: 4),
          Text(sub, style: AppTypography.secondary.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUrgentItem(
    BuildContext context, {
    required String id,
    required String title,
    required String address,
    required String urgency,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: AppTypography.cardTitle.copyWith(color: AppColors.danger)),
              const StatusChip(status: RequestStatus.waiting),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: AppTypography.bodyMedium),
          const SizedBox(height: 4),
          Text(address, style: AppTypography.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          AppButton(
            text: 'Điều phối đội cứu trợ ngay',
            icon: Icons.send_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang mở màn hình phân công đội cho $id...')),
              );
            },
          ),
        ],
      ),
    );
  }
}
