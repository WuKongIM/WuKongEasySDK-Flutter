import 'message.dart';

/// Event Notification Interface
/// Represents a custom event notification from the server
class EventNotification {
  /// Optional header with message flags
  final MessageHeader? header;

  /// Unique event identifier
  final String id;

  /// Event type/category
  final String type;

  /// Event timestamp (milliseconds)
  final int timestamp;

  /// Event data payload (dynamic)
  final dynamic data;

  /// Creates a new event notification
  const EventNotification({
    this.header,
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  /// Creates an EventNotification from JSON
  factory EventNotification.fromJson(Map<String, dynamic> json) {
    return EventNotification(
      header: json['header'] != null
          ? MessageHeader.fromJson(json['header'] as Map<String, dynamic>)
          : null,
      id: json['id'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] as int,
      data: json['data'],
    );
  }

  /// Converts EventNotification to JSON
  Map<String, dynamic> toJson() {
    return {
      if (header != null) 'header': header!.toJson(),
      'id': id,
      'type': type,
      'timestamp': timestamp,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'EventNotification(id: $id, type: $type, timestamp: $timestamp)';
  }
}

