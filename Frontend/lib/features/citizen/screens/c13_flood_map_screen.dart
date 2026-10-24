import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_header.dart';

class C13FloodMapScreen extends StatefulWidget {
  const C13FloodMapScreen({super.key});

  @override
  State<C13FloodMapScreen> createState() => _C13FloodMapScreenState();
}

class _C13FloodMapScreenState extends State<C13FloodMapScreen> {
  bool _showShelters = true;
  bool _showDeepFloods = true;
  bool _showSupplies = false;
  int _selectedShelterIndex = 0;

  final List<Map<String, dynamic>> _shelters = [
    {
      'name': 'Trường THPT Chương Mỹ A',
      'distance': '1.8 km',
      'capacity': 'Còn 120 chỗ tiếp nhận',
      'facilities': 'Có điện máy nổ, nước sạch, trạm y tế dã chiến',
      'isSafe': true,
      'pin': const Offset(0.25, 0.65),
    },
    {
      'name': 'Nhà văn hóa Xã Tân Tiến',
      'distance': '2.4 km',
      'capacity': 'Còn 45 chỗ tiếp nhận',
      'facilities': 'Khuôn viên cao ráo 2 tầng, có bếp nấu tập trung',
      'isSafe': true,
      'pin': const Offset(0.78, 0.70),
    },
    {
      'name': 'Trụ sở UBND Xã Nam Phương Tiến',
      'distance': '3.1 km',
      'capacity': 'Điểm điều phối ca nô trung chuyển',
      'facilities': 'Đội xuồng máy trực 24/24',
      'isSafe': true,
      'pin': const Offset(0.50, 0.20),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const AppHeader(
        title: 'Bản đồ ngập & Điểm sơ tán',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips row
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _showShelters,
                      label: Text('Điểm sơ tán an toàn', style: AppTypography.chip.copyWith(fontSize: 13)),
                      selectedColor: AppColors.primaryContainer,
                      checkmarkColor: AppColors.primaryDark,
                      onSelected: (val) => setState(() => _showShelters = val),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _showDeepFloods,
                      label: Text('Vùng ngập sâu (>1m)', style: AppTypography.chip.copyWith(fontSize: 13)),
                      selectedColor: AppColors.dangerContainer,
                      checkmarkColor: AppColors.danger,
                      onSelected: (val) => setState(() => _showDeepFloods = val),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _showSupplies,
                      label: Text('Kho tiếp tế phẩm', style: AppTypography.chip.copyWith(fontSize: 13)),
                      selectedColor: AppColors.successContainer,
                      checkmarkColor: AppColors.success,
                      onSelected: (val) => setState(() => _showSupplies = val),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),

            // Warning Notice Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.dangerContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Báo động lũ cấp 3 sông Bùi • Nước ngập sâu tại vùng trũng Nam Phương Tiến',
                      style: AppTypography.secondaryMedium.copyWith(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Map viewport with ClipRRect to strictly prevent drawing outside bounds
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  color: const Color(0xFFDCECE8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      // Map Background Painting
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FloodVectorMapPainter(
                            showFloods: _showDeepFloods,
                            showShelters: _showShelters,
                          ),
                        ),
                      ),

                      // User current position pin
                      Positioned(
                        left: 110,
                        top: 130,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Vị trí của bạn', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Icon(Icons.location_on, color: AppColors.danger, size: 28),
                          ],
                        ),
                      ),

                      // Shelter Pins overlay
                      if (_showShelters) ...[
                        _buildShelterPin(0, 'THPT Chương Mỹ A', 50, 160),
                        _buildShelterPin(1, 'NVH Tân Tiến', 190, 175),
                        _buildShelterPin(2, 'UBND Nam Phương Tiến', 130, 45),
                      ],

                      // Map Legend (bottom-left)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLegendDot(AppColors.danger, 'Ngập sâu >1.5m'),
                              const SizedBox(height: 3),
                              _buildLegendDot(Colors.orange, 'Ngập 0.5 - 1.0m'),
                              const SizedBox(height: 3),
                              _buildLegendDot(AppColors.primary, 'Điểm sơ tán cao ráo'),
                            ],
                          ),
                        ),
                      ),

                      // Map Controls (bottom-right)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Column(
                          children: [
                            _buildMapControlBtn(Icons.add, () {}),
                            const SizedBox(height: 4),
                            _buildMapControlBtn(Icons.remove, () {}),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Shelters List section
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Điểm tránh trú gần nhất', style: AppTypography.cardTitle),
                          Text('${_shelters.length} địa điểm', style: AppTypography.secondary),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _shelters.length,
                        separatorBuilder: (_, __) => const Divider(height: 10, color: AppColors.borderSubtle),
                        itemBuilder: (context, index) {
                          final shelter = _shelters[index];
                          final isSelected = index == _selectedShelterIndex;
                          return InkWell(
                            onTap: () => setState(() => _selectedShelterIndex = index),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryContainer.withOpacity(0.5) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.shield_outlined, color: AppColors.primaryDark, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(shelter['name'] as String, style: AppTypography.bodyMedium),
                                        const SizedBox(height: 2),
                                        Text('${shelter['distance']} • ${shelter['capacity']}',
                                            style: AppTypography.secondaryMedium.copyWith(color: AppColors.primaryDark, fontSize: 13)),
                                        Text(shelter['facilities'] as String,
                                            style: AppTypography.secondary.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.directions, color: AppColors.primary),
                                    tooltip: 'Chỉ đường',
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đang vẽ lộ trình an toàn tới ${shelter['name']}...')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelterPin(int index, String name, double left, double top) {
    final isSelected = index == _selectedShelterIndex;
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => setState(() => _selectedShelterIndex = index),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.shield,
              color: isSelected ? AppColors.primaryDark : AppColors.primary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControlBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: AppColors.textPrimary),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.secondary.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _FloodVectorMapPainter extends CustomPainter {
  final bool showFloods;
  final bool showShelters;

  _FloodVectorMapPainter({required this.showFloods, required this.showShelters});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Grid lines for terrain reference
    final gridPaint = Paint()
      ..color = const Color(0xFFCBE0DC)
      ..strokeWidth = 0.8;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // River Sông Bùi (curved blue path)
    final riverPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final riverPath = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.15,
        size.width * 0.6,
        size.height * 0.6,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(riverPath, riverPaint);

    // Flood water zones
    if (showFloods) {
      final deepFloodPaint = Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.45, size.height * 0.45),
          width: size.width * 0.5,
          height: size.height * 0.35,
        ),
        deepFloodPaint,
      );

      final moderatePaint = Paint()
        ..color = const Color(0xFFF59E0B).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.75, size.height * 0.35),
          width: size.width * 0.35,
          height: size.height * 0.25,
        ),
        moderatePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
