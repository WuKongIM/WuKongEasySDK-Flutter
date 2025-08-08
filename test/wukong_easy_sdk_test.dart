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

      expect(sdk.getListenerCount(WuKongEvent.connect), equals(1));
      expect(sdk.getListenerCount(WuKongEvent.message), equals(1));
      expect(sdk.getTotalListenerCount(), equals(2));

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

    test('Channel type enum works', () {
      expect(WuKongChannelType.person.value, equals(1));
      expect(WuKongChannelType.group.value, equals(2));
      expect(WuKongChannelType.fromValue(1), equals(WuKongChannelType.person));
      expect(WuKongChannelType.fromValue(2), equals(WuKongChannelType.group));
    });

    test('Device flag enum works', () {
      expect(WuKongDeviceFlag.app.value, equals(1));
      expect(WuKongDeviceFlag.web.value, equals(2));
      expect(WuKongDeviceFlag.fromValue(1), equals(WuKongDeviceFlag.app));
      expect(WuKongDeviceFlag.fromValue(2), equals(WuKongDeviceFlag.web));
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
