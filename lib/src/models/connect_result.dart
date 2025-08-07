/// Result of a successful connection and authentication
///
/// Contains information returned by the server after successful authentication.
class ConnectResult {
  /// Server key for encryption (optional, may not be provided by all servers)
  final String? serverKey;

  /// Salt for encryption (optional, may not be provided by all servers)
  final String? salt;

  /// Time difference between client and server
  final int timeDiff;

  /// Reason code for the connection
  final int reasonCode;

  /// Optional server version
  final int? serverVersion;

  /// Optional node ID
  final int? nodeId;

  /// Creates a new connect result
  const ConnectResult({
    this.serverKey,
    this.salt,
    required this.timeDiff,
    required this.reasonCode,
    this.serverVersion,
    this.nodeId,
  });
  
  /// Creates a ConnectResult from JSON
  factory ConnectResult.fromJson(Map<String, dynamic> json) {
    return ConnectResult(
      serverKey: json['serverKey'] as String?,
      salt: json['salt'] as String?,
      timeDiff: json['timeDiff'] as int,
      reasonCode: json['reasonCode'] as int,
      serverVersion: json['serverVersion'] as int?,
      nodeId: json['nodeId'] as int?,
    );
  }
  
  /// Converts ConnectResult to JSON
  Map<String, dynamic> toJson() {
    return {
      if (serverKey != null) 'serverKey': serverKey,
      if (salt != null) 'salt': salt,
      'timeDiff': timeDiff,
      'reasonCode': reasonCode,
      if (serverVersion != null) 'serverVersion': serverVersion,
      if (nodeId != null) 'nodeId': nodeId,
    };
  }

  @override
  String toString() {
    return 'ConnectResult(reasonCode: $reasonCode, timeDiff: $timeDiff, serverVersion: $serverVersion, nodeId: $nodeId)';
  }
}
