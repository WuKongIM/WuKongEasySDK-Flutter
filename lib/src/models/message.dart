import '../enums/wukong_channel_type.dart';

/// Header information for messages
class MessageHeader {
  /// Whether the message should not be persisted
  final bool? noPersist;

  /// Whether the message should show a red dot notification
  final bool? redDot;

  /// Whether the message should be synced only once
  final bool? syncOnce;

  /// Whether this is a duplicate message
  final bool? dup;

  /// Creates a new message header
  const MessageHeader({
    this.noPersist,
    this.redDot,
    this.syncOnce,
    this.dup,
  });

  /// Creates a MessageHeader from JSON
  factory MessageHeader.fromJson(Map<String, dynamic> json) {
    return MessageHeader(
      noPersist: json['noPersist'] as bool?,
      redDot: json['redDot'] as bool?,
      syncOnce: json['syncOnce'] as bool?,
      dup: json['dup'] as bool?,
    );
  }

  /// Converts MessageHeader to JSON
  Map<String, dynamic> toJson() {
    return {
      if (noPersist != null) 'noPersist': noPersist,
      if (redDot != null) 'redDot': redDot,
      if (syncOnce != null) 'syncOnce': syncOnce,
      if (dup != null) 'dup': dup,
    };
  }
}

/// Received message from the server
///
/// Contains all information about a message received from WuKongIM.
class Message {
  /// Message header
  final MessageHeader header;

  /// Unique message ID
  final String messageId;

  /// Message sequence number
  final int messageSeq;

  /// Message timestamp
  final int timestamp;

  /// Channel ID where the message was sent
  final String channelId;

  /// Type of channel
  final WuKongChannelType channelType;

  /// User ID of the sender
  final String fromUid;

  /// Business-defined message payload
  final dynamic payload;

  /// Optional client message number
  final String? clientMsgNo;

  /// Optional stream number
  final String? streamNo;

  /// Optional stream ID
  final String? streamId;

  /// Optional stream flag
  final int? streamFlag;

  /// Optional topic
  final String? topic;

  /// Creates a new message
  const Message({
    required this.header,
    required this.messageId,
    required this.messageSeq,
    required this.timestamp,
    required this.channelId,
    required this.channelType,
    required this.fromUid,
    required this.payload,
    this.clientMsgNo,
    this.streamNo,
    this.streamId,
    this.streamFlag,
    this.topic,
  });

  /// Creates a Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      header: MessageHeader.fromJson(json['header'] as Map<String, dynamic>),
      messageId: json['messageId'] as String,
      messageSeq: json['messageSeq'] as int,
      timestamp: json['timestamp'] as int,
      channelId: json['channelId'] as String,
      channelType: WuKongChannelType.fromValue(json['channelType'] as int),
      fromUid: json['fromUid'] as String,
      payload: json['payload'],
      clientMsgNo: json['clientMsgNo'] as String?,
      streamNo: json['streamNo'] as String?,
      streamId: json['streamId'] as String?,
      streamFlag: json['streamFlag'] as int?,
      topic: json['topic'] as String?,
    );
  }

  /// Converts Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'header': header.toJson(),
      'messageId': messageId,
      'messageSeq': messageSeq,
      'timestamp': timestamp,
      'channelId': channelId,
      'channelType': channelType.value,
      'fromUid': fromUid,
      'payload': payload,
      if (clientMsgNo != null) 'clientMsgNo': clientMsgNo,
      if (streamNo != null) 'streamNo': streamNo,
      if (streamId != null) 'streamId': streamId,
      if (streamFlag != null) 'streamFlag': streamFlag,
      if (topic != null) 'topic': topic,
    };
  }

  /// Gets the message timestamp as DateTime
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() {
    return 'Message(messageId: $messageId, fromUid: $fromUid, channelId: $channelId)';
  }
}
