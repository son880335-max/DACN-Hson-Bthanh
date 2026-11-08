import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'request_draft.dart';
import 'vault.dart';

ReliefRepository reliefRepository = ReliefRepository();

class ReliefRepository extends ChangeNotifier with WidgetsBindingObserver {
  ReliefRepository({ApiClient? api, this.openStore = openVault})
    : api = api ?? ApiClient();
  final ApiClient api;
  final Future<Vault> Function(String) openStore;
  static const _secure = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  Vault? _vault;
  Json? account;
  List<Json> items = [], notices = [], operations = [];
  RequestDraft? draft;
  String? lastError, nextCursor;
  bool loading = false;
  Timer? _retry;
  Future<void>? _synchronizing;
  Future<void> _cacheWork = Future.value();
  int _sessionEpoch = 0;
  StreamSubscription<List<ConnectivityResult>>? _connection;
  bool get signedIn => account != null;
  bool get durable => _vault?.durable ?? false;
  bool get pending => operations.any((o) => o['state'] != 'blocked');
  bool get onlyPhotosPending =>
      operations.isNotEmpty && operations.every((o) => o['kind'] == 'evidence');
  Json? get active => items
      .where((r) => ['waiting', 'accepted'].contains(r['stage']))
      .firstOrNull;
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _connection = Connectivity().onConnectivityChanged.listen(
      (_) => synchronizeInBackground(),
      onError: (Object error) => _backgroundError(error),
    );
    try {
      if (!kIsWeb) {
        final session = await _secure.read(key: 'relief-session');
        if (session != null) {
          final saved = Map<String, dynamic>.from(jsonDecode(session));
          final expiry = DateTime.tryParse(saved['expiresAt'] ?? '');
          if (expiry == null || !expiry.isAfter(DateTime.now())) {
            await _secure.delete(key: 'relief-session');
            return;
          }
          api.token = saved['token'];
          await _open(Map<String, dynamic>.from(saved['account']));
        }
      }
    } catch (error) {
      api.token = null;
      account = null;
      await _vault?.close();
      _vault = null;
      _backgroundError(error);
    }
  }

  void _backgroundError(Object error) {
    lastError = error is ApiFailure ? error.message : 'Chưa đọc/ghi được dữ liệu trên thiết bị. Thông tin đã lưu không bị tự xóa. Hãy kiểm tra bộ nhớ và thử lại.';
    notifyListeners();
  }

  void synchronizeInBackground() {
    unawaited(flush().then((_) => refresh()).catchError(_backgroundError));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && signedIn) {
      synchronizeInBackground();
    }
  }

  Future<void> _open(Json actor) async {
    _sessionEpoch++;
    _vault = await openStore(actor['id']);
    account = actor;
    final cached = await _read('list');
    items = _jsonList(cached?['items']);
    nextCursor = cached?['nextCursor'];
    notices = _jsonList((await _read('notices'))?['items']);
    final saved = await _read('draft');
    draft = saved == null ? null : RequestDraft.fromJson(saved);
    await _loadOperations();
    notifyListeners();
  }

  List<Json> _jsonList(dynamic value) =>
      (value as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  Future<void> login(String phone, String password, String role) async {
    if (signedIn) await logout();
    final result = await api.json(
      'POST',
      '/auth/login',
      body: {'phone': phone.trim(), 'password': password},
    );
    final actor = Map<String, dynamic>.from(result['account']);
    api.token = result['token'];
    if (actor['role'] != role) {
      try {
        await api.json('DELETE', '/auth/session');
      } finally {
        api.token = null;
      }
      throw const ApiFailure(
        403,
        'ROLE_MISMATCH',
        'Tài khoản thuộc vai trò khác. Hãy chọn đúng màn hình đăng nhập.',
      );
    }
    if (_vault != null) await _vault!.close();
    await _open(actor);
    if (!kIsWeb) {
      await _secure.write(key: 'relief-session', value: jsonEncode(result));
    }
    await flush();
    await refresh();
  }

  Future<void> logout() async {
    _retry?.cancel();
    await _synchronizing;
    await _cacheWork.catchError((Object error) {});
    try {
      if (api.token != null) await api.json('DELETE', '/auth/session');
    } on ApiFailure {
      /* Local session is removed even offline. */
    }
    await _secure.delete(key: 'relief-session');
    api.token = null;
    _sessionEpoch++;
    loading = false;
    account = null;
    await _vault?.close();
    _vault = null;
    items = [];
    notices = [];
    operations = [];
    draft = null;
    lastError = null;
    notifyListeners();
  }

  Future<Json?> _read(String key) async {
    final bytes = await _vault?.read(key);
    return bytes == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)));
  }

  Future<void> _write(String key, Json value) async {
    final store = _vault;
    if (store == null) {
      throw const ApiFailure(
        401,
        'SIGN_IN_REQUIRED',
        'Đăng nhập trước khi lưu thông tin cá nhân.',
      );
    }
    await store.write(key, Uint8List.fromList(utf8.encode(jsonEncode(value))));
  }

  Future<void> saveDraft(RequestDraft value) async {
    final epoch = _sessionEpoch;
    await _write('draft', value.toJson());
    _assertSession(epoch);
    draft = value;
    notifyListeners();
  }

  Future<Uint8List?> localPhoto(String key) async => _vault?.read(key);
  Future<Json> savePhoto(
    Uint8List bytes, {
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
  }) async {
    final epoch = _sessionEpoch;
    final key = 'photo:${operationUuid.v4()}';
    if (_vault == null) {
      throw const ApiFailure(401, 'SIGN_IN_REQUIRED', 'Đăng nhập để lưu ảnh.');
    }
    await _vault!.write(key, bytes);
    _assertSession(epoch);
    return {
      'key': key,
      'operationId': operationUuid.v4(),
      'capturedAt': (capturedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Future<void> removePhoto(Json photo) async {
    final store = _vault;
    if (store == null) return;
    for (final key in await store.keys('outbox:')) {
      final operation = await _read(key);
      if (_jsonList(operation?['photos'])
          .any((p) => p['key'] == photo['key'])) {
        return;
      }
    }
    await store.remove(photo['key']);
  }

  Future<void> refresh({bool more = false}) async {
    if (!signedIn || loading) return;
    final epoch = _sessionEpoch;
    loading = true;
    notifyListeners();
    try {
      final result = await api.json(
        'GET',
        '/requests${more && nextCursor != null ? '?before=$nextCursor' : ''}',
      );
      final fetched = _jsonList(result['items']);
      if (epoch != _sessionEpoch) return;
      items = more
          ? [
              ...items,
              ...fetched.where((r) => !items.any((i) => i['id'] == r['id'])),
            ]
          : fetched;
      nextCursor = result['nextCursor'];
      await _write('list', {'items': items, 'nextCursor': nextCursor});
      final noticeResult = await api.json('GET', '/notices');
      if (epoch != _sessionEpoch) return;
      notices = _jsonList(noticeResult['items']);
      await _write('notices', noticeResult);
      lastError = null;
    } on ApiFailure catch (error) {
      if (epoch == _sessionEpoch) lastError = error.message;
    } finally {
      if (epoch == _sessionEpoch) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<Json> detail(String id) async {
    final epoch = _sessionEpoch;
    try {
      final result = await api.json('GET', '/requests/$id');
      if (epoch != _sessionEpoch) {
        throw const ApiFailure(
          401,
          'SESSION_CHANGED',
          'Phiên tài khoản đã thay đổi. Hãy mở lại yêu cầu.',
        );
      }
      await _cache(
        'request:$id',
        Uint8List.fromList(utf8.encode(jsonEncode(result))),
      );
      return result;
    } on ApiFailure catch (error) {
      if (error.status == 0 || error.status >= 500) {
        final cached = await _read('request:$id');
        if (cached != null) return {...cached, 'cached': true};
      }
      rethrow;
    }
  }

  Future<Uint8List> evidence(String id, {bool full = false}) async {
    final epoch = _sessionEpoch;
    final key = 'evidence:$id:${full ? 'full' : 'thumb'}';
    final cached = await _vault?.read(key);
    if (epoch != _sessionEpoch) {
      throw const ApiFailure(
        401,
        'SESSION_CHANGED',
        'Phiên tài khoản đã thay đổi.',
      );
    }
    if (cached != null) return cached;
    final bytes = await api.image(id, thumbnail: !full);
    if (epoch != _sessionEpoch) {
      throw const ApiFailure(
        401,
        'SESSION_CHANGED',
        'Phiên tài khoản đã thay đổi.',
      );
    }
    await _cache(key, bytes);
    return bytes;
  }

  Future<void> _cache(String key, Uint8List bytes) async {
    final store = _vault;
    final next = _cacheWork.catchError((Object error) {}).then((_) async {
      if (store == null || !identical(store, _vault)) return;
      final index = await _read('cache-index') ?? <String, dynamic>{};
      index.remove(key);
      index[key] = bytes.length;
      var size = index.values.fold<int>(
        0,
        (sum, value) => sum + (value as int),
      );
      const limit = int.fromEnvironment(
        'PRIVATE_CACHE_BYTES',
        defaultValue: 32 * 1024 * 1024,
      );
      final removals = <String>[];
      while (size > limit && index.isNotEmpty) {
        final oldest = index.keys.first;
        size -= index.remove(oldest) as int;
        removals.add(oldest);
      }
      await store.commit({
        if (index.containsKey(key)) key: bytes,
        'cache-index': Uint8List.fromList(utf8.encode(jsonEncode(index))),
      }, removals);
    });
    _cacheWork = next;
    try {
      await next;
    } catch (error) {
      _backgroundError(error);
    }
  }

  Future<void> cameraPending({Json? context}) async {
    final epoch = _sessionEpoch;
    final store = _vault;
    if (store == null) {
      throw const ApiFailure(401, 'SIGN_IN_REQUIRED', 'Đăng nhập để chụp ảnh.');
    }
    await store.commit(
      {
        'camera-pending': Uint8List.fromList(
          utf8.encode(jsonEncode({'pending': true, ...?context})),
        ),
      },
      ['camera-recovered'],
    );
    _assertSession(epoch);
  }

  void _assertSession(int epoch) {
    if (epoch != _sessionEpoch) {
      throw const ApiFailure(
        401,
        'SESSION_CHANGED',
        'Tài khoản đã thay đổi. Hãy mở lại yêu cầu từ tài khoản hiện tại.',
      );
    }
  }

  Future<Json?> pendingCamera() => _read('camera-pending');
  Future<void> stageCameraPhoto(Uint8List bytes) async {
    final store = _vault;
    if (store == null) throw StateError('No camera owner');
    await store.write('camera-recovered', bytes);
  }

  Future<Uint8List?> recoveredCameraPhoto() async =>
      _vault?.read('camera-recovered');
  Future<bool> hasPendingCamera() async =>
      (await _read('camera-pending')) != null;
  Future<void> cameraFinished() async {
    await _vault?.commit({}, ['camera-pending', 'camera-recovered']);
  }

  Future<Json> submit(RequestDraft value) async {
    final error = value.validate();
    if (error != null) throw ApiFailure(422, 'VALIDATION_FAILED', error);
    if (operations.any((o) => o['kind'] != 'evidence')) {
      throw const ApiFailure(
        409,
        'PENDING_OPERATION',
        'Một thao tác đang chờ xác nhận. Hãy xử lý kết quả đó trước khi gửi thay đổi.',
      );
    }
    await saveDraft(value);
    final id = operationUuid.v4();
    final operation = {
      'id': id,
      'kind': value.requestId == null ? 'create' : 'update',
      'requestId': value.requestId,
      'revision': value.revision,
      'data': {
        ...value.values,
        'clientActionAt': DateTime.now().toUtc().toIso8601String(),
      },
      'photos': value.photos,
      'attempts': 0,
      'state': 'pending',
    };
    await _write('outbox:$id', operation);
    await _loadOperations();
    notifyListeners();
    await flush();
    return await _read('receipt:$id') ?? {'pending': true, 'operationId': id};
  }

  Future<Json> cancel(Json request) async {
    if (operations.any((o) => o['kind'] != 'evidence')) {
      throw const ApiFailure(
        409,
        'PENDING_OPERATION',
        'Chờ xác nhận thao tác trước đó rồi thử hủy.',
      );
    }
    final id = operationUuid.v4();
    await _write('outbox:$id', {
      'id': id,
      'kind': 'cancel',
      'requestId': request['id'],
      'revision': request['revision'],
      'data': {'confirmed': true},
      'photos': <Json>[],
      'state': 'pending',
      'attempts': 0,
    });
    await _loadOperations();
    notifyListeners();
    await flush();
    return await _read('receipt:$id') ?? {'pending': true, 'operationId': id};
  }

  Future<Json> reviewOrReport(String kind, Json request, Json body) async {
    if (!['review', 'report'].contains(kind)) throw ArgumentError.value(kind);
    if (operations.isNotEmpty) {
      throw const ApiFailure(
        409,
        'PENDING_OPERATION',
        'Chờ xác nhận thao tác trước rồi thử lại.',
      );
    }
    final id = operationUuid.v4();
    await _write('outbox:$id', {
      'id': id,
      'kind': kind,
      'requestId': request['id'],
      'revision': request['revision'],
      'data': body,
      'photos': <Json>[],
      'state': 'pending',
      'attempts': 0,
    });
    await _loadOperations();
    notifyListeners();
    await flush();
    return await _read('receipt:$id') ?? {'pending': true, 'operationId': id};
  }

  Future<void> _loadOperations() async {
    final keys = await _vault?.keys('outbox:') ?? [];
    operations = [];
    for (final key in keys) {
      final item = await _read(key);
      if (item != null) operations.add(item);
    }
  }

  Future<void> retry() async {
    for (final operation in operations) {
      operation['state'] = 'pending';
      await _write('outbox:${operation['id']}', operation);
    }
    await flush();
  }

  Future<void> discardRejectedOperation(String id) async {
    final operation = operations.where((o) => o['id'] == id).firstOrNull;
    if (operation == null || operation['state'] != 'blocked') return;
    await _vault?.remove('outbox:$id');
    await _loadOperations();
    notifyListeners();
  }

  Future<void> flush() {
    if (_synchronizing != null) return _synchronizing!;
    if (!signedIn) return Future.value();
    final future = _flush();
    _synchronizing = future;
    return future.whenComplete(() => _synchronizing = null);
  }

  Future<void> _flush() async {
    _retry?.cancel();
    await _loadOperations();
    final batch = operations.toList()
      ..sort(
        (a, b) => (a['kind'] == 'evidence' ? 1 : 0).compareTo(
          b['kind'] == 'evidence' ? 1 : 0,
        ),
      );
    bool saved = false;
    bool interrupted = false;
    for (final operation in batch) {
      if (operation['state'] == 'blocked') continue;
      try {
        final body = Map<String, dynamic>.from(operation['data']);
        final evidenceIds = List<String>.from(body['evidenceIds'] ?? []);
        final photos = _jsonList(operation['photos']);
        final kind = operation['kind'];
        if (kind == 'evidence') {
          for (final photo in photos) {
            if (photo['evidenceId'] != null) {
              evidenceIds.add(photo['evidenceId']);
              continue;
            }
            final bytes = await _vault!.read(photo['key']);
            if (bytes == null) {
              throw const ApiFailure(
                422,
                'PHOTO_MISSING',
                'Ảnh đã lưu không còn đọc được. Bản nháp vẫn được giữ.',
              );
            }
            final result = await api.upload(bytes, {
              'operationId': photo['operationId'],
              'capturedAt': photo['capturedAt'],
              'latitude': photo['latitude'],
              'longitude': photo['longitude'],
            });
            evidenceIds.add(result['id']);
            photo['evidenceId'] = result['id'];
            operation['photos'] = photos;
            await _write('outbox:${operation['id']}', operation);
          }
        }
        Json payload;
        if (kind == 'cancel') {
          payload = {'operationId': operation['id'], 'confirmed': true};
        } else if (kind == 'evidence') {
          payload = {
            'operationId': operation['id'],
            'evidenceIds': evidenceIds.toSet().toList(),
          };
        } else if (kind == 'review' || kind == 'report') {
          payload = {'operationId': operation['id'], ...body};
        } else {
          body['evidenceIds'] = evidenceIds.toSet().toList();
          payload = {'operationId': operation['id'], 'data': body};
        }
        final suffix =
            {
              'cancel': '/cancel',
              'review': '/reviews',
              'report': '/reports',
              'evidence': '/evidence',
            }[kind] ??
            '';
        final path = kind == 'create'
            ? '/requests'
            : '/requests/${operation['requestId']}$suffix';
        final result = await api.json(
          kind == 'update' || kind == 'evidence' ? 'PUT' : 'POST',
          path,
          body: payload,
          revision: operation['revision'],
        );
        final writes = <String, Uint8List>{
          'receipt:${operation['id']}': Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                ...result,
                'photosPending': photos.isNotEmpty && kind != 'evidence',
              }),
            ),
          ),
        };
        final attachments =
            (kind == 'create' || kind == 'update') && photos.isNotEmpty;
        if (attachments) {
          final attachmentId = operationUuid.v4();
          writes['outbox:$attachmentId'] = Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                'id': attachmentId,
                'kind': 'evidence',
                'requestId': result['requestId'],
                'revision': result['revision'],
                'data': {'evidenceIds': <String>[]},
                'photos': photos,
                'state': 'pending',
                'attempts': 0,
              }),
            ),
          );
        }
        await _vault!.commit(writes, [
          'outbox:${operation['id']}',
          if (kind == 'create' || kind == 'update') 'draft',
          if (kind == 'evidence')
            for (final photo in photos) photo['key'] as String,
        ]);
        if (kind == 'create' || kind == 'update') {
          draft = null;
        }
        saved = true;
        lastError = null;
      } on ApiFailure catch (error) {
        interrupted = true;
        operation['attempts'] = (operation['attempts'] as int) + 1;
        operation['state'] = error.retryable ? 'pending' : 'blocked';
        operation['error'] = error.message;
        operation['errorCode'] = error.code;
        await _write('outbox:${operation['id']}', operation);
        lastError = error.message;
        if (error.retryable) {
          final seconds =
              min(60, pow(2, min(operation['attempts'] as int, 6)).toInt()) +
              Random().nextInt(3);
          _retry = Timer(Duration(seconds: seconds), _retryInBackground);
        }
        break;
      }
    }
    await _loadOperations();
    notifyListeners();
    if (saved || operations.isEmpty) await refresh();
    if (!interrupted &&
        saved &&
        operations.any((o) => o['state'] == 'pending')) {
      _retry?.cancel();
      _retry = Timer(Duration.zero, _retryInBackground);
    }
  }

  void _retryInBackground() {
    unawaited(flush().catchError(_backgroundError));
  }

  Future<void> markNoticeRead(String id) async {
    await api.json('PUT', '/notices/$id/read');
    await refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retry?.cancel();
    unawaited(_connection?.cancel());
    super.dispose();
  }
}
