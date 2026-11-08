import 'package:flutter/material.dart';

import '../data/relief_repository.dart';
import '../data/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

String userFacingError(Object error) => error is ApiFailure
    ? error.message
    : error is String
    ? error
    : 'Chưa thực hiện được thao tác. Hãy thử lại.';

void showFailure(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(userFacingError(error))));
void showDraftSaved(BuildContext context) => showFailure(
  context,
  reliefRepository.durable ? 'Đã lưu bản nháp trên thiết bị.' : 'Bản web chỉ giữ tạm trong phiên hiện tại. Dùng ứng dụng Android/iOS để lưu nháp trên thiết bị.',
);

class SyncStatus extends StatelessWidget {
  const SyncStatus({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: reliefRepository,
    builder: (context, _) {
      final repo = reliefRepository;
      if (repo.operations.isEmpty && repo.lastError == null) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warningBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              repo.onlyPhotosPending
                  ? 'Nội dung yêu cầu đã lưu; ảnh bổ sung đang chờ'
                  : repo.operations.isEmpty
                  ? 'Chưa cập nhật được dữ liệu'
                  : 'Đang chờ xác nhận',
              style: AppTypography.bodyMedium,
            ),
            Text(
              repo.lastError ??
                  'Thông tin vẫn được giữ để gửi lại khi có kết nối.',
              style: AppTypography.secondary,
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: () =>
                      repo.operations.isEmpty ? repo.refresh() : repo.retry(),
                  child: const Text('Thử lại'),
                ),
                for (final operation in repo.operations.where(
                  (o) => o['state'] == 'blocked',
                ))
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Giữ bản nháp và kiểm tra lại'),
                          content: const Text(
                            'Thao tác chưa được chấp nhận. Giữ bản nháp và tải dữ liệu mới để kiểm tra lại?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Quay lại'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Kiểm tra lại'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await repo.discardRejectedOperation(operation['id']);
                        await repo.refresh();
                      }
                    },
                    child: const Text('Xem lại thao tác bị từ chối'),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
