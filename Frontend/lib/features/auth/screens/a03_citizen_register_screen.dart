import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'a04_otp_verification_screen.dart';

class A03CitizenRegisterScreen extends StatefulWidget {
  const A03CitizenRegisterScreen({super.key});

  @override
  State<A03CitizenRegisterScreen> createState() => _A03CitizenRegisterScreenState();
}

class _A03CitizenRegisterScreenState extends State<A03CitizenRegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  bool _obscurePassword = true;

  void _proceedToOtp() {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ họ tên, số điện thoại và mật khẩu.')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => A04OtpVerificationScreen(
          phoneNumber: _phoneController.text.trim(),
          userRole: 'citizen',
          nextAction: 'register',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Đăng ký tài khoản Người dân',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin cá nhân', style: AppTypography.cardTitle),
                      const SizedBox(height: 14),

                      Text('Họ và tên', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'VD: Nguyễn Văn An',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Số điện thoại liên hệ', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'VD: 0912 345 678',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Địa chỉ / Nơi cư trú', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressController,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'Thôn/Xã, Huyện Chương Mỹ...',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Mật khẩu', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTypography.body,
                        decoration: InputDecoration(
                          hintText: 'Tối thiểu 6 ký tự',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Xác nhận mật khẩu', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'Nhập lại mật khẩu vừa đặt',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 24),

                      AppButton(
                        text: 'Tiếp tục & Xác thực OTP',
                        icon: Icons.arrow_forward,
                        onPressed: _proceedToOtp,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Đã có tài khoản? ', style: AppTypography.secondary),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Đăng nhập ngay', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary)),
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
