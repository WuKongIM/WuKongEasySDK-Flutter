import 'dart:convert';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';

class StreamRow {
  final String key;
  int sequence = 0;
  bool user = false, finished = false;
  String text = '', status = '生成中';
  final seen = <String>{};
  StreamRow(this.key);
}

/// Bounded disposable projection; history is authoritative at each recovery.
class StreamTimeline {
  final String channel;
  final _entries = <String, StreamRow>{};
  StreamTimeline(this.channel);
  List<StreamRow> get rows => _entries.values.toList()
    ..sort((a, b) {
      final left = a.sequence > 0 ? a.sequence : 1 << 62;
      final right = b.sequence > 0 ? b.sequence : 1 << 62;
      return left == right ? a.key.compareTo(b.key) : left.compareTo(right);
    });
  void receive(Message message) {
    final key = message.clientMsgNo;
    if (message.channelId != channel ||
        message.channelType != WuKongChannelType.group ||
        key == null ||
        key.isEmpty) {
      return;
    }
    final row = _entries[key] ?? StreamRow(key);
    row.sequence = message.messageSeq;
    row.user = message.setting?.stream != true;
    if (row.user) {
      row.text = _textPayload(message.payload);
      row.status = '已发送';
      row.finished = true;
    }
    _save(row);
  }

  /// Merge byte offsets only at complete UTF-8 scalar boundaries; reject gaps.
  void apply(EventNotification event) {
    const kinds = [
      'stream.open',
      'stream.delta',
      'stream.snapshot',
      'stream.close',
      'stream.cancel',
      'stream.error',
      'stream.finish',
    ];
    final data = event.data;
    if (!kinds.contains(event.type) ||
        data is! Map ||
        data['channel_id'] != channel ||
        data['channel_type'] != 2 ||
        (data['event_key'] != 'main' && event.type != 'stream.finish') ||
        data['client_msg_no'] is! String ||
        event.id.isEmpty) {
      return;
    }
    final key = data['client_msg_no'] as String;
    if (key.isEmpty) return;
    final row = _entries[key] ?? StreamRow(key);
    if (_number(data['message_seq']) > 0) {
      row.sequence = _number(data['message_seq']);
    }
    if (row.seen.contains(event.id) ||
        (row.finished && event.type != 'stream.finish')) {
      return;
    }
    if (row.seen.length == 2048) row.seen.clear();
    row.seen.add(event.id);
    final payload = data['payload'] is Map ? data['payload'] as Map : {};
    if (event.type == 'stream.delta' && payload['delta'] is String) {
      final delta = utf8.encode(payload['delta'] as String),
          current = utf8.encode(row.text).length;
      final offset = data['text_offset'] as int? ?? current;
      if (offset < 0 || offset > current) {
        row.status = '增量中断，等待快照';
      } else if (offset + delta.length > current) {
        try {
          row.text += utf8.decode(delta.sublist(current - offset));
        } on FormatException {
          row.status = '增量中断，等待快照';
        }
      }
    }
    if ([
      'stream.snapshot',
      'stream.close',
      'stream.cancel',
      'stream.error',
      'stream.finish',
    ].contains(event.type)) {
      final snapshot = payload['snapshot'] is Map
          ? payload['snapshot'] as Map
          : payload;
      if (snapshot['kind'] == 'text' && snapshot['text'] is String) {
        row.text = snapshot['text'] as String;
        if (row.status == '增量中断，等待快照') row.status = '生成中';
      }
    }
    switch (event.type) {
      case 'stream.cancel':
        row.status = '已取消';
        row.finished = true;
      case 'stream.error':
        row.status = '失败';
        row.finished = true;
      case 'stream.close':
      case 'stream.finish':
        if (!['已取消', '失败'].contains(row.status)) row.status = '完成';
        row.finished = true;
    }
    _save(row);
  }

  void restore(Map<String, dynamic> history) {
    _entries.clear();
    final messages = history['messages'] as List? ?? [];
    for (final message in messages.skip(
      messages.length > 40 ? messages.length - 40 : 0,
    )) {
      final key = message['client_msg_no'];
      if (key is! String || key.isEmpty) continue;
      final row = StreamRow(key)..sequence = _number(message['message_seq']);
      row.user = ((message['setting'] as int? ?? 0) & 2) == 0;
      if (row.user) {
        row.text = _textPayload(message['payload']);
        row.status = '已发送';
        row.finished = true;
      } else {
        final meta = message['event_meta'] as Map? ?? {};
        final lanes = (meta['events'] as List? ?? []).where(
          (e) => e['event_key'] == 'main',
        );
        final lane = lanes.isEmpty ? {} : lanes.first as Map;
        final snapshot = lane['snapshot'] as Map? ?? {};
        if (snapshot['kind'] == 'text') {
          row.text = snapshot['text'] as String? ?? '';
        }
        row.status = switch (lane['status']) {
          'cancelled' => '已取消',
          'error' => '失败',
          'closed' => '完成',
          _ => meta['completed'] == true ? '完成' : '生成中',
        };
        row.finished = row.status != '生成中';
      }
      _save(row);
    }
  }

  List<Map<String, String>> context() {
    var used = 0;
    return rows
        .where((r) => r.user || r.status == '完成')
        .toList()
        .reversed
        .take(39)
        .where((r) {
          used += r.text.length;
          return used <= 24000;
        })
        .toList()
        .reversed
        .map((r) => {'role': r.user ? 'user' : 'assistant', 'content': r.text})
        .toList();
  }

  void _save(StreamRow row) {
    if (row.text.length > 16384) {
      row.text = boundedText(row.text, 16384);
      row.status = '回复超出演示上限';
      row.finished = true;
    }
    _entries[row.key] = row;
    while (_entries.length > 40) {
      _entries.remove(rows.first.key);
    }
  }
}

String boundedText(String text, int limit) {
  var count = 0;
  return String.fromCharCodes(
    text.runes.takeWhile((rune) {
      count += rune > 0xffff ? 2 : 1;
      return count <= limit;
    }),
  );
}

String _textPayload(dynamic value) {
  if (value is Map) return value['content'] as String? ?? '';
  if (value is! String) return '';
  for (final decode in [
    () => jsonDecode(value),
    () => jsonDecode(utf8.decode(base64Decode(value))),
  ]) {
    try {
      final object = decode();
      if (object is Map) return object['content'] as String? ?? '';
    } catch (_) {
      /* Try the other wire representation. */
    }
  }
  return value;
}

int _number(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? "") ?? 0;
