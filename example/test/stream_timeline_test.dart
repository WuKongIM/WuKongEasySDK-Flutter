import 'package:flutter_test/flutter_test.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';
import 'package:wukong_easy_sdk_example/stream/stream_timeline.dart';

void main() {
  test('EVENT decimal-string message sequence preserves ordering', () {
    final timeline = StreamTimeline('c');
    timeline.apply(
      const EventNotification(
        id: 'e',
        type: 'stream.delta',
        timestamp: 0,
        data: {
          'channel_id': 'c',
          'channel_type': 2,
          'client_msg_no': 'p',
          'message_seq': '42',
          'event_key': 'main',
          'text_offset': 0,
          'payload': {'delta': '你好🙂'},
        },
      ),
    );
    expect(timeline.rows.single.sequence, 42);
    expect(timeline.rows.single.text, '你好🙂');
  });
  EventNotification event(
    String id,
    String type,
    Map<String, dynamic> payload, {
    int? offset,
  }) => EventNotification(
    id: id,
    type: type,
    timestamp: 0,
    data: {
      'channel_id': 'c',
      'channel_type': 2,
      'client_msg_no': 'p',
      'event_key': 'main',
      'payload': payload,
      if (offset != null) 'text_offset': offset,
    },
  );
  test(
    'UTF8 overlap, duplicate and gap are bounded and recovered by snapshot',
    () {
      final timeline = StreamTimeline('c');
      timeline.apply(event('a', 'stream.delta', {'delta': '你好🙂'}, offset: 0));
      timeline.apply(event('b', 'stream.delta', {'delta': '🙂世界'}, offset: 6));
      timeline.apply(event('b', 'stream.delta', {'delta': '🙂世界'}, offset: 6));
      expect(timeline.rows.single.text, '你好🙂世界');
      timeline.apply(event('g', 'stream.delta', {'delta': 'gap'}, offset: 999));
      expect(timeline.rows.single.text, '你好🙂世界');
      timeline.apply(
        event('s', 'stream.snapshot', {'kind': 'text', 'text': '快照🙂'}),
      );
      expect(timeline.rows.single.text, '快照🙂');
    },
  );
  test('cancel and error stay terminal after stream.finish', () {
    for (final kind in ['cancel', 'error']) {
      final timeline = StreamTimeline('c');
      timeline.apply(
        event('a', 'stream.$kind', {
          'snapshot': {'kind': 'text', 'text': '部分'},
        }),
      );
      timeline.apply(
        event('b', 'stream.finish', {
          'snapshot': {'kind': 'text', 'text': '部分'},
        }),
      );
      timeline.apply(event('c', 'stream.delta', {'delta': 'late'}, offset: 6));
      expect(timeline.rows.single.status, kind == 'cancel' ? '已取消' : '失败');
      expect(timeline.rows.single.text, '部分');
    }
  });
  test('history full restores parent identity and ignores other lanes', () {
    final timeline = StreamTimeline('c');
    timeline.restore({
      'messages': [
        {
          'client_msg_no': 'p',
          'message_seq': 3,
          'setting': 2,
          'event_meta': {
            'completed': true,
            'events': [
              {
                'event_key': 'main',
                'status': 'closed',
                'snapshot': {'kind': 'text', 'text': '恢复🙂'},
              },
            ],
          },
        },
      ],
    });
    timeline.apply(
      event('other', 'stream.delta', {
        'delta': 'bad',
      }, offset: 0).toJson().letEvent(),
    );
    expect(timeline.rows.single.key, 'p');
    expect(timeline.rows.single.text, '恢复🙂');
    expect(timeline.context().single['role'], 'assistant');
  });
  test('timeline keeps at most forty messages', () {
    final timeline = StreamTimeline('c');
    timeline.restore({
      'messages': List.generate(
        70,
        (i) => {
          'client_msg_no': '$i',
          'message_seq': i + 1,
          'setting': 0,
          'payload': {'content': 'q'},
        },
      ),
    });
    expect(timeline.rows.length, 40);
  });
}

extension on Map<String, dynamic> {
  EventNotification letEvent() {
    (this['data'] as Map<String, dynamic>)['event_key'] = 'other';
    return EventNotification.fromJson(this);
  }
}
