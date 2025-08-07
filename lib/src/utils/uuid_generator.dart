import 'package:uuid/uuid.dart';

/// UUID generator utility
/// 
/// Provides methods for generating unique identifiers.
class UuidGenerator {
  static const Uuid _uuid = Uuid();
  
  /// Generates a random UUID v4
  static String generate() {
    return _uuid.v4();
  }
  
  /// Generates a UUID v4 without hyphens
  static String generateSimple() {
    return _uuid.v4().replaceAll('-', '');
  }
}
