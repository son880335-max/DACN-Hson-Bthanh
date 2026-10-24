import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../citizen/screens/citizen_shell_screen.dart';
import '../../rescue/screens/rescue_shell_screen.dart';

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
  State<A04OtpVerificationScreen> createState() => _A04OtpVerificationScreenState();
}

class _A04OtpVerificationScreenState extends State<A04OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _countdown = 60;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
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

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số mã xác thực OTP.')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isVerifying = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                const SizedBox(width: 8),
                Text('Xác thực thành công!', style: AppTypography.cardTitle),
              ],
            ),
            content: Text(
              widget.userRole == 'rescue'
                  ? 'Hồ sơ đăng ký của đội đã được tiếp nhận và xác thực số điện thoại. Ban điều phối sẽ thẩm định minh chứng trong vòng 1-2 giờ.'
                  : 'Tài khoản của bạn đã được kích hoạt thành công.',
              style: AppTypography.body,
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (widget.userRole == 'rescue') {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const RescueShellScreen()),
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const CitizenShellScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Bắt đầu sử dụng'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Xác thực OTP',
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
                  child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 16),
                Text('Nhập mã xác thực', style: AppTypography.pageTitle.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  'Mã xác thực gồm 6 chữ số đã được gửi qua tin nhắn SMS tới số điện thoại:',
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phoneNumber,
                  style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDark),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    style: AppTypography.secondaryMedium.copyWith(color: AppColors.textSecondary),
                  )
                else
                  TextButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Gửi lại mã OTP'),
                  ),
                const SizedBox(height: 24),

                // Verify Button
                AppButton(
                  text: 'Xác nhận & Kích hoạt tài khoản',
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
