/// WuKong Reason Codes
///
/// Defines the different reason codes returned by the server for operation results and disconnect causes.
enum WuKongReasonCode {
  /// Unknown error
  unknown(0),

  /// Success
  success(1),

  /// Authentication failed
  authFail(2),

  /// Subscriber does not exist in the channel
  subscriberNotExist(3),

  /// In blacklist
  inBlacklist(4),

  /// Channel does not exist
  channelNotExist(5),

  /// User not on node
  userNotOnNode(6),

  /// Sender is offline; message cannot be delivered
  senderOffline(7),

  /// Message key error; the message is invalid
  msgKeyError(8),

  /// Payload decode failed
  payloadDecodeError(9),

  /// Forwarding send packet failed
  forwardSendPacketError(10),

  /// Not allowed to send
  notAllowSend(11),

  /// Connection kicked
  connectKick(12),

  /// Not in whitelist
  notInWhitelist(13),

  /// Failed to query user token
  queryTokenError(14),

  /// System error
  systemError(15),

  /// Invalid channel ID
  channelIDError(16),

  /// Node matching error
  nodeMatchError(17),

  /// Node not matched
  nodeNotMatch(18),

  /// Channel is banned
  ban(19),

  /// Unsupported header
  notSupportHeader(20),

  /// clientKey is empty
  clientKeyIsEmpty(21),

  /// Rate limit
  rateLimit(22),

  /// Unsupported channel type
  notSupportChannelType(23),

  /// Channel disbanded
  disband(24),

  /// Sending is banned
  sendBan(25);

  const WuKongReasonCode(this.value);

  /// The numeric value of the reason code
  final int value;

  /// Get reason code from numeric value
  static WuKongReasonCode fromValue(int value) {
    return WuKongReasonCode.values.firstWhere(
      (code) => code.value == value,
      orElse: () => WuKongReasonCode.unknown,
    );
  }
}

