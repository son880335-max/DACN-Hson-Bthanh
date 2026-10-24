import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../auth/screens/a01_role_selection_screen.dart';
import '../../auth/screens/a06_change_password_screen.dart';

class C20ProfileScreen extends StatefulWidget {
  const C20ProfileScreen({super.key});

  @override
  State<C20ProfileScreen> createState() => _C20ProfileScreenState();
}

class _C20ProfileScreenState extends State<C20ProfileScreen> {
  bool _floodAlertsEnabled = true;
  bool _smsFallbackEnabled = true;

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Đăng xuất tài khoản', style: AppTypography.cardTitle),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?', style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.onDanger,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const A01RoleSelectionScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(
        title: 'Tài khoản cá nhân',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'AN',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nguyễn Văn An', style: AppTypography.cardTitle),
                          const SizedBox(height: 4),
                          Text('0912 345 678', style: AppTypography.secondaryMedium),
                          const SizedBox(height: 4),
                          Text('Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
                              style: AppTypography.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Group 1
              Text('Cài đặt thông báo & cảnh báo lũ', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Nhận cảnh báo mực nước lũ', style: AppTypography.bodyMedium),
                      subtitle: Text('Thông báo khi có báo động lũ cấp 2, cấp 3 trên sông', style: AppTypography.secondary),
                      value: _floodAlertsEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _floodAlertsEnabled = val),
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    SwitchListTile(
                      title: Text('Tự động chuyển chế độ SMS', style: AppTypography.bodyMedium),
                      subtitle: Text('Gửi tin nhắn khi mất kết nối mạng 3G/4G', style: AppTypography.secondary),
                      value: _smsFallbackEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _smsFallbackEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Group 2: Account actions
              Text('Hỗ trợ & Thông tin', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: AppColors.primary),
                      title: Text('Hướng dẫn kỹ năng an toàn mùa lũ', style: AppTypography.bodyMedium),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mở cẩm nang hướng dẫn phòng chống lũ lụt...')),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                      title: Text('Đổi mật khẩu tài khoản', style: AppTypography.bodyMedium),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const A06ChangePasswordScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.danger),
                      title: Text('Đăng xuất tài khoản', style: AppTypography.bodyMedium.copyWith(color: AppColors.danger)),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Version footer
              Center(
                child: Column(
                  children: [
                    Text('Ứng dụng Cứu trợ đồng bào lũ lụt', style: AppTypography.secondaryMedium),
                    const SizedBox(height: 2),
                    Text('Phiên bản 1.0.0', style: AppTypography.secondary.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
