import '../enums/wukong_error_code.dart';

/// WuKong SDK Error
///
/// Represents an error that occurred in the WuKong SDK.
class WuKongError {
  /// Error code
  final WuKongErrorCode code;

  /// Error message
  final String message;

  /// Additional error data
  final dynamic data;

  /// Creates a new WuKong error
  const WuKongError({
    required this.code,
    required this.message,
    this.data,
  });

  /// Creates a WuKongError from JSON
  factory WuKongError.fromJson(Map<String, dynamic> json) {
    return WuKongError(
      code: _parseErrorCode(json['code']),
      message: json['message'] as String? ?? 'Unknown error',
      data: json['data'],
    );
  }

  /// Creates a WuKongError from an exception
  factory WuKongError.fromException(Exception exception,
      {WuKongErrorCode? code}) {
    return WuKongError(
      code: code ?? WuKongErrorCode.unknown,
      message: exception.toString(),
    );
  }

  /// Creates a network error
  factory WuKongError.networkError(String message) {
    return WuKongError(
      code: WuKongErrorCode.networkError,
      message: message,
    );
  }

  /// Creates an authentication error
  factory WuKongError.authError(String message) {
    return WuKongError(
      code: WuKongErrorCode.authFailed,
      message: message,
    );
  }

  /// Creates a connection timeout error
  factory WuKongError.timeoutError(String message) {
    return WuKongError(
      code: WuKongErrorCode.connectionTimeout,
      message: message,
    );
  }

  /// Converts WuKongError to JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code.name,
      'message': message,
      if (data != null) 'data': data,
    };
  }

  static WuKongErrorCode _parseErrorCode(dynamic code) {
    if (code is String) {
      try {
        return WuKongErrorCode.values.firstWhere((e) => e.name == code);
      } catch (_) {
        return WuKongErrorCode.unknown;
      }
    } else if (code is int) {
      // Map common error codes
      switch (code) {
        case 401:
          return WuKongErrorCode.authFailed;
        case 404:
          return WuKongErrorCode.invalidChannel;
        case 413:
          return WuKongErrorCode.messageTooLarge;
        case 408:
          return WuKongErrorCode.connectionTimeout;
        default:
          return WuKongErrorCode.unknown;
      }
    }
    return WuKongErrorCode.unknown;
  }

  @override
  String toString() {
    return 'WuKongError(code: $code, message: $message)';
  }
}
