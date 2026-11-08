import 'package:flutter/material.dart';

import '../data/relief_request.dart';
import '../widgets/request_loader.dart';
import '../widgets/report_request_dialog.dart';
import 'request_detail_screen.dart';
import 'request_wizard_screen.dart';

class RequestListScreen extends StatefulWidget {
  final DemoRole role;
  const RequestListScreen({super.key, this.role = DemoRole.citizen});
  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  String _filter = 'all', _query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.role == DemoRole.admin
            ? 'Tra cứu & xác minh yêu cầu'
            : 'Yêu cầu của tôi',
      ),
      automaticallyImplyLeading: false,
      actions: [
        if (widget.role == DemoRole.citizen)
          IconButton(
            tooltip: 'Báo cáo yêu cầu theo mã',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () async {
              final sent = await showDialog<bool>(
                context: context,
                builder: (_) => const ReportRequestDialog(),
              );
              if (sent == true && context.mounted) {
                requestMessage(context, 'Đã lưu báo cáo để quản trị kiểm tra.');
              }
            },
          ),
      ],
    ),
    floatingActionButton: widget.role == DemoRole.citizen
        ? FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestWizardScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tạo yêu cầu'),
          )
        : null,
    body: RequestLoader(
      builder: (context, store) {
        final all = store.list(role: widget.role);
        final filtered = all.where((r) {
          final match =
              '${r.id} ${r.data.address} ${r.data.description} ${r.data.contactPhone}'
                  .toLowerCase()
                  .contains(_query.toLowerCase().trim());
          return match &&
              switch (_filter) {
                'draft' => r.stage == RequestStage.draft,
                'active' =>
                  (r.stage == RequestStage.waiting &&
                          r.verification != Verification.invalid) ||
                      r.stage == RequestStage.accepted,
                'review' =>
                  r.stage == RequestStage.waiting &&
                      (r.verification == Verification.pending ||
                          r.verification == Verification.needsInfo),
                'finished' =>
                  r.stage == RequestStage.completed ||
                      r.stage == RequestStage.cancelled ||
                      r.verification == Verification.invalid,
                _ => true,
              };
        }).toList();
        return Column(
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text(demoNotice)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Tìm mã, địa chỉ, mô tả, số điện thoại',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    for (final entry in {
                      'all': 'Tất cả (${all.length})',
                      'draft': 'Bản nháp',
                      'active': 'Đang xử lý',
                      'review': 'Cần xác minh',
                      'finished': 'Kết thúc',
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _filter == entry.key,
                          onSelected: (_) =>
                              setState(() => _filter = entry.key),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Không có yêu cầu phù hợp.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final r = filtered[index];
                        return Card(
                          child: ListTile(
                            isThreeLine: true,
                            title: Text('${r.id} • ${r.data.urgency}'),
                            subtitle: Text(
                              '${r.data.types.join(', ')} • ${r.data.people} người\n${r.data.address}\n${stageLabel(r.stage)} • ${verificationLabel(r.verification)}${r.notices.isEmpty ? '' : ' • Có thông báo'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RequestDetailScreen(
                                  requestId: r.id,
                                  role: widget.role,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}
