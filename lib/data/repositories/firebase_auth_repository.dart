import 'package:firebase_auth/firebase_auth.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/models/user.dart' as app_user;

class FirebaseAuthRepository {
  static final FirebaseAuthRepository _instance = FirebaseAuthRepository._internal();
  factory FirebaseAuthRepository() => _instance;
  FirebaseAuthRepository._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user stream
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Send OTP to phone number
  Future<Result<String>> sendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    Function(String)? onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout ?? (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
      
      return const Success('OTP sent successfully');
    } on FirebaseAuthException catch (e) {
      return Failure(_getAuthErrorMessage(e));
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  /// Verify OTP and sign in
  Future<Result<User>> verifyOTP({
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return Success(userCredential.user!);
      } else {
        return const Failure('Failed to sign in user');
      }
    } on FirebaseAuthException catch (e) {
      return Failure(_getAuthErrorMessage(e));
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure('Failed to sign out: $e');
    }
  }

  /// Delete user account
  Future<Result<void>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        return const Success(null);
      } else {
        return const Failure('No user signed in');
      }
    } on FirebaseAuthException catch (e) {
      return Failure(_getAuthErrorMessage(e));
    } catch (e) {
      return Failure('Failed to delete account: $e');
    }
  }

  /// Get formatted phone number for Firebase Auth
  String formatPhoneNumber(String phoneNumber) {
    // Remove any spaces, dashes, or parentheses
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Add Iraq country code if not present
    if (!cleaned.startsWith('+964')) {
      if (cleaned.startsWith('0')) {
        cleaned = '+964${cleaned.substring(1)}';
      } else if (cleaned.startsWith('964')) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+964$cleaned';
      }
    }
    
    return cleaned;
  }

  /// Convert Firebase auth error to user-friendly message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
        return 'معرف التحقق غير صالح';
      case 'quota-exceeded':
        return 'تم تجاوز حد إرسال الرسائل اليومي';
      case 'session-expired':
        return 'انتهت صلاحية جلسة التحقق';
      case 'too-many-requests':
        return 'تم إرسال عدد كبير من الطلبات، حاول مرة أخرى لاحقاً';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'operation-not-allowed':
        return 'العملية غير مسموحة';
      default:
        return 'حدث خطأ في المصادقة: ${e.message}';
    }
  }
}