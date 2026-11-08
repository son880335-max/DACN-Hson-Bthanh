import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/widgets/sync_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';

class A04OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String userRole; // 'citizen' or 'rescue'
  final String nextAction; // 'register' or 'forgot_password'

  const A04OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.userRole = 'citizen',
    this.nextAction = 'register',
  });

  @override
  State<A04OtpVerificationScreen> createState() =>
      _A04OtpVerificationScreenState();
}

class _A04OtpVerificationScreenState extends State<A04OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final int _countdown = 0;
  Timer? _timer;
  final bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    try {
      await reliefRepository.api.json(
        'POST',
        '/auth/verify',
        body: {
          'phone': widget.phoneNumber,
          'otp': _otpControllers.map((c) => c.text).join(),
        },
      );
      if (mounted) {
        showFailure(
          context,
          'Hiện chưa thể xác minh số điện thoại. Tài khoản chưa được tạo.',
        );
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Xác minh số điện thoại',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nhập mã xác minh',
                  style: AppTypography.pageTitle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hiện chưa gửi được mã xác minh qua SMS đến số:',
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phoneNumber,
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 24),

                // 6 OTP Digit input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 46,
                      height: 56,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: AppTypography.pageTitle.copyWith(fontSize: 22),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (val.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Resend Countdown
                if (_countdown > 0)
                  Text(
                    'Gửi lại mã sau $_countdown giây',
                    style: AppTypography.secondaryMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => showFailure(
                      context,
                      'Hiện chưa gửi được mã xác minh. Hãy thử lại sau.',
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Gửi lại mã'),
                  ),
                const SizedBox(height: 24),

                // Verify Button
                AppButton(
                  text: 'Xác nhận',
                  isLoading: _isVerifying,
                  onPressed: _verifyOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
