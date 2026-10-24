import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_chip.dart';

class C10TrackRescueScreen extends StatefulWidget {
  final String requestId;

  const C10TrackRescueScreen({
    super.key,
    this.requestId = 'CR-0247',
  });

  @override
  State<C10TrackRescueScreen> createState() => _C10TrackRescueScreenState();
}

class _C10TrackRescueScreenState extends State<C10TrackRescueScreen> {
  bool _alertSent = false;

  void _sendWaterRisingAlert() {
    setState(() => _alertSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.danger,
        content: Text('Đã gửi cảnh báo khẩn cấp: Nước đang tiếp tục dâng tới đội cứu hộ!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Theo dõi cứu trợ ${widget.requestId}',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top ETA banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_boat, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đội cứu hộ đang di chuyển tới bạn', style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDark)),
                          const SizedBox(height: 2),
                          Text('Khoảng cách: 1.4 km • Dự kiến: 12 phút nữa', style: AppTypography.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mock Map Viewport
              Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E6E3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  children: [
                    // Grid background lines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridMapPainter(),
                      ),
                    ),

                    // Water flood zone overlay
                    Positioned(
                      top: 40,
                      left: 30,
                      right: 40,
                      bottom: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x330284C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x660284C7), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            'Khu vực ngập sâu Chương Mỹ (~1.5m)',
                            style: AppTypography.secondary.copyWith(color: const Color(0xFF0369A1), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                    // Citizen marker (Home)
                    Positioned(
                      top: 70,
                      right: 70,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Vị trí của bạn', style: AppTypography.chip.copyWith(color: Colors.white, fontSize: 12)),
                          ),
                          const Icon(Icons.location_on, color: AppColors.danger, size: 36),
                        ],
                      ),
                    ),

                    // Rescue boat marker
                    Positioned(
                      bottom: 60,
                      left: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Thuyền Sao Vàng (1.4km)', style: AppTypography.chip.copyWith(color: Colors.white, fontSize: 12)),
                          ),
                          const Icon(Icons.directions_boat_filled, color: AppColors.primary, size: 34),
                        ],
                      ),
                    ),

                    // GPS Coordinates overlay
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text('GPS: 20.8841° N, 105.6215° E', style: AppTypography.secondary.copyWith(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rescue Team Card
              Text('Thông tin đội cứu hộ tiếp nhận', style: AppTypography.sectionTitle),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text('Đội Cứu trợ Tình nguyện Sao Vàng', style: AppTypography.cardTitle),
                        ),
                        const SizedBox(width: 8),
                        const StatusChip(status: RequestStatus.inProgress),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Đội trưởng: Trần Văn Mạnh (4 thành viên cứu hộ)', style: AppTypography.body),
                    const SizedBox(height: 4),
                    Text('Phương tiện: 02 thuyền hơi gắn máy, phao cứu sinh & túi sơ cứu', style: AppTypography.secondary),
                    const Divider(height: 24, color: AppColors.borderSubtle),
                    AppButton(
                      text: 'Gọi đội trưởng: 0988 123 456',
                      icon: Icons.phone_in_talk,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang kết nối cuộc gọi tới Đội trưởng Trần Văn Mạnh...')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Emergency water level warning button
              AppButton(
                text: _alertSent ? 'Đã gửi báo động nước dâng' : 'Báo động khẩn: Nước dâng nhanh hơn!',
                icon: Icons.warning_amber_rounded,
                variant: AppButtonVariant.danger,
                onPressed: _alertSent ? null : _sendWaterRisingAlert,
              ),
              const SizedBox(height: 20),

              // Safety recommendations
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lưu ý an toàn khi chờ thuyền đón:', style: AppTypography.cardTitle),
                    const SizedBox(height: 8),
                    Text('• Mặc áo phao hoặc chuẩn bị các vật dụng nổi sẵn sàng.', style: AppTypography.body),
                    Text('• Bọc giấy tờ quan trọng và điện thoại vào túi nilon chống nước.', style: AppTypography.body),
                    Text('• Khi nghe tiếng động cơ thuyền, hãy bật đèn flash hoặc vẫy vải sáng màu.', style: AppTypography.body),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7DDD9)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
