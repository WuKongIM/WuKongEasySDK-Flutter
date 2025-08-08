/// WuKong Channel Type Enum based on WuKongIM protocol
///
/// Defines the different types of channels supported by WuKongIM.
enum WuKongChannelType {
  /// Person channel (1-on-1 chat)
  person(1),

  /// Group channel (group chat)
  group(2),

  /// Customer Service channel (Consider using visitors channel instead)
  customerService(3),

  /// Community channel
  community(4),

  /// Community Topic channel
  communityTopic(5),

  /// Info channel (with concept of temporary subscribers)
  info(6),

  /// Data channel
  data(7),

  /// Temporary channel
  temp(8),

  /// Live channel (does not save recent session data)
  live(9),

  /// Visitors channel (replaces customerService for new implementations)
  visitors(10);

  const WuKongChannelType(this.value);

  /// The numeric value of the channel type
  final int value;

  /// Get channel type from numeric value
  static WuKongChannelType fromValue(int value) {
    return WuKongChannelType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid channel type value: $value'),
    );
  }
}
