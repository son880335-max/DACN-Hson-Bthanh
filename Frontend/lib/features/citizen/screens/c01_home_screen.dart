import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../requests/widgets/request_home_panel.dart';
import 'c02_request_wizard_step1_screen.dart';
import 'c15_sms_request_screen.dart';

class C01HomeScreen extends StatelessWidget {
  const C01HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Cứu trợ lũ lụt',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, size: 26, color: AppColors.textPrimary),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '2',
                      style: AppTypography.button.copyWith(fontSize: 10, height: 1),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bạn có 2 thông báo cứu trợ mới.')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Salutation Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trang chủ cứu trợ',
                              style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tiếp nhận yêu cầu hỗ trợ',
                              style: AppTypography.sectionTitle,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Offline Network Warning Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.wifi_off, color: AppColors.warning, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chế độ cứu trợ ngoại tuyến',
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 17,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Khi mất sóng Internet, bạn có thể gửi tin nhắn SMS cứu trợ trực tiếp từ điện thoại để chuyển tới lực lượng cứu nạn gần nhất.',
                                  style: AppTypography.secondary.copyWith(
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Chưa kết nối Internet',
                            style: AppTypography.secondary.copyWith(fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const C15SmsRequestScreen()),
                              );
                            },
                            icon: const Icon(Icons.sms, size: 18),
                            label: const Text('Chuyển sang SMS'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: const BorderSide(color: AppColors.warning),
                              minimumSize: const Size(48, 48),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Primary Emergency Trigger Button (Min 56dp height, Deep River Teal, High Contrast) US-021
                AppButton(
                  text: 'Gửi yêu cầu cứu trợ',
                  icon: Icons.sos,
                  onPressed: () => _handleCreateRequest(context),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Chỉ sử dụng khi người thân đang nguy hiểm hoặc thiếu lương thực/nước sạch.',
                          style: AppTypography.secondary.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const RequestHomePanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCreateRequest(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const C02RequestWizardStep1Screen()));
  }
}
