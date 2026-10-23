import 'message_setting.dart';

/// Optional SEND fields. Reuse clientMsgNo to correlate the parent and events.
class SendOptions {
  /// Stable application identity for correlation and uncertain-send recovery.
  final String? clientMsgNo;

  /// Persisted stream parent settings, when this send starts a reply.
  final MessageSetting? setting;
  final Map<String, dynamic>? header;
  final String? topic;
  const SendOptions({this.clientMsgNo, this.setting, this.header, this.topic});
  Map<String, dynamic> toJson() => {
        if (clientMsgNo != null) 'clientMsgNo': clientMsgNo,
        if (setting != null) 'setting': setting!.toJson(),
        if (header != null) 'header': header,
        if (topic != null) 'topic': topic,
      };
}
