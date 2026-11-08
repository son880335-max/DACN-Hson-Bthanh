import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/data/request_presentation.dart';
import '../../../core/widgets/sync_status.dart';

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
  final RequestDraft? draft;

  const C06RequestWizardStep4ReviewSubmitScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
    required this.address,
    required this.landmark,
    required this.photosCount,
    required this.photoNote,
    this.draft,
  });

  @override
  State<C06RequestWizardStep4ReviewSubmitScreen> createState() =>
      _C06RequestWizardStep4ReviewSubmitScreenState();
}

class _C06RequestWizardStep4ReviewSubmitScreenState
    extends State<C06RequestWizardStep4ReviewSubmitScreen> {
  bool _isSubmitting = false;
  RequestDraft get _draft => widget.draft ?? RequestDraft();

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await reliefRepository.submit(_draft);
      if (!mounted) return;
      if (result['pending'] == true) {
        showFailure(
          context,
          'Yêu cầu đang chờ gửi. Nội dung đã lưu trên thiết bị; hãy kiểm tra kết nối và thử lại.',
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            _draft.requestId == null
                ? 'Đã tiếp nhận yêu cầu'
                : 'Đã lưu thay đổi',
            style: AppTypography.cardTitle,
          ),
          content: Text(
            'Mã yêu cầu: ${result['requestId']}\nGhi nhận lúc: ${formatTimestamp(result['serverSavedAt'], seconds: true)}${result['photosPending'] == true ? '\nẢnh bổ sung đang được gửi riêng; nội dung yêu cầu đã được lưu.' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Xem yêu cầu'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              C08RequestDetailWaitingScreen(requestId: result['requestId']),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Xem lại yêu cầu',
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Bước 4/4',
                            style: AppTypography.chip.copyWith(
                              color: AppColors.primaryDark,
                            ),
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
                      'Kiểm tra nhu cầu, vị trí và thông tin liên hệ trước khi gửi.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 20),

                    // Card 1: Needs
                    _buildSummaryCard(
                      title: 'Nhu cầu cứu trợ',
                      icon: Icons.assignment_outlined,
                      items: [
                        _buildRow(
                          'Loại hỗ trợ:',
                          widget.reliefTypes.join(', '),
                        ),
                        _buildRow('Số người:', '${widget.totalPeople} người'),
                        _buildRow(
                          'Mức độ khẩn cấp:',
                          widget.urgency,
                          isUrgent: true,
                        ),
                        _buildRow(
                          'Nhóm cần chăm sóc:',
                          'Người cao tuổi: ${_draft.values['elderly']}, trẻ em: ${_draft.values['children']}, người khuyết tật: ${_draft.values['disabled']}, cần chăm sóc đặc biệt: ${_draft.values['special']}',
                        ),
                        _buildRow(
                          'Chăm sóc bổ sung:',
                          _draft.values['specialNotes'],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Location
                    _buildSummaryCard(
                      title: 'Vị trí và địa chỉ',
                      icon: Icons.location_on_outlined,
                      items: [
                        _buildRow('Địa chỉ:', widget.address),
                        _buildRow('Mốc nhận diện:', widget.landmark),
                        _buildRow(
                          'Tọa độ:',
                          '${_draft.values['latitude']}, ${_draft.values['longitude']}',
                        ),
                        _buildRow(
                          'Xác nhận vị trí lúc:',
                          formatTimestamp(
                            _draft.values['locationConfirmedAt'],
                            seconds: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Photos & Note
                    _buildSummaryCard(
                      title: 'Ảnh và mô tả',
                      icon: Icons.photo_library_outlined,
                      items: [
                        _buildRow(
                          'Ảnh đính kèm:',
                          '${widget.photosCount} ảnh đã lưu',
                        ),
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
                        _buildRow(
                          'Họ và tên:',
                          reliefRepository.account?['displayName'] ??
                              'Chưa đăng nhập',
                        ),
                        _buildRow(
                          'Số điện thoại:',
                          reliefRepository.account?['phone'] ??
                              'Chưa đăng nhập',
                        ),
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
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Thông tin đúng với tình trạng hiện tại giúp đội cứu hộ chuẩn bị hỗ trợ phù hợp.',
                              style: AppTypography.secondaryMedium.copyWith(
                                color: AppColors.warning,
                              ),
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
                  const SyncStatus(),
                  AppButton(
                    text: _draft.requestId == null
                        ? 'Gửi yêu cầu cứu trợ'
                        : 'Lưu thay đổi yêu cầu',
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
                  ? AppTypography.bodyMedium.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    )
                  : AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
