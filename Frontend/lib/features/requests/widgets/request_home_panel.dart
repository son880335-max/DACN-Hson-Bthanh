import 'package:flutter/material.dart';

import '../data/relief_request.dart';
import '../widgets/request_loader.dart';
import '../screens/request_detail_screen.dart';
import '../screens/request_wizard_screen.dart';

/// Chỉ thay khu vực yêu cầu của trang chủ, giữ các chức năng sprint trước.
class RequestHomePanel extends StatelessWidget {
  const RequestHomePanel({super.key});
  @override
  Widget build(BuildContext context) => RequestLoader(
    builder: (context, store) {
      final items = store.list();
      final active = items.where(
        (r) =>
            r.stage == RequestStage.accepted ||
            (r.stage == RequestStage.waiting &&
                r.verification != Verification.invalid),
      );
      final drafts = items.where((r) => r.stage == RequestStage.draft);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(demoNotice),
          for (final r in active)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Yêu cầu #${r.id}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(r.data.address),
                    Text('${r.data.people} người • ${r.data.types.join(', ')}'),
                    Text(
                      '${stageLabel(r.stage)} • ${verificationLabel(r.verification)}',
                    ),
                    if (r.notices.isNotEmpty)
                      Text(r.notices.last['text'] as String),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestDetailScreen(requestId: r.id),
                        ),
                      ),
                      child: const Text('Xem chi tiết'),
                    ),
                  ],
                ),
              ),
            ),
          if (active.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Hiện không có yêu cầu đang xử lý.'),
              ),
            ),
          for (final r in drafts)
            Card(
              child: ListTile(
                title: const Text('Bản nháp yêu cầu cứu trợ'),
                subtitle: Text('Đã lưu ${r.updatedAt.toLocal()} • Chưa gửi'),
                trailing: const Icon(Icons.edit_note),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestWizardScreen(requestId: r.id),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
