import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'rescue_shell_screen.dart';

class R21CompleteTaskScreen extends StatefulWidget {
  final String taskId;

  const R21CompleteTaskScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<R21CompleteTaskScreen> createState() => _R21CompleteTaskScreenState();
}

class _R21CompleteTaskScreenState extends State<R21CompleteTaskScreen> {
  int _evacuatedPeople = 4;
  final _shelterLocationController = TextEditingController(text: 'Trường THPT Chương Mỹ A (Khu sơ tán trung tâm)');
  final _suppliesGivenController = TextEditingController(text: '04 Áo phao, 02 thùng nước lọc 20L, 02 thùng lương khô');
  final _notesController = TextEditingController(text: '4 người dân an toàn, sức khỏe ổn định, đã bàn giao cho ban y tế dã chiến');
  bool _isSaving = false;

  void _finishTask() {
    setState(() => _isSaving = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isSaving = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                const SizedBox(width: 8),
                Text('Nhiệm vụ hoàn thành!', style: AppTypography.cardTitle),
              ],
            ),
            content: Text(
              'Biên bản hoàn thành ${widget.taskId} đã được lưu và cập nhật lên hệ thống điều phối cứu trợ.',
              style: AppTypography.body,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RescueShellScreen()),
                    (route) => route.isFirst,
                  );
                },
                child: Text('Về danh sách nhiệm vụ', style: AppTypography.button.copyWith(color: AppColors.primary)),
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
        title: 'Báo cáo hoàn thành ${widget.taskId}',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kết quả cứu trợ & Bàn giao', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              Text(
                'Ghi nhận số lượng người và tiếp tế thực tế đã thực hiện để ban điều phối cập nhật tổng số liệu cứu trợ toàn địa bàn.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 20),

              // People count input
              Text('Số người đã hỗ trợ an toàn', style: AppTypography.cardTitle),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_evacuatedPeople người', style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDark)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 28),
                          onPressed: () {
                            if (_evacuatedPeople > 1) {
                              setState(() => _evacuatedPeople--);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                          onPressed: () {
                            setState(() => _evacuatedPeople++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location of handover
              Text('Địa điểm tiếp nhận / Bàn giao người dân', style: AppTypography.cardTitle),
              const SizedBox(height: 8),
              TextField(
                controller: _shelterLocationController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Supplies given
              Text('Nhu yếu phẩm đã bàn giao', style: AppTypography.cardTitle),
              const SizedBox(height: 8),
              TextField(
                controller: _suppliesGivenController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              Text('Ghi chú tình trạng', style: AppTypography.cardTitle),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: AppTypography.body,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              AppButton(
                text: 'Xác nhận & Hoàn tất nhiệm vụ',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _finishTask,
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Quay lại',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
