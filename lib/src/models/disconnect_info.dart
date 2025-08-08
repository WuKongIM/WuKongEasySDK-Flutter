/// Information about a disconnection event
///
/// Contains details about why the connection was closed.
class DisconnectInfo {
  /// Disconnect code (WebSocket close code)
  final int code;

  /// Reason for disconnection
  final String reason;

  /// Creates a new disconnect info
  const DisconnectInfo({
    required this.code,
    required this.reason,
  });

  /// Creates a DisconnectInfo from JSON
  factory DisconnectInfo.fromJson(Map<String, dynamic> json) {
    return DisconnectInfo(
      code: json['code'] as int? ?? json['reasonCode'] as int? ?? 0,
      reason: json['reason'] as String? ?? 'Unknown',
    );
  }

  /// Converts DisconnectInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'reason': reason,
    };
  }

  /// Whether this was a normal disconnection
  bool get isNormal => code == 1000;

  /// Whether this was a server-initiated disconnection
  bool get isServerInitiated => code >= 4000;

  @override
  String toString() {
    return 'DisconnectInfo(code: $code, reason: $reason)';
  }
}
