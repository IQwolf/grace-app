import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grace_academy/data/api/api_client.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/core/result.dart';

/// Handles Firebase Cloud Messaging setup, permissions, token sync, and message taps.
class NotificationService {
  NotificationService(this.ref);

  final Ref ref;
  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) return;

      // Request permissions where needed (iOS, Web)
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Register foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = message.notification;
        final data = message.data;
        final title = notif?.title ?? data['title'] ?? 'إشعار';
        final body = notif?.body ?? data['body'] ?? '';
        _showInAppBanner(context, title, body, data);
      });

      // Handle background→foreground tap
      _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNavigationFromData(context, message.data);
      });

      // Handle terminated state tap
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNavigationFromData(context, initialMessage.data);
      }

      // Attach token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        await _syncTokenToBackend(token);
      });

      // Initial token sync
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _syncTokenToBackend(token);
      }
    } on FirebaseException catch (e) {
      // On web, users might have previously blocked notifications; treat as non-fatal.
      if (e.code == 'permission-blocked' || e.message?.contains('permission') == true) {
        debugPrint('[NotificationService] Notification permission blocked by user (web/iOS); continuing without push.');
      } else {
        debugPrint('[NotificationService] initialize error: ${e.message ?? e.code}');
      }
    } catch (e) {
      debugPrint('[NotificationService] initialize error: $e');
    }
  }

  Future<void> syncTokenForPhone(String phoneNumber) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        // Try to resolve studentId from current user or prefs
        String? studentId = ref.read(currentUserProvider)?.id;
        if (studentId == null || studentId.isEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            studentId = prefs.getString('auth_user_id');
          } catch (_) {}
        }
        if (studentId != null && studentId.isNotEmpty) {
          await _saveToken(studentId, phoneNumber, token);
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] syncTokenForPhone error: $e');
    }
  }

  Future<void> syncTokenForUser({required String studentId, required String phoneNumber}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(studentId, phoneNumber, token);
      }
    } catch (e) {
      debugPrint('[NotificationService] syncTokenForUser error: $e');
    }
  }

  Future<void> _syncTokenToBackend(String token) async {
    try {
      // Prefer current user data
      final user = ref.read(currentUserProvider);
      String? phone = user?.phone;
      String? studentId = user?.id;

      // Fallbacks from SharedPreferences
      if (studentId == null || studentId.isEmpty || phone == null || phone.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          studentId = studentId?.isNotEmpty == true ? studentId : prefs.getString('auth_user_id');
          if (phone == null || phone.isEmpty) {
            final raw = prefs.getString('auth_user_data');
            if (raw != null && raw.isNotEmpty) {
              try {
                final map = jsonDecode(raw) as Map<String, dynamic>;
                final phoneValue = ((map['phone'] ?? map['phoneNumber']) ?? '').toString();
                if (phoneValue.isNotEmpty) phone = phoneValue;
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
      if (studentId != null && studentId.isNotEmpty && phone != null && phone.isNotEmpty) {
        await _saveToken(studentId, phone, token);
      }
    } catch (e) {
      debugPrint('[NotificationService] _syncTokenToBackend error: $e');
    }
  }

  Future<void> _saveToken(String studentId, String phone, String token) async {
    final api = ref.read(apiClientProvider);
    final res = await api.saveFcmToken(studentId: studentId, phoneNumber: phone, fcmToken: token);
    if (res is Failure<void>) {
      debugPrint('[NotificationService] saveFcmToken failure: ${res.error}');
    } else {
      debugPrint('[NotificationService] saveFcmToken success');
    }
  }

  void dispose() {
    _onMessageOpenedSub?.cancel();
  }

  void _showInAppBanner(BuildContext context, String title, String body, Map<String, dynamic> data) {
    try {
      final scaffold = ScaffoldMessenger.maybeOf(context);
      if (scaffold == null) return;
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(
          content: LayoutBuilder(
            builder: (context, constraints) {
              final message = title + (body.isNotEmpty ? ' — ' + body : '');
              final availableWidth = (constraints.maxWidth.isFinite ? constraints.maxWidth : 280) - 40;
              final clampedWidth = availableWidth.clamp(120.0, 600.0).toDouble();
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: clampedWidth),
                    child: Text(
                      message,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              );
            },
          ),
          action: (data['type'] == 'enrollment' && (data['courseId'] ?? '').toString().isNotEmpty)
              ? SnackBarAction(
                  label: 'فتح', onPressed: () => _handleNavigationFromData(context, data), textColor: Colors.yellow)
              : null,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] showInAppBanner error: $e');
    }
  }

  void _handleNavigationFromData(BuildContext context, Map<String, dynamic> data) {
    try {
      final type = (data['type'] ?? '').toString();
      if (type == 'enrollment') {
        final courseId = (data['courseId'] ?? '').toString();
        if (courseId.isNotEmpty) {
          if (context.mounted) {
            context.go('/course/' + courseId);
          }
        }
      }
      // Other types can be handled as needed
    } catch (e) {
      debugPrint('[NotificationService] navigation error: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref));
