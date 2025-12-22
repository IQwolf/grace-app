import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grace_academy/data/repositories/firebase_auth_repository.dart';
import 'package:grace_academy/data/repositories/firestore_repository.dart';
import 'package:grace_academy/data/models/user.dart' as app_user;
import 'package:grace_academy/core/result.dart';

// Provider for Firebase Auth Repository
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// Provider for Firestore Repository
final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository();
});

// Provider for Firebase Auth User Stream
final authUserStreamProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(firebaseAuthRepositoryProvider);
  return authRepository.userStream;
});

// Provider for current Firebase Auth User
final currentUserProvider = Provider<User?>((ref) {
  final authRepository = ref.watch(firebaseAuthRepositoryProvider);
  return authRepository.currentUser;
});

// Provider for app user data
final appUserProvider = FutureProvider<app_user.User?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;
  
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getUser(currentUser.uid);
  
  return result.when(
    success: (user) => user,
    failure: (_) => null,
  );
});

// Notifier for authentication operations
class AuthController extends Notifier<AsyncValue<void>> {
  late final FirebaseAuthRepository _authRepository;
  late final FirestoreRepository _firestoreRepository;

  @override
  AsyncValue<void> build() {
    _authRepository = ref.read(firebaseAuthRepositoryProvider);
    _firestoreRepository = ref.read(firestoreRepositoryProvider);
    return const AsyncValue.data(null);
  }

  String? _verificationId;
  String? _phoneNumber;

  // Send OTP
  Future<Result<void>> sendOTP(String phoneNumber) async {
    state = const AsyncValue.loading();
    
    _phoneNumber = _authRepository.formatPhoneNumber(phoneNumber);
    
    final completer = Completer<Result<void>>();
    
    final result = await _authRepository.sendOTP(
      phoneNumber: _phoneNumber!,
      onVerificationCompleted: (PhoneAuthCredential credential) async {
        // Auto sign-in (Android only)
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete(Success(null));
        } catch (e) {
          completer.complete(Failure('فشل في التحقق التلقائي: $e'));
        }
      },
      onCodeSent: (String verificationId) {
        _verificationId = verificationId;
        completer.complete(Success(null));
      },
      onVerificationFailed: (FirebaseAuthException error) {
        completer.complete(Failure(error.message ?? 'فشل في إرسال OTP'));
      },
    );
    
    if (result.isFailure) {
      state = AsyncValue.error(result.error ?? 'Unknown error', StackTrace.current);
      return result;
    }
    
    // Wait for the completion
    final finalResult = await completer.future;
    
    if (finalResult.isSuccess) {
      state = const AsyncValue.data(null);
    } else {
      state = AsyncValue.error(finalResult.error ?? 'Unknown error', StackTrace.current);
    }
    
    return finalResult;
  }

  // Verify OTP and sign in
  Future<Result<User>> verifyOTP(String otpCode) async {
    if (_verificationId == null) {
      return const Failure('لم يتم إرسال رمز التحقق');
    }
    
    state = const AsyncValue.loading();
    
    final result = await _authRepository.verifyOTP(
      verificationId: _verificationId!,
      otpCode: otpCode,
    );
    
    if (result.isSuccess) {
      state = const AsyncValue.data(null);
    } else {
      state = AsyncValue.error(result.error ?? 'Unknown error', StackTrace.current);
    }
    
    return result;
  }

  // Create user profile
  Future<Result<void>> createProfile({
    required String name,
    required String governorate,
    required String university,
    required DateTime birthDate,
    required app_user.Gender gender,
  }) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null || _phoneNumber == null) {
      return const Failure('المستخدم غير مسجل الدخول');
    }
    
    state = const AsyncValue.loading();
    
    final user = app_user.User(
      id: currentUser.uid,
      phone: _phoneNumber!,
      name: name,
      governorate: governorate,
      university: university,
      birthDate: birthDate,
      gender: gender,
    );
    
    final result = await _firestoreRepository.createUser(
      userId: currentUser.uid,
      user: user,
    );
    
    if (result.isSuccess) {
      state = const AsyncValue.data(null);
    } else {
      state = AsyncValue.error(result.error ?? 'Unknown error', StackTrace.current);
    }
    
    return result;
  }

  // Sign out
  Future<Result<void>> signOut() async {
    state = const AsyncValue.loading();
    
    final result = await _authRepository.signOut();
    
    if (result.isSuccess) {
      _verificationId = null;
      _phoneNumber = null;
      state = const AsyncValue.data(null);
    } else {
      state = AsyncValue.error(result.error ?? 'Unknown error', StackTrace.current);
    }
    
    return result;
  }

  // Delete account
  Future<Result<void>> deleteAccount() async {
    state = const AsyncValue.loading();
    
    final result = await _authRepository.deleteAccount();
    
    if (result.isSuccess) {
      _verificationId = null;
      _phoneNumber = null;
      state = const AsyncValue.data(null);
    } else {
      state = AsyncValue.error(result.error ?? 'Unknown error', StackTrace.current);
    }
    
    return result;
  }

  // Check if user has account
  Future<bool> hasAccount(String phoneNumber) async {
    final formattedPhone = _authRepository.formatPhoneNumber(phoneNumber);
    // This would typically check Firestore for existing user with phone
    // For now, return false as placeholder
    return false;
  }
}

// Provider for Auth Controller
final authControllerProvider = NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

// Helper provider to check if user is signed in
final isSignedInProvider = Provider<bool>((ref) {
  final authUser = ref.watch(authUserStreamProvider);
  return authUser.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Helper provider to check if user profile is complete
final isProfileCompleteProvider = FutureProvider<bool>((ref) async {
  final appUser = await ref.watch(appUserProvider.future);
  return appUser != null;
});