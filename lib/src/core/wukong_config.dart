import '../enums/wukong_device_flag.dart';

/// Configuration class for WuKong SDK
///
/// Contains all the necessary configuration parameters for initializing the SDK.
class WuKongConfig {
  /// WebSocket server URL (e.g., "ws://your-wukongim-server.com:5200")
  final String serverUrl;

  /// User ID for authentication
  final String uid;

  /// Authentication token
  final String token;

  /// Optional device ID
  final String? deviceId;

  /// Device flag indicating the type of device (defaults to app)
  final WuKongDeviceFlag deviceFlag;

  /// Creates a new WuKong configuration
  const WuKongConfig({
    required this.serverUrl,
    required this.uid,
    required this.token,
    this.deviceId,
    this.deviceFlag = WuKongDeviceFlag.app,
  });

  /// Validates the configuration
  void validate() {
    if (serverUrl.isEmpty) {
      throw ArgumentError('serverUrl cannot be empty');
    }
    if (uid.isEmpty) {
      throw ArgumentError('uid cannot be empty');
    }
    if (token.isEmpty) {
      throw ArgumentError('token cannot be empty');
    }
    if (!serverUrl.startsWith('ws://') && !serverUrl.startsWith('wss://')) {
      throw ArgumentError('serverUrl must start with ws:// or wss://');
    }
  }

  /// Converts configuration to JSON for authentication
  Map<String, dynamic> toAuthParams() {
    return {
      'uid': uid,
      'token': token,
      'deviceId': deviceId,
      'deviceFlag': deviceFlag.value,
      'clientTimestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'WuKongConfig(serverUrl: $serverUrl, uid: $uid, deviceFlag: $deviceFlag)';
  }
}
