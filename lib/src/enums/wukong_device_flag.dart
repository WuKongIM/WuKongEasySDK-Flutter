/// WuKong Device Flag Enum
///
/// Defines the different device types for WuKongIM authentication.
enum WuKongDeviceFlag {
  /// APP client (WuKongIM protocol value: 0)
  app(0),

  /// Web client (WuKongIM protocol value: 1)
  web(1),

  /// PC / desktop client (WuKongIM protocol value: 2)
  pc(2);

  const WuKongDeviceFlag(this.value);

  /// The numeric value of the device flag
  final int value;

  /// Get device flag from numeric value
  static WuKongDeviceFlag fromValue(int value) {
    return WuKongDeviceFlag.values.firstWhere(
      (flag) => flag.value == value,
      orElse: () => throw ArgumentError('Invalid device flag value: $value'),
    );
  }
}
