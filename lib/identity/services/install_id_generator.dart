import 'dart:math';

final _random = Random.secure();

/// Generates a random UUID v4 (RFC 4122 §4.4) using a cryptographically
/// secure RNG.
///
/// Hand-rolled because the `uuid` package is only a *transitive* dependency
/// of this app and cannot be imported without a pubspec change; a v4 UUID
/// is 16 random bytes with 6 fixed bits, so rolling it is trivial and
/// dependency-free.
String generateInstallId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  // Set version 4 (0100) in the high nibble of byte 6 and the variant
  // (10xx) in the high bits of byte 8, per RFC 4122.
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}
