/// WuKong Reason Code
///
/// Represents reason codes returned by the server.
/// Known codes have named constants; unknown codes preserve their original value.
class WuKongReasonCode {
  final int value;

  const WuKongReasonCode(this.value);

  static const unknown = WuKongReasonCode(0);
  static const success = WuKongReasonCode(1);
  static const authFail = WuKongReasonCode(2);
  static const subscriberNotExist = WuKongReasonCode(3);
  static const inBlacklist = WuKongReasonCode(4);
  static const channelNotExist = WuKongReasonCode(5);
  static const userNotOnNode = WuKongReasonCode(6);
  static const senderOffline = WuKongReasonCode(7);
  static const msgKeyError = WuKongReasonCode(8);
  static const payloadDecodeError = WuKongReasonCode(9);
  static const forwardSendPacketError = WuKongReasonCode(10);
  static const notAllowSend = WuKongReasonCode(11);
  static const connectKick = WuKongReasonCode(12);
  static const notInWhitelist = WuKongReasonCode(13);
  static const queryTokenError = WuKongReasonCode(14);
  static const systemError = WuKongReasonCode(15);
  static const channelIDError = WuKongReasonCode(16);
  static const nodeMatchError = WuKongReasonCode(17);
  static const nodeNotMatch = WuKongReasonCode(18);
  static const ban = WuKongReasonCode(19);
  static const notSupportHeader = WuKongReasonCode(20);
  static const clientKeyIsEmpty = WuKongReasonCode(21);
  static const rateLimit = WuKongReasonCode(22);
  static const notSupportChannelType = WuKongReasonCode(23);
  static const disband = WuKongReasonCode(24);
  static const sendBan = WuKongReasonCode(25);

  @override
  bool operator ==(Object other) =>
      other is WuKongReasonCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'WuKongReasonCode($value)';
}
