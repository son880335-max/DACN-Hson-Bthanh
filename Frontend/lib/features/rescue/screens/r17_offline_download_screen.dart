import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'r13_rescue_navigation_route_screen.dart';

class R17OfflineDownloadScreen extends StatefulWidget {
  const R17OfflineDownloadScreen({super.key});

  @override
  State<R17OfflineDownloadScreen> createState() => _R17OfflineDownloadScreenState();
}

class _R17OfflineDownloadScreenState extends State<R17OfflineDownloadScreen> {
  int _selectedBatchSize = 3; // 3, 5, 10
  bool _isDownloading = false;

  final List<Map<String, dynamic>> _availableRequests = [
    {
      'id': 'CR-0247',
      'citizen': 'Nguyễn Văn An',
      'phone': '0912 345 678',
      'address': 'Số 42, Thôn Nam Hài, Nam Phương Tiến, Chương Mỹ',
      'people': 4,
      'needs': 'Sơ tán khẩn cấp, 2 người già, 1 trẻ sơ sinh',
      'urgency': 'Cực kỳ khẩn cấp',
      'distance': '850 m',
      'gps': '20.8841° N, 105.6215° E',
      'notes': 'Nhà cấp 4 xanh gần đình làng, nước dâng ngập cổng 1.5m',
    },
    {
      'id': 'CR-0248',
      'citizen': 'Trần Thị Tươi',
      'phone': '0988 332 114',
      'address': 'Xóm 3, Thôn Nhân Lý, Nam Phương Tiến',
      'people': 2,
      'needs': 'Thuốc cao huyết áp, nước sạch đóng chai',
      'urgency': 'Cần trợ giúp',
      'distance': '1.4 km',
      'gps': '20.8885° N, 105.6240° E',
      'notes': 'Nhà 2 tầng mái bằng, vẫy cờ đỏ ở ban công tầng 2',
    },
    {
      'id': 'CR-0249',
      'citizen': 'Đặng Quốc Bảo',
      'phone': '0903 221 445',
      'address': 'Khu gò đồi, Xã Tân Tiến, Chương Mỹ',
      'people': 5,
      'needs': 'Lương khô, sữa trẻ em & phao cứu sinh',
      'urgency': 'Cần trợ giúp',
      'distance': '2.2 km',
      'gps': '20.8920° N, 105.6190° E',
      'notes': 'Cụm nhà ven chân đồi, lối vào có rặng tre ngập nước',
    },
    {
      'id': 'CR-0250',
      'citizen': 'Hoàng Văn Vinh',
      'phone': '0977 889 001',
      'address': 'Thôn Tiến Tiên, Xã Tân Tiến, Chương Mỹ',
      'people': 3,
      'needs': 'Sơ tán gia đình có phụ nữ có thai',
      'urgency': 'Cực kỳ khẩn cấp',
      'distance': '2.8 km',
      'gps': '20.8965° N, 105.6150° E',
      'notes': 'Nhà ngói đỏ sát mép nước lũ dâng nhanh',
    },
    {
      'id': 'CR-0251',
      'citizen': 'Lê Thị Thu',
      'phone': '0915 667 882',
      'address': 'Xã Hoàng Văn Thụ, Chương Mỹ',
      'people': 4,
      'needs': 'Thực phẩm khô & áo phao',
      'urgency': 'Cần trợ giúp',
      'distance': '3.4 km',
      'gps': '20.9010° N, 105.6120° E',
      'notes': 'Nhà cấp 4, nước ngập sàn 0.6m',
    },
  ];

  void _startDownloadAndAssign() {
    setState(() => _isDownloading = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isDownloading = false);
        final assignedTasks = _availableRequests.take(_selectedBatchSize).toList();
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
                Text('Tải thành công', style: AppTypography.cardTitle),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã phân công $_selectedBatchSize nhiệm vụ cho Đội Hương Thủy.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bản đồ, tọa độ GPS và thông tin người dân đã được lưu ngoại tuyến. Đội có thể bắt đầu di chuyển khi không có mạng.',
                  style: AppTypography.body,
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.navigation, size: 20),
                label: const Text('Bắt đầu dẫn đường'),
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => R13RescueNavigationRouteScreen(tasks: assignedTasks),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewList = _availableRequests.take(_selectedBatchSize).toList();
    final totalPeople = previewList.fold<int>(0, (sum, item) => sum + (item['people'] as int));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Tải danh sách ngoại tuyến',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.signal_wifi_off, color: AppColors.primaryDark, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chuẩn bị vào vùng mất sóng',
                                  style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tải gói nhiệm vụ trước khi xuất phát. Hệ thống sẽ phân công danh sách này cho đội để tránh tiếp nhận trùng lặp.',
                                  style: AppTypography.secondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Batch size selector
                    Text('Chọn số lượng nhiệm vụ cần tải', style: AppTypography.sectionTitle),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildBatchOption(3, '3 nhiệm vụ', 'Phù hợp 1 xuồng máy'),
                        const SizedBox(width: 10),
                        _buildBatchOption(5, '5 nhiệm vụ', 'Phù hợp 2 xuồng máy'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildBatchOption(10, '10 nhiệm vụ', 'Cụm xã Nam Phương Tiến'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Summary statistics
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Số hộ nhận', '$_selectedBatchSize hộ', Icons.home_work_outlined),
                          Container(width: 1, height: 36, color: AppColors.borderSubtle),
                          _buildStatItem('Tổng số người', '$totalPeople người', Icons.people_outline),
                          Container(width: 1, height: 36, color: AppColors.borderSubtle),
                          _buildStatItem('Bán kính', 'Dưới 3.5 km', Icons.near_me_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // List of tasks to be downloaded
                    Text('Danh sách địa điểm tiếp nhận ($_selectedBatchSize điểm)', style: AppTypography.sectionTitle),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: previewList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = previewList[index];
                        final isEmergency = item['urgency'] == 'Cực kỳ khẩn cấp';
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isEmergency ? AppColors.danger.withOpacity(0.4) : AppColors.borderSubtle,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primary,
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(item['id'] as String, style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDark)),
                                  const Spacer(),
                                  Text('Cách: ${item['distance']}', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primaryDark)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('${item['citizen']} • SĐT: ${item['phone']} (${item['people']} người)', style: AppTypography.bodyMedium),
                              const SizedBox(height: 2),
                              Text(item['address'] as String, style: AppTypography.secondary),
                              const SizedBox(height: 4),
                              Text('Nhu cầu: ${item['needs']}', style: AppTypography.secondaryMedium.copyWith(color: isEmergency ? AppColors.danger : AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text('Mốc nhận dạng: ${item['notes']}', style: AppTypography.secondary.copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: AppButton(
                text: 'Tải gói $_selectedBatchSize nhiệm vụ ngoại tuyến',
                icon: Icons.cloud_download,
                isLoading: _isDownloading,
                onPressed: _startDownloadAndAssign,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchOption(int count, String title, String subtitle) {
    final isSelected = _selectedBatchSize == count;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedBatchSize = count),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTypography.secondary.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
        Text(label, style: AppTypography.secondary.copyWith(fontSize: 12)),
      ],
    );
  }
}
