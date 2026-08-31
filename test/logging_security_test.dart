import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';

void main() {
  test('shipped examples do not log protocol or application data', () {
    final exampleSource = File('example/lib/main.dart').readAsStringSync();
    final publicApiSource =
        File('lib/src/core/wukong_easy_sdk.dart').readAsStringSync();

    const unsafeExampleDiagnostics = [
      r'Reason: ${result.reasonCode}',
      r'Reason: ${info.reason}',
      r'${message.fromUid}',
      r'${jsonEncode(message.payload)}',
      r'${error.message}',
      r'Connecting to ${_serverUrlController.text}',
      r'Connection failed: $e',
      r'Sending message to ${_targetUserIdController.text}',
      r'ID: ${result.messageId}',
      r'Send message failed: $e',
    ];

    for (final diagnostic in unsafeExampleDiagnostics) {
      expect(
        exampleSource,
        isNot(contains(diagnostic)),
        reason: 'example logs sensitive diagnostic: $diagnostic',
      );
    }
    expect(
      publicApiSource,
      isNot(contains(r'print("Connected: $result")')),
      reason: 'public API documentation logs the complete ConnectResult',
    );
  });

  test('public string representations redact application and protocol data',
      () {
    const secret = 'STRING-CANARY-7f0a19c2';
    final values = <Object>[
      const WuKongConfig(
        serverUrl: 'wss://$secret.example.test',
        uid: 'uid-$secret',
        token: 'token-$secret',
        deviceId: 'device-$secret',
      ),
      const MessagePayload(
        type: 1,
        content: 'content-$secret',
        data: {'secret': secret},
      ),
      const Message(
        header: MessageHeader(),
        messageId: 'message-$secret',
        messageSeq: 42,
        timestamp: 1,
        channelId: 'channel-$secret',
        channelType: WuKongChannelType.person,
        fromUid: 'sender-$secret',
        payload: {'content': secret},
      ),
      const DisconnectInfo(code: 4000, reason: 'reason-$secret'),
      const EventNotification(
        id: 'event-$secret',
        type: 'type-$secret',
        timestamp: 1,
        data: {'secret': secret},
      ),
      const WuKongError(
        code: WuKongErrorCode.unknown,
        message: 'error-$secret',
        data: {'secret': secret},
      ),
      const SendResult(
        messageId: 'ack-$secret',
        messageSeq: 43,
        reasonCode: WuKongReasonCode(1),
      ),
      const WuKongNotConnectedException('not-connected-$secret'),
      const WuKongInvalidChannelException(
          'channel-$secret', 'invalid-channel-$secret'),
      const WuKongMessageTooLargeException(
          123, 100, 'message-too-large-$secret'),
      const WuKongAuthenticationException('auth-$secret'),
      const WuKongConnectionTimeoutException('timeout-$secret'),
      const WuKongNetworkException('network-$secret'),
      const WuKongConfigurationException('config-$secret'),
      const WuKongProtocolException('protocol-$secret'),
    ];

    final rendered = values.map((value) => '$value').join('\n');
    expect(rendered, isNot(contains(secret)));
    expect(rendered, contains('messageSeq: 42'));
    expect(rendered, contains('code: 4000'));
  });

  test('debug logging disabled emits no SDK logs', () async {
    final logs = <String>[];
    final sdk = WuKongEasySDK.getInstance();
    addTearDown(sdk.dispose);

    await sdk.init(
      WuKongConfig(
        serverUrl: 'ws://127.0.0.1:5200',
        uid: 'logging-disabled-user',
        token: 'TOKEN-CANARY-DISABLED',
        debugLogging: false,
        logHandler: logs.add,
      ),
    );
    sdk.addEventListener<ConnectResult>(WuKongEvent.connect, (_) {});
    sdk.clearAllEventListeners();
    sdk.dispose();

    expect(logs, isEmpty);
  });

  test('application log handler failures do not interrupt SDK operations',
      () async {
    final sdk = WuKongEasySDK.getInstance();
    addTearDown(sdk.dispose);

    await sdk.init(
      WuKongConfig(
        serverUrl: 'ws://127.0.0.1:5200',
        uid: 'throwing-log-handler-user',
        token: 'TOKEN-CANARY-THROWING-HANDLER',
        debugLogging: true,
        logHandler: (_) => throw StateError('application logger failed'),
      ),
    );

    expect(sdk.isInitialized, isTrue);
  });

  test('enabled diagnostics redact authentication and message content',
      () async {
    const uidCanary = 'UID-CANARY-ENABLED';
    const tokenCanary = 'TOKEN-CANARY-ENABLED';
    const outboundCanary = 'PAYLOAD-CANARY-OUTBOUND';
    const inboundCanary = 'PAYLOAD-CANARY-INBOUND';
    const parserCanary = 'PARSER-CANARY-INBOUND';
    const responseIdCanary = 'RESPONSE-ID-CANARY-INBOUND';
    const notificationMethodCanary = 'NOTIFICATION-METHOD-CANARY-INBOUND';
    const serverMessageIdCanary = 'MESSAGE-ID-CANARY-INBOUND';
    final outboundPayload = {'type': 1, 'content': outboundCanary};
    final encodedPayload =
        base64Encode(utf8.encode(jsonEncode(outboundPayload)));
    final logs = <String>[];
    final errors = <WuKongError>[];
    final outboundRequestIds = <String>[];
    final inboundMessagesProcessed = Completer<void>();
    final sockets = <WebSocket>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final serverDone =
        server.transform(WebSocketTransformer()).listen((socket) {
      sockets.add(socket);
      socket.listen((data) {
        final request = jsonDecode(data as String) as Map<String, dynamic>;
        if (request['id'] case final String requestId) {
          outboundRequestIds.add(requestId);
        }
        switch (request['method']) {
          case 'connect':
            socket.add(jsonEncode({
              'jsonrpc': '2.0',
              'id': request['id'],
              'result': {
                'timeDiff': 0,
                'reasonCode': 1,
                'serverVersion': 4,
                'nodeId': 1,
              },
            }));
            break;
          case 'send':
            socket.add(jsonEncode({
              'jsonrpc': '2.0',
              'id': request['id'],
              'result': {
                'messageId': serverMessageIdCanary,
                'messageSeq': 1,
                'reasonCode': 1,
              },
            }));
            break;
        }
      });
    });
    addTearDown(() async {
      for (final socket in sockets) {
        await socket.close();
      }
      await serverDone.cancel();
      await server.close(force: true);
    });

    final sdk = WuKongEasySDK.getInstance();
    addTearDown(sdk.dispose);
    await sdk.init(
      WuKongConfig(
        serverUrl: 'ws://${server.address.address}:${server.port}',
        uid: uidCanary,
        token: tokenCanary,
        debugLogging: true,
        logHandler: (message) {
          logs.add(message);
          if (message.startsWith('Unknown notification method') &&
              !inboundMessagesProcessed.isCompleted) {
            inboundMessagesProcessed.complete();
          }
        },
      ),
    );
    sdk.addEventListener<WuKongError>(WuKongEvent.error, errors.add);
    await sdk.connect();
    await sdk.send(
      channelId: 'bob',
      channelType: WuKongChannelType.person,
      payload: outboundPayload,
    );

    sockets.single
      ..add(jsonEncode({'unexpected': inboundCanary}))
      ..add('{"payload":"$parserCanary"')
      ..add(jsonEncode({
        'jsonrpc': '2.0',
        'id': responseIdCanary,
        'result': <String, dynamic>{},
      }))
      ..add(jsonEncode({
        'jsonrpc': '2.0',
        'method': notificationMethodCanary,
        'params': <String, dynamic>{},
      }));
    await inboundMessagesProcessed.future.timeout(const Duration(seconds: 5));
    sdk.disconnect();

    final output = logs.join('\n');
    final reportedErrors = errors.map((error) => error.message).join('\n');
    expect(errors, isNotEmpty);
    expect(output, contains('method=connect'));
    expect(output, contains('method=unknown'));
    expect(outboundRequestIds, isNotEmpty);
    for (final secret in [
      uidCanary,
      tokenCanary,
      outboundCanary,
      encodedPayload,
      inboundCanary,
      parserCanary,
      responseIdCanary,
      notificationMethodCanary,
      serverMessageIdCanary,
      ...outboundRequestIds,
    ]) {
      expect(output, isNot(contains(secret)), reason: 'leaked $secret');
      expect(
        reportedErrors,
        isNot(contains(secret)),
        reason: 'reported error leaked $secret',
      );
    }
  });
}
