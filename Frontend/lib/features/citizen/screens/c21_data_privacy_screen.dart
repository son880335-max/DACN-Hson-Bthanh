import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_header.dart';

class C21DataPrivacyScreen extends StatelessWidget {
  const C21DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Thông tin sử dụng dữ liệu',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Chính sách bảo vệ dữ liệu cá nhân',
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Ứng dụng Cứu trợ đồng bào lũ lụt cam kết thu thập tối thiểu và bảo vệ dữ liệu cá nhân theo quy định của Nghị định 13/2023/NĐ-CP.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 20),
            _buildCard(
              title: '1. Số điện thoại & Họ tên',
              icon: Icons.phone_android,
              content:
                  'Chỉ dùng để xác thực tài khoản và phục vụ liên lạc cứu nạn khẩn cấp. Số điện thoại được ẩn hoàn toàn trên danh sách công khai và chỉ hiển thị cho đội cứu hộ sau khi đã nhận nhiệm vụ.',
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: '2. Dữ liệu Vị trí GPS & Địa chỉ',
              icon: Icons.location_on_outlined,
              content:
                  'Tọa độ GPS giúp đội cứu trợ xác định vị trí gặp nạn. Trên hàng chờ nhiệm vụ chung, tọa độ được làm tròn 2 chữ số thập phân (~1.1 km) để bảo vệ quyền riêng tư vị trí của bạn.',
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: '3. Ảnh hiện trường',
              icon: Icons.camera_alt_outlined,
              content:
                  'Ảnh chụp là tùy chọn để cung cấp thông tin mức độ ngập lụt. Hệ thống tự động đóng dấu thời gian và tọa độ tham chiếu vào ảnh; không chia sẻ công khai ra ngoài.',
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: '4. Nhật ký kiểm toán truy cập (Access Audit)',
              icon: Icons.history_edu_outlined,
              content:
                  'Mọi thao tác xem số điện thoại và tọa độ chính xác của bạn bởi Đội cứu hộ hoặc Quản trị viên đều được hệ thống ghi nhận vào nhật ký kiểm toán không thể sửa đổi.',
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: '5. Quyền của Chủ thể Dữ liệu',
              icon: Icons.verified_user_outlined,
              content:
                  'Bạn có quyền xem thông tin cá nhân, yêu cầu sửa đổi nội dung yêu cầu cứu trợ trước khi được tiếp nhận, hoặc yêu cầu xóa phiên đăng nhập bất kỳ lúc nào.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'Lưu ý: Trong tình huống khẩn cấp đe dọa trực tiếp đến tính mạng con người, hệ thống ưu tiên cứu nạn trước theo quy định tại Điều 17 Nghị định 13/2023/NĐ-CP.',
                style: AppTypography.secondaryMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
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
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTypography.cardTitle),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          Text(content, style: AppTypography.body),
        ],
      ),
    );
  }
}
