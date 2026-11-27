import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const _format = 'mizan-encrypted-backup';
const _version = 1;
const _maxIterations = 2000000;

/// تشفير النسخ الاحتياطية بكلمة مرور:
/// PBKDF2-HMAC-SHA256 لاشتقاق المفتاح، و AES-256-GCM للتشفير.
/// الاشتقاق بطيء عمداً (ليصعب تخمين كلمة المرور)، لذلك يعمل في Isolate
/// منفصل حتى لا تتجمد الواجهة.
class BackupCrypto {
  BackupCrypto._();

  static const defaultIterations = 200000;

  static bool isEncrypted(String source) {
    try {
      final data = jsonDecode(source);

      return data is Map<String, dynamic> && data['format'] == _format;
    } catch (_) {
      return false;
    }
  }

  static Future<String> encrypt(
    String plainText,
    String password, {
    int iterations = defaultIterations,
  }) {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );

    return Isolate.run(
      () => _encryptJob(plainText, password, salt, iterations),
    );
  }

  /// يرمي ArgumentError عند كلمة مرور خاطئة أو ملف تالف أو معدّل.
  static Future<String> decrypt(String source, String password) async {
    late final Uint8List salt;
    late final Uint8List nonce;
    late final Uint8List cipherText;
    late final Uint8List mac;
    late final int iterations;

    try {
      final data = jsonDecode(source) as Map<String, dynamic>;

      if (data['format'] != _format || data['version'] != _version) {
        throw const FormatException('unknown format');
      }

      iterations = data['iterations'] as int;

      // سقف للتكرارات حتى لا يجمّد ملف مزوّر التطبيق.
      if (iterations < 1 || iterations > _maxIterations) {
        throw const FormatException('bad iterations');
      }

      salt = base64Decode(data['salt'] as String);
      nonce = base64Decode(data['nonce'] as String);
      cipherText = base64Decode(data['ciphertext'] as String);
      mac = base64Decode(data['mac'] as String);
    } catch (_) {
      throw ArgumentError('ملف النسخة المشفرة غير صالح');
    }

    final result = await Isolate.run(
      () => _decryptJob(password, salt, nonce, cipherText, mac, iterations),
    );

    if (result == null) {
      throw ArgumentError('كلمة المرور غير صحيحة أو الملف تالف');
    }

    return result;
  }
}

Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );

  return pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
}

Future<String> _encryptJob(
  String plainText,
  String password,
  Uint8List salt,
  int iterations,
) async {
  final key = await _deriveKey(password, salt, iterations);

  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(plainText),
    secretKey: key,
  );

  return jsonEncode({
    'format': _format,
    'version': _version,
    'kdf': 'pbkdf2-hmac-sha256',
    'iterations': iterations,
    'salt': base64Encode(salt),
    'nonce': base64Encode(box.nonce),
    'ciphertext': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  });
}

Future<String?> _decryptJob(
  String password,
  Uint8List salt,
  Uint8List nonce,
  Uint8List cipherText,
  Uint8List mac,
  int iterations,
) async {
  try {
    final key = await _deriveKey(password, salt, iterations);

    final clear = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: key,
    );

    return utf8.decode(clear);
  } catch (_) {
    return null;
  }
}