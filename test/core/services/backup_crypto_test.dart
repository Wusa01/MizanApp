import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/services/backup_crypto.dart';

void main() {
  // عدد تكرارات صغير ليسرّع الاختبار؛ التطبيق الحقيقي يستخدم 200 ألف.
  const fast = 1000;
  const plain = '{"format":"mizan-backup","amount":12345,"name":"حساب"}';

  test('encrypt then decrypt returns the original text', () async {
    final encrypted = await BackupCrypto.encrypt(
      plain,
      'correct-password',
      iterations: fast,
    );

    expect(encrypted.contains('12345'), isFalse);
    expect(encrypted.contains('mizan-backup'), isFalse);
    expect(BackupCrypto.isEncrypted(encrypted), isTrue);

    expect(await BackupCrypto.decrypt(encrypted, 'correct-password'), plain);
  });

  test('wrong password is rejected', () async {
    final encrypted = await BackupCrypto.encrypt(
      plain,
      'correct-password',
      iterations: fast,
    );

    expect(
      () => BackupCrypto.decrypt(encrypted, 'wrong-password'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('same text encrypts differently each time', () async {
    final a = await BackupCrypto.encrypt(plain, 'pw-12345', iterations: fast);
    final b = await BackupCrypto.encrypt(plain, 'pw-12345', iterations: fast);

    expect(a, isNot(b));
  });

  test('plain backups and garbage are not detected as encrypted', () {
    expect(BackupCrypto.isEncrypted(plain), isFalse);
    expect(BackupCrypto.isEncrypted('not json'), isFalse);
  });

  test('invalid encrypted file is rejected', () async {
    expect(
      () => BackupCrypto.decrypt('{"format":"mizan-encrypted-backup"}', 'x'),
      throwsA(isA<ArgumentError>()),
    );
  });
}