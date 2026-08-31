import 'dart:developer' as developer;

/// Receives an SDK diagnostic message when debug logging is enabled.
typedef WuKongLogHandler = void Function(String message);

/// Central logging boundary for the SDK.
class WuKongLogger {
  /// Whether diagnostic messages may be emitted.
  final bool enabled;

  /// Optional application-owned diagnostic sink.
  final WuKongLogHandler? handler;

  /// Creates a logger that is disabled unless explicitly enabled.
  const WuKongLogger({this.enabled = false, this.handler});

  /// Emits a diagnostic message only when logging is enabled.
  void log(String message) {
    if (!enabled) {
      return;
    }
    if (handler != null) {
      try {
        handler!(message);
      } catch (_) {
        // Application logging must never interrupt protocol or lifecycle work.
      }
      return;
    }
    developer.log(
      message,
      name: 'WuKongEasySDK',
    );
  }
}
