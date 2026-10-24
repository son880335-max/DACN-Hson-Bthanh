import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';
import 'c02_request_wizard_step1_screen.dart';
import 'c08_request_detail_waiting_screen.dart';
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

                // Active Ongoing Request Section (CR-0247)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  children: [
                                    Text(
                                      'Yêu cầu #CR-0247',
                                      style: AppTypography.cardTitle,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('09:15', style: AppTypography.secondary.copyWith(fontSize: 13)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Xã Nam Phương Tiến, Chương Mỹ',
                                        style: AppTypography.secondary,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const StatusChip(status: ReliefStatus.pending),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.borderSubtle),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chi tiết ghi nhận:', style: AppTypography.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              '3 người lớn, 1 trẻ sơ sinh. Nước ngập ngang hiên nhà, cạn kiệt đồ ăn.',
                              style: AppTypography.body,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Đang xếp hàng phân công đội cứu hộ',
                              style: AppTypography.secondary.copyWith(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const C08RequestDetailWaitingScreen(requestId: 'CR-0247'),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                            child: Text(
                              'Xem chi tiết',
                              style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Saved Draft Recovery (US-021)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bản nháp yêu cầu cứu trợ', style: AppTypography.cardTitle.copyWith(fontSize: 17)),
                            Text('Tự động lưu lúc 08:30 (chưa gửi)', style: AppTypography.secondary.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const C02RequestWizardStep1Screen(isDraft: true)),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('Tiếp tục'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasActiveRequest() => true;

  void _handleCreateRequest(BuildContext context) {
    const activeRequestId = 'CR-0247';

    if (_hasActiveRequest()) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Không thể tạo thêm yêu cầu', style: AppTypography.cardTitle),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đang có yêu cầu cứu hộ [$activeRequestId] đang trong trạng thái Đang chờ tiếp nhận.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Theo quy định điều phối, bạn chỉ có thể tạo yêu cầu mới sau khi đội cứu trợ đã hoàn thành cứu hộ và có xác nhận hoàn tất nhiệm vụ hiện tại, nhằm đảm bảo nguồn lực xuồng máy không bị phân tán.',
                style: AppTypography.secondary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const C08RequestDetailWaitingScreen(
                      requestId: activeRequestId,
                      initialStatus: ReliefStatus.waiting,
                      title: 'Sơ tán khẩn cấp & Lương thực',
                      address: 'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
                      people: 4,
                      urgency: 'Cực kỳ khẩn cấp',
                    ),
                  ),
                );
              },
              child: const Text('Xem đơn hiện tại'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const C02RequestWizardStep1Screen()),
    );
  }
}
