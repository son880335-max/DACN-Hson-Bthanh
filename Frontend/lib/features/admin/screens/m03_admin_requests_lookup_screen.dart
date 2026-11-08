import '../../../core/data/request_presentation.dart';

import 'package:flutter/material.dart';

import '../../citizen/screens/c08_request_detail_waiting_screen.dart';
import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/widgets/sync_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';

class M03AdminRequestsLookupScreen extends StatefulWidget {
  const M03AdminRequestsLookupScreen({super.key});

  @override
  State<M03AdminRequestsLookupScreen> createState() =>
      _M03AdminRequestsLookupScreenState();
}

class _M03AdminRequestsLookupScreenState
    extends State<M03AdminRequestsLookupScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Tất cả, 1: Khẩn cấp, 2: Đang chờ, 3: Đã xử lý

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
    _searchController.dispose();
    super.dispose();
  }

  void _assignTeamDialog(Json request) {
    showFailure(
      context,
      'Chức năng phân công đội chưa khả dụng. Chưa thay đổi đội phụ trách.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final filtered = _allRequests.where((req) {
      if (query.isNotEmpty) {
        final match =
            req['id'].toLowerCase().contains(query) ||
            req['citizen'].toLowerCase().contains(query) ||
            req['address'].toLowerCase().contains(query) ||
            req['phone'].contains(query);
        if (!match) return false;
      }
      if (_selectedFilter == 1) return req['isUrgent'] == true;
      if (_selectedFilter == 2) return req['status'] == RequestStatus.waiting;
      if (_selectedFilter == 3) return req['status'] == RequestStatus.completed;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Yêu cầu cứu trợ',
        actions: [
          IconButton(
            tooltip: 'Tải lại danh sách',
            onPressed: () => reliefRepository.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
        showBackButton: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatus(),
            if (reliefRepository.loading) const LinearProgressIndicator(),
            // Search Input
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Tìm mã yêu cầu, số điện thoại, tên, địa chỉ',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.canvas,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Filter Tabs
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(0, 'Tất cả (${_allRequests.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      1,
                      'Khẩn cấp (${_allRequests.where((r) => r['isUrgent'] == true).length})',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      2,
                      'Chờ tiếp nhận (${_allRequests.where((r) => r['stage'] == 'waiting').length})',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      3,
                      'Đã hoàn thành (${_allRequests.where((r) => r['stage'] == 'completed').length})',
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),

            // List of Requests
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Không tìm thấy yêu cầu phù hợp.',
                        style: AppTypography.body,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = filtered[index];
                        return Container(
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        shortRequestId(req['id']),
                                        style: AppTypography.cardTitle.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (req['isUrgent'] == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.dangerContainer,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Khẩn cấp',
                                            style: AppTypography.secondary
                                                .copyWith(
                                                  color: AppColors.danger,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  StatusChip(
                                    status: req['status'] as RequestStatus,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${req['citizen']} • ${req['phone']}',
                                style: AppTypography.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                req['address'] as String,
                                style: AppTypography.secondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nhu cầu: ${req['needs']}',
                                style: AppTypography.secondaryMedium,
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        C08RequestDetailWaitingScreen(
                                          requestId: req['id'],
                                        ),
                                  ),
                                ),
                                icon: const Icon(Icons.fact_check_outlined),
                                label: const Text('Xem chi tiết'),
                              ),
                              const Divider(
                                height: 16,
                                color: AppColors.borderSubtle,
                              ),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    req['time'] as String,
                                    style: AppTypography.secondary.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (req['status'] == RequestStatus.waiting)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.person_add_alt_1,
                                        size: 18,
                                      ),
                                      label: const Text('Phân công đội'),
                                      onPressed: () => _assignTeamDialog(req),
                                    )
                                  else
                                    Text(
                                      'Đã có đội phụ trách',
                                      style: AppTypography.secondaryMedium
                                          .copyWith(color: AppColors.success),
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

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTypography.chip.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
