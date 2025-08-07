/// WuKong Device Flag Enum
/// 
/// Defines the different device types for WuKongIM authentication.
enum WuKongDeviceFlag {
  /// Mobile app device
  app(1),
  
  /// Web browser device
  web(2);

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
