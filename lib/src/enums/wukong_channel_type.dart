/// WuKong Channel Type Enum based on WuKongIM protocol
///
/// Defines the different types of channels supported by WuKongIM.
class WuKongChannelType {
  /// The numeric value of the channel type
  final int value;

  const WuKongChannelType(this.value);

  /// Person channel (1-on-1 chat)
  static const WuKongChannelType person = WuKongChannelType(1);

  /// Group channel (group chat)
  static const WuKongChannelType group = WuKongChannelType(2);

  /// Customer Service channel (Consider using visitors channel instead)
  static const WuKongChannelType customerService = WuKongChannelType(3);

  /// Community channel
  static const WuKongChannelType community = WuKongChannelType(4);

  /// Community Topic channel
  static const WuKongChannelType communityTopic = WuKongChannelType(5);

  /// Info channel (with concept of temporary subscribers)
  static const WuKongChannelType info = WuKongChannelType(6);

  /// Data channel
  static const WuKongChannelType data = WuKongChannelType(7);

  /// Temporary channel
  static const WuKongChannelType temp = WuKongChannelType(8);

  /// Live channel (does not save recent session data)
  static const WuKongChannelType live = WuKongChannelType(9);

  /// Visitors channel (replaces customerService for new implementations)
  static const WuKongChannelType visitors = WuKongChannelType(10);

  /// All predefined channel types
  static const List<WuKongChannelType> values = [
    person,
    group,
    customerService,
    community,
    communityTopic,
    info,
    data,
    temp,
    live,
    visitors,
  ];

  /// Get channel type from numeric value
  static WuKongChannelType fromValue(int value) {
    for (final type in values) {
      if (type.value == value) {
        return type;
      }
    }
    return WuKongChannelType(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WuKongChannelType &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    switch (value) {
      case 1:
        return 'WuKongChannelType.person';
      case 2:
        return 'WuKongChannelType.group';
      case 3:
        return 'WuKongChannelType.customerService';
      case 4:
        return 'WuKongChannelType.community';
      case 5:
        return 'WuKongChannelType.communityTopic';
      case 6:
        return 'WuKongChannelType.info';
      case 7:
        return 'WuKongChannelType.data';
      case 8:
        return 'WuKongChannelType.temp';
      case 9:
        return 'WuKongChannelType.live';
      case 10:
        return 'WuKongChannelType.visitors';
      default:
        return 'WuKongChannelType.custom($value)';
    }
  }
}
