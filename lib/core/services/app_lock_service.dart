import 'package:local_auth/local_auth.dart';

class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// هل في الهاتف قفل شاشة (بصمة أو وجه أو PIN أو نمط)؟
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// يستخدم البصمة أو الوجه، ويقبل رمز الهاتف كبديل.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (_) {
      return false;
    }
  }
}