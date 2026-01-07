/// Information about a reconnection attempt
class ReconnectingInfo {
  /// The current reconnection attempt count
  final int attempt;

  /// The delay before the next reconnection attempt (in milliseconds)
  final int delay;

  /// Creates a new reconnecting info
  const ReconnectingInfo({
    required this.attempt,
    required this.delay,
  });

  @override
  String toString() {
    return 'ReconnectingInfo(attempt: $attempt, delay: $delay ms)';
  }
}

