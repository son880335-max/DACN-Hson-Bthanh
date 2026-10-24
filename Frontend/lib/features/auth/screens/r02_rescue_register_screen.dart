import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'a04_otp_verification_screen.dart';

class R02RescueRegisterScreen extends StatefulWidget {
  const R02RescueRegisterScreen({super.key});

  @override
  State<R02RescueRegisterScreen> createState() => _R02RescueRegisterScreenState();
}

class _R02RescueRegisterScreenState extends State<R02RescueRegisterScreen> {
  final _teamNameController = TextEditingController();
  final _leaderNameController = TextEditingController();
  final _leaderIdCardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController(text: 'Huyện Chương Mỹ, TP. Hà Nội');
  final _equipmentController = TextEditingController(text: '02 Thuyền vỏ nhôm gắn máy 25HP, 12 Áo phao đạt chuẩn QCVN, 02 Túi y tế chống nước');
  final _boatRegController = TextEditingController(text: 'VN-24-HNI-0889');
  int _membersCount = 4;
  bool _agreedToRegulations = false;

  final List<Map<String, String>> _proofDocuments = [
    {
      'title': 'Giấy đăng kiểm phương tiện thủy nội địa (ĐK-2025/HN)',
      'law': 'Điều 24, 26 Luật Giao thông đường thủy nội địa',
      'file': 'Giay_dang_kiem_phuong_tien_thuy.pdf',
    },
    {
      'title': 'Chứng chỉ chuyên môn lái ca-nô/xuồng máy hạng 2',
      'law': 'Điều 35 Luật Giao thông đường thủy nội địa',
      'file': 'Chung_chi_lai_phuong_tien_thuy_hang_2.jpg',
    },
    {
      'title': 'Chứng chỉ tập huấn Sơ cấp cứu ban đầu (Chữ thập đỏ)',
      'law': 'Luật Hoạt động Chữ thập đỏ & Nghiệp vụ cứu hộ',
      'file': 'Chung_chi_so_cap_cuu_chu_thap_do.pdf',
    },
    {
      'title': 'Bản cam kết tuân thủ điều phối PCTT&TKCN địa phương',
      'law': 'Nghị định 93/2021/NĐ-CP & Luật Phòng chống thiên tai',
      'file': 'Ban_cam_ket_dieu_phoi_cuu_tro_pctt.pdf',
    },
  ];

