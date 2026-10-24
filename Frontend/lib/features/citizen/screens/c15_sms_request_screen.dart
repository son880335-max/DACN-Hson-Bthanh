import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';

class C15SmsRequestScreen extends StatefulWidget {
  const C15SmsRequestScreen({super.key});

  @override
  State<C15SmsRequestScreen> createState() => _C15SmsRequestScreenState();
}

class _C15SmsRequestScreenState extends State<C15SmsRequestScreen> {
  String _urgencyCode = 'KC'; // KC: Khẩn cấp, HT: Cần hỗ trợ
  int _peopleCount = 4;
  final _addressController = TextEditingController(text: 'So 42 Nam Hai, Nam Phuong Tien, Chuong My');
  final _needsController = TextEditingController(text: 'SO TAN, NUOC UONG, LUONG THUC');
  final String _destNumber = '0912 000 114';

  String get _generatedSmsBody {
    return 'CUUTRO $_urgencyCode $_peopleCount ${_addressController.text.trim()} ${_needsController.text.trim()}';
  }

  void _sendSms() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Đang mở ứng dụng tin nhắn với nội dung: "$_generatedSmsBody" tới số $_destNumber'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Cứu trợ bằng SMS (Ngoại tuyến)',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.signal_cellular_connected_no_internet_4_bar, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tính năng cứu trợ khi mất Internet', style: AppTypography.cardTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Khi bão lũ làm đứt cáp quang hoặc mất trạm phát sóng 3G/4G, hệ thống sẽ tự động chuyển cú pháp sang tin nhắn SMS chuẩn gửi trực tiếp về Ban điều phối cứu trợ.',
                            style: AppTypography.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form fields
              Text('Mức độ khẩn cấp', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Cực kỳ khẩn cấp (KC)', style: AppTypography.bodyMedium),
                      value: 'KC',
                      groupValue: _urgencyCode,
                      activeColor: AppColors.danger,
                      onChanged: (val) => setState(() => _urgencyCode = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Cần cứu trợ (HT)', style: AppTypography.bodyMedium),
                      value: 'HT',
                      groupValue: _urgencyCode,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _urgencyCode = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text('Số lượng người cần cứu', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.primary),
                    onPressed: () {
                      if (_peopleCount > 1) {
                        setState(() => _peopleCount--);
                      }
                    },
                  ),
                  Text('$_peopleCount người', style: AppTypography.cardTitle),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
                    onPressed: () {
                      if (_peopleCount < 30) {
                        setState(() => _peopleCount++);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text('Địa chỉ & Điểm mốc (Viết không dấu)', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                style: AppTypography.body,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              Text('Nhu cầu cụ thể', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              TextField(
                controller: _needsController,
                style: AppTypography.body,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Preview SMS Card
              Text('Xem trước nội dung SMS', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Gửi tới tổng đài: $_destNumber', style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryDark)),
                        const Icon(Icons.sms, color: AppColors.primaryDark),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    SelectableText(
                      _generatedSmsBody,
                      style: AppTypography.bodyMedium.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit SMS button
              AppButton(
                text: 'Mở ứng dụng Tin nhắn (SMS) để gửi',
                icon: Icons.send,
                onPressed: _sendSms,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
