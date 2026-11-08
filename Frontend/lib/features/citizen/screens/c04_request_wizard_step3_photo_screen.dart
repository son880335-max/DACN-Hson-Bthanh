import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/widgets/evidence_preview.dart';
import '../../../core/data/relief_repository.dart';
import '../../../core/data/request_draft.dart';
import '../../../core/data/request_presentation.dart';
import '../../../core/widgets/sync_status.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import 'c06_request_wizard_step4_review_submit_screen.dart';

class C04RequestWizardStep3PhotoScreen extends StatefulWidget {
  final List<String> reliefTypes;
  final int totalPeople;
  final String urgency;
  final String address;
  final String landmark;
  final RequestDraft? draft;

  const C04RequestWizardStep3PhotoScreen({
    super.key,
    required this.reliefTypes,
    required this.totalPeople,
    required this.urgency,
    required this.address,
    required this.landmark,
    this.draft,
  });

  @override
  State<C04RequestWizardStep3PhotoScreen> createState() =>
      _C04RequestWizardStep3PhotoScreenState();
}

class _C04RequestWizardStep3PhotoScreenState
    extends State<C04RequestWizardStep3PhotoScreen> {
  late final RequestDraft _draft;
  List<Json> get _photos => _draft.photos;
  List<dynamic> get _uploaded => _draft.values['evidenceIds'] as List;
  final _photoNoteController = TextEditingController();
  final _picker = ImagePicker();
  bool _capturing = false;
  @override
  void initState() {
    super.initState();
    _draft = widget.draft ?? RequestDraft();
    _photoNoteController.text = _draft.values['description'];
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recoverCamera());
    }
  }

  Future<void> _recoverCamera() async {
    if (!mounted || _capturing) return;
    final owner = reliefRepository.account?['id'];
    setState(() => _capturing = true);
    try {
      final capture = await reliefRepository.pendingCamera();
      if (capture == null ||
          !mounted ||
          owner != reliefRepository.account?['id']) {
        return;
      }
      if (capture['requestId'] != _draft.requestId) {
        await reliefRepository.cameraFinished();
        throw StateError('Camera belongs to another draft');
      }
      final recovered = await reliefRepository.recoveredCameraPhoto();
      final result = recovered == null
          ? await _picker.retrieveLostData()
          : null;
      if (result?.exception != null) throw result!.exception!;
      if (!mounted || owner != reliefRepository.account?['id']) return;
      final image = result?.files?.firstOrNull;
      if (recovered == null && image == null) {
        await reliefRepository.cameraFinished();
        if (mounted) {
          showFailure(
            context,
            'Không tìm thấy ảnh vừa chụp. Bạn có thể chụp lại hoặc tiếp tục không có ảnh.',
          );
        }
        return;
      }
      final replacing = _photos
          .where((p) => p['key'] == capture['replacingKey'])
          .firstOrNull;
      final use = await _storePhoto(
        image,
        replacing: replacing,
        capture: capture,
      );
      if (owner == reliefRepository.account?['id']) {
        await reliefRepository.cameraFinished();
      }
      if (use == false && mounted) {
        setState(() => _capturing = false);
        await _capturePhoto(replacing: replacing);
      }
    } catch (error) {
      if (mounted) {
        showFailure(
          context,
          'Không khôi phục được ảnh. Bạn vẫn có thể gửi yêu cầu không có ảnh.',
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<bool?> _storePhoto(
    XFile? image, {
    Json? replacing,
    required Json capture,
  }) async {
    final capturedAt = DateTime.tryParse(capture['capturedAt'] ?? '');
    if (capturedAt == null) {
      throw 'Chưa ghi nhận được thời điểm chụp. Kiểm tra ngày giờ thiết bị rồi chụp lại, hoặc tiếp tục không có ảnh.';
    }
    final owner = reliefRepository.account?['id'];
    if (image != null && await image.length() > 8 * 1024 * 1024) {
      throw 'Ảnh quá lớn. Hãy chụp lại hoặc tiếp tục không có ảnh.';
    }
    final bytes = image == null
        ? await reliefRepository.recoveredCameraPhoto()
        : await image.readAsBytes();
    if (bytes == null) throw StateError('Missing camera image');
    if (bytes.length > 8 * 1024 * 1024) {
      throw 'Ảnh quá lớn. Chụp lại hoặc tiếp tục không có ảnh.';
    }
    if (!mounted || owner != reliefRepository.account?['id']) return null;
    // Keep the recovered image encrypted until the preview choice is saved.
    await reliefRepository.stageCameraPhoto(bytes);
    if (!mounted || owner != reliefRepository.account?['id']) return null;
    final use = await previewCapturedPhoto(context, bytes);
    if (use != true || !mounted) return use;
    if (owner != reliefRepository.account?['id']) {
      throw 'Tài khoản đã thay đổi. Ảnh chưa được lưu.';
    }
    final photo = await reliefRepository.savePhoto(
      bytes,
      latitude: (capture['latitude'] as num?)?.toDouble(),
      longitude: (capture['longitude'] as num?)?.toDouble(),
      capturedAt: capturedAt,
    );
    if (!mounted || owner != reliefRepository.account?['id']) return null;
    final previous = _photos.toList();
    final index = replacing == null
        ? -1
        : _photos.indexWhere((p) => p['key'] == replacing['key']);
    if (index < 0) {
      _photos.add(photo);
    } else {
      _photos[index] = photo;
    }
    try {
      await reliefRepository.saveDraft(_draft);
    } catch (_) {
      _photos
        ..clear()
        ..addAll(previous);
      rethrow;
    }
    if (mounted) setState(() {});
    if (index >= 0) await reliefRepository.removePhoto(previous[index]);
    return true;
  }

  Future<void> _capturePhoto({Json? replacing}) async {
    if (_capturing) return;
    if (replacing == null &&
        _photos.length + (_draft.values['evidenceIds'] as List).length >=
            const int.fromEnvironment('MAX_DRAFT_PHOTOS', defaultValue: 20)) {
      showFailure(
        context,
        'Đã đủ số ảnh đính kèm. Bạn có thể bỏ bớt ảnh hoặc tiếp tục gửi yêu cầu.',
      );
      return;
    }
    setState(() => _capturing = true);
    try {
      _draft.values['description'] = _photoNoteController.text.trim();
      await reliefRepository.saveDraft(_draft);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) throw 'Chưa cấp quyền camera. Bạn có thể cấp quyền trong cài đặt ứng dụng hoặc tiếp tục không có ảnh.';
      }
      final owner = reliefRepository.account?['id'];
      bool? use;
      do {
        final capture = <String, dynamic>{
          'requestId': _draft.requestId,
          'replacingKey': replacing?['key'],
          'capturedAt': DateTime.now().toUtc().toIso8601String(),
          'latitude': _draft.values['latitude'],
          'longitude': _draft.values['longitude'],
        };
        await reliefRepository.cameraPending(context: capture);
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 75,
          requestFullMetadata: false,
        );
        if (owner != reliefRepository.account?['id']) {
          throw 'Tài khoản đã thay đổi. Hãy mở lại yêu cầu bằng tài khoản đã chụp ảnh.';
        }
        if (!mounted) return;
        if (image == null) {
          await reliefRepository.cameraFinished();
          return;
        }
        use = await _storePhoto(image, replacing: replacing, capture: capture);
        if (owner == reliefRepository.account?['id']) {
          await reliefRepository.cameraFinished();
        }
      } while (use == false && mounted);
    } catch (error) {
      if (mounted) {
        showFailure(
          context,
          error is String ? error : 'Không chụp được ảnh. Bạn có thể thử lại hoặc tiếp tục không có ảnh.',
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _removePhoto(int index) async {
    final photo = _photos.removeAt(index);
    try {
      await reliefRepository.saveDraft(_draft);
    } catch (error) {
      _photos.insert(index, photo);
      if (mounted) showFailure(context, error);
      return;
    }
    if (mounted) setState(() {});
    try {
      await reliefRepository.removePhoto(photo);
    } catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  Future<void> _navigateNext() async {
    if (_capturing) return;
    _draft.values['description'] = _photoNoteController.text.trim();
    final error = _draft.validate();
    if (error != null) {
      showFailure(context, error);
      return;
    }
    try {
      await reliefRepository.saveDraft(_draft);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => C06RequestWizardStep4ReviewSubmitScreen(
            reliefTypes: widget.reliefTypes,
            totalPeople: widget.totalPeople,
            urgency: widget.urgency,
            address: widget.address,
            landmark: widget.landmark,
            photosCount: _photos.length + _uploaded.length,
            photoNote: _photoNoteController.text,
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
    _photoNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppHeader(
        title: 'Gửi yêu cầu cứu trợ',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: () async {
              _draft.values['description'] = _photoNoteController.text.trim();
              try {
                await reliefRepository.saveDraft(_draft);
                if (context.mounted) showDraftSaved(context);
              } catch (error) {
                if (context.mounted) showFailure(context, error);
              }
            },
            child: const Text('Lưu nháp'),
          ),
        ],
        onBack: () {
          if (!_capturing) Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Bước 3/4',
                            style: AppTypography.chip.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ảnh tình trạng (không bắt buộc)',
                            style: AppTypography.cardTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chỉ chụp ảnh khi an toàn. Bạn vẫn có thể gửi yêu cầu không có ảnh.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 20),

                    // Add photo button card
                    InkWell(
                      onTap: _capturing ? null : _capturePhoto,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.primaryDark,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _capturing ? 'Đang xử lý ảnh…' : 'Chụp ảnh',
                              style: AppTypography.cardTitle.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ảnh sẽ có ngày giờ chụp và vị trí đã xác nhận.',
                              style: AppTypography.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Ảnh đính kèm (${_photos.length + _uploaded.length})',
                      style: AppTypography.sectionTitle,
                    ),
                    const SizedBox(height: 12),

                    if (_uploaded.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final id in _uploaded.toList())
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RemoteEvidencePreview(id: id),
                                TextButton(
                                  onPressed: _capturing
                                      ? null
                                      : () async {
                                          final previous = _uploaded.toList();
                                          _uploaded.remove(id);
                                          try {
                                            await reliefRepository.saveDraft(
                                              _draft,
                                            );
                                            if (mounted) setState(() {});
                                          } catch (error) {
                                            _uploaded
                                              ..clear()
                                              ..addAll(previous);
                                            if (context.mounted) {
                                              showFailure(context, error);
                                            }
                                          }
                                        },
                                  child: const Text('Bỏ ảnh này'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    if (_photos.isEmpty && _uploaded.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Chưa có ảnh. Chọn Tiếp tục để xem lại yêu cầu.',
                          style: AppTypography.secondary,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: LocalEvidencePreview(
                                    photo: _photos[index],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ảnh ${index + 1}',
                                        style: AppTypography.bodyMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${formatTimestamp(_photos[index]['capturedAt'], seconds: true)} • ${_photos[index]['latitude'] == null ? 'Chưa có tọa độ tham chiếu' : 'Có tọa độ tham chiếu'}',
                                        style: AppTypography.secondary.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.replay),
                                  onPressed: _capturing
                                      ? null
                                      : () => _capturePhoto(
                                          replacing: _photos[index],
                                        ),
                                  tooltip: 'Chụp lại ảnh',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                  onPressed: _capturing
                                      ? null
                                      : () => _removePhoto(index),
                                  tooltip: 'Xóa ảnh',
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                    Text(
                      'Mô tả tình trạng hiện tại',
                      style: AppTypography.sectionTitle,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _photoNoteController,
                      maxLength: 4000,
                      maxLines: 3,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        hintText: 'Mô tả tình trạng cần hỗ trợ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Keep notices above the actions so an error does not cover Continue.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                text: 'Xem lại yêu cầu',
                onPressed: _capturing ? null : _navigateNext,
              ),
              const SizedBox(height: 8),
              AppButton(
                text: 'Tiếp tục không thêm ảnh',
                variant: AppButtonVariant.secondary,
                onPressed: _capturing ? null : _navigateNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
