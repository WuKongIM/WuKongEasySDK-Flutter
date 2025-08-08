/// JSON-RPC request
///
/// Represents a JSON-RPC 2.0 request message.
class JsonRpcRequest {
  /// JSON-RPC version (always "2.0")
  final String jsonrpc = '2.0';

  /// Method name
  final String method;

  /// Request parameters
  final dynamic params;

  /// Request ID
  final String id;

  /// Creates a new JSON-RPC request
  const JsonRpcRequest({
    required this.method,
    required this.params,
    required this.id,
  });

  /// Converts request to JSON
  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'params': params,
      'id': id,
    };
  }

  @override
  String toString() {
    return 'JsonRpcRequest(method: $method, id: $id)';
  }
}

/// JSON-RPC response
///
/// Represents a JSON-RPC 2.0 response message.
class JsonRpcResponse {
  /// JSON-RPC version (always "2.0")
  final String jsonrpc = '2.0';

  /// Response result (null if error)
  final dynamic result;

  /// Response error (null if success)
  final JsonRpcError? error;

  /// Request ID this response corresponds to
  final String id;

  /// Creates a new JSON-RPC response
  const JsonRpcResponse({
    this.result,
    this.error,
    required this.id,
  });

  /// Creates a JsonRpcResponse from JSON
  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    return JsonRpcResponse(
      result: json['result'],
      error:
          json['error'] != null ? JsonRpcError.fromJson(json['error']) : null,
      id: json['id'] as String,
    );
  }

  /// Whether this response indicates success
  bool get isSuccess => error == null;

  /// Whether this response indicates an error
  bool get isError => error != null;

  @override
  String toString() {
    return 'JsonRpcResponse(id: $id, success: $isSuccess)';
  }
}

/// JSON-RPC notification
///
/// Represents a JSON-RPC 2.0 notification message (no response expected).
class JsonRpcNotification {
  /// JSON-RPC version (always "2.0")
  final String jsonrpc = '2.0';

  /// Method name
  final String method;

  /// Notification parameters
  final dynamic params;

  /// Creates a new JSON-RPC notification
  const JsonRpcNotification({
    required this.method,
    required this.params,
  });

  /// Creates a JsonRpcNotification from JSON
  factory JsonRpcNotification.fromJson(Map<String, dynamic> json) {
    return JsonRpcNotification(
      method: json['method'] as String,
      params: json['params'],
    );
  }

  /// Converts notification to JSON
  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'params': params,
    };
  }

  @override
  String toString() {
    return 'JsonRpcNotification(method: $method)';
  }
}

/// JSON-RPC error
///
/// Represents an error in a JSON-RPC response.
class JsonRpcError {
  /// Error code
  final int code;

  /// Error message
  final String message;

  /// Additional error data
  final dynamic data;

  /// Creates a new JSON-RPC error
  const JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  /// Creates a JsonRpcError from JSON
  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    return JsonRpcError(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'],
    );
  }

  /// Converts error to JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      if (data != null) 'data': data,
    };
  }

  @override
  String toString() {
    return 'JsonRpcError(code: $code, message: $message)';
  }
}

/// Pending JSON-RPC request
///
/// Represents a request that is waiting for a response.
class PendingRequest {
  /// Completer for the request
  final Function(dynamic) resolve;

  /// Completer for errors
  final Function(dynamic) reject;

  /// Timeout timer
  final dynamic timeoutTimer;

  /// Creates a new pending request
  const PendingRequest({
    required this.resolve,
    required this.reject,
    required this.timeoutTimer,
  });
}
