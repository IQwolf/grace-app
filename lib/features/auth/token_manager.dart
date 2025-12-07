import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grace_academy/core/result.dart';

class AuthTokenManager {
  const AuthTokenManager._();

  static Future<Result<void>> persistToken({
    String? rawToken,
    String? tokenType,
    bool clearRawCache = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    rawToken ??= prefs.getString('auth_backend_token');
    tokenType ??= prefs.getString('auth_backend_token_type');

    if (rawToken == null || rawToken.isEmpty) {
      return const Failure('رمز التحقق مفقود. يرجى المحاولة مرة أخرى');
    }

    final bool isDevToken =
        tokenType == 'dev_token' || rawToken.startsWith('dev_token_');

    if (isDevToken) {
      await prefs.setString('auth_token', rawToken);
      await prefs.remove('firebase_uid');
      // Ensure no lingering Firebase session when using dev tokens only.
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }
      } catch (_) {}
    } else {
      try {
        final credential = await FirebaseAuth.instance.signInWithCustomToken(rawToken);
        final user = credential.user ?? FirebaseAuth.instance.currentUser;
        final idToken = await user?.getIdToken(true);
        if (idToken == null || idToken.isEmpty) {
          await FirebaseAuth.instance.signOut();
          await prefs.remove('auth_token');
          return const Failure('تعذر الحصول على رمز هوية Firebase');
        }
        await prefs.setString('auth_token', idToken);
        final uid = user?.uid;
        if (uid != null && uid.isNotEmpty) {
          await prefs.setString('firebase_uid', uid);
        }
      } on FirebaseAuthException catch (e) {
        await prefs.remove('auth_token');
        final message = () {
          final code = e.code;
          if (code == 'invalid-custom-token' || code == 'custom-token-mismatch') {
            return 'رمز المصادقة المرسل من الخادم غير صالح';
          }
          return 'تعذر تسجيل الدخول باستخدام Firebase، يرجى المحاولة مرة أخرى';
        }();
        return Failure(message);
      } catch (_) {
        await prefs.remove('auth_token');
        return const Failure('تعذر تسجيل الدخول باستخدام Firebase، يرجى المحاولة مرة أخرى');
      }
    }

    if (clearRawCache) {
      await prefs.remove('auth_backend_token');
      await prefs.remove('auth_backend_token_type');
    }

    return const Success(null);
  }
}