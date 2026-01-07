/// WuKong SDK Event Types
///
/// Defines the different types of events that can be emitted by the WuKong SDK.
enum WuKongEvent {
  /// Connection successfully established and authenticated
  connect,

  /// Disconnected from server
  disconnect,

  /// Received a message
  message,

  /// An error occurred (WebSocket error, connection error, etc.)
  error,

  /// Received acknowledgment for a sent message
  sendAck,

  /// The SDK is attempting to reconnect
  reconnecting,

  /// Received a custom event notification from the server
  customEvent,
}
