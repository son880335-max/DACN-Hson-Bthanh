import '../../../core/data/request_presentation.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/request_review_panel.dart';
import 'c02_request_wizard_step1_screen.dart';
import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/widgets/sync_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';

class C08RequestDetailWaitingScreen extends StatefulWidget {
  final String requestId;
  final ReliefStatus initialStatus;
  final String? title;
  final String? address;
  final int? people;
  final String? urgency;

  const C08RequestDetailWaitingScreen({
    super.key,
    this.requestId = 'CR-0247',
    this.initialStatus = ReliefStatus.pending,
    this.title,
    this.address,
    this.people,
    this.urgency,
  });

  @override
  State<C08RequestDetailWaitingScreen> createState() =>
      _C08RequestDetailWaitingScreenState();
}

class _C08RequestDetailWaitingScreenState
    extends State<C08RequestDetailWaitingScreen> {
  ReliefStatus _currentStatus = ReliefStatus.pending;
  Json? _request;
  String? _error;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final value = await reliefRepository.detail(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = value;
        _error = null;
        _currentStatus = stageStatus(value['stage']);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận hủy yêu cầu', style: AppTypography.cardTitle),
        content: const Text(
          'Hủy yêu cầu cứu trợ này? Bạn chỉ có thể hủy khi chưa có đội tiếp nhận. Hãy chờ xác nhận kết quả trước khi gửi yêu cầu mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed != true || _request == null) return;
    try {
      final result = await reliefRepository.cancel(_request!);
      if (!mounted) return;
      showFailure(
        context,
        result['pending'] == true
            ? 'Đang chờ xác nhận hủy. Bạn chưa thể gửi yêu cầu mới.'
            : 'Đã hủy yêu cầu.',
      );
      await _reload();
    } catch (error) {
      if (mounted) showFailure(context, error);
      await _reload();
    }
  }

  Future<void> _edit() async {
    if (_request == null) return;
    try {
      final latest = await reliefRepository.detail(widget.requestId);
      if (!mounted) return;
      if (latest['cached'] == true || latest['stage'] != 'waiting') {
        throw 'Hãy tải lại yêu cầu. Bạn chỉ có thể sửa khi chưa có đội tiếp nhận.';
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => C02RequestWizardStep1Screen(
            draft: RequestDraft.fromRequest(latest),
          ),
        ),
      );
      await _reload();
    } catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    if (request == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppHeader(
          title: 'Chi tiết yêu cầu',
          actions: [
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!),
                ),
        ),
      );
    }
    final values = Map<String, dynamic>.from(request['data']);
    final citizen = reliefRepository.account?['role'] == 'citizen';
    final isCompleted = _currentStatus == ReliefStatus.completed;
    final isCancelled = _currentStatus == ReliefStatus.cancelled;
    final isWaiting =
        _currentStatus == ReliefStatus.pending ||
        _currentStatus == ReliefStatus.waiting;
    final isInProgress =
        _currentStatus == ReliefStatus.inTransit ||
        _currentStatus == ReliefStatus.inProgress ||
        _currentStatus == ReliefStatus.assigned;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Chi tiết yêu cầu ${shortRequestId(widget.requestId)}',
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
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
                      children: [
                        Expanded(
                          child: Text(
                            'Mã: ${shortRequestId(widget.requestId)}',
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        StatusChip(status: _currentStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tiếp nhận lúc: ${formatTimestamp(request['receivedAt'], seconds: true)}',
                      style: AppTypography.secondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mức độ: ${values['urgency']}',
                      style: AppTypography.secondaryMedium.copyWith(
                        color: isCompleted
                            ? AppColors.success
                            : (isCancelled
                                  ? AppColors.textMuted
                                  : AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Completed Notice Banner (If Completed)
              if (!citizen)
                const SizedBox.shrink()
              else if (isCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppColors.success,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hỗ trợ thành công',
                              style: AppTypography.cardTitle.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Yêu cầu đã hoàn thành. Bạn có thể xem lại nội dung và lịch sử xử lý.',
                              style: AppTypography.secondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Progress Timeline
              Text('Tiến độ xử lý', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildTimelineStep(
                      title: 'Đã gửi yêu cầu',
                      subtitle: 'Yêu cầu đã được tiếp nhận',
                      time: formatTimestamp(request['receivedAt']),
                      isCompleted: true,
                      isCurrent: false,
                    ),
                    _buildTimelineStep(
                      title: 'Đội cứu hộ tiếp nhận',
                      subtitle: isCancelled
                          ? 'Bạn đã hủy yêu cầu'
                          : (isCompleted
                                ? 'Yêu cầu đã được đội tiếp nhận'
                                : (isInProgress
                                      ? 'Đã có đội phụ trách'
                                      : 'Đang chờ đội tiếp nhận')),
                      time: '--:--',
                      isCompleted: isCompleted || isInProgress || isCancelled,
                      isCurrent: isWaiting,
                    ),
                    _buildTimelineStep(
                      title: 'Đội cứu hộ tiếp cận',
                      subtitle: isCompleted
                          ? 'Yêu cầu đã hoàn thành'
                          : (isInProgress
                                ? 'Chưa có cập nhật thời điểm đến nơi'
                                : 'Chờ đội tiếp nhận'),
                      time: '--:--',
                      isCompleted: isCompleted,
                      isCurrent: isInProgress,
                    ),
                    _buildTimelineStep(
                      title: 'Hoàn thành hỗ trợ',
                      subtitle: isCompleted ? 'Đã ghi nhận hoàn thành hỗ trợ' : 'Bàn giao nhu yếu phẩm hoặc đưa người về nơi an toàn',
                      time: '--:--',
                      isCompleted: isCompleted,
                      isCurrent: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Request Details
              Text('Nội dung đã gửi', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
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
                    _buildInfoItem(
                      'Nhu cầu:',
                      (values['types'] as List).join(', '),
                    ),
                    _buildInfoItem('Số người:', '${values['people']} người'),
                    _buildInfoItem('Địa chỉ:', values['address']),
                    _buildInfoItem('Mốc nhận diện:', values['landmark']),
                    _buildInfoItem(
                      'Tọa độ đã xác nhận:',
                      '${values['latitude']}, ${values['longitude']}',
                    ),
                    _buildInfoItem(
                      'Người liên hệ:',
                      '${request['contact']['name']} - ${request['contact']['phone']}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              RequestReviewPanel(request: request, reload: _reload),
              // Context-sensitive Actions
              if (!citizen)
                const SizedBox.shrink()
              else if (isCompleted) ...[
                // When Completed: NEVER show Cancel button! Show feedback and home actions
                AppButton(
                  text: 'Đánh giá chất lượng hỗ trợ',
                  icon: Icons.star_rate,
                  onPressed: () => showFailure(
                    context,
                    'Chức năng đánh giá chưa khả dụng. Chưa gửi phản hồi.',
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(
                  text: 'Quay lại danh sách yêu cầu',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ] else if (isInProgress) ...[
                // When In Progress / En Route: Can track rescue
                AppButton(
                  text: 'Theo dõi vị trí đội cứu hộ',
                  icon: Icons.map,
                  onPressed: () => showFailure(
                    context,
                    'Chức năng theo dõi vị trí đội cứu hộ chưa khả dụng.',
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(
                  text: 'Liên hệ đội trưởng cứu hộ',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.phone,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chưa có thông tin liên hệ đội cứu hộ.'),
                      ),
                    );
                  },
                ),
              ] else if (isWaiting) ...[
                AppButton(
                  text: 'Chỉnh sửa yêu cầu',
                  icon: Icons.edit_outlined,
                  onPressed: _edit,
                ),
                const SizedBox(height: 10),
                // ONLY when waiting / pending can citizen cancel the request!
                AppButton(
                  text: 'Hủy yêu cầu cứu trợ này',
                  variant: AppButtonVariant.danger,
                  onPressed: _showCancelDialog,
                ),
              ] else ...[
                // Cancelled
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Yêu cầu đã được hủy.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    Color iconColor = AppColors.border;
    IconData icon = Icons.circle_outlined;
    if (isCompleted) {
      iconColor = AppColors.success;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      iconColor = AppColors.primary;
      icon = Icons.radio_button_checked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isCompleted ? AppColors.success : AppColors.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.bodyMedium),
                    ),
                    Text(
                      time,
                      style: AppTypography.secondary.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.secondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.secondaryMedium),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}
