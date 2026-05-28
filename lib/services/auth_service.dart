import 'package:local_auth/local_auth.dart';

/// Wraps local_auth for Traackit's app lock.
/// Falls back to the device passcode if Face ID is unavailable or fails.
class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device can authenticate at all — biometrics OR a passcode.
  /// Used before enabling the lock so the user can't lock themselves out.
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts Face ID (with device-passcode fallback).
  /// Returns true only if the user successfully authenticated.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Traackit',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow passcode fallback
          stickyAuth: true, // survive app backgrounding mid-prompt
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
