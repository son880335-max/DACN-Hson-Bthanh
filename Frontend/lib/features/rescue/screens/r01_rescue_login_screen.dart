import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/sync_status.dart';
import '../../auth/screens/a05_forgot_password_screen.dart';
import '../../auth/screens/r02_rescue_register_screen.dart';
import '../../rescue/screens/rescue_shell_screen.dart';

class R01RescueLoginScreen extends StatefulWidget {
  const R01RescueLoginScreen({super.key});

  @override
  State<R01RescueLoginScreen> createState() => _R01RescueLoginScreenState();
}

class _R01RescueLoginScreenState extends State<R01RescueLoginScreen> {
  final _teamIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await reliefRepository.login(
        _teamIdController.text,
        _passwordController.text,
        'rescue',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RescueShellScreen()),
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
    _teamIdController.dispose();
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
                          Icons.directions_boat,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Đội cứu hộ', style: AppTypography.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Dùng tài khoản của đội đã được duyệt.',
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
                  controller: _teamIdController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.group,
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
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const A05ForgotPasswordScreen(userRole: 'rescue'),
                        ),
                      );
                    },
                    child: Text(
                      'Quên mật khẩu?',
                      style: AppTypography.secondary.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                AppButton(
                  text: 'Đăng nhập',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),

                // Register and Forgot password links
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Text('Chưa có tài khoản?', style: AppTypography.secondary),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const R02RescueRegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Đăng ký đội cứu hộ',
                        style: AppTypography.secondaryMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
