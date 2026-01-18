import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grace_academy/utils/firebase_id_token_provider.dart';

import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/core/config.dart';
import 'package:grace_academy/data/api/api_client.dart';
import 'package:grace_academy/data/models/auth_session.dart';
import 'package:grace_academy/data/models/course.dart' as domain;
import 'package:grace_academy/data/models/instructor.dart' as domain;
import 'package:grace_academy/data/models/lecture.dart' as domain;
import 'package:grace_academy/data/models/major.dart' as domain;
import 'package:grace_academy/data/models/user.dart' as domain;
import 'package:grace_academy/data/models/major_levels.dart';
import 'package:grace_academy/data/models/app_notification.dart';
import 'package:grace_academy/data/models/university.dart';

/// REST implementation of ApiClient for EduPulse custom backend
class RestApiClient implements ApiClient {
  RestApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl =
      'https://grace.future-code.iq';

  final String _baseUrl;

  // Public getters for consumers that need to compose absolute URLs
  String get baseUrl => _baseUrl;
  String get baseOrigin {
    final base = Uri.parse(_baseUrl);
    return '${base.scheme}://${base.authority}';
  }

  // Simple in-memory caches
  final Map<String, domain.Instructor> _instructorCache = {};
  final Map<String, List<domain.Lecture>> _lecturesCacheByCourse = {};

  Future<Map<String, String>> _headers({bool withAuth = false, bool json = false}) async {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }

    if (!withAuth) {
      return headers;
    }

    String? authToken;
    if (AppConfig.isProduction) {
      authToken = await FirebaseIdTokenProvider.getValidToken();
    }

