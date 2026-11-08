import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/widgets/sync_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';

class A05ForgotPasswordScreen extends StatefulWidget {
  final String userRole; // 'citizen' or 'rescue'

  const A05ForgotPasswordScreen({super.key, this.userRole = 'citizen'});

  @override
  State<A05ForgotPasswordScreen> createState() =>
      _A05ForgotPasswordScreenState();
}

class _A05ForgotPasswordScreenState extends State<A05ForgotPasswordScreen> {
  final _phoneController = TextEditingController();

  Future<void> _sendOtp() async {
    try {
      await reliefRepository.api.json(
        'POST',
        '/auth/recovery',
        body: {'phone': _phoneController.text.trim()},
      );
      if (mounted) {
        showFailure(
          context,
          'Hiện chưa gửi được mã xác minh. Mật khẩu của bạn chưa thay đổi.',
        );
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRescue = widget.userRole == 'rescue';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: isRescue ? 'Quên mật khẩu' : 'Quên mật khẩu',
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
                          child: Icon(
                            Icons.lock_reset,
                            color: AppColors.primaryDark,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Quên mật khẩu?',
                          style: AppTypography.cardTitle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRescue
                            ? 'Nhập số điện thoại đã đăng ký cho đội. Hiện chưa thể gửi mã xác minh qua SMS.'
                            : 'Nhập số điện thoại đã đăng ký. Hiện chưa thể gửi mã xác minh qua SMS.',
                        textAlign: TextAlign.center,
                        style: AppTypography.secondary,
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Số điện thoại',
                        style: AppTypography.secondaryMedium,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.body,
                        decoration: InputDecoration(
                          hintText: isRescue
                              ? 'Nhập số điện thoại đã đăng ký'
                              : 'Nhập số điện thoại của bạn',
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),

                      AppButton(
                        text: 'Gửi mã xác minh',
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
