import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/widgets/location_picker.dart';
import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/widgets/sync_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'c04_request_wizard_step3_photo_screen.dart';

class C03RequestWizardStep2LocationScreen extends StatefulWidget {
  final List<String> reliefTypes;
  final int totalPeople;
  final String urgency;
  final RequestDraft? draft;

  const C03RequestWizardStep2LocationScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
    this.draft,
  });

  @override
  State<C03RequestWizardStep2LocationScreen> createState() =>
      _C03RequestWizardStep2LocationScreenState();
}

class _C03RequestWizardStep2LocationScreenState
    extends State<C03RequestWizardStep2LocationScreen> {
  final _addressController = TextEditingController(),
      _landmarkController = TextEditingController();
  late final RequestDraft _draft;
  String _gpsStatus =
      'Chưa xác nhận vị trí. Lấy GPS hoặc ghim điểm trên bản đồ.';
  bool _isLocating = false;
  @override
  void initState() {
    super.initState();
    _draft =
        widget.draft ??
        RequestDraft(
          values: {
            ...RequestDraft().values,
            'types': widget.reliefTypes,
            'people': widget.totalPeople,
            'urgency': widget.urgency,
          },
        );
    _addressController.text = _draft.values['address'];
    _landmarkController.text = _draft.values['landmark'];
    if (_draft.values['latitude'] != null) {
      _gpsStatus =
          'Vị trí đã lưu: ${_draft.values['latitude']}, ${_draft.values['longitude']}';
    }
  }

  void _confirm(double latitude, double longitude, String source) {
    setState(() {
      _draft.values.addAll({
        'latitude': latitude,
        'longitude': longitude,
        'locationSource': source,
        'locationConfirmedAt': DateTime.now().toUtc().toIso8601String(),
      });
      _gpsStatus =
          'Tọa độ: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)} — ${source == 'gps' ? 'GPS' : 'Đã ghim'}';
    });
  }

  Future<void> _getCurrentGps() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Định vị đang tắt. Bạn có thể ghim điểm trên bản đồ.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Chưa có quyền vị trí. Bạn có thể ghim điểm trên bản đồ.';
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      setState(() => _isLocating = false);
      final location = await showDialog<PickedLocation>(
        context: context,
        builder: (_) => LocationPicker(
          latitude: position.latitude,
          longitude: position.longitude,
          source: 'gps',
          accuracyMetres: position.accuracy,
        ),
      );
      if (location != null && mounted) {
        _confirm(location.latitude, location.longitude, location.source);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _gpsStatus = 'Không lấy được GPS. Hãy ghim vị trí hoặc nhập tọa độ đã xác nhận.',
        );
        showFailure(context, error);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickLocation() async {
    final location = await showDialog<PickedLocation>(
      context: context,
      builder: (_) => LocationPicker(
        latitude: (_draft.values['latitude'] as num?)?.toDouble(),
        longitude: (_draft.values['longitude'] as num?)?.toDouble(),
      ),
    );
    if (location != null && mounted) {
      _confirm(location.latitude, location.longitude, 'pin');
    }
  }

  Future<void> _save({bool next = false}) async {
    _draft.values.addAll({
      'address': _addressController.text.trim(),
      'landmark': _landmarkController.text.trim(),
    });
    final error = next ? _draft.validate() : null;
    if (error != null) {
      showFailure(context, error);
      return;
    }
    try {
      await reliefRepository.saveDraft(_draft);
      if (!mounted) return;
      if (!next) {
        showDraftSaved(context);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => C04RequestWizardStep3PhotoScreen(
            reliefTypes: widget.reliefTypes,
            totalPeople: widget.totalPeople,
            urgency: widget.urgency,
            address: _addressController.text.trim(),
            landmark: _landmarkController.text.trim(),
            draft: _draft,
          ),
        ),
      );
    } catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Vị trí cần hỗ trợ',
        actions: [
          TextButton(onPressed: () => _save(), child: const Text('Lưu nháp')),
        ],
      ),
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
                          Text(
                            'Tạo yêu cầu cứu trợ',
                            style: AppTypography.secondaryMedium.copyWith(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Bước 2 / 4',
                            style: AppTypography.secondaryMedium.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.50,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Vị trí cần cứu trợ',
                        style: AppTypography.sectionTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lấy vị trí hiện tại hoặc ghim nơi cần hỗ trợ. Thêm địa chỉ hay mốc dễ nhận biết để đội cứu hộ tìm đến.',
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
                      Positioned.fill(
                        child: TextButton(
                          onPressed: _pickLocation,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 48,
                              color: AppColors.danger,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: _pickLocation,
                                child: Text(
                                  _draft.values['latitude'] == null
                                      ? 'Chạm để ghim vị trí'
                                      : 'Kiểm tra vị trí',
                                  style: AppTypography.secondaryMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          tooltip: 'Lấy vị trí hiện tại',
                          onPressed: _isLocating ? null : _getCurrentGps,
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                          child: _isLocating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
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
                      const Icon(
                        Icons.gps_fixed,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsStatus,
                          style: AppTypography.secondaryMedium.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Manual Address Input (US-027)
                Text('Địa chỉ', style: AppTypography.bodyMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _addressController,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.home,
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Nhập địa chỉ nơi cần hỗ trợ',
                  ),
                ),

                const SizedBox(height: 16),

                // Landmark / Identification note (US-027)
                Text(
                  'Mốc nhận diện hoặc đường đi',
                  style: AppTypography.bodyMedium,
                ),
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
                  text: 'Tiếp tục',
                  icon: Icons.arrow_forward,
                  onPressed: () => _save(next: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
