import 'package:flutter_test/flutter_test.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';

void main() {
  group('ConnectResult Tests', () {
    test('should parse server response without serverKey and salt', () {
      // This is the actual server response format that was causing the error
      final serverResponse = {
        "serverVersion": 4,
        "timeDiff": 27,
        "reasonCode": 1,
        "nodeId": 1
      };

      // This should not throw an exception
      expect(() {
        final result = ConnectResult.fromJson(serverResponse);
        expect(result.serverVersion, equals(4));
        expect(result.timeDiff, equals(27));
        expect(result.reasonCode, equals(1));
        expect(result.nodeId, equals(1));
        expect(result.serverKey, isNull);
        expect(result.salt, isNull);
      }, returnsNormally);
    });

    test('should parse server response with serverKey and salt', () {
      // This is the expected format from the TypeScript reference
      final serverResponse = {
        "serverKey": "test-server-key",
        "salt": "test-salt",
        "serverVersion": 4,
        "timeDiff": 27,
        "reasonCode": 1,
        "nodeId": 1
      };

      final result = ConnectResult.fromJson(serverResponse);
      expect(result.serverKey, equals("test-server-key"));
      expect(result.salt, equals("test-salt"));
      expect(result.serverVersion, equals(4));
      expect(result.timeDiff, equals(27));
      expect(result.reasonCode, equals(1));
      expect(result.nodeId, equals(1));
    });

    test('should parse minimal server response', () {
      // Minimal required fields
      final serverResponse = {
        "timeDiff": 100,
        "reasonCode": 1
      };

      final result = ConnectResult.fromJson(serverResponse);
      expect(result.timeDiff, equals(100));
      expect(result.reasonCode, equals(1));
      expect(result.serverKey, isNull);
      expect(result.salt, isNull);
      expect(result.serverVersion, isNull);
      expect(result.nodeId, isNull);
    });

    test('should convert to JSON correctly with null values', () {
      final result = ConnectResult(
        timeDiff: 50,
        reasonCode: 1,
        serverVersion: 4,
        nodeId: 1,
        // serverKey and salt are null
      );

      final json = result.toJson();
      expect(json['timeDiff'], equals(50));
      expect(json['reasonCode'], equals(1));
      expect(json['serverVersion'], equals(4));
      expect(json['nodeId'], equals(1));
      expect(json.containsKey('serverKey'), isFalse);
      expect(json.containsKey('salt'), isFalse);
    });

    test('should convert to JSON correctly with all values', () {
      final result = ConnectResult(
        serverKey: "test-key",
        salt: "test-salt",
        timeDiff: 50,
        reasonCode: 1,
        serverVersion: 4,
        nodeId: 1,
      );

      final json = result.toJson();
      expect(json['serverKey'], equals("test-key"));
      expect(json['salt'], equals("test-salt"));
      expect(json['timeDiff'], equals(50));
      expect(json['reasonCode'], equals(1));
      expect(json['serverVersion'], equals(4));
      expect(json['nodeId'], equals(1));
    });

    test('toString should work with null serverKey', () {
      final result = ConnectResult(
        timeDiff: 50,
        reasonCode: 1,
        serverVersion: 4,
        nodeId: 1,
      );

      final stringResult = result.toString();
      expect(stringResult, contains('reasonCode: 1'));
      expect(stringResult, contains('timeDiff: 50'));
      expect(stringResult, contains('serverVersion: 4'));
      expect(stringResult, contains('nodeId: 1'));
    });
  });
}
