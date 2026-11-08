import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'request_draft.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.status, this.code, this.message);
  final int status;
  final String code, message;
  bool get retryable => status == 0 || status == 429 || status >= 500;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://127.0.0.1:3000/api/v1',
          );
  final http.Client client;
  final String baseUrl;
  String? token;
  Uri uri(String path) {
    final value = Uri.parse('$baseUrl$path');
    if (kReleaseMode && value.scheme != 'https') {
      throw const ApiFailure(
        400,
        'HTTPS_REQUIRED',
        'Bản phát hành cần địa chỉ máy chủ HTTPS.',
      );
    }
    return value;
  }

  Map<String, String> get headers => {
    if (token != null) 'Authorization': 'Bearer $token',
  };
  Future<Json> json(
    String method,
    String path, {
    Json? body,
    int? revision,
  }) async {
    final abort=Completer<void>();
    final request = http.AbortableRequest(method, uri(path),abortTrigger:abort.future)..headers.addAll(headers);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (revision != null) request.headers['If-Match'] = '"$revision"';
    return decode(await _send(request,abort));
  }

  Future<http.Response> _send(http.BaseRequest request,Completer<void> abort) async {
    try {
      return await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 30),onTimeout:(){abort.complete();throw TimeoutException('No acknowledgment');});
    } on TimeoutException {
      throw const ApiFailure(
        0,
        'NETWORK_TIMEOUT',
        'Chưa nhận được xác nhận. Thông tin được giữ để gửi lại.',
      );
    } on http.ClientException {
      throw const ApiFailure(
        0,
        'NETWORK_UNAVAILABLE',
        'Không kết nối được máy chủ. Hãy kiểm tra mạng và giữ bản nháp.',
      );
    }
  }

  Json decode(http.Response response) {
    Json value;
    try {
      value = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      throw ApiFailure(
        response.statusCode >= 400 ? response.statusCode : 502,
        'INVALID_RESPONSE',
        'Máy chủ trả dữ liệu chưa hợp lệ.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final fields = value['fields'] as List?;
      throw ApiFailure(
        response.statusCode,
        value['code'] ?? 'REQUEST_FAILED',
        fields?.isNotEmpty == true
            ? '${value['message']} ${fields!.first['message']}'
            : value['message'] ?? 'Thao tác chưa thành công.',
      );
    }
    return value;
  }

  Future<Json> upload(Uint8List bytes, Json metadata) async {
    final abort=Completer<void>();
    final request = http.AbortableMultipartRequest('POST', uri('/evidence'),abortTrigger:abort.future)
      ..headers.addAll(headers)
      ..fields['metadata'] = jsonEncode(metadata)
      ..files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: 'camera.jpg'),
      );
    return decode(await _send(request,abort));
  }

  Future<Uint8List> image(String id, {bool thumbnail = true}) async {
    final abort=Completer<void>();
    final response = await _send(
      http.AbortableRequest(
        'GET',
        uri('/evidence/$id${thumbnail ? '?thumbnail=1' : ''}'),
        abortTrigger:abort.future,
      )..headers.addAll(headers),
      abort,
    );
    if (response.statusCode != 200) decode(response);
    return response.bodyBytes;
  }
}
