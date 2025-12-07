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

// Simple auth providers using FutureProvider and Provider
// Note: We avoid importing FirebaseApiClient to keep web startup fast while no backend is connected.
final apiClientProvider = Provider<ApiClient>((ref) {
  if (AppConfig.USE_MOCK) {
    // Avoid linking any Firebase web plugins when mocking.
    return MockApiClient();
  }
  return RestApiClient();
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('auth_user_data');
    if (userDataString != null) {
      // In real app, parse JSON properly
      return null; // For now return null
    }
    return null;
  } catch (e) {
    return null;
  }
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Simple auth methods
class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  Future<Result<String>> startOtp(String phone) async {
    return await apiClient.startOtp(phone);
  }

  Future<Result<User?>> verifyOtp(String phone, String otp, String requestId) async {
    final result = await apiClient.verifyOtp(phone, otp, requestId);

    if (result is Success<OtpVerificationResult>) {
      final payload = result.data;
      final tokenResult = await AuthTokenManager.persistToken(
        rawToken: payload.token,
        tokenType: payload.tokenType,
      );
      if (tokenResult is Failure<void>) {
        return Failure(tokenResult.error);
      }
      final user = payload.user;
      await _saveUser(user);
      return Success(user);
    }

    if (result is Failure<OtpVerificationResult>) {
      final error = result.error;
      if (error == 'new_user') {
        final tokenResult = await AuthTokenManager.persistToken();
        if (tokenResult is Failure<void>) {
          return Failure(tokenResult.error);
        }
        return const Success(null);
      }
      return Failure(error);
    }

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
    final result = await apiClient.createProfile(
      phone: phone,
      name: name,
      governorate: governorate,
      university: university,
      birthDate: birthDate,
      gender: gender,
    );
    
    return result.when(
      success: (user) async {
        await _saveUser(user);
        return Success(user);
      },
      failure: (error) => Failure(error),
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
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      try {
        await fb_auth.FirebaseAuth.instance.signOut();
      } catch (_) {}
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
}

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});