import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/api/api_client.dart';
import 'package:grace_academy/data/api/rest_api_client.dart';
import 'package:grace_academy/core/config.dart';
import 'package:grace_academy/data/models/auth_session.dart';
import 'package:grace_academy/data/models/user.dart';
import 'package:grace_academy/features/auth/token_manager.dart';
import 'package:grace_academy/services/notification_service.dart';

// API client provider
// Keep Firebase out of the build until a backend is connected in Dreamflow.
final apiClientProvider = Provider<ApiClient>((ref) {
  if (AppConfig.USE_MOCK) {
    // ignore: avoid_print
    print('[apiClientProvider] Using MockApiClient');
    return MockApiClient();
  }
  // ignore: avoid_print
  print('[apiClientProvider] Using RestApiClient');
  return RestApiClient();
});

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth controller
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return await _loadUser();
  }

  Future<AuthState> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try to restore full user object first
      final raw = prefs.getString('auth_user_data');
      if (raw != null && raw.trim().isNotEmpty) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(raw) as Map<String, dynamic>;
          final user = User.fromJson(jsonMap);
          return AuthState(user: user);
        } catch (_) {
          // Legacy non-JSON format, ignore and continue
        }
      }

      // If we have a cached token, consider the session authenticated so user skips OTP
      final token = prefs.getString('auth_token');
      final cachedId = prefs.getString('auth_user_id') ?? '';
      if (token != null && token.isNotEmpty) {
        final placeholder = User(
          id: cachedId.isNotEmpty ? cachedId : 'local',
          phone: '',
          name: 'مستخدم',
          governorate: '',
          university: '',
          birthDate: DateTime.fromMillisecondsSinceEpoch(0),
          gender: Gender.male,
          telegramUsername: null,
        );
        return AuthState(user: placeholder);
      }
    } catch (e) {
      // Silently handle error
    }
    return const AuthState();
  }

  // Login flow: ensure account exists before sending OTP
  Future<Result<String>> signIn(String phone) async {
    state = const AsyncLoading();
    final apiClient = ref.read(apiClientProvider);

    final existsRes = await apiClient.hasAccount(phone);
    if (existsRes is Failure<bool>) {
      state = AsyncData(AuthState(error: existsRes.error));
      return Failure(existsRes.error);
    }
    final exists = (existsRes as Success<bool>).data;
    if (!exists) {
      state = const AsyncData(AuthState());
      return const Failure('no_account');
    }

    final result = await apiClient.startOtp(phone);
    result.when(
      success: (_) => state = const AsyncData(AuthState()),
      failure: (error) => state = AsyncData(AuthState(error: error)),
    );
    return result;
  }

  // Registration flow: ensure account does NOT exist then send OTP
  Future<Result<String>> startRegistration(String phone) async {
    state = const AsyncLoading();
    final apiClient = ref.read(apiClientProvider);

    final existsRes = await apiClient.hasAccount(phone);
    if (existsRes is Failure<bool>) {
      state = AsyncData(AuthState(error: existsRes.error));
      return Failure(existsRes.error);
    }
    final exists = (existsRes as Success<bool>).data;
    if (exists) {
      state = const AsyncData(AuthState());
      return const Failure('existing_account');
    }

    final result = await apiClient.startOtp(phone);
    result.when(
      success: (_) => state = const AsyncData(AuthState()),
      failure: (error) => state = AsyncData(AuthState(error: error)),
    );
    return result;
  }

  // Resend OTP without re-checking account existence or changing auth state
  Future<Result<String>> resendOtp(String phone) async {
    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.startOtp(phone);
    return result;
  }

  Future<Result<User?>> verifyOtp(String phone, String otp, String requestId) async {
    state = const AsyncLoading();
    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.verifyOtp(phone, otp, requestId);

    if (result is Success<OtpVerificationResult>) {
      final payload = result.data;
      final tokenResult = await AuthTokenManager.persistToken(
        rawToken: payload.token,
        tokenType: payload.tokenType,
      );
      if (tokenResult is Failure<void>) {
        final error = tokenResult.error;
        state = AsyncData(AuthState(error: error));
        return Failure(error);
      }

      final user = payload.user;
      state = AsyncData(AuthState(user: user));
      _saveUser(user);
      try {
        ref.read(notificationServiceProvider).syncTokenForUser(studentId: user.id, phoneNumber: user.phone);
      } catch (_) {}
      return Success(user);
    }

    if (result is Failure<OtpVerificationResult>) {
      final error = result.error;
      if (error == 'new_user') {
        final tokenResult = await AuthTokenManager.persistToken();
        if (tokenResult is Failure<void>) {
          final err = tokenResult.error;
          state = AsyncData(AuthState(error: err));
          return Failure(err);
        }
        state = const AsyncData(AuthState());
        return const Success(null);
      }

      state = AsyncData(AuthState(error: error));
      return Failure(error);
    }

    state = const AsyncData(AuthState(error: 'unknown_error'));
    return const Failure('unknown_error');
  }

  Future<Result<User>> createProfile({
    required String phone,
    required String name,
    required String governorate,
    required String university,
    required DateTime birthDate,
    required Gender gender,
  }) async {
    state = const AsyncLoading();
    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.createProfile(
      phone: phone,
      name: name,
      governorate: governorate,
      university: university,
      birthDate: birthDate,
      gender: gender,
    );

    return result.when(
      success: (user) {
        state = AsyncData(AuthState(user: user));
        _saveUser(user);
        // Save FCM token for this device using studentId
        try { ref.read(notificationServiceProvider).syncTokenForUser(studentId: user.id, phoneNumber: user.phone); } catch (_) {}
        return Success(user);
      },
      failure: (error) {
        state = AsyncData(AuthState(error: error));
        return Failure(error);
      },
    );
  }

  Future<Result<User>> fetchCurrentUser() async {
    final previousUser = state.whenOrNull(data: (authState) => authState.user);
    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.getCurrentUser();

    return result.when(
      success: (user) {
        final merged = _mergeUser(previousUser, user);
        state = AsyncData(AuthState(user: merged));
        _saveUser(merged);
        return Success(merged);
      },
      failure: (error) {
        state = AsyncData(AuthState(user: previousUser, error: error));
        return Failure(error);
      },
    );
  }

  Future<Result<User>> updateProfile({
    String? name,
    String? governorate,
    String? university,
    DateTime? birthDate,
    Gender? gender,
    String? telegramUsername,
  }) async {
    final previousUser = state.whenOrNull(data: (authState) => authState.user);
    if (previousUser != null) {
      state = AsyncData(AuthState(user: previousUser, isLoading: true));
    } else {
      state = const AsyncLoading();
    }
    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.updateProfile(
      name: name,
      governorate: governorate,
      university: university,
      birthDate: birthDate,
      gender: gender,
      telegramUsername: telegramUsername,
    );

    return result.when(
      success: (user) {
        final merged = _mergeUser(previousUser, user);
        state = AsyncData(AuthState(user: merged));
        _saveUser(merged);
        return Success(merged);
      },
      failure: (error) {
        state = AsyncData(AuthState(user: previousUser, error: error));
        return Failure(error);
      },
    );
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_user_data');
      await prefs.remove('auth_token');
      await prefs.remove('auth_backend_token');
      await prefs.remove('auth_backend_token_type');
      await prefs.remove('firebase_uid');
      try {
        await fb_auth.FirebaseAuth.instance.signOut();
      } catch (_) {}
      state = const AsyncData(AuthState());
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all data
      try {
        await fb_auth.FirebaseAuth.instance.signOut();
      } catch (_) {}
      state = const AsyncData(AuthState());
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_id', user.id);
      await prefs.setString('auth_user_data', jsonEncode(user.toJson()));
    } catch (e) {
      // Handle error silently
    }
  }

  User _mergeUser(User? existing, User incoming) {
    if (existing == null) return incoming;
    final birthDate = incoming.birthDate.millisecondsSinceEpoch == 0 ? existing.birthDate : incoming.birthDate;
    final normalizedTelegram = () {
      final t = incoming.telegramUsername;
      if (t == null || t.trim().isEmpty) {
        return existing.telegramUsername;
      }
      return t;
    }();

    return incoming.copyWith(
      phone: incoming.phone.isNotEmpty ? incoming.phone : existing.phone,
      name: incoming.name.isNotEmpty ? incoming.name : existing.name,
      governorate: incoming.governorate.isNotEmpty ? incoming.governorate : existing.governorate,
      university: incoming.university.isNotEmpty ? incoming.university : existing.university,
      birthDate: birthDate,
      gender: incoming.gender,
      telegramUsername: normalizedTelegram,
    );
  }

  void clearError() {
    state = const AsyncData(AuthState());
  }
}

// Provider for auth controller
final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(() => AuthController());

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.when(
    data: (state) => state.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.when(
    data: (state) => state.user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});