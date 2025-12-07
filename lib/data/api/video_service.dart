import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grace_academy/core/config.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/data/api/rest_api_client.dart';
import 'package:grace_academy/utils/firebase_id_token_provider.dart';
import 'package:grace_academy/data/models/video_quality.dart';

class VideoMetadata {
  final String id;
  final String title;
  final int durationSeconds;
  final bool isFree;
  final String streamPath;
  final List<VideoQuality> formats;
  final String videoUrl;

  const VideoMetadata({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.isFree,
    required this.streamPath,
    required this.formats,
    required this.videoUrl,
  });
}

class VideoService {
  const VideoService._();

  static Future<String> _getBaseOrigin(WidgetRef ref) async {
    final apiClient = ref.read(apiClientProvider);
    if (apiClient is RestApiClient) {
      return apiClient.baseOrigin;
    }
    // Fallback to the default defined in RestApiClient
    return RestApiClient().baseOrigin;
  }

  /// Returns headers with a Firebase ID token.
  /// Waits for Firebase Auth to emit an auth state before attempting.
  static Future<Map<String, String>> _getFirebaseAuthHeaders() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Wait for first auth state emission (user may be restored asynchronously)
        debugPrint('[VideoService] waiting for Firebase auth state...');
        try {
          user = await FirebaseAuth.instance
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 6));
        } catch (_) {
          debugPrint('[VideoService] auth state wait timeout or still null');
        }
      }

      user ??= FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[VideoService] No authenticated user found');
        return const <String, String>{};
      }

      final token = await FirebaseIdTokenProvider.getValidToken();
      if (token == null || token.isEmpty) {
        debugPrint('[VideoService] firebase token preview=<none>');
        return const <String, String>{};
      }
      final preview = token.length > 20 ? '${token.substring(0, 20)}…' : token;
      debugPrint('[VideoService] firebase token preview=$preview');
      return <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    } catch (e) {
      debugPrint('[VideoService] Error getting Firebase token: $e');
      return const <String, String>{};
    }
  }

  /// Prefer the same stored dev token used by RestApiClient; fallback to Firebase headers if absent.
  static Future<Map<String, String>> _getAuthHeaders() async {
    if (AppConfig.isProduction) {
      final firebaseHeaders = await _getFirebaseAuthHeaders();
      if (firebaseHeaders.isNotEmpty) {
        return firebaseHeaders;
      }
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        final preview = token.length > 20 ? '${token.substring(0, 20)}…' : token;
        debugPrint('[VideoService] Using stored token: $preview');
        return <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
      }
      debugPrint('[VideoService] No auth token found in storage → fallback to Firebase token');
    } catch (e) {
      debugPrint('[VideoService] Error getting auth token from storage: $e');
    }
    // Fallback to Firebase-based headers
    return await _getFirebaseAuthHeaders();
  }

  static Future<VideoMetadata> getVideoMetadata(WidgetRef ref, String lectureId) async {
    final base = await _getBaseOrigin(ref);
    final headers = await _getAuthHeaders();

    final uri = Uri.parse('$base/api/videos/$lectureId');
    // Debug logs to verify headers/token
    debugPrint('[VideoService] getVideoMetadata → GET ${uri.toString()}');
    debugPrint('[VideoService] getVideoMetadata headers.keys=${headers.keys.join(',')}');

    final res = await http.get(
      uri,
      headers: headers,
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
      final formatsJson = (data['formats'] as List<dynamic>? ?? const []);
      if (formatsJson.isEmpty) {
        throw Exception('لا توجد صيغة فيديو متاحة');
      }
      final formats = formatsJson
          .map((f) => VideoQuality.fromJson(f as Map<String, dynamic>))
          .toList();
      final first = formats.first;
      final path = first.url;
      if (path.isEmpty) {
        throw Exception('مسار الفيديو غير صالح');
      }
      return VideoMetadata(
        id: (data['id'] ?? '').toString(),
        title: (data['title'] ?? 'محاضرة').toString(),
        durationSeconds: int.tryParse((data['duration'] ?? 0).toString()) ?? 0,
        isFree: (data['isFree'] ?? true) == true,
        streamPath: path,
        formats: formats,
        videoUrl: data['videoUrl'] ?? path,
      );
    } else if (res.statusCode == 401) {
      throw Exception('يجب تسجيل الدخول لمشاهدة هذا المحتوى');
    } else if (res.statusCode == 404) {
      throw Exception('المحاضرة غير موجودة');
    } else {
      debugPrint('[VideoService] Error: ${res.statusCode} ${res.body}');
      throw Exception('خطأ في تحميل بيانات الفيديو');
    }
  }

  /// Build the final streaming Uri and append the auth token as a query parameter.
  /// Always prefer token in URL because some platforms (notably web) do not support
  /// custom http headers for media elements.
  static Future<Uri> buildStreamUri(WidgetRef ref, String relativePath) async {
    final base = await _getBaseOrigin(ref);
    Uri uri;
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      uri = Uri.parse(relativePath);
    } else if (!relativePath.startsWith('/')) {
      uri = Uri.parse('$base/$relativePath');
    } else {
      uri = Uri.parse('$base$relativePath');
    }

    // Get stored dev token first; fallback to Firebase ID token.
    String? token;
    if (AppConfig.isProduction) {
      token = await FirebaseIdTokenProvider.getValidToken();
    }
    if (token == null || token.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('auth_token');
        if (stored != null && stored.isNotEmpty) token = stored;
      } catch (_) {}
    }
    token ??= await FirebaseIdTokenProvider.getValidToken();

    if (token != null && token.isNotEmpty) {
      final qp = Map<String, String>.from(uri.queryParameters);
      if (!qp.containsKey('token') && !qp.containsKey('access_token')) {
        final updated = uri.replace(queryParameters: {
          ...qp,
          'token': token,
        });
        debugPrint('[VideoService] buildStreamUri appended token query parameter');
        return updated;
      }
    }
    return uri;
  }

  static Future<Map<String, String>> authHeaders() async {
    final headers = await _getAuthHeaders();
    // Debug: show whether Authorization will be sent for the metadata request
    debugPrint('[VideoService] authHeaders keys=${headers.keys.join(',')}');
    return headers;
  }
}
