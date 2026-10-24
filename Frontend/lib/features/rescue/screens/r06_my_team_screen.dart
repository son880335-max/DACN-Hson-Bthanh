import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../auth/screens/a01_role_selection_screen.dart';
import '../../auth/screens/a06_change_password_screen.dart';

class R06MyTeamScreen extends StatefulWidget {
  const R06MyTeamScreen({super.key});

  @override
  State<R06MyTeamScreen> createState() => _R06MyTeamScreenState();
}

class _R06MyTeamScreenState extends State<R06MyTeamScreen> {
  bool _isReady = true;

  final List<Map<String, String>> _members = [
    {'name': 'Lê Văn Bình', 'role': 'Đội trưởng • Lái xuồng máy', 'phone': '0983 234 567'},
    {'name': 'Nguyễn Hoàng Long', 'role': 'Cứu hộ viên • Sơ cấp cứu', 'phone': '0977 112 233'},
    {'name': 'Trần Đình Trọng', 'role': 'Cứu hộ viên • Hậu cần', 'phone': '0915 443 221'},
    {'name': 'Phạm Hải Nam', 'role': 'Cứu hộ viên • Liên lạc đàm', 'phone': '0904 887 665'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(
        title: 'Đội của tôi',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Overview Card
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
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.directions_boat, color: AppColors.primaryDark, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Đội Cứu trợ Hương Thủy', style: AppTypography.cardTitle),
                              const SizedBox(height: 2),
                              Text('Mã đội: TEAM-HT-01 • Đã kiểm duyệt',
                                  style: AppTypography.secondaryMedium.copyWith(color: AppColors.primaryDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.borderSubtle),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Trạng thái sẵn sàng ứng cứu', style: AppTypography.bodyMedium),
                      subtitle: Text(
                        _isReady ? 'Đang bật nhận nhiệm vụ trên bản đồ' : 'Tạm dừng nhận nhiệm vụ để tiếp nhiên liệu',
                        style: AppTypography.secondary,
                      ),
                      value: _isReady,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isReady = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Equipment Card
              Text('Phương tiện & Trang thiết bị', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildEquipmentItem(Icons.sailing, '02 Thuyền hơi cao su gắn máy', 'Công suất 15HP, tải trọng 6 người/thuyền'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildEquipmentItem(Icons.local_shipping, '01 Xe bán tải hỗ trợ kéo thuyền', 'Túc trực tại bờ đê Nam Phương Tiến'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildEquipmentItem(Icons.security, '12 Áo phao cứu sinh chuẩn', 'Kèm 02 phao tròn & 02 túi y tế kháng nước'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Members List
              Text('Danh sách thành viên (${_members.length})', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.surfaceContainerLow,
                          child: Text('${index + 1}', style: AppTypography.bodyMedium),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['name']!, style: AppTypography.bodyMedium),
                              Text(member['role']!, style: AppTypography.secondary.copyWith(fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(member['phone']!, style: AppTypography.secondaryMedium),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Actions
              AppButton(
                text: 'Đổi mật khẩu tài khoản',
                icon: Icons.lock_outline,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const A06ChangePasswordScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Logout Button
              AppButton(
                text: 'Đăng xuất đội cứu hộ',
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

  Widget _buildEquipmentItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.secondary),
            ],
          ),
        ),
      ],
    );
  }
}
