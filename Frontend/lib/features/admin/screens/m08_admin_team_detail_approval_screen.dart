import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';

class M08AdminTeamDetailApprovalScreen extends StatefulWidget {
  final Map<String, dynamic> teamData;
  final Function(String status)? onStatusChanged;

  const M08AdminTeamDetailApprovalScreen({
    super.key,
    required this.teamData,
    this.onStatusChanged,
  });

  @override
  State<M08AdminTeamDetailApprovalScreen> createState() => _M08AdminTeamDetailApprovalScreenState();
}

class _M08AdminTeamDetailApprovalScreenState extends State<M08AdminTeamDetailApprovalScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.teamData['status'] as String? ?? 'pending';
  }

  void _showProofPreview(String title, String type, String details) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: AppTypography.cardTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'image' ? Icons.image : Icons.picture_as_pdf,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text('Tài liệu minh chứng số hóa', style: AppTypography.bodyMedium),
                  Text('Độ phân giải cao • Đã đối soát', style: AppTypography.secondary.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Thông tin hồ sơ:', style: AppTypography.secondaryMedium),
            const SizedBox(height: 4),
            Text(details, style: AppTypography.body),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _approveTeam() {
    setState(() => _currentStatus = 'approved');
    widget.onStatusChanged?.call('approved');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Đã phê duyệt hồ sơ cho ${widget.teamData['name']} thành công!'),
      ),
    );
    Navigator.of(context).pop();
  }

  void _requestMoreInfo() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Yêu cầu bổ sung minh chứng', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập nội dung cần đội cứu trợ gửi bổ sung hoặc làm rõ:', style: AppTypography.body),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'VD: Ảnh chứng chỉ lái tàu bị mờ, vui lòng chụp lại góc rõ số hiệu bằng lái...',
                fillColor: AppColors.canvas,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _currentStatus = 'needs_info');
              widget.onStatusChanged?.call('needs_info');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi thông báo yêu cầu bổ sung minh chứng tới trưởng đội.')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  void _rejectTeam() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Từ chối hồ sơ đội cứu hộ', style: AppTypography.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập lý do không phê duyệt hồ sơ:', style: AppTypography.body),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'VD: Phương tiện không đáp ứng tiêu chuẩn an toàn đê điều mùa lũ...',
                fillColor: AppColors.canvas,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy', style: AppTypography.button.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _currentStatus = 'rejected');
              widget.onStatusChanged?.call('rejected');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.danger,
                  content: Text('Đã từ chối hồ sơ đăng ký của đội.'),
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.teamData;
    final isApproved = _currentStatus == 'approved';
    final isPending = _currentStatus == 'pending';
    final isNeedsInfo = _currentStatus == 'needs_info';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Chi tiết hồ sơ xét duyệt',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Status Card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(team['id'] as String? ?? 'TEAM-NEW', style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? AppColors.successContainer
                                : isNeedsInfo
                                    ? AppColors.warningContainer
                                    : isPending
                                        ? AppColors.primaryContainer
                                        : AppColors.dangerContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isApproved
                                ? 'Đã phê duyệt'
                                : isNeedsInfo
                                    ? 'Cần bổ sung'
                                    : isPending
                                        ? 'Chờ thẩm định'
                                        : 'Từ chối',
                            style: AppTypography.chip.copyWith(
                              color: isApproved
                                  ? AppColors.success
                                  : isNeedsInfo
                                      ? AppColors.warning
                                      : isPending
                                          ? AppColors.primaryDark
                                          : AppColors.danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(team['name'] as String? ?? '', style: AppTypography.pageTitle.copyWith(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text('Ngày đăng ký: 23/10/2026 • Địa bàn đăng ký: Huyện Chương Mỹ', style: AppTypography.secondary),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Leader & Personnel
              Text('Thông tin Trưởng đội & Nhân sự', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Trưởng đội', team['leader'] as String? ?? 'Chưa cập nhật'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildInfoRow('Số CCCD định danh', '001092004882 (Đã xác thực OTP)'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildInfoRow('Số lượng thành viên', '${team['members'] ?? 4} thành viên trực tiếp ứng cứu'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildInfoRow('Kinh nghiệm thực địa', 'Đã tham gia cứu trợ mùa lũ Chương Mỹ & Quốc Oai 2024'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 2: Equipment
              Text('Phương tiện & Trang thiết bị cứu nạn', style: AppTypography.sectionTitle),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Phương tiện chính', team['equipment'] as String? ?? 'Ca-nô vỏ nhôm 25HP'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildInfoRow('Biển số đăng kiểm', 'VN-24-HNI-0889 (Hạn đăng kiểm: 11/2027)'),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    _buildInfoRow('Trang bị an toàn kèm theo', '12 Áo phao tiêu chuẩn, 02 phao tròn, 02 túi y tế chống nước'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 3: Legal & Technical Proofs according to Vietnamese Law
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hồ sơ minh chứng theo quy định pháp luật',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Cần kiểm tra', style: AppTypography.chip.copyWith(color: AppColors.primaryDark, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Căn cứ Luật Phòng, chống thiên tai, Luật GT Đường thủy nội địa & Nghị định 93/2021/NĐ-CP:',
                style: AppTypography.secondary.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 10),

              // Proof Card 1: Giấy đăng kiểm phương tiện thủy nội địa (Luật GTĐTNĐ)
              _buildProofCard(
                title: '1. Giấy chứng nhận Đăng kiểm Phương tiện thủy',
                subtitle: 'Số hiệu: ĐK-2025/HN • Hạn kiểm định: 11/2027',
                fileType: 'pdf',
                legalBasis: 'Điều 24, 26 Luật Giao thông đường thủy nội địa',
                details: 'Phương tiện: Ca-nô vỏ nhôm composite gắn máy ngoài 25HP. Sức chở tối đa: 08 người. Đạt tiêu chuẩn an toàn kỹ thuật và bảo vệ môi trường đường thủy.',
              ),
              const SizedBox(height: 10),

              // Proof Card 2: Bằng lái / Chứng chỉ chuyên môn lái phương tiện thủy nội địa
              _buildProofCard(
                title: '2. Chứng chỉ chuyên môn lái phương tiện thủy',
                subtitle: 'Người đứng tên: Vũ Hữu Đạt • Hạng 2 • Cục ĐTNĐ cấp',
                fileType: 'image',
                legalBasis: 'Điều 35 Luật Giao thông đường thủy nội địa',
                details: 'Chứng chỉ chuyên môn lái ca-nô/xuồng máy công suất đến 30HP. Đủ điều kiện điều khiển phương tiện chở người trong điều kiện mưa lũ, dòng nước chảy.',
              ),
              const SizedBox(height: 10),

              // Proof Card 3: Chứng chỉ Sơ cấp cứu ban đầu & Cứu nạn cứu hộ
              _buildProofCard(
                title: '3. Chứng chỉ Sơ cấp cứu & Cứu đuối nước',
                subtitle: 'Cấp bởi: Hội Chữ thập đỏ Việt Nam • Còn hiệu lực đến 2028',
                fileType: 'pdf',
                legalBasis: 'Luật Hoạt động Chữ thập đỏ & Nghiệp vụ cứu hộ',
                details: 'Đã hoàn thành khóa huấn luyện kỹ năng ép tim, hô hấp nhân tạo, xử trí đuối nước, nẹp cố định chấn thương và vận chuyển nạn nhân trên xuồng an toàn.',
              ),
              const SizedBox(height: 10),

              // Proof Card 4: Bản cam kết tuân thủ điều phối PCTT&TKCN & Nghị định 93/2021/NĐ-CP
              _buildProofCard(
                title: '4. Bản cam kết tuân thủ điều phối PCTT&TKCN',
                subtitle: 'Xác nhận của Đội trưởng & UBND xã nơi thường trú',
                fileType: 'pdf',
                legalBasis: 'Nghị định 93/2021/NĐ-CP & Luật Phòng chống thiên tai',
                details: 'Cam kết chấp hành sự phân công, điều hành của Ban Chỉ huy PCTT&TKCN địa phương; không tự ý vào luồng xoáy nguy hiểm; thực hiện cứu trợ công khai, minh bạch.',
              ),
              const SizedBox(height: 10),

              // Proof Card 5: Ảnh chụp thực tế phương tiện và trang bị an toàn
              _buildProofCard(
                title: '5. Ảnh thực tế phương tiện & Áo phao cứu sinh',
                subtitle: '03 ảnh hiện trường • 12 áo phao đạt chuẩn QCVN',
                fileType: 'image',
                legalBasis: 'Quy chuẩn QCVN 08:2015/BKHCN về phao cứu sinh',
                details: 'Ảnh chụp toàn cảnh ca-nô vỏ nhôm số hiệu VN-24-HNI-0889, động cơ Yamaha 25HP, 12 áo phao có còi và vạch phản quang, 02 phao tròn cứu sinh.',
              ),
              const SizedBox(height: 24),

              // Actions Buttons Group
              if (isPending || isNeedsInfo) ...[
                AppButton(
                  text: 'Phê duyệt & Cấp quyền cứu hộ',
                  icon: Icons.check_circle,
                  onPressed: _approveTeam,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text('Yêu cầu bổ sung'),
                        onPressed: _requestMoreInfo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Từ chối hồ sơ'),
                        onPressed: _rejectTeam,
                      ),
                    ),
                  ],
                ),
              ] else if (isApproved) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.success, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Đội đã được phê duyệt và đang hoạt động điều phối trên hệ thống.',
                          style: AppTypography.secondaryMedium.copyWith(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: AppColors.danger, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hồ sơ của đội đã bị từ chối do không đáp ứng yêu cầu an toàn kỹ thuật.',
                          style: AppTypography.secondaryMedium.copyWith(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(label, style: AppTypography.secondary.copyWith(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: AppTypography.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildProofCard({
    required String title,
    required String subtitle,
    required String fileType,
    required String details,
    String? legalBasis,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: fileType == 'pdf' ? AppColors.dangerContainer : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              fileType == 'pdf' ? Icons.picture_as_pdf : Icons.photo_library_outlined,
              color: fileType == 'pdf' ? AppColors.danger : AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.secondary.copyWith(fontSize: 12)),
                if (legalBasis != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Căn cứ: $legalBasis',
                      style: AppTypography.secondary.copyWith(fontSize: 11, color: AppColors.primaryDark),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _showProofPreview(title, fileType, details),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Xem tài liệu minh chứng', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
