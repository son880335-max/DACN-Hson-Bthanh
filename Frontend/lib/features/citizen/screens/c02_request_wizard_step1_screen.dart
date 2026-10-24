import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'c03_request_wizard_step2_location_screen.dart';

class C02RequestWizardStep1Screen extends StatefulWidget {
  final bool isDraft;
  const C02RequestWizardStep1Screen({super.key, this.isDraft = false});

  @override
  State<C02RequestWizardStep1Screen> createState() => _C02RequestWizardStep1ScreenState();
}

class _C02RequestWizardStep1ScreenState extends State<C02RequestWizardStep1Screen> {
  String _recipientType = 'self'; // 'self' or 'other'
  final Set<String> _selectedReliefTypes = {'Sơ tán', 'Thực phẩm', 'Nước uống'};
  int _totalPeople = 4;
  int _elderlyCount = 1;
  int _childrenCount = 1;
  int _disabledCount = 0;
  String _urgencyLevel = 'Cao';

  final List<Map<String, dynamic>> _reliefOptions = [
    {'name': 'Sơ tán', 'icon': Icons.transfer_within_a_station, 'desc': 'Nước dâng cao cần xuồng di chuyển'},
    {'name': 'Thực phẩm', 'icon': Icons.restaurant, 'desc': 'Lương khô, mì tôm, thức ăn liền'},
    {'name': 'Nước uống', 'icon': Icons.water_drop, 'desc': 'Nước lọc đóng chai sạch'},
    {'name': 'Thuốc men', 'icon': Icons.medical_services, 'desc': 'Thuốc hạ sốt, tiêu hóa, bông băng'},
    {'name': 'Cứu hộ', 'icon': Icons.sos, 'desc': 'Ứng cứu người mắc kẹt khẩn cấp'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Bước 1/4: Nhu cầu cứu trợ',
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bản nháp đã được lưu an toàn trên máy.')),
              );
            },
            icon: const Icon(Icons.bookmark_border, size: 20, color: AppColors.primary),
            label: Text(
              'Lưu nháp',
              style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary),
            ),
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
                // Step Progress Indicator
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TIẾN TRÌNH SOẠN THẢO', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary, fontSize: 13)),
                          Text('Bước 1 / 4', style: AppTypography.secondaryMedium.copyWith(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.25,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Bạn cần hỗ trợ gì?', style: AppTypography.sectionTitle),
                      const SizedBox(height: 2),
                      Text(
                        'Vui lòng chọn chính xác các nhu cầu để đội cứu trợ chuẩn bị phương tiện và vật phẩm.',
                        style: AppTypography.secondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Đối tượng cần cứu trợ (US-021)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text('Bạn đang gửi yêu cầu cho ai?', style: AppTypography.cardTitle),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _RadioOption(
                              label: 'Cho bản thân/Gia đình',
                              selected: _recipientType == 'self',
                              onTap: () => setState(() => _recipientType = 'self'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RadioOption(
                              label: 'Gửi giúp người khác',
                              selected: _recipientType == 'other',
                              onTap: () => setState(() => _recipientType = 'other'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Loại cứu trợ cần thiết (Multi-select)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.checklist, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text('Nhu cầu cứu trợ cần thiết', style: AppTypography.cardTitle),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Có thể chọn nhiều mục cùng lúc', style: AppTypography.secondary.copyWith(fontSize: 14)),
                      const SizedBox(height: 12),
                      ..._reliefOptions.map((opt) {
                        final isSelected = _selectedReliefTypes.contains(opt['name']);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryContainer : AppColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedReliefTypes.add(opt['name'] as String);
                                } else {
                                  _selectedReliefTypes.remove(opt['name'] as String);
                                }
                              });
                            },
                            title: Text(opt['name'] as String, style: AppTypography.bodyMedium),
                            subtitle: Text(opt['desc'] as String, style: AppTypography.secondary),
                            secondary: Icon(opt['icon'] as IconData, color: isSelected ? AppColors.primary : AppColors.textMuted),
                            activeColor: AppColors.primary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Số lượng người cần hỗ trợ (US-023, US-024)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text('Số người tại điểm cứu trợ', style: AppTypography.cardTitle),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _StepperRow(
                        label: 'Tổng số người cần ứng cứu',
                        value: _totalPeople,
                        onChanged: (v) => setState(() => _totalPeople = v),
                      ),
                      const Divider(height: 20, color: AppColors.borderSubtle),
                      Text('Đối tượng ưu tiên chăm sóc đặc biệt:', style: AppTypography.bodyMedium),
                      const SizedBox(height: 8),
                      _StepperRow(
                        label: 'Người cao tuổi (trên 65)',
                        value: _elderlyCount,
                        onChanged: (v) => setState(() => _elderlyCount = v),
                      ),
                      _StepperRow(
                        label: 'Trẻ sơ sinh / Trẻ nhỏ',
                        value: _childrenCount,
                        onChanged: (v) => setState(() => _childrenCount = v),
                      ),
                      _StepperRow(
                        label: 'Người khuyết tật / Đang bệnh',
                        value: _disabledCount,
                        onChanged: (v) => setState(() => _disabledCount = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Mức độ khẩn cấp (US-025)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mức độ khẩn cấp', style: AppTypography.cardTitle),
                      const SizedBox(height: 10),
                      ...['Khẩn cấp (Nước dâng nhanh, đe dọa tính mạng)', 'Cao (Hết thức ăn, nước sạch trên 1 ngày)', 'Trung bình (Bị cô lập, có dự trữ hạn chế)'].map((lvl) {
                        final isSel = _urgencyLevel == lvl.split(' ')[0];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => setState(() => _urgencyLevel = lvl.split(' ')[0]),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.warningContainer : AppColors.canvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel ? AppColors.warning : AppColors.borderSubtle,
                                  width: isSel ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: isSel ? AppColors.warning : AppColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      lvl,
                                      style: AppTypography.body.copyWith(
                                        fontSize: 16,
                                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Next Step Button
                AppButton(
                  text: 'Tiếp tục sang bước 2 (Vị trí)',
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => C03RequestWizardStep2LocationScreen(
                          reliefTypes: _selectedReliefTypes.toList(),
                          totalPeople: _totalPeople,
                          urgency: _urgencyLevel,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 15,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.body)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                iconSize: 28,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                alignment: Alignment.center,
                child: Text('$value', style: AppTypography.cardTitle),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () => onChanged(value + 1),
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
