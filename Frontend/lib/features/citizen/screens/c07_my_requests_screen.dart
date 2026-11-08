import '../../../core/data/request_presentation.dart';

import 'package:flutter/material.dart';

import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/widgets/sync_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';
import 'c02_request_wizard_step1_screen.dart';
import 'c08_request_detail_waiting_screen.dart';

class C07MyRequestsScreen extends StatefulWidget {
  const C07MyRequestsScreen({super.key});

  @override
  State<C07MyRequestsScreen> createState() => _C07MyRequestsScreenState();
}

class _C07MyRequestsScreenState extends State<C07MyRequestsScreen> {
  int _selectedFilter = 0; // 0: Tất cả, 1: Đang chờ/xử lý, 2: Đã hoàn thành

  List<Json> get _allRequests =>
      reliefRepository.items.map(requestCard).toList();
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

  @override
  Widget build(BuildContext context) {
    final filtered = _allRequests.where((req) {
      if (_selectedFilter == 1) {
        return req['status'] == RequestStatus.waiting ||
            req['status'] == RequestStatus.assigned;
      } else if (_selectedFilter == 2) {
        return req['status'] == RequestStatus.completed;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(title: 'Yêu cầu của tôi', showBackButton: false),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            Container(
              color: AppColors.surface,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterTab(0, 'Tất cả (${_allRequests.length})'),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      1,
                      'Đang xử lý (${_allRequests.where((r) => [RequestStatus.waiting, RequestStatus.assigned].contains(r['status'])).length})',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      2,
                      'Đã xong (${_allRequests.where((r) => r['status'] == RequestStatus.completed).length})',
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),

            const SyncStatus(),
            if (reliefRepository.loading) const LinearProgressIndicator(),
            // Request List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Không có yêu cầu nào trong mục này.',
                            style: AppTypography.body,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildRequestCard(item);
                      },
                    ),
            ),

            if (reliefRepository.nextCursor != null)
              TextButton(
                onPressed: () => reliefRepository.refresh(more: true),
                child: const Text('Xem thêm'),
              ),
            TextButton(
              onPressed: () => reliefRepository.refresh(),
              child: const Text('Tải lại danh sách'),
            ),
            // Bottom CTA to create new request
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: AppButton(
                text: 'Tạo yêu cầu cứu trợ',
                icon: Icons.add,
                onPressed: _tryCreateNewRequest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tryCreateNewRequest() {
    if (!reliefRepository.signedIn) {
      showFailure(context, 'Đăng nhập để gửi yêu cầu.');
      return;
    }
    if (reliefRepository.operations.any((o) => o['kind'] != 'evidence')) {
      showFailure(
        context,
        'Còn thao tác chờ xác nhận. Hãy xem trạng thái gửi trước.',
      );
      return;
    }
    final activeReq = _allRequests.firstWhere(
      (req) =>
          req['status'] == RequestStatus.waiting ||
          req['status'] == RequestStatus.assigned,
      orElse: () => <String, dynamic>{},
    );

    if (activeReq.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Không thể tạo thêm yêu cầu',
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đang có yêu cầu cứu trợ [${activeReq['id']}] chưa hoàn tất (${activeReq['status'] == RequestStatus.waiting ? 'Đang chờ tiếp nhận' : 'Đang xử lý'}).',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mỗi tài khoản có một yêu cầu đang mở. Bạn có thể gửi mới sau khi yêu cầu hiện tại hoàn thành hoặc được xác nhận hủy. Khi chưa có đội tiếp nhận, bạn có thể sửa nội dung đã gửi.',
                style: AppTypography.secondary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => C08RequestDetailWaitingScreen(
                      requestId: activeReq['id'] as String,
                      initialStatus: activeReq['status'] as ReliefStatus,
                      title: activeReq['title'] as String?,
                      address: activeReq['address'] as String?,
                      people: activeReq['people'] as int?,
                      urgency: activeReq['urgency'] as String?,
                    ),
                  ),
                );
              },
              child: const Text('Xem yêu cầu hiện tại'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const C02RequestWizardStep1Screen()),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.chip.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => C08RequestDetailWaitingScreen(
              requestId: item['id'] as String,
              initialStatus: item['status'] as ReliefStatus,
              title: item['title'] as String?,
              address: item['address'] as String?,
              people: item['people'] as int?,
              urgency: item['urgency'] as String?,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  shortRequestId(item['id']),
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                StatusChip(status: item['status'] as RequestStatus),
              ],
            ),
            const SizedBox(height: 8),
            Text(item['title'] as String, style: AppTypography.bodyMedium),
            const SizedBox(height: 4),
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
                    item['address'] as String,
                    style: AppTypography.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  '${item['people']} người cần trợ giúp',
                  style: AppTypography.secondaryMedium,
                ),
                Text(
                  item['time'] as String,
                  style: AppTypography.secondary.copyWith(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
