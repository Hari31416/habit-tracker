import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/sync/backup_encryption_engine.dart';

void main() {
  group('BackupEncryptionEngine Tests', () {
    const testPlaintext = '{"schemaVersion":1,"appVersion":"0.8.1","habits":[{"id":"h1","title":"Meditation"}]}';
    const testPassword = 'SuperSecretPassphrase123!';

    test('encrypt and decrypt roundtrip restores exact plaintext', () async {
      final encryptedJson = await BackupEncryptionEngine.encrypt(
        plaintextJson: testPlaintext,
        password: testPassword,
      );

      expect(BackupEncryptionEngine.isEncrypted(encryptedJson), isTrue);

      final decodedEnvelope = jsonDecode(encryptedJson);
      expect(decodedEnvelope['schemaVersion'], 1);
      expect(decodedEnvelope['type'], 'encrypted_envelope');
      expect(decodedEnvelope['crypto']['algorithm'], 'AES-256-GCM');
      expect(decodedEnvelope['crypto']['kdf'], 'PBKDF2-HMAC-SHA256');

      final decrypted = await BackupEncryptionEngine.decrypt(
        encryptedEnvelopeJson: encryptedJson,
        password: testPassword,
      );

      expect(decrypted, equals(testPlaintext));
    });

    test('isEncrypted identifies plain vs encrypted JSON accurately', () {
      expect(BackupEncryptionEngine.isEncrypted(testPlaintext), isFalse);
      expect(BackupEncryptionEngine.isEncrypted('not json at all'), isFalse);
      expect(BackupEncryptionEngine.isEncrypted('{}'), isFalse);

      final fakeEncrypted = jsonEncode({
        'type': 'encrypted_envelope',
        'ciphertext': 'dGVzdA==',
      });
      expect(BackupEncryptionEngine.isEncrypted(fakeEncrypted), isTrue);
    });

    test('decrypting with wrong password throws InvalidPasswordOrCorruptedException', () async {
      final encryptedJson = await BackupEncryptionEngine.encrypt(
        plaintextJson: testPlaintext,
        password: testPassword,
      );

      expect(
        () => BackupEncryptionEngine.decrypt(
          encryptedEnvelopeJson: encryptedJson,
          password: 'WrongPassword456!',
        ),
        throwsA(isA<InvalidPasswordOrCorruptedException>()),
      );
    });

    test('tampered ciphertext fails authentication check', () async {
      final encryptedJson = await BackupEncryptionEngine.encrypt(
        plaintextJson: testPlaintext,
        password: testPassword,
      );

      final Map<String, dynamic> envelope = jsonDecode(encryptedJson);
      final rawCipher = base64Decode(envelope['ciphertext'] as String);
      // Flip a bit in ciphertext
      rawCipher[0] = rawCipher[0] ^ 0xFF;
      envelope['ciphertext'] = base64Encode(rawCipher);

      final tamperedJson = jsonEncode(envelope);

      expect(
        () => BackupEncryptionEngine.decrypt(
          encryptedEnvelopeJson: tamperedJson,
          password: testPassword,
        ),
        throwsA(isA<InvalidPasswordOrCorruptedException>()),
      );
    });

    test('empty password throws argument error or exception', () async {
      expect(
        () => BackupEncryptionEngine.encrypt(
          plaintextJson: testPlaintext,
          password: '',
        ),
        throwsA(isA<ArgumentError>()),
      );

      final encryptedJson = await BackupEncryptionEngine.encrypt(
        plaintextJson: testPlaintext,
        password: testPassword,
      );

      expect(
        () => BackupEncryptionEngine.decrypt(
          encryptedEnvelopeJson: encryptedJson,
          password: '',
        ),
        throwsA(isA<InvalidPasswordOrCorruptedException>()),
      );
    });

    test('generatePasskey returns valid segmented uppercase alphanumeric format', () {
      final passkey1 = BackupEncryptionEngine.generatePasskey();
      final passkey2 = BackupEncryptionEngine.generatePasskey();

      expect(passkey1, matches(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$'));
      expect(passkey2, matches(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$'));
      expect(passkey1, isNot(equals(passkey2)));
    });
  });
}
