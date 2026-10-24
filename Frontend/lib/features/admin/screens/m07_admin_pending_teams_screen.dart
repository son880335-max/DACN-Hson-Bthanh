import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_header.dart';
import 'm08_admin_team_detail_approval_screen.dart';

class M07AdminPendingTeamsScreen extends StatefulWidget {
  const M07AdminPendingTeamsScreen({super.key});

  @override
  State<M07AdminPendingTeamsScreen> createState() => _M07AdminPendingTeamsScreenState();
}

class _M07AdminPendingTeamsScreenState extends State<M07AdminPendingTeamsScreen> {
  final List<Map<String, dynamic>> _teams = [
    {
      'id': 'TEAM-DK-04',
      'name': 'Đội Cứu trợ Tình nguyện Sao Vàng',
      'leader': 'Trần Văn Mạnh • 0988 123 456',
      'members': 4,
      'equipment': '02 Thuyền hơi gắn máy 15HP, 10 áo phao, 02 túi y tế',
      'certification': 'Chứng chỉ cứu hộ đường thủy & Sơ cấp cứu Chữ thập đỏ',
      'status': 'pending',
    },
    {
      'id': 'TEAM-DK-05',
      'name': 'Câu lạc bộ Ca-nô Sông Đáy',
      'leader': 'Vũ Hữu Đạt • 0914 998 776',
      'members': 3,
      'equipment': '01 Ca-nô vỏ nhôm 25HP, 06 áo phao',
      'certification': 'Bằng lái tàu thuyền dân dụng hạng 2',
      'status': 'pending',
    },
    {
      'id': 'TEAM-HT-01',
      'name': 'Đội Cứu trợ Hương Thủy',
      'leader': 'Lê Văn Bình • 0983 234 567',
      'members': 4,
      'equipment': '02 Thuyền cao su, 01 xe bán tải, 12 áo phao',
      'certification': 'Đã xác minh đầy đủ điều kiện an toàn',
      'status': 'approved',
    },
  ];

  void _openTeamDetail(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => M08AdminTeamDetailApprovalScreen(
          teamData: _teams[index],
          onStatusChanged: (newStatus) {
            setState(() {
              _teams[index]['status'] = newStatus;
            });
          },
        ),
      ),
    );
  }

  void _approveTeam(int index) {
    setState(() {
      _teams[index]['status'] = 'approved';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Đã phê duyệt và kích hoạt tài khoản cho ${_teams[index]['name']}!'),
      ),
    );
  }

  void _rejectTeam(int index) {
    setState(() {
      _teams[index]['status'] = 'rejected';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text('Đã từ chối hồ sơ ${_teams[index]['name']}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(
        title: 'Xét duyệt hồ sơ Đội cứu hộ',
        showBackButton: false,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _teams.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final team = _teams[index];
            final isPending = team['status'] == 'pending';
            final isApproved = team['status'] == 'approved';

            return Container(
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
                      Text(team['id'] as String, style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? AppColors.successContainer
                              : isPending
                                  ? AppColors.warningContainer
                                  : AppColors.dangerContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isApproved ? 'Đã phê duyệt' : isPending ? 'Chờ thẩm định' : 'Từ chối',
                          style: AppTypography.chip.copyWith(
                            color: isApproved ? AppColors.success : isPending ? AppColors.warning : AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(team['name'] as String, style: AppTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text('Trưởng đội: ${team['leader']}', style: AppTypography.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Nhân sự: ${team['members']} thành viên', style: AppTypography.secondary),
                  const SizedBox(height: 4),
                  Text('Phương tiện: ${team['equipment']}', style: AppTypography.secondary),
                  const SizedBox(height: 4),
                  Text('Năng lực: ${team['certification']}',
                      style: AppTypography.secondaryMedium.copyWith(color: AppColors.primaryDark)),
                  const Divider(height: 16, color: AppColors.borderSubtle),

                  // View full profile & proofs button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.file_present_outlined, size: 18),
                      label: const Text('Xem chi tiết hồ sơ & minh chứng (4 tệp)'),
                      onPressed: () => _openTeamDetail(index),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (isPending)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _rejectTeam(index),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _approveTeam(index),
                            child: const Text('Phê duyệt nhanh'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(isApproved ? Icons.verified : Icons.cancel,
                            color: isApproved ? AppColors.success : AppColors.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isApproved ? 'Đội đã sẵn sàng nhận nhiệm vụ cứu hộ' : 'Hồ sơ chưa đạt yêu cầu an toàn kỹ thuật',
                            style: AppTypography.secondaryMedium.copyWith(
                              color: isApproved ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
