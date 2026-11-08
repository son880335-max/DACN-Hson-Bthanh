import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/relief_repository.dart';
import '../data/request_draft.dart';
import '../data/request_presentation.dart';
import '../theme/app_colors.dart';

Future<bool?> previewCapturedPhoto(
  BuildContext context,
  Uint8List bytes,
) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      if (descriptor.width * descriptor.height >
          const int.fromEnvironment(
            'MAX_IMAGE_PIXELS',
            defaultValue: 20000000,
          )) {
        throw const FormatException('Image dimensions exceed the limit');
      }
    } finally {
      descriptor.dispose();
    }
  } catch (_) {
    throw 'Không đọc được ảnh hoặc ảnh quá lớn. Hãy chụp lại hoặc tiếp tục không có ảnh.';
  } finally {
    buffer.dispose();
  }
  if (!context.mounted) return null;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Xem trước ảnh'),
      content: SizedBox(
        width: 400,
        height: 320,
        child: InteractiveViewer(
          child: Image.memory(
            bytes,
            cacheWidth: 1280,
            errorBuilder: (_, _, _) =>
                const Text('Không đọc được ảnh. Hãy chụp lại.'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Bỏ ảnh'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Chụp lại'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Dùng ảnh'),
        ),
      ],
    ),
  );
}

class LocalEvidencePreview extends StatefulWidget {
  const LocalEvidencePreview({super.key, required this.photo});
  final Json photo;
  @override
  State<LocalEvidencePreview> createState() => _LocalEvidencePreviewState();
}

class _LocalEvidencePreviewState extends State<LocalEvidencePreview> {
  late Future<Uint8List?> _bytes;
  @override
  void initState() {
    super.initState();
    _bytes = reliefRepository.localPhoto(widget.photo['key']);
  }

  @override
  void didUpdateWidget(covariant LocalEvidencePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo['key'] != widget.photo['key']) {
      _bytes = reliefRepository.localPhoto(widget.photo['key']);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _bytes,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null) {
        return const Icon(Icons.image_outlined, color: AppColors.textSecondary);
      }
      return InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: InteractiveViewer(
                    child: Image.memory(
                      bytes,
                      cacheWidth: 1280,
                      errorBuilder: (_, _, _) =>
                          const Text('Không đọc được ảnh. Hãy chụp lại.'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Giờ thiết bị: ${formatTimestamp(widget.photo['capturedAt'], seconds: true)}\nTọa độ tham chiếu: ${widget.photo['latitude'] ?? 'Chưa có'}, ${widget.photo['longitude'] ?? 'Chưa có'}',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        ),
        child: Image.memory(
          bytes,
          cacheWidth: 128,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
        ),
      );
    },
  );
}

class RemoteEvidencePreview extends StatefulWidget {
  const RemoteEvidencePreview({super.key, required this.id});
  final String id;
  @override
  State<RemoteEvidencePreview> createState() => _RemoteEvidencePreviewState();
}

class _RemoteEvidencePreviewState extends State<RemoteEvidencePreview> {
  late Future<Uint8List> _bytes;
  @override
  void initState() {
    super.initState();
    _bytes = reliefRepository.evidence(widget.id);
  }

  @override
  void didUpdateWidget(covariant RemoteEvidencePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _bytes = reliefRepository.evidence(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Tooltip(
          message: 'Chưa tải được ảnh',
          child: Icon(Icons.broken_image),
        );
      }
      final bytes = snapshot.data;
      if (bytes == null) {
        return const SizedBox(
          width: 48,
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      return InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            child: FutureBuilder<Uint8List>(
              future: reliefRepository.evidence(widget.id, full: true),
              builder: (context, full) => full.hasError
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa tải được ảnh. Thử lại khi có mạng.'),
                    )
                  : full.data == null
                  ? const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : InteractiveViewer(
                      child: Image.memory(full.data!, cacheWidth: 1280),
                    ),
            ),
          ),
        ),
        child: Image.memory(
          bytes,
          width: 80,
          height: 80,
          cacheWidth: 160,
          fit: BoxFit.cover,
        ),
      );
    },
  );
}
