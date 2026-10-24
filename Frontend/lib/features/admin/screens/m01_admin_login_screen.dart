import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../admin/screens/admin_shell_screen.dart';

class M01AdminLoginScreen extends StatefulWidget {
  const M01AdminLoginScreen({super.key});

  @override
  State<M01AdminLoginScreen> createState() => _M01AdminLoginScreenState();
}

class _M01AdminLoginScreenState extends State<M01AdminLoginScreen> {
  final _adminAccountController = TextEditingController(text: 'admin_dieupoi');
  final _passwordController = TextEditingController(text: 'admin@123');
  bool _isLoading = false;

  void _login() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminShellScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(title: 'Đăng nhập Quản trị viên'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text('Không gian Quản trị viên', style: AppTypography.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Dành cho điều phối viên hệ thống cứu trợ và xét duyệt đội',
                        style: AppTypography.secondary,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tài khoản quản trị', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _adminAccountController,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge, color: AppColors.textSecondary),
                    hintText: 'Nhập tên tài khoản quản trị',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Mật khẩu', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    hintText: 'Nhập mật khẩu',
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Đăng nhập hệ thống điều phối',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 14),
                AppButton(
                  text: 'Xem nhanh tổng quan điều phối',
                  type: AppButtonType.outlined,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AdminShellScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
