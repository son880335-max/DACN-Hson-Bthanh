import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'r21_complete_task_screen.dart';

class R13RescueNavigationRouteScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;

  const R13RescueNavigationRouteScreen({
    super.key,
    required this.tasks,
  });

  @override
  State<R13RescueNavigationRouteScreen> createState() => _R13RescueNavigationRouteScreenState();
}

class _R13RescueNavigationRouteScreenState extends State<R13RescueNavigationRouteScreen> {
  int _currentStepIndex = 0;
  final Set<int> _completedStepIndices = {};

  void _markCurrentStepCompleted() {
    setState(() {
      _completedStepIndices.add(_currentStepIndex);
      if (_currentStepIndex < widget.tasks.length - 1) {
        _currentStepIndex++;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Đã hoàn tất hỗ trợ tại điểm ${widget.tasks[_currentStepIndex]['id']}! Đang chuyển lộ trình sang điểm tiếp theo.'),
      ),
    );
  }

  void _finishAllRoute() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => R21CompleteTaskScreen(
          taskId: widget.tasks.length == 1
              ? (widget.tasks.first['id'] as String)
              : 'LỘ TRÌNH NGOẠI TUYẾN (${widget.tasks.length} ĐIỂM)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = widget.tasks[_currentStepIndex];
    final isLastStep = _currentStepIndex == widget.tasks.length - 1;
    final allFinished = _completedStepIndices.length == widget.tasks.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: widget.tasks.length > 1
            ? 'Dẫn đường ngoại tuyến (${widget.tasks.length} điểm)'
            : 'Dẫn đường đến ${widget.tasks.first['id']}',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ĐANG MẤT SÓNG • Hoạt động bằng GPS & Bản đồ ngoại tuyến',
                      style: AppTypography.secondary.copyWith(color: const Color(0xFFE2E8F0), fontSize: 12),
                    ),
                  ),
                  Text(
                    'Độc quyền: Đội Hương Thủy',
                    style: AppTypography.secondaryMedium.copyWith(color: const Color(0xFF93C5FD), fontSize: 12),
                  ),
                ],
              ),
            ),

            // Waypoints Step Tab Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: List.generate(widget.tasks.length, (index) {
                  final isDone = _completedStepIndices.contains(index);
                  final isCurrent = index == _currentStepIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _currentStepIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primaryContainer
                              : isDone
                                  ? AppColors.successContainer
                                  : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary
                                : isDone
                                    ? AppColors.success
                                    : AppColors.borderSubtle,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isDone)
                                  const Icon(Icons.check_circle, size: 14, color: AppColors.success)
                                else
                                  Text('${index + 1}',
                                      style: AppTypography.chip.copyWith(
                                        fontSize: 13,
                                        color: isCurrent ? AppColors.primaryDark : AppColors.textSecondary,
                                      )),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.tasks[index]['id'] as String,
                              style: AppTypography.secondary.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),

            // Main Content: Map & Turn-by-turn guidance
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Turn Guidance Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.navigation, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Khoảng cách: ${currentTask['distance']}',
                                  style: AppTypography.cardTitle.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hướng Tây Bắc 315° • Lái thuyền thẳng theo trục đê ngập',
                                  style: AppTypography.secondary.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Navigation Map Canvas
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFE1DE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _OfflineRouteMapPainter(
                                currentIndex: _currentStepIndex,
                                totalSteps: widget.tasks.length,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Tọa độ: ${currentTask['gps']}', style: AppTypography.secondary.copyWith(fontSize: 12)),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.dangerContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.danger),
                              ),
                              child: Text('Tránh xoáy nước cống tràn', style: AppTypography.secondary.copyWith(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Citizen Information Card
                    Text('Điểm cứu trợ hiện tại: ${currentTask['id']}', style: AppTypography.sectionTitle),
                    const SizedBox(height: 8),
                    Container(
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
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primaryContainer,
                                child: Icon(Icons.person, color: AppColors.primaryDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${currentTask['citizen']} (${currentTask['people']} người)', style: AppTypography.cardTitle),
                                    const SizedBox(height: 2),
                                    Text('SĐT liên hệ: ${currentTask['phone']}', style: AppTypography.secondaryMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppColors.borderSubtle),
                          _buildDetailRow('Địa chỉ:', currentTask['address'] as String),
                          const SizedBox(height: 6),
                          _buildDetailRow('Nhu cầu:', currentTask['needs'] as String, isHighlight: true),
                          const SizedBox(height: 6),
                          _buildDetailRow('Mốc nhận dạng:', currentTask['notes'] as String),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!allFinished) ...[
                    AppButton(
                      text: 'Đã hoàn tất hỗ trợ điểm này',
                      icon: Icons.check_circle,
                      onPressed: _markCurrentStepCompleted,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!isLastStep) ...[
                    AppButton(
                      text: 'Chuyển sang điểm tiếp theo (${_currentStepIndex + 2}/${widget.tasks.length})',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => setState(() => _currentStepIndex++),
                    ),
                  ] else ...[
                    AppButton(
                      text: 'Nghiệm thu toàn bộ danh sách cứu trợ',
                      icon: Icons.assignment_turned_in,
                      variant: AppButtonVariant.primary,
                      onPressed: _finishAllRoute,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: AppTypography.secondaryMedium)),
        Expanded(
          child: Text(
            value,
            style: isHighlight ? AppTypography.bodyMedium.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600) : AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _OfflineRouteMapPainter extends CustomPainter {
  final int currentIndex;
  final int totalSteps;

  _OfflineRouteMapPainter({required this.currentIndex, required this.totalSteps});

  @override
  void paint(Canvas canvas, Size size) {
    // Water background line
    final routePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..lineTo(size.width * 0.45, size.height * 0.45)
      ..lineTo(size.width * 0.8, size.height * 0.25);
    canvas.drawPath(path, routePaint);

    // Points
    final points = [
      Offset(size.width * 0.15, size.height * 0.75),
      Offset(size.width * 0.45, size.height * 0.45),
      Offset(size.width * 0.8, size.height * 0.25),
    ];

    for (int i = 0; i < points.length && i < totalSteps; i++) {
      final isCurrent = i == currentIndex;
      final pointPaint = Paint()
        ..color = isCurrent ? const Color(0xFFA32626) : const Color(0xFF176B64)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], isCurrent ? 14 : 10, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
