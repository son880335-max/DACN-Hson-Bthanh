import 'package:flutter/material.dart';

import '../data/request_store.dart';

class RequestLoader extends StatefulWidget {
  final Widget Function(BuildContext context, RequestStore store) builder;
  const RequestLoader({super.key, required this.builder});
  @override
  State<RequestLoader> createState() => _RequestLoaderState();
}

class _RequestLoaderState extends State<RequestLoader> {
  late Future<void> _loading = RequestStore.instance.load();
  @override
  Widget build(BuildContext context) => RequestStore.instance.isLoaded
      ? ListenableBuilder(
          listenable: RequestStore.instance,
          builder: (context, _) =>
              widget.builder(context, RequestStore.instance),
        )
      : FutureBuilder<void>(
          future: _loading,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error is RequestError
                          ? (snapshot.error as RequestError).message
                          : 'Không tải được dữ liệu yêu cầu. Vui lòng thử lại.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(
                        () => _loading = RequestStore.instance.load(),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListenableBuilder(
              listenable: RequestStore.instance,
              builder: (context, _) =>
                  widget.builder(context, RequestStore.instance),
            );
          },
        );
}

void requestMessage(BuildContext context, Object message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$message')));
}

const demoNotice =
    'Dữ liệu mẫu trên thiết bị • Chưa gửi tới lực lượng cứu hộ thực tế.';
