/// Base exception class for WuKong SDK
/// 
/// All WuKong-specific exceptions extend from this class.
abstract class WuKongException implements Exception {
  /// Error message
  final String message;
  
  /// Creates a new WuKong exception
  const WuKongException(this.message);
  
  @override
  String toString() => 'WuKongException: $message';
}

/// Exception thrown when trying to perform an operation while not connected
class WuKongNotConnectedException extends WuKongException {
  /// Creates a new not connected exception
  const WuKongNotConnectedException([String? message])
      : super(message ?? 'Not connected to WuKong server. Call connect() first.');
  
  @override
  String toString() => 'WuKongNotConnectedException: $message';
}

/// Exception thrown when trying to send a message to an invalid channel
class WuKongInvalidChannelException extends WuKongException {
  /// Channel ID that was invalid
  final String channelId;
  
  /// Creates a new invalid channel exception
  const WuKongInvalidChannelException(this.channelId, [String? message])
      : super(message ?? 'Invalid channel: $channelId');
  
  @override
  String toString() => 'WuKongInvalidChannelException: $message';
}

/// Exception thrown when trying to send a message that is too large
class WuKongMessageTooLargeException extends WuKongException {
  /// Size of the message that was too large
  final int messageSize;
  
  /// Maximum allowed message size
  final int maxSize;
  
  /// Creates a new message too large exception
  const WuKongMessageTooLargeException(this.messageSize, this.maxSize, [String? message])
      : super(message ?? 'Message size ($messageSize bytes) exceeds maximum allowed size ($maxSize bytes)');
  
  @override
  String toString() => 'WuKongMessageTooLargeException: $message';
}

/// Exception thrown when authentication fails
class WuKongAuthenticationException extends WuKongException {
  /// Creates a new authentication exception
  const WuKongAuthenticationException([String? message])
      : super(message ?? 'Authentication failed. Please check your credentials.');
  
  @override
  String toString() => 'WuKongAuthenticationException: $message';
}

/// Exception thrown when connection times out
class WuKongConnectionTimeoutException extends WuKongException {
  /// Creates a new connection timeout exception
  const WuKongConnectionTimeoutException([String? message])
      : super(message ?? 'Connection timeout. Please check your network connection.');
  
  @override
  String toString() => 'WuKongConnectionTimeoutException: $message';
}

/// Exception thrown when there's a network error
class WuKongNetworkException extends WuKongException {
  /// Creates a new network exception
  const WuKongNetworkException([String? message])
      : super(message ?? 'Network error occurred. Please check your connection.');
  
  @override
  String toString() => 'WuKongNetworkException: $message';
}

/// Exception thrown when the configuration is invalid
class WuKongConfigurationException extends WuKongException {
  /// Creates a new configuration exception
  const WuKongConfigurationException([String? message])
      : super(message ?? 'Invalid configuration provided.');
  
  @override
  String toString() => 'WuKongConfigurationException: $message';
}

/// Exception thrown when there's a protocol error
class WuKongProtocolException extends WuKongException {
  /// Creates a new protocol exception
  const WuKongProtocolException([String? message])
      : super(message ?? 'Protocol error occurred.');
  
  @override
  String toString() => 'WuKongProtocolException: $message';
}
