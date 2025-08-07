/// Message payload for sending messages
/// 
/// Contains the business-defined payload for messages.
class MessagePayload {
  /// Message type (business-defined)
  final int type;
  
  /// Message content
  final String content;
  
  /// Additional data (optional)
  final Map<String, dynamic>? data;
  
  /// Creates a new message payload
  const MessagePayload({
    required this.type,
    required this.content,
    this.data,
  });
  
  /// Creates a MessagePayload from JSON
  factory MessagePayload.fromJson(Map<String, dynamic> json) {
    return MessagePayload(
      type: json['type'] as int,
      content: json['content'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
  
  /// Converts MessagePayload to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      if (data != null) 'data': data,
    };
  }
  
  @override
  String toString() {
    return 'MessagePayload(type: $type, content: $content)';
  }
}
