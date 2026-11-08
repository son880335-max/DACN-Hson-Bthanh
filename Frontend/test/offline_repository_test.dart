import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flood_relief_app/core/data/api_client.dart';
import 'package:flood_relief_app/core/data/relief_repository.dart';
import 'package:flood_relief_app/core/data/request_draft.dart';
import 'package:flood_relief_app/core/data/vault_web.dart';

class PausedDraftVault extends MemoryVault {
  Completer<void>? draftWrite;
  @override
  Future<void> write(String key, Uint8List value) async {
    if (key == 'draft' && draftWrite != null) await draftWrite!.future;
    await super.write(key, value);
  }
}

class Server {
  final requests = <Json>[], bodies = <Json>[], calls = <String>[];
  bool loseResponse = false, conflict = false, offline = false;
  int uploads = 0;
  Json response(Json body) => {
    'requestId': '54a16201-b6af-4d34-bfa2-407b6115fddb',
    'revision': 1,
    'stage': 'waiting',
    'verification': 'pending',
    'receivedAt': '2026-11-08T10:00:00Z',
    'serverSavedAt': '2026-11-08T10:00:00Z',
  };
  http.Response ok(Json value, {int status = 200}) => http.Response(
    jsonEncode(value),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  Future<http.Response> send(http.Request request) async {
    final path = request.url.path;
    calls.add('${request.method} $path');
    if (path.endsWith('/auth/login')) {
      return ok({
        'token': 'test-session',
        'expiresAt': '2099-01-01T00:00:00Z',
        'account': {
          'id': 'b40f4ec9-dd9e-4461-9845-4a857e6bb765',
          'role': 'citizen',
          'phone': '+12025550101',
          'displayName': 'Kiểm thử',
        },
      });
    }
    if (request.method == 'DELETE') return ok({'signedOut': true});
    if (path.endsWith('/notices')) {
      return ok({'items': <Json>[], 'nextCursor': null});
    }
    if (path.endsWith('/requests') && request.method == 'GET') {
      return ok({'items': requests, 'nextCursor': null});
    }
    if (path.endsWith('/requests') && request.method == 'POST') {
      final body = Map<String, dynamic>.from(jsonDecode(request.body));
      bodies.add(body);
      if (offline) throw http.ClientException('Offline');
      if (requests.isEmpty) {
        requests.add({
          'id': response(body)['requestId'],
          'stage': 'waiting',
          'data': body['data'],
        });
      }
      if (loseResponse) {
        loseResponse = false;
        throw http.ClientException('Lost acknowledgment');
      }
      return ok(response(body), status: 201);
    }
    if (path.endsWith('/cancel')) {
      if (conflict) {
        return ok({
          'code': 'VERSION_CONFLICT',
          'message': 'Yêu cầu đã được đội tiếp nhận.',
        }, status: 409);
      }
      requests.single['stage'] = 'cancelled';
      return ok({
        ...response({}),
        'stage': 'cancelled',
        'revision': 2,
      }, status: 201);
    }
    if (path.endsWith('/evidence') && request.method == 'POST') {
      uploads++;
      return ok({'id': '729e223b-9b3f-40d3-9227-5787a22873d7'}, status: 201);
    }
    if (path.endsWith('/evidence') && request.method == 'PUT') {
      return ok({...response({}), 'revision': 2});
    }
    throw StateError('Unexpected ${request.method} $path');
  }
}

RequestDraft draft() => RequestDraft(
  values: {
    ...RequestDraft().values,
    'types': ['Nước uống'],
    'description': 'Cần nước uống',
    'address': 'Điểm thử',
    'latitude': 0.0,
    'longitude': 0.0,
    'locationSource': 'pin',
    'locationConfirmedAt': '2026-11-08T09:59:00Z',
  },
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('lost acknowledgment persists the same immutable operation across repository recreation', () async {
    final server = Server(), store = MemoryVault();
    ReliefRepository make() => ReliefRepository(
      api: ApiClient(client: MockClient(server.send)),
      openStore: (_) async => store,
    );
    final first = make();
    await first.login('+12025550101', 'test', 'citizen');
    server.loseResponse = true;
    final value = draft();
    final result = await first.submit(value);
    expect(result['pending'], true);
    expect(first.operations.length, 1);
    expect(first.active, isNull);
    value.values['people'] = 8;
    first.dispose();
    final second = make();
    await second.login('+12025550101', 'test', 'citizen');
    expect(server.bodies.length, 2);
    expect(server.bodies[1], server.bodies[0]);
    expect(server.requests.length, 1);
    expect(second.operations, isEmpty);
    expect(second.draft, isNull);
    second.dispose();
  });
  test('request text is acknowledged before optional photos upload; image checkpoint avoids repeated uploads', () async {
    final server = Server(), store = MemoryVault();
    final repo = ReliefRepository(
      api: ApiClient(client: MockClient(server.send)),
      openStore: (_) async => store,
    );
    await repo.login('+12025550101', 'test', 'citizen');
    final value = draft();
    value.photos.add(
      await repo.savePhoto(
        Uint8List.fromList([1, 2, 3]),
        latitude: 0,
        longitude: 0,
      ),
    );
    final result = await repo.submit(value);
    expect(result['photosPending'], true);
    expect(server.uploads, 0);
    expect(server.bodies.single['data']['evidenceIds'], isEmpty);
    await repo.flush();
    expect(server.uploads, 1);
    expect(repo.operations, isEmpty);
    expect(
      server.calls.indexOf('POST /api/v1/requests'),
      lessThan(server.calls.indexOf('POST /api/v1/evidence')),
    );
    repo.dispose();
  });
  test(
    'offline submissions wait before retrying and preserve the operation',
    () async {
      final server = Server(), store = MemoryVault();
      final repo = ReliefRepository(
        api: ApiClient(client: MockClient(server.send)),
        openStore: (_) async => store,
      );
      await repo.login('+12025550101', 'test', 'citizen');
      server.offline = true;
      final result = await repo.submit(draft());
      expect(result['pending'], true);
      expect(server.bodies, hasLength(1));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(server.bodies, hasLength(1));
      expect(repo.operations.single['attempts'], 1);
      server.offline = false;
      await repo.retry();
      expect(server.bodies, hasLength(2));
      expect(server.bodies.last, server.bodies.first);
      expect(repo.operations, isEmpty);
      repo.dispose();
    },
  );
  test(
    'a rejected cancellation never marks an accepted request cancelled locally',
    () async {
      final server = Server(), store = MemoryVault();
      final repo = ReliefRepository(
        api: ApiClient(client: MockClient(server.send)),
        openStore: (_) async => store,
      );
      await repo.login('+12025550101', 'test', 'citizen');
      await repo.submit(draft());
      server.requests.single['stage'] = 'accepted';
      server.conflict = true;
      final result = await repo.cancel({
        'id': server.requests.single['id'],
        'revision': 1,
      });
      expect(result['pending'], true);
      expect(repo.operations.single['state'], 'blocked');
      expect(repo.active?['stage'], 'waiting');
      await repo.refresh();
      expect(repo.active?['stage'], 'accepted');
      repo.dispose();
    },
  );
  test(
    'removing a draft photo preserves bytes referenced by a pending submission',
    () async {
      final server = Server(), store = MemoryVault();
      final repo = ReliefRepository(
        api: ApiClient(client: MockClient(server.send)),
        openStore: (_) async => store,
      );
      await repo.login('+12025550101', 'test', 'citizen');
      final bytes = Uint8List.fromList([1, 2, 3]);
      final photo = await repo.savePhoto(bytes);
      final value = draft()..photos.add(photo);
      server.offline = true;
      await repo.submit(value);
      value.photos.clear();
      await repo.removePhoto(photo);
      expect(await repo.localPhoto(photo['key']), bytes);
      server.offline = false;
      await repo.retry();
      await repo.flush();
      expect(server.uploads, 1);
      expect(repo.operations, isEmpty);
      expect(await repo.localPhoto(photo['key']), isNull);
      repo.dispose();
    },
  );
  test('draft validates complete urgency names, group counts and confirmed zero coordinates', () {
    final value = draft();
    value.values['urgency'] = 'Trung bình';
    expect(value.validate(), isNull);
    value.values['special'] = 2;
    expect(value.validate(), isNotNull);
    value.values['special'] = 0;
    value.values.remove('locationConfirmedAt');
    expect(value.validate(), isNotNull);
  });
  test('an old account response and delayed draft cannot enter the next account cache', () async {
    var accountId = 'first-account';
    final stores = <String, MemoryVault>{};
    final delayed = Completer<http.Response>();
    final api = ApiClient(
      client: MockClient((request) async {
        Json value;
        if (request.url.path.endsWith('/requests/private-id')) {
          return delayed.future;
        }
        if (request.url.path.endsWith('/auth/login')) {
          value = {
            'token': 'token-$accountId',
            'expiresAt': '2099-01-01T00:00:00Z',
            'account': {
              'id': accountId,
              'role': 'citizen',
              'phone': '+12025550101',
              'displayName': accountId,
            },
          };
        } else {
          value = {'items': <Json>[]};
        }
        return http.Response(
          jsonEncode(value),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final repo = ReliefRepository(
      api: api,
      openStore: (owner) async =>
          stores.putIfAbsent(owner, () => PausedDraftVault()),
    );
    await repo.login('+12025550101', 'test', 'citizen');
    await repo.cameraPending(
      context: {'capturedAt': '2026-11-08T10:00:00Z', 'requestId': null},
    );
    await repo.stageCameraPhoto(Uint8List.fromList([1, 2, 3]));
    final paused = stores['first-account']! as PausedDraftVault;
    paused.draftWrite = Completer<void>();
    final oldDraftSave = expectLater(
      repo.saveDraft(draft()),
      throwsA(
        isA<ApiFailure>().having((e) => e.code, 'code', 'SESSION_CHANGED'),
      ),
    );
    final pending = repo.detail('private-id');
    final checked = expectLater(
      pending,
      throwsA(
        isA<ApiFailure>().having((e) => e.code, 'code', 'SESSION_CHANGED'),
      ),
    );
    await repo.logout();
    accountId = 'second-account';
    await repo.login('+12025550102', 'test', 'citizen');
    paused.draftWrite!.complete();
    await oldDraftSave;
    expect(repo.draft, isNull);
    expect(await repo.hasPendingCamera(), false);
    expect(await repo.recoveredCameraPhoto(), isNull);
    expect(await stores['first-account']!.read('camera-recovered'), isNotNull);
    delayed.complete(
      http.Response(
        jsonEncode({
          'contact': {'name': 'first-account private data'},
        }),
        200,
      ),
    );
    await checked;
    expect(await stores['second-account']!.keys('request:'), isEmpty);
    repo.dispose();
  });
}
