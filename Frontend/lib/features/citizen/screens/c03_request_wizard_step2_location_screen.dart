import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'c04_request_wizard_step3_photo_screen.dart';

class C03RequestWizardStep2LocationScreen extends StatefulWidget {
  final List<String> reliefTypes;
  final int totalPeople;
  final String urgency;

  const C03RequestWizardStep2LocationScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
  });

  @override
  State<C03RequestWizardStep2LocationScreen> createState() => _C03RequestWizardStep2LocationScreenState();
}

class _C03RequestWizardStep2LocationScreenState extends State<C03RequestWizardStep2LocationScreen> {
  final _addressController = TextEditingController(text: 'Số 42, Thôn Nam Hài, Xã Nam Phương Tiến, Huyện Chương Mỹ');
  final _landmarkController = TextEditingController(text: 'Nhà cấp 4 màu xanh gần đình làng, nước dâng ngập cổng');
  String _gpsStatus = 'Tọa độ: 20.8841° N, 105.6215° E (Độ chính xác: ±8m)';
  bool _isLocating = false;

  void _getCurrentGps() {
    setState(() => _isLocating = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _gpsStatus = 'Tọa độ cập nhật: 20.8842° N, 105.6214° E (Độ chính xác: ±5m)';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật vị trí GPS thành công.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(title: 'Bước 2/4: Vị trí cứu trợ'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TIẾN TRÌNH SOẠN THẢO', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary, fontSize: 13)),
                          Text('Bước 2 / 4', style: AppTypography.secondaryMedium.copyWith(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.50,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Vị trí cần cứu trợ', style: AppTypography.sectionTitle),
                      const SizedBox(height: 2),
                      Text(
                        'Kết hợp định vị GPS và mô tả đặc điểm nhận dạng để đội cứu hộ tiếp cận chính xác trong đêm hoặc sương mù.',
                        style: AppTypography.secondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Map Preview Container
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 48, color: AppColors.danger),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Text('Điểm cứu hộ của bạn', style: AppTypography.secondaryMedium),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          onPressed: _getCurrentGps,
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                          child: _isLocating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // GPS status box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsStatus,
                          style: AppTypography.secondaryMedium.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Manual Address Input (US-027)
                Text('Địa chỉ chi tiết (Thôn / Xã / Huyện)', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _addressController,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.home, color: AppColors.textSecondary),
                    hintText: 'Nhập số nhà, thôn xóm, xã phường...',
                  ),
                ),

                const SizedBox(height: 16),

                // Landmark / Identification note (US-027)
                Text('Đặc điểm nhận diện & Điểm mốc dễ thấy', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _landmarkController,
                  maxLines: 3,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Gần trạm biến áp, cây gạo đầu làng, nhà có mái tôn xanh...',
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  text: 'Tiếp tục sang bước 3 (Chụp ảnh)',
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => C04RequestWizardStep3PhotoScreen(
                          reliefTypes: widget.reliefTypes,
                          totalPeople: widget.totalPeople,
                          urgency: widget.urgency,
                          address: _addressController.text,
                          landmark: _landmarkController.text,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
