import 'package:flutter_test/flutter_test.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';

void main() {
  test('independent peers retain singleton and isolate disposal', () async {
    final reader = WuKongEasySDK.createInstance();
    final writer = WuKongEasySDK.createInstance();
    final shared = WuKongEasySDK.getInstance();
    addTearDown(reader.dispose);
    addTearDown(writer.dispose);
    addTearDown(shared.dispose);
    for (final sdk in [reader, writer, shared]) {
      await sdk.init(const WuKongConfig(
          serverUrl: 'ws://localhost:5200', uid: 'test', token: 'test'));
      sdk.addEventListener<EventNotification>(WuKongEvent.customEvent, (_) {});
    }
    reader.dispose();
    expect(writer.isInitialized, isTrue);
    expect(writer.getListenerCount(WuKongEvent.customEvent), 1);
    expect(shared.isInitialized, isTrue);
    expect(identical(shared, WuKongEasySDK.getInstance()), isTrue);
  });
  test('typed settings and options serialize without replacing legacy send',
      () {
    expect(const MessageSetting(stream: true).toJson(), {'stream': true});
    expect(MessageSetting.fromJson({}).stream, isFalse);
    expect(
        const SendOptions(
                clientMsgNo: 'parent', setting: MessageSetting(stream: true))
            .toJson(),
        {
          'clientMsgNo': 'parent',
          'setting': {'stream': true}
        });
    final message = Message.fromJson({
      'header': <String, dynamic>{},
      'messageId': '1',
      'messageSeq': 1,
      'timestamp': 0,
      'channelId': 'c',
      'channelType': 2,
      'fromUid': 'w',
      'payload': '',
      'setting': {'stream': true}
    });
    expect(message.setting?.stream, isTrue);
    expect(message.toJson()['setting'], {'stream': true});
  });
  test('event data decodes JSON strings and preserves object and null', () {
    EventNotification event(dynamic data) => EventNotification.fromJson(
        {'id': '1', 'type': 'stream.delta', 'timestamp': 0, 'data': data});
    expect(
        event('{"payload":{"delta":"你好🙂"}}').data['payload']['delta'], '你好🙂');
    expect(event({'text_offset': 4}).data['text_offset'], 4);
    expect(event(null).data, isNull);
    expect(event('plain text').data, 'plain text');
  });
  test('SENDACK accepts reason alias and defaults legacy success to one', () {
    expect(
        SendResult.fromJson({'messageId': '1', 'messageSeq': 1, 'reason': 1})
            .reasonCode
            .value,
        1);
    expect(
        SendResult.fromJson({'messageId': '1', 'messageSeq': 1})
            .reasonCode
            .value,
        1);
    expect(
        SendResult.fromJson(
                {'messageId': '1', 'messageSeq': 1, 'reasonCode': 99})
            .reasonCode
            .value,
        99);
  });
}
