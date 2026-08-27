import 'package:flutter_test/flutter_test.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';

void main() {
  test('device flags match the WuKongIM protocol', () {
    expect(WuKongDeviceFlag.app.value, equals(0));
    expect(WuKongDeviceFlag.web.value, equals(1));
    expect(WuKongDeviceFlag.pc.value, equals(2));
    expect(WuKongDeviceFlag.fromValue(0), equals(WuKongDeviceFlag.app));
    expect(WuKongDeviceFlag.fromValue(1), equals(WuKongDeviceFlag.web));
    expect(WuKongDeviceFlag.fromValue(2), equals(WuKongDeviceFlag.pc));
  });

  test('default configuration authenticates as APP', () {
    final config = WuKongConfig(
      serverUrl: 'ws://localhost:5200',
      uid: 'test-user',
      token: 'test-token',
    );

    expect(config.deviceFlag, equals(WuKongDeviceFlag.app));
    expect(config.toAuthParams()['deviceFlag'], equals(0));
  });
}
