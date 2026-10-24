import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'c08_request_detail_waiting_screen.dart';

class C06RequestWizardStep4ReviewSubmitScreen extends StatefulWidget {
  final List<String> reliefTypes;
  final int totalPeople;
  final String urgency;
  final String address;
  final String landmark;
  final int photosCount;
  final String photoNote;

  const C06RequestWizardStep4ReviewSubmitScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
    required this.address,
    required this.landmark,
    required this.photosCount,
    required this.photoNote,
  });

  @override
  State<C06RequestWizardStep4ReviewSubmitScreen> createState() => _C06RequestWizardStep4ReviewSubmitScreenState();
}

class _C06RequestWizardStep4ReviewSubmitScreenState extends State<C06RequestWizardStep4ReviewSubmitScreen> {
  bool _isSubmitting = false;

  void _submitRequest() {
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Text('Đã tiếp nhận yêu cầu!', style: AppTypography.cardTitle),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã yêu cầu cứu trợ của bạn là: CR-0247',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hệ thống đang chuyển thông tin tới các đội cứu hộ gần nhất trên địa bàn. Vui lòng giữ liên lạc qua số điện thoại đã đăng ký.',
                  style: AppTypography.body,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const C08RequestDetailWaitingScreen(requestId: 'CR-0247'),
                    ),
                    (route) => route.isFirst,
                  );
                },
                child: Text('Xem chi tiết đơn', style: AppTypography.button.copyWith(color: AppColors.primary)),
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
        title: 'Kiểm tra & Gửi đơn cứu trợ',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Bước 4/4',
                            style: AppTypography.chip.copyWith(color: AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Xác nhận thông tin',
                            style: AppTypography.cardTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng rà soát cẩn thận các nội dung dưới đây trước khi gửi lên ban điều phối cứu trợ.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 20),

                    // Card 1: Needs
                    _buildSummaryCard(
                      title: 'Nhu cầu cứu trợ',
                      icon: Icons.assignment_outlined,
                      items: [
                        _buildRow('Loại cứu trợ:', widget.reliefTypes.join(', ')),
                        _buildRow('Số lượng người cần hỗ trợ:', '${widget.totalPeople} người'),
                        _buildRow('Mức độ cấp bách:', widget.urgency, isUrgent: true),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Location
                    _buildSummaryCard(
                      title: 'Vị trí & Địa chỉ',
                      icon: Icons.location_on_outlined,
                      items: [
                        _buildRow('Địa chỉ:', widget.address),
                        _buildRow('Điểm mốc / Nhận diện:', widget.landmark),
                        _buildRow('Tọa độ GPS:', '20.8841° N, 105.6215° E (±8m)'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Photos & Note
                    _buildSummaryCard(
                      title: 'Ảnh & Ghi chú',
                      icon: Icons.photo_library_outlined,
                      items: [
                        _buildRow('Ảnh đính kèm:', '${widget.photosCount} ảnh đã lưu'),
                        if (widget.photoNote.isNotEmpty)
                          _buildRow('Ghi chú bổ sung:', widget.photoNote),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 4: Contact
                    _buildSummaryCard(
                      title: 'Người liên hệ',
                      icon: Icons.person_outline,
                      items: [
                        _buildRow('Họ và tên:', 'Nguyễn Văn An'),
                        _buildRow('Số điện thoại:', '0912 345 678'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Warning notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warningBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cam kết thông tin trung thực: Mọi hành vi báo khống hoặc phóng đại có thể làm lỡ cơ hội cứu nạn của đồng bào khác đang trong tình thế nguy kịch.',
                              style: AppTypography.secondaryMedium.copyWith(color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Submit Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    text: 'Gửi yêu cầu cứu trợ',
                    isLoading: _isSubmitting,
                    onPressed: _submitRequest,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Quay lại chỉnh sửa',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.cardTitle),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderSubtle),
          ...items,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isUrgent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTypography.secondaryMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: isUrgent
                  ? AppTypography.bodyMedium.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)
                  : AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
