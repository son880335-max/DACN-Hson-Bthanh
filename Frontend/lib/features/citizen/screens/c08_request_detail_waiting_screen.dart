import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';
import 'c10_track_rescue_screen.dart';

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
  State<C08RequestDetailWaitingScreen> createState() => _C08RequestDetailWaitingScreenState();
}

class _C08RequestDetailWaitingScreenState extends State<C08RequestDetailWaitingScreen> {
  late ReliefStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  void _showCancelDialog() {
    String cancelReason = 'Gia đình đã tự di chuyển an toàn sang nhà hàng xóm';
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Xác nhận hủy yêu cầu', style: AppTypography.cardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn chắc chắn muốn hủy yêu cầu cứu trợ ${widget.requestId}? Vui lòng chọn lý do để nhường lượt cho các hộ khác đang nguy kịch:',
                style: AppTypography.body,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: cancelReason,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.canvas,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Gia đình đã tự di chuyển an toàn sang nhà hàng xóm',
                    child: Text('Đã tự di chuyển an toàn', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Đã nhận được trợ giúp từ đội ứng cứu địa phương',
                    child: Text('Đã nhận hỗ trợ tại chỗ', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Nước lũ đã rút, không còn nguy hiểm',
                    child: Text('Nước lũ đã rút', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Nhầm lẫn thông tin',
                    child: Text('Gửi nhầm thông tin', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => cancelReason = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Quay lại', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.onDanger,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                setState(() => _currentStatus = ReliefStatus.cancelled);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã hủy yêu cầu cứu trợ thành công.')),
                );
              },
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Đánh giá chất lượng hỗ trợ', style: AppTypography.cardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bạn đánh giá thế nào về sự hỗ trợ của đội cứu hộ?', style: AppTypography.body),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setModalState(() => rating = index + 1),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Đóng', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cảm ơn bạn đã gửi đánh giá!')),
                );
              },
              child: const Text('Gửi đánh giá'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _currentStatus == ReliefStatus.completed;
    final isCancelled = _currentStatus == ReliefStatus.cancelled;
    final isWaiting = _currentStatus == ReliefStatus.pending || _currentStatus == ReliefStatus.waiting;
    final isInProgress = _currentStatus == ReliefStatus.inTransit || _currentStatus == ReliefStatus.inProgress || _currentStatus == ReliefStatus.assigned;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Chi tiết yêu cầu ${widget.requestId}',
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
                          child: Text('Mã: ${widget.requestId}', style: AppTypography.cardTitle),
                        ),
                        StatusChip(status: _currentStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Gửi lúc: 18:20, 23/10/2026', style: AppTypography.secondary),
                    const SizedBox(height: 4),
                    Text(
                      widget.urgency ?? (isCompleted ? 'Trạng thái: Đã đưa về nơi an toàn' : 'Mức độ: Cực kỳ khẩn cấp'),
                      style: AppTypography.secondaryMedium.copyWith(
                        color: isCompleted ? AppColors.success : (isCancelled ? AppColors.textMuted : AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Completed Notice Banner (If Completed)
              if (isCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified, color: AppColors.success, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hỗ trợ thành công', style: AppTypography.cardTitle.copyWith(color: AppColors.success)),
                            const SizedBox(height: 4),
                            Text(
                              'Đội cứu hộ đã hoàn thành nhiệm vụ và bàn giao an toàn. Yêu cầu đã được lưu trữ vào hệ thống lưu trữ cứu trợ và không thể hủy.',
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
                      subtitle: 'Hệ thống đã nhận đơn vào cơ sở dữ liệu cứu trợ',
                      time: '18:20',
                      isCompleted: true,
                      isCurrent: false,
                    ),
                    _buildTimelineStep(
                      title: 'Điều phối & Tiếp nhận',
                      subtitle: isCancelled
                          ? 'Yêu cầu đã được chủ động hủy'
                          : (isCompleted
                              ? 'Đội Cứu trợ Hương Thủy đã tiếp nhận'
                              : (isInProgress ? 'Đội Hương Thủy đang phụ trách' : 'Đang tìm đội cứu trợ gần nhất trong bán kính 5km')),
                      time: '18:22',
                      isCompleted: isCompleted || isInProgress || isCancelled,
                      isCurrent: isWaiting,
                    ),
                    _buildTimelineStep(
                      title: 'Đội cứu hộ tiếp cận',
                      subtitle: isCompleted
                          ? 'Đã tiếp cận vị trí hộ gia đình an toàn'
                          : (isInProgress ? 'Đội cứu hộ đang di chuyển trên đường' : 'Chờ đội xuất phát'),
                      time: isCompleted ? '18:45' : (isInProgress ? '18:30' : '--:--'),
                      isCompleted: isCompleted,
                      isCurrent: isInProgress,
                    ),
                    _buildTimelineStep(
                      title: 'Hoàn thành hỗ trợ',
                      subtitle: isCompleted
                          ? 'Đã sơ tán an toàn về điểm tránh trú THPT Chương Mỹ A'
                          : 'Bàn giao nhu yếu phẩm hoặc đưa người về nơi an toàn',
                      time: isCompleted ? '19:10' : '--:--',
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
                    _buildInfoItem('Nhu cầu:', widget.title ?? 'Sơ tán khẩn cấp, Lương thực & Nước uống'),
                    _buildInfoItem('Số người:', '${widget.people ?? 4} người (người già, trẻ nhỏ)'),
                    _buildInfoItem('Địa chỉ:', widget.address ?? 'Số 42, Thôn Nam Hài, Xã Nam Phương Tiến, Huyện Chương Mỹ'),
                    _buildInfoItem('Mốc nhận dạng:', 'Nhà cấp 4 màu xanh gần đình làng, nước dâng ngập cổng'),
                    _buildInfoItem('Tọa độ GPS:', '20.8841° N, 105.6215° E (Độ chính xác: ±8m)'),
                    _buildInfoItem('Người liên hệ:', 'Nguyễn Văn An - 0912 345 678'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Context-sensitive Actions
              if (isCompleted) ...[
                // When Completed: NEVER show Cancel button! Show feedback and home actions
                AppButton(
                  text: 'Đánh giá chất lượng hỗ trợ',
                  icon: Icons.star_rate,
                  onPressed: _showFeedbackDialog,
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => C10TrackRescueScreen(requestId: widget.requestId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  text: 'Liên hệ đội trưởng cứu hộ',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.phone,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang kết nối tới Đội trưởng Đội Hương Thủy (0983 234 567)...')),
                    );
                  },
                ),
              ] else if (isWaiting) ...[
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
                      'Yêu cầu này đã được hủy thành công.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                    Expanded(child: Text(title, style: AppTypography.bodyMedium)),
                    Text(time, style: AppTypography.secondary.copyWith(fontSize: 14)),
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
