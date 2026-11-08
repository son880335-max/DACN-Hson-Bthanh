import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/data/request_presentation.dart';
import '../../../core/widgets/request_review_panel.dart';
import '../../../core/widgets/sync_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';

class R12AssignedTaskDetailScreen extends StatefulWidget {
  final String taskId;

  const R12AssignedTaskDetailScreen({super.key, this.taskId = 'TASK-8801'});

  @override
  State<R12AssignedTaskDetailScreen> createState() =>
      _R12AssignedTaskDetailScreenState();
}

class _R12AssignedTaskDetailScreenState
    extends State<R12AssignedTaskDetailScreen> {
  final bool _arrivedAtScene = false;

  Json? _request;
  String? _error;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final result = await reliefRepository.detail(widget.taskId);
      if (mounted) {
        setState(() {
          _request = result;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _openNavigation() {
    showFailure(context, 'Chức năng dẫn đường chưa khả dụng.');
  }

  void _callCitizen() {
    showFailure(
      context,
      'Liên hệ: ${_request?['contact']['phone'] ?? 'Chưa tải được thông tin'}',
    );
  }

  void _reportObstacle() {
    showFailure(
      context,
      'Chức năng báo chướng ngại vật chưa khả dụng. Chưa gửi báo cáo.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_request == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: const AppHeader(title: 'Chi tiết yêu cầu'),
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Text(_error!),
        ),
      );
    }
    final r = _request!, values = Map<String, dynamic>.from(r['data']);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Chi tiết yêu cầu ${shortRequestId(widget.taskId)}',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            shortRequestId(widget.taskId),
                            style: AppTypography.cardTitle.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const StatusChip(status: RequestStatus.assigned),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      values['description'],
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đội phụ trách: ${reliefRepository.account?['displayName'] ?? 'Chưa có thông tin'}',
                      style: AppTypography.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Citizen contact box
              Text(
                'Thông tin người liên hệ',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(
                            Icons.person,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['contact']['name'],
                                style: AppTypography.cardTitle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r['contact']['phone'],
                                style: AppTypography.secondaryMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.phone,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          onPressed: _callCitizen,
                          tooltip: 'Gọi điện',
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.borderSubtle),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${values['address']} • ${values['landmark']}',
                            style: AppTypography.body,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Route & Distance Card
              Text(
                'Đường đi và khoảng cách',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.navigation,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Khoảng cách: chưa có dữ liệu',
                              style: AppTypography.cardTitle,
                            ),
                          ],
                        ),
                        Text(
                          'Chưa có thời gian di chuyển dự kiến',
                          style: AppTypography.secondaryMedium.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _arrivedAtScene
                          ? 'Đã tiếp cận địa điểm người dân. Bắt đầu phương án cứu hộ.'
                          : 'Chưa có dữ liệu dẫn đường và cảnh báo thực tế.',
                      style: AppTypography.secondary,
                    ),
                    const SizedBox(height: 14),
                    // Navigation CTA right in the route card
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.navigation, size: 22),
                        label: const Text(
                          'Chỉ đường',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _openNavigation,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              RequestReviewPanel(request: r, reload: _reload),
              // Action Buttons
              if (!_arrivedAtScene) ...[
                AppButton(
                  text: 'Xác nhận đã đến nơi',
                  icon: Icons.check_circle_outline,
                  onPressed: () => showFailure(
                    context,
                    'Chức năng cập nhật hiện trường chưa khả dụng. Chưa gửi cập nhật.',
                  ),
                ),
                const SizedBox(height: 12),
              ],

              AppButton(
                text: 'Hoàn thành cứu trợ',
                icon: Icons.task_alt,
                onPressed: () => showFailure(
                  context,
                  'Chức năng xác nhận hoàn thành chưa khả dụng. Trạng thái yêu cầu chưa thay đổi.',
                ),
              ),
              const SizedBox(height: 12),

              AppButton(
                text: 'Báo điểm ngập hoặc chướng ngại vật',
                icon: Icons.warning_amber_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: _reportObstacle,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
