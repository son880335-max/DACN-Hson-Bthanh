import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../auth/screens/a01_role_selection_screen.dart';

class M19AdminStatisticsScreen extends StatelessWidget {
  const M19AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(
        title: 'Báo cáo thống kê cứu trợ',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top total impact box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng số người dân đã sơ tán an toàn',
                        style: AppTypography.cardTitle.copyWith(color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 8),
                    Text('684 người', style: AppTypography.pageTitle.copyWith(color: Colors.white, fontSize: 36)),
                    const SizedBox(height: 8),
                    Text('Gồm: 142 trẻ em • 185 người cao tuổi • 357 người lớn',
                        style: AppTypography.secondary.copyWith(color: Colors.white.withOpacity(0.85))),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Breakdown cards
              Text('Hàng hóa & Nhu yếu phẩm đã cấp phát', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Nước uống đóng chai (20L / bình)', '1,420 bình', '100% nhu cầu thiết yếu'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildStatRow('Lương khô & Mì ăn liền', '2,100 thùng', 'Đủ dự trữ 5-7 ngày'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildStatRow('Áo phao & Thiết bị nổi', '580 chiếc', 'Đã cấp cho hộ ven sông'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildStatRow('Túi thuốc gia đình & Sát trùng', '340 bộ', 'Hạn chế dịch bệnh sau lũ'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rescue Teams distribution
              Text('Phân bổ lực lượng cứu hộ', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildTeamDistrictRow('Xã Nam Phương Tiến (Tâm lũ)', '10 đội', '22 xuồng máy'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildTeamDistrictRow('Xã Tân Tiến', '8 đội', '15 xuồng máy'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildTeamDistrictRow('Xã Hoàng Văn Thụ', '6 đội', '10 xuồng máy'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Export button
              AppButton(
                text: 'Xuất báo cáo PDF / Excel',
                icon: Icons.file_download_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang tạo báo cáo thống kê tình hình cứu trợ (PDF)...')),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Logout
              AppButton(
                text: 'Đăng xuất tài khoản Quản trị',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const A01RoleSelectionScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String name, String qty, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.bodyMedium),
              Text(desc, style: AppTypography.secondary.copyWith(fontSize: 12)),
            ],
          ),
        ),
        Text(qty, style: AppTypography.cardTitle.copyWith(color: AppColors.primary)),
      ],
    );
  }

  Widget _buildTeamDistrictRow(String district, String teams, String boats) {
    return Row(
      children: [
        Expanded(
          child: Text(
            district,
            style: AppTypography.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$teams • $boats',
          style: AppTypography.secondaryMedium.copyWith(color: AppColors.primaryDark),
        ),
      ],
    );
  }
}
