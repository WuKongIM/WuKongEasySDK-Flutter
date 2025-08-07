/// WuKong Error Code Enum
/// 
/// Defines the different types of errors that can occur in the WuKong SDK.
enum WuKongErrorCode {
  /// Authentication failed
  authFailed,
  
  /// Network error
  networkError,
  
  /// Connection timeout
  connectionTimeout,
  
  /// Invalid channel
  invalidChannel,
  
  /// Message too large
  messageTooLarge,
  
  /// Not connected
  notConnected,
  
  /// Invalid configuration
  invalidConfig,
  
  /// Protocol error
  protocolError,
  
  /// Unknown error
  unknown,
}
