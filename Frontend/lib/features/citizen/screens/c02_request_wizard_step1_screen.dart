import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/widgets/sync_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'c03_request_wizard_step2_location_screen.dart';

class C02RequestWizardStep1Screen extends StatefulWidget {
  final bool isDraft;
  final RequestDraft? draft;
  const C02RequestWizardStep1Screen({
    super.key,
    this.isDraft = false,
    this.draft,
  });

  @override
  State<C02RequestWizardStep1Screen> createState() =>
      _C02RequestWizardStep1ScreenState();
}

class _C02RequestWizardStep1ScreenState
    extends State<C02RequestWizardStep1Screen> {
  final Set<String> _selectedReliefTypes = {};
  int _totalPeople = 1,
      _elderlyCount = 0,
      _childrenCount = 0,
      _disabledCount = 0,
      _specialCount = 0;
  String _urgencyLevel = 'Cao';
  late final RequestDraft _draft;
  final _description = TextEditingController(),
      _specialNotes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _draft =
        widget.draft ??
        (widget.isDraft ? reliefRepository.draft : null) ??
        RequestDraft();
    final v = _draft.values;
    _selectedReliefTypes.addAll(List<String>.from(v['types']));
    _totalPeople = v['people'];
    _elderlyCount = v['elderly'];
    _childrenCount = v['children'];
    _disabledCount = v['disabled'];
    _specialCount = v['special'];
    _urgencyLevel = v['urgency'];
    _description.text = v['description'];
    _specialNotes.text = v['specialNotes'];
  }

  void _collect() {
    _draft.values.addAll({
      'types': _selectedReliefTypes.toList(),
      'people': _totalPeople,
      'elderly': _elderlyCount,
      'children': _childrenCount,
      'disabled': _disabledCount,
      'special': _specialCount,
      'urgency': _urgencyLevel,
      'description': _description.text.trim(),
      'specialNotes': _specialNotes.text.trim(),
    });
  }

  Future<void> _save() async {
    _collect();
    try {
      await reliefRepository.saveDraft(_draft);
      if (mounted) showDraftSaved(context);
    } catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  Future<void> _next() async {
    _collect();
    final error = _draft.validate(location: false);
    if (error != null) {
      showFailure(context, error);
      return;
    }
    try {
      await reliefRepository.saveDraft(_draft);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => C03RequestWizardStep2LocationScreen(
            reliefTypes: _selectedReliefTypes.toList(),
            totalPeople: _totalPeople,
            urgency: _urgencyLevel,
            draft: _draft,
          ),
        ),
      );
    } catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _specialNotes.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _reliefOptions = [
    {
      'name': 'Sơ tán',
      'icon': Icons.transfer_within_a_station,
      'desc': 'Nước dâng cao cần xuồng di chuyển',
    },
    {
      'name': 'Thực phẩm',
      'icon': Icons.restaurant,
      'desc': 'Lương khô, mì tôm, thức ăn liền',
    },
    {
      'name': 'Nước uống',
      'icon': Icons.water_drop,
      'desc': 'Nước lọc đóng chai sạch',
    },
    {
      'name': 'Thuốc men',
      'icon': Icons.medical_services,
      'desc': 'Thuốc hạ sốt, tiêu hóa, bông băng',
    },
    {
      'name': 'Cứu hộ',
      'icon': Icons.sos,
      'desc': 'Ứng cứu người mắc kẹt khẩn cấp',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Nhu cầu hỗ trợ',
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(
              Icons.bookmark_border,
              size: 20,
              color: AppColors.primary,
            ),
            label: Text(
              'Lưu nháp',
              style: AppTypography.secondaryMedium.copyWith(
                color: AppColors.primary,
              ),
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Tạo yêu cầu cứu trợ',
                            style: AppTypography.secondaryMedium.copyWith(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Bước 1 / 4',
                            style: AppTypography.secondaryMedium.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.25,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bạn cần hỗ trợ gì?',
                        style: AppTypography.sectionTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chọn các loại hỗ trợ bạn đang cần.',
                        style: AppTypography.secondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Yêu cầu dành cho bạn và những người cần hỗ trợ tại cùng địa điểm.',
                  style: AppTypography.secondary,
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
                          const Icon(
                            Icons.checklist,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Loại hỗ trợ',
                              style: AppTypography.cardTitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn có thể chọn nhiều loại hỗ trợ.',
                        style: AppTypography.secondary.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ..._reliefOptions.map((opt) {
                        final isSelected = _selectedReliefTypes.contains(
                          opt['name'],
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : AppColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderSubtle,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedReliefTypes.add(
                                      opt['name'] as String,
                                    );
                                  } else {
                                    _selectedReliefTypes.remove(
                                      opt['name'] as String,
                                    );
                                  }
                                });
                              },
                              title: Text(
                                opt['name'] as String,
                                style: AppTypography.bodyMedium,
                              ),
                              subtitle: Text(
                                opt['desc'] as String,
                                style: AppTypography.secondary,
                              ),
                              secondary: Icon(
                                opt['icon'] as IconData,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                              activeColor: AppColors.primary,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
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
                          const Icon(
                            Icons.group,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Số người cần hỗ trợ',
                              style: AppTypography.cardTitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _StepperRow(
                        label: 'Tổng số người cần hỗ trợ',
                        value: _totalPeople,
                        onChanged: (v) => setState(() => _totalPeople = v),
                      ),
                      const Divider(height: 20, color: AppColors.borderSubtle),
                      Text(
                        'Người cần ưu tiên hỗ trợ',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      _StepperRow(
                        label: 'Người cao tuổi',
                        value: _elderlyCount,
                        onChanged: (v) => setState(() => _elderlyCount = v),
                      ),
                      _StepperRow(
                        label: 'Trẻ em',
                        value: _childrenCount,
                        onChanged: (v) => setState(() => _childrenCount = v),
                      ),
                      _StepperRow(
                        label: 'Người khuyết tật',
                        value: _disabledCount,
                        onChanged: (v) => setState(() => _disabledCount = v),
                      ),
                      _StepperRow(
                        label: 'Người cần chăm sóc đặc biệt',
                        value: _specialCount,
                        onChanged: (v) => setState(() => _specialCount = v),
                      ),
                      TextField(
                        controller: _specialNotes,
                        maxLength: 2000,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Thông tin chăm sóc đặc biệt (nếu có)',
                        ),
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
                      ...[
                        'Khẩn cấp (đang bị đe dọa tính mạng)',
                        'Cao (thiếu thức ăn, nước uống)',
                        'Trung bình (bị cô lập, còn đồ dự trữ)',
                      ].map((lvl) {
                        final isSel = _urgencyLevel == lvl.split(' (')[0];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => setState(
                              () => _urgencyLevel = lvl.split(' (')[0],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.warningContainer
                                    : AppColors.canvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.warning
                                      : AppColors.borderSubtle,
                                  width: isSel ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSel
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSel
                                        ? AppColors.warning
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      lvl,
                                      style: AppTypography.body.copyWith(
                                        fontSize: 16,
                                        fontWeight: isSel
                                            ? FontWeight.w600
                                            : FontWeight.w400,
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

                Text(
                  'Mô tả tình trạng hiện tại',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _description,
                  maxLength: 4000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Mô tả tình trạng cần hỗ trợ...',
                  ),
                ),
                const SizedBox(height: 16),
                const SyncStatus(),
                // Next Step Button
                AppButton(
                  text: 'Tiếp tục',
                  icon: Icons.arrow_forward,
                  onPressed: _next,
                ),
              ],
            ),
          ),
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
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.primary,
                ),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                iconSize: 28,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                alignment: Alignment.center,
                child: Text('$value', style: AppTypography.cardTitle),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
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
