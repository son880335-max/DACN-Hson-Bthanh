import '../../../core/data/request_presentation.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/notices_dialog.dart';
import '../../../core/data/relief_repository.dart';
import '../../../core/widgets/sync_status.dart';

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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: reliefRepository,
    builder: (context, _) => _page(context),
  );
  Widget _page(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Cứu trợ lũ lụt',
        showBackButton: false,
        actions: [
          IconButton(
            tooltip: 'Thông báo yêu cầu',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 26,
                  color: AppColors.textPrimary,
                ),
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
                      '${reliefRepository.notices.where((n) => n['read'] != true).length}',
                      style: AppTypography.button.copyWith(
                        fontSize: 10,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => showNotices(context),
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
                              'Hỗ trợ khi ngập lụt',
                              style: AppTypography.secondaryMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gửi yêu cầu và theo dõi tiến độ cứu trợ.',
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
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.primary,
                        ),
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
                          const Icon(
                            Icons.wifi_off,
                            color: AppColors.warning,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Khi mạng yếu hoặc mất kết nối',
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 17,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bạn có thể soạn và lưu nháp. Khi gửi, hãy kiểm tra yêu cầu đã được tiếp nhận. Gửi qua SMS hiện chưa khả dụng.',
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
                            'Chưa được xác nhận khi mất kết nối',
                            style: AppTypography.secondary.copyWith(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const C15SmsRequestScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.sms, size: 18),
                            label: const Text('Xem cách gửi SMS'),
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
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gửi yêu cầu cho bạn và những người cần hỗ trợ tại cùng địa điểm.',
                          style: AppTypography.secondary.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const SyncStatus(),
                // Active Ongoing Request Section
                if (reliefRepository.active != null)
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
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        'Yêu cầu #${shortRequestId(reliefRepository.active?['id'] ?? '')}',
                                        style: AppTypography.cardTitle,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          formatTimestamp(
                                            reliefRepository
                                                .active?['createdAt'],
                                          ),
                                          style: AppTypography.secondary
                                              .copyWith(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          reliefRepository.active?['address'] ??
                                              '',
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
                            StatusChip(
                              status: stageStatus(
                                reliefRepository.active?['stage'] ?? 'waiting',
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          height: 24,
                          color: AppColors.borderSubtle,
                        ),
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
                              Text(
                                'Nội dung yêu cầu:',
                                style: AppTypography.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${reliefRepository.active?['people']} người cần hỗ trợ: ${(reliefRepository.active?['types'] as List? ?? []).join(', ')}',
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
                                'Đang chờ đội cứu hộ tiếp nhận',
                                style: AppTypography.secondary.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        C08RequestDetailWaitingScreen(
                                          requestId:
                                              reliefRepository.active!['id'],
                                        ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              child: Text(
                                'Xem chi tiết',
                                style: AppTypography.secondaryMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                // Saved Draft Recovery (US-021)
                if (reliefRepository.draft != null)
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
                          child: const Icon(
                            Icons.edit_note,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bản nháp yêu cầu cứu trợ',
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'Đã lưu trên thiết bị (chưa gửi)',
                                style: AppTypography.secondary.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const C02RequestWizardStep1Screen(
                                      isDraft: true,
                                    ),
                              ),
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

  bool _hasActiveRequest() => reliefRepository.active != null;

  void _handleCreateRequest(BuildContext context) {
    if (!reliefRepository.signedIn) {
      showFailure(context, 'Đăng nhập để gửi yêu cầu cứu trợ.');
      return;
    }
    if (reliefRepository.operations.any((o) => o['kind'] != 'evidence')) {
      showFailure(
        context,
        'Còn thao tác đang chờ máy chủ xác nhận. Hãy xem trạng thái gửi.',
      );
      return;
    }
    final activeRequestId = reliefRepository.active?['id'] ?? '';

    if (_hasActiveRequest()) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Không thể tạo thêm yêu cầu',
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đang có yêu cầu ${shortRequestId(activeRequestId)} chưa hoàn thành.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mỗi tài khoản có một yêu cầu đang mở. Bạn có thể gửi mới sau khi yêu cầu này hoàn thành hoặc được xác nhận hủy. Khi chưa có đội tiếp nhận, bạn có thể sửa yêu cầu hiện tại.',
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
                    builder: (_) => C08RequestDetailWaitingScreen(
                      requestId: activeRequestId,
                      initialStatus: ReliefStatus.waiting,
                      title: (reliefRepository.active?['types'] as List? ?? [])
                          .join(', '),
                      address:
                          'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
                      people: 4,
                      urgency: 'Cực kỳ khẩn cấp',
                    ),
                  ),
                );
              },
              child: const Text('Xem yêu cầu hiện tại'),
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
