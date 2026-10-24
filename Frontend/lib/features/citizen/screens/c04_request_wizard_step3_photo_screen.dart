import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'c06_request_wizard_step4_review_submit_screen.dart';

class C04RequestWizardStep3PhotoScreen extends StatefulWidget {
  final List<String> reliefTypes;
  final int totalPeople;
  final String urgency;
  final String address;
  final String landmark;

  const C04RequestWizardStep3PhotoScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
    required this.address,
    required this.landmark,
  });

  @override
  State<C04RequestWizardStep3PhotoScreen> createState() => _C04RequestWizardStep3PhotoScreenState();
}

class _C04RequestWizardStep3PhotoScreenState extends State<C04RequestWizardStep3PhotoScreen> {
  final List<String> _photos = [
    'Mực nước dâng qua cổng 1.2m',
    'Toàn cảnh mái nhà ngập lụt',
  ];
  final _photoNoteController = TextEditingController(text: 'Nước đang tiếp tục dâng chậm, gia đình đã leo lên gác xép.');

  void _addMockPhoto() {
    setState(() {
      _photos.add('Ảnh chụp mới (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đính kèm ảnh thành công kèm tọa độ và dấu thời gian.')),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _navigateNext() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => C06RequestWizardStep4ReviewSubmitScreen(
          reliefTypes: widget.reliefTypes,
          totalPeople: widget.totalPeople,
          urgency: widget.urgency,
          address: widget.address,
          landmark: widget.landmark,
          photosCount: _photos.length,
          photoNote: _photoNoteController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Gửi yêu cầu cứu trợ',
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
                            'Bước 3/4',
                            style: AppTypography.chip.copyWith(color: AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hình ảnh tình trạng (Không bắt buộc)',
                            style: AppTypography.cardTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nếu có thể chụp ảnh an toàn, hình ảnh thực tế sẽ giúp lực lượng cứu hộ đánh giá mức độ ngập và chuẩn bị phương tiện phù hợp.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 20),

                    // Add photo button card
                    InkWell(
                      onTap: _addMockPhoto,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryDark, size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text('Chụp ảnh hoặc chọn từ máy', style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDark)),
                            const SizedBox(height: 4),
                            Text('Tự động ghi nhận tọa độ GPS & thời gian chụp', style: AppTypography.secondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Ảnh đã đính kèm (${_photos.length})', style: AppTypography.sectionTitle),
                    const SizedBox(height: 12),

                    if (_photos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Chưa có ảnh nào. Bạn có thể nhấn Tiếp tục để chuyển thẳng sang bước xác nhận.',
                          style: AppTypography.secondary,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_photos[index], style: AppTypography.bodyMedium),
                                      const SizedBox(height: 2),
                                      Text('23/10/2026 • Đã gán tọa độ GPS', style: AppTypography.secondary.copyWith(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                  onPressed: () => _removePhoto(index),
                                  tooltip: 'Xóa ảnh',
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                    Text('Ghi chú hiện trường', style: AppTypography.sectionTitle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _photoNoteController,
                      maxLines: 3,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        hintText: 'Nhập thêm chi tiết tình trạng nếu cần...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTA
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
                    text: 'Tiếp tục sang bước cuối',
                    onPressed: _navigateNext,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Bỏ qua bước này',
                    variant: AppButtonVariant.secondary,
                    onPressed: _navigateNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