    if (authToken == null || authToken.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        authToken = prefs.getString('auth_token');
      } catch (_) {}
    }

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  Uri _u(String path, [Map<String, dynamic>? query]) {
    // Normalize base URL and strip accidental path prefix like '/5000'
    final baseUri = Uri.parse(_baseUrl);
    String basePath = baseUri.path;
    if (basePath == '/5000') {
      basePath = '';
    } else if (basePath.startsWith('/5000/')) {
      basePath = basePath.replaceFirst('/5000', '');
    }
    // Ensure no trailing slash
    if (basePath.endsWith('/') && basePath.length > 1) {
      basePath = basePath.substring(0, basePath.length - 1);
    }
    final normalizedBase = baseUri.replace(path: basePath);

    final baseStr = '${normalizedBase.scheme}://${normalizedBase.authority}${normalizedBase.path.isEmpty ? '' : normalizedBase.path}';
    final full = '$baseStr${path.startsWith('/') ? path : '/$path'}';
    return Uri.parse(full).replace(queryParameters: query);
  }

  // Heuristics to detect non-JSON (e.g., HTML landing pages) in 2xx responses
  bool _isJsonResponse(http.Response res) {
    final ct = (res.headers['content-type'] ?? res.headers['Content-Type'] ?? '').toLowerCase();
    if (ct.contains('application/json') || ct.contains('json')) return true;
    final body = res.body.trimLeft();
    return body.startsWith('{') || body.startsWith('[');
  }

  Uri _functionsUrl(String path) {
    final base = AppConfig.firebaseFunctionsBaseUrl.trim();
    final normalized = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final full = '$normalized${path.startsWith('/') ? path : '/$path'}';
    return Uri.parse(full);
  }

  Uri _userServiceUrl({String path = '/users'}) {
    final functionsBase = AppConfig.firebaseFunctionsBaseUrl.trim();
    final hasCustomFunctionsBase =
        functionsBase.isNotEmpty && !functionsBase.contains('your-firebase-project');
    if (hasCustomFunctionsBase) {
      return _functionsUrl(path);
    }
    final normalizedPath = path.startsWith('/api/')
        ? path
        : '/api${path.startsWith('/') ? path : '/$path'}';
    return _u(normalizedPath);
  }

  Uri _centralApiUrl(String path, [Map<String, dynamic>? query]) {
    final functionsBase = AppConfig.firebaseFunctionsBaseUrl.trim();
    final hasCentralApi =
        functionsBase.isNotEmpty && !functionsBase.contains('your-firebase-project');
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    if (hasCentralApi) {
      final uri = _functionsUrl(normalizedPath);
      if (query != null && query.isNotEmpty) {
        final qp = query.map((key, value) => MapEntry(key, value.toString()));
        return uri.replace(queryParameters: qp);
      }
      return uri;
    }

    final fallbackPath = normalizedPath.startsWith('/api/')
        ? normalizedPath
        : '/api$normalizedPath';
    return _u(fallbackPath, query);
  }

  T _safe<T>(T Function() fn, String fallbackMessage) {
    try {
      return fn();
    } catch (_) {
      throw Exception(fallbackMessage);
    }
  }

  // ---------------- Auth ----------------

  @override
  Future<Result<String>> startOtp(String phone) async {
    try {
      // Use a "simple" POST (form-urlencoded) to avoid CORS preflight on web.
      final uri = _u('/auth/otp/start');
      // Debug prints to verify final URL and headers in web console
      // NOTE: These logs are safe; they do not include secrets.
      debugPrint('[RestApiClient] startOtp → POST ${uri.toString()}');
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      debugPrint('[RestApiClient] startOtp headers=${headers.toString()}');

      final res = await http.post(
        uri,
        headers: headers,
        body: {
          'phone': phone,
          'channel': 'telegram',
          'ttl': '300',
          'codeLength': '6',
        },
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final requestId = (data['requestId'] ?? '').toString();
        if (requestId.isEmpty) {
          return const Failure('فشل بدء التحقق. لم يتم استلام requestId');
        }
        return Success(requestId);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في الشبكة: $e');
    }
  }

  @override
  Future<Result<OtpVerificationResult>> verifyOtp(String phone, String otp, String requestId) async {
    try {
      // Step 1: verify OTP (Telegram gateway)
      final uri = _u('/auth/otp/verify');
      debugPrint('[RestApiClient] verifyOtp → POST ${uri.toString()}');
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      debugPrint('[RestApiClient] verifyOtp headers=${headers.toString()}');

      final res = await http.post(
        uri,
        headers: headers,
        body: {
          'requestId': requestId,
          'code': otp,
        },
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = (data['token'] ?? '').toString();
        final tokenTypeRaw = (data['type'] ?? '').toString();
        if (token.isEmpty) {
          return const Failure('لم يتم استلام رمز الدخول');
        }
        // Persist raw backend token for downstream processing in AuthController
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_backend_token', token);
        if (tokenTypeRaw.isEmpty) {
          await prefs.remove('auth_backend_token_type');
        } else {
          await prefs.setString('auth_backend_token_type', tokenTypeRaw);
        }

        // Step 2: check if phone is already registered via the new Flutter endpoint
        final checkRes = await http.get(_u('/api/flutter/check-phone/' + phone));
        if (checkRes.statusCode >= 200 && checkRes.statusCode < 300) {
          final m = jsonDecode(checkRes.body) as Map<String, dynamic>;
          final exists = (m['exists'] == true);
          if (exists) {
            final student = (m['student'] as Map<String, dynamic>? ?? <String, dynamic>{});
            // Map student to domain.User
            final user = _parseUser(student, phone);
            return Success(
              OtpVerificationResult(
                user: user,
                token: token,
                tokenType: tokenTypeRaw.isEmpty ? null : tokenTypeRaw,
              ),
            );
          } else {
            // New user → go to profile completion
            return const Failure('new_user');
          }
        }
        // If check fails, still allow profile completion path
        return const Failure('new_user');
      }
      // Map common OTP invalid statuses to a clear message
      if (res.statusCode == 400 || res.statusCode == 401 || res.statusCode == 422) {
        return const Failure('رمز التحقق خطأ');
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في التحقق: $e');
    }
  }

  @override
  Future<Result<bool>> hasAccount(String phone) async {
    try {
      final res = await http.get(_u('/api/flutter/check-phone/' + phone));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final exists = (data['exists'] == true);
        return Success(exists);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في التحقق من الرقم: $e');
    }
  }

  @override
  Future<Result<domain.User>> createProfile({
    required String phone,
    required String name,
    required String governorate,
    required String university,
    required DateTime birthDate,
    required domain.Gender gender,
  }) async {
    try {
      final res = await http.post(
        _u('/api/flutter/register'),
        headers: await _headers(withAuth: false, json: true),
        body: jsonEncode({
          'name': name,
          'phoneNumber': phone,
          'governorate': governorate,
          'university': university,
          'birthDate': birthDate.toIso8601String().split('T').first,
          'gender': gender.name,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final success = (data['success'] == true);
        if (!success) {
          final msg = (data['message'] ?? 'فشل التسجيل').toString();
          return Failure(msg);
        }
        final student = (data['student'] as Map<String, dynamic>? ?? <String, dynamic>{});
        final user = _parseUser(student, phone);
        return Success(user);
      }
      // Handle duplicate phone gracefully
      if (res.statusCode == 409 || res.statusCode == 400) {
        try {
          final err = jsonDecode(res.body) as Map<String, dynamic>;
          final msg = (err['message'] ?? err['error'] ?? 'رقم الهاتف مسجل مسبقاً').toString();
          return Failure(msg);
        } catch (_) {}
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في إنشاء الحساب: $e');
    }
  }

  @override
  Future<Result<domain.User>> getCurrentUser() async {
    try {
      final uri = _userServiceUrl(path: '/users');
      debugPrint('[RestApiClient] getCurrentUser → GET ${uri.toString()}');
      final res = await http.get(uri, headers: await _headers(withAuth: true));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Map<String, dynamic>? data;
        final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['user'] is Map<String, dynamic>) {
            data = decoded['user'] as Map<String, dynamic>;
          } else if (decoded['student'] is Map<String, dynamic>) {
            data = decoded['student'] as Map<String, dynamic>;
          } else {
            data = decoded;
          }
        } else {
          return const Failure('استجابة غير متوقعة من الخادم');
        }
        if (data == null) {
          return const Failure('استجابة غير متوقعة من الخادم');
        }
        final phoneFallback = await _cachedPhoneFallback();
        final user = _parseUser(data, phoneFallback);
        return Success(user);
      }
      if (res.statusCode == 404) {
        return const Failure('الملف الشخصي غير موجود');
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحميل بيانات الحساب: $e');
    }
  }

  @override
  Future<Result<domain.User>> updateProfile({
    String? name,
    String? governorate,
    String? university,
    DateTime? birthDate,
    domain.Gender? gender,
    String? telegramUsername,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (governorate != null) payload['governorate'] = governorate;
      if (university != null) payload['university'] = university;
      if (birthDate != null) payload['birthDate'] = birthDate.toIso8601String().split('T').first;
      if (gender != null) payload['gender'] = gender.name;
      if (telegramUsername != null) payload['telegramUsername'] = telegramUsername;
      if (payload.isEmpty) {
        return const Failure('لا توجد بيانات للتحديث');
      }

      final uri = _userServiceUrl(path: '/users');
      debugPrint('[RestApiClient] updateProfile → PUT ${uri.toString()} fields=${payload.keys.toList()}');
      final res = await http.put(
        uri,
        headers: await _headers(withAuth: true, json: true),
        body: jsonEncode(payload),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
        Map<String, dynamic>? userMap;
        if (decoded is Map<String, dynamic>) {
          if (decoded['user'] is Map<String, dynamic>) {
            userMap = (decoded['user'] as Map<String, dynamic>);
          } else if (decoded['student'] is Map<String, dynamic>) {
            userMap = (decoded['student'] as Map<String, dynamic>);
          } else {
            userMap = decoded;
          }
        }
        if (userMap == null) {
          return const Failure('استجابة غير متوقعة من الخادم');
        }
        final phoneFallback = await _cachedPhoneFallback();
        final user = _parseUser(userMap, phoneFallback);
        return Success(user);
      }
      if (res.statusCode == 400) {
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            final msg = (decoded['message'] ?? decoded['error'] ?? 'طلب غير صالح').toString();
            return Failure(msg);
          }
        } catch (_) {}
      }
      if (res.statusCode == 404) {
        return const Failure('الملف الشخصي غير موجود');
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحديث بيانات الحساب: $e');
    }
  }

  @override
  Future<Result<String?>> getTelegramUsername({required String phoneNumber}) async {
    try {
      final encoded = Uri.encodeComponent(phoneNumber);
      final uri = _u('/api/students/$encoded/telegram-username');
      debugPrint('[RestApiClient] getTelegramUsername → GET ${uri.toString()}');
      final res = await http.get(uri, headers: await _headers(withAuth: true));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) {
          return const Success(null);
        }
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final success = decoded['success'] != false;
          if (!success) {
            final msg = (decoded['message'] ?? 'تعذر تحميل اسم المستخدم').toString();
            return Failure(msg);
          }
          final hasValue = decoded['hasValue'] == true;
          final raw = (decoded['telegramUsername'] ?? '').toString().trim();
          if (!hasValue || raw.isEmpty) {
            return const Success(null);
          }
          return Success(raw);
        }
        return const Failure('استجابة غير متوقعة من الخادم');
      }

      if (res.statusCode == 404) {
        return const Success(null);
      }

      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحميل اسم المستخدم: $e');
    }
  }

  @override
  Future<Result<void>> updateTelegramUsername({
    required String phoneNumber,
    required String telegramUsername,
  }) async {
    try {
      final encoded = Uri.encodeComponent(phoneNumber);
      final uri = _u('/api/students/$encoded/telegram-username');
      debugPrint('[RestApiClient] updateTelegramUsername → PUT ${uri.toString()}');
      final normalized = telegramUsername.trim();
      final res = await http.put(
        uri,
        headers: await _headers(withAuth: true, json: true),
        body: jsonEncode({'telegramUsername': normalized}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) {
          return const Success(null);
        }
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final success = decoded['success'] != false;
          if (success) {
            return const Success(null);
          }
          final msg = (decoded['message'] ?? 'تعذر تحديث اسم المستخدم').toString();
          return Failure(msg);
        }
        return const Success(null);
      }

      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحديث اسم المستخدم: $e');
    }
  }

  // ---------------- Account Deletion ----------------
  // Note: These endpoints do NOT require Authorization token.
  // Verification is done via OTP instead.

  @override
  Future<Result<String>> sendDeleteAccountOtp(String phone) async {
    try {
      final uri = _u('/api/delete-account/send-otp');
      final requestBody = jsonEncode({'phone': phone});
      final headers = {'Content-Type': 'application/json'};
      
      final res = await http.post(
        uri,
        headers: headers,
        body: requestBody,
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!_isJsonResponse(res)) {
          return const Failure('استجابة غير صالحة من الخادم أثناء إرسال الرمز');
        }
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final requestId = (data['requestId'] ?? '').toString();
        if (requestId.isEmpty) {
          return const Failure('فشل في بدء عملية الحذف. لم يتم استلام requestId');
        }
        return Success(requestId);
      }
      
      // Handle 404 - Account not found
      if (res.statusCode == 404) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final error = (data['error'] ?? 'الحساب غير موجود').toString();
          return Failure(error);
        } catch (_) {
          return const Failure('الحساب غير موجود');
        }
      }
      
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في الشبكة: $e');
    }
  }

  @override
  Future<Result<String>> verifyDeleteAccountOtp(String phone, String otp, String requestId) async {
    try {
      final uri = _u('/api/delete-account/verify-otp');
      final requestBody = jsonEncode({
        'phone': phone,
        'otp': otp,
        'requestId': requestId,
      });
      final headers = {'Content-Type': 'application/json'};
      
      final res = await http.post(
        uri,
        headers: headers,
        body: requestBody,
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!_isJsonResponse(res)) {
          return const Failure('استجابة غير صالحة من الخادم أثناء التحقق من الرمز');
        }
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = (data['verificationToken'] ?? '').toString();
        if (token.isEmpty) {
          return const Failure('رمز التحقق صحيح ولكن لم يتم استلام رمز التأكيد');
        }
        return Success(token);
      }
      
      // Handle OTP errors
      if (res.statusCode == 400 || res.statusCode == 401 || res.statusCode == 422) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final error = (data['error'] ?? '').toString();
          if (error.contains('Invalid OTP')) {
            return const Failure('رمز التحقق غير صحيح');
          } else if (error.contains('expired')) {
            return const Failure('انتهت صلاحية رمز التحقق');
          } else if (error.contains('Invalid or expired request')) {
            return const Failure('انتهت صلاحية الطلب، يرجى المحاولة مرة أخرى');
          }
          return Failure(error.isNotEmpty ? error : 'رمز OTP غير صحيح أو منتهي الصلاحية');
        } catch (_) {
          return const Failure('رمز OTP غير صحيح أو منتهي الصلاحية');
        }
      }
      
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في التحقق: $e');
    }
  }

  @override
  Future<Result<void>> confirmDeleteAccount(String phone, String verificationToken) async {
    try {
      final uri = _u('/api/delete-account/confirm');
      final requestBody = jsonEncode({
        'phone': phone,
        'verificationToken': verificationToken,
      });
      
      // DELETE request with body requires http.Request
      final request = http.Request('DELETE', uri);
      request.headers['Content-Type'] = 'application/json';
      request.body = requestBody;
      
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!_isJsonResponse(res) && res.body.isNotEmpty) {
          return const Failure('استجابة غير صالحة من الخادم أثناء تأكيد الحذف');
        }
        return const Success(null);
      }
      
      // Handle confirmation errors
      if (res.statusCode == 400 || res.statusCode == 401 || res.statusCode == 422) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final error = (data['error'] ?? '').toString();
          if (error.contains('Invalid or expired verification token')) {
            return const Failure('رمز التأكيد غير صالح أو منتهي الصلاحية');
          } else if (error.contains('Verification token expired')) {
            return const Failure('انتهت صلاحية رمز التأكيد (10 دقائق)');
          } else if (error.contains('Phone number does not match')) {
            return const Failure('رقم الهاتف لا يتطابق مع الرمز');
          }
          return Failure(error.isNotEmpty ? error : 'فشل تأكيد الحذف');
        } catch (_) {
          return const Failure('فشل تأكيد الحذف');
        }
      }
      
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تأكيد الحذف: $e');
    }
  }

  // ---------------- Notifications ----------------

  @override
  Future<Result<void>> saveFcmToken({required String studentId, required String phoneNumber, required String fcmToken}) async {
    try {
      final uri = _u('/api/students/' + Uri.encodeComponent(studentId) + '/fcm-token');
      debugPrint('[RestApiClient] saveFcmToken → PUT ${uri.toString()}');
      final res = await http.put(
        uri,
        headers: await _headers(withAuth: true, json: true),
        body: jsonEncode({'fcmToken': fcmToken, 'phoneNumber': phoneNumber}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return const Success(null);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في حفظ رمز الإشعارات: $e');
    }
  }

  @override
  Future<Result<List<AppNotification>>> getNotifications({required String studentId}) async {
    try {
      // Use direct root path to avoid accidental HTML responses on some deployments
      final uri = _u('/notifications', {'studentId': studentId});
      debugPrint('[RestApiClient] getNotifications → GET ${uri.toString()}');
      final res = await http.get(uri, headers: await _headers(withAuth: true));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!_isJsonResponse(res)) {
          debugPrint('[RestApiClient] getNotifications non-JSON 2xx body: '
              '${res.body.substring(0, res.body.length > 160 ? 160 : res.body.length)}');
          return const Failure('استجابة غير صالحة من الخادم أثناء تحميل الإشعارات');
        }
        final decoded = jsonDecode(res.body);
        List<Map<String, dynamic>> items;
        if (decoded is Map<String, dynamic>) {
          items = (decoded['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        } else if (decoded is List) {
          items = decoded.cast<Map<String, dynamic>>();
        } else {
          items = <Map<String, dynamic>>[];
        }
        final list = items.map((m) => AppNotification.fromJson(m)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Success(list);
      }
      return Failure(_mapHttpError(res));
      } catch (e) {
        return Failure('خطأ في تحميل الإشعارات: $e');
     }
   }

  @override
  Future<Result<void>> markNotificationAsRead(String notificationId) async {
    try {
      // Use direct root path to match getNotifications
      final uri = _u('/notifications/$notificationId/read');
      debugPrint('[RestApiClient] markNotificationAsRead → PUT ${uri.toString()}');
      final res = await http.put(uri, headers: await _headers(withAuth: true));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return const Success(null);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحديث حالة الإشعار: $e');
    }
  }

   // ---------------- Catalog ----------------

  @override
  Future<Result<List<MajorLevels>>> getMajorsWithLevels() async {
    try {
      final res = await http.get(_u('/api/public/majors-levels'), headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final list = items.map((m) => MajorLevels.fromJson(m)).where((e) => e.id.isNotEmpty && e.name.isNotEmpty).toList();
        return Success(list);
      }
      return Failure(_mapHttpError(res));
      } catch (e) {
        return Failure('خطأ في تحميل التخصصات والمراحل: $e');
    }
  }

  @override
  Future<Result<List<domain.Major>>> getMajors() async {
    try {
      final res = await http.get(_u('/api/majors'), headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final majors = items
            .map((m) => domain.Major(
                  id: (m['id'] ?? '').toString(),
                  name: (m['name'] ?? '').toString(),
                ))
            .where((m) => m.id.isNotEmpty && m.name.isNotEmpty)
            .toList();
        return Success(majors);
      }
      return Failure(_mapHttpError(res));
      } catch (e) {
        return Failure('خطأ في تحميل التخصصات: $e');
    }
  }

  @override
  Future<Result<List<String>>> getLevels() async {
    try {
      final res = await http.get(_u('/api/levels'), headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
        return Success(items);
      }
      return Failure(_mapHttpError(res));
      } catch (e) {
        return Failure('خطأ في تحميل المراحل: $e');
    }
  }

  @override
  Future<Result<List<University>>> getUniversities({String? type}) async {
    try {
      final query = <String, dynamic>{};
      if (type != null && type.trim().isNotEmpty) {
        query['type'] = type.trim();
      }

      final uri = _centralApiUrl('/universities', query.isEmpty ? null : query);
      debugPrint('[RestApiClient] getUniversities → GET ${uri.toString()}');
      final res = await http.get(uri, headers: await _headers(withAuth: true));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          final list = decoded
              .whereType<Map<String, dynamic>>()
              .map((m) => University.fromJson(m))
              .where((u) => u.id.isNotEmpty && u.name.isNotEmpty)
              .toList();
          return Success(list);
        }
        return const Failure('استجابة غير متوقعة من الخادم');
      }

      if (res.statusCode == 401) {
        return const Failure('غير مصرح: يرجى تسجيل الدخول مرة أخرى');
      }

      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحميل الجامعات: $e');
    }
  }

  @override
  Future<Result<List<domain.Course>>> getCourses({
    required String majorId,
    required String level,
    required domain.CourseTrack track,
  }) async {
    try {
      final res = await http.get(
        _u('/api/courses', {
          if (majorId.isNotEmpty) 'majorId': majorId,
          if (level.isNotEmpty) 'level': level,
          // Pass track when available; backend expects values like 'first' or 'second'
          'track': track.name,
          'limit': '50',
        }),
        headers: await _headers(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        // Map and defensively filter client-side in case backend ignores 'track'
        var courses = list
            .map(_parseCourse)
            .where((c) => c.track == track)
            .toList();

        // Enrich subscriptions using enrollments API
        try {
          final prefs = await SharedPreferences.getInstance();
          final String? userId = (prefs.getString('auth_user_id') ?? FirebaseAuth.instance.currentUser?.uid);
          if (userId != null && userId.isNotEmpty) {
            final activeRes = await getUserActiveCourses(userId);
            if (activeRes is Success<List<domain.Course>>) {
              final activeIds = activeRes.data.map((c) => c.id).toSet();
              courses = [
                for (final c in courses) c.copyWith(isSubscribed: c.isSubscribed || activeIds.contains(c.id))
              ];
            }
          }
        } catch (_) {}

        return Success(courses);
      }
      return Failure(_mapHttpError(res));
      } catch (e) {
        return Failure('خطأ في تحميل الكورسات: $e');
    }
  }

  @override
  Future<Result<List<domain.Lecture>>> getLectures(String courseId) async {
    try {
      if (courseId.isEmpty) {
        // Return all cached lectures (used by video page to resolve by id)
        final all = _lecturesCacheByCourse.values.expand((e) => e).toList();
        return Success(all);
      }

      final uri = _u('/api/courses/$courseId/lectures');
      debugPrint('[RestApiClient] getLectures GET ${uri.toString()}');
      final res = await http.get(
        uri,
        headers: await _headers(),
      );
      debugPrint('[RestApiClient] getLectures status=${res.statusCode}');
      debugPrint('[RestApiClient] getLectures body.len=${res.body.length}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        List<Map<String, dynamic>> list;
        if (decoded is List) {
          list = decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map) {
          list = (decoded['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        } else {
          list = <Map<String, dynamic>>[];
        }
        final lectures = list.map(_parseLecture).toList();
        // Cache
        _lecturesCacheByCourse[courseId] = lectures;
        return Success(lectures);
      }
      return Failure(_mapHttpError(res));
      } catch (e) {
        return Failure('خطأ في تحميل المحاضرات: $e');
    }
  }

  @override
  Future<Result<domain.Course>> getCourse(String courseId) async {
    try {
      final res = await http.get(
        _u('/api/courses/$courseId'),
        headers: await _headers(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        var course = _parseCourse(data);

        // Enrich with enrollment status for current user
        try {
          final prefs = await SharedPreferences.getInstance();
          final String? userId = (prefs.getString('auth_user_id') ?? FirebaseAuth.instance.currentUser?.uid);
          if (userId != null && userId.isNotEmpty) {
            final enr = await isUserEnrolledInCourse(userId, courseId);
            if (enr is Success<bool> && enr.data) {
              course = course.copyWith(isSubscribed: true);
            }
          }
        } catch (_) {}

        return Success(course);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحميل الكورس: $e');
    }
  }

  @override
  Future<Result<domain.Instructor>> getInstructor(String instructorId) async {
    try {
      if (_instructorCache.containsKey(instructorId)) {
        return Success(_instructorCache[instructorId]!);
      }
      final res = await http.get(_u('/api/instructors'), headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        for (final m in items) {
          final inst = domain.Instructor(
            id: (m['id'] ?? '').toString(),
            name: (m['name'] ?? 'المدرس').toString(),
            avatarUrl: (m['avatar'] ?? '').toString(),
          );
          _instructorCache[inst.id] = inst;
        }
        final found = _instructorCache[instructorId];
        if (found != null) return Success(found);
        // Fallback placeholder
        return Success(domain.Instructor(
          id: instructorId,
          name: 'المدرس',
          avatarUrl: 'https://api.dicebear.com/7.x/initials/svg?seed=$instructorId',
        ));
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحميل بيانات المدرس: $e');
    }
  }

  // ---------------- Library ----------------

  @override
  Future<Result<List<domain.Course>>> getLibraryCourses() async {
    final Map<String, domain.Course> coursesById = {};
    final List<String> order = [];
    bool activeMerged = false;

    void mergeCourse(domain.Course course, {bool markSubscribed = false}) {
      if (course.id.isEmpty) return;
      final shouldMarkSubscribed = markSubscribed || course.isSubscribed;
      final normalized = shouldMarkSubscribed && !course.isSubscribed
          ? course.copyWith(isSubscribed: true)
          : course;

      final existing = coursesById[normalized.id];
      if (existing == null) {
        coursesById[normalized.id] = normalized;
        order.add(normalized.id);
      } else {
        coursesById[normalized.id] = domain.Course(
          id: normalized.id,
          title: normalized.title.isNotEmpty ? normalized.title : existing.title,
          instructorId: normalized.instructorId.isNotEmpty ? normalized.instructorId : existing.instructorId,
          majorId: normalized.majorId.isNotEmpty ? normalized.majorId : existing.majorId,
          level: normalized.level.isNotEmpty ? normalized.level : existing.level,
          track: existing.track,
          coverUrl: normalized.coverUrl.isNotEmpty ? normalized.coverUrl : existing.coverUrl,
          lecturesCount: normalized.lecturesCount != 0 ? normalized.lecturesCount : existing.lecturesCount,
          description: normalized.description.isNotEmpty ? normalized.description : existing.description,
          pendingActivation: existing.pendingActivation || normalized.pendingActivation,
          isSubscribed: existing.isSubscribed || normalized.isSubscribed || shouldMarkSubscribed,
        );
      }
    }

    Future<bool> mergeActiveCourses() async {
      if (activeMerged) return coursesById.isNotEmpty;

      String? userId;
      try {
        final prefs = await SharedPreferences.getInstance();
        userId = (prefs.getString('auth_user_id') ?? FirebaseAuth.instance.currentUser?.uid);
      } catch (_) {}

      userId ??= FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        return false;
      }

      final enr = await getUserActiveCourses(userId);
      if (enr is Success<List<domain.Course>>) {
        final list = enr.data;
        for (final course in list) {
          mergeCourse(course, markSubscribed: true);
        }
        activeMerged = true;
        return list.isNotEmpty;
      }

      return false;
    }

    try {
      final uri = _u('/me/courses');
      debugPrint('[RestApiClient] getLibraryCourses → GET ${uri.toString()}');
      final res = await http.get(uri, headers: await _headers(withAuth: true));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = res.body.trim();
        List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
        if (raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            items = decoded.cast<Map<String, dynamic>>();
          } else if (decoded is Map<String, dynamic>) {
            items = (decoded['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          }
        }

        for (final item in items) {
          final course = _parseCourse(item);
          mergeCourse(course, markSubscribed: !course.pendingActivation);
        }
      } else if (res.statusCode == 404) {
        debugPrint('[RestApiClient] getLibraryCourses → /me/courses 404, falling back to enrollments');
        final fallbackLoaded = await mergeActiveCourses();
        if (fallbackLoaded) {
          final combined = [for (final id in order) coursesById[id]!];
          return Success(combined);
        }
        return const Success(<domain.Course>[]);
      } else {
        final fallbackLoaded = await mergeActiveCourses();
        if (fallbackLoaded) {
          final combined = [for (final id in order) coursesById[id]!];
          return Success(combined);
        }
        return Failure(_mapHttpError(res));
      }
    } catch (e) {
      final fallbackLoaded = await mergeActiveCourses();
      if (fallbackLoaded) {
        final combined = [for (final id in order) coursesById[id]!];
        return Success(combined);
      }
      return Failure('خطأ في تحميل المكتبة: $e');
    }

    await mergeActiveCourses();
    final combined = [for (final id in order) coursesById[id]!];
    return Success(combined);
  }

  @override
  Future<Result<void>> requestActivation(String courseId) async {
    try {
      // Read userId from SharedPreferences (set by AuthController on login)
      String? userId;
      try {
        final prefs = await SharedPreferences.getInstance();
        userId = (prefs.getString('auth_user_id') ?? FirebaseAuth.instance.currentUser?.uid);
      } catch (_) {}

      if (userId == null || userId.isEmpty) {
        return const Failure('يجب تسجيل الدخول أولاً');
      }

      final uri = _u('/api/requests');
      debugPrint('[RestApiClient] requestActivation → POST ${uri.toString()}');

      final res = await http.post(
        uri,
        headers: await _headers(withAuth: true, json: true),
        body: jsonEncode({
          'userId': userId,
          'courseId': courseId,
          'type': 'enroll',
          'message': '',
        }),
      );

      // Backend returns 200 with { success: true }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          final m = jsonDecode(res.body) as Map<String, dynamic>;
          final success = (m['success'] == true);
          if (success) return const Success(null);
          final msg = (m['message'] ?? 'فشل إرسال الطلب').toString();
          return Failure(msg);
        } catch (_) {
          // Accept empty/unknown body as success when 2xx
          return const Success(null);
        }
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في إرسال طلب الصلاحية: $e');
    }
  }

  // ---------------- Enrollment ----------------

  @override
  Future<Result<bool>> isUserEnrolledInCourse(String userId, String courseId) async {
    try {
      final uri = _u('/api/enrollments/$userId/$courseId');
      debugPrint('[RestApiClient] isUserEnrolledInCourse GET ${uri.toString()}');
      final res = await http.get(uri, headers: await _headers(withAuth: true));
      if (res.statusCode == 200) {
        try {
          final data = jsonDecode(res.body);
          if (data is Map<String, dynamic>) {
            // Support multiple backend shapes: {active: true} or {status: "active"}
            final activeFlag = (data['active'] == true);
            final status = (data['status'] ?? data['state'] ?? '').toString();
            final isActive = activeFlag || status.toLowerCase() == 'active';
            return Success(isActive);
          }
          // If body is not a map, treat 200 as active
          return const Success(true);
        } catch (_) {
          return const Success(true);
        }
      }
      if (res.statusCode == 404) {
        return const Success(false);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في التحقق من حالة الصلاحية: $e');
    }
  }

  @override
  Future<Result<List<domain.Course>>> getUserActiveCourses(String userId) async {
    try {
      final uri = _u('/api/enrollments', {
        'userId': userId,
      });
      debugPrint('[RestApiClient] getUserActiveCourses GET ${uri.toString()}');
      final res = await http.get(uri, headers: await _headers(withAuth: true));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        List<Map<String, dynamic>> items;
        if (decoded is List) {
          items = decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map) {
          if (decoded['items'] is List) {
            items = (decoded['items'] as List).cast<Map<String, dynamic>>();
          } else if (decoded['enrollments'] is List) {
            items = (decoded['enrollments'] as List).cast<Map<String, dynamic>>();
          } else if (decoded['courses'] is List) {
            items = (decoded['courses'] as List).cast<Map<String, dynamic>>();
          } else {
            items = <Map<String, dynamic>>[];
          }
        } else {
          items = <Map<String, dynamic>>[];
        }

        // Extract courseIds from enrollments; support shapes like
        // {courseId: 'c1', active: true} or {course: {...}, status: 'active'}
        final activeCourseIds = <String>{};
        for (final m in items) {
          final bool isActive = (m['active'] == true) ||
              ((m['status'] ?? m['state'] ?? '').toString().toLowerCase() == 'active');
          if (!isActive) continue;

          if (m['courseId'] != null) {
            final id = (m['courseId'] ?? '').toString();
            if (id.isNotEmpty) activeCourseIds.add(id);
          } else if (m['course'] is Map<String, dynamic>) {
            final cm = m['course'] as Map<String, dynamic>;
            final id = (cm['id'] ?? '').toString();
            if (id.isNotEmpty) activeCourseIds.add(id);
          } else if (m['id'] != null && m['title'] != null) {
            // Already a course shape
            final id = (m['id'] ?? '').toString();
            if (id.isNotEmpty) activeCourseIds.add(id);
          }
        }

        // Fetch course details for those ids
        final List<domain.Course> courses = [];
        for (final id in activeCourseIds) {
          final cRes = await getCourse(id);
          if (cRes is Success<domain.Course>) {
            courses.add(cRes.data.copyWith(isSubscribed: true));
          }
        }
        return Success(courses);
      }
      if (res.statusCode == 404) {
        return const Success(<domain.Course>[]);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في جلب الكورسات المتاحة: $e');
    }
  }

  // ---------------- Search & Hero ----------------

  @override
  Future<Result<List<domain.Course>>> searchCourses(String query) async {
    try {
      // Simple client-side filter by title over the first 100 courses
      final res = await http.get(_u('/api/courses', {'limit': '100'}), headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final q = query.toLowerCase();
        final courses = list
            .map(_parseCourse)
            .where((c) => c.title.toLowerCase().contains(q))
            .toList();
        return Success(courses);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في البحث: ' + e.toString());
    }
  }

  @override
  Future<Result<List<String>>> getHeroImages() async {
    try {
      final res = await http.get(_u('/api/public/hero-slides'), headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final base = Uri.parse(_baseUrl);
      final baseOrigin = '${base.scheme}://${base.authority}';
        final images = items
            .map((m) => (m['imageUrl'] ?? '').toString())
            .where((u) => u.isNotEmpty)
            .map((u) {
              // If backend returns relative path like "/uploads/..", prefix with base origin
              if (u.startsWith('http://') || u.startsWith('https://')) return u;
               if (u.startsWith('/')) return baseOrigin + u;
               return '$baseOrigin/$u';
            })
            .toList();
        return Success(images);
      }
      return Failure(_mapHttpError(res));
    } catch (e) {
      return Failure('خطأ في تحميل الصور: $e');
    }
  }

  // ---------------- Mapping helpers ----------------

  domain.User _parseUser(Map<String, dynamic> m, String phoneFallback) {
    final rawTelegram = (m['telegramUsername'] ?? m['telegram_username'] ?? '').toString().trim();
    return domain.User(
      id: (m['id'] ?? '').toString(),
      phone: ((m['phone'] ?? m['phoneNumber']) ?? phoneFallback).toString(),
      name: (m['name'] ?? '').toString(),
      governorate: (m['governorate'] ?? '').toString(),
      university: (m['university'] ?? '').toString(),
      birthDate: DateTime.tryParse((m['birthDate'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      gender: _parseGender((m['gender'] ?? 'male').toString()),
      telegramUsername: rawTelegram.isEmpty ? null : rawTelegram,
    );
  }

  Future<String> _cachedPhoneFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('auth_user_data');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final phone = (decoded['phone'] ?? decoded['phoneNumber'] ?? '').toString();
          if (phone.isNotEmpty) {
            return phone;
          }
        }
      }
    } catch (_) {}
    return '';
  }

  domain.Gender _parseGender(String g) {
    return g == 'female' ? domain.Gender.female : domain.Gender.male;
  }

  domain.Course _parseCourse(Map<String, dynamic> m) {
    final String id = (m['id'] ?? '').toString();
    final String title = (m['title'] ?? '').toString();
    final String instructorId = (m['instructorId'] ?? '').toString();
    final String majorId = (m['majorId'] ?? '').toString();
    final String level = (m['level'] ?? '').toString();
    final String trackStr = (m['track'] ?? 'first').toString();
    domain.CourseTrack track;
    try {
      track = domain.CourseTrack.values.byName(trackStr);
    } catch (_) {
      track = domain.CourseTrack.first;
    }
    final int lecturesCount = int.tryParse((m['lecturesCount'] ?? 0).toString()) ?? 0;
    final bool isSubscribed = (m['isSubscribed'] ?? false) == true;
    final bool pendingActivation = (m['pendingActivation'] ?? false) == true;

    // Normalize coverUrl: if backend returns a relative path, prefix with base origin.
    final rawCover = (m['coverUrl'] ?? '').toString();
    final base = Uri.parse(_baseUrl);
    final baseOrigin = '${base.scheme}://${base.authority}';
    String coverUrl;
    if (rawCover.isEmpty) {
      coverUrl = 'https://images.unsplash.com/photo-1513258496099-48168024aec0?q=80&w=1200&auto=format&fit=crop';
    } else if (rawCover.startsWith('http://') || rawCover.startsWith('https://') || rawCover.startsWith('blob:') || rawCover.startsWith('data:')) {
      coverUrl = rawCover;
    } else if (rawCover.startsWith('/')) {
      coverUrl = baseOrigin + rawCover;
    } else {
      coverUrl = '$baseOrigin/$rawCover';
    }
    // Debug: log the final cover url mapping for troubleshooting
    debugPrint('[RestApiClient] _parseCourse coverUrl=$coverUrl');

    final String description = (m['description'] ?? m['desc'] ?? '').toString();

    return domain.Course(
      id: id,
      title: title,
      instructorId: instructorId,
      majorId: majorId,
      level: level,
      track: track,
      coverUrl: coverUrl,
      lecturesCount: lecturesCount,
      description: description,
      isSubscribed: isSubscribed,
      pendingActivation: pendingActivation,
    );
  }

  domain.Lecture _parseLecture(Map<String, dynamic> m) {
    final int seconds = int.tryParse((m['duration'] ?? 0).toString()) ?? 0;
    return domain.Lecture(
      id: (m['id'] ?? '').toString(),
      courseId: (m['courseId'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      order: int.tryParse((m['order'] ?? 0).toString()) ?? 0,
      isFree: (m['isFree'] ?? true) == true, // default to true if not provided
      videoUrl: (m['videoUrl'] ?? '').toString(),
      duration: Duration(seconds: seconds),
    );
  }

  String _mapHttpError(http.Response res) {
    final status = res.statusCode;
    final body = res.body;
    String message;
    if (status == 401) message = 'مصادقة مطلوبة';
    else if (status == 403) message = 'محظور';
    else if (status == 404) message = 'غير موجود';
    else if (status >= 500) message = 'خطأ في الخادم';
    else message = 'خطأ غير متوقع ($status)';

    try {
      final m = jsonDecode(body);
      if (m is Map && m['message'] is String && (m['message'] as String).isNotEmpty) {
        message = m['message'] as String;
      }
    } catch (_) {}

    return message;
  }
}
