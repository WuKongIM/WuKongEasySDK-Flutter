import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fixed public errors keep upstream bodies and credential-bearing URLs private.
class StreamFailure implements Exception {
  const StreamFailure();
  @override
  String toString() => 'Stream operation failed';
}

Uri _address(String value) {
  final uri = Uri.parse(value);
  if (!['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const StreamFailure();
  }
  return uri;
}

/// Bounded management transport for the explicitly writable development demo.
class StreamAPI {
  final Uri base;
  final http.Client _client = http.Client();
  StreamAPI(String value) : base = _address(value.trim());
  Future<Map<String, dynamic>> _json(http.Request request) async {
    request.followRedirects = false;
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.listen((_) {}).cancel();
      throw const StreamFailure();
    }
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 15),
    )) {
      if (bytes.length + chunk.length > 2 * 1024 * 1024) {
        throw const StreamFailure();
      }
      bytes.addAll(chunk);
    }
    final value = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (value['status'] != null && value['status'] != 200) {
      throw const StreamFailure();
    }
    return value;
  }

  Uri endpoint(String path) =>
      base.replace(path: '${base.path.replaceFirst(RegExp(r'/$'), '')}$path');
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _json(
        http.Request('POST', endpoint(path))
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode(body),
      );
  Future<String> route(String uid) async {
    final value = await _json(
      http.Request(
        'GET',
        endpoint('/route').replace(queryParameters: {'uid': uid}),
      ),
    );
    final secure = value['wss_addr'] as String? ?? '';
    final address = secure.isNotEmpty
        ? secure
        : value['ws_addr'] as String? ?? '';
    if (!address.startsWith('ws://') && !address.startsWith('wss://')) {
      throw const StreamFailure();
    }
    return address;
  }

  void close() => _client.close();
}

class ModelConfig {
  final String url, model, key;
  const ModelConfig({required this.url, required this.model, this.key = ''});
  @override
  String toString() => 'ModelConfig(<redacted>)';
}

/// Incremental SSE parser; limits apply before decoding and JSON allocation.
class StreamModel {
  final _client = http.Client();
  void cancel() => _client.close();
  Future<void> consume(
    ModelConfig config,
    List<Map<String, String>> context,
    Future<void> Function(String) emit,
  ) async {
    var url = _address(config.url);
    if (!url.path.endsWith('/chat/completions')) {
      url = url.replace(
        path: '${url.path.replaceFirst(RegExp(r'/$'), '')}/chat/completions',
      );
    }
    if (config.model.trim().isEmpty) throw const StreamFailure();
    final request = http.Request('POST', url)
      ..followRedirects = false
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        if (config.key.isNotEmpty) 'Authorization': 'Bearer ${config.key}',
      })
      ..body = jsonEncode({
        'model': config.model,
        'messages': context,
        'stream': true,
      });
    if (utf8.encode(request.body).length > 131072) throw const StreamFailure();
    final deadline = Timer(const Duration(seconds: 180), cancel);
    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').contains(
            'text/event-stream',
          )) {
        throw const StreamFailure();
      }
      var total = 0, eventSize = 0, textSize = 0;
      final line = <int>[], event = <String>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        total += chunk.length;
        if (total > 4 * 1024 * 1024) throw const StreamFailure();
        for (final byte in chunk) {
          if (byte != 10) {
            if (line.length == 65536) throw const StreamFailure();
            line.add(byte);
            continue;
          }
          if (line.isNotEmpty && line.last == 13) line.removeLast();
          final value = utf8.decode(line);
          line.clear();
          if (value.isEmpty && event.isNotEmpty) {
            final data = event.join('\n');
            event.clear();
            eventSize = 0;
            if (data == '[DONE]') return;
            final object = jsonDecode(data) as Map<String, dynamic>;
            if (object['error'] != null) throw const StreamFailure();
            for (final choice in object['choices'] as List? ?? []) {
              if (choice['index'] != 0) continue;
              final delta = choice['delta']?['content'];
              if (delta is String && delta.isNotEmpty) {
                textSize += delta.length;
                if (textSize > 16384) throw const StreamFailure();
                await emit(delta);
              }
            }
          } else if (value.startsWith('data:')) {
            var data = value.substring(5);
            if (data.startsWith(' ')) data = data.substring(1);
            eventSize += utf8.encode(data).length + 1;
            if (eventSize > 65536) throw const StreamFailure();
            event.add(data);
          }
        }
      }
      throw const StreamFailure(); // EOF without DONE is incomplete.
    } finally {
      deadline.cancel();
      cancel();
    }
  }
}
