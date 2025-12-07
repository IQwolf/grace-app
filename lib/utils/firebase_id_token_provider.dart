import 'package:firebase_auth/firebase_auth.dart';

/// Provides fresh Firebase ID tokens for authenticated requests.
class FirebaseIdTokenProvider {
  const FirebaseIdTokenProvider._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Returns a valid Firebase ID token string, refreshing when needed.
  static Future<String?> getValidToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      if (forceRefresh) {
        return await user.getIdToken(true);
      }
      final result = await user.getIdTokenResult();
      final expiry = result.expirationTime;
      final now = DateTime.now();
      if (expiry == null || now.isAfter(expiry.subtract(const Duration(minutes: 5)))) {
        // Expired or expiring soon → refresh
        return await user.getIdToken(true);
      }
      // Use cached token
      return await user.getIdToken(false);
    } catch (_) {
      try {
        // Fallback: force refresh once
        return await _auth.currentUser?.getIdToken(true);
      } catch (_) {}
      return null;
    }
  }

  /// Builds headers map containing the Authorization: Bearer token when available.
  static Future<Map<String, String>> buildAuthHeaders() async {
    final token = await getValidToken();
    if (token == null || token.isEmpty) return const <String, String>{};
    return {
      'Authorization': 'Bearer ' + token,
    };
  }
}
