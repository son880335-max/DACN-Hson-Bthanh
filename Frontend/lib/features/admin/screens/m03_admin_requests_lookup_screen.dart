import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';

class M03AdminRequestsLookupScreen extends StatefulWidget {
  const M03AdminRequestsLookupScreen({super.key});

  @override
  State<M03AdminRequestsLookupScreen> createState() => _M03AdminRequestsLookupScreenState();
}

class _M03AdminRequestsLookupScreenState extends State<M03AdminRequestsLookupScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Tất cả, 1: Khẩn cấp, 2: Đang chờ, 3: Đã xử lý

  final List<Map<String, dynamic>> _allRequests = [
    {
      'id': 'CR-0247',
      'citizen': 'Nguyễn Văn An',
      'phone': '0912 345 678',
      'address': 'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
      'needs': 'Sơ tán khẩn cấp (4 người: 2 người già, 1 trẻ nhỏ)',
      'status': RequestStatus.waiting,
      'isUrgent': true,
      'time': '18:20 23/10',
    },
    {
      'id': 'CR-0251',
      'citizen': 'Hoàng Thị Mai',
      'phone': '0988 776 554',
      'address': 'Thôn Nhân Lý, Xã Nam Phương Tiến',
      'needs': 'Y tế khẩn cấp: Sản phụ chuyển dạ cần ca nô',
      'status': RequestStatus.waiting,
      'isUrgent': true,
      'time': '18:15 23/10',
    },
    {
      'id': 'CR-0238',
      'citizen': 'Đặng Quốc Bảo',
      'phone': '0903 221 445',
      'address': 'Khu gò đồi, Xã Tân Tiến, Chương Mỹ',
      'needs': 'Tiếp tế nước uống & lương khô cho 6 người',
      'status': RequestStatus.inProgress,
      'isUrgent': false,
      'time': '17:30 23/10',
    },
    {
      'id': 'CR-0199',
      'citizen': 'Phạm Thu Hằng',
      'phone': '0977 443 219',
      'address': 'Khu tập thể ven sông, Chương Mỹ',
      'needs': 'Đã hoàn tất đưa về điểm sơ tán THPT Chương Mỹ A',
      'status': RequestStatus.completed,
      'isUrgent': false,
      'time': '16:00 23/10',
    },
  ];

  void _assignTeamDialog(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Điều phối đội cứu hộ cho ${req['id']}', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người dân: ${req['citizen']} (${req['phone']})', style: AppTypography.bodyMedium),
            const SizedBox(height: 4),
            Text('Nhu cầu: ${req['needs']}', style: AppTypography.secondary),
            const SizedBox(height: 12),
            Text('Chọn đội cứu hộ sẵn sàng:', style: AppTypography.secondaryMedium),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.directions_boat, color: AppColors.primary),
              title: const Text('Đội Hương Thủy (Cách 2.1km)'),
              subtitle: const Text('02 Thuyền hơi • 4 thành viên'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã điều phối Đội Hương Thủy cho yêu cầu ${req['id']} thành công!')),
                  );
                },
                child: const Text('Gán'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Đóng', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final filtered = _allRequests.where((req) {
      if (query.isNotEmpty) {
        final match = req['id'].toLowerCase().contains(query) ||
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
      appBar: const AppHeader(
        title: 'Tra cứu & Điều phối yêu cầu',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã đơn, SĐT, tên hoặc địa bàn...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.canvas,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                    _buildFilterChip(1, 'Khẩn cấp (2)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Chờ phân công (2)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(3, 'Đã an toàn (1)'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),

            // List of Requests
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('Không tìm thấy yêu cầu phù hợp.', style: AppTypography.body))
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(req['id'] as String, style: AppTypography.cardTitle.copyWith(color: AppColors.primary)),
                                      const SizedBox(width: 8),
                                      if (req['isUrgent'] == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.dangerContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('Khẩn cấp', style: AppTypography.secondary.copyWith(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  StatusChip(status: req['status'] as RequestStatus),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${req['citizen']} • ${req['phone']}', style: AppTypography.bodyMedium),
                              const SizedBox(height: 4),
                              Text(req['address'] as String, style: AppTypography.secondary),
                              const SizedBox(height: 4),
                              Text('Nhu cầu: ${req['needs']}', style: AppTypography.secondaryMedium),
                              const Divider(height: 16, color: AppColors.borderSubtle),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(req['time'] as String, style: AppTypography.secondary.copyWith(fontSize: 13)),
                                  if (req['status'] == RequestStatus.waiting)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                                      label: const Text('Gán đội cứu hộ'),
                                      onPressed: () => _assignTeamDialog(req),
                                    )
                                  else
                                    Text('Đã có đơn vị xử lý', style: AppTypography.secondaryMedium.copyWith(color: AppColors.success)),
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
