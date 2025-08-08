/// WuKong SDK Constants
///
/// Defines configuration constants used throughout the SDK.
class WuKongConstants {
  WuKongConstants._(); // Private constructor to prevent instantiation

  /// Default request timeout in milliseconds
  static const int defaultRequestTimeoutMs = 15000;

  /// Connection timeout in milliseconds
  static const int connectTimeoutMs = 5000;

  /// Ping interval in milliseconds
  static const int pingIntervalMs = 25000;

  /// Pong timeout in milliseconds
  static const int pongTimeoutMs = 10000;

  /// Maximum reconnection attempts
  static const int maxReconnectAttempts = 5;

  /// Initial reconnection delay in milliseconds
  static const int initialReconnectDelayMs = 1000;

  /// Default device flag for Flutter apps
  static const int defaultDeviceFlag = 1; // APP

  /// JSON-RPC version
  static const String jsonRpcVersion = '2.0';
}
