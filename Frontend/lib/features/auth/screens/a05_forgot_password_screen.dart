import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'a04_otp_verification_screen.dart';

class A05ForgotPasswordScreen extends StatefulWidget {
  final String userRole; // 'citizen' or 'rescue'

  const A05ForgotPasswordScreen({
    super.key,
    this.userRole = 'citizen',
  });

  @override
  State<A05ForgotPasswordScreen> createState() => _A05ForgotPasswordScreenState();
}

class _A05ForgotPasswordScreenState extends State<A05ForgotPasswordScreen> {
  final _phoneController = TextEditingController();

  void _sendOtp() {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại đã đăng ký.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => A04OtpVerificationScreen(
          phoneNumber: _phoneController.text.trim(),
          userRole: widget.userRole,
          nextAction: 'forgot_password',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRescue = widget.userRole == 'rescue';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: isRescue ? 'Khôi phục mật khẩu Đội cứu hộ' : 'Khôi phục mật khẩu',
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.lock_reset, color: AppColors.primaryDark, size: 32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text('Quên mật khẩu?', style: AppTypography.cardTitle),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRescue
                            ? 'Nhập số điện thoại trưởng đội đã dùng để đăng ký. Hệ thống sẽ gửi mã OTP để đặt lại mật khẩu.'
                            : 'Nhập số điện thoại đã dùng để đăng ký tài khoản. Hệ thống sẽ gửi mã OTP để bạn đặt lại mật khẩu mới.',
                        textAlign: TextAlign.center,
                        style: AppTypography.secondary,
                      ),
                      const SizedBox(height: 20),

                      Text('Số điện thoại', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.body,
                        decoration: InputDecoration(
                          hintText: isRescue ? 'Nhập số điện thoại trưởng đội' : 'Nhập số điện thoại của bạn',
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),

                      AppButton(
                        text: 'Gửi mã xác thực OTP',
                        icon: Icons.send,
                        onPressed: _sendOtp,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Quay lại đăng nhập'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
