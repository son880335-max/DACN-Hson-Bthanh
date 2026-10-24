import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../citizen/screens/citizen_shell_screen.dart';
import 'a03_citizen_register_screen.dart';
import 'a05_forgot_password_screen.dart';

class A02CitizenLoginScreen extends StatefulWidget {
  const A02CitizenLoginScreen({super.key});

  @override
  State<A02CitizenLoginScreen> createState() => _A02CitizenLoginScreenState();
}

class _A02CitizenLoginScreenState extends State<A02CitizenLoginScreen> {
  final _phoneController = TextEditingController(text: '0912345678');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _login() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CitizenShellScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(title: 'Đăng nhập Người dân'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
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
                        child: Icon(Icons.person, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text('Tài khoản Người dân', style: AppTypography.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Đăng nhập bằng số điện thoại để gửi yêu cầu và theo dõi tiến độ cứu trợ',
                        style: AppTypography.secondary,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Phone Input
                Text('Số điện thoại liên hệ', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_android, color: AppColors.textSecondary),
                    hintText: 'Nhập số điện thoại (ví dụ: 0912345678)',
                  ),
                ),

                const SizedBox(height: 16),

                // Password Input
                Text('Mật khẩu', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    hintText: 'Nhập mật khẩu',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const A05ForgotPasswordScreen()),
                      );
                    },
                    child: Text('Quên mật khẩu?', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary)),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Button
                AppButton(
                  text: 'Đăng nhập',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),

                const SizedBox(height: 12),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tài khoản? ', style: AppTypography.secondary),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const A03CitizenRegisterScreen()),
                        );
                      },
                      child: Text('Đăng ký ngay', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Quick guest entrance
                AppButton(
                  text: 'Trải nghiệm không cần đăng nhập',
                  type: AppButtonType.outlined,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const CitizenShellScreen()),
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
