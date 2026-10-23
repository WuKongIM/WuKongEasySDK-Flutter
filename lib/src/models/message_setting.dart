/// Protocol settings for a persisted stream parent message.
class MessageSetting {
  /// Marks a parent whose text is projected from subsequent stream events.
  final bool stream;
  const MessageSetting({this.stream = false});
  factory MessageSetting.fromJson(Map<String, dynamic> json) =>
      MessageSetting(stream: json['stream'] == true);
  Map<String, dynamic> toJson() => {'stream': stream};
}
