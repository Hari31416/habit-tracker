import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

class InvalidPasswordOrCorruptedException implements Exception {
  final String message;
  const InvalidPasswordOrCorruptedException([this.message = 'Invalid password or corrupted backup file']);

  @override
  String toString() => 'InvalidPasswordOrCorruptedException: $message';
}

class BackupEncryptionEngine {
  static const int kdfIterations = 100000;
  static const int saltLengthBytes = 16;
  static const int nonceLengthBytes = 12;

  /// Upper bound on decrypted ciphertext to bound memory on crafted files.
  static const int maxCiphertextBytes = 50 * 1024 * 1024;

  static const String expectedAlgorithm = 'AES-256-GCM';
  static const String expectedKdf = 'PBKDF2-HMAC-SHA256';

  static const String _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Generates a cryptographically secure random passkey in uppercase 'XXXX-XXXX-XXXX-XXXX' format (e.g. 'JSJS-7172-HDJ1-76HD').
  static String generatePasskey({int segments = 4, int segmentLength = 4}) {
    final rng = Random.secure();
    final parts = <String>[];
    for (var i = 0; i < segments; i++) {
      final buffer = StringBuffer();
      for (var j = 0; j < segmentLength; j++) {
        buffer.write(_charset[rng.nextInt(_charset.length)]);
      }
      parts.add(buffer.toString());
    }
    return parts.join('-');
  }

  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: kdfIterations,
    bits: 256,
  );

  /// Checks if a given JSON string represents an encrypted envelope container.
  static bool isEncrypted(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded['type'] == 'encrypted_envelope' && decoded.containsKey('ciphertext');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Encrypts a plaintext JSON string with a passphrase using PBKDF2-HMAC-SHA256 and AES-256-GCM.
  static Future<String> encrypt({
    required String plaintextJson,
    required String password,
    @visibleForTesting List<int>? customSalt,
    @visibleForTesting List<int>? customNonce,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty');
    }
    if (customSalt != null && customSalt.length != saltLengthBytes) {
      throw ArgumentError('customSalt must be $saltLengthBytes bytes');
    }
    if (customNonce != null && customNonce.length != nonceLengthBytes) {
      throw ArgumentError('customNonce must be $nonceLengthBytes bytes');
    }

    final salt = customSalt ?? _generateSecureRandomBytes(saltLengthBytes);
    final nonce = customNonce ?? _generateSecureRandomBytes(nonceLengthBytes);

    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final plaintextBytes = utf8.encode(plaintextJson);
    final secretBox = await _aesGcm.encrypt(
      plaintextBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Concatenate ciphertext and 16-byte MAC tag into single payload for portability
    final combinedCiphertextBytes = Uint8List(secretBox.cipherText.length + secretBox.mac.bytes.length)
      ..setAll(0, secretBox.cipherText)
      ..setAll(secretBox.cipherText.length, secretBox.mac.bytes);

    final envelope = {
      'schemaVersion': 1,
      'type': 'encrypted_envelope',
      'crypto': {
        'algorithm': 'AES-256-GCM',
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': kdfIterations,
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
      },
      'ciphertext': base64Encode(combinedCiphertextBytes),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(envelope);
  }

  /// Decrypts an encrypted envelope container with a passphrase.
  /// Throws [InvalidPasswordOrCorruptedException] if password is wrong or ciphertext is tampered.
  static Future<String> decrypt({
    required String encryptedEnvelopeJson,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw const InvalidPasswordOrCorruptedException('Password cannot be empty');
    }

    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(encryptedEnvelopeJson) as Map<String, dynamic>;
    } catch (_) {
      throw const InvalidPasswordOrCorruptedException('Corrupted backup JSON format');
    }

    if (envelope['type'] != 'encrypted_envelope' || !envelope.containsKey('ciphertext')) {
      throw const InvalidPasswordOrCorruptedException('Not an encrypted envelope');
    }

    final cryptoInfo = envelope['crypto'] as Map<String, dynamic>?;
    if (cryptoInfo == null) {
      throw const InvalidPasswordOrCorruptedException('Missing cryptographic metadata');
    }

    final saltBase64 = cryptoInfo['salt'] as String?;
    final nonceBase64 = cryptoInfo['nonce'] as String?;
    final ciphertextBase64 = envelope['ciphertext'] as String?;
    final iterations = cryptoInfo['iterations'] as int? ?? kdfIterations;

    if (saltBase64 == null || nonceBase64 == null || ciphertextBase64 == null) {
      throw const InvalidPasswordOrCorruptedException('Incomplete cryptographic parameters');
    }

    if (cryptoInfo['algorithm'] != expectedAlgorithm ||
        cryptoInfo['kdf'] != expectedKdf) {
      throw const InvalidPasswordOrCorruptedException('Unsupported cryptographic parameters');
    }

    // Pin KDF cost: attacker-controlled iteration counts enable
    // downgrade (iterations=1) or CPU-DoS (iterations=huge).
    if (iterations != kdfIterations) {
      throw const InvalidPasswordOrCorruptedException('Unsupported KDF iterations');
    }

    final Uint8List salt;
    final Uint8List nonce;
    final Uint8List combinedCiphertext;
    try {
      salt = base64Decode(saltBase64);
      nonce = base64Decode(nonceBase64);
      combinedCiphertext = base64Decode(ciphertextBase64);
    } catch (_) {
      throw const InvalidPasswordOrCorruptedException('Invalid base64 payload');
    }

    if (combinedCiphertext.length < 16) {
      throw const InvalidPasswordOrCorruptedException('Ciphertext payload is too short');
    }

    if (salt.length != saltLengthBytes || nonce.length != nonceLengthBytes) {
      throw const InvalidPasswordOrCorruptedException('Invalid cryptographic parameters');
    }

    if (combinedCiphertext.length > maxCiphertextBytes) {
      throw const InvalidPasswordOrCorruptedException('Ciphertext payload is too large');
    }

    // Split MAC tag (last 16 bytes) from ciphertext
    final cipherTextLength = combinedCiphertext.length - 16;
    final cipherText = combinedCiphertext.sublist(0, cipherTextLength);
    final macBytes = combinedCiphertext.sublist(cipherTextLength);

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );

    try {
      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(decryptedBytes);
    } on SecretBoxAuthenticationError {
      throw const InvalidPasswordOrCorruptedException('Incorrect password or modified backup');
    } catch (e) {
      if (e is InvalidPasswordOrCorruptedException) rethrow;
      throw const InvalidPasswordOrCorruptedException('Failed to decrypt backup');
    }
  }

  static Uint8List _generateSecureRandomBytes(int length) {
    final rng = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return bytes;
  }
}
