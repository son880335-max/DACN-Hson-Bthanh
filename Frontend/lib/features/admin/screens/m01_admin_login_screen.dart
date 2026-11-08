import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/sync_status.dart';
import '../../admin/screens/admin_shell_screen.dart';

class M01AdminLoginScreen extends StatefulWidget {
  const M01AdminLoginScreen({super.key});

  @override
  State<M01AdminLoginScreen> createState() => _M01AdminLoginScreenState();
}

class _M01AdminLoginScreenState extends State<M01AdminLoginScreen> {
  final _adminAccountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await reliefRepository.login(
        _adminAccountController.text,
        _passwordController.text,
        'admin',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminShellScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _adminAccountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(title: 'Đăng nhập'),
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
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Quản trị viên', style: AppTypography.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Dùng tài khoản quản trị viên đã được cấp.',
                        style: AppTypography.secondary,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Số điện thoại', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _adminAccountController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.badge,
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Nhập số điện thoại đã đăng ký',
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
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Nhập mật khẩu',
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Đăng nhập',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
