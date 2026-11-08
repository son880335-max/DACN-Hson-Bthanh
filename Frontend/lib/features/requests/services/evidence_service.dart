import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/relief_request.dart';
import '../data/request_store.dart';

class EvidenceService {
  Future<Position> locate() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const RequestError(
        'Dịch vụ vị trí đang tắt. Hãy bật GPS hoặc ghim vị trí trên bản đồ.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const RequestError(
        'Quyền vị trí bị chặn. Mở cài đặt ứng dụng hoặc chọn vị trí trên bản đồ.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const RequestError(
        'Chưa được cấp quyền vị trí. Bạn vẫn có thể ghim bản đồ.',
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on TimeoutException {
      // Google Play Services có thể chậm/không sẵn sàng; thử provider Android trực tiếp.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          return await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.high,
              forceLocationManager: true,
              timeLimit: const Duration(seconds: 8),
            ),
          );
        } on TimeoutException {
          // Cả hai provider đều hết thời gian: giữ phương án ghim/nhập tọa độ.
        } on LocationServiceDisabledException {
          throw const RequestError(
            'GPS vừa bị tắt. Hãy bật lại hoặc chọn vị trí trên bản đồ.',
          );
        }
      }
      throw const RequestError(
        'Lấy GPS quá thời gian chờ. Hãy thử lại hoặc ghim vị trí trên bản đồ.',
      );
    } on LocationServiceDisabledException {
      throw const RequestError(
        'GPS vừa bị tắt. Hãy bật lại hoặc chọn vị trí trên bản đồ.',
      );
    }
  }

  Future<EvidencePhoto?> capture() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      throw const RequestError(
        'Camera chưa hỗ trợ trên desktop. Dùng điện thoại hoặc nút ảnh mẫu để kiểm thử.',
      );
    }
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw RequestError(
          status.isPermanentlyDenied
              ? 'Quyền camera bị chặn. Hãy mở cài đặt ứng dụng để cấp quyền.'
              : 'Bạn chưa cấp quyền camera. Có thể tiếp tục và bổ sung ảnh sau.',
        );
      }
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final capturedAt = DateTime.now().toUtc();
    double? lat, lon;
    // Không tự xin quyền GPS từ thao tác chụp ảnh. Chỉ đọc nếu đã cấp quyền.
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        lat = p.latitude;
        lon = p.longitude;
      }
    } catch (_) {
      /* Thiếu GPS được lưu thành dấu hiệu cần xác minh. */
    }
    if (await file.length() > 10 * 1024 * 1024) {
      throw const RequestError('Ảnh quá lớn, tối đa 10 MB trước khi xử lý.');
    }
    return compute(_stampCameraPhoto, {
      'bytes': await file.readAsBytes(),
      'capturedAt': capturedAt.toIso8601String(),
      'latitude': lat,
      'longitude': lon,
    });
  }

  Future<EvidencePhoto?> recoverCapture(DateTime startedAt) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await ImagePicker().retrieveLostData();
    if (response.isEmpty) return null;
    if (response.exception != null) {
      throw const RequestError(
        'Không khôi phục được ảnh camera. Biểu mẫu vẫn có thể khôi phục để chụp lại.',
      );
    }
    final files = response.files;
    if (files == null || files.isEmpty) return null;
    final file = files.first;
    if (await file.length() > 10 * 1024 * 1024) {
      throw const RequestError('Ảnh khôi phục vượt 10 MB. Hãy chụp lại.');
    }
    // Không dùng GPS hiện tại làm vị trí của ảnh đã chụp trước khi khởi động lại.
    return compute(_stampCameraPhoto, {
      'bytes': await file.readAsBytes(),
      'capturedAt': startedAt.toIso8601String(),
      'recovered': true,
    });
  }

  EvidencePhoto sample() {
    final image = img.Image(width: 720, height: 420);
    img.fill(image, color: img.ColorRgb8(213, 234, 235));
    img.drawString(
      image,
      'DEMO - NOT REAL EVIDENCE',
      font: img.arial24,
      x: 35,
      y: 110,
      color: img.ColorRgb8(0, 65, 70),
    );
    return stamp(
      Uint8List.fromList(img.encodeJpg(image)),
      capturedAt: DateTime.now().toUtc(),
      latitude: 20.8841,
      longitude: 105.6215,
      demo: true,
    );
  }

  EvidencePhoto stamp(
    Uint8List bytes, {
    required DateTime capturedAt,
    double? latitude,
    double? longitude,
    bool demo = false,
    bool recovered = false,
  }) {
    if (bytes.length > 10 * 1024 * 1024) {
      throw const RequestError('Ảnh quá lớn.');
    }
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      throw const RequestError('Tệp ảnh không hợp lệ hoặc bị hỏng.');
    }
    if (decoded == null || decoded.width < 32 || decoded.height < 32) {
      throw const RequestError('Ảnh không hợp lệ hoặc quá nhỏ.');
    }
    final photo = img.copyResize(img.bakeOrientation(decoded), width: 720);
    final stamped = img.Image(width: photo.width, height: photo.height + 80);
    img.fill(stamped, color: img.ColorRgb8(0, 35, 40));
    img.compositeImage(stamped, photo);
    img.drawString(
      stamped,
      '${demo ? 'DEMO ' : ''}${recovered ? 'ESTIMATED ' : ''}UTC ${capturedAt.toIso8601String()}',
      font: img.arial14,
      x: 8,
      y: photo.height + 8,
      color: img.ColorRgb8(255, 255, 255),
    );
    img.drawString(
      stamped,
      validCoordinates(latitude, longitude)
          ? 'GPS ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
          : 'GPS UNAVAILABLE - NEEDS VERIFICATION',
      font: img.arial14,
      x: 8,
      y: photo.height + 35,
      color: img.ColorRgb8(255, 255, 255),
    );
    final encoded = img.encodeJpg(stamped, quality: 75);
    if (encoded.length > 1024 * 1024) {
      throw const RequestError('Ảnh sau xử lý vượt quá 1 MB. Hãy chụp lại.');
    }
    return EvidencePhoto(
      id: 'PHOTO-${capturedAt.microsecondsSinceEpoch}',
      base64: base64Encode(encoded),
      capturedAt: capturedAt,
      latitude: latitude,
      longitude: longitude,
      demo: demo,
      recovered: recovered,
    );
  }

  Future<bool> requestNotifications() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const RequestError(
        'Bản mẫu này hiển thị thông báo trong ứng dụng. Xin quyền thông báo hệ thống được hỗ trợ trên Android/iOS.',
      );
    }
    final result = await Permission.notification.request();
    if (result.isPermanentlyDenied) {
      throw const RequestError(
        'Thông báo đang bị chặn. Có thể cấp lại trong cài đặt ứng dụng.',
      );
    }
    return result.isGranted;
  }
}

EvidencePhoto _stampCameraPhoto(Map<String, dynamic> input) =>
    EvidenceService().stamp(
      input['bytes'] as Uint8List,
      capturedAt: DateTime.parse(input['capturedAt'] as String),
      latitude: input['latitude'] as double?,
      longitude: input['longitude'] as double?,
      recovered: input['recovered'] == true,
    );
