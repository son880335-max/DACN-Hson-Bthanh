import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/data/request_presentation.dart';
import '../../../core/widgets/sync_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_header.dart';
import 'r12_assigned_task_detail_screen.dart';
import 'r17_offline_download_screen.dart';

class R07WaitingTasksScreen extends StatefulWidget {
  const R07WaitingTasksScreen({super.key});

  @override
  State<R07WaitingTasksScreen> createState() => _R07WaitingTasksScreenState();
}

class _R07WaitingTasksScreenState extends State<R07WaitingTasksScreen> {
  List<Json> get _tasks => reliefRepository.items.map(requestCard).toList();
  @override
  void initState() {
    super.initState();
    reliefRepository.addListener(_changed);
    reliefRepository.refresh();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    reliefRepository.removeListener(_changed);
    super.dispose();
  }

  void _acceptTask(Json task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => R12AssignedTaskDetailScreen(taskId: task['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(
        title: 'Yêu cầu đang phụ trách',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatus(),
            TextButton(
              onPressed: () => reliefRepository.refresh(),
              child: const Text("Tải lại danh sách"),
            ),
            // Status bar
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_tasks.length} yêu cầu đang phụ trách',
                      style: AppTypography.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tải lại để cập nhật',
                    style: AppTypography.secondary.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),

            // Offline Download Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_download_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuẩn bị vào vùng mất sóng?',
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 15,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Xem danh sách ngoại tuyến minh họa',
                          style: AppTypography.secondary.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: const Size(48, 42),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const R17OfflineDownloadScreen(),
                        ),
                      );
                    },
                    child: const Text('Xem danh sách'),
                  ),
                ],
              ),
            ),

            // Tasks List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: task['isUrgent']
                            ? AppColors.danger.withOpacity(0.5)
                            : AppColors.borderSubtle,
                        width: task['isUrgent'] ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              shortRequestId(task['id']),
                              style: AppTypography.cardTitle.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: task['isUrgent']
                                    ? AppColors.dangerContainer
                                    : AppColors.warningContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task['urgency'] as String,
                                style: AppTypography.chip.copyWith(
                                  color: task['isUrgent']
                                      ? AppColors.danger
                                      : AppColors.warning,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          task['title'] as String,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                task['address'] as String,
                                style: AppTypography.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task['distance'].toString().isEmpty
                                  ? 'Chưa có khoảng cách'
                                  : 'Cách đội: ${task['distance']}',
                              style: AppTypography.secondaryMedium.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              task['time'] as String,
                              style: AppTypography.secondary.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          height: 20,
                          color: AppColors.borderSubtle,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task['tools'].toString().isEmpty
                                    ? 'Chưa có thông tin trang bị'
                                    : 'Trang bị: ${task['tools']}',
                                style: AppTypography.secondary.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _acceptTask(task),
                              child: const Text('Xem yêu cầu'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
