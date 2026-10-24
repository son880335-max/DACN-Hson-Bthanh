import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../auth/screens/a05_forgot_password_screen.dart';
import '../../auth/screens/r02_rescue_register_screen.dart';
import '../../rescue/screens/rescue_shell_screen.dart';

class R01RescueLoginScreen extends StatefulWidget {
  const R01RescueLoginScreen({super.key});

  @override
  State<R01RescueLoginScreen> createState() => _R01RescueLoginScreenState();
}

class _R01RescueLoginScreenState extends State<R01RescueLoginScreen> {
  final _teamIdController = TextEditingController(text: 'TEAM-HƯƠNG THỦY');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;

  void _login() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RescueShellScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(title: 'Đăng nhập Đội cứu hộ'),
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
                        child: Icon(Icons.directions_boat, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text('Tài khoản Đội cứu hộ', style: AppTypography.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Dành cho các đội cứu hộ đã được xét duyệt năng lực và phương tiện',
                        style: AppTypography.secondary,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text('Tên đội hoặc mã định danh', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _teamIdController,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.group, color: AppColors.textSecondary),
                    hintText: 'Nhập tên đội hoặc mã định danh',
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
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const A05ForgotPasswordScreen(userRole: 'rescue'),
                        ),
                      );
                    },
                    child: Text('Quên mật khẩu?', style: AppTypography.secondary.copyWith(color: AppColors.primary)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const R02RescueRegisterScreen()),
                        );
                      },
                      child: Text('Đăng ký đội', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                AppButton(
                  text: 'Dùng thử không cần đăng nhập',
                  type: AppButtonType.outlined,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const RescueShellScreen()),
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