  void _addProofDocument() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(ctx).viewPadding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Chọn loại tệp minh chứng đính kèm', style: AppTypography.cardTitle),
                const SizedBox(height: 6),
                Text('Theo quy định pháp luật Việt Nam về cứu nạn mùa lũ:', style: AppTypography.secondary),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 22),
                  ),
                  title: Text('Giấy đăng ký / Đăng kiểm phương tiện', style: AppTypography.bodyMedium),
                  subtitle: Text('Căn cứ Điều 24, 26 Luật GT Đường thủy', style: AppTypography.secondary.copyWith(fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _attachDoc('Giấy đăng kiểm phương tiện thủy', 'Luật GTĐTNĐ', 'Dang_kiem_bo_sung.pdf');
                  },
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge_outlined, color: AppColors.primaryDark, size: 22),
                  ),
                  title: Text('Bằng thuyền trưởng / Lái ca-nô', style: AppTypography.bodyMedium),
                  subtitle: Text('Cục Đường thủy hoặc Sở GTVT cấp', style: AppTypography.secondary.copyWith(fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _attachDoc('Bằng lái ca-nô/xuồng máy', 'Điều 35 Luật GTĐTNĐ', 'Bang_lai_bo_sung.jpg');
                  },
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.health_and_safety_outlined, color: AppColors.success, size: 22),
                  ),
                  title: Text('Chứng chỉ Sơ cấp cứu / Cứu đuối nước', style: AppTypography.bodyMedium),
                  subtitle: Text('Hội Chữ thập đỏ hoặc cơ sở y tế cấp', style: AppTypography.secondary.copyWith(fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _attachDoc('Chứng chỉ sơ cấp cứu', 'Hội Chữ thập đỏ', 'So_cap_cuu_bo_sung.pdf');
                  },
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.warning, size: 22),
                  ),
                  title: Text('Ảnh thực tế phương tiện & Áo phao QCVN', style: AppTypography.bodyMedium),
                  subtitle: Text('Tối thiểu 100% áo phao đủ cho người trên xuồng', style: AppTypography.secondary.copyWith(fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _attachDoc('Ảnh thực tế xuồng máy & áo phao', 'QCVN 08:2015/BKHCN', 'Anh_thuc_te_phuong_tien.jpg');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _attachDoc(String title, String law, String file) {
    setState(() {
      _proofDocuments.add({
        'title': title,
        'law': law,
        'file': file,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã tải lên tệp minh chứng: $file')),
    );
  }

  void _removeProofDocument(int index) {
    setState(() {
      _proofDocuments.removeAt(index);
    });
  }

  void _proceedToOtp() {
    if (_teamNameController.text.trim().isEmpty ||
        _leaderNameController.text.trim().isEmpty ||
        _leaderIdCardController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ tên đội, họ tên đội trưởng, số CCCD và số điện thoại.')),
      );
      return;
    }

    if (_proofDocuments.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Bắt buộc phải cung cấp đủ Giấy đăng kiểm phương tiện và Chứng chỉ chuyên môn lái ca-nô theo luật.'),
        ),
      );
      return;
    }

    if (!_agreedToRegulations) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Bạn cần đọc và đồng ý cam kết tuân thủ quy định pháp luật & điều phối cứu hộ.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => A04OtpVerificationScreen(
          phoneNumber: _phoneController.text.trim(),
          userRole: 'rescue',
          nextAction: 'register',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Đăng ký Đội cứu hộ',
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Legal Note Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.gavel_outlined, color: AppColors.primaryDark, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Căn cứ Luật Phòng, chống thiên tai, Luật Giao thông đường thủy nội địa và Nghị định 93/2021/NĐ-CP: Mọi đội cứu hộ dân sự/tình nguyện khi tham gia ứng cứu lũ lụt bắt buộc phải có đầy đủ chứng chỉ chuyên môn, đăng kiểm phương tiện và cam kết chấp hành sự điều phối của Ban Chỉ huy PCTT&TKCN.',
                          style: AppTypography.secondary.copyWith(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Team General Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Thông tin Đội cứu hộ & Người đại diện', style: AppTypography.cardTitle),
                      const SizedBox(height: 14),

                      Text('Tên Đội cứu hộ', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _teamNameController,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'VD: Đội Cứu trợ Tình nguyện Hương Thủy',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Họ và tên Đội trưởng (Người đại diện pháp lý)', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _leaderNameController,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'VD: Lê Văn Bình',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Số CCCD / Mã định danh VNeID của Đội trưởng', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _leaderIdCardController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'VD: 001092004882',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Số điện thoại trực ban / Hotline đội', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'VD: 0983 234 567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Địa bàn đăng ký thường trực cứu trợ', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _areaController,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Số lượng thành viên trực tiếp ứng cứu', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                            onPressed: () {
                              if (_membersCount > 2) setState(() => _membersCount--);
                            },
                          ),
                          Text('$_membersCount thành viên', style: AppTypography.cardTitle),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onPressed: () {
                              if (_membersCount < 50) setState(() => _membersCount++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Equipment & Capacity Proof (BẮT BUỘC THEO LUẬT)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('2. Hồ sơ minh chứng pháp lý & Phương tiện', style: AppTypography.cardTitle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hồ sơ được dùng để Ban Chỉ huy PCTT&TKCN và Quản trị viên đối soát, đảm bảo an toàn tuyệt đối tính mạng người dân và thành viên cứu trợ.',
                        style: AppTypography.secondary,
                      ),
                      const SizedBox(height: 14),

                      Text('Phương tiện thủy & Biển số đăng ký', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _boatRegController,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'Biển số đăng kiểm (VD: VN-24-HNI-0889)',
                          prefixIcon: Icon(Icons.directions_boat_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Trang thiết bị an toàn trên phương tiện', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _equipmentController,
                        maxLines: 2,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: 'Loại xuồng máy, số áo phao QCVN, phao tròn, túi y tế, bộ đàm...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('Danh sách tài liệu minh chứng đã tải lên (${_proofDocuments.length})', style: AppTypography.secondaryMedium),
                      const SizedBox(height: 8),

                      ..._proofDocuments.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final doc = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doc['title']!, style: AppTypography.bodyMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('Căn cứ: ${doc['law']}', style: AppTypography.secondary.copyWith(fontSize: 12, color: AppColors.primaryDark)),
                                    const SizedBox(height: 2),
                                    Text('Tệp đính kèm: ${doc['file']}', style: AppTypography.secondary.copyWith(fontSize: 11)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.danger, size: 20),
                                onPressed: () => _removeProofDocument(idx),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Tải thêm tệp minh chứng theo quy định'),
                        onPressed: _addProofDocument,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Legal Commitment Checkbox
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreedToRegulations,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _agreedToRegulations = val ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'Đội trưởng cam kết toàn bộ thông tin phương tiện, chứng chỉ chuyên môn và nhân sự khai báo là chính xác trước pháp luật; cam kết chấp hành sự điều phối của Ban Chỉ huy PCTT&TKCN địa phương và tuân thủ Nghị định 93/2021/NĐ-CP.',
                          style: AppTypography.secondary.copyWith(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit & OTP
                AppButton(
                  text: 'Tiếp tục & Xác thực OTP Đội trưởng',
                  icon: Icons.arrow_forward,
                  onPressed: _proceedToOtp,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Đã có tài khoản đội? Đăng nhập ngay', style: AppTypography.secondaryMedium.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
