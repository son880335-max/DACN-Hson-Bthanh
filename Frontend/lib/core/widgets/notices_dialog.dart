import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/relief_repository.dart';
import '../data/request_presentation.dart';
import 'sync_status.dart';

Future<void> showNotices(BuildContext context) async {
  await reliefRepository.refresh();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Thông báo yêu cầu'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: ListenableBuilder(
          listenable: reliefRepository,
          builder: (context, _) => reliefRepository.notices.isEmpty
              ? const Center(child: Text('Chưa có thông báo.'))
              : ListView.builder(
                  itemCount: reliefRepository.notices.length,
                  itemBuilder: (context, index) {
                    final notice = reliefRepository.notices[index];
                    return ListTile(
                      title: Text(notice['message']),
                      subtitle: Text(formatTimestamp(notice['createdAt'])),
                      trailing: notice['read'] == true
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.done),
                              tooltip: 'Đánh dấu đã đọc',
                              onPressed: () async {
                                try {
                                  await reliefRepository.markNoticeRead(
                                    notice['id'],
                                  );
                                } catch (error) {
                                  if (context.mounted) {
                                    showFailure(context, error);
                                  }
                                }
                              },
                            ),
                    );
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final status = await Permission.notification.request();
            if (ctx.mounted) {
              showFailure(
                ctx,
                status.isGranted
                    ? 'Đã cấp quyền thông báo trên thiết bị. Thông báo yêu cầu hiện được xem trong ứng dụng.'
                    : 'Bạn vẫn có thể xem thông báo trong ứng dụng.',
              );
            }
          },
          child: const Text('Cho phép thông báo'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
