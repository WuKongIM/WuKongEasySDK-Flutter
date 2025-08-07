/// Result of sending a message
/// 
/// Contains information returned by the server after successfully sending a message.
class SendResult {
  /// Unique message ID assigned by the server
  final String messageId;
  
  /// Message sequence number assigned by the server
  final int messageSeq;
  
  /// Creates a new send result
  const SendResult({
    required this.messageId,
    required this.messageSeq,
  });
  
  /// Creates a SendResult from JSON
  factory SendResult.fromJson(Map<String, dynamic> json) {
    return SendResult(
      messageId: json['messageId'] as String,
      messageSeq: json['messageSeq'] as int,
    );
  }
  
  /// Converts SendResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'messageSeq': messageSeq,
    };
  }
  
  @override
  String toString() {
    return 'SendResult(messageId: $messageId, messageSeq: $messageSeq)';
  }
}
