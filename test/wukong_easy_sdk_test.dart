import 'package:flutter_test/flutter_test.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';

void main() {
  group('WuKong Easy SDK Tests', () {
    late WuKongEasySDK sdk;

    setUp(() {
      sdk = WuKongEasySDK.getInstance();
    });

    test('SDK singleton pattern works', () {
      final sdk1 = WuKongEasySDK.getInstance();
      final sdk2 = WuKongEasySDK.getInstance();
      expect(sdk1, same(sdk2));
    });

    test('Configuration validation works', () {
      // Valid configuration
      expect(() {
        final config = WuKongConfig(
          serverUrl: 'ws://localhost:5200',
          uid: 'test_user',
          token: 'test_token',
        );
        config.validate();
      }, returnsNormally);

      // Invalid server URL
      expect(() {
        final config = WuKongConfig(
          serverUrl: 'invalid_url',
          uid: 'test_user',
          token: 'test_token',
        );
        config.validate();
      }, throwsArgumentError);

      // Empty UID
      expect(() {
        final config = WuKongConfig(
          serverUrl: 'ws://localhost:5200',
          uid: '',
          token: 'test_token',
        );
        config.validate();
      }, throwsArgumentError);
    });

    test('Event listener management works', () {
      // Add listeners
      void connectListener(ConnectResult result) {
        // Test listener function
      }

      void messageListener(Message message) {
        // Test listener function
      }

      sdk.addEventListener(WuKongEvent.connect, connectListener);
      sdk.addEventListener(WuKongEvent.message, messageListener);
      sdk.addEventListener(WuKongEvent.sendAck, (result) {});
      sdk.addEventListener(WuKongEvent.reconnecting, (info) {});
      sdk.addEventListener(WuKongEvent.customEvent, (event) {});

      expect(sdk.getListenerCount(WuKongEvent.connect), equals(1));
      expect(sdk.getListenerCount(WuKongEvent.message), equals(1));
      expect(sdk.getListenerCount(WuKongEvent.sendAck), equals(1));
      expect(sdk.getListenerCount(WuKongEvent.reconnecting), equals(1));
      expect(sdk.getListenerCount(WuKongEvent.customEvent), equals(1));
      expect(sdk.getTotalListenerCount(), equals(5));

      // Remove listeners
      final removed1 =
          sdk.removeEventListener(WuKongEvent.connect, connectListener);
      final removed2 =
          sdk.removeEventListener(WuKongEvent.message, messageListener);

      expect(removed1, isTrue);
      expect(removed2, isTrue);
      expect(sdk.getListenerCount(WuKongEvent.connect), equals(0));
      expect(sdk.getListenerCount(WuKongEvent.message), equals(0));
    });

    test('Channel type class works', () {
      expect(WuKongChannelType.person.value, equals(1));
      expect(WuKongChannelType.group.value, equals(2));
      expect(WuKongChannelType.fromValue(1), equals(WuKongChannelType.person));
      expect(WuKongChannelType.fromValue(2), equals(WuKongChannelType.group));

      // Test custom channel type
      final customType = WuKongChannelType(100);
      expect(customType.value, equals(100));
      expect(WuKongChannelType.fromValue(100), equals(customType));
      expect(WuKongChannelType.fromValue(100).toString(),
          equals('WuKongChannelType.custom(100)'));
    });

    test('Device flag enum works', () {
      expect(WuKongDeviceFlag.app.value, equals(0));
      expect(WuKongDeviceFlag.web.value, equals(1));
      expect(WuKongDeviceFlag.fromValue(0), equals(WuKongDeviceFlag.app));
      expect(WuKongDeviceFlag.fromValue(1), equals(WuKongDeviceFlag.web));
    });

    test('Reason code enum works', () {
      expect(WuKongReasonCode.success.value, equals(1));
      expect(WuKongReasonCode.authFail.value, equals(2));
      expect(WuKongReasonCode.fromValue(1), equals(WuKongReasonCode.success));
      expect(WuKongReasonCode.fromValue(2), equals(WuKongReasonCode.authFail));
      expect(WuKongReasonCode.fromValue(99), equals(WuKongReasonCode.unknown));
    });

    test('Event notification model works', () {
      final notification = EventNotification(
        id: 'evt_123',
        type: 'test_event',
        timestamp: 123456789,
        data: {'key': 'value'},
      );

      expect(notification.id, equals('evt_123'));
      expect(notification.type, equals('test_event'));
      expect(notification.data['key'], equals('value'));

      final json = notification.toJson();
      final fromJson = EventNotification.fromJson(json);
      expect(fromJson.id, equals(notification.id));
      expect(fromJson.type, equals(notification.type));
    });

    test('Reconnecting info model works', () {
      const info = ReconnectingInfo(attempt: 1, delay: 1000);
      expect(info.attempt, equals(1));
      expect(info.delay, equals(1000));
      expect(info.toString(), contains('attempt: 1'));
    });

    test('Message payload serialization works', () {
      final payload = MessagePayload(
        type: 1,
        content: 'Hello World',
        data: {'key': 'value'},
      );

      final json = payload.toJson();
      expect(json['type'], equals(1));
      expect(json['content'], equals('Hello World'));
      expect(json['data'], equals({'key': 'value'}));

      final fromJson = MessagePayload.fromJson(json);
      expect(fromJson.type, equals(payload.type));
      expect(fromJson.content, equals(payload.content));
      expect(fromJson.data, equals(payload.data));
    });

    test('Error handling works', () {
      final error = WuKongError.networkError('Network failed');
      expect(error.code, equals(WuKongErrorCode.networkError));
      expect(error.message, equals('Network failed'));

      final authError = WuKongError.authError('Auth failed');
      expect(authError.code, equals(WuKongErrorCode.authFailed));
      expect(authError.message, equals('Auth failed'));
    });

    test('Exceptions work correctly', () {
      expect(() => throw const WuKongNotConnectedException(),
          throwsA(isA<WuKongNotConnectedException>()));

      expect(() => throw const WuKongInvalidChannelException('test_channel'),
          throwsA(isA<WuKongInvalidChannelException>()));

      expect(() => throw const WuKongMessageTooLargeException(1000, 500),
          throwsA(isA<WuKongMessageTooLargeException>()));
    });

    test('SDK initialization requires valid config', () async {
      expect(() async {
        await sdk.init(WuKongConfig(
          serverUrl: '',
          uid: 'test',
          token: 'test',
        ));
      }, throwsA(isA<WuKongConfigurationException>()));
    });

    test('Send requires connection', () async {
      final config = WuKongConfig(
        serverUrl: 'ws://localhost:5200',
        uid: 'test_user',
        token: 'test_token',
      );

      await sdk.init(config);

      expect(() async {
        await sdk.send(
          channelId: 'test_channel',
          channelType: WuKongChannelType.person,
          payload: MessagePayload(type: 1, content: 'test'),
        );
      }, throwsA(isA<WuKongNotConnectedException>()));
    });

    tearDown(() {
      sdk.clearAllEventListeners();
      sdk.dispose();
    });
  });
}
