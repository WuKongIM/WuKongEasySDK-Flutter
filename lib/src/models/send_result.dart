import '../enums/wukong_reason_code.dart';

/// Result of sending a message
///
/// Contains information returned by the server after sending a message.
class SendResult {
  /// Unique message ID assigned by the server
  final String messageId;

  /// Message sequence number assigned by the server
  final int messageSeq;

  /// Reason code indicating the result of the send operation
  final WuKongReasonCode reasonCode;

  /// Creates a new send result
  const SendResult({
    required this.messageId,
    required this.messageSeq,
    required this.reasonCode,
  });

  /// Creates a SendResult from JSON
  factory SendResult.fromJson(Map<String, dynamic> json) {
    return SendResult(
      messageId: json['messageId'] as String,
      messageSeq: json['messageSeq'] as int,
      reasonCode: WuKongReasonCode(json['reasonCode'] as int? ?? 0),
    );
  }

  /// Converts SendResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'messageSeq': messageSeq,
      'reasonCode': reasonCode.value,
    };
  }

  @override
  String toString() {
    return 'SendResult(messageId: $messageId, messageSeq: $messageSeq, reasonCode: $reasonCode)';
  }
}
